//
//  LCCKConversationListViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.7.3 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCCKBaseTableViewController.h"

/**
 *  对话列表 Cell 的默认高度
 */
FOUNDATION_EXTERN const CGFloat LCCKConversationListCellDefaultHeight;

@interface LCCKConversationListViewController : LCCKBaseTableViewController

/*!
 * 禁止预览id
 * 如果不设置，或者设置为NO，在群聊需要显示最后一条消息的发送者时，会在网络请求用户昵称成功前，先显示id，然后，成功后再显示昵称。
 */
@property (nonatomic, assign, getter=isDisablePreviewUserId) BOOL disablePreviewUserId;

- (void)refresh;

@end

