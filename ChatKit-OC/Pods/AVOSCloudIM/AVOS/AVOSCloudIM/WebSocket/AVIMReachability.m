//
//  AVIMReachability.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/5/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMReachability.h"

NSString *const kAVIMReachabilityChangedNotification = @"kAVIMReachabilityChangedNotification";

@interface AVIMReachability ()

@property (nonatomic, assign) SCNetworkReachabilityRef  reachabilityRef;


#if NEEDS_DISPATCH_RETAIN_RELEASE
@property (nonatomic, assign) dispatch_queue_t          reachabilitySerialQueue;
#else
@property (nonatomic, strong) dispatch_queue_t          reachabilitySerialQueue;
#endif


@property (nonatomic, strong) id reachabilityObject;

-(void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;
-(BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags;

@end

static NSString *reachabilityFlags(SCNetworkReachabilityFlags flags)
{
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
#if	TARGET_OS_IPHONE
            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
#else
            'X',
#endif
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
}

// Start listening for reachability notifications on the current run loop
static void AVIMReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target)
#if __has_feature(objc_arc)
    AVIMReachability *reachability = ((__bridge AVIMReachability*)info);
#else
    AVIMReachability *reachability = ((AVIMReachability*)info);
#endif
    
    // We probably don't need an autoreleasepool here, as GCD docs state each queue has its own autorelease pool,
    // but what the heck eh?
    @autoreleasepool
    {
        [reachability reachabilityChanged:flags];
    }
}


@implementation AVIMReachability

@synthesize reachabilityRef;
@synthesize reachabilitySerialQueue;

@synthesize reachableOnWWAN;

@synthesize reachableBlock;
@synthesize unreachableBlock;

@synthesize reachabilityObject;

#pragma mark - Class Constructor Methods

+(instancetype)reachabilityWithHostName:(NSString*)hostname
{
    return [AVIMReachability reachabilityWithHostname:hostname];
}

+(instancetype)reachabilityWithHostname:(NSString*)hostname
{
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
    if (ref)
    {
        id reachability = [[self alloc] initWithReachabilityRef:ref];
        
#if __has_feature(objc_arc)
        return reachability;
#else
        return [reachability autorelease];
#endif
        
    }
    
    return nil;
}

+(instancetype)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress
{
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    if (ref)
    {
        id reachability = [[self alloc] initWithReachabilityRef:ref];
        
#if __has_feature(objc_arc)
        return reachability;
#else
        return [reachability autorelease];
#endif
    }
    
    return nil;
}

+(instancetype)reachabilityForInternetConnection
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    return [self reachabilityWithAddress:&zeroAddress];
}

+(instancetype)reachabilityForLocalWiFi
{
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len            = sizeof(localWifiAddress);
    localWifiAddress.sin_family         = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr    = htonl(IN_LINKLOCALNETNUM);
    
    return [self reachabilityWithAddress:&localWifiAddress];
}


// Initialization methods

-(instancetype)initWithReachabilityRef:(SCNetworkReachabilityRef)ref
{
    self = [super init];
    if (self != nil)
    {
        self.reachableOnWWAN = YES;
        self.reachabilityRef = ref;
    }
    
    return self;
}

-(void)dealloc
{
    [self stopNotifier];
    
    if(self.reachabilityRef)
    {
        CFRelease(self.reachabilityRef);
        self.reachabilityRef = nil;
    }
    
    self.reachableBlock		= nil;
    self.unreachableBlock	= nil;
    
#if !(__has_feature(objc_arc))
    [super dealloc];
#endif
    
    
}

#pragma mark - Notifier Methods

// Notifier
// NOTE: This uses GCD to trigger the blocks - they *WILL NOT* be called on THE MAIN THREAD
// - In other words DO NOT DO ANY UI UPDATES IN THE BLOCKS.
//   INSTEAD USE dispatch_async(dispatch_get_main_queue(), ^{UISTUFF}) (or dispatch_sync if you want)

-(BOOL)startNotifier
{
    SCNetworkReachabilityContext    context = { 0, NULL, NULL, NULL, NULL };
    
    // this should do a retain on ourself, so as long as we're in notifier mode we shouldn't disappear out from under ourselves
    // woah
    self.reachabilityObject = self;
    
    
    
    // First, we need to create a serial queue.
    // We allocate this once for the lifetime of the notifier.
    self.reachabilitySerialQueue = dispatch_queue_create("cn.leancloud.im.reachability", NULL);
    if(self.reachabilitySerialQueue == nil)
    {
        return NO;
    }
    
#if __has_feature(objc_arc)
    context.info = (__bridge void *)self;
#else
    context.info = (void *)self;
#endif
    
    if (!SCNetworkReachabilitySetCallback(self.reachabilityRef, AVIMReachabilityCallback, &context))
    {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetCallback() failed: %s", SCErrorString(SCError()));
#endif
        
        // Clear out the dispatch queue
        if(self.reachabilitySerialQueue)
        {
#if NEEDS_DISPATCH_RETAIN_RELEASE
            dispatch_release(self.reachabilitySerialQueue);
#endif
            self.reachabilitySerialQueue = nil;
        }
        
        self.reachabilityObject = nil;
        
        return NO;
    }
    
    // Set it as our reachability queue, which will retain the queue
    if(!SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue))
    {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetDispatchQueue() failed: %s", SCErrorString(SCError()));
#endif
        
        // UH OH - FAILURE!
        
        // First stop, any callbacks!
        SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
        
        // Then clear out the dispatch queue.
        if(self.reachabilitySerialQueue)
        {
#if NEEDS_DISPATCH_RETAIN_RELEASE
            dispatch_release(self.reachabilitySerialQueue);
#endif
            self.reachabilitySerialQueue = nil;
        }
        
        self.reachabilityObject = nil;
        
        return NO;
    }
    
    return YES;
}

-(void)stopNotifier
{
    // First stop, any callbacks!
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
    
    // Unregister target from the GCD serial dispatch queue.
    SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);
    
    if(self.reachabilitySerialQueue)
    {
#if NEEDS_DISPATCH_RETAIN_RELEASE
        dispatch_release(self.reachabilitySerialQueue);
#endif
        self.reachabilitySerialQueue = nil;
    }
    
    self.reachabilityObject = nil;
}

#pragma mark - reachability tests

// This is for the case where you flick the airplane mode;
// you end up getting something like this:
//Reachability: WR ct-----
//Reachability: -- -------
//Reachability: WR ct-----
//Reachability: -- -------
// We treat this as 4 UNREACHABLE triggers - really apple should do better than this

#define testcase (kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)

-(BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags
{
    BOOL connectionUP = YES;
    
    if(!(flags & kSCNetworkReachabilityFlagsReachable))
        connectionUP = NO;
    
    if( (flags & testcase) == testcase )
        connectionUP = NO;
    
#if	TARGET_OS_IPHONE
    if(flags & kSCNetworkReachabilityFlagsIsWWAN)
    {
        // We're on 3G.
        if(!self.reachableOnWWAN)
        {
            // We don't want to connect when on 3G.
            connectionUP = NO;
        }
    }
#endif
    
    return connectionUP;
}

-(BOOL)isReachable
{
    SCNetworkReachabilityFlags flags;
    
    if(!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
        return NO;
    
    return [self isReachableWithFlags:flags];
}

-(BOOL)isReachableViaWWAN
{
#if	TARGET_OS_IPHONE
    
    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        // Check we're REACHABLE
        if(flags & kSCNetworkReachabilityFlagsReachable)
        {
            // Now, check we're on WWAN
            if(flags & kSCNetworkReachabilityFlagsIsWWAN)
            {
                return YES;
            }
        }
    }
#endif
    
    return NO;
}

-(BOOL)isReachableViaWiFi
{
    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        // Check we're reachable
        if((flags & kSCNetworkReachabilityFlagsReachable))
        {
#if	TARGET_OS_IPHONE
            // Check we're NOT on WWAN
            if((flags & kSCNetworkReachabilityFlagsIsWWAN))
            {
                return NO;
            }
#endif
            return YES;
        }
    }
    
    return NO;
}


// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
-(BOOL)isConnectionRequired
{
    return [self connectionRequired];
}

-(BOOL)connectionRequired
{
    SCNetworkReachabilityFlags flags;
    
    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    
    return NO;
}

// Dynamic, on demand connection?
-(BOOL)isConnectionOnDemand
{
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
                (flags & (kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand)));
    }
    
    return NO;
}

// Is user intervention required?
-(BOOL)isInterventionRequired
{
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
                (flags & kSCNetworkReachabilityFlagsInterventionRequired));
    }
    
    return NO;
}


#pragma mark - reachability status stuff

-(AVIMNetworkStatus)currentReachabilityStatus
{
    if([self isReachable])
    {
        if([self isReachableViaWiFi])
            return AVIMReachableViaWiFi;
        
#if	TARGET_OS_IPHONE
        return AVIMReachableViaWWAN;
#endif
    }
    
    return AVIMNotReachable;
}

-(SCNetworkReachabilityFlags)reachabilityFlags
{
    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        return flags;
    }
    
    return 0;
}

-(NSString*)currentReachabilityString
{
    AVIMNetworkStatus temp = [self currentReachabilityStatus];
    
    if(temp == reachableOnWWAN)
    {
        // Updated for the fact that we have CDMA phones now!
        return NSLocalizedString(@"Cellular", @"");
    }
    if (temp == AVIMReachableViaWiFi)
    {
        return NSLocalizedString(@"WiFi", @"");
    }
    
    return NSLocalizedString(@"No Connection", @"");
}

-(NSString*)currentReachabilityFlags
{
    return reachabilityFlags([self reachabilityFlags]);
}

#pragma mark - Callback function calls this method

-(void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    if([self isReachableWithFlags:flags])
    {
        if(self.reachableBlock)
        {
            self.reachableBlock(self);
        }
    }
    else
    {
        if(self.unreachableBlock)
        {
            self.unreachableBlock(self);
        }
    }
    
    // this makes sure the change notification happens on the MAIN THREAD
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kAVIMReachabilityChangedNotification
                                                            object:self];
    });
}

#pragma mark - Debug Description

- (NSString *) description
{
    NSString *description = [NSString stringWithFormat:@"<%@: %#x>",
                             NSStringFromClass([self class]), (unsigned int) self];
    return description;
}

@end
