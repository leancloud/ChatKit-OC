//
//  AVAnalyticsImpl.h
//  paas
//
//  Created by Zhu Zeng on 8/2/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVAnalytics.h"
#import "AVAnalyticsActivity.h"
#import "AVAnalyticsSession.h"

@interface AVAnalyticsImpl : NSObject

@property (nonatomic, readwrite) BOOL enableAnalytics;
@property (nonatomic, readwrite) BOOL enableCrashReport;
@property (nonatomic, readwrite) BOOL enableIgnoreCrash;
@property (nonatomic, readwrite) BOOL enableDebugLog;
@property (nonatomic, retain) NSDictionary *ignoreCrashAlertStrings;
@property (nonatomic, readwrite) AVReportPolicy reportPolicy;
@property (nonatomic, readwrite) BOOL enableReport;
@property (nonatomic, readwrite, copy) NSString * appChannel;
@property (nonatomic, readwrite) double sendInterval;
@property (nonatomic, readwrite, strong) NSMutableDictionary * onlineConfig;

@property (nonatomic, retain) NSDictionary *customInfo;

+(AVAnalyticsImpl *)sharedInstance;

-(void)setEnableCrashReport:(BOOL)enabled completion:(void (^)(void))completion;
-(void)beginSession;
-(void)endSession;
-(AVAnalyticsSession *)currentSession;

-(void)addActivity:(NSString *)name seconds:(int)seconds;
-(void)beginActivity:(NSString *)name;
-(void)endActivity:(NSString *)name;

-(void)addEvent:(NSString *)eventId
          label:(NSString *)label
            key:(NSString *)key
            acc:(NSInteger)acc
             du:(int)du
     attributes:(NSDictionary *)attributes;

-(void)beginEvent:(NSString *)name
            label:(NSString *)label
            key:(NSString *)key
       attributes:(NSDictionary *)attributes;

-(void)endEvent:(NSString *)name
          label:(NSString *)label
            key:(NSString *)key
     attributes:(NSDictionary *)attributes;

/**
 *  send crash report
 *  @param exception the exception with trace userinfo
 */
-(void)addException:(NSException *)exception;

-(void)setLatitude:(double)latitude longitude:(double)longitude;
-(void)clearLocation;

-(BOOL)isLocalEnabled;
-(void)onlineConfigChanged:(id)object;

- (void)stopRun;

@end
