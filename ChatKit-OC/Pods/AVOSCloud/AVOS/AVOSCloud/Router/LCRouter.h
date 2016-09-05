//
//  LCRouter.h
//  AVOS
//
//  Created by Tang Tianyong on 5/9/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const LCRouterDidUpdateNotification;

@interface LCRouter : NSObject

+ (instancetype)sharedInstance;

/**
 Get API URL string.

 @return API URL string.
 */
- (NSString *)APIURLString;

/**
 Get versioned API URL string.

 @return Versioned API URL string.
 */
- (NSString *)versionedAPIURLString;

/**
 Get versioned API URL.

 @return Versioned API URL.
 */
- (NSURL *)versionedAPIURL;

/**
 Get push router URL string.

 @return push router URL string.
 */
- (NSString *)pushRouterURLString;

/**
 Cache API host for service region.

 @param host          The API host to be cached.
 @param lastModified  The last modified timestamp since 1970 in seconds.
 @param TTL           The time-to-live timestamp in seconds.
 */
- (void)cacheAPIHostWithHost:(NSString *)host
                lastModified:(NSTimeInterval)lastModified
                         TTL:(NSTimeInterval)TTL;

/**
 Cache push router host for service region.

 @param host          The push router host to be cached.
 @param lastModified  The last modified timestamp since 1970 in seconds.
 @param TTL           The time-to-live timestamp in seconds.
 */
- (void)cachePushRouterHostWithHost:(NSString *)host
                       lastModified:(NSTimeInterval)lastModified
                                TTL:(NSTimeInterval)TTL;

/**
 Update router asynchronously.
 */
- (void)updateInBackground;

@end
