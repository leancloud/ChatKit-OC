//
//  LCCKBaseNavigationController.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKBaseNavigationController.h"

@interface LCCKBaseNavigationController()<UINavigationControllerDelegate>
{
    BOOL _pushing;
}
@end

@implementation LCCKBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    _pushing = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationBar.barStyle = UIBarStyleBlack;
    self.delegate = self;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    if (_pushing == YES) {
        return;
    }else{
        _pushing = NO;
    }
    
    [super pushViewController:viewController animated:animated];
}


// 实现当delegate为其他的时候, 还能调到这个方法
- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate {
    [super setDelegate:delegate];
    
    // 待实现
}

#pragma mark - UINavigationControllerDelegate
-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    _pushing = NO; //完成PUSH
}

@end
