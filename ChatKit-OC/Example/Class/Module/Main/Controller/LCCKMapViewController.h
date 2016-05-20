//
//  LCCKMapViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/30.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

@import UIKit;
@import MapKit;
@import CoreLocation;

@interface LCCKMapViewController : UIViewController

@property (nonatomic, strong) CLLocation *location;
- (instancetype)initWithLocation:(CLLocation *)location;
+ (instancetype)initWithLocation:(CLLocation *)location;

@end
