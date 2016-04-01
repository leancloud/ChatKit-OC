//
//  XMNContentView.m
//  XMNChatExample
//
//  Created by shscce on 15/11/13.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import "XMNContentView.h"

@implementation XMNContentView

- (instancetype)init {
    if ([super init]) {
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.fillColor = [UIColor grayColor].CGColor;
        maskLayer.contentsCenter = CGRectMake(.7f, .7f, .1f, .1f);
        maskLayer.contentsScale = [UIScreen mainScreen].scale;
        self.layer.mask = maskLayer;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.maskView.frame = CGRectInset(self.bounds, 0, 0);
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    self.layer.mask.frame = CGRectInset(self.bounds, 0, 0);
}

@end
