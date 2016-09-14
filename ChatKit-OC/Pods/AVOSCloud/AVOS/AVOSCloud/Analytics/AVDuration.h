//
//  AVDuration.h
//  paas
//
//  Created by Zhu Zeng on 10/10/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

// life cycle, like android activity.
@interface AVDuration : NSObject


@property (nonatomic, readwrite) NSTimeInterval resumeTimeStamp;
@property (nonatomic, readwrite) NSTimeInterval duration;

/// Duration set by user. Sometimes, developers want to record duration by themselves.
@property (nonatomic, readwrite) NSTimeInterval userDuration;


-(void)start;
-(void)stop;
-(BOOL)isStopped;

-(void)resume;
-(void)pause;

/// Sync duration. Let duration += Now - Last.
-(void)sync;

-(void)setDurationWithMilliSeconds:(long)ms;
-(void)addDurationWithMilliSeconds:(long)ms;
-(NSTimeInterval)createTimeStampInMilliSeconds;

+(NSTimeInterval)currentTS;


@end
