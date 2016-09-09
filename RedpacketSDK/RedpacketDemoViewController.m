//
//  RedpacketDemoViewController.m
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-22.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketDemoViewController.h"
#import <ChatKit/LCChatKit.h>

#pragma mark - 红包相关头文件
#import "RedpacketViewControl.h"
#import "YZHRedpacketBridge.h"
#import "LCCKChatBar.h"
#import "RedpacketConfig.h"
#import "AVIMTypedMessageRedPacket.h"
#import "AVIMTypedMessageRedPacketTaken.h"
#import "RedpacketConfig.h"
#pragma mark -
#pragma mark - 红包相关的宏定义
#define REDPACKET_BUNDLE(name) @"RedpacketCellResource.bundle/" name
#define REDPACKET_TAG 2016
#pragma mark -

@interface RedpacketDemoViewController ()<RedpacketViewControlDelegate,LCCKConversationViewModelDelegate>
@property (nonatomic, strong)LCCKConversationViewModel * chatViewModel;
@property (nonatomic, strong) RedpacketViewControl *redpacketControl;
@property (nonatomic, strong)id<LCCKUserDelegate> user;
@end

@implementation RedpacketDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> user, NSError *error) {
        weakSelf.user = user;
    }];
    
    self.redpacketControl = [[RedpacketViewControl alloc] init];
    self.redpacketControl.delegate = self;
    self.redpacketControl.conversationController = self;

    // 设置红包 SDK 功能回调
    [self.redpacketControl setRedpacketGrabBlock:^(RedpacketMessageModel *redpacket) {
        // 用户发出的红包收到被抢的通知
        [weakSelf onRedpacketTakenMessage:redpacket];
    } andRedpacketBlock:^(RedpacketMessageModel *redpacket) {
        // 用户发红包的通知
        // SDK 默认的消息需要改变
        redpacket.redpacket.redpacketOrgName = @"LeacCLoud红包";
        [weakSelf sendRedpacketMessage:redpacket];
    }];
    
    // 通知 红包 SDK 刷新 Token
    [[YZHRedpacketBridge sharedBridge] reRequestRedpacketUserToken:^(NSInteger code, NSString *msg) {
        //to do token失效重请求策略
    }];


}
- (void)chatBarWillSendRedPacket{

    AVIMConversation *conversation = [self getConversationIfExists];
    RedpacketUserInfo * userInfo = [RedpacketUserInfo new];
    RPSendRedPacketViewControllerType rptype;
    if (conversation) {
        if (conversation.members.count > 2) {
            userInfo.userId = self.conversationId;
            rptype = RPSendRedPacketViewControllerMember;
        }else{
            rptype = RPSendRedPacketViewControllerSingle;
            [conversation.members enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![[RedpacketConfig sharedConfig].redpacketUserInfo.userId isEqualToString:obj]) {
                    userInfo.userId = obj;
                }
            }];
        }
    }
    self.redpacketControl.converstationInfo = userInfo;
    [self.redpacketControl presentRedPacketViewControllerWithType:rptype memberCount:conversation.members.count];
}

- (NSString*)clientId{
    NSString * clientID = @"";
    clientID = self.peerId?self.peerId:@"";
    clientID = self.conversationId?self.conversationId:@"";
    return clientID;
}
- (LCCKConversationViewModel *)chatViewModel {
    if (_chatViewModel == nil) {
        LCCKConversationViewModel *chatViewModel = [[LCCKConversationViewModel alloc] initWithParentViewController:self];
        chatViewModel.delegate = self;
        _chatViewModel = chatViewModel;
    }
    return _chatViewModel;
}

- (void)messageCellTappedMessage:(LCCKChatMessageCell *)messageCell{
    if ([messageCell.message isKindOfClass:[AVIMTypedMessageRedPacket class]]) {
        AVIMTypedMessageRedPacket * message = (AVIMTypedMessageRedPacket*)messageCell.message;
        [self.redpacketControl redpacketCellTouchedWithMessageModel:message.rpModel];
        
    }else{
        [super messageCellTappedMessage:messageCell];
    }
}

// 发送融云红包消息
- (void)sendRedpacketMessage:(RedpacketMessageModel *)redpacket
{
    AVIMTypedMessageRedPacket * message = [[AVIMTypedMessageRedPacket alloc]init];
    message.rpModel = redpacket;
    [self.chatViewModel sendCustomMessage:message];
}

// 红包被抢消息处理
- (void)onRedpacketTakenMessage:(RedpacketMessageModel *)redpacket
{

    if ([redpacket.currentUser.userId isEqualToString:redpacket.redpacketSender.userId]) {//如果发送者是自己
        [self.chatViewModel sendLocalFeedbackTextMessge:@"您抢了自己的红包"];
    }
    else {
        switch (redpacket.redpacketType) {
            case RedpacketTypeSingle:
            case RedpacketTypeGroup:
            case RedpacketTypeRand:
            case RedpacketTypeAvg:
            case RedpacketTypeRandpri:{
                AVIMTypedMessageRedPacketTaken * message = [[AVIMTypedMessageRedPacketTaken alloc]initWithClientId:self.clientId ConversationType:LCCKConversationTypeSingle receiveMembers:@[redpacket.redpacketSender.userId]];
                message.rpModel = redpacket;
                [self.chatViewModel sendCustomMessage:message];
                break;
            }
            case RedpacketTypeMember: {
                AVIMTypedMessageRedPacketTaken * message = [[AVIMTypedMessageRedPacketTaken alloc]initWithClientId:self.clientId ConversationType:LCCKConversationTypeSingle receiveMembers:@[redpacket.toRedpacketReceiver.userId]];
                message.rpModel = redpacket;
                [self.chatViewModel sendCustomMessage:message];
                break;
            }
            default:{
                
                break;
            }
        }
    }
}

- (void)getGroupMemberListCompletionHandle:(void (^)(NSArray<RedpacketUserInfo *> *))completionHandle{
    
    NSMutableArray * usersArray = [NSMutableArray array];
    AVIMConversation *conversation = [self getConversationIfExists];
    [conversation.members enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RedpacketUserInfo * userInfo = [RedpacketUserInfo new];
        userInfo.userId = obj;
        userInfo.userNickname = obj;
        [usersArray addObject:userInfo];
    }];
    
    completionHandle(usersArray);
}
@end
