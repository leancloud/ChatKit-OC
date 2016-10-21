//
//  LCCKVCardMessage.m
//  ChatKit-OC
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/8/10.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKVCardMessage.h"

@implementation LCCKVCardMessage

#pragma mark -
#pragma mark - initialize Method

/*!
 * 有几个必须添加的字段：
 *  - degrade 用来定义如何展示老版本未支持的自定义消息类型
 *  - typeTitle 最近对话列表中最近一条消息的title，比如：最近一条消息是图片，可设置该字段内容为：`@"图片"`，相应会展示：`[图片]`。
 *  - summary 会显示在 push 提示中
 *  - conversationType 用来展示在推送提示中，以达到这样的效果： [群消息]Tom：hello gays!
 * @attention 务必添加这几个字段，ChatKit 内部会使用到。
 */
- (instancetype)initWithClientId:(NSString *)clientId  conversationType:(LCCKConversationType)conversationType {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self lcck_setObject:@"名片" forKey:LCCKCustomMessageTypeTitleKey];
    [self lcck_setObject:@"这是一条名片消息，当前版本过低无法显示，请尝试升级APP查看" forKey:LCCKCustomMessageDegradeKey];
    [self lcck_setObject:@"有人向您发送了一条名片消息，请打开APP查看" forKey:LCCKCustomMessageSummaryKey];
    [self lcck_setObject:@(conversationType) forKey:LCCKCustomMessageConversationTypeKey];
    [self lcck_setObject:clientId forKey:@"clientId"];
    //定向群消息，仅部分用户可见，需要实现 `-setFilterMessagesBlock:`, 详情见 LCChatKitExample 中的演示
//    [self lcck_setObject:@[ @"Tom", @"Jerry"] forKey:LCCKCustomMessageOnlyVisiableForPartClientIds];
    return self;
}

+ (instancetype)vCardMessageWithClientId:(NSString *)clientId  conversationType:(LCCKConversationType)conversationType {
    return [[self alloc] initWithClientId:clientId conversationType:conversationType];
}

#pragma mark -
#pragma mark - Override Methods

#pragma mark -
#pragma mark - AVIMTypedMessageSubclassing Method

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeVCard;
}

@end
