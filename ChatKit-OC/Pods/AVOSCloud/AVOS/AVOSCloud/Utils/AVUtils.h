//
//  AVUtils.h
//  paas
//
//  Created by Zhu Zeng on 2/27/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVConstants.h"
#import "AVOSCloud.h"
#import "AVHelpers.h"

/**
 * Check the equality of two security key.
 */
BOOL LCSecKeyIsEqual(SecKeyRef key1, SecKeyRef key2);

/**
 * Get public key of given certificate.
 */
SecKeyRef LCGetPublicKeyFromCertificate(SecCertificateRef cert);

/**
 * Make certificate from base64 string.
 */
SecCertificateRef LCGetCertificateFromBase64String(NSString *base64);

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    #import <MobileCoreServices/MobileCoreServices.h>
#else
    #import <CoreServices/CoreServices.h>
#endif

@class AVObject;

@interface AVUtils : NSObject

+(void)warnMainThreadIfNecessary;

+(BOOL)containsProperty:(Class)objectClass property:(NSString *)name;
+ (BOOL)containsProperty:(NSString *)name inClass:(Class)objectClass containSuper:(BOOL)containSuper filterDynamic:(BOOL)filterDynamic;
+ (BOOL)isDynamicProperty:(NSString *)name inClass:(Class)objectClass withType:(Class)targetClass containSuper:(BOOL)containSuper;

+(void)copyPropertiesFrom:(NSObject *)src
                 toObject:(NSObject *)target;
+(void)copyPropertiesFromDictionary:(NSDictionary *)src
                         toNSObject:(NSObject *)target;

+(NSString *)jsonStringFromDictionary:(NSDictionary *)dictionary;
+(NSString *)jsonStringFromArray:(NSArray *)array;

+(void)performSelectorIfCould:(id)target
                     selector:(SEL)selector
                       object:(id)arg1
                       object:(id)arg2;

+ (NSString *)generateUUID;
+ (NSString *)generateCompactUUID;
+ (NSString *)deviceUUID;

#pragma mark - Block
+ (void)callBooleanResultBlock:(AVBooleanResultBlock)block
                         error:(NSError *)error;

+ (void)callIntegerResultBlock:(AVIntegerResultBlock)block
                        number:(NSInteger)number
                         error:(NSError *)error;

+ (void)callArrayResultBlock:(AVArrayResultBlock)block
                       array:(NSArray *)array
                       error:(NSError *)error;

+ (void)callObjectResultBlock:(AVObjectResultBlock)block
                       object:(AVObject *)object
                        error:(NSError *)error;

+ (void)callUserResultBlock:(AVUserResultBlock)block
                       user:(AVUser *)user
                      error:(NSError *)error;

+ (void)callIdResultBlock:(AVIdResultBlock)block
                   object:(id)object
                    error:(NSError *)error;

+ (void)callProgressBlock:(AVProgressBlock)block
                  percent:(NSInteger)percentDone;


+ (void)callImageResultBlock:(AVImageResultBlock)block
                       image:(UIImage *)image
                       error:(NSError *)error;

+ (void)callFileResultBlock:(AVFileResultBlock)block
                     AVFile:(AVFile *)file
                      error:(NSError *)error;

+(void)callSetResultBlock:(AVSetResultBlock)block
                      set:(NSSet *)set
                    error:(NSError *)error;
+(void)callCloudQueryResultBlock:(AVCloudQueryCallback)block
                          result:(AVCloudQueryResult *)result
                           error:error;

/*!
 Dispatch task on background thread.

 @param task The task to be dispatched.
 */
+ (void)asynchronizeTask:(void(^)())task;

#pragma mark - String Util
+ (NSString *)MIMEType:(NSString *)filePathOrName;
+ (NSString *)MIMETypeFromPath:(NSString *)fullPath;
+ (NSString *)contentTypeForImageData:(NSData *)data;

+ (NSString*)MD5ForFile:(NSString*)filePath;
+ (NSString*)SHAForFile:(NSString*)filePath;


#pragma mark - Network Util

#if !TARGET_OS_WATCH
+ (BOOL)networkIsReachableOrBetter;
+ (BOOL)networkIs3GOrBetter;
+ (BOOL)networkIsWifiOrBetter;
#endif

#pragma mark - Something about log

// the level is only for NSLogger
typedef enum LoggerLevel : NSUInteger {
    LoggerLevelError = 0,
    LoggerLevelWarning,
    LoggerLevelInfo,
    LoggerLevelVerbose,
    LoggerLevelInternal,
    LoggerLevelNum
} LoggerLevel;

@end

#define AV_WAIT_TIL_TRUE(signal, interval) \
do {                                       \
    while(!(signal)) {                     \
        @autoreleasepool {                 \
            if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:(interval)]]) { \
                [NSThread sleepForTimeInterval:(interval)]; \
            }                              \
        }                                  \
    }                                      \
} while (0)

#define AV_WAIT_WITH_ROUTINE_TIL_TRUE(signal, interval, routine) \
do {                                       \
    while(!(signal)) {                     \
        @autoreleasepool {                 \
            routine;                       \
            if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:(interval)]]) { \
                [NSThread sleepForTimeInterval:(interval)]; \
            }                              \
        }                                  \
    }                                      \
} while (0)

@interface NSString (AVAES256)
- (NSString *)AVAES256Encrypt;
- (NSString *)AVAES256Decrypt;
@end

