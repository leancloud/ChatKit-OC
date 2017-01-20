//
//  AVMessage.h
//  AVOS
//
//  Created by Qihe Bian on 8/6/14.
//
//

#import <Foundation/Foundation.h>

@class AVSession;
@class AVGroup;
typedef enum : NSUInteger {
    AVMessageTypePeerIn = 1,
    AVMessageTypePeerOut,
    AVMessageTypeGroupIn,
    AVMessageTypeGroupOut,
} AVMessageType;

NS_ASSUME_NONNULL_BEGIN

@interface AVMessage : NSObject <NSCopying>

@property (nonatomic, assign) AVMessageType type;
@property (nonatomic, copy, nullable) NSString *payload;
@property (nonatomic, copy, nullable) NSString *fromPeerId;
@property (nonatomic, copy, nullable) NSString *toPeerId;
@property (nonatomic, copy, nullable) NSString *groupId;
@property (nonatomic, assign) int64_t timestamp;
@property (nonatomic, assign) int64_t receiptTimestamp;
@property (nonatomic, assign) BOOL offline;

/*!
 *  构造一个发送到group的message对象
 *  @param group 要发送的group
 *  @param payload 消息载体
 *  @return message 对象
 */
+ (instancetype)messageForGroup:(AVGroup *)group payload:(NSString *)payload;

/*!
 *  构造一个发送给 toPeerId 的message对象
 *  @param session 服务器会话
 *  @param toPeerId 要发往的 peerId
 *  @param payload 消息载体
 *  @return message 对象
 */
+ (instancetype)messageForPeerWithSession:(AVSession *)session
                                 toPeerId:(NSString *)toPeerId
                                  payload:(NSString *)payload;

@end

NS_ASSUME_NONNULL_END
