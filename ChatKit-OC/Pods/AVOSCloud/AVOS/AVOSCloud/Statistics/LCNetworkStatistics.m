//
//  LCNetworkStatistics.m
//  AVOS
//
//  Created by Tang Tianyong on 6/26/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "LCNetworkStatistics.h"
#import "LCKeyValueStore.h"
#import "AVAnalyticsUtils.h"
#import "AVPaasClient.h"
#import "AVUtils.h"
#import <libkern/OSAtomic.h>

#define LC_INTERVAL_HALF_AN_HOUR 30 * 60

static NSTimeInterval LCNetworkStatisticsCheckInterval  = 60; // A minute
static NSTimeInterval LCNetworkStatisticsUploadInterval = 24 * 60 * 60; // A day

static NSString *LCNetworkStatisticsInfoKey = @"LCNetworkStatisticsInfoKey";
static NSString *LCNetworkStatisticsLastUpdateKey = @"LCNetworkStatisticsLastUpdateKey";
static NSInteger LCNetworkStatisticsMaxCount = 100;
static NSInteger LCNetworkStatisticsCacheSize = 20;

@interface LCNetworkStatistics ()

@property (atomic, assign) BOOL enable;
@property (atomic, strong) NSMutableDictionary *cachedStatisticDict;
@property (atomic, assign) NSTimeInterval cachedLastUpdatedAt;

@end

@implementation LCNetworkStatistics {
    OSSpinLock _statisticDataLock;
}

+ (instancetype)sharedInstance {
    static LCNetworkStatistics *instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        _statisticDataLock = OS_SPINLOCK_INIT;
    }

    return self;
}

- (NSMutableDictionary *)statisticsInfo {
    if (self.cachedStatisticDict) {
        return self.cachedStatisticDict;
    }

    NSMutableDictionary *dict = nil;

    LCKeyValueStore *store = [LCKeyValueStore sharedInstance];

    NSData *data = [store dataForKey:LCNetworkStatisticsInfoKey];

    if (data) {
        dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else {
        dict = [NSMutableDictionary dictionary];
    }

    return dict;
}

- (void)saveStatisticsDict:(NSDictionary *)statisticsDict {
    self.cachedStatisticDict = [statisticsDict mutableCopy];
}

- (void)writeCachedStatisticsDict {
    if (!self.cachedStatisticDict) return;

    LCKeyValueStore *store = [LCKeyValueStore sharedInstance];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.cachedStatisticDict];

    [store setData:data forKey:LCNetworkStatisticsInfoKey];
}

- (void)addIncrementalAttribute:(NSInteger)amount forKey:(NSString *)key {
    OSSpinLockLock(&_statisticDataLock);

    NSMutableDictionary *statisticsInfo = [self statisticsInfo];

    NSNumber *value = statisticsInfo[key];

    if (value) {
        statisticsInfo[key] = @([value integerValue] + amount);
    } else {
        statisticsInfo[key] = @(amount);
    }

    [self saveStatisticsDict:statisticsInfo];

    OSSpinLockUnlock(&_statisticDataLock);
}

- (void)addAverageAttribute:(double)amount forKey:(NSString *)key {
    OSSpinLockLock(&_statisticDataLock);

    NSMutableDictionary *statisticsInfo = [self statisticsInfo];

    NSNumber *value = statisticsInfo[key];

    if (value) {
        statisticsInfo[key] = @(([value doubleValue] + amount) / 2.0);
    } else {
        statisticsInfo[key] = @(amount);
    }

    [self saveStatisticsDict:statisticsInfo];

    OSSpinLockUnlock(&_statisticDataLock);
}

- (void)uploadStatisticsInfo:(NSDictionary *)statisticsInfo {
    NSDictionary *deviceInfo = [AVAnalyticsUtils deviceInfo];
    NSDictionary *payload = @{
        @"attributes": statisticsInfo,
        @"client": @{
#if !TARGET_OS_WATCH
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
            @"id": deviceInfo[@"device_id"],
#endif
#endif
            @"platform": deviceInfo[@"os"],
            @"app_version": deviceInfo[@"app_version"],
            @"sdk_version": deviceInfo[@"sdk_version"]
        }
    };

    AVPaasClient *client = [AVPaasClient sharedInstance];
    NSURLRequest *request = [client requestWithPath:@"always_collect" method:@"POST" headers:nil parameters:payload];

    [client
     performRequest:request
     success:^(NSHTTPURLResponse *response, id responseObject) {
         // Reset network statistics data
         LCKeyValueStore *store = [LCKeyValueStore sharedInstance];
         [store deleteKey:LCNetworkStatisticsInfoKey];

         // Clean cached statistic dict
         self.cachedStatisticDict = nil;

         // Increase check interval to save CPU time
         LCNetworkStatisticsCheckInterval = LC_INTERVAL_HALF_AN_HOUR;

         [self updateLastUpdateAt];
     }
     failure:nil];
}

- (void)updateLastUpdateAt {
    LCKeyValueStore *store = [LCKeyValueStore sharedInstance];

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSData *dateData = [NSData dataWithBytes:&now length:sizeof(now)];

    [store setData:dateData forKey:LCNetworkStatisticsLastUpdateKey];

    self.cachedLastUpdatedAt = now;
}

- (NSTimeInterval)lastUpdateAt {
    if (self.cachedLastUpdatedAt > 0) {
        return self.cachedLastUpdatedAt;
    }

    LCKeyValueStore *store = [LCKeyValueStore sharedInstance];
    NSData *dateData = [store dataForKey:LCNetworkStatisticsLastUpdateKey];

    if (dateData) {
        NSTimeInterval lastUpdateAt = 0;
        [dateData getBytes:&lastUpdateAt length:sizeof(lastUpdateAt)];

        self.cachedLastUpdatedAt = lastUpdateAt;

        return lastUpdateAt;
    }

    return 0;
}

- (BOOL)atTimeToUpload {
    NSTimeInterval lastUpdateAt = [self lastUpdateAt];

    if (lastUpdateAt <= 0) {
        return YES;
    }

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];

    if (now - lastUpdateAt > LCNetworkStatisticsUploadInterval) {
        return YES;
    } else {
        return NO;
    }
}

- (void)startInBackground {
    NSAssert(![NSThread isMainThread], @"This method must run in background.");

    AV_WAIT_WITH_ROUTINE_TIL_TRUE(!self.enable, LCNetworkStatisticsCheckInterval, ({
        NSMutableDictionary *statisticsInfo = [self statisticsInfo];

        NSInteger total = [statisticsInfo[@"total"] integerValue];

        if (total > 0) {
            if ([self atTimeToUpload] || total > LCNetworkStatisticsMaxCount) {
                [self uploadStatisticsInfo:statisticsInfo];
            }
            if (total % LCNetworkStatisticsCacheSize == 0) {
                [self writeCachedStatisticsDict];
            }
        }
    }));
}

- (void)start {
    if (!self.enable) {
        self.enable = YES;
        [self performSelectorInBackground:@selector(startInBackground) withObject:nil];
    }
}

- (void)stop {
    self.enable = NO;
}

@end
