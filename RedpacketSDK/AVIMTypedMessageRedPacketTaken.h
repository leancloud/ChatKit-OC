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
// 按照 Android 方面的格式修改消息格式
@interface AVIMTypedMessageRedPacketTaken : AVIMTypedMessage<AVIMTypedMessageSubclassing>
- (instancetype)initWithClientId:(NSString *)clientId ConversationType:(LCCKConversationType)conversationType receiveMembers:(NSArray<NSString*>*)members;
@property (nonatomic,strong)RedpacketMessageModel * rpModel;
@end
