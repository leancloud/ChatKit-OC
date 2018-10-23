//
//  LCCKMapViewController.h
//  LeanCloudIMKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/30.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface LCCKMapViewController : UIViewController

@property (nonatomic, strong) CLLocation *location;
- (instancetype)initWithLocation:(CLLocation *)location;
+ (instancetype)initWithLocation:(CLLocation *)location;

@end
