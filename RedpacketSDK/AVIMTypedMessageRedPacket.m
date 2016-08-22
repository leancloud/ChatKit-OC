//
//  AVIMTypedMessageRedPacket.m
//  ChatKit-OC
//
//  Created by 都基鹏 on 16/8/16.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "AVIMTypedMessageRedPacket.h"


@implementation AVIMTypedMessageRedPacket
+ (AVIMMessageMediaType)classMediaType;{
    return 3;
}
- (instancetype)initWithClientId:(NSString *)clientId ConversationType:(LCCKConversationType)conversationType{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self lcck_setObject:@"名片" forKey:LCCKCustomMessageTypeTitleKey];
    [self lcck_setObject:@"这是一条名片消息，当前版本过低无法显示，请尝试升级APP查看" forKey:LCCKCustomMessageDegradeKey];
    [self lcck_setObject:@"有人向您发送了一条名片消息，请打开APP查看" forKey:LCCKCustomMessageSummaryKey];
    [self lcck_setObject:@(conversationType) forKey:LCCKCustomMessageConversationTypeKey];
    [self lcck_setObject:clientId forKey:@"clientId"];
    return self;
}
@end
