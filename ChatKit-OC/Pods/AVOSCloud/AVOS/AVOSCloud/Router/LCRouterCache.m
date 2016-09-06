//
//  LCRouterCache.m
//  AVOS
//
//  Created by Tang Tianyong on 5/9/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import "LCRouterCache.h"
#import "LCKeyValueStore.h"

static NSString *LCRouterKey = @"LCRouterKey";

static NSString *LCURLKey = @"url";
static NSString *LCLastModifiedKey = @"last_modified";

extern NSString *LCAPIHostEntryKey;
extern NSString *LCPushRouterHostEntryKey;
extern NSString *LCTTLKey;

@interface LCRouterCache ()

/// The table of router info indexed by service region.
@property (nonatomic, strong) NSMutableDictionary *routerInfoTable;

@end

@implementation LCRouterCache

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LCRouterCache *sharedInstance;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[LCRouterCache alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        [self loadRouterInfoTableFromCache];
    }

    return self;
}

- (void)loadRouterInfoTableFromCache {
    NSData *data = [[LCKeyValueStore sharedInstance] dataForKey:LCRouterKey];

    if (data) {
        _routerInfoTable = [[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
    } else {
        _routerInfoTable = [[NSMutableDictionary alloc] init];
    }
}

- (NSMutableDictionary *)loadRouterInfoForServiceRegion:(AVServiceRegion)serviceRegion {
    NSNumber *key = @(serviceRegion);
    NSMutableDictionary *routerInfo = self.routerInfoTable[key];

    if (!routerInfo) {
        routerInfo = self.routerInfoTable[key] = [NSMutableDictionary dictionary];
    }

    return routerInfo;
}

- (void)cacheAPIHostWithServiceRegion:(AVServiceRegion)serviceRegion
                                 host:(NSString *)host
                         lastModified:(NSTimeInterval)lastModified
                                  TTL:(NSTimeInterval)TTL
{
    NSDictionary *entry = @{
        LCURLKey: host,
        LCLastModifiedKey: @(lastModified),
        LCTTLKey: @(TTL)
    };

    NSMutableDictionary *routerInfo = [self loadRouterInfoForServiceRegion:serviceRegion];
    routerInfo[LCAPIHostEntryKey] = entry;
    [self save];
}

- (void)cachePushRouterHostWithServiceRegion:(AVServiceRegion)serviceRegion
                                        host:(NSString *)host
                                lastModified:(NSTimeInterval)lastModified
                                         TTL:(NSTimeInterval)TTL
{
    NSDictionary *entry = @{
        LCURLKey: host,
        LCLastModifiedKey: @(lastModified),
        LCTTLKey: @(TTL)
    };

    NSMutableDictionary *routerInfo = [self loadRouterInfoForServiceRegion:serviceRegion];
    routerInfo[LCPushRouterHostEntryKey] = entry;
    [self save];
}

- (void)save {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.routerInfoTable];
    [[LCKeyValueStore sharedInstance] setData:data forKey:LCRouterKey];
}

- (NSString *)APIHostForServiceRegion:(AVServiceRegion)serviceRegion {
    return [self URLStringForServiceRegion:serviceRegion entryKey:LCAPIHostEntryKey];
}

- (NSString *)pushRouterHostForServiceRegion:(AVServiceRegion)serviceRegion {
    return [self URLStringForServiceRegion:serviceRegion entryKey:LCPushRouterHostEntryKey];
}

- (BOOL)isValidEntry:(NSDictionary *)entry {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval lastModified = [entry[LCLastModifiedKey] doubleValue];
    NSTimeInterval TTL = [entry[LCTTLKey] doubleValue];

    return now >= lastModified && now < lastModified + TTL;
}

- (NSString *)URLStringForServiceRegion:(AVServiceRegion)serviceRegion entryKey:(NSString *)entryKey {
    NSMutableDictionary *routerInfo = self.routerInfoTable[@(serviceRegion)];
    NSDictionary *entry = routerInfo[entryKey];

    if (entry) {
        if ([self isValidEntry:entry]) {
            return entry[LCURLKey];
        } else {
            /* If cache is expired, delete it. */
            [routerInfo removeObjectForKey:entryKey];
            [self save];
        }
    }

    return nil;
}

@end
