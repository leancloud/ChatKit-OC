//
//  LCCKConversationListViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCCKBaseTableViewController.h"

/**
 *  对话列表 Cell 的默认高度
 */
FOUNDATION_EXTERN const CGFloat LCCKConversationListCellDefaultHeight;

@interface LCCKConversationListViewController : LCCKBaseTableViewController

- (void)refresh;

@end

