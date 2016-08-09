//
//  LCCKConstants.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Common typdef and constants, and so on.

#import "LCCKUserDelegate.h"

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
//Callback with Function object
typedef void (^LCCKVoidBlock)(void);
typedef void (^LCCKErrorBlock)(NSError *error);
typedef void (^LCCKImageResultBlock)(UIImage * image, NSError *error);
typedef void (^LCCKProgressBlock)(NSInteger percentDone);

#define LCCK_DEPRECATED(explain) __attribute__((deprecated(explain)))


#ifndef LCCKLocalizedStrings
#define LCCKLocalizedStrings(key) \
    NSLocalizedStringFromTableInBundle(key, @"LCChatKitString", [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[LCChatKit class]] resourcePath] stringByAppendingPathComponent:@"Common.bundle"]], nil)
#endif


#ifdef DEBUG
#define LCCKLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ## __VA_ARGS__);
#else
#   define LCCKLog(...)
#endif

static CGFloat const LCCKAnimateDuration = .25f;
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

static NSString *const LCCK_KEY_USERNAME = @"LCCK_KEY_USERNAME";
static NSString *const LCCK_KEY_USERID = @"LCCK_KEY_USERID";

#pragma mark - 用以产生Demo中的联系人数据的宏定义
///=============================================================================
/// @name 用以产生Demo中的联系人数据的宏定义
///=============================================================================

#define LCCKProfileKeyPeerId        @"peerId"
#define LCCKProfileKeyName          @"username"
#define LCCKProfileKeyAvatarURL     @"avatarURL"
#define LCCKDeveloperPeerId @"571dae7375c4cd3379024b2f"

//TODO:add more friends
#define LCCKContactProfiles \
@[ \
    @{ LCCKProfileKeyPeerId:LCCKDeveloperPeerId, LCCKProfileKeyName:@"ChatKit-iOS小秘书", LCCKProfileKeyAvatarURL:@"http://image17-c.poco.cn/mypoco/myphoto/20151211/16/17338872420151211164742047.png" },\
    @{ LCCKProfileKeyPeerId:@"Tom", LCCKProfileKeyName:@"Tom", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/tom_and_jerry2.jpg" },\
    @{ LCCKProfileKeyPeerId:@"Jerry", LCCKProfileKeyName:@"Jerry", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/jerry.jpg" },\
    @{ LCCKProfileKeyPeerId:@"Harry", LCCKProfileKeyName:@"Harry", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/young_harry.jpg" },\
    @{ LCCKProfileKeyPeerId:@"William", LCCKProfileKeyName:@"William", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/william_shakespeare.jpg" },\
    @{ LCCKProfileKeyPeerId:@"Bob", LCCKProfileKeyName:@"Bob", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/bath_bob.jpg" },\
]

#define LCCKContactPeerIds \
    [LCCKContactProfiles valueForKeyPath:LCCKProfileKeyPeerId]

#define LCCKTestPersonProfiles \
@[ \
    @{ LCCKProfileKeyPeerId:@"Tom" },\
    @{ LCCKProfileKeyPeerId:@"Jerry" },\
    @{ LCCKProfileKeyPeerId:@"Harry" },\
    @{ LCCKProfileKeyPeerId:@"William" },\
    @{ LCCKProfileKeyPeerId:@"Bob" },\
]

#define LCCKTestPeerIds \
    [LCCKTestPersonProfiles valueForKeyPath:LCCKProfileKeyPeerId]


#define localize(key, default) LCCKLocalizedStrings(key)

#pragma mark - Message Bars

#define kStringMessageBarErrorTitle localize(@"message.bar.error.title")
#define kStringMessageBarErrorMessage localize(@"message.bar.error.message")
#define kStringMessageBarSuccessTitle localize(@"message.bar.success.title")
#define kStringMessageBarSuccessMessage localize(@"message.bar.success.message")
#define kStringMessageBarInfoTitle localize(@"message.bar.info.title")
#define kStringMessageBarInfoMessage localize(@"message.bar.info.message")

#pragma mark - Buttons

#define kStringButtonLabelSuccessMessage localize(@"button.label.success.message")
#define kStringButtonLabelErrorMessage localize(@"button.label.error.message")
#define kStringButtonLabelInfoMessage localize(@"button.label.info.message")
#define kStringButtonLabelHideAll localize(@"button.label.hide.all")

static NSString *const LCCK_CONVERSATION_TYPE = @"type";

/**
 *  消息聊天类型
 */
typedef NS_ENUM(NSUInteger, LCCKConversationType){
    LCCKConversationTypeSingle = 0 /**< 单人聊天,不显示nickname */,
    LCCKConversationTypeGroup /**< 群组聊天,显示nickname */,
};

static NSString *const LCCKInstallationKeyChannels = @"channels";

// image STRETCH
#define LCCK_STRETCH_IMAGE(image, edgeInsets) [image resizableImageWithCapInsets:edgeInsets resizingMode:UIImageResizingModeStretch]

typedef NS_ENUM(NSInteger, LCCKBubbleMessageMediaType) {
    LCCKBubbleMessageMediaTypeText = 0,
    LCCKBubbleMessageMediaTypePhoto = 1,
    LCCKBubbleMessageMediaTypeVideo = 2,
    LCCKBubbleMessageMediaTypeVoice = 3,
    LCCKBubbleMessageMediaTypeEmotion = 4,
    LCCKBubbleMessageMediaTypeLocalPosition = 5,
};

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

typedef NS_ENUM(NSInteger, LCCKBubbleMessageType) {
    LCCKBubbleMessageTypeSending = 0,
    LCCKBubbleMessageTypeReceiving
};

static NSInteger const kLCCKOnePageSize = 10;

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
    
