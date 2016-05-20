//
//  LCCKChatUntiles.h
//  LCCKChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/16.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#ifndef LCCKChatUntiles_h
#define LCCKChatUntiles_h

#define LCCKMessageCellLimit ([UIApplication sharedApplication].keyWindow.frame.size.width/5*3)
/**
 *  消息拥有者类型
 */
typedef NS_ENUM(NSUInteger, LCCKMessageOwner){
    LCCKMessageOwnerUnknown = 0 /**< 未知的消息拥有者 */,
    LCCKMessageOwnerSystem /**< 系统消息 */,
    LCCKMessageOwnerSelf /**< 自己发送的消息 */,
    LCCKMessageOwnerOther /**< 接收到的他人消息 */,
};

/**
 *  消息类型
 */
typedef NS_ENUM(NSUInteger, LCCKMessageType){
    LCCKMessageTypeUnknow = 0 /**< 未知的消息类型 */,
    LCCKMessageTypeSystem = 1 /**< 系统消息 */,
    LCCKMessageTypeText = 2 /**< 文本消息 */,
    LCCKMessageTypeImage = 3 /**< 图片消息 */,
    LCCKMessageTypeVoice = 4 /**< 语音消息 */,
    LCCKMessageTypeLocation = 5 /**< 地理位置消息 */,
    LCCKMessageTypeEmotion = 6 /**< GIF表情消息 */,
    LCCKMessageTypeVideo = 7 /**< 视频文件消息 */,
};

/**
 *  消息发送状态,自己发送的消息时有
 */
typedef NS_ENUM(NSUInteger, LCCKMessageSendState){
    LCCKMessageSendStateSending = 0, /**< 消息发送中 */
    LCCKMessageSendStateSuccess = 1 /**< 消息发送成功 */,
    LCCKMessageSendStateReceived = 2/**< 消息对方已接收*/,
     LCCKMessageSendStateFailed = 3 /**< 消息发送失败 */,
};

/**
 *  消息读取状态,接收的消息时有
 */
typedef NS_ENUM(NSUInteger, LCCKMessageReadState) {
    LCCKMessageUnRead = 0 /**< 消息未读 */,
    LCCKMessageReading /**< 正在接收 */,
    LCCKMessageReaded /**< 消息已读 */,
};

/**
 *  录音消息的状态
 */
typedef NS_ENUM(NSUInteger, LCCKVoiceMessageState){
    LCCKVoiceMessageStateNormal,/**< 未播放状态 */
    LCCKVoiceMessageStateDownloading,/**< 正在下载中 */
    LCCKVoiceMessageStatePlaying,/**< 正在播放 */
    LCCKVoiceMessageStateCancel,/**< 播放被取消 */
};


/**
 *  LCCKChatMessageCell menu对应action类型
 */
typedef NS_ENUM(NSUInteger, LCCKChatMessageCellMenuActionType) {
    LCCKChatMessageCellMenuActionTypeCopy, /**< 复制 */
    LCCKChatMessageCellMenuActionTypeRelay, /**< 转发 */
};


#pragma mark - LCCKMessage 相关key值定义

/**
 *  消息类型的key
 */
static NSString *const kLCCKMessageConfigurationTypeKey = @"com.LeanCloud.kLCCKMessageConfigurationTypeKey";

/**
 *  消息拥有者的key
 */
static NSString *const kLCCKMessageConfigurationOwnerKey = @"com.LeanCloud.kLCCKMessageConfigurationOwnerKey";

/**
 *  消息群组类型的key
 */
static NSString *const kLCCKMessageConfigurationGroupKey = @"com.LeanCloud.kLCCKMessageConfigurationGroupKey";

/**
 *  消息昵称类型的key
 */
static NSString *const kLCCKMessageConfigurationNicknameKey = @"com.LeanCloud.kLCCKMessageConfigurationNicknameKey";

/**
 *  消息头像类型的key
 */
static NSString *const kLCCKMessageConfigurationAvatorKey = @"com.LeanCloud.kLCCKMessageConfigurationAvatorKey";

/**
 *  消息阅读状态类型的key
 */
static NSString *const kLCCKMessageConfigurationReadStateKey = @"com.LeanCloud.kLCCKMessageConfigurationReadStateKey";

/**
 *  消息发送状态类型的key
 */
static NSString *const kLCCKMessageConfigurationSendStateKey = @"com.LeanCloud.kLCCKMessageConfigurationSendStateKey";

/**
 *  文本消息内容的key
 */
static NSString *const kLCCKMessageConfigurationTextKey = @"com.LeanCloud.kLCCKMessageConfigurationTextKey";
/**
 *  图片消息内容的key
 */
static NSString *const kLCCKMessageConfigurationImageKey = @"com.LeanCloud.kLCCKMessageConfigurationImageKey";
/**
 *  语音消息内容的key
 */
static NSString *const kLCCKMessageConfigurationVoiceKey = @"com.LeanCloud.kLCCKMessageConfigurationVoiceKey";

/**
 *  语音消息时长key
 */
static NSString *const kLCCKMessageConfigurationVoiceSecondsKey = @"com.LeanCloud.kLCCKMessageConfigurationVoiceSecondsKey";

/**
 *  地理位置消息内容的key
 */
static NSString *const kLCCKMessageConfigurationLocationKey = @"com.LeanCloud.kLCCKMessageConfigurationLocationKey";

#endif /* LCCKChatUntiles_h */
