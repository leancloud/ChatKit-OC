//
//  LCIMTableViewRowAction.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/24.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import "LCIMTableViewRowAction.h"

@interface LCIMTableViewRowAction()

@property (nonatomic, copy, readwrite) LCIMTableViewRowActionHandler handler;

@end

@implementation LCIMTableViewRowAction


+ (instancetype)rowActionWithStyle:(LCIMTableViewRowActionStyle)style title:(nullable NSString *)title handler:(LCIMTableViewRowActionHandler)handler {
    LCIMTableViewRowAction *button = [LCIMTableViewRowAction buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button.titleLabel setAdjustsFontSizeToFitWidth:YES];
    button.title = title;
    button.handler = handler;
    button.backgroundColor = [UIColor redColor];
    return button;
}

- (BOOL)isValid {
    return  self.title && self.handler;
}

@end
