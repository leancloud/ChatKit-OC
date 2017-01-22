//
//  AVPush.h
//  AVOS Inc
//

#import <Foundation/Foundation.h>
#import "AVPush.h"
#import "AVPush_Internal.h"
#import "AVPaasClient.h"
#import "AVUtils.h"
#import "AVQuery_Internal.h"
#import "AVInstallation_Internal.h"
#import "AVOSCloud_Internal.h"
#import "AVObjectUtils.h"

/*!
 A class which defines a push notification that can be sent from
 a client device.

 The preferred way of modifying or retrieving channel subscriptions is to use
 the AVInstallation class, instead of the class methods in AVPush.

 This class is currently for iOS only. LeanCloud does not handle Push Notifications
 to LeanCloud applications running on OS X. Push Notifications can be sent from OS X
 applications via Cloud Code or the REST API to push-enabled devices (e.g. iOS
 or Android).
 */

static BOOL _isProduction = YES;

NSString *const kAVPushTargetPlatformIOS = @"ios";
NSString *const kAVPushTargetPlatformAndroid = @"android";
NSString *const kAVPushTargetPlatformWindowsPhone = @"wp";

@implementation AVPush

@synthesize pushQuery = _pushQuery;
@synthesize pushChannels = _pushChannels;
@synthesize pushData = _pushData;
@synthesize expirationDate = _expirationDate;
@synthesize expireTimeInterval = _expireTimeInterval;
@synthesize pushTarget = _pushTarget;

+(NSString *)myObjectPath
{
    return [[[AVOSCloud RESTBaseURL] URLByAppendingPathComponent:@"push"] absoluteString];
}

-(id)init
{
    self = [super init];
    _pushChannels = [[NSMutableArray alloc] init];
    _pushData = [[NSMutableDictionary alloc] init];
    
    _pushTarget = [[NSMutableArray alloc] init];
    return self;
}

+ (instancetype)push
{
    AVPush * push = [[AVPush alloc] init];
    return push;
}

/*! @name Configuring a Push Notification */

/*!
 Sets the channel on which this push notification will be sent.
 @param channel The channel to set for this push. The channel name must start
 with a letter and contain only letters, numbers, dashes, and underscores.
 */
- (void)setChannel:(NSString *)channel
{
    [self.pushChannels removeAllObjects];
    [self.pushChannels addObject:channel];
}

- (void)setChannels:(NSArray *)channels
{
    [self.pushChannels removeAllObjects];
    [self.pushChannels addObjectsFromArray:channels];
}

- (void)setQuery:(AVQuery *)query
{
    self.pushQuery = query;
}

- (void)setMessage:(NSString *)message
{
    [self.pushData removeAllObjects];
    [self.pushData setObject:message forKey:@"alert"];
}

- (void)setData:(NSDictionary *)data
{
    [self.pushData removeAllObjects];
    [self.pushData addEntriesFromDictionary:data];
}

- (void)setPushToTargetPlatforms:(NSArray *)platforms {
    if (platforms) {
        self.pushTarget = [platforms mutableCopy];
    } else {
        self.pushTarget = [[NSMutableArray alloc] init];
    }
}

- (void)setPushToAndroid:(BOOL)pushToAndroid {
    if (pushToAndroid) {
        [self.pushTarget addObject:kAVPushTargetPlatformAndroid];
    } else {
        [self.pushTarget removeObject:kAVPushTargetPlatformAndroid];
    }
}

- (void)setPushToIOS:(BOOL)pushToIOS {
    if (pushToIOS) {
        [self.pushTarget addObject:kAVPushTargetPlatformIOS];
    } else {
        [self.pushTarget removeObject:kAVPushTargetPlatformIOS];
    }
}

- (void)setPushToWP:(BOOL)pushToWP {
    if (pushToWP) {
        [self.pushTarget addObject:kAVPushTargetPlatformWindowsPhone];
    } else {
        [self.pushTarget removeObject:kAVPushTargetPlatformWindowsPhone];
    }
}

- (void)setPushDate:(NSDate *)dateToPush{
    self.pushTime=dateToPush;
}

- (void)expireAtDate:(NSDate *)date
{
    self.expirationDate = date;
}

- (void)expireAfterTimeInterval:(NSTimeInterval)timeInterval
{
    self.expireTimeInterval = timeInterval;
}

- (void)clearExpiration
{
    self.expirationDate = nil;
    self.expireTimeInterval = 0.0;
}

+ (void)setProductionMode:(BOOL)isProduction {
    _isProduction = isProduction;
}

+ (BOOL)sendPushMessage:(AVPush *)push
                   wait:(BOOL)wait
                  block:(AVBooleanResultBlock)block
                  error:(NSError **)theError
{
    BOOL __block theResult = NO;
    BOOL __block hasCalledBack = NO;
    NSError __block *blockError = nil;
    
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
        blockError = error;
        
        if (wait) {
            theResult = (error == nil);
            hasCalledBack = YES;
        }
    }];
    
    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    };
    
    if (theError != NULL) *theError = blockError;
    return theResult;
}


+ (BOOL)sendPushMessageToChannel:(NSString *)channel
                     withMessage:(NSString *)message
                           error:(NSError **)error
{
    AVPush * push = [AVPush push];
    [push setChannel:channel];
    [push setMessage:message];
    return [AVPush sendPushMessage:push wait:YES block:^(BOOL succeeded, NSError *error) {} error:error];
}

+ (void)sendPushMessageToChannelInBackground:(NSString *)channel
                                 withMessage:(NSString *)message
{
    AVPush * push = [AVPush push];
    [push setChannel:channel];
    [push setMessage:message];
    [AVPush sendPushMessage:push wait:YES block:^(BOOL succeeded, NSError *error) {} error:nil];
}

+ (void)sendPushMessageToChannelInBackground:(NSString *)channel
                                 withMessage:(NSString *)message
                                       block:(AVBooleanResultBlock)block
{
    AVPush * push = [AVPush push];
    [push setChannel:channel];
    [push setMessage:message];
    [AVPush sendPushMessage:push wait:YES block:block error:nil];
}

+ (void)sendPushMessageToChannelInBackground:(NSString *)channel
                                 withMessage:(NSString *)message
                                      target:(id)target
                                    selector:(SEL)selector
{
    AVPush * push = [AVPush push];
    [push setChannel:channel];
    [push setMessage:message];
    [AVPush sendPushMessage:push wait:YES block:^(BOOL succeeded, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:@(succeeded) object:error];
    } error:nil];
}

+ (BOOL)sendPushMessageToQuery:(AVQuery *)query
                   withMessage:(NSString *)message
                         error:(NSError **)theError
{
    AVPush * push = [AVPush push];
    [push setQuery:query];
    [push setMessage:message];
    return [AVPush sendPushMessage:push wait:YES block:^(BOOL succeeded, NSError *error) {} error:theError];
}

+ (void)sendPushMessageToQueryInBackground:(AVQuery *)query
                               withMessage:(NSString *)message
{
    AVPush * push = [AVPush push];
    [push setQuery:query];
    [push setMessage:message];
    [AVPush sendPushMessage:push wait:NO block:^(BOOL succeeded, NSError *error) {} error:nil];
}

+ (void)sendPushMessageToQueryInBackground:(AVQuery *)query
                               withMessage:(NSString *)message
                                     block:(AVBooleanResultBlock)block
{
    AVPush * push = [AVPush push];
    [push setQuery:query];
    [push setMessage:message];
    [AVPush sendPushMessage:push wait:NO block:block error:nil];
}

- (BOOL)sendPush:(NSError **)error
{
    return [AVPush sendPushMessage:self wait:YES block:^(BOOL succeeded, NSError *error) {} error:error];
}

- (BOOL)sendPushAndThrowsWithError:(NSError * _Nullable __autoreleasing *)error {
    return [self sendPush:error];
}

- (void)sendPushInBackground
{
    [AVPush sendPushMessage:self wait:NO block:^(BOOL succeeded, NSError *error) {} error:nil];
}

-(NSDictionary *)queryData
{
    return [self.pushQuery assembleParameters];
}

-(NSDictionary *) pushChannelsData
{
    return @{channelsTag:self.pushChannels};
}

-(NSDictionary *)pushDataMessage
{
    return @{@"data": self.pushData};
}

-(NSMutableDictionary *)postData
{
    NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
    NSString *prod = @"prod";
    if (!_isProduction) {
        prod = @"dev";
    }
    [data setObject:prod forKey:@"prod"];
    if (self.pushQuery)
    {
        [data addEntriesFromDictionary:[self queryData]];
    }
    else if (self.pushChannels.count > 0)
    {
        [data addEntriesFromDictionary:[self pushChannelsData]];
    }
    
    if (self.expirationDate)
    {
        [data setObject:[AVObjectUtils stringFromDate:self.expirationDate] forKey:@"expiration_time"];
    }
    if (self.expireTimeInterval > 0)
    {
        NSDate * currentDate = [NSDate date];
        [data setObject:[AVObjectUtils stringFromDate:currentDate] forKey:@"push_time"];
        [data setObject:@(self.expireTimeInterval) forKey:@"expiration_interval"];
    }
    
    if (self.pushTime) {
        [data setObject:[AVObjectUtils stringFromDate:self.pushTime] forKey:@"push_time"];
    }
    
    if (self.pushTarget.count > 0)
    {
        NSMutableDictionary *where = [[NSMutableDictionary alloc] init];
        NSDictionary *condition = @{@"$in": self.pushTarget};
        [where setObject:condition forKey:deviceTypeTag];
        [data setObject:where forKey:@"where"];
    }
    
    [data addEntriesFromDictionary:[self pushDataMessage]];
    return data;
}

- (void)sendPushInBackgroundWithBlock:(AVBooleanResultBlock)block
{
    NSString *path = [AVPush myObjectPath];
    [[AVPaasClient sharedInstance] postObject:path
                               withParameters:[self postData]
                                   eventually:YES
                                        block:^(id object, NSError *error) {
                                                [AVUtils callBooleanResultBlock:block error:error];
    }];
}

- (void)sendPushInBackgroundWithTarget:(id)target selector:(SEL)selector
{
    [self sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:@(succeeded) object:error];
    }];
}

+ (BOOL)sendPushDataToChannel:(NSString *)channel
                     withData:(NSDictionary *)data
                        error:(NSError **)error
{
    AVPush * push = [AVPush push];
    [push setChannel:channel];
    [push setData:data];
    return [AVPush sendPushMessage:push wait:YES block:nil error:error];
}

+ (void)sendPushDataToChannelInBackground:(NSString *)channel
                                 withData:(NSDictionary *)data
{
    AVPush * push = [AVPush push];
    [push setChannel:channel];
    [push setData:data];
    [AVPush sendPushMessage:push wait:YES block:nil error:nil];
}

+ (void)sendPushDataToChannelInBackground:(NSString *)channel
                                 withData:(NSDictionary *)data
                                    block:(AVBooleanResultBlock)block
{
    AVPush * push = [AVPush push];
    [push setChannel:channel];
    [push setData:data];
    [AVPush sendPushMessage:push wait:NO block:block error:nil];
}

+ (void)sendPushDataToChannelInBackground:(NSString *)channel
                                 withData:(NSDictionary *)data
                                   target:(id)target
                                 selector:(SEL)selector
{
    AVPush * push = [AVPush push];
    [push setChannel:channel];
    [push setData:data];
    [AVPush sendPushMessage:push wait:NO block:^(BOOL succeeded, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:@(succeeded) object:error];
    } error:nil];
}

+ (BOOL)sendPushDataToQuery:(AVQuery *)query
                   withData:(NSDictionary *)data
                      error:(NSError **)error
{
    AVPush * push = [AVPush push];
    [push setQuery:query];
    [push setData:data];
    return [AVPush sendPushMessage:push wait:YES block:nil error:error];
}

+ (void)sendPushDataToQueryInBackground:(AVQuery *)query
                               withData:(NSDictionary *)data
{
    AVPush * push = [AVPush push];
    [push setQuery:query];
    [push setData:data];
    [AVPush sendPushMessage:push wait:NO block:nil error:nil];
}

+ (void)sendPushDataToQueryInBackground:(AVQuery *)query
                               withData:(NSDictionary *)data
                                  block:(AVBooleanResultBlock)block
{
    AVPush * push = [AVPush push];
    [push setQuery:query];
    [push setData:data];
    [AVPush sendPushMessage:push wait:NO block:block error:nil];
}

+ (NSSet *)getSubscribedChannels:(NSError **)error
{
    return [AVPush getSubscribedChannelsWithBlock:^(NSSet *channels, NSError *error) {
    } wait:YES error:error];
}

+ (NSSet *)getSubscribedChannelsAndThrowsWithError:(NSError * _Nullable __autoreleasing *)error {
    return [self getSubscribedChannels:error];
}

+ (void)getSubscribedChannelsInBackgroundWithBlock:(AVSetResultBlock)block
{
    [AVPush getSubscribedChannelsWithBlock:^(NSSet *channels, NSError *error) {
        [AVUtils callSetResultBlock:block set:channels error:error];
    } wait:NO error:nil];
}

+ (void)getSubscribedChannelsInBackgroundWithTarget:(id)target
                                           selector:(SEL)selector
{
    [AVPush getSubscribedChannelsWithBlock:^(NSSet *channels, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:channels object:error];
    } wait:NO error:nil];
}

+ (NSSet *)getSubscribedChannelsWithBlock:(AVSetResultBlock)block
                                     wait:(BOOL)wait
                                    error:(NSError **)theError
{
    BOOL __block theResult = NO;
    BOOL __block hasCalledBack = NO;
    NSError __block *blockError = nil;
    __block  NSSet * resultSet = nil;

    AVQuery * query = [AVInstallation installationQuery];
    [query whereKey:deviceTokenTag equalTo:[AVInstallation currentInstallation].deviceToken];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (objects.count > 0)
        {
            AVInstallation * installation = [objects objectAtIndex:0];
            resultSet = [NSSet setWithArray:installation.channels];
        }
        [AVUtils callSetResultBlock:block set:resultSet error:error];
        
        blockError = error;
        
        if (wait) {
            theResult = (error == nil);
            hasCalledBack = YES;
        }
    }];
    
    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    };
    
    if (theError != NULL) *theError = blockError;
    return resultSet;
}


+ (BOOL)subscribeToChannel:(NSString *)channel error:(NSError **)error
{
    AVInstallation * installation = [AVInstallation currentInstallation];
    [installation addUniqueObject:channel forKey:channelsTag];
    return [installation save:error];
}

+ (void)subscribeToChannelInBackground:(NSString *)channel
{
    AVInstallation * installation = [AVInstallation currentInstallation];
    [installation addUniqueObject:channel forKey:channelsTag];
    [installation saveInBackground];
}

+ (void)subscribeToChannelInBackground:(NSString *)channel
                                 block:(AVBooleanResultBlock)block
{
    AVInstallation * installation = [AVInstallation currentInstallation];
    [installation addUniqueObject:channel forKey:channelsTag];
    [installation saveInBackgroundWithBlock:block];
}

+ (void)subscribeToChannelInBackground:(NSString *)channel
                                target:(id)target
                              selector:(SEL)selector
{
    AVInstallation * installation = [AVInstallation currentInstallation];
    [installation addUniqueObject:channel forKey:channelsTag];
    [installation saveInBackgroundWithTarget:target selector:selector];
}

+ (BOOL)unsubscribeFromChannel:(NSString *)channel error:(NSError **)error
{
    AVInstallation * installation = [AVInstallation currentInstallation];
    [installation removeObject:channel forKey:channelsTag];
    return [installation save:error];
}

+ (void)unsubscribeFromChannelInBackground:(NSString *)channel
{
    AVInstallation * installation = [AVInstallation currentInstallation];
    [installation removeObject:channel forKey:channelsTag];
    [installation saveInBackground];
}


+ (void)unsubscribeFromChannelInBackground:(NSString *)channel
                                     block:(AVBooleanResultBlock)block
{
    AVInstallation * installation = [AVInstallation currentInstallation];
    [installation removeObject:channel forKey:channelsTag];
    [installation saveInBackgroundWithBlock:block];
}

+ (void)unsubscribeFromChannelInBackground:(NSString *)channel
                                    target:(id)target
                                  selector:(SEL)selector
{
    AVInstallation * installation = [AVInstallation currentInstallation];
    [installation removeObject:channel forKey:channelsTag];
    [installation saveInBackgroundWithTarget:target selector:selector];
}

@end
