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
@property (nonatomic, strong)NSMutableArray * usersArray;
@property (nonatomic, strong)id<LCCKUserDelegate> user;
@end

@implementation RedpacketDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.usersArray = [NSMutableArray array];
    
    __weak typeof(self) weakSelf = self;
    [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> user, NSError *error) {
        weakSelf.user = user;
    }];
    
    self.redpacketControl = [[RedpacketViewControl alloc] init];
    self.redpacketControl.delegate = self;
    self.redpacketControl.conversationController = self;

    self.redpacketControl.converstationInfo = [RedpacketConfig sharedConfig].redpacketUserInfo;
    
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
    if (self.peerId) {
        [self.redpacketControl presentRedPacketViewController];
    }else if(self.conversationId){
        [self.redpacketControl presentRedPacketMoreViewControllerWithGroupMembers:@[]];
    }
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
        [self.redpacketControl redpacketCellTouchedWithMessageModel:[RedpacketMessageModel redpacketMessageModelWithDic:message.attributes]];
        
    }else{
        [super messageCellTappedMessage:messageCell];
    }
    
}

// 发送融云红包消息
- (void)sendRedpacketMessage:(RedpacketMessageModel *)redpacket
{
    AVIMTypedMessageRedPacket * message = [[AVIMTypedMessageRedPacket alloc]initWithClientId:self.clientId ConversationType:LCCKConversationTypeSingle];
    [self.chatViewModel sendCustomMessage:message];
}

// 红包被抢消息处理
- (void)onRedpacketTakenMessage:(RedpacketMessageModel *)redpacket
{

    if ([redpacket.currentUser.userId isEqualToString:redpacket.redpacketSender.userId]) {//如果发送者是自己
        [self.chatViewModel sendLocalFeedbackTextMessge:@"您给自己发了一个红包"];
    }
    else {
        if (NO == self.redpacketControl.converstationInfo.isGroup) {//如果不是群红包
            NSString * receiveString = [NSString stringWithFormat:@"%@抢了你的红包",redpacket.currentUser.userNickname];
            AVIMTypedMessageRedPacketTaken * message = [AVIMTypedMessageRedPacketTaken messageWithText:receiveString file:nil attributes:redpacket.redpacketMessageModelToDic ];
            [self.chatViewModel sendCustomMessage:message];
            
        }else {
            AVIMTypedMessageRedPacketTaken * message = [[AVIMTypedMessageRedPacketTaken alloc]initWithClientId:self.clientId ConversationType:LCCKConversationTypeSingle receiveMembers:@[redpacket.redpacketSender.userId]];
            [self.chatViewModel sendCustomMessage:message];
        }
    }
}

- (NSArray *)groupMemberList{

    return self.usersArray;
}
@end
