//
//  AVScheduler.h
//  paas
//
//  Created by Summer on 13-8-22.
//  Copyright (c) 2013年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVScheduler : NSObject

@property (nonatomic, assign) NSInteger queryCacheExpiredDays;
@property (nonatomic, assign) NSInteger fileCacheExpiredDays;

+ (AVScheduler *)sharedInstance;

@end
