//
//  AVAnalyticsImpl.m
//  paas
//
//  Created by Zhu Zeng on 8/2/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVAnalyticsImpl.h"
#import "AVAnalyticsSession.h"
#import "AVExceptionHandler.h"
#import "AVPaasClient.h"
#import "AVAnalyticsUtils.h"
#import "AVGlobal.h"
#import "AVUtils.h"

#import "AVOSCloud_Internal.h"
#import "AVErrorUtils.h"

static NSString *const kAVOnlineConfig = @"AVOS_ONLINE_CONFIG";

@interface AVAnalyticsImpl()

@property (nonatomic, readwrite, copy) NSString * currentSessionName;
@property (nonatomic, readwrite) int messageCount;
/// The timestamp when application did enter background
@property (nonatomic, readwrite) NSTimeInterval pauseTimeStamp;
@property (nonatomic, readwrite) double latitude;
@property (nonatomic, readwrite) double longitude;
@property (nonatomic, readwrite, strong) NSMutableArray * sessions;
@property (nonatomic, strong) NSTimer *reportTimer;

@end

@implementation AVAnalyticsImpl

@synthesize reportPolicy =  _reportPolicy;

+(AVAnalyticsImpl *)sharedInstance
{
    static dispatch_once_t once;
    static AVAnalyticsImpl * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init
{
    self = [super init];
    _appChannel = @"App Store";
    _sessions = [[NSMutableArray alloc] init];
    
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(av_applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(av_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
#else
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(av_applicationWillResignActive:) name:NSApplicationDidResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(av_applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
#endif
    
    _sendInterval = AV_DEFAULT_REPORT_INTERVAL;
    _enableDebugLog = NO;
//    _enableCrashReport = YES;
    _reportPolicy = AV_SEND_INTERVAL;
    _enableReport = YES;
    _enableAnalytics = YES;
    
    _pauseTimeStamp=0;
    
    NSDictionary *onlineConfig= [[NSUserDefaults standardUserDefaults] objectForKey:kAVOnlineConfig];
    if (onlineConfig) {
        [self loadOnlineConfig:onlineConfig];
    }
    return self;
}

- (void)stopRun {
    [self endSessionWithoutPost];
    [self sendSessionsThenClose];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.reportTimer invalidate];
    self.reportTimer = nil;
}

-(void)loadOnlineConfig:(NSDictionary *)dict {
    id valueObject = [dict valueForKey:@"policy"];
    int policy = AV_SEND_INTERVAL;
    if (valueObject != nil) {
        policy = [valueObject intValue];
    }
    if (policy < AV_REALTIME || policy > AV_SEND_ON_EXIT) {
        self.reportPolicy = AV_SEND_INTERVAL;
    } else {
        self.reportPolicy = policy;
    }
    self.enableReport = [[dict valueForKey:enableTag] boolValue];
    self.onlineConfig = [dict valueForKey:@"parameters"];
}

-(void)_enableCrashReportRunloop{
    [AVExceptionHandler installAVOSUncaughtExceptionHandler];
}

-(void)setEnableCrashReport:(BOOL)e {
    [self setEnableCrashReport:e completion:nil];
}

-(void)setEnableCrashReport:(BOOL)enabled completion:(void (^)(void))completion {
    _enableCrashReport = enabled;
    if (self.enableCrashReport) {
        //tick exception handler out of main runloop,
        //in case some app start with a crash in `application:didFinishLaunchingWithOptions:`
        dispatch_async(dispatch_get_main_queue(), ^{
            [AVExceptionHandler installAVOSUncaughtExceptionHandler];
            if (completion) {
                completion();
            }
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [AVExceptionHandler uninstallAVOSUncaughtExceptionHandler];
            if (completion) {
                completion();
            }
        });
    }
}
-(void)addException:(NSException *)exception{
    if (!self.enableAnalytics) {
        return;
    }
    
    NSArray *trace=[[exception userInfo] objectForKey:AVOS_UncaughtExceptionHandlerAddressesKey];
    NSString *strace=nil;
    
    if (trace.count>0) {
        strace=[trace componentsJoinedByString:@"\n"];
    } else {
        strace=@"";
    }
    
    NSMutableDictionary * dict = [AVAnalyticsUtils deviceInfo];
    
    [dict addEntriesFromDictionary:@{
                                     @"type": [exception name],
                                     @"reason": [exception reason],
                                     @"stack_trace": strace,
                                     @"time":  @([AVAnalyticsUtils currentTimestamp]),
                                     }];
    
    if (self.customInfo != nil) {
        [dict setObject:self.customInfo forKey:@"customInfo"];
    }
    
    //add app build uuid to match dSYM
    [dict setObject:[AVExceptionHandler appBuildUUID] forKey:@"build_uuid"];
    
    [[AVPaasClient sharedInstance] postObject:[[[self class] myObjectPath] stringByAppendingPathComponent:@"crash"]
                               withParameters:dict
                                   eventually:YES
                                        block:^(id object, NSError *error)
     {
         if (error == nil) {
             AVLoggerI(@"Save success %@", [object description]);
         } else {
             AVLoggerI(@"Save failed %@ error %@", dict, error);
         }
     }];
}

-(AVAnalyticsSession *)currentSession
{
    for(AVAnalyticsSession * session in [self.sessions copy]) {
        if ([session.sessionId isEqualToString:self.currentSessionName]) {
            return session;
        }
    }
    return nil;
}

-(NSTimeInterval)threshold
{
    return AV_REGARD_NEW_SESSION * 1000;
}

-(BOOL)shouldRegardAsNewSession
{
    NSTimeInterval current = [AVAnalyticsUtils currentTimestamp];
    NSTimeInterval start = self.pauseTimeStamp;
    NSTimeInterval delta = current - start;
    if (delta > [self threshold] && start > 0) {
        return true;
    }
    return false;
}

/// @warning When user terminates it, applicationWillEnterBackground: will run. If the app crashes, nothing we can do except catching SIGKILL. When click home button, av_applicationWillResignActive: will be called firstly. Then If user terminates, appWillDidEnterBackground: will be called. So it's correct to use av_applicationWillResignActive: as we are recording active duration.
- (void)av_applicationWillResignActive:(id)sender {
    if (!self.enableAnalytics) {
        return;
    }
    if (self.pauseTimeStamp>0) {
        return;
    }
    if (self.reportPolicy == AV_SEND_INTERVAL) {
        [self.reportTimer invalidate];
        self.reportTimer = nil;
    }
    // application paused
    self.pauseTimeStamp = [AVAnalyticsUtils currentTimestamp];
    [[self currentSession] pauseSession];
    [self incMessageCount];
    
    // should always send no matter report policy. it serves as offline cache.
    [self sendSessions];
}

- (void)av_applicationDidBecomeActive:(id)sender {
    if (!self.enableAnalytics) {
        return;
    }
    [[self currentSession] resumeSession];
    if ([self  shouldRegardAsNewSession]) {
        NSString * activityName = [self currentSession].currentActivityName;
        [self endSessionWithoutPost];
        [self sendSessionsThenClearAll:YES];
        [self beginSession];
        if (activityName.length > 0) {
            [self beginActivity:activityName];
        }
    }
    self.pauseTimeStamp=0;
    if (self.reportPolicy == AV_SEND_INTERVAL) {
        [self sendWithInterval];
    }
}

-(AVAnalyticsSession *)createSession
{
    AVAnalyticsSession * session = [[AVAnalyticsSession alloc] init];
    return session;
}

-(void)beginSession
{
    AVAnalyticsSession * session = [self currentSession];
    if (session == nil) {
        session = [self createSession];
        self.currentSessionName = session.sessionId;
        [self.sessions addObject:session];
    }
    [session beginSession];
    [self incMessageCount];
    [self postRecording];
}

- (void)endSessionWithoutPost {
    [[self currentSession] endSession];
    self.currentSessionName = @"";
    [self incMessageCount];
}

-(void)endSession
{
    [self endSessionWithoutPost];
    [self postRecording];
}

-(void)addActivity:(NSString *)name seconds:(int)seconds
{
    [[self currentSession] addActivity:name seconds:seconds];
    [self incMessageCount];
    [self postRecording];
}

-(void)beginActivity:(NSString *)name
{
    [[self currentSession] beginActivity:name];
    [self incMessageCount];
    [self postRecording];
}

-(void)endActivity:(NSString *)name
{
    [[self currentSession] endActivity:name];
    [self incMessageCount];
    [self postRecording];
}

-(void)addEvent:(NSString *)eventId
          label:(NSString *)label
            key:(NSString *)key
            acc:(NSInteger)acc
             du:(int)du
     attributes:(NSDictionary *)attributes {
    [[self currentSession] addEvent:eventId label:label key:key acc:acc du:du attributes:attributes];
    [self incMessageCount];
    [self postRecording];
}

-(void)beginEvent:(NSString *)name
            label:(NSString *)label
              key:(NSString *)key
       attributes:(NSDictionary *)attributes {
    [[self currentSession] beginEvent:name label:label key:key attributes:attributes];
}

-(void)endEvent:(NSString *)name
          label:(NSString *)label
            key:(NSString *)key
     attributes:(NSDictionary *)attributes
{
    [[self currentSession] endEvent:name label:label primaryKey:key attributes:attributes];
    [self incMessageCount];
    [self postRecording];
}

-(NSDictionary *)launchDictionary
{
    AVAnalyticsSession * session = [self currentSession];
    if (session==nil) {
        return nil;
    }
    NSDictionary *dict=@{kAVSessionIdTag: session.sessionId, kAVDateTag: @([session.durationImpl createTimeStampInMilliSeconds])};
    return dict;
}

-(NSDictionary *)eventDictionary
{
    return @{};
}

-(void)sync {
    for(AVAnalyticsSession * session in [self.sessions copy]) {
        [session sync];
    }
}

-(NSArray *)allSessionData
{
    NSMutableDictionary * devInfo = [NSMutableDictionary dictionary];
    [devInfo setObject:self.appChannel forKey:@"channel"];
    if (self.longitude != 0 && self.latitude != 0) {//latitude can be negative
        [devInfo setObject:@(self.longitude) forKey:@"longitude"];
        [devInfo setObject:@(self.latitude) forKey:@"latitude"];
    }
    
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:self.sessions.count];
    for(AVAnalyticsSession * session in [self.sessions copy]) {
        NSDictionary * dict = [session jsonDictionary:devInfo];
        [array addObject:dict];
    }
    return array;
}

-(void)clearAllSessionData
{
    [self.sessions removeAllObjects];
}

-(void)clearSessionEventsAndActivities:(NSString *)sessionId {
    for(AVAnalyticsSession * session in [self.sessions copy]) {
        if ([session.sessionId isEqualToString:sessionId]) {
            [session.activities removeAllObjects];
            [session.events removeAllObjects];
            return;
        }
    }
}

-(void)cleanSessionFinished {
    NSMutableArray * discardedItems = [NSMutableArray array];
    for(AVAnalyticsSession * session in [self.sessions copy]) {
        if ([session isStoppped]) {
            [discardedItems addObject:session];
        }
    }
    [self.sessions removeObjectsInArray:discardedItems];
}

+(NSString *)myObjectPath
{
    return [[[AVOSCloud RESTBaseURL] URLByAppendingPathComponent:@"stats"] absoluteString];
}

-(void)sendSessions {
    [self sendSessionsThenClearAll:NO];
}

/// @warning It will clear all session data, it is just used when app terminates, enter foreground, analytics not enabled. After it, if you want to record a new session, you should call beginSession.
- (void)sendSessionsThenClose {
    [self sendSessionsThenClearAll:YES];
}

- (void)sendOneSession:(NSDictionary *)session {
    [[AVPaasClient sharedInstance] postObject:[[[self class] myObjectPath] stringByAppendingString:@"/collect"]
                               withParameters:[session copy]
                                   eventually:YES
                                        block:^(id object, NSError *error)
     {
         // @warning eventually is YES. We do not care the result, as it will eventually save the result.
     }];
    // Clean events and activities
    NSString * sid = session[@"events"][@"terminate"][@"sessionId"];
    [self clearSessionEventsAndActivities:sid];
}

-(void)sendSessionsThenClearAll:(BOOL)clearAll {
    if (!self.enableAnalytics) {
        return;
    }
    
    [self sync];
    [self debugDump];
    
    if (!self.enableReport) {
        AVLoggerI(@"Report is disabled by caller");
        return;
    }
    
    NSArray *array = [self allSessionData];
    for(NSDictionary * dict in array) {
        [self sendOneSession:dict];
    }
    [self cleanSessionFinished];
    if (clearAll) {
        [self clearAllSessionData];
    }
}

-(int)incMessageCount {
    return ++self.messageCount;
}

-(BOOL)exceedMessageCountThreshold
{
    return (self.messageCount >= AV_MESSAGE_COUNT_THRESHOLD);
}

-(void)resetMessageCount
{
    self.messageCount = 0;
}

-(void)setReportPolicy:(AVReportPolicy)reportPolicy {
    _reportPolicy = reportPolicy;
    [self postRecording];
}

-(AVReportPolicy)reportPolicy {
    BOOL debug = [AVAnalyticsUtils inDebug];
    if (_reportPolicy == AV_REALTIME && !debug) {
        return AV_BATCH;
    }
    if (_reportPolicy == AV_SENDWIFIONLY && !debug) {
        return AV_BATCH;
    }
    return _reportPolicy;
}

/**
 *  Post to server what have been recording.
 */
-(void)postRecording {
    if (self.reportPolicy ==  AV_REALTIME) {
        [self sendSessions];
    } else if (self.reportPolicy == AV_BATCH) {
        [self sendWithBatch];
    } else if (self.reportPolicy == AV_SENDWIFIONLY) {
        if ([AVAnalyticsUtils isWiFiConnection]) {
            [self sendWithBatch];
        }
    } else if (self.reportPolicy == AV_SEND_INTERVAL) {
        [self sendWithInterval];
    }
}

-(void)sendWithBatch {
    if ([self exceedMessageCountThreshold]) {
        [self sendSessions];
        [self resetMessageCount];
    }
}

-(void)sendWithInterval
{
    [self.reportTimer invalidate];//stop the previous timer in case it's not tick then we should get 2 timers fired
    self.reportTimer = [NSTimer scheduledTimerWithTimeInterval:self.sendInterval target:self selector:@selector(reportTimerFired:) userInfo:nil repeats:NO];
}

- (void)reportTimerFired:(id)sender {
    if (self.reportPolicy != AV_SEND_INTERVAL) {
        return;
    }
    [self sendSessions];
    self.reportTimer = [NSTimer scheduledTimerWithTimeInterval:self.sendInterval target:self selector:@selector(reportTimerFired:) userInfo:nil repeats:NO];
}

-(BOOL)isLocalEnabled {
    NSDictionary *onlineConfig= [[NSUserDefaults standardUserDefaults] objectForKey:kAVOnlineConfig];
    
    // if we haven't save config before, it should be enabled.
    if (onlineConfig == nil) {
        return YES;
    }
    return [[onlineConfig valueForKey:enableTag] boolValue];
}

-(void)onlineConfigChanged:(NSDictionary *)config {
    [self loadOnlineConfig:config];
    
    //save config
    [[NSUserDefaults standardUserDefaults] setObject:config forKey:kAVOnlineConfig];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (!self.enableReport) {        
        [self.reportTimer invalidate];
    } else {
        [self postRecording];
    }
}

-(void)setLatitude:(double)latitude longitude:(double)longitude {
    self.longitude = longitude;
    self.latitude = latitude;
}

-(void)clearLocation {
    self.latitude = 0;
    self.longitude = 0;
}

-(void)debugDump {
    if (!self.enableDebugLog) {
        return;
    }
    AVLoggerI(@"Report policy is %d", self.reportPolicy);
    NSArray * array = [self allSessionData];
    for(NSDictionary * dict in array) {
        AVLoggerI(@"session data %@", dict);
    }
}

@end
