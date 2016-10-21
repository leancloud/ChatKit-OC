//
//  LCCKLocationManager.m
//  LCCKLocationManagerDemo
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/7/31.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKLocationManager.h"

@interface LCCKLocationManager ()<CLLocationManagerDelegate,UIAlertViewDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLGeocoder *geocoder;

@end

@implementation LCCKLocationManager

+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    static id shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [manager startUpdatingLocation];
    }
}

/**
 *  跟踪定位代理方法，每次位置发生变化即会执行（只要定位到相应位置）
 *
 *  @param manager
 *  @param locations
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //取出经纬度
    CLLocationCoordinate2D coordinate = manager.location.coordinate;
    // 3.打印经纬度
//    NSLog(@"didUpdateLocations------%f %f", coordinate.latitude, coordinate.longitude);
    if (self.locationCompleteBlock) {
        self.locationCompleteBlock(coordinate);
    }
//    [_locationManager stopUpdatingLocation];//停止定位
}

#pragma mark - Public Methods

//kCLAuthorizationStatusNotDetermined： 用户尚未做出决定是否启用定位服务
//kCLAuthorizationStatusRestricted： 没有获得用户授权使用定位服务
//kCLAuthorizationStatusDenied ：用户已经明确禁止应用使用定位服务或者当前系统定位服务处于关闭状态
//kCLAuthorizationStatusAuthorizedAlways： 应用获得授权可以一直使用定位服务，即使应用不在使用状态
//kCLAuthorizationStatusAuthorizedWhenInUse： 使用此应用过程中允许访问定位服务
- (void)requestAuthorization {
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                break;
                
            case kCLAuthorizationStatusNotDetermined:
                [self.locationManager requestAlwaysAuthorization];
                [self.locationManager requestWhenInUseAuthorization];
                break;
            case kCLAuthorizationStatusDenied: {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请在隐私设置中打开定位开关" delegate:self cancelButtonTitle:@"以后再说" otherButtonTitles:@"前往设置",nil];
                [alertView show];
            }
                break;
            default:
                break;
        }
    }
    
}

- (void)startLocation {
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocation {
    [self.locationManager stopUpdatingLocation];
}

/**
 *  地理编码 （通过地址获取经纬度）
 *
 *  @param address       输入的地址
 *  @param success       成功block，返回pm
 *  @param failure       失败block
 */
- (void)geocode:(NSString *)address success:(void(^)(CLPlacemark *pm))success failure:(void(^)())failure {
    [self.geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            if (failure) {
                failure();
            }
            return ;
        }
        if (success) {
            success([placemarks firstObject]);
        }
    }];
}


/**
 *  反地理编码 （通过经纬度获取地址）
 *
 *  @param latitude      输入的纬度
 *  @param longitude     输入经度
 *  @param success       成功block，返回pm
 *  @param failure       失败block
 */
- (void)reverseGeocodeWithCoordinate2D:(CLLocationCoordinate2D)coordinate2D success:(void(^)(NSArray *placemarks))success failure:(void(^)())failure {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate2D.latitude longitude:coordinate2D.longitude];
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            if (failure) {
                failure();
            }
            return ;
        }
        if (success) {
            success(placemarks);
        }
    }];
}


- (double)customDistanceWithEndCoordinate2D:(CLLocationCoordinate2D)endCoordinate2D fromStartCoordinate2D:(CLLocationCoordinate2D)startCoordinate2D{
    double er = 6378137; // 6378700.0f;
    //ave. radius = 6371.315 (someone said more accurate is 6366.707)
    //equatorial radius = 6378.388
    //nautical mile = 1.15078
    double radlat1 = M_PI*endCoordinate2D.latitude/180.0f;
    double radlat2 = M_PI*startCoordinate2D.latitude/180.0f;
    //now long.
    double radlong1 = M_PI*endCoordinate2D.longitude/180.0f;
    double radlong2 = M_PI*startCoordinate2D.longitude/180.0f;
    if( radlat1 < 0 ) radlat1 = M_PI/2 + fabs(radlat1);// south
    if( radlat1 > 0 ) radlat1 = M_PI/2 - fabs(radlat1);// north
    if( radlong1 < 0 ) radlong1 = M_PI*2 - fabs(radlong1);//west
    if( radlat2 < 0 ) radlat2 = M_PI/2 + fabs(radlat2);// south
    if( radlat2 > 0 ) radlat2 = M_PI/2 - fabs(radlat2);// north
    if( radlong2 < 0 ) radlong2 = M_PI*2 - fabs(radlong2);// west
    //spherical coordinates x=r*cos(ag)sin(at), y=r*sin(ag)*sin(at), z=r*cos(at)
    //zero ag is up so reverse lat
    double x1 = er * cos(radlong1) * sin(radlat1);
    double y1 = er * sin(radlong1) * sin(radlat1);
    double z1 = er * cos(radlat1);
    double x2 = er * cos(radlong2) * sin(radlat2);
    double y2 = er * sin(radlong2) * sin(radlat2);
    double z2 = er * cos(radlat2);
    double d = sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)+(z1-z2)*(z1-z2));
    //side, side, side, law of cosines and arccos
    double theta = acos((er*er+er*er-d*d)/(2*er*er));
    double dist  = theta*er;
    return dist;
}


- (double)systemDistanceWithEndCoordinate2D:(CLLocationCoordinate2D)endCoordinate2D fromStartCoordinate2D:(CLLocationCoordinate2D)startCoordinate2D{
    //计算2个经纬度之间的直线距离
    CLLocation *endLocation = [[CLLocation alloc] initWithLatitude:endCoordinate2D.latitude longitude:endCoordinate2D.longitude];
    CLLocation *startLocation = [[CLLocation alloc] initWithLatitude:startCoordinate2D.latitude longitude:startCoordinate2D.longitude];
    CLLocationDistance distance = [endLocation distanceFromLocation:startLocation];
    return distance;
}

#pragma mark - Getters

- (CLLocationManager *)locationManager{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;//定位精确度
        _locationManager.distanceFilter = 10;//10米定位一次
    }
    return _locationManager;
}

- (CLGeocoder *)geocoder{
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}

- (CLLocationDegrees)latitude {
    return self.locationManager.location.coordinate.latitude;
}

- (CLLocationDegrees)longitude {
    return self.locationManager.location.coordinate.longitude;
}

@end
