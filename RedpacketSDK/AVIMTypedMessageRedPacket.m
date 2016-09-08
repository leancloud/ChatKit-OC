//
//  AVIMTypedMessageRedPacket.m
//  ChatKit-OC
//
//  Created by 都基鹏 on 16/8/16.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "AVIMTypedMessageRedPacket.h"


@implementation AVIMTypedMessageRedPacket
+ (void)load{
    [self registerSubclass];
}
+ (AVIMMessageMediaType)classMediaType{
    return 3;
}
- (instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    [self setText:@"红包"];
    [self lcck_setObject:@"红包" forKey:LCCKCustomMessageTypeTitleKey];
    [self lcck_setObject:@"这是一条红包消息，当前版本过低无法显示，请尝试升级APP查看" forKey:LCCKCustomMessageDegradeKey];
    [self lcck_setObject:@"有人向您发送了一条红包消息，请打开APP查看" forKey:LCCKCustomMessageSummaryKey];
    return self;
}

@end
