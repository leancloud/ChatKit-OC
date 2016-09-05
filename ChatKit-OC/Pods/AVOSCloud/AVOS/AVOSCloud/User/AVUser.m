// AVUser.h
// Copyright 2013 AVOS, Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import "AVConstants.h"
#import "AVObject.h"
#import "AVObject_Internal.h"
#import "AVUser.h"
#import "AVPaasClient.h"
#import "AVUtils.h"
#import "AVQuery.h"
#import "AVUser_Internal.h"
#import "AVPersistenceUtils.h"
#import "AVObjectUtils.h"
#import "AVPaasClient.h"
#import "AVErrorUtils.h"
#import "AVOSCloud_Internal.h"

#import "AVFriendQuery.h"
#import "AVUtils.h"

static BOOL enableAutomatic = NO;

@class AVQuery;

@implementation  AVUser

@synthesize sessionToken = _sessionToken;
@synthesize isNew = _isNew;
@synthesize username = _username;
@synthesize password = _password;
@synthesize email = _email;
@synthesize mobilePhoneVerified = _mobilePhoneVerified;
@synthesize facebookToken = _facebookToken;
@synthesize twitterToken = _twitterToken;
@synthesize sinaWeiboToken = _sinaWeiboToken;
@synthesize qqWeiboToken = _qqWeiboToken;
@synthesize mobilePhoneNumber = _mobilePhoneNumber;

+ (NSString *)parseClassName
{
    return [AVUser userTag];
}

+(void)changeCurrentUser:(AVUser *)newUser
                    save:(BOOL)save
{
    if (newUser && save) {
        NSMutableDictionary * json = [newUser userDictionaryForCache];
        [json removeObjectForKey:passwordTag];
        [AVPersistenceUtils saveJSON:json toPath:[AVPersistenceUtils currentUserArchivePath]];
        [AVPersistenceUtils saveJSON:@{@"class": NSStringFromClass([newUser class])}
                              toPath:[AVPersistenceUtils currentUserClassArchivePath]];
    } else if (save) {
        [AVPersistenceUtils removeFile:[AVPersistenceUtils currentUserArchivePath]];
        [AVPersistenceUtils removeFile:[AVPersistenceUtils currentUserClassArchivePath]];
    }
    [AVPaasClient sharedInstance].currentUser = newUser;
}

+ (instancetype)currentUser
{
    AVUser * u = [AVPaasClient sharedInstance].currentUser;
    if (u) {
        return u;
    } else if ([AVPersistenceUtils fileExist:[AVPersistenceUtils currentUserArchivePath]]) {
        NSMutableDictionary *userDict = [NSMutableDictionary dictionaryWithDictionary:[AVPersistenceUtils getJSONFromPath:[AVPersistenceUtils currentUserArchivePath]]];
        if (userDict) {
            if ([AVPersistenceUtils fileExist:[AVPersistenceUtils currentUserClassArchivePath]]) {
                NSDictionary *classDict = [AVPersistenceUtils getJSONFromPath:[AVPersistenceUtils currentUserClassArchivePath]];
                u = [NSClassFromString(classDict[@"class"]) user];
            } else {
                u = [self userOrSubclassUser];
            }
            
            [AVObjectUtils copyDictionary:userDict toObject:u];
            [AVPaasClient sharedInstance].currentUser = u;
            return u;
        }
    }
    if (!enableAutomatic) {
        return u;
    }
    
    AVUser *user = [self userOrSubclassUser];
    [[self class] changeCurrentUser:user save:NO];
    return user;
}

- (BOOL)isAuthenticated
{
    if (self.sessionToken.length > 0 ||
        self.sinaWeiboToken.length > 0 ||
        [self objectForKey:authDataTag]) // for sns user
    {
        return YES;
    }
    return NO;
}

- (NSArray *)linkedServiceNames {
    NSDictionary *dict = [self objectForKey:authDataTag];
    return[dict allKeys];
}

+ (instancetype)user
{
    AVUser *u = [[[self class] alloc] initWithClassName:[[self class] userTag]];
    return u;
}

+ (AVUser *)userOrSubclassUser {
    return (AVUser *)[AVObjectUtils avObjectForClass:[AVUser userTag]];
}

+ (void)enableAutomaticUser
{
    enableAutomatic = YES;
}

+(BOOL)isAutomaticUserEnabled
{
    return enableAutomatic;
}

+(void)disableAutomaticUser
{
    enableAutomatic = NO;
}

-(NSError *)preSave
{
    if ([self isAuthenticated])
    {
        return nil;
    }
    return [AVErrorUtils errorWithCode:kAVErrorUserCannotBeAlteredWithoutSession];
}

-(void)postSave
{
    [super postSave];
    [[self class] changeCurrentUser:self save:YES];
}

- (void)postDelete {
    [super postDelete];
    if (self == [AVUser currentUser]) {
        [AVUser logOut];
    }
}

- (BOOL)signUp
{
    return [self signUp:NULL];
}

- (BOOL)signUp:(NSError *__autoreleasing *)error
{
    return [self saveWithOption:nil eventually:NO verifyBefore:NO error:error];
}

- (void)signUpInBackground
{
    [self signUpInBackgroundWithBlock:nil];
}

- (void)signUpInBackgroundWithBlock:(AVBooleanResultBlock)block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        [self signUp:&error];
        [AVUtils callBooleanResultBlock:block error:error];
    });
}

/*
 * If an user is not login, update that user will failed.
 * So, we should not include update requests when sign up user.
 */
- (BOOL)shouldIncludeUpdateRequests {
    return self.objectId != nil;
}

-(NSMutableDictionary *)userDictionary
{
    NSMutableDictionary * parameters = [[NSMutableDictionary alloc] init];
    if (self.username) {
        [parameters setObject:self.username forKey:usernameTag];
    }
    if (self.password) {
        [parameters setObject:self.password forKey:passwordTag];
    }
    if (self.email) {
        [parameters setObject:self.email forKey:emailTag];
    }
    if (self.mobilePhoneNumber) {
        [parameters setObject:self.mobilePhoneNumber forKey:mobilePhoneNumberTag];
    }
    return parameters;
}

-(NSMutableDictionary *)userDictionaryForCache
{
    NSMutableDictionary * data = [self postData];
    return data;
}

-(NSMutableDictionary *)initialBodyData {
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    NSMutableDictionary *dict = [[self.requestManager jsonForCloud] firstObject];

    if (dict) {
        [body addEntriesFromDictionary:dict];
    }

    return body;
}

+(void)requestEmailVerify:(NSString*)email withBlock:(AVBooleanResultBlock)block{
    NSParameterAssert(email);
    
    [[AVPaasClient sharedInstance] postObject:@"requestEmailVerify" withParameters:@{@"email":email} block:^(id object, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    }];
}

+(void)requestMobilePhoneVerify:(NSString *)phoneNumber withBlock:(AVBooleanResultBlock)block {
    NSParameterAssert(phoneNumber);
    
    [[AVPaasClient sharedInstance] postObject:@"requestMobilePhoneVerify" withParameters:@{ @"mobilePhoneNumber" : phoneNumber } block:^(id object, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    }];
}

+(void)verifyMobilePhone:(NSString *)code withBlock:(AVBooleanResultBlock)block {
    NSParameterAssert(code);
    
    NSString *path=[NSString stringWithFormat:@"verifyMobilePhone/%@",code];
    
    [[AVPaasClient sharedInstance] getObject:path withParameters:nil block:^(id object, NSError *error) {
        if (!error) {
            [[AVUser currentUser] setMobilePhoneVerified:YES];
        } else {
            [[AVUser currentUser] setMobilePhoneVerified:NO];
        }
        [self changeCurrentUser:[AVUser currentUser] save:YES];
        [AVUtils callBooleanResultBlock:block error:error];
    }];
    
}

- (void)signUpInBackgroundWithTarget:(id)target selector:(SEL)selector
{
    [self signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:@(succeeded) object:error];
    }];
}

- (void)updatePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword withTarget:(id)target selector:(SEL)selector {
    [self updatePassword:oldPassword newPassword:newPassword block:^(id object, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:object object:error];
    }];
}

- (void)updatePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword block:(AVIdResultBlock)block {
    if (self.isAuthenticated && oldPassword && newPassword) {
        NSString *pathComponent = [NSString stringWithFormat:@"users/%@/updatePassword", self.objectId];
        NSString *path = [[[AVOSCloud RESTBaseURL] URLByAppendingPathComponent:pathComponent] absoluteString];
        NSDictionary *params = @{@"old_password":oldPassword,
                                 @"new_password":newPassword};
        [[AVPaasClient sharedInstance] putObject:path withParameters:params sessionToken:self.sessionToken block:^(id object, NSError *error) {
            if (!error) {
                // {"sessionToken":"kns1w56ch9b3mn308i13bkln6",
                //  "updatedAt":"2015-10-20T03:12:38.203Z",
                //  "objectId":"5625b11b60b2fc79c2fb8c40"}
                [AVObjectUtils copyDictionary:object toObject:self];
                if (self == [AVUser currentUser]) {
                    [AVUser changeCurrentUser:self save:YES];
                }
            }
            [AVUtils callIdResultBlock:block object:self error:error];
        }];
    } else {
        NSError *error = nil;
        if (!self.isAuthenticated) {
            error= [AVErrorUtils errorWithCode:kAVErrorUserCannotBeAlteredWithoutSession];
        }
        
        if (!(oldPassword && newPassword)) {
            error = [AVErrorUtils errorWithCode:kAVErrorUserPasswordMissing];
        }
        [AVUtils callIdResultBlock:block object:nil error:error];
    }
}

+(NSDictionary *)userParameter:(NSString *)username
                      password:(NSString *)password
{
    NSDictionary * parameters = @{usernameTag: username, passwordTag:password};
    return parameters;
}

+ (instancetype)logInWithUsername:(NSString *)username
                     password:(NSString *)password
{
    return [[self class] logInWithUsername:username password:password error:nil];
}

+ (instancetype)logInWithUsername:(NSString *)username
                     password:(NSString *)password
                        error:(NSError **)error
{
    __block AVUser * resultUser = nil;
    [[self class] logInWithUsername:username password:password block:^(AVUser *user, NSError *error) {
        resultUser = user;
    } waitUntilDone:YES error:error];
    return resultUser;
}

+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
{
    [[self class] logInWithUsername:username password:password block:nil waitUntilDone:YES error:nil];
}

+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                               target:(id)target
                             selector:(SEL)selector
{
    [[self class] logInWithUsernameInBackground:username
                                       password:password
                                          block:^(AVUser *user, NSError *error) {
                                              [AVUtils performSelectorIfCould:target selector:selector object:user object:error];
                                          }];
}

+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                                block:(AVUserResultBlock)block
{
    [[self class] logInWithUsername:username password:password block:^(AVUser *user, NSError * error) {
        [AVUtils callUserResultBlock:block user:user error:error];
    }
    waitUntilDone:NO error:nil];
    
}

+ (BOOL)logInWithUsername:(NSString *)username
                 password:(NSString *)password
                    block:(AVUserResultBlock)block
            waitUntilDone:(BOOL)wait
                    error:(NSError **)theError {
    
    BOOL __block theResult = NO;
    BOOL __block hasCalledBack = NO;
    NSError __block *blockError = nil;
    
    NSDictionary * parameters = [[self class] userParameter:username password:password];
    [[AVPaasClient sharedInstance] postObject:@"login" withParameters:parameters block:^(id object, NSError *error) {
        AVUser * user = nil;
        if (error == nil)
        {
            user = [self userOrSubclassUser];
            user.username = username;
            user.password = password;
            [AVObjectUtils copyDictionary:object toObject:user];
            [user.requestManager clear];
            [[self class] changeCurrentUser:user save:YES];
        }
        
        if (wait) {
            blockError = error;
            theResult = (error == nil);
            hasCalledBack = YES;
        }
        [AVUtils callUserResultBlock:block user:user error:error];
    }];

    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    };
    
    if (theError != NULL) *theError = blockError;
    return theResult;
}

+ (instancetype)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                         password:(NSString *)password
{
    return [[self class] logInWithMobilePhoneNumber:phoneNumber password:password error:nil];
}

+ (instancetype)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                         password:(NSString *)password
                            error:(NSError **)error
{
    __block AVUser * resultUser = nil;
    [self logInWithMobilePhoneNumber:phoneNumber password:password block:^(AVUser *user, NSError *error) {
        resultUser = user;
    } waitUntilDone:YES error:error];
    return resultUser;
}

+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                             password:(NSString *)password
{
    [self logInWithMobilePhoneNumber:phoneNumber password:password block:nil waitUntilDone:YES error:nil];
}

+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                             password:(NSString *)password
                               target:(id)target
                             selector:(SEL)selector
{
    [self logInWithMobilePhoneNumberInBackground:phoneNumber
                                       password:password
                                          block:^(AVUser *user, NSError *error) {
                                              [AVUtils performSelectorIfCould:target selector:selector object:user object:error];
                                          }];
}

+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                             password:(NSString *)password
                                block:(AVUserResultBlock)block
{
    [self logInWithMobilePhoneNumber:phoneNumber password:password block:^(AVUser *user, NSError * error) {
        [AVUtils callUserResultBlock:block user:user error:error];
    }
                      waitUntilDone:NO error:nil];
    
}
+ (BOOL)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                 password:(NSString *)password
                    block:(AVUserResultBlock)block
            waitUntilDone:(BOOL)wait
                    error:(NSError **)theError {
    
    BOOL __block theResult = NO;
    BOOL __block hasCalledBack = NO;
    NSError __block *blockError = nil;
    
    NSDictionary * parameters = @{mobilePhoneNumberTag: phoneNumber, passwordTag:password};
    [[AVPaasClient sharedInstance] postObject:@"login" withParameters:parameters block:^(id object, NSError *error) {
        AVUser * user = nil;
        if (error == nil)
        {
            user = [self userOrSubclassUser];
            [AVObjectUtils copyDictionary:object toObject:user];
            [user.requestManager clear];
            [[self class] changeCurrentUser:user save:YES];
        }
        
        if (wait) {
            blockError = error;
            theResult = (error == nil);
            hasCalledBack = YES;
        }
        [AVUtils callUserResultBlock:block user:user error:error];
    }];
    
    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    };
    
    if (theError != NULL) *theError = blockError;
    return theResult;
}

+ (void)becomeWithSessionTokenInBackground:(NSString *)sessionToken block:(AVUserResultBlock)block {
    [self internalBecomeWithSessionTokenInBackground:sessionToken block:^(AVUser *user, NSError *error) {
        [AVUtils callUserResultBlock:block user:user error:error];
    }];
}

+ (void)internalBecomeWithSessionTokenInBackground:(NSString *)sessionToken block:(AVUserResultBlock)block {
    if (sessionToken == nil) {
        [NSException raise:NSInvalidArgumentException format:@"sessionToken is nil"];
        return;
    }
    [[AVPaasClient sharedInstance] getObject:[NSString stringWithFormat:@"%@/%@", [self endPoint], @"me"] withParameters:@{@"session_token": sessionToken} block:^(id object, NSError *error) {
        AVUser *user;
        if (!error) {
            user = [self userOrSubclassUser];
            [user objectFromDictionary:object];
            [[self class] changeCurrentUser:user save:YES];
        }
        if (block) {
            block(user, error);
        }
    }];
}

+ (instancetype)becomeWithSessionToken:(NSString *)sessionToken error:(NSError **)error {
    __block Boolean hasCallback = NO;
    __block AVUser *user;
    [self internalBecomeWithSessionTokenInBackground:sessionToken block:^(AVUser *theUser, NSError *theError) {
        user = theUser;
        if (error) {
            *error = theError;
        }
        hasCallback = YES;
    }];
    AV_WAIT_TIL_TRUE(hasCallback, 0.1);
    return user;
}

+(void)requestLoginSmsCode:(NSString *)phoneNumber withBlock:(AVBooleanResultBlock)block {
    NSParameterAssert(phoneNumber);
    
    [[AVPaasClient sharedInstance] postObject:@"requestLoginSmsCode" withParameters:@{ @"mobilePhoneNumber" : phoneNumber } block:^(id object, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    }];
}

+ (instancetype)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                                  smsCode:(NSString *)code
{
    return [[self class] logInWithMobilePhoneNumber:phoneNumber smsCode:code error:nil];
}

+ (instancetype)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                                  smsCode:(NSString *)code
                                     error:(NSError **)error
{
    __block AVUser * resultUser = nil;
    [self logInWithMobilePhoneNumber:phoneNumber smsCode:code block:^(AVUser *user, NSError *error) {
        resultUser = user;
    } waitUntilDone:YES error:error];
    return resultUser;
}

+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                      smsCode:(NSString *)code
{
    [self logInWithMobilePhoneNumber:phoneNumber smsCode:code block:nil waitUntilDone:YES error:nil];
}

+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                      smsCode:(NSString *)code
                                        target:(id)target
                                      selector:(SEL)selector
{
    [self logInWithMobilePhoneNumberInBackground:phoneNumber
                                        smsCode:code
                                           block:^(AVUser *user, NSError *error) {
                                               [AVUtils performSelectorIfCould:target selector:selector object:user object:error];
                                           }];
}

+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                      smsCode:(NSString *)code
                                         block:(AVUserResultBlock)block
{
    [self logInWithMobilePhoneNumber:phoneNumber smsCode:code block:^(AVUser *user, NSError * error) {
        [AVUtils callUserResultBlock:block user:user error:error];
    }
                       waitUntilDone:NO error:nil];
    
}
+ (BOOL)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                          smsCode:(NSString *)smsCode
                             block:(AVUserResultBlock)block
                     waitUntilDone:(BOOL)wait
                             error:(NSError **)theError {
    
    BOOL __block theResult = NO;
    BOOL __block hasCalledBack = NO;
    NSError __block *blockError = nil;
    
    NSDictionary * parameters = @{mobilePhoneNumberTag: phoneNumber, smsCodeTag:smsCode};
    [[AVPaasClient sharedInstance] postObject:@"login" withParameters:parameters block:^(id object, NSError *error) {
        AVUser * user = nil;
        if (error == nil)
        {
            user = [self userOrSubclassUser];
            //            user.username = username;
            //            user.password = password;
            user.mobilePhoneVerified = YES;
            [AVObjectUtils copyDictionary:object toObject:user];
            [user.requestManager clear];
            [[self class] changeCurrentUser:user save:YES];
        }
        
        if (wait) {
            blockError = error;
            theResult = (error == nil);
            hasCalledBack = YES;
        }
        [AVUtils callUserResultBlock:block user:user error:error];
    }];
    
    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    };
    
    if (theError != NULL) *theError = blockError;
    return theResult;
}

+ (instancetype)signUpOrLoginWithMobilePhoneNumber:(NSString *)phoneNumber
                                           smsCode:(NSString *)code {
    return [self signUpOrLoginWithMobilePhoneNumber:phoneNumber smsCode:code error:nil];
}

+ (instancetype)signUpOrLoginWithMobilePhoneNumber:(NSString *)phoneNumber
                                           smsCode:(NSString *)code
                                             error:(NSError **)error {
    __block AVUser * resultUser = nil;
    [self signUpOrLoginWithMobilePhoneNumber:phoneNumber smsCode:code block:^(AVUser *user, NSError *error) {
        resultUser = user;
    } waitUntilDone:YES error:error];
    return resultUser;
}

+ (void)signUpOrLoginWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                               smsCode:(NSString *)code {
    [self signUpOrLoginWithMobilePhoneNumber:phoneNumber smsCode:code block:nil waitUntilDone:YES error:nil];
}

+ (void)signUpOrLoginWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                               smsCode:(NSString *)code
                                                target:(id)target
                                              selector:(SEL)selector {
    [self signUpOrLoginWithMobilePhoneNumberInBackground:phoneNumber
                                                 smsCode:code
                                                   block:^(AVUser *user, NSError *error) {
                                                       [AVUtils performSelectorIfCould:target selector:selector object:user object:error];
                                                   }];
}

+ (void)signUpOrLoginWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                               smsCode:(NSString *)code
                                                 block:(AVUserResultBlock)block {
    [self signUpOrLoginWithMobilePhoneNumber:phoneNumber smsCode:code block:^(AVUser *user, NSError *error) {
        [AVUtils callUserResultBlock:block user:user error:error];
    } waitUntilDone:NO error:NULL];
}

+ (BOOL)signUpOrLoginWithMobilePhoneNumber:(NSString *)phoneNumber
                                   smsCode:(NSString *)smsCode
                                     block:(AVUserResultBlock)block
                             waitUntilDone:(BOOL)wait
                                     error:(NSError **)theError {
    
    BOOL __block theResult = NO;
    BOOL __block hasCalledBack = NO;
    NSError __block *blockError = nil;
    
    NSDictionary * parameters = @{mobilePhoneNumberTag: phoneNumber, smsCodeTag:smsCode};
    [[AVPaasClient sharedInstance] postObject:@"usersByMobilePhone" withParameters:parameters block:^(id object, NSError *error) {
        AVUser * user = nil;
        if (error == nil)
        {
            user = [self userOrSubclassUser];
            //            user.username = username;
            //            user.password = password;
            [AVObjectUtils copyDictionary:object toObject:user];
            [user.requestManager clear];
            [[self class] changeCurrentUser:user save:YES];
        }
        
        if (wait) {
            blockError = error;
            theResult = (error == nil);
            hasCalledBack = YES;
        }
        [AVUtils callUserResultBlock:block user:user error:error];
    }];
    
    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    };
    
    if (theError != NULL) *theError = blockError;
    return theResult;
}

+(void)removeCookies {
    // delete cookies
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        if ([[AVPaasClient sharedInstance].baseURL rangeOfString:cookie.domain].location != NSNotFound) {
            [storage deleteCookie:cookie];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)logOut {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:AnonymousIdKey];
    [AVUser removeCookies];
    [[self class] changeCurrentUser:nil save:YES];
}

+ (BOOL)requestPasswordResetForEmail:(NSString *)email
{
    return [[self class] requestPasswordResetForEmail:email error:nil];
}

+ (BOOL)requestPasswordResetForEmail:(NSString *)email
                               error:(NSError **)resultError
{
    BOOL wait = YES;
    BOOL __block theResult = NO;
    BOOL __block hasCalledBack = NO;
    NSError * __block  theError = nil;

    [self internalRequestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *callBackError) {
        if (wait) {
            hasCalledBack = YES;
            theResult = succeeded;
            theError = callBackError;
        }
    }];
    
    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);        
    };
    
    if (resultError != NULL) *resultError = theError;
    return theResult;

}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
{
    [[self class] requestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *error) {
        
    }];
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
                                          target:(id)target
                                        selector:(SEL)selector
{
    [[self class] requestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:@(succeeded) object:error];
    }];    
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
                                            block:(AVBooleanResultBlock)block {
    [self internalRequestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    }];
}

+ (void)internalRequestPasswordResetForEmailInBackground:(NSString *)email
                                           block:(AVBooleanResultBlock)block
{
    NSDictionary * parameters = @{emailTag: email};
    [[AVPaasClient sharedInstance] postObject:@"requestPasswordReset" withParameters:parameters block:^(id object, NSError *error) {
        if (block) {
            block(error == nil, error);
        }
    }];
}

+(void)requestPasswordResetWithPhoneNumber:(NSString *)phoneNumber block:(AVBooleanResultBlock)block {
    NSParameterAssert(phoneNumber);
    
    [[AVPaasClient sharedInstance] postObject:@"requestPasswordResetBySmsCode" withParameters:@{ @"mobilePhoneNumber" : phoneNumber } block:^(id object, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    }];
}

+(void)resetPasswordWithSmsCode:(NSString *)code
                    newPassword:(NSString *)password
                          block:(AVBooleanResultBlock)block {
    NSParameterAssert(code);
    
    NSString *path=[NSString stringWithFormat:@"resetPasswordBySmsCode/%@",code];
    [[AVPaasClient sharedInstance] putObject:path withParameters:@{ @"password" : password } sessionToken:nil block:^(id object, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    }];
}

+ (AVQuery *)query
{
    AVQuery *query = [[AVQuery alloc] initWithClassName:[[self class] userTag]];
    return query;
}

+(NSString *)userTag
{
    return @"_User";
}

+(NSString *)endPoint
{
    return @"users";
}

-(NSString *)internalClassName
{
    return @"_User";
}

-(void)setNewFlag:(BOOL)isNew
{
    self.isNew = isNew;
}

#pragma mark - Override from AVObject
-(NSMutableDictionary *)postData
{
    // TO BE REMOVED
    NSMutableDictionary * data = [super postData];
    [data addEntriesFromDictionary:[self userDictionary]];
    return data;
}

-(void)setUsername:(NSString *)username {
    _username = username;
    [self addSetRequest:usernameTag object:username];
}

-(void)setPassword:(NSString *)password {
    _password = password;
    [self addSetRequest:passwordTag object:password];
}

-(void)setEmail:(NSString *)email {
    _email = email;
    [self addSetRequest:emailTag object:email];
}

- (void)setMobilePhoneNumber:(NSString *)mobilePhoneNumber {
    _mobilePhoneNumber = mobilePhoneNumber;
    [self addSetRequest:mobilePhoneNumberTag object:mobilePhoneNumber];
}

- (NSDictionary *)snapshot {
    NSMutableDictionary *snapshot = [[super snapshot] mutableCopy];
    [snapshot removeObjectForKey:passwordTag];
    return snapshot;
}

@end


@implementation AVUser (Friendship)

+(AVQuery*)followerQuery:(NSString*)userObjectId{
    AVFriendQuery *query=[AVFriendQuery queryWithClassName:@"_Follower"];
    query.targetFeild=@"follower";
    
    AVUser *user=[self user];
    user.objectId=userObjectId;
    [query whereKey:@"user" equalTo:user];
    
    [query includeKey:@"follower"];
    [query selectKeys:@[@"follower"]];
    
    return query;
}

+(AVQuery*)followeeQuery:(NSString*)userObjectId{
    AVFriendQuery *query=[AVFriendQuery queryWithClassName:@"_Followee"];
    query.targetFeild=@"followee";
    
    AVUser *user=[self user];
    user.objectId=userObjectId;
    [query whereKey:@"user" equalTo:user];
    
    [query includeKey:@"followee"];
    [query selectKeys:@[@"followee"]];
    
    return query;
}

-(AVQuery*)followeeQuery{
    return [AVUser followeeQuery:self.objectId];
}

-(AVQuery*)followerQuery{
    return [AVUser followerQuery:self.objectId];
}

-(void)follow:(NSString*)userId andCallback:(AVBooleanResultBlock)callback{
    [self follow:userId userDictionary:nil andCallback:callback];
}

-(void)follow:(NSString*)userId userDictionary:(NSDictionary *)dictionary andCallback:(AVBooleanResultBlock)callback{
    if (![self isAuthenticated]) {
        NSError *error= [AVErrorUtils errorWithCode:kAVErrorUserCannotBeAlteredWithoutSession];
        callback(NO,error);
        return;
    }
    NSDictionary *dict = [AVObjectUtils dictionaryFromObject:dictionary];
    NSString *path=[NSString stringWithFormat:@"users/self/friendship/%@",userId];
    
    [[AVPaasClient sharedInstance] postObject:path withParameters:dict block:^(NSDictionary *object, NSError *error) {
        [AVUtils callBooleanResultBlock:callback error:error];
    }];
}

-(void)unfollow:(NSString *)userId andCallback:(AVBooleanResultBlock)callback{
    if (![self isAuthenticated]) {
        NSError *error= [AVErrorUtils errorWithCode:kAVErrorUserCannotBeAlteredWithoutSession];
        callback(NO,error);
        return;
    }
    
    NSString *path=[NSString stringWithFormat:@"users/self/friendship/%@",userId];
    
    [[AVPaasClient sharedInstance] deleteObject:path withParameters:nil block:^(NSDictionary *object, NSError *error) {
        [AVUtils callBooleanResultBlock:callback error:error];
    }];
}

-(void)getFollowers:(AVArrayResultBlock)callback{
    
    AVQuery *query= [AVUser followerQuery:self.objectId];
    [query findObjectsInBackgroundWithBlock:callback];
    
}

-(void)getFollowees:(AVArrayResultBlock)callback{
    
    AVQuery *query= [AVUser followeeQuery:self.objectId];
    
    [query findObjectsInBackgroundWithBlock:callback];
    
}

-(void)getFollowersAndFollowees:(AVDictionaryResultBlock)callback{
    NSString *path=[NSString stringWithFormat:@"users/%@/followersAndFollowees?include=follower,followee",self.objectId];
    
    [[AVPaasClient sharedInstance] getObject:path withParameters:nil block:^(NSDictionary *object, NSError *error) {
        if (error==nil) {
            NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:2];
            @try {
                NSArray *orig=nil;
                NSArray *result=nil;
                
                orig=[object[@"followees"] valueForKeyPath:@"followee"];
                result=[AVObjectUtils arrayFromArray:orig];
                [dict setObject:result forKey:@"followees"];
                
                orig=[object[@"followers"] valueForKeyPath:@"follower"];
                result=[AVObjectUtils arrayFromArray:orig];
                [dict setObject:result forKey:@"followers"];
                
            }
            @catch (NSException *exception) {
                error=[AVErrorUtils errorWithCode:kAVErrorInternalServer errorText:@"wrong format return"];
            }
            @finally {
                [AVUtils callIdResultBlock:callback object:dict error:error];
            }
            
        } else {
            [AVUtils callIdResultBlock:callback object:object error:error];
        }
        
    }];
}



@end

