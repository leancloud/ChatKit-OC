//
//  AVLocationManager.m
//  paas
//
//  Created by Summer on 13-3-16.
//  Copyright (c) 2013年 AVOS. All rights reserved.
//

#import "AVLocationManager.h"
#import "AVConstants.h"
#import "AVGeoPoint.h"
#import "AVErrorUtils.h"

#import <CoreLocation/CoreLocation.h>

@interface AVLocationManager ()<CLLocationManagerDelegate>

@property (nonatomic, strong, readwrite) CLLocationManager *locationManager;
@property (nonatomic, strong, readwrite) NSMutableArray *completionBlocks;
@property (nonatomic, strong, readwrite) NSRecursiveLock *lock;
@property (nonatomic, strong, readwrite) CLLocation *lastLocation;

@end

@implementation AVLocationManager

+ (AVLocationManager *)sharedInstance {
    static dispatch_once_t once;
    static AVLocationManager *_sharedInstance;
    dispatch_once(&once, ^{
        _sharedInstance = [[AVLocationManager alloc] init];
        [_sharedInstance commonInit];
    });
    return _sharedInstance;
}

- (void)commonInit {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.completionBlocks = [NSMutableArray array];
    
    self.lock = [[NSRecursiveLock alloc] init];
}

- (void)updateWithBlock:(void(^)(AVGeoPoint *geoPoint, NSError *error))block {
    [self.lock lock];
    if (block) [self.completionBlocks addObject:[block copy]];
    [self.lock unlock];

#if TARGET_OS_TV
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestLocation];
#elif TARGET_OS_WATCH
    NSBundle *bundle = [NSBundle mainBundle];
    if ([bundle objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager requestLocation];
#elif TARGET_OS_IOS
    NSBundle *bundle = [NSBundle mainBundle];
    UIApplication *application = [UIApplication sharedApplication];

    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        if (application.applicationState != UIApplicationStateBackground &&
            [bundle objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
            [self.locationManager requestWhenInUseAuthorization];
        } else {
            [self.locationManager requestAlwaysAuthorization];
        }
    }
    [self.locationManager startUpdatingLocation];
#elif AV_TARGET_OS_OSX
    [self.locationManager startUpdatingLocation];
#endif
}

#pragma mark - CLLocation Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self.locationManager stopUpdatingLocation];
    self.lastLocation = newLocation;
    
    [self.lock lock];
    
    for (void (^completion)(AVGeoPoint *, NSError *) in [self.completionBlocks copy]) {
        completion([AVGeoPoint geoPointWithLocation:newLocation], nil);
    }
    
    self.completionBlocks = [NSMutableArray array];
    
    [self.lock unlock];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    [self.locationManager stopUpdatingLocation];
    CLLocation *newLocation = [locations lastObject];
    self.lastLocation = newLocation;
    
    
    [self.lock lock];
    
    for (void (^completion)(AVGeoPoint *, NSError *) in [self.completionBlocks copy]) {
        completion([AVGeoPoint geoPointWithLocation:newLocation], nil);
    }
    
    self.completionBlocks = [NSMutableArray array];
    
    [self.lock unlock];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.lock lock];
    
    for (void (^completion)(AVGeoPoint *, NSError *) in [self.completionBlocks copy]) {
        if (self.lastLocation) {
            completion([AVGeoPoint geoPointWithLocation:self.lastLocation], nil);
        } else {
            completion(nil, error);
        }
    }
    
    self.completionBlocks = [NSMutableArray array];
    
    [self.lock unlock];
}

@end
