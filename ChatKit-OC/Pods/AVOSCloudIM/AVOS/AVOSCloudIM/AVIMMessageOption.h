//
//  AVIMMessageOption.h
//  AVOS
//
//  Created by Tang Tianyong on 9/13/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AVIMMessagePriority) {
    AVIMMessagePriorityHigh    = 1,
    AVIMMessagePriorityNormal  = 2,
    AVIMMessagePriorityLow     = 3,
};

NS_ASSUME_NONNULL_BEGIN

@interface AVIMMessageOption : NSObject

@property (nonatomic, assign)           BOOL                 receipt;
@property (nonatomic, assign)           BOOL                 transient;
@property (nonatomic, assign)           AVIMMessagePriority  priority;
@property (nonatomic, strong, nullable) NSDictionary        *pushData;

@end

NS_ASSUME_NONNULL_END
