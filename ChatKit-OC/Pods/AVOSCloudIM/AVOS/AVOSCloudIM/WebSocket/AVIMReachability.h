//
//  AVIMReachability.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/5/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

/**
 * Does ARC support GCD objects?
 * It does if the minimum deployment target is iOS 6+ or Mac OS X 8+
 *
 * @see http://opensource.apple.com/source/libdispatch/libdispatch-228.18/os/object.h
 **/
#if OS_OBJECT_USE_OBJC
#define NEEDS_DISPATCH_RETAIN_RELEASE 0
#else
#define NEEDS_DISPATCH_RETAIN_RELEASE 1
#endif

/**
 * Create NS_ENUM macro if it does not exist on the targeted version of iOS or OS X.
 *
 * @see http://nshipster.com/ns_enum-ns_options/
 **/
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

extern NSString *const kAVIMReachabilityChangedNotification;

typedef NS_ENUM(NSInteger, AVIMNetworkStatus) {
    // Apple NetworkStatus Compatible Names.
    AVIMNotReachable = 0,
    AVIMReachableViaWWAN = 1,
    AVIMReachableViaWiFi = 2
};

@class AVIMReachability;

typedef void (^AVIMNetworkReachable)(AVIMReachability * reachability);
typedef void (^AVIMNetworkUnreachable)(AVIMReachability * reachability);

@interface AVIMReachability : NSObject

@property (nonatomic, copy) AVIMNetworkReachable    reachableBlock;
@property (nonatomic, copy) AVIMNetworkUnreachable  unreachableBlock;


@property (nonatomic, assign) BOOL reachableOnWWAN;

+(instancetype)reachabilityWithHostname:(NSString*)hostname;
// This is identical to the function above, but is here to maintain
//compatibility with Apples original code. (see .m)
+(instancetype)reachabilityWithHostName:(NSString*)hostname;
+(instancetype)reachabilityForInternetConnection;
+(instancetype)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress;
+(instancetype)reachabilityForLocalWiFi;

-(instancetype)initWithReachabilityRef:(SCNetworkReachabilityRef)ref;

-(BOOL)startNotifier;
-(void)stopNotifier;

-(BOOL)isReachable;
-(BOOL)isReachableViaWWAN;
-(BOOL)isReachableViaWiFi;

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
-(BOOL)isConnectionRequired; // Identical DDG variant.
-(BOOL)connectionRequired; // Apple's routine.
// Dynamic, on demand connection?
-(BOOL)isConnectionOnDemand;
// Is user intervention required?
-(BOOL)isInterventionRequired;

-(AVIMNetworkStatus)currentReachabilityStatus;
-(SCNetworkReachabilityFlags)reachabilityFlags;
-(NSString*)currentReachabilityString;
-(NSString*)currentReachabilityFlags;

@end
