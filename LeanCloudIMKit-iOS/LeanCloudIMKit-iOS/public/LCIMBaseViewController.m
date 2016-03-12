//
//  LCIMBaseViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMBaseViewController.h"

@interface LCIMBaseViewController ()

@property (nonatomic, copy, readwrite) LCIMViewDidLoadBlock viewDidLoadBlock;
@property (nonatomic, copy, readwrite) LCIMViewWillAppearBlock viewWillAppearBlock;
@property (nonatomic, copy, readwrite) LCIMViewDidAppearBlock viewDidAppearBlock;
@property (nonatomic, copy, readwrite) LCIMViewWillDisappearBlock viewWillDisappearBlock;
@property (nonatomic, copy, readwrite) LCIMViewDidDisappearBlock viewDidDisappearBlock;
@property (nonatomic, copy, readwrite) LCIMViewControllerWillDeallocBlock viewControllerWillDeallocBlock;
@property (nonatomic, copy, readwrite) LCIMViewDidReceiveMemoryWarningBlock didReceiveMemoryWarningBlock;
@property (nonatomic, copy) LCIMBarButtonItemActionBlock barbuttonItemAction;

@end

@implementation LCIMBaseViewController

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor= [UIColor whiteColor];
    !self.viewDidLoadBlock ?: self.viewDidLoadBlock();
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    !self.viewWillAppearBlock ?: self.viewWillAppearBlock(animated);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    !self.viewDidAppearBlock ?: self.viewDidAppearBlock(animated);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    !self.viewWillDisappearBlock ?: self.viewWillDisappearBlock(animated);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    !self.viewDidDisappearBlock ?: self.viewDidDisappearBlock(animated);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    !self.didReceiveMemoryWarningBlock ?: self.didReceiveMemoryWarningBlock();
}

-(void)dealloc {
    !self.viewControllerWillDeallocBlock ?: self.viewControllerWillDeallocBlock();
}

#pragma mark -
#pragma mark - UIViewController Life Event Block

- (void)setViewDidLoadBlock:(LCIMViewDidLoadBlock)viewDidLoadBlock {
    _viewDidLoadBlock = viewDidLoadBlock;
}

- (void)setViewWillAppearBlock:(LCIMViewWillAppearBlock)viewWillAppearBlock {
    _viewWillAppearBlock = viewWillAppearBlock;
}

- (void)setViewDidAppearBlock:(LCIMViewDidAppearBlock)viewDidAppearBlock {
    _viewDidAppearBlock = viewDidAppearBlock;
}

- (void)setViewWillDisappearBlock:(LCIMViewWillDisappearBlock)viewWillDisappearBlock {
    _viewWillDisappearBlock = viewWillDisappearBlock;
}

- (void)setViewDidDisappearBlock:(LCIMViewDidDisappearBlock)viewDidDisappearBlock {
    _viewDidDisappearBlock = viewDidDisappearBlock;
}

- (void)setViewControllerWillDeallocBlock:(LCIMViewControllerWillDeallocBlock)viewControllerWillDeallocBlock {
    _viewControllerWillDeallocBlock = viewControllerWillDeallocBlock;
}

- (void)setViewDidReceiveMemoryWarningBlock:(LCIMViewDidReceiveMemoryWarningBlock)didReceiveMemoryWarningBlock {
    _didReceiveMemoryWarningBlock = didReceiveMemoryWarningBlock;
}
- (void)clickedBarButtonItemAction {
    if (self.barbuttonItemAction) {
        self.barbuttonItemAction();
    }
}

#pragma mark - Public Method

- (void)configureBarbuttonItemStyle:(LCIMBarbuttonItemStyle)style action:(LCIMBarButtonItemActionBlock)action {
    NSString *icon;
    switch (style) {
        case LCIMBarbuttonItemStyleSetting: {
            icon = @"barbuttonicon_set";
            break;
        }
        case LCIMBarbuttonItemStyleMore: {
            icon = @"barbuttonicon_more";
            break;
        }
        case LCIMBarbuttonItemStyleAdd: {
            icon = @"barbuttonicon_add";
            break;
        }
        case LCIMBarbuttonItemStyleAddFriends:
            icon = @"barbuttonicon_addfriends";
            break;
        case LCIMBarbuttonItemStyleSingleProfile:
            icon = @"barbuttonicon_InfoSingle";
            break;
        case LCIMBarbuttonItemStyleGroupProfile:
            icon = @"barbuttonicon_InfoMulti";
            break;
        case LCIMBarbuttonItemStyleShare:
            icon = @"barbuttonicon_Operate";
            break;
    }
    NSString *imgString = [NSString stringWithFormat:@"BarButtonIcon.bundle/%@", icon];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imgString] style:UIBarButtonItemStylePlain target:self action:@selector(clickedBarButtonItemAction)];
    self.barbuttonItemAction = action;
}

- (void)setupBackgroundImage:(UIImage *)backgroundImage {
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backgroundImageView.image = backgroundImage;
    [self.view insertSubview:backgroundImageView atIndex:0];
}

@end
