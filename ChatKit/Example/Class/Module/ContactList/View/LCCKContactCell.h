//
//  LCCKContactCell.h
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LCCKContactCell : UITableViewCell

- (void)configureWithAvatorURL:(NSURL *)avatorURL title:(NSString *)title subtitle:(NSString *)subtitle;

@property (nonatomic, copy) NSString *identifier;

@end
