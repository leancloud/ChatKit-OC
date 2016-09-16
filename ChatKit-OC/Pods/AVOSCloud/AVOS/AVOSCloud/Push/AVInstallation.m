//
//  AVInstallation.m
//  LeanCloud

#import <Foundation/Foundation.h>
#import "AVObject_Internal.h"
#import "AVQuery.h"
#import "AVInstallation.h"
#import "AVPaasClient.h"
#import "AVInstallation_Internal.h"
#import "AVUtils.h"
#import "AVObjectUtils.h"
#import "AVPersistenceUtils.h"
#import "AVErrorUtils.h"

@implementation AVInstallation

@synthesize deviceType  = _deviceType;
@synthesize installationId = _installationId;
@synthesize deviceToken  = _deviceToken;
@synthesize deviceProfile = _deviceProfile;
@synthesize badge = _badge;
@synthesize timeZone  = _timeZone;
@synthesize channels  = _channels;


+ (AVQuery *)query
{
    AVQuery *query = [[AVQuery alloc] initWithClassName:@"_Installation"];
    return query;
}

+(AVQuery *)installationQuery
{
    AVQuery *query = [[AVQuery alloc] initWithClassName:[AVInstallation className]];
    return query;
}

+(NSString *)installationTag
{
    return @"Installation";
}

+(AVInstallation *)installation
{
    AVInstallation * installation = [[AVInstallation alloc] init];
    return installation;
}

+ (AVInstallation *)currentInstallation
{
    if ([AVPaasClient sharedInstance].currentInstallation)
    {
        return [AVPaasClient sharedInstance].currentInstallation;
    }
    AVInstallation * installation = [AVInstallation installation];
    [AVPaasClient sharedInstance].currentInstallation = installation;
    return installation;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.className = [AVInstallation className];
        self.deviceType = [AVInstallation deviceType];
        
        NSString *path = [AVPersistenceUtils currentInstallationArchivePath];
        if ([AVPersistenceUtils fileExist:path]) {
            NSMutableDictionary *installationDict = [NSMutableDictionary dictionaryWithDictionary:[AVPersistenceUtils getJSONFromPath:path]];
            if (installationDict) {
                [AVObjectUtils copyDictionary:installationDict toObject:self];
            }
        }
    }
    return self;
}

- (void)setDeviceTokenFromData:(NSData *)deviceTokenData {
    [self setDeviceTokenFromData:deviceTokenData submit:NO];
}

- (void)setDeviceTokenFromData:(NSData *)deviceTokenData submit:(BOOL)submit
{
    NSString *deviceToken = [[deviceTokenData description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (submit || ![self.deviceToken isEqualToString:deviceToken]) {
        self.deviceToken = deviceToken;

        [self.requestManager synchronize:^{
            [self updateInstallationDictionary:[self.requestManager setDict]];
        }];
    }
}

+(NSString *)deviceType
{
#if TARGET_OS_TV
    return @"tvos";
#elif TARGET_OS_WATCH
    return @"watchos";
#elif TARGET_OS_IOS
    return @"ios";
#elif AV_TARGET_OS_OSX
    return @"osx";
#else
    return @"unknown";
#endif
}

- (NSMutableDictionary *)installationDictionaryForCache {
    NSMutableDictionary *data = [self postData];
    return data;
}

- (void)saveInstallationToLocalCache {
    [AVPersistenceUtils saveJSON:[self installationDictionaryForCache]
                          toPath:[AVPersistenceUtils currentInstallationArchivePath]];
}

- (BOOL)isDirty {
    if ([super isDirty]) {
        return YES;
    } else if ([AVInstallation currentInstallation] == self) {
        /* If cache expired, we deem that it is dirty. */
        if (!self.updatedAt || [self.updatedAt timeIntervalSinceNow] < - 60 * 60 * 24) {
            return YES;
        }
    }

    return NO;
}

-(NSError *)preSave {
    if ([self isDirty]) {
        [self.requestManager synchronize:^{
            [self updateInstallationDictionary:[self.requestManager setDict]];
        }];
    }
    if (self.installationId==nil && self.deviceToken==nil) {
        return [AVErrorUtils errorWithCode:kAVErrorInvalidDeviceToken errorText:@"无法保存Installation数据, 请检查deviceToken是否在`application: didRegisterForRemoteNotificationsWithDeviceToken`方法中正常设置"];
    }

    return nil;
}

-(void)postSave {
    [super postSave];
    [self saveInstallationToLocalCache];
}

-(NSMutableDictionary *)updateInstallationDictionary:(NSMutableDictionary * )data
{
    self.timeZone = [[NSTimeZone systemTimeZone] name];

    [data addEntriesFromDictionary:@{
        badgeTag: @(self.badge),
        deviceTypeTag: [AVInstallation deviceType],
        timeZoneTag: self.timeZone,
        topicTag: [NSBundle mainBundle].bundleIdentifier ?: @""
    }];

    if (self.objectId) {
        [data setObject:self.objectId forKey:@"objectId"];
    }
    if (self.channels)
    {
        [data setObject:self.channels forKey:channelsTag];
    }
    if (self.installationId)
    {
        [data setObject:self.installationId forKey:installationIdTag];
    }
    if (self.deviceToken)
    {
        [data setObject:self.deviceToken forKey:deviceTokenTag];
    }
    if (self.deviceProfile)
    {
        [data setObject:self.deviceProfile forKey:deviceProfileTag];
    }

    NSDictionary *updationData = [AVObjectUtils dictionaryFromObject:self.localData];

    [data addEntriesFromDictionary:updationData];

    return data;
}

+(NSString *)className
{
    return @"_Installation";
}

+(NSString *)endPoint
{
    return @"installations";    
}

-(void)setBadge:(NSInteger)badge {
    _badge = badge;
    [self addSetRequest:badgeTag object:@(self.badge)];
}

-(void)setChannels:(NSArray *)channels {
    if ([_channels isEqual:channels]) {
        return;
    }
    _channels = channels;
    [self addSetRequest:channelsTag object:self.channels];
}

-(void)setDeviceToken:(NSString *)deviceToken {
    if ([_deviceToken isEqualToString:deviceToken]) {
        return;
    }
    _deviceToken = deviceToken;
    [self addSetRequest:deviceTokenTag object:self.deviceToken];
}

-(void)setDeviceProfile:(NSString *)deviceProfile {
    if ([_deviceProfile isEqualToString:deviceProfile]) {
        return;
    }
    _deviceProfile = deviceProfile;
    [self addSetRequest:deviceProfileTag object:self.deviceProfile];
}

- (void)postProcessBatchRequests:(NSMutableArray *)requests {
    NSString *classEndpoint = [NSString stringWithFormat:@"/%@/%@", API_VERSION, [[self class] endPoint]];

    for (NSMutableDictionary *request in [requests copy]) {
        if ([request_path(request) hasPrefix:classEndpoint] && [request_method(request) isEqualToString:@"PUT"]) {
            request[@"method"] = @"POST";
            request[@"path"]   = classEndpoint;
            request[@"body"][@"objectId"]    = self.objectId;
            request[@"body"][@"deviceType"]  = self.deviceType;
            request[@"body"][@"deviceToken"] = self.deviceToken;
        }
    }
}

@end
