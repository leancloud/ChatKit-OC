//
//  LCIMKit.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMKit.h"
#import <AVOSCloud/AVOSCloud.h>
#import "LCIMSessionService.h"
#import "LCIMUserSystemService.h"
#import "LCIMSignatureService.h"
#import "LCIMSettingService.h"
#import "LCIMUIService.h"
#import "LCIMConversationService.h"

// Dictionary that holds all instances of Singleton include subclasses
static NSMutableDictionary *_sharedInstances = nil;

@interface LCIMKit ()

@property (nonatomic, copy, readwrite) LCIMOpenProfileBlock openProfileBlock;

/*!
 * open or close client Service
 */
@property (nonatomic, strong, readwrite) id<LCIMSessionService> sessionService;

/*!
 * User-System Service
 */
@property (nonatomic, strong, readwrite) id<LCIMUserSystemService> userSystemService;

/*!
 * Signature Service
 */
@property (nonatomic, strong, readwrite) id<LCIMSignatureService> signatureService;

/*!
 * Setting Service
 */
@property (nonatomic, strong, readwrite) id<LCIMSettingService> settingService;

/*!
 * UI Service
 */
@property (nonatomic, strong, readwrite) id<LCIMUIService> UIService;

/*!
 * Conversation Service
 */
@property (nonatomic, strong, readwrite) id<LCIMConversationService> conversationService;

@end

@implementation LCIMKit

#pragma mark -

+ (void)initialize {
    if (_sharedInstances == nil) {
        _sharedInstances = [NSMutableDictionary dictionary];
    }
}

+ (id)allocWithZone:(NSZone *)zone {
    // Not allow allocating memory in a different zone
    return [self sharedInstance];
}

+ (id)copyWithZone:(NSZone *)zone {
    // Not allow copying to a different zone
    return [self sharedInstance];
}

+ (instancetype)sharedInstance {
    id sharedInstance = nil;
    
    @synchronized(self) {
        NSString *instanceClass = NSStringFromClass(self);
        
        // Looking for existing instance
        sharedInstance = [_sharedInstances objectForKey:instanceClass];
        
        // If there's no instance – create one and add it to the dictionary
        if (sharedInstance == nil) {
            sharedInstance = [[super allocWithZone:nil] init];
            [_sharedInstances setObject:sharedInstance forKey:instanceClass];
        }
    }
    
    return sharedInstance;
}

#pragma mark -
#pragma mark - LCIMKit Method

+ (void)setAppId:(NSString *)appId appKey:(NSString *)appKey {
    [AVOSCloud setApplicationId:appId clientKey:appKey];
    if ([LCIMSettingService allLogsEnabled]) {
        NSLog(@"LeanCloudKit Version is %@", [LCIMSettingService IMKitVersion]);
    }
}

#pragma mark -
#pragma mark - Service Delegate Method

- (id<LCIMSessionService>)sessionService {
    return [[LCIMSessionService alloc] init];
}

- (id<LCIMUserSystemService>)userSystemService {
    return [[LCIMUserSystemService alloc] init];
}

- (id<LCIMSignatureService>)signatureService {
    return [[LCIMSignatureService alloc] init];
}

- (id<LCIMSettingService>)settingService {
    return [[LCIMSettingService alloc] init];
}

- (id<LCIMUIService>)UIService {
    return [[LCIMUIService alloc] init];
}

- (id<LCIMConversationService>)conversationService {
    return [[LCIMConversationService alloc] init];
}

+ (void)setAllLogsEnabled:(BOOL)enabled {
    [LCIMSettingService setAllLogsEnabled:YES];
}

#pragma mark - -
#pragma mark - - LCIMUIService Method

- (void)setOpenProfileBlock:(LCIMOpenProfileBlock)openProfileBlock {
    //TODO:
}

@end


