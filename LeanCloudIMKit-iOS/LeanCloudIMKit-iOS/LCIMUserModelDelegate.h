
//
//  LCIMUserModelDelegate.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import UIKit;

@protocol LCIMUserModelDelegate <NSObject>

@required

/*!
 * @brief The user's id
 */
@property (nonatomic, copy) NSString *userId;

/*!
 * @brief The user's name
 */
@property (nonatomic, copy) NSString *name;

/*!
 * @brief String of the user's avatar URL
 * @attention Its type is NSString, not NSURL
 */
@property (nonatomic, copy) NSString *avatarURL;

@end
