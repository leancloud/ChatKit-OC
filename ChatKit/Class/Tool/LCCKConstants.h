//
//  LCCKConstants.h
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Common typdef and constants, and so on.

#import "LCCKUserDelegate.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

#pragma mark - Base ViewController Life Time Block
///=============================================================================
/// @name Base ViewController Life Time Block
///=============================================================================

//Callback with Custom type
typedef void (^LCCKUserResultsCallBack)(NSArray<id<LCCKUserDelegate>> *users, NSError *error);
typedef void (^LCCKUserResultCallBack)(id<LCCKUserDelegate> user, NSError *error);
//Callback with Foundation type
typedef void (^LCCKBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^LCCKViewControllerBooleanResultBlock)(__kindof UIViewController *viewController, BOOL succeeded, NSError *error);

typedef void (^LCCKIntegerResultBlock)(NSInteger number, NSError *error);
typedef void (^LCCKStringResultBlock)(NSString *string, NSError *error);
typedef void (^LCCKDictionaryResultBlock)(NSDictionary * dict, NSError *error);
typedef void (^LCCKArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^LCCKSetResultBlock)(NSSet *channels, NSError *error);
typedef void (^LCCKDataResultBlock)(NSData *data, NSError *error);
typedef void (^LCCKIdResultBlock)(id object, NSError *error);
typedef void (^LCCKIdBoolResultBlock)(BOOL succeeded, id object, NSError *error);
typedef void (^LCCKRequestAuthorizationBoolResultBlock)(BOOL granted, NSError *error);

//Callback with Function object
typedef void (^LCCKVoidBlock)(void);
typedef void (^LCCKErrorBlock)(NSError *error);
typedef void (^LCCKImageResultBlock)(UIImage * image, NSError *error);
typedef void (^LCCKProgressBlock)(NSInteger percentDone);

#pragma mark - Common Define
///=============================================================================
/// @name Common Define
///=============================================================================

#define LCCK_DEPRECATED(explain) __attribute__((deprecated(explain)))

#ifndef LCCKLocalizedStrings
#define LCCKLocalizedStrings(key) \
    NSLocalizedStringFromTableInBundle(key, @"LCChatKitString", [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[LCChatKit class]] resourcePath] stringByAppendingPathComponent:@"Other.bundle"]], nil)
#endif


#ifdef DEBUG
#define LCCKLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ## __VA_ARGS__);
#else
#   define LCCKLog(...)
#endif

#pragma mark - Notification Name
///=============================================================================
/// @name Notification Name
///=============================================================================

/**
 *  未读数改变了。通知去服务器同步 installation 的badge
 */
static NSString *const LCCKNotificationUnreadsUpdated = @"LCCKNotificationUnreadsUpdated";

/**
 *  消息到来了，通知聊天页面和最近对话页面刷新
 */
static NSString *const LCCKNotificationMessageReceived = @"LCCKNotificationMessageReceived";
/**
 *  消息到来了，通知聊天页面和最近对话页面刷新
 */
static NSString *const LCCKNotificationCustomMessageReceived = @"LCCKNotificationCustomMessageReceived";

static NSString *const LCCKNotificationCustomTransientMessageReceived = @"LCCKNotificationCustomTransientMessageReceived";

/**
 *  消息到达对方了，通知聊天页面更改消息状态
 */
static NSString *const LCCKNotificationMessageDelivered = @"LCCKNotificationMessageDelivered";

/**
 *  对话的元数据变化了，通知页面刷新
 */
static NSString *const LCCKNotificationConversationUpdated = @"LCCKNotificationConversationUpdated";

/**
 *  聊天服务器连接状态更改了，通知最近对话和聊天页面是否显示红色警告条
 */
static NSString *const LCCKNotificationConnectivityUpdated = @"LCCKNotificationConnectivityUpdated";

/**
 * 会话失效，如当群被解散或当前用户不再属于该会话时，对应会话会失效应当被删除并且关闭聊天窗口
 */
static NSString *const LCCKNotificationCurrentConversationInvalided = @"LCCKNotificationCurrentConversationInvalided";

/**
 * 对话聊天背景切换
 */
static NSString *const LCCKNotificationConversationViewControllerBackgroundImageDidChanged = @"LCCKNotificationConversationViewControllerBackgroundImageDidChanged";

static NSString *const LCCKNotificationConversationViewControllerBackgroundImageDidChangedUserInfoConversationIdKey = @"LCCKNotificationConversationViewControllerBackgroundImageDidChangedUserInfoConversationIdKey";


static NSString *const LCCKNotificationConversationInvalided = @"LCCKNotificationConversationInvalided";
static NSString *const LCCKNotificationConversationListDataSourceUpdated = @"LCCKNotificationConversationListDataSourceUpdated";
static NSString *const LCCKNotificationContactListDataSourceUpdated = @"LCCKNotificationContactListDataSourceUpdated";

static NSString *const LCCKNotificationContactListDataSourceUpdatedUserInfoDataSourceKey = @"LCCKNotificationContactListDataSourceUpdatedUserInfoDataSourceKey";

static NSString *const LCCKNotificationContactListDataSourceUserIdType = @"LCCKNotificationContactListDataSourceUserIdType";
static NSString *const LCCKNotificationContactListDataSourceContactObjType = @"LCCKNotificationContactListDataSourceContactObjType";
static NSString *const LCCKNotificationContactListDataSourceUpdatedUserInfoDataSourceTypeKey = @"LCCKNotificationContactListDataSourceUpdatedUserInfoDataSourceTypeKey";

#pragma mark - Conversation Enum : Message Type and operation
///=============================================================================
/// @name Conversation Enum : Message Type and operation
///=============================================================================

/**
 *  消息聊天类型
 */
typedef NS_ENUM(NSUInteger, LCCKConversationType){
    LCCKConversationTypeSingle = 0 /**< 单人聊天,不显示nickname */,
    LCCKConversationTypeGroup /**< 群组聊天,显示nickname */,
};

/**
 *  消息拥有者类型
 */
typedef NS_ENUM(NSUInteger, LCCKMessageOwnerType){
    LCCKMessageOwnerTypeUnknown = 0 /**< 未知的消息拥有者 */,
    LCCKMessageOwnerTypeSystem /**< 系统消息 */,
    LCCKMessageOwnerTypeSelf /**< 自己发送的消息 */,
    LCCKMessageOwnerTypeOther /**< 接收到的他人消息 */,
};

static AVIMMessageMediaType const kAVIMMessageMediaTypeSystem = -7;

/**
 *  消息发送状态,自己发送的消息时有
 */
typedef NS_ENUM(NSUInteger, LCCKMessageSendState){
    LCCKMessageSendStateNone = 0,
    LCCKMessageSendStateSending = 1, /**< 消息发送中 */
    LCCKMessageSendStateSent, /**< 消息发送成功 */
    LCCKMessageSendStateDelivered, /**< 消息对方已接收*/
    LCCKMessageSendStateFailed, /**< 消息发送失败 */
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

static NSInteger const kLCCKOnePageSize = 10;
static NSString *const LCCK_CONVERSATION_TYPE = @"type";
static NSString *const LCCKInstallationKeyChannels = @"channels";

static NSString *const LCCKDidReceiveMessagesUserInfoConversationKey = @"conversation";
static NSString *const LCCKDidReceiveMessagesUserInfoMessagesKey = @"receivedMessages";
static NSString *const LCCKDidReceiveCustomMessageUserInfoMessageKey = @"receivedCustomMessage";

#define LCCK_CURRENT_TIMESTAMP ([[NSDate date] timeIntervalSince1970] * 1000)
#define LCCK_FUTURE_TIMESTAMP ([[NSDate distantFuture] timeIntervalSince1970] * 1000)
//整数或小数
#define LCCK_TIMESTAMP_REGEX @"^[0-9]*(.)?[0-9]*$"

#pragma mark - Custom Message
///=============================================================================
/// @name Custom Message
///=============================================================================

/*!
 * 用来定义如何展示老版本未支持的自定义消息类型
 */
static NSString *const LCCKCustomMessageDegradeKey = @"degrade";

/*!
 * 最近对话列表中最近一条消息的title，比如：最近一条消息是图片，可设置该字段内容为：`@"图片"`，相应会展示：`[图片]`
 */
static NSString *const LCCKCustomMessageTypeTitleKey = @"typeTitle";

/*!
 * 用来显示在push提示中。
 */
static NSString *const LCCKCustomMessageSummaryKey = @"summary";

static NSString *const LCCKCustomMessageIsCustomKey = @"isCustom";
static NSString *const LCCKCustomMessageOnlyVisiableForPartClientIds = @"OnlyVisiableForPartClientIds";

/*!
 * 对话类型，用来展示在推送提示中，以达到这样的效果： [群消息]Tom：hello gays!
 * 以枚举 LCCKConversationType 定义为准，0为单聊，1为群聊
 */
static NSString *const LCCKCustomMessageConversationTypeKey = @"conversationType";

static NSString *const LCCKConversationGroupAvatarURLKey = @"groupAvatarURL";

#pragma mark - Custom Message Cell
///=============================================================================
/// @name Custom Message Cell
///=============================================================================

FOUNDATION_EXTERN NSMutableDictionary const * LCCKChatMessageCellMediaTypeDict;
FOUNDATION_EXTERN NSMutableDictionary const *_typeDict;

static NSString *const LCCKCellIdentifierDefault = @"LCCKCellIdentifierDefault";
static NSString *const LCCKCellIdentifierCustom = @"LCCKCellIdentifierCustom";
static NSString *const LCCKCellIdentifierGroup = @"LCCKCellIdentifierGroup";
static NSString *const LCCKCellIdentifierSingle = @"LCCKCellIdentifierSingle";
static NSString *const LCCKCellIdentifierOwnerSelf = @"LCCKCellIdentifierOwnerSelf";
static NSString *const LCCKCellIdentifierOwnerOther = @"LCCKCellIdentifierOwnerOther";
static NSString *const LCCKCellIdentifierOwnerSystem = @"LCCKCellIdentifierOwnerSystem";

#pragma mark - 聊天输入框默认插件类型定义
///=============================================================================
/// @name 聊天输入框默认插件类型定义
///=============================================================================

FOUNDATION_EXTERN NSMutableDictionary const * LCCKInputViewPluginDict;
FOUNDATION_EXTERN NSMutableArray const * LCCKInputViewPluginArray;
static NSString *const LCCKInputViewPluginTypeKey = @"LCCKInputViewPluginTypeKey";
static NSString *const LCCKInputViewPluginClassKey = @"LCCKInputViewPluginClassKey";

/**
 *  默认插件的类型定义
 */
typedef NS_ENUM(NSUInteger, LCCKInputViewPluginType) {
    LCCKInputViewPluginTypeDefault = 0,       /**< 默认未知类型 */
    LCCKInputViewPluginTypeTakePhoto = -1,         /**< 拍照 */
    LCCKInputViewPluginTypePickImage = -2,         /**< 选择照片 */
    LCCKInputViewPluginTypeLocation = -3,          /**< 地理位置 */
    LCCKInputViewPluginTypeShortVideo = -4,        /**< 短视频 */
//    LCCKInputViewPluginTypeMorePanel= -7,         /**< 显示更多面板 */
//    LCCKInputViewPluginTypeText = -1,              /**< 文本输入 */
//    LCCKInputViewPluginTypeVoice = -2,             /**< 语音输入 */
};

#define LCCK_CURRENT_CONVERSATIONVIEWCONTROLLER_OBJECT              \
({                                                                  \
    LCCKConversationViewController *conversationViewController;     \
    conversationViewController = self.conversationViewController;   \
    conversationViewController;                                     \
}) 

#pragma mark - 自定义UI行为
///=============================================================================
/// @name 自定义UI行为
///=============================================================================
static NSString *const LCCKCustomConversationViewControllerBackgroundImageNamePrefix = @"CONVERSATION_BACKGROUND_";
static NSString *const LCCKDefaultConversationViewControllerBackgroundImageName = @"CONVERSATION_BACKGROUND_ALL";
    
static CGFloat const LCCKAnimateDuration = .25f;

#define LCCKMessageCellLimit ([UIApplication sharedApplication].keyWindow.frame.size.width/5*3)

// image STRETCH
#define LCCK_STRETCH_IMAGE(image, edgeInsets) [image resizableImageWithCapInsets:edgeInsets resizingMode:UIImageResizingModeStretch]
#define LCCK_CONVERSATIONVIEWCONTROLLER_BACKGROUNDCOLOR [UIColor colorWithRed:234.0f/255.0f green:234/255.0f blue:234/255.f alpha:1.0f]
/*!
 *  提示信息的类型定义
 */
typedef enum : NSUInteger {
    /// 普通消息
    LCCKMessageNotificationTypeMessage = 0,
    /// 警告
    LCCKMessageNotificationTypeWarning,
    /// 错误
    LCCKMessageNotificationTypeError,
    /// 成功
    LCCKMessageNotificationTypeSuccess
} LCCKMessageNotificationType;

/*!
 * HUD的行为
 */
typedef enum : NSUInteger {
    /// 展示
    LCCKMessageHUDActionTypeShow,
    /// 隐藏
    LCCKMessageHUDActionTypeHide,
    /// 错误
    LCCKMessageHUDActionTypeError,
    /// 成功
    LCCKMessageHUDActionTypeSuccess
} LCCKMessageHUDActionType;

typedef enum : NSUInteger {
    LCCKScrollDirectionNone,
    LCCKScrollDirectionRight,
    LCCKScrollDirectionLeft,
    LCCKScrollDirectionUp,
    LCCKScrollDirectionDown,
    LCCKScrollDirectionCrazy,
} LCCKScrollDirection;

//TODO: to Delete
typedef NS_ENUM(NSInteger, LCCKBubbleMessageMenuSelectedType) {
    LCCKBubbleMessageMenuSelectedTypeTextCopy = 0,
    LCCKBubbleMessageMenuSelectedTypeTextTranspond = 1,
    LCCKBubbleMessageMenuSelectedTypeTextFavorites = 2,
    LCCKBubbleMessageMenuSelectedTypeTextMore = 3,
    
    LCCKBubbleMessageMenuSelectedTypePhotoCopy = 4,
    LCCKBubbleMessageMenuSelectedTypePhotoTranspond = 5,
    LCCKBubbleMessageMenuSelectedTypePhotoFavorites = 6,
    LCCKBubbleMessageMenuSelectedTypePhotoMore = 7,
    
    LCCKBubbleMessageMenuSelectedTypeVideoTranspond = 8,
    LCCKBubbleMessageMenuSelectedTypeVideoFavorites = 9,
    LCCKBubbleMessageMenuSelectedTypeVideoMore = 10,
    
    LCCKBubbleMessageMenuSelectedTypeVoicePlay = 11,
    LCCKBubbleMessageMenuSelectedTypeVoiceFavorites = 12,
    LCCKBubbleMessageMenuSelectedTypeVoiceTurnToText = 13,
    LCCKBubbleMessageMenuSelectedTypeVoiceMore = 14,
};


#pragma mark - Succeed Message Store
///=============================================================================
/// @name Succeed Message Store
///=============================================================================

#define LCCKConversationTableName           @"conversations"
#define LCCKConversationTableKeyId          @"id"
#define LCCKConversationTableKeyData        @"data"
#define LCCKConversationTableKeyUnreadCount @"unreadCount"
#define LCCKConversationTableKeyMentioned   @"mentioned"
#define LCCKConversationTableKeyDraft       @"draft"

#define LCCKConversatoinTableCreateSQL                                       \
    @"CREATE TABLE IF NOT EXISTS " LCCKConversationTableName @" ("           \
        LCCKConversationTableKeyId           @" VARCHAR(63) PRIMARY KEY, "   \
        LCCKConversationTableKeyData         @" BLOB NOT NULL, "             \
        LCCKConversationTableKeyUnreadCount  @" INTEGER DEFAULT 0, "         \
        LCCKConversationTableKeyMentioned    @" BOOL DEFAULT FALSE, "        \
        LCCKConversationTableKeyDraft        @" VARCHAR(63)"                 \
    @")"

#define LCCKConversationTableInsertSQL                           \
    @"INSERT OR IGNORE INTO " LCCKConversationTableName @" ("    \
        LCCKConversationTableKeyId               @", "           \
        LCCKConversationTableKeyData             @", "           \
        LCCKConversationTableKeyUnreadCount      @", "           \
        LCCKConversationTableKeyMentioned        @", "           \
        LCCKConversationTableKeyDraft                            \
    @") VALUES(?, ?, ?, ?, ?)"

#define LCCKConversationTableWhereClause                         \
    @" WHERE " LCCKConversationTableKeyId         @" = ?"

#define LCCKConversationTableDeleteSQL                           \
    @"DELETE FROM " LCCKConversationTableName                    \
    LCCKConversationTableWhereClause

#define LCCKDeleteConversationTable                              \
    @"DELETE FROM " LCCKConversationTableName                     \

#define LCCKConversationTableIncreaseUnreadCountSQL              \
    @"UPDATE " LCCKConversationTableName         @" "            \
    @"SET " LCCKConversationTableKeyUnreadCount  @" = "          \
            LCCKConversationTableKeyUnreadCount  @" + ?"        \
    LCCKConversationTableWhereClause

#define LCCKConversationTableIncreaseOneUnreadCountSQL              \
    @"UPDATE " LCCKConversationTableName         @" "            \
    @"SET " LCCKConversationTableKeyUnreadCount  @" = "          \
            LCCKConversationTableKeyUnreadCount  @" + 1 "        \
    LCCKConversationTableWhereClause


#define LCCKConversationTableUpdateUnreadCountSQL                \
    @"UPDATE " LCCKConversationTableName         @" "            \
    @"SET " LCCKConversationTableKeyUnreadCount  @" = ? "        \
    LCCKConversationTableWhereClause

#define LCCKConversationTableUpdateMentionedSQL                  \
    @"UPDATE " LCCKConversationTableName         @" "            \
    @"SET " LCCKConversationTableKeyMentioned    @" = ? "        \
    LCCKConversationTableWhereClause

#define LCCKConversationTableUpdateDraftSQL                      \
    @"UPDATE " LCCKConversationTableName         @" "            \
    @"SET " LCCKConversationTableKeyDraft        @" = ? "        \
    LCCKConversationTableWhereClause


#define LCCKConversationTableSelectSQL                           \
    @"SELECT * FROM " LCCKConversationTableName                  \

#define LCCKConversationTableSelectDraftSQL                           \
    @"SELECT draft FROM " LCCKConversationTableName                  \
    LCCKConversationTableWhereClause

#define LCCKConversationTableSelectOneSQL                        \
    @"SELECT * FROM " LCCKConversationTableName                  \
    LCCKConversationTableWhereClause

#define LCCKConversationTableUpdateDataSQL                       \
    @"UPDATE " LCCKConversationTableName @" "                    \
    @"SET " LCCKConversationTableKeyData @" = ? "                \
    LCCKConversationTableWhereClause                             \

#pragma mark - Failed Message Store
///=============================================================================
/// @name Failed Message Store
///=============================================================================

#define LCCKFaildMessageTable   @"failed_messages"
#define LCCKKeyId               @"id"
#define LCCKKeyConversationId   @"conversationId"
#define LCCKKeyMessage          @"message"

#define LCCKCreateTableSQL                                       \
    @"CREATE TABLE IF NOT EXISTS " LCCKFaildMessageTable @"("    \
        LCCKKeyId @" VARCHAR(63) PRIMARY KEY, "                  \
        LCCKKeyConversationId @" VARCHAR(63) NOT NULL,"          \
        LCCKKeyMessage @" BLOB NOT NULL"                         \
    @")"

#define LCCKWhereConversationId \
    @" WHERE " LCCKKeyConversationId @" = ? "

#define LCCKSelectMessagesSQL                        \
    @"SELECT * FROM " LCCKFaildMessageTable          \
    LCCKWhereConversationId

#define LCCKWhereKeyId \
    @" WHERE " LCCKKeyId @" IN ('%@') "

//SELECT * FROM failed_messages WHERE id IN ('%@')
#define LCCKSelectMessagesByIDSQL                        \
    @"SELECT * FROM " LCCKFaildMessageTable          \
    LCCKWhereKeyId

#define LCCKInsertMessageSQL                             \
    @"INSERT OR IGNORE INTO " LCCKFaildMessageTable @"(" \
        LCCKKeyId @","                                   \
        LCCKKeyConversationId @","                       \
        LCCKKeyMessage                                   \
    @") values (?, ?, ?) "                              \

#define LCCKDeleteMessageSQL                             \
    @"DELETE FROM " LCCKFaildMessageTable @" "           \
    @"WHERE " LCCKKeyId " = ? "                          \
    
