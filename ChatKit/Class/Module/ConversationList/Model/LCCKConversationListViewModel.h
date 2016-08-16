//
//  LCCKConversationListViewModel.h
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
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
