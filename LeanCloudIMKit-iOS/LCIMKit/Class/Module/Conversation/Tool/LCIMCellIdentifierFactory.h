//
//  UITableViewCell+LCIMCellIdentifier.h
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

@import UIKit;
@import Foundation;
#import "LCIMChatMessageCell.h"

@interface LCIMCellIdentifierFactory : NSObject

/**
 *  用来获取cellIdentifier
 */
+ (NSString *)cellIdentifierForMessageConfiguration:(LCIMMessage *)message;

@end
