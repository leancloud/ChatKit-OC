//
//  AVCacheManager.h
//  LeanCloud
//
//  Created by Summer on 13-3-19.
//  Copyright (c) 2013年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVConstants.h"

@interface AVCacheManager : NSObject

+ (AVCacheManager *)sharedInstance;

// cache
- (void)getWithKey:(NSString *)key maxCacheAge:(NSTimeInterval)maxCacheAge block:(AVIdResultBlock)block;
- (void)saveJSON:(id)JSON forKey:(NSString *)key;

- (BOOL)hasCacheForKey:(NSString *)key;
- (BOOL)hasCacheForMD5Key:(NSString *)key;

// clear
+ (BOOL)clearAllCache;
+ (BOOL)clearCacheMoreThanOneDay;
+ (BOOL)clearCacheMoreThanDays:(NSInteger)numberOfDays;
- (void)clearCacheForKey:(NSString *)key;
- (void)clearCacheForMD5Key:(NSString *)key;
@end
