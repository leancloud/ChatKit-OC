//
//  LCIMChatUntiles.h
//  LCIMChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/16.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#ifndef LCIMChatUntiles_h
#define LCIMChatUntiles_h

#define LCIMMessageCellLimit ([UIApplication sharedApplication].keyWindow.frame.size.width/5*3)
/**
 *  消息拥有者类型
 */
typedef NS_ENUM(NSUInteger, LCIMMessageOwner){
    LCIMMessageOwnerUnknown = 0 /**< 未知的消息拥有者 */,
    LCIMMessageOwnerSystem /**< 系统消息 */,
    LCIMMessageOwnerSelf /**< 自己发送的消息 */,
    LCIMMessageOwnerOther /**< 接收到的他人消息 */,
};

/**
 *  消息类型
 */
typedef NS_ENUM(NSUInteger, LCIMMessageType){
    LCIMMessageTypeUnknow = 0 /**< 未知的消息类型 */,
    LCIMMessageTypeSystem = 1 /**< 系统消息 */,
    LCIMMessageTypeText = 2 /**< 文本消息 */,
    LCIMMessageTypeImage = 3 /**< 图片消息 */,
    LCIMMessageTypeVoice = 4 /**< 语音消息 */,
    LCIMMessageTypeLocation = 5 /**< 地理位置消息 */,
    LCIMMessageTypeEmotion = 6 /**< GIF表情消息 */,
    LCIMMessageTypeVideo = 7 /**< 视频文件消息 */,
};

/**
 *  消息发送状态,自己发送的消息时有
 */
typedef NS_ENUM(NSUInteger, LCIMMessageSendState){
    LCIMMessageSendStateSending = 0, /**< 消息发送中 */
    LCIMMessageSendStateSuccess = 1 /**< 消息发送成功 */,
    LCIMMessageSendStateReceived = 2/**< 消息对方已接收*/,
     LCIMMessageSendStateFailed = 3 /**< 消息发送失败 */,
};

/**
 *  消息读取状态,接收的消息时有
 */
typedef NS_ENUM(NSUInteger, LCIMMessageReadState) {
    LCIMMessageUnRead = 0 /**< 消息未读 */,
    LCIMMessageReading /**< 正在接收 */,
    LCIMMessageReaded /**< 消息已读 */,
};

/**
 *  录音消息的状态
 */
typedef NS_ENUM(NSUInteger, LCIMVoiceMessageState){
    LCIMVoiceMessageStateNormal,/**< 未播放状态 */
    LCIMVoiceMessageStateDownloading,/**< 正在下载中 */
    LCIMVoiceMessageStatePlaying,/**< 正在播放 */
    LCIMVoiceMessageStateCancel,/**< 播放被取消 */
};


/**
 *  LCIMChatMessageCell menu对应action类型
 */
typedef NS_ENUM(NSUInteger, LCIMChatMessageCellMenuActionType) {
    LCIMChatMessageCellMenuActionTypeCopy, /**< 复制 */
    LCIMChatMessageCellMenuActionTypeRelay, /**< 转发 */
};


#pragma mark - LCIMMessage 相关key值定义

/**
 *  消息类型的key
 */
static NSString *const kLCIMMessageConfigurationTypeKey = @"com.LeanCloud.kLCIMMessageConfigurationTypeKey";

/**
 *  消息拥有者的key
 */
static NSString *const kLCIMMessageConfigurationOwnerKey = @"com.LeanCloud.kLCIMMessageConfigurationOwnerKey";

/**
 *  消息群组类型的key
 */
static NSString *const kLCIMMessageConfigurationGroupKey = @"com.LeanCloud.kLCIMMessageConfigurationGroupKey";

/**
 *  消息昵称类型的key
 */
static NSString *const kLCIMMessageConfigurationNicknameKey = @"com.LeanCloud.kLCIMMessageConfigurationNicknameKey";

/**
 *  消息头像类型的key
 */
static NSString *const kLCIMMessageConfigurationAvatorKey = @"com.LeanCloud.kLCIMMessageConfigurationAvatorKey";

/**
 *  消息阅读状态类型的key
 */
static NSString *const kLCIMMessageConfigurationReadStateKey = @"com.LeanCloud.kLCIMMessageConfigurationReadStateKey";

/**
 *  消息发送状态类型的key
 */
static NSString *const kLCIMMessageConfigurationSendStateKey = @"com.LeanCloud.kLCIMMessageConfigurationSendStateKey";

/**
 *  文本消息内容的key
 */
static NSString *const kLCIMMessageConfigurationTextKey = @"com.LeanCloud.kLCIMMessageConfigurationTextKey";
/**
 *  图片消息内容的key
 */
static NSString *const kLCIMMessageConfigurationImageKey = @"com.LeanCloud.kLCIMMessageConfigurationImageKey";
/**
 *  语音消息内容的key
 */
static NSString *const kLCIMMessageConfigurationVoiceKey = @"com.LeanCloud.kLCIMMessageConfigurationVoiceKey";

/**
 *  语音消息时长key
 */
static NSString *const kLCIMMessageConfigurationVoiceSecondsKey = @"com.LeanCloud.kLCIMMessageConfigurationVoiceSecondsKey";

/**
 *  地理位置消息内容的key
 */
static NSString *const kLCIMMessageConfigurationLocationKey = @"com.LeanCloud.kLCIMMessageConfigurationLocationKey";

#endif /* LCIMChatUntiles_h */
