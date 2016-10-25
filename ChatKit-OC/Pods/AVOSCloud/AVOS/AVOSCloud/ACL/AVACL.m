//
//  AVACL.m
//  AVOSCloud
//
//  Created by Zhu Zeng on 3/13/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVACL.h"
#import "AVACL_Internal.h"
#import "AVUser.h"
#import "AVRole.h"
#import "AVPaasClient.h"

static NSString * readTag = @"read";
static NSString * writeTag = @"write";

@implementation AVACL

@synthesize permissionsById = _permissionsById;

-(id)copyWithZone:(NSZone *)zone
{
    AVACL *newObject = [[[self class] allocWithZone:zone] init];
    if(newObject) {
        newObject.permissionsById = [self.permissionsById mutableCopy];
    }
    return newObject;
}

+ (AVACL *)ACL
{
    AVACL * result = [[AVACL alloc] init];
    return result;
}

+ (AVACL *)ACLWithUser:(AVUser *)user
{
    AVACL * result = [[AVACL alloc] init];
    [result setReadAccess:YES forUser:user];
    [result setWriteAccess:YES forUser:user];
    return result;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _permissionsById = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(NSDictionary *)dictionary:(BOOL)read
                      write:(BOOL)write
{
    NSDictionary * dictionary = @{readTag: [NSNumber numberWithBool:read], writeTag: [NSNumber numberWithBool:write]};
    return dictionary;
}

-(NSString *)publicTag
{
    return @"*";
}

-(NSMutableDictionary * )dictionaryForKey:(NSString *)key
                                   create:(BOOL)create
{
    NSMutableDictionary * data = [self.permissionsById objectForKey:key];
    if (data == nil && create)
    {
        data = [[NSMutableDictionary alloc] init];
        [self.permissionsById setObject:data forKey:key];
    }
    return data;
}

-(void)allowRead:(BOOL)allowed
             key:(NSString *)key
{
    NSMutableDictionary * data = [self dictionaryForKey:key create:allowed];
    if (allowed)
    {
        [data setObject:[NSNumber numberWithBool:allowed] forKey:readTag];
    }
    else
    {
        [data removeObjectForKey:readTag];
    }
}

-(BOOL)isReadAllowed:(NSString *)key
{
    NSMutableDictionary * data = [self dictionaryForKey:key create:NO];
    return [[data objectForKey:readTag] boolValue];
}

-(void)allowWrite:(BOOL)allowed
              key:(NSString *)key
{
    NSMutableDictionary * data = [self dictionaryForKey:key create:allowed];
    if (allowed)
    {
        [data setObject:[NSNumber numberWithBool:allowed] forKey:writeTag];
    }
    else
    {
        [data removeObjectForKey:writeTag];
    }
}

-(BOOL)isWriteAllowed:(NSString *)key
{
    NSMutableDictionary * data = [self dictionaryForKey:key create:NO];
    return [[data objectForKey:writeTag] boolValue];
}

- (void)setPublicReadAccess:(BOOL)allowed
{
    [self allowRead:allowed key:[self publicTag]];
}

- (BOOL)getPublicReadAccess
{
    return [self isReadAllowed:[self publicTag]];
}

- (void)setPublicWriteAccess:(BOOL)allowed
{
    [self allowWrite:allowed key:[self publicTag]];
}

- (BOOL)getPublicWriteAccess
{
    return [self isWriteAllowed:[self publicTag]];
}

- (void)setReadAccess:(BOOL)allowed forUserId:(NSString *)userId
{
    [self allowRead:allowed key:userId];
}

- (BOOL)getReadAccessForUserId:(NSString *)userId
{
    return [self isReadAllowed:userId];
}

- (void)setWriteAccess:(BOOL)allowed forUserId:(NSString *)userId
{
    [self allowWrite:allowed key:userId];
}

- (BOOL)getWriteAccessForUserId:(NSString *)userId
{
    return [self isWriteAllowed:userId];
}

- (void)setReadAccess:(BOOL)allowed forUser:(AVUser *)user
{
    [self allowRead:allowed key:user.objectId];
}

- (BOOL)getReadAccessForUser:(AVUser *)user
{
    return [self getReadAccessForUserId:user.objectId];
}

- (void)setWriteAccess:(BOOL)allowed forUser:(AVUser *)user
{
    [self setWriteAccess:allowed forUserId:user.objectId];
}

- (BOOL)getWriteAccessForUser:(AVUser *)user
{
    return [self getWriteAccessForUserId:user.objectId];
}

-(NSString *)roleName:(NSString *)name
{
    return [NSString stringWithFormat:@"role:%@", name];
}

- (BOOL)getReadAccessForRoleWithName:(NSString *)name
{
    return [self isReadAllowed:[self roleName:name]];
}

- (void)setReadAccess:(BOOL)allowed forRoleWithName:(NSString *)name
{
    [self allowRead:allowed key:[self roleName:name]];
}

- (BOOL)getWriteAccessForRoleWithName:(NSString *)name
{
    return [self isWriteAllowed:[self roleName:name]];
}

- (void)setWriteAccess:(BOOL)allowed forRoleWithName:(NSString *)name
{
    return [self allowWrite:allowed key:[self roleName:name]];
}

- (BOOL)getReadAccessForRole:(AVRole *)role
{
    return [self isReadAllowed:[self roleName:role.name]];
}

- (void)setReadAccess:(BOOL)allowed forRole:(AVRole *)role
{
    [self allowRead:allowed key:[self roleName:role.name]];
}

- (BOOL)getWriteAccessForRole:(AVRole *)role
{
    return [self isWriteAllowed:[self roleName:role.name]];
}

- (void)setWriteAccess:(BOOL)allowed forRole:(AVRole *)role
{
    [self allowWrite:allowed key:[self roleName:role.name]];
}

+ (void)setDefaultACL:(AVACL *)acl withAccessForCurrentUser:(BOOL)currentUserAccess
{
    [AVPaasClient sharedInstance].defaultACL = acl;
    [AVPaasClient sharedInstance].currentUserAccessForDefaultACL = currentUserAccess;
}


@end
