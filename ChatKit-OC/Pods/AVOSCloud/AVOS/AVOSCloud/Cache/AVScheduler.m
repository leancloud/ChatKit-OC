//
//  AVScheduler.m
//  paas
//
//  Created by Summer on 13-8-22.
//  Copyright (c) 2013年 AVOS. All rights reserved.
//

#import "AVScheduler.h"
#import "AVFile.h"
#import "AVFile_Internal.h"
#import "AVCacheManager.h"
#import "AVPaasClient.h"
#import "AVUtils.h"

static NSUInteger const ExpiredDays = 30;

// 60s * 15 = 15min
//static NSUInteger const AVTimerInterval = 60 * 15;
static NSUInteger const AVTimerInterval = 15; // for debug
static NSUInteger const AVHourCount = 3600 / AVTimerInterval;

@interface AVScheduler ()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger firedCount;
@end

@implementation AVScheduler

+ (AVScheduler *)sharedInstance {
    static dispatch_once_t once;
    static AVScheduler *_sharedInstance;
    dispatch_once(&once, ^{
        _sharedInstance = [[AVScheduler alloc] init];
        [_sharedInstance setup];
    });
    return _sharedInstance;
}

- (void)setup {
    // default setting
    self.queryCacheExpiredDays = ExpiredDays;
    self.fileCacheExpiredDays = ExpiredDays;
    ////
    
    self.firedCount = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:AVTimerInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    
#if !TARGET_OS_WATCH
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminate:) name:UIApplicationWillTerminateNotification object:nil];
#elif defined(__MAX_OS_X_VERSION_MIN_REQUIRED)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:NSApplicationDidFinishLaunchingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminate:) name:NSApplicationWillTerminateNotification object:nil];
#endif
#endif
}

- (void)clean {
    [_timer invalidate];
    _timer = nil;
    _firedCount = 0;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self clean];
}

#pragma mark - Schedule

#pragma mark Notification

#if !TARGET_OS_WATCH

- (void)didEnterBackground:(NSNotification *)notification {
    [self clearCache];
}

- (void)willEnterForeground:(NSNotification *)notification {
    if ([AVUtils networkIsWifiOrBetter])
        [self handleArchivedRequests];
}

- (void)didFinishLaunching:(NSNotification *)notification {
    if ([AVUtils networkIsWifiOrBetter])
        [self handleArchivedRequests];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    // Stub method
}

- (void)willTerminate:(NSNotification *)notification {
    // Stub method
}

#endif

- (void)handleArchivedRequests {
    [[AVPaasClient sharedInstance] handleAllArchivedRequests];
}

- (void)clearCache {
    [AVCacheManager clearCacheMoreThanDays:self.queryCacheExpiredDays];
    [AVFile clearCacheMoreThanDays:self.fileCacheExpiredDays];
}

#pragma mark Timer

- (void)timerFired:(id)sender {
    self.firedCount++;

    if ((self.firedCount % AVHourCount) == 0) {
        [self hourlyFired];
    }
}

- (void)hourlyFired {
#if TARGET_OS_WATCH
    [self handleArchivedRequests];
    [self clearCache];
#endif
}

@end
