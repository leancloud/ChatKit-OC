//
//  LCIMUserSystemService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for User-System.

#import <Foundation/Foundation.h>
#import "LCIMServiceDefinition.h"

/**
 *  You must implement `-setFetchProfilesBlock:` to allow LeanCloudIMKit to get user information by user id.
 *   The following example shows how to use AVUser as the user system:

 ```
    [[LCIMKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback) {
        NSMutableArray<id<LCIMUserModelDelegate>> *userList = [NSMutableArray array];
        for (NSString *userId in userIds) {
            //MyUser is a subclass of AVUser, conforming to the LCIMUserModelDelegate protocol.
            AVQuery *query = [LCIMUser query];
            NSError *error = nil;
            LCIMUser *object = (LCIMUser *)[query getObjectWithId:userId error:&error];
            if (error == nil) {
                [userList addObject:object];
            } else {
                if (callback) {
                    callback(nil, error);
                    return;
                }
            }
        }
        if (callback) {
            callback(userList, nil);
        }
    }
     ];

  ```
 
*/

@interface LCIMUserSystemService : NSObject <LCIMUserSystemService>

@end
