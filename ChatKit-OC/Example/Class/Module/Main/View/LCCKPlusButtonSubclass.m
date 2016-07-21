//
//  LCCKPlusButtonSubclass.m
//  DWCustomTabBarDemo
//
//  Created by 微博@iOS程序犭袁 (http://weibo.com/luohanchenyilong/) on 15/10/24.
//  Copyright (c) 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import "LCCKPlusButtonSubclass.h"
#import "LCChatKitExample.h"

@interface LCCKPlusButtonSubclass () {
    CGFloat _buttonImageHeight;
}
@end
@implementation LCCKPlusButtonSubclass

#pragma mark -
#pragma mark - Life Cycle

+ (void)load {
    [super registerPlusButton];
}

#pragma mark -
#pragma mark - Life Cycle

-(instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
//        self.titleLabel.textAlignment = NSTextAlignmentCenter;
//        self.adjustsImageWhenHighlighted = NO;
    }
    
    return self;
}



#pragma mark -
#pragma mark - Public Methods

/*
 *
 Create a custom UIButton without title and add it to the center of our tab bar
 *
 */
+ (instancetype)plusButton
{

    UIImage *buttonImage = [UIImage imageNamed:@"tabbar_compose_button"];
    UIImage *highlightImage = [UIImage imageNamed:@"tabbar_compose_button_highlighted"];
    UIImage *iconImage = [UIImage imageNamed:@"tabbar_compose_icon_add"];
    UIImage *highlightIconImage = [UIImage imageNamed:@"tabbar_compose_icon_add"];

    LCCKPlusButtonSubclass *button = [LCCKPlusButtonSubclass buttonWithType:UIButtonTypeCustom];
    
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    button.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
    [button setImage:iconImage forState:UIControlStateNormal];
    [button setImage:highlightIconImage forState:UIControlStateHighlighted];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [button addTarget:button action:@selector(clickPublish) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark -
#pragma mark - Event Response

- (void)clickPublish {
    [LCChatKitExample exampleOpenConversationViewControllerWithConversaionId:@"570da6a9daeb3a63ca5b07b0" fromNavigationController:nil];
}

+ (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    return 2;
}


@end
