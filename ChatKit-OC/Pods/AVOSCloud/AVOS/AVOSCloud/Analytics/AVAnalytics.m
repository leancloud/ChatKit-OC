//
//  AVAnalytics.m
//  LeanCloud
//
//  Created by Zhu Zeng on 6/20/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVAnalytics.h"
#import "AVAnalyticsImpl.h"
#import "AVPaasClient.h"
#import "AVAnalyticsUtils.h"
#import "AVUtils.h"

#import "AVOSCloud_Internal.h"
#import <CoreLocation/CoreLocation.h>

static NSString * endPoint = @"statistics";

static NSString * appOpen = @"!AV!AppOpen";
static NSString * appOpenWithPush = @"!AV!PushOpen";

static NSString * viewOpen = @"_viewOpen";
static NSString * viewClose = @"_viewClose";
static NSString * currentSessionId;


@implementation AVAnalytics

+ (void)setChannel:(NSString *)channel
{
    [AVAnalyticsImpl sharedInstance].appChannel = channel;
}

+ (void)setCustomInfo:(NSDictionary*)info{
    [AVAnalyticsImpl sharedInstance].customInfo=info;
}

+ (void)trackAppOpenedWithLaunchOptions:(NSDictionary *)launchOptions
{
    [AVAnalytics event:appOpen];
}

+ (void)trackAppOpenedWithRemoteNotificationPayload:(NSDictionary *)userInfo
{
    [AVAnalytics event:appOpenWithPush];
}

+ (void)start
{
    [AVAnalytics startWithReportPolicy:AV_BATCH channelId:@""];
}

+ (void)startWithReportPolicy:(AVReportPolicy)rp channelId:(NSString *)cid
{
    AVLoggerError(AVLoggerDomainDefault, @"The method is not supported anymore, please visit application web console to config.");
}

+ (void)startInternallyWithChannel:(NSString *)cid
{
    if (cid.length > 0) {
        [AVAnalyticsImpl sharedInstance].appChannel = cid;
    }
    
    BOOL enable = [AVAnalyticsImpl sharedInstance].enableReport;
    
    if (enable) {
        //the session is started at after app launch, so we just make it still
        if ([[AVAnalyticsImpl sharedInstance] currentSession]==nil) {
            [[AVAnalyticsImpl sharedInstance] beginSession];
        }
        
    } else {
        [self stop];
        
    }
    
}

+ (void)stop{
    [[AVAnalyticsImpl sharedInstance] stopRun];
}

+(void)setLogEnabled:(BOOL)value
{
    [AVAnalyticsImpl sharedInstance].enableDebugLog = value;
}

+ (void)setLogSendInterval:(double)second {
    if (second < 10 || second >= 60 * 60 * 24) {
        second = 10;
    }
    [AVAnalyticsImpl sharedInstance].sendInterval = second;
}

+(void)setAnalyticsEnabled:(BOOL)value
{
    [AVAnalyticsImpl sharedInstance].enableAnalytics = value;
}

+(void)setCrashReportEnabled:(BOOL)value
{
    [AVAnalyticsImpl sharedInstance].enableCrashReport = value;
}

+(void)setCrashReportEnabled:(BOOL)value completion:(void (^)(void))completion {
    [[AVAnalyticsImpl sharedInstance] setEnableCrashReport:value completion:completion];
}

+ (void)setCrashReportEnabled:(BOOL)value andIgnore:(BOOL)ignore {
    [[self class] setCrashReportEnabled:value];
    [AVAnalyticsImpl sharedInstance].enableIgnoreCrash = ignore;
}

+ (void)setCrashReportEnabled:(BOOL)value withIgnoreAlertTitle:(NSString*)alertTitle andMessage:(NSString*)alertMsg andQuitTitle:(NSString*)alertQuit andContinueTitle:(NSString*)alertContinue {
    [[self class] setCrashReportEnabled:value];
    if (value) {
        [AVAnalyticsImpl sharedInstance].enableIgnoreCrash = YES;
        
        NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:5];
        if (alertTitle) [dict setObject:alertTitle forKey:@"title"];
        if (alertMsg)   [dict setObject:alertMsg forKey:@"msg"];
        if (alertQuit)  [dict setObject:alertQuit forKey:@"quit"];
        if (alertContinue) [dict setObject:alertContinue forKey:@"continue"];
        
        if (dict.count>0) {
            [AVAnalyticsImpl sharedInstance].ignoreCrashAlertStrings = dict;
        }
    }
}

+ (void)logPageView:(NSString *)pageName seconds:(int)seconds
{
    [[AVAnalyticsImpl sharedInstance] addActivity:pageName seconds:seconds];
}

+ (void)beginLogPageView:(NSString *)pageName
{
    [[AVAnalyticsImpl sharedInstance] beginActivity:pageName];
}

+ (void)endLogPageView:(NSString *)pageName
{
    [[AVAnalyticsImpl sharedInstance] endActivity:pageName];
}

+ (void)event:(NSString *)eventId
{
    [[AVAnalyticsImpl sharedInstance] addEvent:eventId label:nil key:nil acc:1 du:0 attributes:nil];
}

+ (void)event:(NSString *)eventId label:(NSString *)label
{
    [[AVAnalyticsImpl sharedInstance] addEvent:eventId label:label key:nil acc:1 du:0 attributes:nil];
}

+ (void)event:(NSString *)eventId acc:(NSInteger)accumulation
{
     [[AVAnalyticsImpl sharedInstance] addEvent:eventId label:nil key:nil acc:accumulation du:0 attributes:nil];
}

+ (void)event:(NSString *)eventId label:(NSString *)label acc:(NSInteger)accumulation
{
    [[AVAnalyticsImpl sharedInstance] addEvent:eventId label:label key:nil acc:accumulation du:0 attributes:nil];
}

+ (void)event:(NSString *)eventId attributes:(NSDictionary *)attributes
{
    [[AVAnalyticsImpl sharedInstance] addEvent:eventId label:nil key:nil acc:1 du:0 attributes:attributes];
}

+ (void)beginEvent:(NSString *)eventId {
    [[AVAnalyticsImpl sharedInstance] beginEvent:eventId label:nil key:nil attributes:nil];
}

+ (void)endEvent:(NSString *)eventId {
    [[AVAnalyticsImpl sharedInstance] endEvent:eventId label:nil key:nil attributes:nil];
}

+ (void)beginEvent:(NSString *)eventId label:(NSString *)label {
    [[AVAnalyticsImpl sharedInstance] beginEvent:eventId label:label key:nil attributes:nil];
}

+ (void)endEvent:(NSString *)eventId label:(NSString *)label {
    [[AVAnalyticsImpl sharedInstance] endEvent:eventId label:label key:nil attributes:nil];
}

+ (void)beginEvent:(NSString *)eventId primarykey :(NSString *)keyName attributes:(NSDictionary *)attributes {
    [[AVAnalyticsImpl sharedInstance] beginEvent:eventId label:nil key:keyName attributes:attributes];
}

+ (void)endEvent:(NSString *)eventId primarykey:(NSString *)keyName {
    [[AVAnalyticsImpl sharedInstance] endEvent:eventId label:nil key:keyName attributes:nil];
}

+ (void)event:(NSString *)eventId durations:(int)millisecond {
    [[AVAnalyticsImpl sharedInstance] addEvent:eventId label:nil key:nil acc:1 du:millisecond attributes:nil];
}

+ (void)event:(NSString *)eventId label:(NSString *)label durations:(int)millisecond {
    [[AVAnalyticsImpl sharedInstance] addEvent:eventId label:nil key:nil acc:1 du:millisecond attributes:nil];
}

+ (void)event:(NSString *)eventId attributes:(NSDictionary *)attributes durations:(int)millisecond {
    [[AVAnalyticsImpl sharedInstance] addEvent:eventId label:nil key:nil acc:1 du:millisecond attributes:attributes];
}

+ (void)updateOnlineConfig
{
    [AVAnalytics updateOnlineConfigWithBlock:^(NSDictionary *dict, NSError *error) {
        
    }];
}

+ (void)updateOnlineConfigWithBlock:(AVDictionaryResultBlock)block {
    NSString *pathComponent = [NSString stringWithFormat:@"statistics/apps/%@/sendPolicy", [AVOSCloud getApplicationId]];
    NSString *endpoint = [[[AVOSCloud RESTBaseURL] URLByAppendingPathComponent:pathComponent] absoluteString];
    
    [[AVPaasClient sharedInstance] getObject:endpoint withParameters:nil block:^(id object, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // make sure we call the onlineConfigChanged in main thread
            // otherwise timer may not work correctly.
            if (error == nil) {
                [[AVAnalyticsImpl sharedInstance] onlineConfigChanged:object];
                block([AVAnalyticsImpl sharedInstance].onlineConfig, nil);
            } else {
                AVLoggerE(@"Update online config failed %@", error);
                block(nil, error);
            }
        });
    }];
}

+ (id)getConfigParams:(NSString *)key {
    return [[AVAnalyticsImpl sharedInstance].onlineConfig objectForKey:key];
}

+ (NSDictionary *)getConfigParams {
    return [AVAnalyticsImpl sharedInstance].onlineConfig;
}

+ (void)setLatitude:(double)latitude longitude:(double)longitude {
    [[AVAnalyticsImpl sharedInstance] setLatitude:latitude longitude:longitude];
}

+ (void)setLocation:(CLLocation *)location {
    [[AVAnalyticsImpl sharedInstance] setLatitude:location.coordinate.latitude
                                        longitude:location.coordinate.longitude];
}

+(void)startInternally {
    if ([[AVAnalyticsImpl sharedInstance] isLocalEnabled]) {
        [AVAnalytics startInternallyWithChannel:@""];
    }
    
    [AVAnalytics updateOnlineConfigWithBlock:^(NSDictionary *dict, NSError *error) {
        [AVAnalytics startInternallyWithChannel:@""];
    }];
}


@end
