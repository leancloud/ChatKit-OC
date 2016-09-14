//
//  AVExceptionHandler.m
//  paas
//
//  Created by Zhu Zeng on 8/19/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVExceptionHandler.h"
#import "AVAnalyticsImpl.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <UIKit/UIKit.h>
#endif
static NSString * const AVOS_UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
static NSString * const AVOS_UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const AVOS_UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

static volatile int32_t AVOS_UncaughtExceptionCount = 0;
static const int32_t AVOS_UncaughtExceptionMaximum = 10;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"

static const int AVOS_UncaughtExceptionHandlerSkipAddressCount = 4;
static const int AVOS_UncaughtExceptionHandlerReportAddressCount = 5;

#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"

/**
 * @internal
 *
 * Async-safe binary image list element.
 */
typedef struct bin_image {
    /** The binary image's header address. */
    uintptr_t header;
    
    /** The binary image's name/path. */
    char *name;
    
    /** The previous image in the list, or NULL */
    struct bin_image *prev;
    
    /** The next image in the list, or NULL. */
    struct bin_image *next;
} bin_image_t;

/**
 * @internal
 *
 * Async-safe binary image list. May be used to iterate over the binary images currently
 * available in-process.
 */
typedef struct bs_image_list {
    /** The lock used by writers. No lock is required for readers. */
    OSSpinLock write_lock;
    
    /** The head of the list, or NULL if the list is empty. Must only be used to iterate or delete entries. */
    bin_image_t *head;
    
    /** The tail of the list, or NULL if the list is empty. Must only be used to append new entries. */
    bin_image_t *tail;
    
    /** The list reference count. No nodes will be deallocated while the count is greater than 0. If the count
     * reaches 0, all nodes in the free list will be deallocated. */
    int32_t refcount;
    
    /** The node free list. */
    bin_image_t *free;
} bs_image_list_t;

/**
 * @internal
 *
 * Shared dyld image list.
 */
static bs_image_list_t shared_image_list = { 0 };

/**
 * @internal
 *
 * Maintains a linked list of binary images with support for async-safe iteration. Writing may occur concurrently with
 * async-safe reading, but is not async-safe.
 *
 * Atomic compare and swap is used to ensure a consistent view of the list for readers. To simplify implementation, a
 * write mutex is held for all updates; the implementation is not designed for efficiency in the face of contention
 * between readers and writers, and it's assumed that no contention should realistically occur.
 * @{
 */

/**
 * Initialize a new binary image list and issue a memory barrier
 *
 * @param list The list structure to be initialized.
 *
 * @warning This method is not async safe.
 */
static void image_list_init (bs_image_list_t *list) {
    memset(list, 0, sizeof(*list));
    
    list->write_lock = OS_SPINLOCK_INIT;
}

/**
 * Free any binary image list resources.
 *
 * @warning This method is not async safe.
 */
static void image_list_free (bs_image_list_t *list) {
    bin_image_t *next = list->head;
    while (next != NULL) {
        /* Save the current pointer and fetch the next pointer. */
        bin_image_t *cur = next;
        next = cur->next;
        
        /* Deallocate the current item. */
        if (cur->name != NULL)
            free(cur->name);
        free(cur);
    }
}

/**
 * Append a new binary image record to @a list.
 *
 * @param list The list to which the image record should be appended.
 * @param header The image's header address.
 * @param name The image's name.
 *
 * @warning This method is not async safe.
 */
static void image_list_append (bs_image_list_t *list, uintptr_t header, const char *name) {
    /* Initialize the new entry. */
    bin_image_t *new = calloc(1, sizeof(bin_image_t));
    new->header = header;
    new->name = strdup(name);
    
    /* Update the image record and issue a memory barrier to ensure a consistent view. */
    OSMemoryBarrier();
    
    /* Lock the list from other writers. */
    OSSpinLockLock(&list->write_lock); {
        
        /* If this is the first entry, initialize the list. */
        if (list->tail == NULL) {
            
            /* Update the list tail. This need not be done atomically, as tail is never accessed by a lockless reader. */
            list->tail = new;
            
            /* Atomically update the list head; this will be iterated upon by lockless readers. */
            if (!OSAtomicCompareAndSwapPtrBarrier(NULL, new, (void **) (&list->head))) {
                /* Should never occur */
                NSLog(@"An async image head was set with tail == NULL despite holding lock.");
            }
        }
        
        /* Otherwise, append to the end of the list */
        else {
            /* Atomically slot the new record into place; this may be iterated on by a lockless reader. */
            if (!OSAtomicCompareAndSwapPtrBarrier(NULL, new, (void **) (&list->tail->next))) {
                NSLog(@"Failed to append to image list despite holding lock");
            }
            
            /* Update the prev and tail pointers. This is never accessed without a lock, so no additional barrier
             * is required here. */
            new->prev = list->tail;
            list->tail = new;
        }
    } OSSpinLockUnlock(&list->write_lock);
}

/**
 * Remove a binary image record from @a list.
 *
 * @param header The header address of the record to be removed. The first record matching this address will be removed.
 *
 * @warning This method is not async safe.
 */
static void image_list_remove (bs_image_list_t *list, uintptr_t header) {
    /* Lock the list from other writers. */
    OSSpinLockLock(&list->write_lock); {
        /* Find the record. */
        bin_image_t *item = list->head;
        while (item != NULL) {
            if (item->header == header)
                break;
            
            item = item->next;
        }
        
        /* If not found, nothing to do */
        if (item == NULL) {
            OSSpinLockUnlock(&list->write_lock);
            return;
        }
        
        /*
         * Atomically make the item unreachable by readers.
         *
         * This serves as a synchronization point -- after the CAS, the item is no longer reachable via the list.
         */
        if (item == list->head) {
            if (!OSAtomicCompareAndSwapPtrBarrier(item, item->next, (void **) &list->head)) {
                NSLog(@"Failed to remove image list head despite holding lock");
            }
        } else {
            /* There MUST be a non-NULL prev pointer, as this is not HEAD. */
            if (!OSAtomicCompareAndSwapPtrBarrier(item, item->next, (void **) &item->prev->next)) {
                NSLog(@"Failed to remove image list item despite holding lock");
            }
        }
        
        /* Now that the item is unreachable, update the prev/tail pointers. These are never accessed without a lock,
         * and need not be updated atomically. */
        if (item->next != NULL) {
            /* Item is not the tail (otherwise next would be NULL), so simply update the next item's prev pointer. */
            item->next->prev = item->prev;
        } else {
            /* Item is the tail (next is NULL). Simply update the tail record. */
            list->tail = item->prev;
        }
        
        /* If a reader is active, simply spin until inactive. */
        while (list->refcount > 0) {
        }
        
        if (item->name != NULL)
            free(item->name);
        free(item);
    } OSSpinLockUnlock(&list->write_lock);
}

/**
 * Retain or release the list for reading. This method is async-safe.
 *
 * This must be issued prior to attempting to iterate the list, and must called again once reads have completed.
 *
 * @param list The list to be be retained or released for reading.
 * @param enable If true, the list will be retained. If false, released.
 */
static void image_list_set_reading (bs_image_list_t *list, bool enable) {
    if (enable) {
        /* Increment and issue a barrier. Once issued, no items will be deallocated while a reference is held. */
        OSAtomicIncrement32Barrier(&list->refcount);
    } else {
        /* Increment and issue a barrier. Once issued, items may again be deallocated. */
        OSAtomicDecrement32Barrier(&list->refcount);
    }
}

/**
 * Return the next image record. This method is async-safe. If no additional images are available, will return NULL;
 *
 * @param list The list to be iterated.
 * @param current The current image record, or NULL to start iteration.
 */
static bin_image_t *image_list_next (bs_image_list_t *list, bin_image_t *current) {
    if (current != NULL)
        return current->next;
    
    return list->head;
}

/**
 * @internal
 * dyld image add notification callback.
 */
static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    
    /* Look up the image info */
    if (dladdr(mh, &info) == 0) {
        NSLog(@"%s: dladdr(%p, ...) failed", __FUNCTION__, mh);
        return;
    }
    
    /* Register the image */
    image_list_append(&shared_image_list, (uintptr_t) mh, info.dli_fname);
}

/**
 * @internal
 *
 * Write a binary image frame
 *
 * @param file Output file
 * @param name binary image path (or name).
 * @param image_base Mach-O image base.
 */
static void process_binary_image (const char *name, const void *header,
                                  struct uuid_command *out_uuid, uintptr_t *out_baseaddr) {
    uint32_t ncmds;
    const struct mach_header *header32 = (const struct mach_header *) header;
    const struct mach_header_64 *header64 = (const struct mach_header_64 *) header;
    
    struct load_command *cmd;
    
    /* Check for 32-bit/64-bit header and extract required values */
    switch (header32->magic) {
            /* 32-bit */
        case MH_MAGIC:
        case MH_CIGAM:
            ncmds = header32->ncmds;
            cmd = (struct load_command *) (header32 + 1);
            break;
            
            /* 64-bit */
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            ncmds = header64->ncmds;
            cmd = (struct load_command *) (header64 + 1);
            break;
            
        default:
            NSLog(@"Invalid Mach-O header magic value: %x", header32->magic);
            return;
    }
    
    /* Compute the image size and search for a UUID */
    struct uuid_command *uuid = NULL;
    
    for (uint32_t i = 0; cmd != NULL && i < ncmds; i++) {
        /* DWARF dSYM UUID */
        if (cmd->cmd == LC_UUID && cmd->cmdsize == sizeof(struct uuid_command))
            uuid = (struct uuid_command *) cmd;
        
        cmd = (struct load_command *) ((uint8_t *) cmd + cmd->cmdsize);
    }
    
    /* Base address */
    uintptr_t base_addr;
    base_addr = (uintptr_t) header;
    
    *out_baseaddr = base_addr;
    if(out_uuid && uuid)
        memcpy(out_uuid, uuid, sizeof(struct uuid_command));
}

@interface AVExceptionHandler ()
- (void)handleException:(NSException *)exception;
@end

void globalHandleException(NSException *exception)
{
	int32_t exceptionCount = OSAtomicIncrement32(&AVOS_UncaughtExceptionCount);
	if (exceptionCount > AVOS_UncaughtExceptionMaximum)
	{
		return;
	}
	
	NSArray *callStack = [exception callStackSymbols];
    
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
	[userInfo setObject:callStack forKey:AVOS_UncaughtExceptionHandlerAddressesKey];
	
	[[[AVExceptionHandler alloc] init]
     performSelectorOnMainThread:@selector(handleException:)
     withObject:
     [NSException
      exceptionWithName:[exception name]
      reason:[exception reason]
      userInfo:userInfo]
     waitUntilDone:YES];
}

void globalSignalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&AVOS_UncaughtExceptionCount);
	if (exceptionCount > AVOS_UncaughtExceptionMaximum)
	{
		return;
	}
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal]
                                                                       forKey:AVOS_UncaughtExceptionHandlerSignalKey];
    
	NSArray *callStack = [AVExceptionHandler backtrace];
	[userInfo setObject:callStack forKey:AVOS_UncaughtExceptionHandlerAddressesKey];
	
	[[[AVExceptionHandler alloc] init]
     performSelectorOnMainThread:@selector(handleException:)
     withObject:
     [NSException
      exceptionWithName:AVOS_UncaughtExceptionHandlerSignalExceptionName
      reason:
      [NSString stringWithFormat:
       NSLocalizedString(@"Signal %d was raised.", nil),
       signal]
      userInfo:
      [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:signal]
                                  forKey:AVOS_UncaughtExceptionHandlerSignalKey]]
     waitUntilDone:YES];
}

#pragma clang diagnostic pop

@interface AVExceptionHandler ()
@property (readwrite, nonatomic) BOOL holdException;
@end
@implementation AVExceptionHandler

+ (void)registerCallback {
    _dyld_register_func_for_add_image(image_add_callback);
}

+ (NSString*)appBuildUUID {
    static NSString *buildUUID=nil;
    
    if (buildUUID) {
        return buildUUID;
    }
    
    int i;
    struct uuid_command uuid = { 0 };
    uintptr_t baseaddr;
    char uuidstr[64] = { 0 };
    
    image_list_set_reading(&shared_image_list, true);
    
    bin_image_t *image = NULL;
    while ((image = image_list_next(&shared_image_list, image)) != NULL) {
        
        process_binary_image(image->name, (const void *) (image->header), &uuid, &baseaddr);
        
        for(i=0; i<16; i++) {
            sprintf(&uuidstr[2*i], "%02X", uuid.uuid[i]);
        }
        
        NSString *imgName=[NSString stringWithCString:image->name encoding:NSASCIIStringEncoding];
        
        
        if ([imgName rangeOfString:@".app"].location!=NSNotFound) {
            NSString *uuidString=[NSString stringWithCString:uuidstr encoding:NSASCIIStringEncoding];
            
            buildUUID=[NSString stringWithFormat:@"%@-%@-%@-%@-%@",
                                    [uuidString substringWithRange:NSMakeRange(0, 8)],
                                    [uuidString substringWithRange:NSMakeRange(8, 4)],
                                    [uuidString substringWithRange:NSMakeRange(12, 4)],
                                    [uuidString substringWithRange:NSMakeRange(16, 4)],
                                    [uuidString substringWithRange:NSMakeRange(20, 12)]
                                    ];
            
            return buildUUID;
        }
    }
    
    return @"";
}



+(void) installAVOSUncaughtExceptionHandler
{
    NSSetUncaughtExceptionHandler(&globalHandleException);
	signal(SIGABRT, globalSignalHandler);
	signal(SIGILL, globalSignalHandler);
	signal(SIGSEGV, globalSignalHandler);
	signal(SIGFPE, globalSignalHandler);
	signal(SIGBUS, globalSignalHandler);
	signal(SIGPIPE, globalSignalHandler);
    
    [self registerCallback];
}

+(void)uninstallAVOSUncaughtExceptionHandler
{
    NSSetUncaughtExceptionHandler(NULL);
	signal(SIGABRT, SIG_DFL);
	signal(SIGILL, SIG_DFL);
	signal(SIGSEGV, SIG_DFL);
	signal(SIGFPE, SIG_DFL);
	signal(SIGBUS, SIG_DFL);
	signal(SIGPIPE, SIG_DFL);
}

+ (NSArray *)backtrace
{
    void* callstack[1024];
    int frames = backtrace(callstack, 1024);
    char **strs = backtrace_symbols(callstack, frames);
    
    NSRegularExpression *re=[[NSRegularExpression alloc] initWithPattern:@"^[0-9]{1,3}"
                                                                 options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = AVOS_UncaughtExceptionHandlerSkipAddressCount; i < frames; ++i)
    {
        char * str=strs[i];
        NSMutableString *stacInfo=[NSMutableString stringWithUTF8String:str];
        
        NSTextCheckingResult *checkResult= [re firstMatchInString:stacInfo options:NSMatchingReportCompletion range:NSMakeRange(0, 4)];
        
        if (checkResult) {
            NSString *finalFrame=[NSString stringWithFormat:@"%d", i-AVOS_UncaughtExceptionHandlerSkipAddressCount];
            [stacInfo replaceCharactersInRange:checkResult.range withString:finalFrame];
        }
        
	 	[backtrace addObject:stacInfo];
    }
    free(strs);
    return backtrace;
}

- (void)handleException:(NSException *)exception
{
    [[AVAnalyticsImpl sharedInstance] addException:exception];
	
    //需要让开发者设置忽略crash吗? 我们可以提醒用户app已经不稳定 但这对开发者来说比退出要好
    
    
    if ([AVAnalyticsImpl sharedInstance].enableIgnoreCrash) {
        self.holdException=YES;
        NSString *title=nil,*msg=nil,*quit=nil,*ctn=nil;
        NSDictionary *ignoreCrashAlertStrings=[AVAnalyticsImpl sharedInstance].ignoreCrashAlertStrings;
        if ([AVAnalyticsImpl sharedInstance].ignoreCrashAlertStrings) {
            title=ignoreCrashAlertStrings[@"title"];
            msg=ignoreCrashAlertStrings[@"msg"];
            quit=ignoreCrashAlertStrings[@"quit"];
            ctn=ignoreCrashAlertStrings[@"continue"];
        }
        title=(title==nil)?NSLocalizedString(@"App becomes unstable", nil):title;
        msg=(msg==nil)?NSLocalizedString(@"You can choose quit or continue, but it may course unexcepted problem", nil):msg;
        quit=(quit==nil)?NSLocalizedString(@"Quit", nil):quit;
        ctn=(ctn==nil)?NSLocalizedString(@"Continue", nil):ctn;
        
#if AV_TARGET_OS_IOS
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:title
                                                      message:msg
                                                     delegate:(id<UIAlertViewDelegate>)self
                                            cancelButtonTitle:quit
                                            otherButtonTitles:ctn, nil];
        [alert show];
#elif AV_TARGET_OS_OSX
        NSAlert *alert=[NSAlert alertWithMessageText:title defaultButton:quit alternateButton:ctn otherButton:Nil informativeTextWithFormat:@"%@",msg];
        
        NSInteger r=[alert runModal];
        if (r==0) {
            self.holdException=NO;
        }
#endif
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
        
        while (self.holdException)
        {
            for (NSString *mode in (__bridge NSArray *)allModes)
            {
                CFRunLoopRunInMode((__bridge CFStringRef)mode, 0.01, false);
            }
        }
        
        CFRelease(allModes);
    }
    
    [AVExceptionHandler uninstallAVOSUncaughtExceptionHandler];
    if ([[exception name] isEqual:AVOS_UncaughtExceptionHandlerSignalExceptionName])
    {
        kill(getpid(), [[[exception userInfo] objectForKey:AVOS_UncaughtExceptionHandlerSignalKey] intValue]);
    }
    else
    {
        [exception raise];
    }
}

#if AV_TARGET_OS_IOS

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex==0) {
        self.holdException=NO;
    }
}

#else

#endif

@end

