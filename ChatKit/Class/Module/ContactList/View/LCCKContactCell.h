//
//  LCCKContactCell.h
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCCKContactListViewController.h"

@interface LCCKContactCell : UITableViewCell

- (void)configureWithAvatarURL:(NSURL *)avatarURL title:(NSString *)title subtitle:(NSString *)subtitle model:(LCCKContactListMode)model;

@property (nonatomic, assign, getter=isChecked) BOOL checked;

@property (nonatomic, copy) NSString *identifier;

@end
