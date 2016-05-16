//
//  LCIMStatusView.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

@import UIKit;
@import Foundation;

@protocol LCIMStatusViewDelegate <NSObject>

@optional
- (void)statusViewClicked:(id)sender;
@end

static CGFloat LCIMStatusViewHight = 44;

@interface LCIMStatusView : UIView

@property (nonatomic, weak) id<LCIMStatusViewDelegate> delegate;

@end
