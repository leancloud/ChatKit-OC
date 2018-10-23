//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import <UIKit/UIKit.h>

//@class LCCKGroup;
@interface LCCKUIUtility : NSObject

+ (CGFloat)getTextHeightOfText:(NSString *)text
                          font:(UIFont *)font
                         width:(CGFloat)width;

//+ (void)createGroupAvatar:(LCCKGroup *)group
//                 finished:(void (^)(NSString *groupID))finished;

+ (void)captureScreenshotFromView:(UIView *)view
                             rect:(CGRect)rect
                         finished:(void (^)(NSString *avatarPath))finished;

@end
