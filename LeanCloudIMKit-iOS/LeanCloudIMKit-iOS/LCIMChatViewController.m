//
//  LCIMChatViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMChatViewController.h"
#import "LCIMChatService.h"
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
}

@end
