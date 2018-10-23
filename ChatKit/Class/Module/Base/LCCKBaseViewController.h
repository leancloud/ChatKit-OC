//
//  LCCKBaseViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LCCKBaseViewController;
@protocol LCCKViewControllerEventProtocol <NSObject>

/**
 *  页面需要透出的通用事件，例如viewDidLoad，viewWillAppear，viewDidAppear等
 */
typedef void(^LCCKViewDidLoadBlock)(__kindof LCCKBaseViewController *viewController);
typedef void(^LCCKViewWillAppearBlock)(__kindof LCCKBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCCKViewDidAppearBlock)(__kindof LCCKBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCCKViewWillDisappearBlock)(__kindof LCCKBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCCKViewDidDisappearBlock)(__kindof LCCKBaseViewController *viewController, BOOL aAnimated);
typedef void(^LCCKViewDidDismissBlock)(__kindof LCCKBaseViewController *viewController);
typedef void(^LCCKViewControllerWillDeallocBlock) (__kindof LCCKBaseViewController *viewController);
typedef void(^LCCKViewDidReceiveMemoryWarningBlock)(__kindof LCCKBaseViewController *viewController);

@property (nonatomic, copy) LCCKViewDidLoadBlock viewDidLoadBlock;
@property (nonatomic, copy) LCCKViewWillAppearBlock viewWillAppearBlock;
@property (nonatomic, copy) LCCKViewDidAppearBlock viewDidAppearBlock;
@property (nonatomic, copy) LCCKViewWillDisappearBlock viewWillDisappearBlock;
@property (nonatomic, copy) LCCKViewDidDisappearBlock viewDidDisappearBlock;
@property (nonatomic, copy) LCCKViewDidDismissBlock viewDidDismissBlock;
@property (nonatomic, copy) LCCKViewControllerWillDeallocBlock viewControllerWillDeallocBlock;
@property (nonatomic, copy) LCCKViewDidReceiveMemoryWarningBlock didReceiveMemoryWarningBlock;

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

typedef void(^LCCKBarButtonItemActionBlock)(__kindof LCCKBaseViewController *viewController, UIBarButtonItem *sender, UIEvent *event);

typedef NS_ENUM(NSInteger, LCCKBarButtonItemStyle) {
    LCCKBarButtonItemStyleSetting = 0,
    LCCKBarButtonItemStyleMore,
    LCCKBarButtonItemStyleAdd,
    LCCKBarButtonItemStyleAddFriends,
    LCCKBarButtonItemStyleShare,
    LCCKBarButtonItemStyleSingleProfile,
    LCCKBarButtonItemStyleGroupProfile,
};

@interface LCCKBaseViewController : UIViewController <LCCKViewControllerEventProtocol>

- (void)configureBarButtonItemStyle:(LCCKBarButtonItemStyle)style action:(LCCKBarButtonItemActionBlock)action;

- (void)alert:(NSString *)message;

- (BOOL)alertAVIMError:(NSError *)error;

- (BOOL)filterAVIMError:(NSError *)error;

@end
