//
//  LCCKContactCell.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/9.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCCKContactListViewController.h"

@interface LCCKContactCell : UITableViewCell

- (void)configureWithAvatarURL:(NSURL *)avatarURL title:(NSString *)title subtitle:(NSString *)subtitle model:(LCCKContactListMode)model;

@property (nonatomic, assign, getter=isChecked) BOOL checked;

@property (nonatomic, copy) NSString *identifier;

@end
