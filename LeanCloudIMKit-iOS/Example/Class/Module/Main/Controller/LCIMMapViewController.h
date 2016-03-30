//
//  LCIMMapViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/30.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

@import UIKit;
@import MapKit;
@import CoreLocation;

@interface LCIMMapViewController : UIViewController

@property (nonatomic, strong) CLLocation *location;
- (instancetype)initWithLocation:(CLLocation *)location;
+ (instancetype)initWithLocation:(CLLocation *)location;

@end
