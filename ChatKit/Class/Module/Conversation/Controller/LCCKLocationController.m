//
//  LCCKLocationController.m
//  LCCKChatBarExample
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/8/24.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKLocationController.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif
#import "UIImage+LCCKExtension.h"

static CGFloat const LCCKLocationPOIListCellHeight = 40.f;

@interface LCCKLocationController ()<UITableViewDelegate,UITableViewDataSource,MKMapViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) MKMapView *mapView;

@property (strong, nonatomic) UIButton *showUserLocationButton;
@property (strong, nonatomic) UIImageView *locationImageView;

@property (strong, nonatomic) NSMutableArray *placemarks;
@property (assign, nonatomic) BOOL firstLocateUser;

@property (weak, nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation LCCKLocationController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStylePlain target:self action:@selector(sendLocation)];
    
    self.placemarks = [NSMutableArray array];
    self.firstLocateUser = YES;
    [self.mapView addSubview:self.locationImageView];
    [self.mapView addSubview:self.showUserLocationButton];
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.tableView];
    
    [[LCCKLocationManager shareManager] requestAuthorization];
    [[LCCKLocationManager shareManager] startLocation];
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];

    [self.view updateConstraintsIfNeeded];
    
}


- (void)updateViewConstraints{
    [super updateViewConstraints];
    
    [self.locationImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mapView.mas_centerX);
        make.centerY.equalTo(self.mapView.mas_centerY);
    }];
    
    [self.showUserLocationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mapView.mas_left).with.offset(8);
        make.bottom.equalTo(self.mapView.mas_bottom).with.offset(-8);
    }];
    

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
//        make.top.equalTo(self.mapView.mas_bottom);
        make.height.equalTo(@(0));
        make.bottom.equalTo(self.view.mas_bottom);
    }];
    
    [self.mapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.top.equalTo(self.view.mas_top);
//        make.height.mas_equalTo(280);
        make.bottom.equalTo(self.tableView.mas_top);
    }];
    
}



#pragma mark - UITableViewDelegate & UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.placemarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    if (indexPath.row == self.selectedIndexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if (indexPath.row >= self.placemarks.count) {
        return cell;
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"[位置] \n%@",[self.placemarks[indexPath.row] name]];
    } else {
        cell.textLabel.text = [self.placemarks[indexPath.row] name];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedIndexPath = indexPath;
    [tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return LCCKLocationPOIListCellHeight;
}

#pragma mark - MKMapViewDelegate

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    if (!self.firstLocateUser) {
        return;
    }
    [mapView setShowsUserLocation:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    self.firstLocateUser = NO;
    [self showUserLocation];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (!animated) {
        self.showUserLocationButton.selected = NO;
        [self updateCenterLocation:mapView.centerCoordinate];
    }
}


#pragma mark - Private Methods

/**
 *  搜索附近兴趣点信息
 *
 *  @param coordinate 搜索的点
 */
- (void)searchNearBy:(CLLocationCoordinate2D)coordinate {
    //创建一个位置信息对象，第一个参数为经纬度，第二个为纬度检索范围，单位为米，第三个为经度检索范围，单位为米
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500);
    //初始化一个检索请求对象
    MKLocalSearchRequest * req = [[MKLocalSearchRequest alloc]init];
    //设置检索参数
    req.region = region;
    //兴趣点关键字
//    req.naturalLanguageQuery = NSLocalizedStringFromTable(@"community", @"LCChatKitString", @"兴趣点搜索");
    //初始化检索
    MKLocalSearch *ser = [[MKLocalSearch alloc] initWithRequest:req];
    //开始检索，结果返回在block中
    [ser startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        //兴趣点节点数组
        NSArray * array = [NSArray arrayWithArray:response.mapItems];
        for (MKMapItem *mapItem in array) {
            [self.placemarks addObject:mapItem.placemark];
        }
        dispatch_async(dispatch_get_main_queue(),^{
            [self.tableView reloadData];
            [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
                CGFloat height = LCCKLocationPOIListCellHeight * self.placemarks.count;
                make.height.mas_equalTo(@(height));
            }];
        });
    }];
}

/**
 *  更新mapView中心点
 *
 *
 *  @param centerCoordinate 中心点经纬度
 */
- (void)updateCenterLocation:(CLLocationCoordinate2D)centerCoordinate {
    MKCoordinateSpan span;
    span.latitudeDelta=0.001;
    span.longitudeDelta=0.001;
    MKCoordinateRegion region = {centerCoordinate,span};
    [self.mapView setRegion:region animated:YES];
    
    [self.placemarks removeAllObjects];
    
    [[LCCKLocationManager shareManager] reverseGeocodeWithCoordinate2D:centerCoordinate success:^(NSArray *placemarks) {
        [self.placemarks addObjectsFromArray:placemarks];
        [self searchNearBy:centerCoordinate];
    } failure:^{
        [self searchNearBy:centerCoordinate];
    }];
    
}


- (void)showUserLocation {
    self.showUserLocationButton.selected = YES;
    [self updateCenterLocation:self.mapView.userLocation.coordinate];
}


- (void)cancel {
    if ([self.delegate respondsToSelector:@selector(cancelLocation)]) {
        [self.delegate cancelLocation];
    }
}

- (void)sendLocation {
    if (self.placemarks.count > self.selectedIndexPath.row) {
        if ([self.delegate respondsToSelector:@selector(sendLocation:)]) {
            [self.delegate sendLocation:self.placemarks[self.selectedIndexPath.row]];
        }
    }
}

#pragma mark - Getters

- (MKMapView *)mapView {
    if (!_mapView) {
        _mapView = [[MKMapView alloc] init];
        _mapView.delegate = self;
    }
    return _mapView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
}

- (UIButton *)showUserLocationButton {
    if (!_showUserLocationButton) {
        _showUserLocationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_showUserLocationButton setBackgroundImage:[self imageInBundlePathForImageName:@"show_user_location_normal"] forState:UIControlStateNormal];
        [_showUserLocationButton setBackgroundImage:[self imageInBundlePathForImageName:@"show_user_location_pressed"] forState:UIControlStateHighlighted];
        [_showUserLocationButton setBackgroundImage:[self imageInBundlePathForImageName:@"show_user_location_selected"] forState:UIControlStateSelected];
        [_showUserLocationButton addTarget:self action:@selector(showUserLocation) forControlEvents:UIControlEventTouchUpInside];
    }
    return _showUserLocationButton;
}

- (UIImageView *)locationImageView {
    if (!_locationImageView) {
        _locationImageView = [[UIImageView alloc] initWithImage:[self imageInBundlePathForImageName:@"location_green_icon"]];
    }
    return _locationImageView;
}

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    return   ({
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
        image;});
}

@end
