//
//  AVAnalyticsActivity.m
//  paas
//
//  Created by Zhu Zeng on 8/2/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVAnalyticsActivity.h"
#import "AVAnalyticsUtils.h"
#import "AVAnalyticsImpl.h"

@implementation AVAnalyticsActivity

-(id)initWithName:(NSString *)name
{
    self = [self init];
    _durationImpl = [[AVDuration alloc] init];
    self.activityName = name;
    return self;
}

-(void)pause {
    [self.durationImpl pause];
}

-(void)resume {
    [self.durationImpl resume];
}

-(long)duration
{
    return (long)[self.durationImpl duration];
}

-(NSDictionary *)jsonDictionary
{
    return @{@"name": [AVAnalyticsUtils safeString:self.activityName],
             kAVEventDurationTag: @([self duration]),
             kAVTSTag:@([self.durationImpl createTimeStampInMilliSeconds])};
}

@end


@implementation AVAnalyticsEvent

-(id)initWithName:(NSString *)name
{
    self = [super init];
    self.eventName = name;
    _durationImpl = [[AVDuration alloc] init];
    _attributes = [[NSMutableDictionary alloc] init];
    return self;
}


-(void)pause {
    [self.durationImpl pause];
}

-(void)resume {
    [self.durationImpl resume];
}

-(long)duration
{
    return (long)[self.durationImpl duration];
}

-(NSDictionary *)jsonDictionary:(NSDictionary *)additionalDict
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict addEntriesFromDictionary:additionalDict];
    if (self.attributes.count > 0) {
        [dict setObject:self.attributes forKey:kAVAttributesTag];
    }
    [dict setObject:@([self duration]) forKey:kAVEventDurationTag];
    [dict setObject:@([self.durationImpl createTimeStampInMilliSeconds]) forKey:kAVTSTag];
    
    [dict setObject:[AVAnalyticsUtils safeString:self.eventName] forKey:kAVEventTag];
    if (self.labelName.length > 0) {
        [dict setObject:self.labelName forKey:kAVLabelTag];
    } else {
        [dict setObject:[AVAnalyticsUtils safeString:self.eventName] forKey:kAVLabelTag];
    }

    if (self.primaryKey.length > 0) {
        [dict setObject:self.primaryKey forKey:kAVPrimaryKeyTag];
    }

    if (self.acc > 1) {
        [dict setObject:@(self.acc) forKey:kAVAccTag];
    }
    return dict;
}


-(BOOL)match:(NSString *)name
       label:(NSString *)label
         key:(NSString *)key {
    if (![self.eventName isEqualToString:name]) {
        return NO;
    }
    if (![AVAnalyticsUtils isStringEqual:self.labelName with:label]) {
        return NO;
    }
    if (![AVAnalyticsUtils isStringEqual:self.primaryKey with:key]) {
        return NO;
    }
    // Fix same analytics event send one time.
    if ([self.durationImpl isStopped]) {
        return NO;
    }
    return YES;
}


@end
