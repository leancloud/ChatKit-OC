//
//  AVIMTypedMessageRedPacket.h
//  ChatKit-OC
//
//  Created by 都基鹏 on 16/8/16.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVOSCloudIM/AVIMTypedMessage.h>
#import "AVIMTypedMessage+LCCKExtension.h"
#import "LCCKConstants.h"
#import "RedpacketMessageModel.h"

@interface AVIMTypedMessageRedPacket : AVIMTypedMessage<AVIMTypedMessageSubclassing>

/**
 *  红包相关数据模型
 */
@property (nonatomic,strong)RedpacketMessageModel * rpModel;

@end
