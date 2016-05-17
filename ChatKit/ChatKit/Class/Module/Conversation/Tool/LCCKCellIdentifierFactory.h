//
//  UITableViewCell+LCCKCellIdentifier.h
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudChatKit-iOS ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

@import UIKit;
@import Foundation;
#import "LCCKChatMessageCell.h"

@interface LCCKCellIdentifierFactory : NSObject

/**
 *  用来获取cellIdentifier
 */
+ (NSString *)cellIdentifierForMessageConfiguration:(LCCKMessage *)message;

@end
