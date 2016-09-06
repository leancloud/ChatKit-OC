//
//  AVConfiguration.m
//  AVOS
//
//  Created by Tang Tianyong on 7/29/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import "AVConfiguration.h"
#import "AVConfiguration_extension.h"

@implementation AVConfiguration

+ (instancetype)sharedInstance {
    static AVConfiguration *sharedInstance = nil;

    if (sharedInstance) {
        return sharedInstance;
    }

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[AVConfiguration alloc] init];
    });

    return sharedInstance;
}

@end
