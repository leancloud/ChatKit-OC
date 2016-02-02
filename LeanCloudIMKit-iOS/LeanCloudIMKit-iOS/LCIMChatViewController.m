//
//  LCIMChatViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMChatViewController.h"
#import "LCIMChatManager.h"

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

+ (instancetype)chatWithConversationId:(NSString *)conversationId {
    LCIMChatViewController *chatViewController = [[LCIMChatViewController alloc] init];
    chatViewController = [chatViewController initWithConversationId:conversationId];
    return chatViewController;
}

- (instancetype)initWithMemberId:(NSString *)memberId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _memberId = memberId;
    return self;
}

+ (instancetype)chatWithMemberId:(NSString *)memberId {
    LCIMChatViewController *chatViewController = [[LCIMChatViewController alloc] init];
    chatViewController = [chatViewController initWithMemberId:memberId];
    return chatViewController;
}

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
