//
//  LCIMClientSessionTokenCacheStore.m
//  AVOS
//
//  Created by Tang Tianyong on 10/16/15.
//  Copyright © 2015 LeanCloud Inc. All rights reserved.
//

#import "LCIMClientSessionTokenCacheStore.h"
#import "LCKeyValueStore.h"
#import "AVPersistenceUtils.h"

NSString *const LCIMTagDefault = @"default";

static NSString *const LCIMKeySessionToken = @"session_token";
static NSString *const LCIMKeyExpireAt     = @"expire_at";
static NSString *const LCIMKeyTag          = @"tag";

@interface LCIMClientSessionTokenCacheStore ()

@property (nonatomic, strong) LCKeyValueStore *keyValueStore;

@end

@implementation LCIMClientSessionTokenCacheStore

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static LCIMClientSessionTokenCacheStore *instance = nil;

    dispatch_once(&once, ^{
        instance = [[LCIMClientSessionTokenCacheStore alloc] init];
    });

    return instance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        _keyValueStore = [[LCKeyValueStore alloc] initWithDatabasePath:[AVPersistenceUtils clientSessionTokenCacheDatabasePath] tableName:nil];
    }

    return self;
}

- (void)setSessionToken:(NSString *)sessionToken TTL:(NSTimeInterval)TTL forClientId:(NSString *)clientId tag:(NSString *)tag {
    if (!sessionToken || TTL <= 0 || !clientId)
        return;

    NSDictionary *record = @{
        LCIMKeySessionToken : sessionToken,
        LCIMKeyExpireAt     : @([[NSDate date] timeIntervalSince1970] + TTL),
        LCIMKeyTag          : (tag ?: LCIMTagDefault)
    };

    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:record options:0 error:NULL];

    if (JSONData) {
        [self.keyValueStore setData:JSONData forKey:clientId];
    }
}

- (NSString *)sessionTokenForClientId:(NSString *)clientId tag:(NSString *)tag {
    if (!clientId)
        return nil;

    NSString *sessionToken = nil;
    NSData *JSONData = [self.keyValueStore dataForKey:clientId];

    if (JSONData) {
        NSDictionary *record = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:NULL];

        do {
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            NSTimeInterval expireAt = [record[LCIMKeyExpireAt] doubleValue];

            if (now < expireAt) {
                NSString *lastTag = record[LCIMKeyTag];

                if ([(tag ?: LCIMTagDefault) isEqualToString:lastTag]) {
                    sessionToken = record[LCIMKeySessionToken];
                    break;
                }
            }

            [self clearForClientId:clientId];
        } while (NO);
    }

    return sessionToken;
}

- (void)clearForClientId:(NSString *)clientId {
    [self.keyValueStore deleteKey:clientId];
}

@end
