//
//  LCCKMapViewController.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/30.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKMapViewController.h"

@interface LCCKMapViewController ()<MKMapViewDelegate,CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end
@implementation LCCKMapViewController

- (instancetype)initWithLocation:(CLLocation *)location {
    self = [super init];
    if (!self) {
        return nil;
    }
    _location = location;
    return self;
}

+ (instancetype)initWithLocation:(CLLocation *)location {
    LCCKMapViewController *mapViewController = [[LCCKMapViewController alloc] init];
    mapViewController.location = location;
    return mapViewController;
}

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1. 实例化定位管理器
    _locationManager = [[CLLocationManager alloc] init];
    // 2. 设置代理
    _locationManager.delegate = self;
    // 3. 定位精度
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    // 4.请求用户权限：分为：⓵只在前台开启定位⓶在后台也可定位，
    //注意：建议只请求⓵和⓶中的一个，如果两个权限都需要，只请求⓶即可，
    //⓵⓶这样的顺序，将导致bug：第一次启动程序后，系统将只请求⓵的权限，⓶的权限系统不会请求，只会在下一次启动应用时请求⓶
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        [_locationManager requestWhenInUseAuthorization];//⓵只在前台开启定位
    }
    // 6. 更新用户位置
    [_locationManager startUpdatingLocation];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
