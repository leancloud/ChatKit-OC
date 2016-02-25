//
//  LCIMChatViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMChatViewController.h"
#import <AVOSCloud/AVOSCloud.h>
#import "LCIMUserModelDelegate.h"

@implementation LCIMChatViewController

#pragma mark -
#pragma mark - initialization Method

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _conversationId = conversationId;
    return self;
}

- (instancetype)initWithMemberId:(NSString *)memberId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _memberId = memberId;
    return self;
}

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    //TODO: query chat history i.e.

    //TODO:
    /*!
     * 这里要说明的有几点：
     1. conversationId／memberId 是二选一使用的（这是最普通的情况）；
     2. 万一用户把 conversationId／memberId 都填了，会怎样？
     3. 万一用户只填了 memberId，但是 memberId 是 currentUserId，会怎样？
     4. 万一用户只填了 conversationId，但是对应的 conversation 不存在，会怎样？
     */
}

@end
