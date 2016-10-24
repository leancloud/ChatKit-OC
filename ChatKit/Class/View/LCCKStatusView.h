//
//  LCCKStatusView.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
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
