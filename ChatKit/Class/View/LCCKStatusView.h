//
//  LCCKStatusView.h
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

@import UIKit;
@import Foundation;

@protocol LCCKStatusViewDelegate <NSObject>

@optional
- (void)statusViewClicked:(id)sender;
@end

static CGFloat LCCKStatusViewHight = 44;

@interface LCCKStatusView : UIView

@property (nonatomic, weak) id<LCCKStatusViewDelegate> delegate;

@end
