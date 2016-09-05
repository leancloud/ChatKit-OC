//
//  AVIMMessage_Internal.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/28/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMMessage.h"

@interface AVIMMessage ()

/*!
 * Wether message has breakpoint or not
 */
@property (assign) BOOL breakpoint;

/*!
 * Wether message is offline or not
 */
@property (nonatomic, assign) BOOL offline;

/*!
 * Wether has more messages before current message
 */
@property (nonatomic, assign) BOOL hasMore;

/*!
 * Id of local client which owns the message
 */
@property (nonatomic, copy) NSString *localClientId;

/*!
 * Wether message is transient or not
 */
@property (nonatomic, assign) BOOL transient;

/*!
 * Payload of current message, it is a JSON string or plain text message
 */
- (NSString *)payload;

//======================================================================
//====== override readonly property to readwrite for internal use ======
//======================================================================

/* 表示消息状态*/
@property (nonatomic, assign) AVIMMessageStatus status;
/*消息 id*/
@property (nonatomic, copy) NSString *messageId;
/*消息发送/接收方 id*/
@property (nonatomic, copy) NSString *clientId;
/*消息所属对话的 id*/
@property (nonatomic, copy) NSString *conversationId;

@end
