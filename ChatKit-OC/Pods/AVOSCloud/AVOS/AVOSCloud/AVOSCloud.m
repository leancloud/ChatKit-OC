//
//  paas.m
//  paas
//
//  Created by Zhu Zeng on 2/25/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVOSCloud.h"
#import "AVOSCloud_Internal.h"
#import "AVConfiguration.h"
#import "AVConfiguration_extension.h"
#import "AVPaasClient.h"
#import "AVUploaderManager.h"
#import "AVScheduler.h"
#import "AVPersistenceUtils.h"

#if !TARGET_OS_WATCH
#import "AVAnalytics_Internal.h"
#endif

#import "AVUtils.h"
#include "AVOSCloud_Art.inc"
#import "AVAnalyticsUtils.h"
#import "LCNetworkStatistics.h"
#import "AVObjectUtils.h"

#if AV_IOS_ONLY && !TARGET_OS_WATCH
#import "AVWebSocketWrapper.h"
#endif

#import "LCRouter.h"
#import "LCRouter_internal.h"
#import "SDMacros.h"

#define PUSH_GROUP_CN @"g0"
#define PUSH_GROUP_US @"a0"

static AVVerbosePolicy _verbosePolicy       = kAVVerboseShow;
NSString * const LCRootDomain      = @"leancloud.cn";
NSString * const LCRootCertificate = @"MIIFDzCCA/egAwIBAgIQECg10GmSYWMKtzx/By5NMTANBgkqhkiG9w0BAQsFADBEMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEdMBsGA1UEAxMUR2VvVHJ1c3QgU1NMIENBIC0gRzMwHhcNMTQxMTI4MDAwMDAwWhcNMTYwOTI0MjM1OTU5WjCBjDELMAkGA1UEBhMCQ04xEDAOBgNVBAgTB0JlaWppbmcxEDAOBgNVBAcUB0JlaWppbmcxMjAwBgNVBAoUKU1laSBXZWkgU2h1IFFpYW4gKCBCZWlqaW5nICkgSVQgQ28uLCBMdGQuMQwwCgYDVQQLFANPUFMxFzAVBgNVBAMUDioubGVhbmNsb3VkLmNuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzHX5I4zHZcHerO3x0l5pScvqKE8MlK/6hzrDONDsBuMnfkAPRpkPPGB6HfaAAGjyStsi5hZrPgOA3r+6lActiapjnRnfTSo57tJyF/5XexLOdzU45fhNO41mJYiSlGAK0L+EUQSlnSClxixPDIwkkpbF8XYrrpPnZeSCzm62Jk38Lx6GUheZH3UzmC5JPmcqBgmAidmi36wFk7UWT2c6fmmDA+DWJBxdt5+/MhLG7OcFEP0YeiSDXwirnSlQphMswIn1d+XprX/BHqnvlQgnTPZeIrYraVmTlA2qjOWZLKlZExhLaSnOqT/XLQN9q0fAHrKswhrBAzOycvvbt/9HswIDAQABo4IBsjCCAa4wJwYDVR0RBCAwHoIOKi5sZWFuY2xvdWQuY26CDGxlYW5jbG91ZC5jbjAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIFoDArBgNVHR8EJDAiMCCgHqAchhpodHRwOi8vZ24uc3ltY2IuY29tL2duLmNybDCBoQYDVR0gBIGZMIGWMIGTBgpghkgBhvhFAQc2MIGEMD8GCCsGAQUFBwIBFjNodHRwczovL3d3dy5nZW90cnVzdC5jb20vcmVzb3VyY2VzL3JlcG9zaXRvcnkvbGVnYWwwQQYIKwYBBQUHAgIwNQwzaHR0cHM6Ly93d3cuZ2VvdHJ1c3QuY29tL3Jlc291cmNlcy9yZXBvc2l0b3J5L2xlZ2FsMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAfBgNVHSMEGDAWgBTSb/eW9IU/cjwwfSPahXibo3xafDBXBggrBgEFBQcBAQRLMEkwHwYIKwYBBQUHMAGGE2h0dHA6Ly9nbi5zeW1jZC5jb20wJgYIKwYBBQUHMAKGGmh0dHA6Ly9nbi5zeW1jYi5jb20vZ24uY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQDdrrEg1t+LtyE5Roy5dhe7yM0tb5pcy+hEP1ZXncwv4SMldTWPejuomwF5vt2lX0FEhzrd1k9Ndk5LJq5x5SrCHos1kTO/MxkRvg7eUkErOYM0AK3j3I37xZv/rRN4UOJVKh1i4e88hgrAXhxLLQn96d8zzMJbpRYiBz3cW6I8w+bR5BtwVpgzJU5Z3gLDDJLVqwSDUjNpFrlmBor0kh7izPc5WAg5xkZ5ovQgp5Mwc1l9FByIqNZvY/pfGZBkEzeSP73rfccWg3Y7vz+mORgHDpSxAqmyna2hXn8aiEl3FW1v0w1PgJAskNmxt8zNAg38Jpuv7I1sDNjX/tyC1je0";

static BOOL LCInitialized = NO;
static NSMutableArray *AVOSCloudModules = nil;

AVServiceRegion LCEffectiveServiceRegion = AVServiceRegionDefault;

@implementation AVOSCloud

+ (void)setAllLogsEnabled:(BOOL)enabled {
    [AVLogger setAllLogsEnabled:enabled];
}

+ (void)enableAVOSCloudModule:(Class<AVOSCloudModule>)cls {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AVOSCloudModules = [[NSMutableArray alloc] init];
    });
    if (LCInitialized) {
        [NSException raise:NSInternalInconsistencyException format:@"Should enable module %@ before +[AVOSCloud setApplicationId:clientKey:].", NSStringFromClass(cls)];
    }
    [AVOSCloudModules addObject:cls];
}

+ (void)setVerbosePolicy:(AVVerbosePolicy)verbosePolicy {
    _verbosePolicy = verbosePolicy;
}

+ (void)logApplicationInfo {
    const char *s = (const char *)AVOSCloud_Art_inc;
    printf("%s\n", s);
    printf("appid: %s\n", [[self getApplicationId] UTF8String]);
    NSDictionary *dict = [AVAnalyticsUtils deviceInfo];
    for (NSString *key in dict) {
        id value = [dict objectForKey:key];
        printf("%s: %s\n", [key UTF8String], [[NSString stringWithFormat:@"%@", value] UTF8String]);
    }
    printf("----------------------------------------------------------\n");
}

+ (void)updateRouterInBackground {
    LCRouter *router = [LCRouter sharedInstance];
    router.serviceRegion = LCEffectiveServiceRegion;

    [router updateInBackground];
}

+ (void)initializePaasClient {
    AVPaasClient *paasClient = [AVPaasClient sharedInstance];

    paasClient.applicationId = [self getApplicationId];
    paasClient.clientKey     = [self getClientKey];

    // always handle offline requests, include analytics collection
    [paasClient handleAllArchivedRequests];
}

+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey
{
    AVConfiguration *configuration = [AVConfiguration sharedInstance];

    configuration.applicationId  = applicationId;
    configuration.applicationKey = clientKey;

    if (_verbosePolicy == kAVVerboseShow) {
        [self logApplicationInfo];
    }

    [self initializePaasClient];
    [self updateRouterInBackground];
    [[LCNetworkStatistics sharedInstance] start];

    for (Class<AVOSCloudModule> cls in AVOSCloudModules) {
        [cls AVOSCloudDidInitializeWithApplicationId:applicationId clientKey:clientKey];
    }

#if !TARGET_OS_WATCH
    [AVAnalytics startInternally];
#endif

    LCInitialized = YES;
}

+ (BOOL)isTwoArrayEqual:(NSArray *)array withAnotherArray:(NSArray *)anotherArray
{
    if (array.count != anotherArray.count) {
        return NO;
    }
    
    NSSet *set = [NSSet setWithArray:array];
    NSMutableSet *set1 = [NSMutableSet setWithSet:set];
    NSSet *set2 = [NSSet setWithArray:anotherArray];
    [set1 unionSet:set2];

    return set1.count == array.count;
}

+ (NSString *)getApplicationId
{
    return [AVConfiguration sharedInstance].applicationId;
}

+ (NSString *)getClientKey
{
    return [AVConfiguration sharedInstance].applicationKey;
}

+ (void)setLastModifyEnabled:(BOOL)enabled{
    [AVPaasClient sharedInstance].isLastModifyEnabled=enabled;
}

/**
 *  获取是否开启LastModify支持
 */
+ (BOOL)getLastModifyEnabled{
    return [AVPaasClient sharedInstance].isLastModifyEnabled;
}

+(void)clearLastModifyCache {
    [[AVPaasClient sharedInstance] clearLastModifyCache];
}

+ (void)useAVCloud
{
    [self setServiceRegion:AVServiceRegionUrulu];
}

+ (void)useAVCloudUS
{
    [self setServiceRegion:AVServiceRegionUS];
}

+ (void)useAVCloudCN
{
    [self setServiceRegion:AVServiceRegionCN];
}

+ (void)setStorageType:(AVStorageType)storageType
{
    [AVUploaderManager sharedInstance].storageType = storageType;
}

+ (AVStorageType)storageTypeForServiceRegion:(AVServiceRegion)serviceRegion {
    AVStorageType storageType = AVStorageTypeDefault;

    switch (serviceRegion) {
    case AVServiceRegionCN:
        storageType = AVStorageTypeQiniu;
        break;
    case AVServiceRegionUS:
        storageType = AVStorageTypeS3;
        break;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    case AVServiceRegionUrulu:
        break;
#pragma clang diagnostic pop
    }

    return storageType;
}

+ (NSString *)pushGroupForServiceRegion:(AVServiceRegion)serviceRegion {
    NSString *pushGroup = nil;

    switch (serviceRegion) {
    case AVServiceRegionCN:
        pushGroup = @"g0";
        break;
    case AVServiceRegionUS:
        pushGroup = @"a0";
        break;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    case AVServiceRegionUrulu:
        break;
#pragma clang diagnostic pop
    }

    if (!pushGroup) {
        pushGroup = [self pushGroupForServiceRegion:AVServiceRegionDefault];
    }

    return pushGroup;
}

+ (NSURL *)RESTBaseURL {
    return [[NSURL URLWithString:[LCRouter sharedInstance].APIURLString] URLByAppendingPathComponent:API_VERSION];
}

+ (void)setServiceRegion:(AVServiceRegion)serviceRegion {
    if (LCInitialized) {
        [NSException raise:NSInternalInconsistencyException format:@"Service region should be set before +[AVOSCloud setApplicationId:clientKey:]."];
    }

    LCEffectiveServiceRegion = serviceRegion;

    /* Setup file uploading service. */
    [self setStorageType:[self storageTypeForServiceRegion:serviceRegion]];

    NSString *pushGroup = [self pushGroupForServiceRegion:serviceRegion];

#if AV_IOS_ONLY && !TARGET_OS_WATCH
    /* Setup push group for IM 1.0. */
    [AVWebSocketWrapper setDefaultPushGroup:pushGroup];
#endif
    [AVUploaderManager sharedInstance].serviceRegion = serviceRegion;
}

#pragma mark - Network

+ (NSTimeInterval)networkTimeoutInterval
{
    return [[AVPaasClient sharedInstance] timeoutInterval];
}

+ (void)setNetworkTimeoutInterval:(NSTimeInterval)time
{
    [[AVPaasClient sharedInstance] setTimeoutInterval:time];
}

#pragma mark - Log

static AVLogLevel avlogLevel = AVLogLevelDefault;

+ (void)setLogLevel:(AVLogLevel)level {
    // if log level is too high and is not secret mode
    if ((int)level >= (1 << 4) && !getenv("SHOWMETHEMONEY")) {
        NSLog(@"unsupport log level");
        level = AVLogLevelDefault;
    }
    avlogLevel = level;
}

+ (AVLogLevel)logLevel {
    return avlogLevel;
}

#pragma mark Schedule work

+ (NSInteger)queryCacheExpiredDays {
    return [AVScheduler sharedInstance].queryCacheExpiredDays;
}

+ (void)setQueryCacheExpiredDays:(NSInteger)days {
    [AVScheduler sharedInstance].queryCacheExpiredDays = days;
}

+ (NSInteger)fileCacheExpiredDays {
    return [AVScheduler sharedInstance].fileCacheExpiredDays;
}

+ (void)setFileCacheExpiredDays:(NSInteger)days {
    [AVScheduler sharedInstance].fileCacheExpiredDays = days;
}

+(void)requestSmsCodeWithPhoneNumber:(NSString *)phoneNumber
                            callback:(AVBooleanResultBlock)callback {
    [self requestSmsCodeWithPhoneNumber:phoneNumber appName:nil operation:nil timeToLive:0 callback:callback];
}

+(void)requestSmsCodeWithPhoneNumber:(NSString *)phoneNumber
                             appName:(NSString *)appName
                           operation:(NSString *)operation
                          timeToLive:(NSUInteger)ttl
                            callback:(AVBooleanResultBlock)callback {
    NSParameterAssert(phoneNumber);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//    [dict setObject:phoneNumber forKey:@"mobilePhoneNumber"];
    if (appName) {
        [dict setObject:appName forKey:@"name"];
    }
    if (operation) {
        [dict setObject:operation forKey:@"op"];
    }
    if (ttl > 0) {
        [dict setObject:[NSNumber numberWithUnsignedInteger:ttl] forKey:@"ttl"];
    }
    [self requestSmsCodeWithPhoneNumber:phoneNumber templateName:nil variables:dict callback:callback];
}

+(void)requestSmsCodeWithPhoneNumber:(NSString *)phoneNumber
                        templateName:(NSString *)templateName
                           variables:(NSDictionary *)variables
                            callback:(AVBooleanResultBlock)callback {
    NSParameterAssert(phoneNumber);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:phoneNumber forKey:@"mobilePhoneNumber"];
    if (templateName) {
        [dict setObject:templateName forKey:@"template"];
    }
    [dict addEntriesFromDictionary:variables];
    [[AVPaasClient sharedInstance] postObject:@"requestSmsCode" withParameters:dict block:^(id object, NSError *error) {
        [AVUtils callBooleanResultBlock:callback error:error];
    }];
}

+ (void)requestVoiceCodeWithPhoneNumber:(NSString *)phoneNumber
                                    IDD:(NSString *)IDD
                               callback:(AVBooleanResultBlock)callback {
    NSParameterAssert(phoneNumber);

    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    params[@"smsType"] = @"voice";
    params[@"mobilePhoneNumber"] = phoneNumber;

    if (IDD) {
        params[@"IDD"] = IDD;
    }

    [[AVPaasClient sharedInstance] postObject:@"requestSmsCode" withParameters:params block:^(id object, NSError *error) {
        [AVUtils callBooleanResultBlock:callback error:error];
    }];
}

+(void)verifySmsCode:(NSString *)code callback:(AVBooleanResultBlock)callback {
    @throw [NSException exceptionWithName:@"Interface not supported" reason:@"This interface is altered by +[verifySmsCode:mobilePhoneNumber:callback:]" userInfo:nil];
}

+(void)verifySmsCode:(NSString *)code mobilePhoneNumber:(NSString *)phoneNumber callback:(AVBooleanResultBlock)callback {
    NSParameterAssert(code);
    NSParameterAssert(phoneNumber);
    
    NSString *path=[NSString stringWithFormat:@"verifySmsCode/%@?mobilePhoneNumber=%@",code, phoneNumber];
    [[AVPaasClient sharedInstance] postObject:path withParameters:nil block:^(id object, NSError *error) {
        [AVUtils callBooleanResultBlock:callback error:error];
    }];
}

+ (NSDate *)getServerDate:(NSError *__autoreleasing *)error {
    __block NSDate *date = nil;
    __block NSError *errorStrong;
    __block BOOL finished = NO;

    [[AVPaasClient sharedInstance] getObject:@"date" withParameters:nil block:^(id object, NSError *error_) {
        if (error) errorStrong = error_;
        if (!error_) date = [AVObjectUtils dateFromDictionary:object];
        finished = YES;
    }];

    AV_WAIT_TIL_TRUE(finished, 0.1);

    if (error) {
        *error = errorStrong;
    }

    return date;
}

+ (void)getServerDateWithBlock:(void (^)(NSDate *, NSError *))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSDate  *date  = [self getServerDate:&error];

        [AVUtils callIdResultBlock:block object:date error:error];
    });
}

#pragma mark - Push Notification

+ (void)registerForRemoteNotification {
#if AV_TARGET_OS_IOS
    [self registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound categories:nil];
#elif AV_TARGET_OS_OSX
    [self registerForRemoteNotificationTypes:
     NSRemoteNotificationTypeAlert |
     NSRemoteNotificationTypeBadge |
     NSRemoteNotificationTypeSound categories:nil];
#endif
}

+ (void)registerForRemoteNotificationTypes:(NSUInteger)types categories:(NSSet *)categories {
#if AV_TARGET_OS_IOS
    UIApplication *application = [UIApplication sharedApplication];

    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        [application registerForRemoteNotificationTypes:types];
    } else {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:categories];

        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
#elif AV_TARGET_OS_OSX
    NSApplication *application = [NSApplication sharedApplication];
    [application registerForRemoteNotificationTypes:types];
#endif
}

+ (void)handleRemoteNotificationsWithDeviceToken:(NSData *)deviceToken constructingInstallationWithBlock:(void (^)(AVInstallation *))block {
    AVInstallation *installation = [AVInstallation currentInstallation];

    @weakify(installation, weakInstallation);

    [installation setDeviceTokenFromData:deviceToken];

    if (block) {
        block(installation);
    }

    [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            AVLoggerError(AVLoggerDomainIM, @"Installation saved failed, reason: %@.", error.localizedDescription);
        } else {
            AVLoggerInfo(AVLoggerDomainIM, @"Installation saved OK, object id: %@.", weakInstallation.objectId);
        }
    }];
}

+ (void)handleRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self handleRemoteNotificationsWithDeviceToken:deviceToken constructingInstallationWithBlock:nil];
}

@end
