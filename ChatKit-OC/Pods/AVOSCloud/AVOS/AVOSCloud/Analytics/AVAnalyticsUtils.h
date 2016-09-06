//
//  AVAnalyticsUtils.h
//  paas
//
//  Created by Zhu Zeng on 8/15/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVAvailability.h"

#define kAVSessionIdTag @"sessionId"
#define kAVPrimaryKeyTag @"primaryKey"
#define kAVDurationTag @"duration"
#define kAVEventDurationTag @"du"
#define kAVEventTag @"name"
#define kAVLabelTag @"tag"
#define kAVAccTag @"acc"
#define kAVAttributesTag @"attributes"
#define kAVTSTag @"ts"
#define kAVDateTag @"date"
#define kAVActivitiesTag @"activities"

#define AV_SESSIONID_LENGTH  32
#define AV_MESSAGE_COUNT_THRESHOLD 30
#define AV_DEFAULT_REPORT_INTERVAL 20
#define AV_REGARD_NEW_SESSION 20

@interface AVAnalyticsUtils : NSObject


+(NSMutableDictionary *)deviceInfo;
+(NSString *)randomString:(int)length;
+(NSTimeInterval)currentTimestamp;

+(BOOL)inSimulator;
+(BOOL)inDebug;
+(BOOL)isStringEqual:(NSString *)source
                with:(NSString *)target;

+(NSString *)safeString:(NSString *)string;

+(BOOL)isWiFiConnection AV_WATCH_UNAVAILABLE;
+(NSString *)deviceId AV_WATCH_UNAVAILABLE AV_OSX_UNAVAILABLE;

@end
