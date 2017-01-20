// AVUser.h
// Copyright 2013 AVOS, Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import "AVConstants.h"
#import "AVObject.h"
#import "AVSubclassing.h"

@class AVRole;
@class AVQuery;

NS_ASSUME_NONNULL_BEGIN

/*!
A LeanCloud Framework User Object that is a local representation of a user persisted to the LeanCloud. This class
 is a subclass of a AVObject, and retains the same functionality of a AVObject, but also extends it with various
 user specific methods, like authentication, signing up, and validation uniqueness.
 
 Many APIs responsible for linking a AVUser with Facebook or Twitter have been deprecated in favor of dedicated
 utilities for each social network. See AVFacebookUtils and AVTwitterUtils for more information.
 */


@interface AVUser : AVObject<AVSubclassing>

/** @name Accessing the Current User */

/*!
 Gets the currently logged in user from disk and returns an instance of it.
 @return a AVUser that is the currently logged in user. If there is none, returns nil.
 */
+ (nullable instancetype)currentUser;

/*!
 * change the current login user manually.
 *  @param newUser 新的 AVUser 实例
 *  @param save 是否需要把 newUser 保存到本地缓存。如果 newUser==nil && save==YES，则会清除本地缓存
 * Note: 请注意不要随意调用这个函数！
 */
+(void)changeCurrentUser:(nullable AVUser *)newUser
                    save:(BOOL)save;

/// The session token for the AVUser. This is set by the server upon successful authentication.
@property (nonatomic, copy, nullable) NSString *sessionToken;

/// Whether the AVUser was just created from a request. This is only set after a Facebook or Twitter login.
@property (nonatomic, assign, readonly) BOOL isNew;

/*!
 Whether the user is an authenticated object with the given sessionToken.
 */
- (void)isAuthenticatedWithSessionToken:(NSString *)sessionToken callback:(AVBooleanResultBlock)callback;

/** @name Creating a New User */

/*!
 Creates a new AVUser object.
 @return a new AVUser object.
 */
+ (instancetype)user;

/*!
 Enables automatic creation of anonymous users.  After calling this method, [AVUser currentUser] will always have a value.
 The user will only be created on the server once the user has been saved, or once an object with a relation to that user or
 an ACL that refers to the user has been saved.
 
 Note: saveEventually will not work if an item being saved has a relation to an automatic user that has never been saved.
 */
+ (void)enableAutomaticUser;

/// The username for the AVUser.
@property (nonatomic, copy, nullable) NSString *username;

/** 
 The password for the AVUser. This will not be filled in from the server with
 the password. It is only meant to be set.
 */
@property (nonatomic, copy, nullable) NSString *password;

/**
 *  Email of the user. If enable "Enable Email Verification" option in the console, when register a user, will send a verification email to the user. Otherwise, only save the email to the server.
 */
@property (nonatomic, copy, nullable) NSString *email;

/**
 *  Mobile phone number of the user. Can be set when registering. If enable the "Enable Mobile Phone Number Verification" option in the console, when register a user, will send an sms message to the phone. Otherwise, only save the mobile phone number to the server.
 */
@property (nonatomic, copy, nullable) NSString *mobilePhoneNumber;

/**
 *  Mobile phone number verification flag. Read-only. if calling verifyMobilePhone:withBlock: succeeds, the server will set this value YES.
 */
@property (nonatomic, assign, readonly) BOOL mobilePhoneVerified;

/**
 *  请求重发验证邮件
 *  如果用户邮箱没有得到验证或者用户修改了邮箱, 通过本方法重新发送验证邮件.
 *  
 *  @warning 为防止滥用,同一个邮件地址，1分钟内只能发1次!
 *
 *  @param email 邮件地址
 *  @param block 回调结果
 */
+(void)requestEmailVerify:(NSString*)email withBlock:(AVBooleanResultBlock)block;

/*!
 *  请求手机号码验证
 *  发送短信到指定的手机上，内容有6位数字验证码。验证码10分钟内有效。
 *  
 *  @warning 对同一个手机号码，每天有 5 条数量的限制，并且发送间隔需要控制在一分钟。
 *
 *  @param phoneNumber 11位电话号码
 *  @param block 回调结果
 */
+(void)requestMobilePhoneVerify:(NSString *)phoneNumber withBlock:(AVBooleanResultBlock)block;

/*!
 *  验证手机验证码
 *  发送验证码给服务器进行验证。
 *  @param code 6位手机验证码
 *  @param block 回调结果
 */
+(void)verifyMobilePhone:(NSString *)code withBlock:(AVBooleanResultBlock)block;

/*!
 Get roles which current user belongs to.

 @param error The error of request, or nil if request did succeed.

 @return An array of roles, or nil if some error occured.
 */
- (nullable NSArray<AVRole *> *)getRoles:(NSError **)error;

/*!
 An alias of `-[AVUser getRolesAndThrowsWithError:]` methods that supports Swift exception.
 @seealso `-[AVUser getRolesAndThrowsWithError:]`
 */
- (nullable NSArray<AVRole *> *)getRolesAndThrowsWithError:(NSError **)error;

/*!
 Asynchronously get roles which current user belongs to.

 @param block The callback for request.
 */
- (void)getRolesInBackgroundWithBlock:(void (^)(NSArray<AVRole *> * _Nullable objects, NSError * _Nullable error))block;

/*!
 Signs up the user. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 @param error Error object to set on error. 
 @return whether the sign up was successful.
 */
- (BOOL)signUp:(NSError **)error;

/*!
 An alias of `-[AVUser signUp:]` methods that supports Swift exception.
 @seealso `-[AVUser signUp:]`
 */
- (BOOL)signUpAndThrowsWithError:(NSError **)error;

/*!
 Signs up the user asynchronously. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
- (void)signUpInBackgroundWithBlock:(AVBooleanResultBlock)block;

/*!
 用旧密码来更新密码。在 3.1.6 之后，更新密码成功之后不再需要强制用户重新登录，仍然保持登录状态。
 @param oldPassword 旧密码
 @param newPassword 新密码
 @param block 完成时的回调，有以下签名 (id object, NSError *error)
 @warning 此用户必须登录且同时提供了新旧密码，否则不能更新成功。
 */
- (void)updatePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword block:(AVIdResultBlock)block;

/*!
 Makes a request to login a user with specified credentials. Returns an
 instance of the successfully logged in AVUser. This will also cache the user 
 locally so that calls to userFromCurrentUser will use the latest logged in user.
 @param username The username of the user.
 @param password The password of the user.
 @param error The error object to set on error.
 @return an instance of the AVUser on success. If login failed for either wrong password or wrong username, returns nil.
 */
+ (nullable instancetype)logInWithUsername:(NSString *)username
                                  password:(NSString *)password
                                     error:(NSError **)error;

/*!
 Makes an asynchronous request to log in a user with specified credentials.
 Returns an instance of the successfully logged in AVUser. This will also cache 
 the user locally so that calls to userFromCurrentUser will use the latest logged in user. 
 @param username The username of the user.
 @param password The password of the user.
 @param block The block to execute. The block should have the following argument signature: (AVUser *user, NSError *error) 
 */
+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                                block:(AVUserResultBlock)block;

//phoneNumber + password
/*!
 *  使用手机号码和密码登录
 *  @param phoneNumber 11位电话号码
 *  @param password 密码
 *  @param error 发生错误通过此参数返回
 */
+ (nullable instancetype)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                                           password:(NSString *)password
                                              error:(NSError **)error;
/*!
 *  使用手机号码和密码登录
 *  @param phoneNumber 11位电话号码
 *  @param password 密码
 *  @param block 回调结果
 */
+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                      password:(NSString *)password
                                         block:(AVUserResultBlock)block;
//phoneNumber + smsCode

/*!
 *  请求登录码验证
 *  发送短信到指定的手机上，内容有6位数字验证码。验证码10分钟内有效。
 *  @param phoneNumber 11位电话号码
 *  @param block 回调结果
 */
+(void)requestLoginSmsCode:(NSString *)phoneNumber withBlock:(AVBooleanResultBlock)block;

/*!
 *  使用手机号码和验证码登录
 *  @param phoneNumber 11位电话号码
 *  @param code 6位验证码
 *  @param error 发生错误通过此参数返回
 */
+ (nullable instancetype)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                                            smsCode:(NSString *)code
                                              error:(NSError **)error;

/*!
 *  使用手机号码和验证码登录
 *  @param phoneNumber 11位电话号码
 *  @param code 6位验证码
 *  @param block 回调结果
 */
+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                       smsCode:(NSString *)code
                                         block:(AVUserResultBlock)block;


/*!
 *  使用手机号码和验证码注册或登录
 *  用于手机号直接注册用户，需要使用 [AVOSCloud requestSmsCodeWithPhoneNumber:callback:] 获取验证码
 *  @param phoneNumber 11位电话号码
 *  @param code 6位验证码
 *  @param error 发生错误通过此参数返回
 */
+ (nullable instancetype)signUpOrLoginWithMobilePhoneNumber:(NSString *)phoneNumber
                                                    smsCode:(NSString *)code
                                                      error:(NSError **)error;

/*!
 *  使用手机号码和验证码注册或登录
 *  用于手机号直接注册用户，需要使用 [AVOSCloud requestSmsCodeWithPhoneNumber:callback:] 获取验证码
 *  @param phoneNumber 11位电话号码
 *  @param code 6位验证码
 *  @param block 回调结果
 */
+ (void)signUpOrLoginWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                               smsCode:(NSString *)code
                                                 block:(AVUserResultBlock)block;


/** @name Logging Out */

/*!
 Logs out the currently logged in user on disk.
 */
+ (void)logOut;

/** @name Requesting a Password Reset */


/*!
 Send a password reset request for a specified email and sets an error object. If a user
 account exists with that email, an email will be sent to that address with instructions 
 on how to reset their password.
 @param email Email of the account to send a reset password request.
 @param error Error object to set on error.
 @return true if the reset email request is successful. False if no account was found for the email address.
 */
+ (BOOL)requestPasswordResetForEmail:(NSString *)email
                               error:(NSError **)error;

/*!
 Send a password reset request asynchronously for a specified email.
 If a user account exists with that email, an email will be sent to that address with instructions
 on how to reset their password.
 @param email Email of the account to send a reset password request.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
                                           block:(AVBooleanResultBlock)block;

/*!
 *  使用手机号请求密码重置，需要用户绑定手机号码
 *  发送短信到指定的手机上，内容有6位数字验证码。验证码10分钟内有效。
 *  @param phoneNumber 11位电话号码
 *  @param block 回调结果
 */
+(void)requestPasswordResetWithPhoneNumber:(NSString *)phoneNumber
                                     block:(AVBooleanResultBlock)block;

/*!
 *  使用验证码重置密码
 *  @param code 6位验证码
 *  @param password 新密码
 *  @param block 回调结果
 */
+(void)resetPasswordWithSmsCode:(NSString *)code
                    newPassword:(NSString *)password
                          block:(AVBooleanResultBlock)block;

/*!
 *  用 sessionToken 来登录用户
 *  @param sessionToken sessionToken
 *  @param block        回调结果
 */
+ (void)becomeWithSessionTokenInBackground:(NSString *)sessionToken block:(AVUserResultBlock)block;
/*!
 *  用 sessionToken 来登录用户
 *  @param sessionToken sessionToken
 *  @param error        回调错误
 *  @return 登录的用户对象
 */
+ (nullable instancetype)becomeWithSessionToken:(NSString *)sessionToken error:(NSError **)error;

/** @name Querying for Users */

/*!
 Creates a query for AVUser objects.
 */
+ (AVQuery *)query;
@end

@interface AVUser (Deprecated)

/*!
 Signs up the user. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 @return true if the sign up was successful.
 */
- (BOOL)signUp AV_DEPRECATED("2.6.10");

/*!
 Signs up the user asynchronously. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 */
- (void)signUpInBackground AV_DEPRECATED("2.6.10");

/*!
 Signs up the user asynchronously. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchrounous request is complete. It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError **)error`. error will be nil on success and set if there was an error. `[result boolValue]` will tell you whether the call succeeded or not.
 */
- (void)signUpInBackgroundWithTarget:(id)target selector:(SEL)selector AV_DEPRECATED("2.6.10");

/*!
 update user's password
 @param oldPassword old password
 @param newPassword new password
 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchrounous request is complete. It should have the following signature: `(void)callbackWithResult:(id)object error:(NSError *)error`. error will be nil on success and set if there was an error.
 @warning the user must have logged in, and provide both oldPassword and newPassword, otherwise can't update password successfully.
 */
- (void)updatePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword withTarget:(id)target selector:(SEL)selector AV_DEPRECATED("2.6.10");

/*!
 Makes a request to login a user with specified credentials. Returns an instance
 of the successfully logged in AVUser. This will also cache the user locally so
 that calls to userFromCurrentUser will use the latest logged in user.
 @param username The username of the user.
 @param password The password of the user.
 @return an instance of the AVUser on success. If login failed for either wrong password or wrong username, returns nil.
 */
+ (nullable instancetype)logInWithUsername:(NSString *)username
                                  password:(NSString *)password  AV_DEPRECATED("2.6.10");

/*!
 Makes an asynchronous request to login a user with specified credentials.
 Returns an instance of the successfully logged in AVUser. This will also cache
 the user locally so that calls to userFromCurrentUser will use the latest logged in user.
 @param username The username of the user.
 @param password The password of the user.
 */
+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password AV_DEPRECATED("2.6.10");

/*!
 Makes an asynchronous request to login a user with specified credentials.
 Returns an instance of the successfully logged in AVUser. This will also cache
 the user locally so that calls to userFromCurrentUser will use the latest logged in user.
 The selector for the callback should look like: myCallback:(AVUser *)user error:(NSError **)error
 @param username The username of the user.
 @param password The password of the user.
 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchrounous request is complete.
 */
+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                               target:(id)target
                             selector:(SEL)selector AV_DEPRECATED("2.6.10");

+ (nullable instancetype)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                                           password:(NSString *)password AV_DEPRECATED("2.6.10");
+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                      password:(NSString *)password AV_DEPRECATED("2.6.10");
+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                      password:(NSString *)password
                                        target:(id)target
                                      selector:(SEL)selector AV_DEPRECATED("2.6.10");

+ (nullable instancetype)logInWithMobilePhoneNumber:(NSString *)phoneNumber
                                            smsCode:(NSString *)code AV_DEPRECATED("2.6.10");
+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                       smsCode:(NSString *)code AV_DEPRECATED("2.6.10");
+ (void)logInWithMobilePhoneNumberInBackground:(NSString *)phoneNumber
                                       smsCode:(NSString *)code
                                        target:(id)target
                                      selector:(SEL)selector AV_DEPRECATED("2.6.10");

/*!
 Send a password reset request for a specified email. If a user account exists with that email,
 an email will be sent to that address with instructions on how to reset their password.
 @param email Email of the account to send a reset password request.
 @return true if the reset email request is successful. False if no account was found for the email address.
 */
+ (BOOL)requestPasswordResetForEmail:(NSString *)email AV_DEPRECATED("2.6.10");

/*!
 Send a password reset request asynchronously for a specified email and sets an
 error object. If a user account exists with that email, an email will be sent to
 that address with instructions on how to reset their password.
 @param email Email of the account to send a reset password request.
 */
+ (void)requestPasswordResetForEmailInBackground:(NSString *)email AV_DEPRECATED("2.6.10");

/*!
 Send a password reset request asynchronously for a specified email and sets an error object.
 If a user account exists with that email, an email will be sent to that address with instructions
 on how to reset their password.
 @param email Email of the account to send a reset password request.
 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchronous request is complete. It should have the following signature: (void)callbackWithResult:(NSNumber *)result error:(NSError **)error. error will be nil on success and set if there was an error. [result boolValue] will tell you whether the call succeeded or not.
 */
+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
                                          target:(id)target
                                        selector:(SEL)selector AV_DEPRECATED("2.6.10");

/*!
 Whether the user is an authenticated object for the device. An authenticated AVUser is one that is obtained via
 a signUp or logIn method. An authenticated object is required in order to save (with altered values) or delete it.
 @return whether the user is authenticated.
 */
- (BOOL)isAuthenticated AV_DEPRECATED("Deprecated in AVOSCloud SDK 3.7.0. Use -[AVUser isAuthenticatedWithSessionToken:callback:] instead.");

@end

NS_ASSUME_NONNULL_END
