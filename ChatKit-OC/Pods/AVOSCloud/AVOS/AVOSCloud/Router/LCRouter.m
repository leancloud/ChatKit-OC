//
//  LCRouter.m
//  AVOS
//
//  Created by Tang Tianyong on 5/9/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import "LCRouter.h"
#import "LCRouter_internal.h"
#import "LCRouterCache.h"
#import "AVPaasClient.h"

static NSString *const APIVersion = @"1.1";

/// Table of router indexed by service region.
static NSDictionary *routerURLTable = nil;

/// Table of default API host indexed by service region.
static NSDictionary *defaultAPIHostTable = nil;

/// Table of default push router host indexed by service region.
static NSDictionary *defaultPushRouterHostTable = nil;

/// Fallback API host for service region if host not found.
static NSString *const fallbackAPIHost = @"api.leancloud.cn";

/// Fallback push router path for service region if host not found.
static NSString *const fallbackPushRouterHost = @"router-g0-push.leancloud.cn";

/// Notification name for router update.
NSString *const LCRouterDidUpdateNotification = @"LCRouterDidUpdateNotification";

/// Keys of router response.
NSString *LCAPIHostEntryKey        = @"api_server";
NSString *LCPushRouterHostEntryKey = @"push_router_server";
NSString *LCTTLKey                 = @"ttl";

extern AVServiceRegion LCEffectiveServiceRegion;

@interface LCRouter ()

@property (nonatomic, copy) NSString *APIHost;
@property (nonatomic, copy) NSString *pushRouterHost;

@end

@implementation LCRouter

+ (void)load {
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        [self doInitialize];
    });
}

+ (void)doInitialize {
    defaultAPIHostTable = @{
        @(AVServiceRegionCN): @"api.leancloud.cn",
        @(AVServiceRegionUS): @"us-api.leancloud.cn",
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        @(AVServiceRegionUrulu): @"cn-stg1.leancloud.cn"
#pragma clang diagnostic pop
    };

    defaultPushRouterHostTable = @{
        @(AVServiceRegionCN): @"router-g0-push.leancloud.cn",
        @(AVServiceRegionUS): @"router-a0-push.leancloud.cn"
    };

    routerURLTable = @{
        @(AVServiceRegionCN): @"https://app-router.leancloud.cn/1/route"
    };
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LCRouter *sharedInstance;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[LCRouter alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        _serviceRegion = LCEffectiveServiceRegion;
    }

    return self;
}

- (void)cacheAPIHostWithHost:(NSString *)host lastModified:(NSTimeInterval)lastModified TTL:(NSTimeInterval)TTL {
    [[LCRouterCache sharedInstance] cacheAPIHostWithServiceRegion:self.serviceRegion host:host lastModified:lastModified TTL:TTL];
}

- (void)cachePushRouterHostWithHost:(NSString *)host lastModified:(NSTimeInterval)lastModified TTL:(NSTimeInterval)TTL {
    [[LCRouterCache sharedInstance] cachePushRouterHostWithServiceRegion:self.serviceRegion host:host lastModified:lastModified TTL:TTL];
}

- (void)updateInBackground {
    [[self class] doInitialize];
    NSString *router = routerURLTable[@(_serviceRegion)];

    if (router) {
        NSDictionary *parameters = @{@"appId": [AVOSCloud getApplicationId]};

        [[AVPaasClient sharedInstance] getObject:router withParameters:parameters block:^(NSDictionary *result, NSError *error) {
            if (!error && result)
                [self handleResult:result];
        }];
    }
}

- (void)handleResult:(NSDictionary *)result {
    NSString *APIHost = result[LCAPIHostEntryKey];
    NSString *pushRouterHost = result[LCPushRouterHostEntryKey];

    NSTimeInterval lastModified = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval TTL = [result[LCTTLKey] doubleValue];

    [[LCRouterCache sharedInstance] cacheAPIHostWithServiceRegion:self.serviceRegion host:APIHost lastModified:lastModified TTL:TTL];
    [[LCRouterCache sharedInstance] cachePushRouterHostWithServiceRegion:self.serviceRegion host:pushRouterHost lastModified:lastModified TTL:TTL];

    self.APIHost = APIHost;
    self.pushRouterHost = pushRouterHost;

    [[NSNotificationCenter defaultCenter] postNotificationName:LCRouterDidUpdateNotification object:self];
}

- (NSString *)APIHost {
    /* Pardon me for the quick and dirty code.
       All QCloud application ends with suffix "-9Nh9j0Va"
     */
    if ([[AVOSCloud getApplicationId] hasSuffix:@"-9Nh9j0Va"]) {
        return @"e1-api.leancloud.cn";
    }

    NSString *cachedAPIHost = [[LCRouterCache sharedInstance] APIHostForServiceRegion:self.serviceRegion];

    return (
        cachedAPIHost ?:
        defaultAPIHostTable[@(self.serviceRegion)] ?:
        fallbackAPIHost
    );
}

- (NSString *)pushRouterHost {
    NSString *cachedPushRouterHost = [[LCRouterCache sharedInstance] pushRouterHostForServiceRegion:self.serviceRegion];

    return (
        cachedPushRouterHost ?:
        defaultPushRouterHostTable[@(self.serviceRegion)] ?:
        fallbackPushRouterHost
    );
}

- (NSString *)APIURLString {
    return [NSString stringWithFormat:@"https://%@", self.APIHost];
}

- (NSString *)versionedAPIURLString {
    return [[NSURL URLWithString:[self APIURLString]] URLByAppendingPathComponent:API_VERSION].absoluteString;
}

- (NSURL *)versionedAPIURL {
    return [NSURL URLWithString:[self versionedAPIURLString]];
}

- (NSString *)pushRouterURLString {
    return [NSString stringWithFormat:@"https://%@", self.pushRouterHost];
}

@end
