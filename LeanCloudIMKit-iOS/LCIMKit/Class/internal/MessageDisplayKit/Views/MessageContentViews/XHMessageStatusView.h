//
//  XHMessageStatusView.h
//  LeanChat
//
//  Created by lzw on 14/12/30.
//  Copyright (c) 2014年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "XHMessage.h"

static const CGFloat kXHStatusViewWidth = 50;
static const CGFloat kXHStatusViewHeight = 20;
static const CGFloat kXHStatusViewSentWidth = 50;
static const CGFloat kXHStatusViewSentHeight = 20;
static const CGFloat kXHStatusViewRetryButtonSize = 20;
static const CGFloat kXHStatusViewPadding = 5;

@interface XHMessageStatusView : UIView

@property (nonatomic, assign) XHMessageStatus status;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UILabel *sentView;
@property (nonatomic, strong) UIButton *retryButton;

@end
