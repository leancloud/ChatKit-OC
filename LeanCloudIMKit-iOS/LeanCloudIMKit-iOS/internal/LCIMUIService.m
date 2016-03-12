//
//  LCIMUIService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMUIService.h"

NSString *const LCIMUIServiceErrorDomain = @"LCIMUIServiceErrorDomain";

@implementation LCIMUIService

/**
 * create a singleton instance of LCIMUIService
 */
+ (instancetype)sharedInstance {
    static LCIMUIService *_sharedLCIMUIService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCIMUIService = [[self alloc] init];
    });
    return _sharedLCIMUIService;
}

@end
