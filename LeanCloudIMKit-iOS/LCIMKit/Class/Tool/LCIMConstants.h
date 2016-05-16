//
//  LCIMConstants.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Common typdef and constants, and so on.

#import "LCIMUserModelDelegate.h"

//Callback with Custom type
typedef void (^LCIMUserResultsCallBack)(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error);
typedef void (^LCIMUserResultCallBack)(id<LCIMUserModelDelegate> user, NSError *error);
//Callback with Foundation type
typedef void (^LCIMBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^LCIMIntegerResultBlock)(NSInteger number, NSError *error);
typedef void (^LCIMStringResultBlock)(NSString *string, NSError *error);
typedef void (^LCIMDictionaryResultBlock)(NSDictionary * dict, NSError *error);
typedef void (^LCIMArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^LCIMSetResultBlock)(NSSet *channels, NSError *error);
typedef void (^LCIMDataResultBlock)(NSData *data, NSError *error);
typedef void (^LCIMIdResultBlock)(id object, NSError *error);
//Callback with Function object
typedef void (^LCIMVoidBlock)(void);
typedef void (^LCIMErrorBlock)(NSError *error);
typedef void (^LCIMImageResultBlock)(UIImage * image, NSError *error);
typedef void (^LCIMProgressBlock)(NSInteger percentDone);

#define LCIM_DEPRECATED(explain) __attribute__((deprecated(explain)))
//TODO: change to gcd semphore 
#define LCIM_WAIT_TIL_TRUE(signal, interval) \
do {                                       \
    while(!(signal)) {                     \
        @autoreleasepool {                 \
            if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:(interval)]]) { \
                [NSThread sleepForTimeInterval:(interval)]; \
            }                              \
        }                                  \
    }                                      \
} while (0)

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ## __VA_ARGS__);
#else
#   define DLog(...)
#endif

/**
 *  未读数改变了。通知去服务器同步 installation 的badge
 */
static NSString *const LCIMNotificationUnreadsUpdated = @"LCIMNotificationUnreadsUpdated";

/**
 *  消息到来了，通知聊天页面和最近对话页面刷新
 */
static NSString *const LCIMNotificationMessageReceived = @"LCIMNotificationMessageReceived";

/**
 *  消息到达对方了，通知聊天页面更改消息状态
 */
static NSString *const LCIMNotificationMessageDelivered = @"LCIMNotificationMessageDelivered";

/**
 *  对话的元数据变化了，通知页面刷新
 */
static NSString *const LCIMNotificationConversationUpdated = @"LCIMNotificationConversationUpdated";

/**
 *  聊天服务器连接状态更改了，通知最近对话和聊天页面是否显示红色警告条
 */
static NSString *const LCIMNotificationConnectivityUpdated = @"LCIMNotificationConnectivityUpdated";

static NSString *const LCIM_KEY_USERNAME = @"LCIM_KEY_USERNAME";
static NSString *const LCIM_KEY_USERID = @"LCIM_KEY_USERID";

///-----------------------------------------------------------------------------------
///---------------------用以产生Demo中的联系人数据的宏定义-------------------------------
///-----------------------------------------------------------------------------------

#define LCIMProfileKeyPeerId        @"peerId"
#define LCIMProfileKeyName          @"username"
#define LCIMProfileKeyAvatarURL     @"avatarURL"
#define LCIMDeveloperPeerId @"571dae7375c4cd3379024b2f"

//TODO:add more friends
#define LCIMContactProfiles \
@[ \
    @{ LCIMProfileKeyPeerId:LCIMDeveloperPeerId, LCIMProfileKeyName:@"LCIMKit小秘书", LCIMProfileKeyAvatarURL:@"http://image17-c.poco.cn/mypoco/myphoto/20151211/16/17338872420151211164742047.png" },\
    @{ LCIMProfileKeyPeerId:@"Tom", LCIMProfileKeyName:@"Tom", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/tom_and_jerry2.jpg" },\
    @{ LCIMProfileKeyPeerId:@"Jerry", LCIMProfileKeyName:@"Jerry", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/jerry.jpg" },\
    @{ LCIMProfileKeyPeerId:@"Harry", LCIMProfileKeyName:@"Harry", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/young_harry.jpg" },\
    @{ LCIMProfileKeyPeerId:@"William", LCIMProfileKeyName:@"William", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/william_shakespeare.jpg" },\
    @{ LCIMProfileKeyPeerId:@"Bob", LCIMProfileKeyName:@"Bob", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/bath_bob.jpg" },\
]

#define LCIMContactPeerIds \
    [LCIMContactProfiles valueForKeyPath:LCIMProfileKeyPeerId]

#define LCIMTestPersonProfiles \
@[ \
    @{ LCIMProfileKeyPeerId:@"Tom" },\
    @{ LCIMProfileKeyPeerId:@"Jerry" },\
    @{ LCIMProfileKeyPeerId:@"Harry" },\
    @{ LCIMProfileKeyPeerId:@"William" },\
    @{ LCIMProfileKeyPeerId:@"Bob" },\
]

#define LCIMTestPeerIds \
    [LCIMTestPersonProfiles valueForKeyPath:LCIMProfileKeyPeerId]

#define localize(key, default) NSLocalizedStringWithDefaultValue(key, nil, [NSBundle mainBundle], default, nil)

#pragma mark - Message Bars

#define kStringMessageBarErrorTitle localize(@"message.bar.error.title", @"Error Title")
#define kStringMessageBarErrorMessage localize(@"message.bar.error.message", @"This is an error message!")
#define kStringMessageBarSuccessTitle localize(@"message.bar.success.title", @"Success Title")
#define kStringMessageBarSuccessMessage localize(@"message.bar.success.message", @"This is a success message!")
#define kStringMessageBarInfoTitle localize(@"message.bar.info.title", @"--------")
#define kStringMessageBarInfoMessage localize(@"message.bar.info.message", @"--------")

#pragma mark - Buttons

#define kStringButtonLabelSuccessMessage localize(@"button.label.success.message", @"Success Message")
#define kStringButtonLabelErrorMessage localize(@"button.label.error.message", @"Error Message")
#define kStringButtonLabelInfoMessage localize(@"button.label.info.message", @"Information Message")
#define kStringButtonLabelHideAll localize(@"button.label.hide.all", @"Hide All")

static NSString *const LCIM_CONVERSATION_TYPE = @"type";

/**
 *  消息聊天类型
 */
typedef NS_ENUM(NSUInteger, LCIMConversationType){
    LCIMConversationTypeSingle = 0 /**< 单人聊天,不显示nickname */,
    LCIMConversationTypeGroup /**< 群组聊天,显示nickname */,
};

static NSString *const LCIMInstallationKeyChannels = @"channels";

// image STRETCH
#define LCIM_STRETCH_IMAGE(image, edgeInsets) [image resizableImageWithCapInsets:edgeInsets resizingMode:UIImageResizingModeStretch]

typedef NS_ENUM(NSInteger, LCIMBubbleMessageMediaType) {
    LCIMBubbleMessageMediaTypeText = 0,
    LCIMBubbleMessageMediaTypePhoto = 1,
    LCIMBubbleMessageMediaTypeVideo = 2,
    LCIMBubbleMessageMediaTypeVoice = 3,
    LCIMBubbleMessageMediaTypeEmotion = 4,
    LCIMBubbleMessageMediaTypeLocalPosition = 5,
};

typedef NS_ENUM(NSInteger, LCIMBubbleMessageMenuSelectedType) {
    LCIMBubbleMessageMenuSelectedTypeTextCopy = 0,
    LCIMBubbleMessageMenuSelectedTypeTextTranspond = 1,
    LCIMBubbleMessageMenuSelectedTypeTextFavorites = 2,
    LCIMBubbleMessageMenuSelectedTypeTextMore = 3,
    
    LCIMBubbleMessageMenuSelectedTypePhotoCopy = 4,
    LCIMBubbleMessageMenuSelectedTypePhotoTranspond = 5,
    LCIMBubbleMessageMenuSelectedTypePhotoFavorites = 6,
    LCIMBubbleMessageMenuSelectedTypePhotoMore = 7,
    
    LCIMBubbleMessageMenuSelectedTypeVideoTranspond = 8,
    LCIMBubbleMessageMenuSelectedTypeVideoFavorites = 9,
    LCIMBubbleMessageMenuSelectedTypeVideoMore = 10,
    
    LCIMBubbleMessageMenuSelectedTypeVoicePlay = 11,
    LCIMBubbleMessageMenuSelectedTypeVoiceFavorites = 12,
    LCIMBubbleMessageMenuSelectedTypeVoiceTurnToText = 13,
    LCIMBubbleMessageMenuSelectedTypeVoiceMore = 14,
};

typedef NS_ENUM(NSInteger, LCIMMessageStatus){
    LCIMMessageStatusSending,
    LCIMMessageStatusSent,
    LCIMMessageStatusReceived,
    LCIMMessageStatusFailed,
};

typedef NS_ENUM(NSInteger, LCIMBubbleMessageType) {
    LCIMBubbleMessageTypeSending = 0,
    LCIMBubbleMessageTypeReceiving
};

static NSInteger const kLCIMOnePageSize = 10;

/**
 *  提示信息的类型定义
 */
typedef NS_ENUM(NSInteger, LCIMMessageNotificationType) {
    /// 普通消息
    LCIMMessageNotificationTypeMessage = 0,
    /// 警告
    LCIMMessageNotificationTypeWarning,
    /// 错误
    LCIMMessageNotificationTypeError,
    /// 成功
    LCIMMessageNotificationTypeSuccess
};


///-------------------------------------------------------------------------
///---------------------Succeed Message Store-------------------------------
///-------------------------------------------------------------------------

#define LCIMConversationTableName           @"conversations"
#define LCIMConversationTableKeyId          @"id"
#define LCIMConversationTableKeyData        @"data"
#define LCIMConversationTableKeyUnreadCount @"unreadCount"
#define LCIMConversationTableKeyMentioned   @"mentioned"

#define LCIMConversatoinTableCreateSQL                                       \
    @"CREATE TABLE IF NOT EXISTS " LCIMConversationTableName @" ("           \
        LCIMConversationTableKeyId           @" VARCHAR(63) PRIMARY KEY, "   \
        LCIMConversationTableKeyData         @" BLOB NOT NULL, "             \
        LCIMConversationTableKeyUnreadCount  @" INTEGER DEFAULT 0, "         \
        LCIMConversationTableKeyMentioned    @" BOOL DEFAULT FALSE "         \
    @")"

#define LCIMConversationTableInsertSQL                           \
    @"INSERT OR IGNORE INTO " LCIMConversationTableName @" ("    \
        LCIMConversationTableKeyId               @", "           \
        LCIMConversationTableKeyData             @", "           \
        LCIMConversationTableKeyUnreadCount      @", "           \
        LCIMConversationTableKeyMentioned                        \
    @") VALUES(?, ?, ?, ?)"

#define LCIMConversationTableWhereClause                         \
    @" WHERE " LCIMConversationTableKeyId         @" = ?"

#define LCIMConversationTableDeleteSQL                           \
    @"DELETE FROM " LCIMConversationTableName                    \
    LCIMConversationTableWhereClause

#define LCIMDeleteConversationTable                              \
    @"DELETE FROM" LCIMConversationTableName                     \

#define LCIMConversationTableIncreaseUnreadCountSQL              \
    @"UPDATE " LCIMConversationTableName         @" "            \
    @"SET " LCIMConversationTableKeyUnreadCount  @" = "          \
            LCIMConversationTableKeyUnreadCount  @" + 1 "        \
    LCIMConversationTableWhereClause

#define LCIMConversationTableUpdateUnreadCountSQL                \
    @"UPDATE " LCIMConversationTableName         @" "            \
    @"SET " LCIMConversationTableKeyUnreadCount  @" = ? "        \
    LCIMConversationTableWhereClause

#define LCIMConversationTableUpdateMentionedSQL                  \
    @"UPDATE " LCIMConversationTableName         @" "            \
    @"SET " LCIMConversationTableKeyMentioned    @" = ? "        \
    LCIMConversationTableWhereClause

#define LCIMConversationTableSelectSQL                           \
    @"SELECT * FROM " LCIMConversationTableName                  \

#define LCIMConversationTableSelectOneSQL                        \
    @"SELECT * FROM " LCIMConversationTableName                  \
    LCIMConversationTableWhereClause

#define LCIMConversationTableUpdateDataSQL                       \
    @"UPDATE " LCIMConversationTableName @" "                    \
    @"SET " LCIMConversationTableKeyData @" = ? "                \
    LCIMConversationTableWhereClause                             \

///------------------------------------------------------------------------
///---------------------Failed Message Store-------------------------------
///------------------------------------------------------------------------

#define LCIMFaildMessageTable   @"failed_messages"
#define LCIMKeyId               @"id"
#define LCIMKeyConversationId   @"conversationId"
#define LCIMKeyMessage          @"message"

#define LCIMCreateTableSQL                                       \
    @"CREATE TABLE IF NOT EXISTS " LCIMFaildMessageTable @"("    \
        LCIMKeyId @" VARCHAR(63) PRIMARY KEY, "                  \
        LCIMKeyConversationId @" VARCHAR(63) NOT NULL,"          \
        LCIMKeyMessage @" BLOB NOT NULL"                         \
    @")"

#define LCIMWhereConversationId \
    @" WHERE " LCIMKeyConversationId @" = ? "

#define LCIMSelectMessagesSQL                        \
    @"SELECT * FROM " LCIMFaildMessageTable          \
    LCIMWhereConversationId

#define LCIMInsertMessageSQL                             \
    @"INSERT OR IGNORE INTO " LCIMFaildMessageTable @"(" \
        LCIMKeyId @","                                   \
        LCIMKeyConversationId @","                       \
        LCIMKeyMessage                                   \
    @") values (?, ?, ?) "                              \

#define LCIMDeleteMessageSQL                             \
    @"DELETE FROM " LCIMFaildMessageTable @" "           \
    @"WHERE " LCIMKeyId " = ? "                          \
    
