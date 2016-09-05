//
//  AVCacheManager.m
//  LeanCloud
//
//  Created by Summer on 13-3-19.
//  Copyright (c) 2013年 AVOS. All rights reserved.
//

#import "AVCacheManager.h"
#import "AVErrorUtils.h"
#import "AVUtils.h"
#import "AVPersistenceUtils.h"


@interface AVCacheManager ()
@property (nonatomic, copy) NSString *diskCachePath;

// This is singleton, so the queue doesn't need release
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t cacheQueue;
#else
@property (nonatomic, assign) dispatch_queue_t cacheQueue;
#endif

@end

@implementation AVCacheManager
+ (AVCacheManager *)sharedInstance {
    static dispatch_once_t once;
    static AVCacheManager *_sharedInstance;
    dispatch_once(&once, ^{
        _sharedInstance = [[AVCacheManager alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - Accessors
+ (NSString *)path {
    return [AVPersistenceUtils avCacheDirectory];
}

- (NSString *)diskCachePath {
    if (!_diskCachePath) {
        _diskCachePath = [AVCacheManager path];
    }
    return _diskCachePath;
}

- (dispatch_queue_t)cacheQueue {
    if (!_cacheQueue) {
        _cacheQueue = dispatch_queue_create("avos.paas.cacheQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _cacheQueue;
}

- (NSString *)pathForKey:(NSString *)key {
    return [self.diskCachePath stringByAppendingPathComponent:key];
}

- (BOOL)hasCacheForKey:(NSString *)key {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self pathForKey:[key AVMD5String]]];
}
- (BOOL)hasCacheForMD5Key:(NSString *)key {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self pathForKey:key]];
}

- (void)getWithKey:(NSString *)key maxCacheAge:(NSTimeInterval)maxCacheAge block:(AVIdResultBlock)block {
    dispatch_async(self.cacheQueue, ^{
        
        BOOL isTooOld = NO;
        id diskResult =nil;
        if (maxCacheAge<=0) {
            isTooOld=YES;
        } else {
             diskResult=[AVPersistenceUtils getJSONFromPath:[self pathForKey:[key AVMD5String]]];
            if (diskResult && maxCacheAge > 0) {
                NSDate *lastModified = [AVPersistenceUtils lastModified:[self pathForKey:[key AVMD5String]]];
                if ([[NSDate date] timeIntervalSinceDate:lastModified] > maxCacheAge) {
                    isTooOld = YES;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (diskResult && !isTooOld) {
                if (block) block(diskResult, nil);
            } else {
                if (block) block(nil, [NSError errorWithDomain:kAVErrorDomain code:kAVErrorCacheMiss userInfo:nil]);
            }
        });
    });
}

- (void)saveJSON:(id)JSON forKey:(NSString *)key {
    dispatch_async(self.cacheQueue, ^{
        [AVPersistenceUtils saveJSON:JSON toPath:[self pathForKey:[key AVMD5String]]];
    });
}

#pragma mark - Clear Cache
+ (BOOL)clearAllCache {
    BOOL __block success;
    dispatch_sync([AVCacheManager sharedInstance].cacheQueue, ^{
        NSString *path = [AVCacheManager path];
        success = [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        // ignore create diectory error
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    });
    
    return success;
}

+ (BOOL)clearCacheMoreThanOneDay {
    return [AVCacheManager clearCacheMoreThanDays:1];
}

+ (BOOL)clearCacheMoreThanDays:(NSInteger)numberOfDays {
    BOOL __block success = NO;
    
    // 为了避免冲突把读写cache的操作都放在cacheQueue里面, 这里是同步的block删除
    dispatch_sync([AVCacheManager sharedInstance].cacheQueue, ^{
        [AVPersistenceUtils deleteFilesInDirectory:[AVCacheManager path] moreThanDays:numberOfDays];
    });
    
    return success;
}

- (void)clearCacheForKey:(NSString *)key {
    dispatch_sync(self.cacheQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:[key AVMD5String]] error:NULL];
    });
}

- (void)clearCacheForMD5Key:(NSString *)key {
    dispatch_sync(self.cacheQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:key] error:NULL];
    });
}
@end
