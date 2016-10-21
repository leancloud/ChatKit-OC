//
//  LCCKConversationListViewModel.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import UIKit;
@import Foundation;
@class LCCKConversationListViewController;
@class AVIMConversation;

@interface LCCKConversationListViewModel : NSObject <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithConversationListViewController:(LCCKConversationListViewController *)conversationListViewController;

@property (nonatomic, strong) NSMutableArray<AVIMConversation *> *dataArray;

- (void)refresh;

@end
