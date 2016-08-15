//
//  LCCKBaseViewController.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import UIKit;
@class LCCKBaseViewController;
@protocol LCCKBaseViewController <NSObject>

/**
 *  页面需要透出的通用事件，例如viewDidLoad，viewWillAppear，viewDidAppear等
 */
typedef void(^LCCKViewDidLoadBlock)(LCCKBaseViewController *viewController);
typedef void(^LCCKViewWillAppearBlock)(LCCKBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCCKViewDidAppearBlock)(LCCKBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCCKViewWillDisappearBlock)(LCCKBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCCKViewDidDisappearBlock)(LCCKBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCCKViewDidDismissBlock)(LCCKBaseViewController *viewController);
typedef void(^LCCKViewControllerWillDeallocBlock) (LCCKBaseViewController *viewController);
typedef void(^LCCKViewDidReceiveMemoryWarningBlock)(LCCKBaseViewController *viewController);

@property (nonatomic, copy, readonly) LCCKViewDidLoadBlock viewDidLoadBlock;
@property (nonatomic, copy, readonly) LCCKViewWillAppearBlock viewWillAppearBlock;
@property (nonatomic, copy, readonly) LCCKViewDidAppearBlock viewDidAppearBlock;
@property (nonatomic, copy, readonly) LCCKViewWillDisappearBlock viewWillDisappearBlock;
@property (nonatomic, copy, readonly) LCCKViewDidDisappearBlock viewDidDisappearBlock;
@property (nonatomic, copy, readonly) LCCKViewDidDismissBlock viewDidDismissBlock;
@property (nonatomic, copy, readonly) LCCKViewControllerWillDeallocBlock viewControllerWillDeallocBlock;
@property (nonatomic, copy, readonly) LCCKViewDidReceiveMemoryWarningBlock didReceiveMemoryWarningBlock;

/**
 *  View的相关事件调出
 */
- (void)setViewDidLoadBlock:(LCCKViewDidLoadBlock)viewDidLoadBlock;
- (void)setViewWillAppearBlock:(LCCKViewWillAppearBlock)viewWillAppearBlock;
- (void)setViewDidAppearBlock:(LCCKViewDidAppearBlock)viewDidAppearBlock;
- (void)setViewWillDisappearBlock:(LCCKViewWillDisappearBlock)viewWillDisappearBlock;
- (void)setViewDidDisappearBlock:(LCCKViewDidDisappearBlock)viewDidDisappearBlock;
- (void)setViewDidDismissBlock:(LCCKViewDidDismissBlock)viewDidDismissBlock;
- (void)setViewControllerWillDeallocBlock:(LCCKViewControllerWillDeallocBlock)viewControllerWillDeallocBlock;
- (void)setViewDidReceiveMemoryWarningBlock:(LCCKViewDidReceiveMemoryWarningBlock)didReceiveMemoryWarningBlock;

@end

typedef void(^LCCKBarButtonItemActionBlock)(void);

typedef NS_ENUM(NSInteger, LCCKBarButtonItemStyle) {
    LCCKBarButtonItemStyleSetting = 0,
    LCCKBarButtonItemStyleMore,
    LCCKBarButtonItemStyleAdd,
    LCCKBarButtonItemStyleAddFriends,
    LCCKBarButtonItemStyleShare,
    LCCKBarButtonItemStyleSingleProfile,
    LCCKBarButtonItemStyleGroupProfile,
};

@interface LCCKBaseViewController : UIViewController <LCCKBaseViewController>

/**
 *  统一设置背景图片
 *
 *  @param backgroundImage 目标背景图片
 */
- (void)setupBackgroundImage:(UIImage *)backgroundImage;

- (void)configureBarButtonItemStyle:(LCCKBarButtonItemStyle)style action:(LCCKBarButtonItemActionBlock)action;

- (void)alert:(NSString *)message;

- (BOOL)alertAVIMError:(NSError *)error;

- (BOOL)filterAVIMError:(NSError *)error;

@end
