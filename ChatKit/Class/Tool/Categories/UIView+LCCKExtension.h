//
//  UIView+LCCKExtension.h
//  ChatKit
//
// v0.5.2 Created by 陈宜龙 on 16/6/2.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^LCCKViewActionBlock)(UIView *subview);

@interface UIView (LCCKExtension)

- (NSMutableArray*)lcck_allSubViews;

- (void)lcck_logViewHierarchy:(LCCKViewActionBlock)viewActionBlcok;

@end
