//
//  LCIMConversationViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMConversationViewController.h"
#import <AVOSCloud/AVOSCloud.h>
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMUserModelDelegate.h"
#import "LCIMUtil.h"
#import "LCIMKit.h"

@interface LCIMConversationViewController ()
@end

@implementation LCIMConversationViewController

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

- (instancetype)initWithPeerId:(NSString *)peerId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _peerId = peerId;
    return self;
}

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    !self.viewDidLoadBlock ?: self.viewDidLoadBlock();
    //TODO: query chat history i.e.

    //TODO:
    /*!
     * 这里要说明的有几点：
     1. conversationId／PeerId 是二选一使用的（这是最普通的情况）；
     2. 万一用户把 conversationId／peerId 都填了，会怎样？
     3. 万一用户只填了 peerId，但是 peerId 是 currentUserId，会怎样？
     4. 万一用户只填了 conversationId，但是对应的 conversation 不存在，会怎样？
     */
}

@end
