//
//  LCIMClientSessionTokenCacheStore.h
//  AVOS
//
//  Created by Tang Tianyong on 10/16/15.
//  Copyright © 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const LCIMTagDefault;

@interface LCIMClientSessionTokenCacheStore : NSObject

+ (instancetype)sharedInstance;

- (void)setSessionToken:(NSString *)sessionToken TTL:(NSTimeInterval)TTL forClientId:(NSString *)clientId tag:(NSString *)tag;

- (NSString *)sessionTokenForClientId:(NSString *)clientId tag:(NSString *)tag;

- (void)clearForClientId:(NSString *)clientId;

@end
