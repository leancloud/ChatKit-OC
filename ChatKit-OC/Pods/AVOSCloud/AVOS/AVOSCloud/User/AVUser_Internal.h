//
//  AVUser_Internal.h
//  paas
//
//  Created by Zhu Zeng on 3/14/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVUser.h"

#define AnonymousIdKey @"LeanCloud.AnonymousId"

@interface AVUser ()

@property (nonatomic, readwrite, copy) NSString *facebookToken;
@property (nonatomic, readwrite, copy) NSString *twitterToken;
@property (nonatomic, readwrite, copy) NSString *sinaWeiboToken;
@property (nonatomic, readwrite, copy) NSString *qqWeiboToken;
@property (nonatomic, readwrite) BOOL isNew;
@property (nonatomic, readwrite) BOOL mobilePhoneVerified;

- (BOOL)isAuthDataExistInMemory;

+ (AVUser *)userOrSubclassUser;

+(NSString *)userTag;
+(BOOL)isAutomaticUserEnabled;
+(void)disableAutomaticUser;

+(NSString *)endPoint;
-(NSString *)internalClassName;
-(void)setNewFlag:(BOOL)isNew;

+(void)removeCookies;

- (NSArray *)linkedServiceNames;
@end
