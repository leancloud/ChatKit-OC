//
//  LCIMConversatonListViewModel.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

@import UIKit;
@import Foundation;
@class LCIMConversationListViewController;
@class AVIMConversation;

@interface LCIMConversatonListViewModel : NSObject <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithConversationListViewController:(LCIMConversationListViewController *)conversationListViewController;

@property (nonatomic, strong) NSMutableArray<AVIMConversation *> *dataArray;

- (void)refresh;

@end
