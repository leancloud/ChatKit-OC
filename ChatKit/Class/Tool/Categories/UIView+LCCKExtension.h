//
//  UIView+LCCKExtension.h
//  ChatKit
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/6/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^LCCKViewActionBlock)(UIView *subview);

@interface UIView (LCCKExtension)

- (NSMutableArray*)lcck_allSubViews;

- (void)lcck_logViewHierarchy:(LCCKViewActionBlock)viewActionBlcok;

@end
