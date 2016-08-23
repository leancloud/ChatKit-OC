//
//  LCCKContact.m
//  ChatKit
//
//  v0.6.2 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/7/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKContact.h"

@implementation LCCKContact
@synthesize userId = _userId;
@synthesize name = _name;
@synthesize avatarURL = _avatarURL;
@synthesize clientId = _clientId;

- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL clientId:(NSString *)clientId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _userId = userId;
    _name = name;
    _avatarURL = avatarURL;
    _clientId = clientId;
    return self;
}

+ (instancetype)userWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL clientId:(NSString *)clientId{
    LCCKContact *user = [[LCCKContact alloc] initWithUserId:userId name:name avatarURL:avatarURL clientId:clientId];
    return user;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[LCCKContact alloc] initWithUserId:self.userId
                                       name:self.name
                                  avatarURL:self.avatarURL
                                   clientId:self.clientId
            ];
}

@end
