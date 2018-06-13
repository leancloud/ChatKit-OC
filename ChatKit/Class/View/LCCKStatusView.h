//
//  LCCKStatusView.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol LCCKStatusViewDelegate <NSObject>

@optional
- (void)statusViewClicked:(id)sender;
@end

static CGFloat LCCKStatusViewHight = 44;

@interface LCCKStatusView : UIView

@property (nonatomic, weak) id<LCCKStatusViewDelegate> delegate;

@end
