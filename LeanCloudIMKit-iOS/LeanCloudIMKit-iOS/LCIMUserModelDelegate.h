
//
//  LCIMUserModelDelegate.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@protocol LCIMUserModelDelegate <NSObject>

@required

/*!
 * @brief the user's id
 */
@property (nonatomic, copy) NSString *userId;

/*!
 * @brief the user's avatar image
 */
@property (nonatomic, strong) UIImage *avatar;

/*!
 * @brief string of the user's avatar URL
 * @attention its type is NSString, not NSURL
 */
@property (nonatomic, copy) NSString *avatarURL;

@end
