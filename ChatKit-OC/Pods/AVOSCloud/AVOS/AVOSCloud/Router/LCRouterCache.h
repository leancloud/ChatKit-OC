//
//  LCRouterCache.h
//  AVOS
//
//  Created by Tang Tianyong on 5/9/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVOSCloud.h"

@interface LCRouterCache : NSObject

+ (instancetype)sharedInstance;

/**
 Cache API host for service region.

 @param serviceRegion The service region.
 @param host          The API host to be cached.
 @param lastModified  The last modified timestamp since 1970 in seconds.
 @param TTL           The time-to-live timestamp in seconds.
 */
- (void)cacheAPIHostWithServiceRegion:(AVServiceRegion)serviceRegion
                                 host:(NSString *)host
                         lastModified:(NSTimeInterval)lastModified
                                  TTL:(NSTimeInterval)TTL;

/**
 Cache push router host for service region.

 @param serviceRegion The service region.
 @param host          The push router host to be cached.
 @param lastModified  The last modified timestamp since 1970 in seconds.
 @param TTL           The time-to-live timestamp in seconds.
 */
- (void)cachePushRouterHostWithServiceRegion:(AVServiceRegion)serviceRegion
                                        host:(NSString *)host
                                lastModified:(NSTimeInterval)lastModified
                                         TTL:(NSTimeInterval)TTL;

/**
 Get API host for service region.

 @param serviceRegion The service region.

 @return API host for service region, or nil of cache not found or expired.
 */
- (NSString *)APIHostForServiceRegion:(AVServiceRegion)serviceRegion;

/**
 Get push router host for service region.

 @param serviceRegion The service region.

 @return Push router host for service region, or nil of cache not found or expired.
 */
- (NSString *)pushRouterHostForServiceRegion:(AVServiceRegion)serviceRegion;

@end
