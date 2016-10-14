//
//  AVIMMessageOption.h
//  AVOS
//
//  Created by Tang Tianyong on 9/13/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AVIMMessagePriority) {
    AVIMMessagePriorityDefault = 0,
    AVIMMessagePriorityHigh    = 1,
    AVIMMessagePriorityNormal  = 2,
    AVIMMessagePriorityLow     = 3,
};

@interface AVIMMessageOption : NSObject

@property (nonatomic, assign) BOOL                 receipt;
@property (nonatomic, assign) BOOL                 transient;
@property (nonatomic, assign) AVIMMessagePriority  priority;
@property (nonatomic, strong) NSDictionary        *pushData;

@end
