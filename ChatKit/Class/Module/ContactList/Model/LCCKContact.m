//
//  LCCKContact.m
//  ChatKit
//
//  v0.8.5 Created by ElonChan on 16/7/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKContact.h"

@implementation LCCKContact
@synthesize userId = _userId;
@synthesize name = _name;
@synthesize avatarURL = _avatarURL;
@synthesize clientId = _clientId;
@synthesize sex = _sex;


- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL clientId:(NSString *)clientId sex:(NSString *)sex {
    self = [super init];
    if (!self) {
        return nil;
    }
    _userId = userId;
    _name = name;
    _avatarURL = avatarURL;
    _clientId = clientId;
    _sex = sex;
    return self;
}

+ (instancetype)userWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL clientId:(NSString *)clientId sex:(NSString *)sex {
    LCCKContact *user = [[LCCKContact alloc] initWithUserId:userId name:name avatarURL:avatarURL clientId:clientId sex:sex];
    return user;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[LCCKContact alloc] initWithUserId:self.userId
                                       name:self.name
                                  avatarURL:self.avatarURL
                                   clientId:self.clientId
                                           sex:self.sex
            ];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userId forKey:@"userId"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.avatarURL forKey:@"avatarURL"];
    [aCoder encodeObject:self.clientId forKey:@"clientId"];
    [aCoder encodeObject:self.sex forKey:@"sex"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super init]){
        _userId = [aDecoder decodeObjectForKey:@"userId"];
        _name = [aDecoder decodeObjectForKey:@"name"];
        _avatarURL = [aDecoder decodeObjectForKey:@"avatarURL"];
        _clientId = [aDecoder decodeObjectForKey:@"clientId"];
        _sex = [aDecoder decodeObjectForKey:@"sex"];
    }
    return self;
}

@end
