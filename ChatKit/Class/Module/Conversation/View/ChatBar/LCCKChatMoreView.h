//
//  LCCKChatMoreView.h
//  LCCKChatBarExample
//
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/8/18.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCCKConstants.h"

static CGFloat const kFunctionViewHeight = 210.0f;
@class LCCKChatBar;
/**
 *  更多view
 */
@interface LCCKChatMoreView : UIView

@property (assign, nonatomic) NSUInteger numberPerLine;
@property (assign, nonatomic) UIEdgeInsets edgeInsets;
@property (weak, nonatomic) LCCKChatBar *inputViewRef;

@end
