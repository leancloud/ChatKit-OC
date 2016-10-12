//
//  LCCKInputViewPluginTest.m
//  ChatKit-OC
//
//  Created by 都基鹏 on 16/8/16.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "RedPacketInputViewPlugin.h"
#import "RedpacketViewControl.h"
#import "CYLTabBarController.h"
#import "RedpacketConfig.h"
#import "AVIMTypedMessageRedPacket.h"
#import "LCCKContactManager.h"

@interface RedPacketInputViewPlugin()<RedpacketViewControlDelegate>

/**
 *  发红包的控制器
 */
@property (nonatomic, strong) RedpacketViewControl *redpacketControl;

@end

@implementation RedPacketInputViewPlugin
@synthesize inputViewRef = _inputViewRef;
@synthesize sendCustomMessageHandler = _sendCustomMessageHandler;

+ (void)load {
    [self registerSubclass];
}

+ (LCCKInputViewPluginType)classPluginType {
    return 3;
}

#pragma mark -
#pragma mark - LCCKInputViewPluginDelegate Method

/*!
 * 插件图标
 */
- (UIImage *)pluginIconImage {
    return [self imageInBundlePathForImageName:@"redpacket_redpacket"];
}

/*!
 * 插件名称
 */
- (NSString *)pluginTitle {
    return @"红包";
}

/*!
 * 插件对应的 view，会被加载到 inputView 上
 */
- (UIView *)pluginContentView {
    return nil;
}

- (void)pluginDidClicked {
     self.redpacketControl.conversationController = self.conversationViewController;
     AVIMConversation *conversation = [self.conversationViewController getConversationIfExists];
     RedpacketUserInfo * userInfo = [RedpacketUserInfo new];
     RPSendRedPacketViewControllerType rptype;
     if (conversation) {
         if (conversation.members.count > 2) {
             userInfo.userId = self.conversationViewController.conversationId;
             rptype = RPSendRedPacketViewControllerMember;
         } else {
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

- (RedpacketViewControl *)redpacketControl {
    if (_redpacketControl) return _redpacketControl;
    
    _redpacketControl = [RedpacketViewControl new];
    _redpacketControl.delegate = self;
    
    // 设置红包 SDK 功能回调
    [_redpacketControl setRedpacketGrabBlock:nil andRedpacketBlock:^(RedpacketMessageModel *redpacket) {
        // 用户发红包的通知
        // SDK 默认的消息需要改变
        redpacket.redpacket.redpacketOrgName = @"LeacCloud红包";
        [self sendRedpacketMessage:redpacket];
        _redpacketControl = nil;
    }];
    return _redpacketControl;
}

// 发送红包消息
- (void)sendRedpacketMessage:(RedpacketMessageModel *)redpacket {
    AVIMTypedMessageRedPacket * message = [[AVIMTypedMessageRedPacket alloc]init];
    message.rpModel = redpacket;
    [self.conversationViewController sendCustomMessage:message];
}

- (void)getGroupMemberListCompletionHandle:(void (^)(NSArray<RedpacketUserInfo *> *))completionHandle {
    __weak typeof(self) weakSlef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVIMConversation *conversation = [self.conversationViewController getConversationIfExists];
        NSArray *allPersonIds;
        NSMutableArray * usersArray = [NSMutableArray array];
        if (conversation.lcck_type == LCCKConversationTypeGroup) {
            allPersonIds = conversation.members;
        } else {
            allPersonIds = [[LCCKContactManager defaultManager] fetchContactPeerIds];
        }
        NSError * error;
        NSArray<id<LCCKUserDelegate>> *users = [[LCChatKit sharedInstance] getCachedProfilesIfExists:allPersonIds shouldSameCount:YES error:&error];
        if (users.count && !error) {
            [users enumerateObjectsUsingBlock:^(id<LCCKUserDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                RedpacketUserInfo * userInfo = [RedpacketUserInfo new];
                userInfo.userId = obj.clientId;
                userInfo.userNickname = obj.name?obj.name:obj.clientId;
                userInfo.userAvatar = obj.avatarURL.absoluteString;
                [usersArray addObject:userInfo];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandle(usersArray);
            });
        }
    });
}
#pragma mark -
#pragma mark - Private Methods

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"RedpacketCellResource" bundleForClass:[self class]];
    return image;
}

@end
