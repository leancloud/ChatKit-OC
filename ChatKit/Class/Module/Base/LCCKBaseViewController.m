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
@property (nonatomic, copy, readwrite) LCCKViewControllerWillDeallocBlock viewControllerWillDeallocBlock;
@property (nonatomic, copy, readwrite) LCCKViewDidReceiveMemoryWarningBlock didReceiveMemoryWarningBlock;
@property (nonatomic, copy) LCCKBarButtonItemActionBlock barbuttonItemAction;

@end

@implementation LCCKBaseViewController

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    !self.viewDidLoadBlock ?: self.viewDidLoadBlock(self);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    !self.viewWillAppearBlock ?: self.viewWillAppearBlock(self, animated);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    !self.viewDidAppearBlock ?: self.viewDidAppearBlock(self, animated);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    !self.viewWillDisappearBlock ?: self.viewWillDisappearBlock(self, animated);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    !self.viewDidDisappearBlock ?: self.viewDidDisappearBlock(self, animated);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    !self.didReceiveMemoryWarningBlock ?: self.didReceiveMemoryWarningBlock(self);
}

-(void)dealloc {
    !self.viewControllerWillDeallocBlock ?: self.viewControllerWillDeallocBlock(self);
}

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

- (void)setViewControllerWillDeallocBlock:(LCCKViewControllerWillDeallocBlock)viewControllerWillDeallocBlock {
    _viewControllerWillDeallocBlock = viewControllerWillDeallocBlock;
}

- (void)setViewDidReceiveMemoryWarningBlock:(LCCKViewDidReceiveMemoryWarningBlock)didReceiveMemoryWarningBlock {
    _didReceiveMemoryWarningBlock = didReceiveMemoryWarningBlock;
}
- (void)clickedBarButtonItemAction {
    if (self.barbuttonItemAction) {
        self.barbuttonItemAction();
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
    self.barbuttonItemAction = action;
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
