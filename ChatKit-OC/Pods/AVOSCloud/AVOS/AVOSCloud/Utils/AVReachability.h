//
//  AVReachability.h
//  AVOS
//
//  Created by Qihe Bian on 10/10/14.
//
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

extern NSString *const kAVReachabilityChangedNotification;

typedef NS_ENUM(NSInteger, AVNetworkStatus) {
    // Apple NetworkStatus Compatible Names.
    AVNotReachable = 0,
    AVReachableViaWWAN = 1,
    AVReachableViaWiFi = 2
};

@class AVReachability;

typedef void (^AVNetworkReachable)(AVReachability * reachability);
typedef void (^AVNetworkUnreachable)(AVReachability * reachability);

@interface AVReachability : NSObject

@property (nonatomic, copy) AVNetworkReachable    reachableBlock;
@property (nonatomic, copy) AVNetworkUnreachable  unreachableBlock;


@property (nonatomic, assign) BOOL reachableOnWWAN;

+(AVReachability*)reachabilityWithHostname:(NSString*)hostname;
// This is identical to the function above, but is here to maintain
//compatibility with Apples original code. (see .m)
+(AVReachability*)reachabilityWithHostName:(NSString*)hostname;
+(AVReachability*)reachabilityForInternetConnection;
+(AVReachability*)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress;
+(AVReachability*)reachabilityForLocalWiFi;

-(AVReachability *)initWithReachabilityRef:(SCNetworkReachabilityRef)ref;

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

-(AVNetworkStatus)currentReachabilityStatus;
-(SCNetworkReachabilityFlags)reachabilityFlags;
-(NSString*)currentReachabilityString;
-(NSString*)currentReachabilityFlags;

@end
