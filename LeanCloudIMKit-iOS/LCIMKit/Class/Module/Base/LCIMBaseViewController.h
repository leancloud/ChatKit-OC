//
//  LCIMBaseViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import UIKit;
@class LCIMBaseViewController;
@protocol LCIMBaseViewController <NSObject>

/**
 *  页面需要透出的通用事件，例如viewDidLoad，viewWillAppear，viewDidAppear等
 */
typedef void(^LCIMViewDidLoadBlock)(LCIMBaseViewController *viewController);
typedef void(^LCIMViewWillAppearBlock)(LCIMBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCIMViewDidAppearBlock)(LCIMBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCIMViewWillDisappearBlock)(LCIMBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCIMViewDidDisappearBlock)(LCIMBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCIMViewControllerWillDeallocBlock) (LCIMBaseViewController *viewController);
typedef void(^LCIMViewDidReceiveMemoryWarningBlock)(LCIMBaseViewController *viewController);

@property (nonatomic, copy, readonly) LCIMViewDidLoadBlock viewDidLoadBlock;
@property (nonatomic, copy, readonly) LCIMViewWillAppearBlock viewWillAppearBlock;
@property (nonatomic, copy, readonly) LCIMViewDidAppearBlock viewDidAppearBlock;
@property (nonatomic, copy, readonly) LCIMViewWillDisappearBlock viewWillDisappearBlock;
@property (nonatomic, copy, readonly) LCIMViewDidDisappearBlock viewDidDisappearBlock;
@property (nonatomic, copy, readonly) LCIMViewControllerWillDeallocBlock viewControllerWillDeallocBlock;
@property (nonatomic, copy, readonly) LCIMViewDidReceiveMemoryWarningBlock didReceiveMemoryWarningBlock;

/**
 *  View的相关事件调出
 */
- (void)setViewDidLoadBlock:(LCIMViewDidLoadBlock)viewDidLoadBlock;
- (void)setViewWillAppearBlock:(LCIMViewWillAppearBlock)viewWillAppearBlock;
- (void)setViewDidAppearBlock:(LCIMViewDidAppearBlock)viewDidAppearBlock;
- (void)setViewWillDisappearBlock:(LCIMViewWillDisappearBlock)viewWillDisappearBlock;
- (void)setViewDidDisappearBlock:(LCIMViewDidDisappearBlock)viewDidDisappearBlock;
- (void)setViewControllerWillDeallocBlock:(LCIMViewControllerWillDeallocBlock)viewControllerWillDeallocBlock;
- (void)setViewDidReceiveMemoryWarningBlock:(LCIMViewDidReceiveMemoryWarningBlock)didReceiveMemoryWarningBlock;

@end

typedef void(^LCIMBarButtonItemActionBlock)(void);

typedef NS_ENUM(NSInteger, LCIMBarButtonItemStyle) {
    LCIMBarButtonItemStyleSetting = 0,
    LCIMBarButtonItemStyleMore,
    LCIMBarButtonItemStyleAdd,
    LCIMBarButtonItemStyleAddFriends,
    LCIMBarButtonItemStyleShare,
    LCIMBarButtonItemStyleSingleProfile,
    LCIMBarButtonItemStyleGroupProfile,
};

@interface LCIMBaseViewController : UIViewController <LCIMBaseViewController>

/**
 *  统一设置背景图片
 *
 *  @param backgroundImage 目标背景图片
 */
- (void)setupBackgroundImage:(UIImage *)backgroundImage;

- (void)configureBarButtonItemStyle:(LCIMBarButtonItemStyle)style action:(LCIMBarButtonItemActionBlock)action;

- (void)alert:(NSString *)message;

- (BOOL)alertAVIMError:(NSError *)error;

- (BOOL)filterAVIMError:(NSError *)error;

@end
