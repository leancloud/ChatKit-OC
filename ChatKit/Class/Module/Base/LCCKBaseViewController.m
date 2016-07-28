//
//  LCCKBaseViewController.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKBaseViewController.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKUIService.h"
#import "UIImage+LCCKExtension.h"

@interface LCCKBaseViewController ()

@property (nonatomic, copy, readwrite) LCCKViewDidLoadBlock viewDidLoadBlock;
@property (nonatomic, copy, readwrite) LCCKViewWillAppearBlock viewWillAppearBlock;
@property (nonatomic, copy, readwrite) LCCKViewDidAppearBlock viewDidAppearBlock;
@property (nonatomic, copy, readwrite) LCCKViewWillDisappearBlock viewWillDisappearBlock;
@property (nonatomic, copy, readwrite) LCCKViewDidDisappearBlock viewDidDisappearBlock;
@property (nonatomic, copy, readwrite) LCCKViewDidDismissBlock viewDidDismissBlock;
@property (nonatomic, copy, readwrite) LCCKViewControllerWillDeallocBlock viewControllerWillDeallocBlock;
@property (nonatomic, copy, readwrite) LCCKViewDidReceiveMemoryWarningBlock didReceiveMemoryWarningBlock;
@property (nonatomic, copy) LCCKBarButtonItemActionBlock barButtonItemAction;

@end

@implementation LCCKBaseViewController

#pragma mark -
#pragma mark - UIViewController Life Event Block

- (void)setViewDidLoadBlock:(LCCKViewDidLoadBlock)viewDidLoadBlock {
    _viewDidLoadBlock = viewDidLoadBlock;
}

- (void)setViewWillAppearBlock:(LCCKViewWillAppearBlock)viewWillAppearBlock {
    _viewWillAppearBlock = viewWillAppearBlock;
}

- (void)setViewDidAppearBlock:(LCCKViewDidAppearBlock)viewDidAppearBlock {
    _viewDidAppearBlock = viewDidAppearBlock;
}

- (void)setViewWillDisappearBlock:(LCCKViewWillDisappearBlock)viewWillDisappearBlock {
    _viewWillDisappearBlock = viewWillDisappearBlock;
}

- (void)setViewDidDisappearBlock:(LCCKViewDidDisappearBlock)viewDidDisappearBlock {
    _viewDidDisappearBlock = viewDidDisappearBlock;
}

- (void)setViewDidDismissBlock:(LCCKViewDidDismissBlock)viewDidDismissBlock {
    _viewDidDismissBlock = viewDidDismissBlock;
}


- (void)setViewControllerWillDeallocBlock:(LCCKViewControllerWillDeallocBlock)viewControllerWillDeallocBlock {
    _viewControllerWillDeallocBlock = viewControllerWillDeallocBlock;
}

- (void)setViewDidReceiveMemoryWarningBlock:(LCCKViewDidReceiveMemoryWarningBlock)didReceiveMemoryWarningBlock {
    _didReceiveMemoryWarningBlock = didReceiveMemoryWarningBlock;
}

- (void)clickedBarButtonItemAction {
    if (self.barButtonItemAction) {
        self.barButtonItemAction();
    }
}

#pragma mark - Public Method

- (void)configureBarButtonItemStyle:(LCCKBarButtonItemStyle)style action:(LCCKBarButtonItemActionBlock)action {
    NSString *icon;
    switch (style) {
        case LCCKBarButtonItemStyleSetting: {
            icon = @"barbuttonicon_set";
            break;
        }
        case LCCKBarButtonItemStyleMore: {
            icon = @"barbuttonicon_more";
            break;
        }
        case LCCKBarButtonItemStyleAdd: {
            icon = @"barbuttonicon_add";
            break;
        }
        case LCCKBarButtonItemStyleAddFriends:
            icon = @"barbuttonicon_addfriends";
            break;
        case LCCKBarButtonItemStyleSingleProfile:
            icon = @"barbuttonicon_InfoSingle";
            break;
        case LCCKBarButtonItemStyleGroupProfile:
            icon = @"barbuttonicon_InfoMulti";
            break;
        case LCCKBarButtonItemStyleShare:
            icon = @"barbuttonicon_Operate";
            break;
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage lcck_imageNamed:icon bundleName:@"BarButtonIcon" bundleForClass:[self class]] style:UIBarButtonItemStylePlain target:self action:@selector(clickedBarButtonItemAction)];
    self.barButtonItemAction = action;
}

- (void)setupBackgroundImage:(UIImage *)backgroundImage {
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backgroundImageView.image = backgroundImage;
    [self.view insertSubview:backgroundImageView atIndex:0];
}

#pragma mark - alert and async utils

- (void)alert:(NSString *)message {
    LCCKShowNotificationBlock showNotificationBlock = [LCCKUIService sharedInstance].showNotificationBlock;
    !showNotificationBlock ?: showNotificationBlock(self, message, nil, LCCKMessageNotificationTypeError);
}

- (BOOL)alertAVIMError:(NSError *)error {
    if (error) {
        if (error.code == kAVIMErrorConnectionLost) {
            [self alert:@"未能连接聊天服务"];
        } else if ([error.domain isEqualToString:NSURLErrorDomain]) {
            [self alert:@"网络连接发生错误"];
        } else {
            [self alert:[NSString stringWithFormat:@"%@", error]];
        }
        return YES;
    }
    return NO;
}

- (BOOL)filterAVIMError:(NSError *)error {
    return [self alertAVIMError:error] == NO;
}

@end
