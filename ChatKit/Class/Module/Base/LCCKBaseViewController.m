//
//  LCCKBaseViewController.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (wechat:chenyilong1010) on 16/2/26.
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

- (void)clickedBarButtonItemAction:(UIBarButtonItem *)sender event:(UIEvent *)event {
    if (self.barButtonItemAction) {
        self.barButtonItemAction(sender, event);
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage lcck_imageNamed:icon bundleName:@"BarButtonIcon" bundleForClass:[self class]] style:UIBarButtonItemStylePlain target:self action:@selector(clickedBarButtonItemAction:event:)];
    self.barButtonItemAction = action;
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
