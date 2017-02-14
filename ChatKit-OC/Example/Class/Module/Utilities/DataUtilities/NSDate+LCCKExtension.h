//
//  LCCKContactListViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDate+Extension.h"
#import "NSDate+Utilities.h"

@interface NSDate (LCCKExtension)

- (NSString *)lcck_chatTimeInfo;

- (NSString *)lcck_conversaionTimeInfo;

- (NSString *)lcck_chatFileTimeInfo;

@end
