//
//  AVAnonymousUtils.h
//  AVOSCloud
//
//

#import <Foundation/Foundation.h>
#import "AVUser.h"
#import "AVConstants.h"
#import "AVAnonymousUtils.h"
#import "AVUtils.h"
#import "AVObjectUtils.h"
#import "AVPaasClient.h"
#import "AVUser.h"
#import "AVUser_Internal.h"

@implementation AVAnonymousUtils

+(NSDictionary *)anonymousAuthData
{
    NSString *anonymousId = [[NSUserDefaults standardUserDefaults] objectForKey:AnonymousIdKey];
    if (!anonymousId) {
        anonymousId = [AVUtils generateCompactUUID];
        [[NSUserDefaults standardUserDefaults] setObject:anonymousId forKey:AnonymousIdKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSDictionary * data = @{authDataTag: @{@"anonymous": @{@"id": anonymousId}}};
    return data;
}

+ (void)logInWithBlock:(AVUserResultBlock)block
{
    NSDictionary * parameters = [AVAnonymousUtils anonymousAuthData];
    [[AVPaasClient sharedInstance] postObject:@"users" withParameters:parameters block:^(id object, NSError *error) {
        AVUser * user = nil;
        if (error == nil)
        {
            if (![object objectForKey:@"authData"]) {
                object = [NSMutableDictionary dictionaryWithDictionary:object];
                [object addEntriesFromDictionary:parameters];
            }
            user = [AVUser userOrSubclassUser];
            [AVObjectUtils copyDictionary:object toObject:user];
            [AVUser changeCurrentUser:user save:YES];
        }
        [AVUtils callUserResultBlock:block user:user error:error];
    }];
}

+ (void)logInWithTarget:(id)target selector:(SEL)selector
{
    [AVAnonymousUtils logInWithBlock:^(AVUser *user, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:user object:error];
    }];
}

+ (BOOL)isLinkedWithUser:(AVUser *)user
{
    if ([[user linkedServiceNames] containsObject:@"anonymous"])
    {
        return YES;
    }
    return NO;
}

@end
