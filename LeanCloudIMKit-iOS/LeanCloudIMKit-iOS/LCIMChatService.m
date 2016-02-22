
//
//  LCIMChatService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMChatService.h"
#import <AVOSCloud/AVOSCloud.h>
#import "LCIMConstants.h"

static LCIMChatService *_sharedLCIMChatService = nil;

@interface LCIMChatService ()

@property (nonatomic, strong) AVIMClient *client;

@end

@implementation LCIMChatService

// Dictionary that holds all instances of DOSingleton subclasses
static NSMutableDictionary *_sharedInstances = nil;

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

#pragma mark -

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

+ (instancetype)instance {
    return [self sharedInstance];
}

#pragma mark -

+ (void)destroyInstance {
    [_sharedInstances removeObjectForKey:NSStringFromClass(self)];
}

#pragma mark -

- (id)init {
    self = [super init];
    
    if (self && !self.isInitialized) {
        // Thread-safe because it called from +sharedInstance
        _isInitialized = YES;
    }
    
    return self;
}

+ (void)setAppId:(NSString *)appId appKey:(NSString *)appKey {
    [AVOSCloud setApplicationId:appId clientKey:appKey];
}

- (void)openWithClientId:(NSString *)clientId callback:(LCIMBoolCallBack)callback {
    //TODO:
}

- (void)closeWithCallback:(LCIMBoolCallBack)callback {
    //TODO:
}

#pragma mark -
#pragma mark - LCIMChatService Delegate Method

- (void)getProfilesWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback {
    // This enforces implementing this method in subclasses
    NSString *reason = [NSString stringWithFormat:@"You must implement `-[id<LCIMChatService> getProfilesWithUserIds:callback]` in the subclass of LCIMChatService, so LeanCloudIMKit can get user information by user id."];
    @throw [NSException exceptionWithName:NSGenericException
                                   reason:reason
                                 userInfo:nil];
}

@end

@implementation LCIMChatService (Subclass)

- (NSArray<id<LCIMUserModelDelegate>> *)lc_getProfilesWithUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError {
    __block NSArray<id<LCIMUserModelDelegate>> *blockUsers = [NSArray array];
    __block BOOL hasCallback = NO;
    __block NSError *blockError;
    [self lc_getProfilesInBackgroundWithUserIds:userIds callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
        if (error) {
            blockError = error;
        }
        hasCallback = YES;
        blockUsers = users;
    }];
    LCIM_WAIT_TIL_TRUE(hasCallback, 0.1);
    if (theError != NULL) {
        *theError = blockError;
    }
    return blockUsers;
}

- (void)lc_getProfilesInBackgroundWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self getProfilesWithUserIds:userIds callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
            safeBlock(users);
        }];
    });
}

@end