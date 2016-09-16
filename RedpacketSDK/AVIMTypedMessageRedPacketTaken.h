//
//  RedpacketTakenMessage.h
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-5-3.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import <AVOSCloudIM/AVIMTypedMessage.h>
#import "AVIMTypedMessage+LCCKExtension.h"
#import "LCCKConstants.h"
#import "RedpacketMessageModel.h"

@interface AVIMTypedMessageRedPacketTaken : AVIMTypedMessage<AVIMTypedMessageSubclassing>

/**
 *  红包相关数据模型
 */
@property (nonatomic,strong)RedpacketMessageModel * rpModel;

/**
 *  初始胡抢红包消息
 *
 *  @param clientId         会话ID
 *  @param conversationType 会话类型
 *  @param members          接收人IDs
 */
- (instancetype)initWithClientId:(NSString *)clientId ConversationType:(LCCKConversationType)conversationType receiveMembers:(NSArray<NSString*>*)members;

@end
