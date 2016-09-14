
//
//  AVAnalyticsSession.m
//  paas
//
//  Created by Zhu Zeng on 8/15/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVAnalyticsImpl.h"
#import "AVAnalyticsSession.h"
#import "AVAnalyticsUtils.h"



@implementation AVAnalyticsSession

-(instancetype)init
{
    self = [super init];
    _sessionId = [AVAnalyticsUtils randomString:AV_SESSIONID_LENGTH];
    _activities = [[NSMutableArray alloc] init];
    _events = [[NSMutableArray alloc] init];
    _durationImpl = [[AVDuration alloc] init];
    return self;
}

-(void)beginSession
{
    [self.durationImpl resume];
}

-(void)endSession
{
    [self.durationImpl stop];
}

-(BOOL)isStoppped {
    return [self.durationImpl isStopped];
}

-(void)pauseSession
{
    [self.durationImpl pause];
    for(AVAnalyticsActivity * a in [self.activities copy]) {
        [a pause];
    }
    for(AVAnalyticsEvent * e in [self.events copy]) {
        [e pause];
    }
}

-(void)resumeSession
{
    [self.durationImpl resume];
    for(AVAnalyticsActivity * a in [self.activities copy]) {
        [a resume];
    }
    for(AVAnalyticsEvent * event in [self.events copy]) {
        [event resume];
    }
}

-(void)sync {
    [self.durationImpl sync];
    for(AVAnalyticsActivity * a in [self.activities copy]) {
        [a.durationImpl sync];
    }
    for(AVAnalyticsEvent * event in [self.events copy]) {
        [event.durationImpl sync];
    }
}

-(AVAnalyticsActivity *)activityByName:(NSString *)name
                                create:(BOOL)create
{
    for(AVAnalyticsActivity * activity in [self.activities copy]) {
        if ([activity.activityName isEqualToString:name] &&
            ![activity.durationImpl isStopped]) {
            return activity;
        }
    }
    AVAnalyticsActivity * activity = nil;
    if (create) {
        activity = [[AVAnalyticsActivity alloc] initWithName:name];
        [self.activities addObject:activity];
    }
    return activity;
}

-(AVAnalyticsEvent *)eventByName:(NSString *)name
                           label:(NSString *)label
                             key:(NSString *)key
                          create:(BOOL)create
{
    for(AVAnalyticsEvent * event in [self.events copy]) {
        if ([event match:name label:label key:key]) {
            return event;
        }
    }
    AVAnalyticsEvent * event = nil;
    if (create) {
        event = [[AVAnalyticsEvent alloc] initWithName:name];
        [self.events addObject:event];
    }
    return event;
}

- (void)addActivity:(NSString *)name seconds:(int)seconds
{
    AVAnalyticsActivity * activity = [self activityByName:name create:YES];
    [activity.durationImpl setDurationWithMilliSeconds:seconds * 1000];
}

-(void)beginActivity:(NSString *)name
{
    AVAnalyticsActivity * activity = [self activityByName:name create:YES];
    [activity.durationImpl start];
    self.currentActivityName = name;
}

-(void)endActivity:(NSString *)name
{
    AVAnalyticsActivity * activity = [self activityByName:name create:NO];
    if (activity == nil) {
        // wrong.
        NSLog(@"The beginning of analytics session \"%@\" not found.", name);
        return;
    }
    [activity.durationImpl stop];
    self.currentActivityName = @"";
}

-(void)addEvent:(NSString *)name
          label:(NSString *)label
            key:(NSString *)key
            acc:(NSInteger)acc
             du:(int)du
     attributes:(NSDictionary *)attributes
{
    AVAnalyticsEvent * event = [self eventByName:name label:label key:key create:YES];
    event.labelName = label;
    event.primaryKey = key;
    if (acc <= 0) {
        event.acc = 1;
    } else {
        event.acc = (int)acc;
    }
    
    @try {
        [event.attributes addEntriesFromDictionary:attributes];
    }
    @catch (NSException *exception) {
        
    }
    [event.durationImpl start];
    [event.durationImpl setDurationWithMilliSeconds:du];
    [event.durationImpl stop];
}

-(void)beginEvent:(NSString *)name
            label:(NSString *)label
              key:(NSString *)key
       attributes:(NSDictionary *)attributes {
    AVAnalyticsEvent * event = [self eventByName:name label:label key:key create:YES];
    event.labelName = label;
    event.primaryKey = key;
    [event.attributes addEntriesFromDictionary:attributes];
    [event.durationImpl start];
}


-(void)endEvent:(NSString *)name
          label:(NSString *)label
     primaryKey:(NSString *)key
     attributes:(NSDictionary *)attributes {
    
    AVAnalyticsEvent * event = [self eventByName:name label:label key:key create:NO];
    if (event == nil) {
        // wrong.
        NSLog(@"Please call beginEvent at first.");
        return;
    }
    if (label)   {
        event.labelName = label;
    }
    
    if (key) {
        event.primaryKey = key;
    }
    [event.attributes addEntriesFromDictionary:attributes];
    [event.durationImpl stop];
}

-(NSDictionary *)launchDictionary
{
    return @{kAVSessionIdTag:[AVAnalyticsUtils safeString:self.sessionId],
             kAVDateTag: @([self.durationImpl createTimeStampInMilliSeconds])};
}

-(long)duration
{
    return [self.durationImpl duration];
}

-(NSDictionary *)activitiesDictionary
{
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:self.activities.count];
    for(AVAnalyticsActivity * a in [self.activities copy]) {
        [array addObject:[a jsonDictionary]];
    }
    return @{kAVActivitiesTag: array,
             kAVSessionIdTag: [AVAnalyticsUtils safeString:self.sessionId],
             kAVDurationTag: @([self duration])};
}

-(NSArray *)eventsDictionary
{
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:self.events.count];
    NSDictionary * dict = @{kAVSessionIdTag: self.sessionId};
    for(AVAnalyticsEvent * event in [self.events copy]) {
        [array addObject:[event jsonDictionary:dict]];
    }
    return array;
}

-(NSDictionary *)jsonDictionary:(NSDictionary *)additionalDeviceInfo
{
    NSMutableDictionary * deviceInfo = [AVAnalyticsUtils deviceInfo];
    [deviceInfo addEntriesFromDictionary:additionalDeviceInfo];
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:@{@"events": @{@"launch": [self launchDictionary],
                                                                                              @"terminate": [self activitiesDictionary],
                                                                                              @"event": [self eventsDictionary]},
                                                                                 @"device": deviceInfo}];
    
    if ([AVAnalyticsImpl sharedInstance].customInfo!=nil) {
        [dict setObject:[AVAnalyticsImpl sharedInstance].customInfo forKey:@"customInfo"];
    }
    return dict;
}


@end
