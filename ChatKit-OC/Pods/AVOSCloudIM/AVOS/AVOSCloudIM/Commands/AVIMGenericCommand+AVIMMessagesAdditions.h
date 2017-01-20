//
//  AVIMGenericCommand+AVIMMessagesAdditions.h
//  AVOS
//
//  Created by 陈宜龙 on 15/11/18.
//  Copyright © 2015年 LeanCloud Inc. All rights reserved.
//

#import "MessagesProtoOrig.pbobjc.h"
#import "AVIMDirectCommand+DirectCommandAdditions.h"

@class AVIMConversationOutCommand;
@class AVIMSignature;
@class AVIMMessage;

typedef void (^AVIMCommandResultBlock)(AVIMGenericCommand *outCommand, AVIMGenericCommand *inCommand, NSError *error);

@interface AVIMGenericCommand (AVIMMessagesAdditions)

@property (nonatomic, copy) AVIMCommandResultBlock callback;
@property (nonatomic, assign) BOOL needResponse;

/*!
 序列化时必须要调用。为AVIMGenericCommand对象添加必要的三个字段：needResponse、SerialId、messageObject，，在command完全初始化之后调用
 @param commmand 具体的Command对象
 *
 */
- (void)avim_addRequiredKeyWithCommand:(LCIMMessage *)command;

/*!
 序列化时必须要调用。为AVIMGenericCommand对象添加必要的三个字段：s、t、n
 @param signature AVIMSignature签名对象
 *
 */
- (void)avim_addRequiredKeyForConvMessageWithSignature:(AVIMSignature *)signature;

/*!
 序列化时必须要调用。为AVIMGenericCommand对象添加必要的三个字段：s、t、n
 @param signature AVIMSignature签名对象
 *
 */
- (void)avim_addRequiredKeyForSessionMessageWithSignature:(AVIMSignature *)signature;

/*!
 序列化时必须要调用。为AVIMGenericCommand对象添加必要的三个字段：peerId、cid、msg、transient。请确保在调用本方法前调用了avim_addRequiredKey
 @param message AVIMMessage消息
 @param transient 是否为暂态消息
 *
 */
- (void)avim_addRequiredKeyForDirectMessageWithMessage:(AVIMMessage *)message transient:(BOOL)transient;

/*!
 为消息创建SerialId
 *
 */
- (void)avim_addOrRefreshSerialId;

/*!
 序列化时，判断消息是否需要符合要求：包含必要的字段
 @param error - 错误
 @return 消息是否需要符合要求：包含必要的字段
 */
- (BOOL)avim_validateCommand:(NSError **)error;

/*!
 判断是包含错误信息
 @return 是否包含错误信息
 */
- (BOOL)avim_hasError;

/*!
 反序列化时，如果包含错误信息，则将错误信息包装为 NSError 对象
 @return 将错误信息包装为 NSError 对象
 */
- (NSError *)avim_errorObject;

/*!
 反序列化时获取Command所属的具体的消息类型对象
 @return Command所属的具体的消息类型对象
 */
- (LCIMMessage *)avim_messageCommand;

/*!
 做 conversation 缓存时，为了使 key 能兼容，需要将 AVIMGenericCommand 对象转换为 AVIMConversationOutCommand 对象
 @return AVIMGenericCommand 对应的 AVIMConversationOutCommand 对象
 */
- (AVIMConversationOutCommand *)avim_conversationForCache;

/*!
 获取Command所属的具体的消息类型的字符串描述，仅在打印日志时使用
 @return Command所属的具体的消息类型的字符串描述
 */
- (NSString *)avim_messageClass;

/*!
 AVIMGenericCommand的字符串描述，仅在打印日志时使用
 @return AVIMGenericCommand的字符串描述
 */
- (NSString *)avim_description;

@end
