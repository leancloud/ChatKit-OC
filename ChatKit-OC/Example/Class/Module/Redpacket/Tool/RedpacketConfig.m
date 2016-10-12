//
//  RedpacketConfig.m
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-25.
//  Copyright © 2016年 云帐户. All rights reserved.
//
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
#import <UIKit/UIKit.h>
#import "LCCKExampleConstants.h"
#import "RedpacketConfig.h"
#import "YZHRedpacketBridge.h"
#import "RedpacketMessageModel.h"
#import "AppDelegate+RedPacket.h"
#import "AVIMTypedMessageRedPacketTaken.h"
//	*此为演示地址* App需要修改为自己AppServer上的地址, 数据格式参考此地址给出的格式。
static NSString *requestUrl = @"https://rpv2.yunzhanghu.com/api/sign?duid=";

@interface RedpacketConfig ()

@end

@implementation RedpacketConfig

+ (instancetype)sharedConfig {
    static RedpacketConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[RedpacketConfig alloc] init];
        [[YZHRedpacketBridge sharedBridge] setDataSource:config];
    });
    return config;
}

+ (void)config {
    [[self sharedConfig] config];
}

- (void)configWithSignDict:(NSDictionary *)dict {
    NSString *partner = [dict valueForKey:@"partner"];
    NSString *appUserId = [dict valueForKey:@"user_id"];
    unsigned long timeStamp = [[dict valueForKey:@"timestamp"] unsignedLongValue];
    NSString *sign = [dict valueForKey:@"sign"];
    
    
    [[YZHRedpacketBridge sharedBridge] configWithSign:sign
                                              partner:partner
                                            appUserId:appUserId
                                            timestamp:[NSString stringWithFormat:@"%@",@(timeStamp)]];
}

- (void)config {
    [AppDelegate swizzleRedPacketMethod];
    [[YZHRedpacketBridge sharedBridge] setRedacketURLScheme:@"redpacket.chatkit"];
    
    NSString *userId = self.redpacketUserInfo.userId;
    if(userId && [[YZHRedpacketBridge sharedBridge] isNeedUpdateSignWithUserId:userId]) {

        // 获取应用自己的签名字段。实际应用中需要开发者自行提供相应在的签名计算服务
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@",requestUrl, userId];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        [[[NSURLSession sharedSession]dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!error) {
                NSError * jsonError;
                NSDictionary * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonError];
                if (!jsonError && [jsonObject isKindOfClass:[NSDictionary class]]) {
                    [self configWithSignDict:jsonObject];
                }
            }
        }] resume];
    }
}

- (RedpacketUserInfo *)redpacketUserInfo {
    NSUserDefaults *defaultsGet = [NSUserDefaults standardUserDefaults];
    NSString *clientId = [defaultsGet stringForKey:LCCK_KEY_USERID];
    NSString *avatarURL;
    NSString * userName;
    for (NSDictionary *user in LCCKContactProfiles) {
        if ([clientId isEqualToString:user[LCCKProfileKeyPeerId]]) {
            avatarURL = user[LCCKProfileKeyAvatarURL];
            userName = user[LCCKProfileKeyName];
        }
    }
    RedpacketUserInfo *user = [[RedpacketUserInfo alloc] init];
    user.userId = clientId;
    user.userNickname = userName;
    user.userAvatar = avatarURL;
    return user;
}

- (void)lcck_setting {
    [self config];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LCCKFilterMessagesBlock filterMessagesBlock = [LCCKConversationService sharedInstance].filterMessagesBlock;
        [[LCChatKit sharedInstance] setFilterMessagesBlock:^(AVIMConversation *conversation, NSArray<AVIMTypedMessage *> *messages, LCCKFilterMessagesCompletionHandler completionHandler) {
            NSMutableArray * messageArray = [messages mutableCopy];
            [messages enumerateObjectsUsingBlock:^(AVIMTypedMessage *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if ([obj isKindOfClass:[AVIMTypedMessageRedPacketTaken class]]) {
                    RedpacketMessageModel * rpModel = [RedpacketMessageModel redpacketMessageModelWithDic:obj.attributes];
                    if (![rpModel.redpacketSender.userId isEqualToString:self.redpacketUserInfo.userId] &&
                        ![rpModel.redpacketReceiver.userId isEqualToString:self.redpacketUserInfo.userId] )
                    {
                        [messageArray removeObject:obj];
                    }
                }
            }];
            
            if (filterMessagesBlock) {
                filterMessagesBlock(conversation,messageArray,completionHandler);
            } else {
                completionHandler([messageArray copy], nil);
            }
        }];
    });
}

@end
