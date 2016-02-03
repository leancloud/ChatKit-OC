
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
 * @brief the user's id
 */
@property (nonatomic, copy) NSString *userId;

/*!
 * @brief the user's name
 */
@property (nonatomic, copy) NSString *name;

/*!
 * @brief string of the user's avatar URL
 * @attention its type is NSString, not NSURL
 */
@property (nonatomic, copy) NSString *avatarURL;

@end
