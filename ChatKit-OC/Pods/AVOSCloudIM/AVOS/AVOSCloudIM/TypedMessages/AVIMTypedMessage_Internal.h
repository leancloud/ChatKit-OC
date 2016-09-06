//
//  AVIMTypedMessage_Internal.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/8/15.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMTypedMessage.h"
#import "AVIMTypedMessageObject.h"
#import "AVIMMessage_Internal.h"

//NSString *const kAVIMTypedMessageMetaKey = @"metaData";

extern NSMutableDictionary const *_typeDict;

@interface AVIMTypedMessage ()
//@property(nonatomic, strong)NSString *attachmentUrl;  // 附件URL地址
//@property(nonatomic, strong)NSDictionary *metaData;  // 自定义属性
@property(nonatomic, strong)AVFile *file;
@property(nonatomic, strong)AVGeoPoint *location;
//@property(nonatomic, strong)NSData *data;
@property(nonatomic, strong)AVIMTypedMessageObject *messageObject;
@property(nonatomic, strong)NSString *attachedFilePath;

+ (Class)classForMediaType:(AVIMMessageMediaType)mediaType;
//+ (instancetype)messageWithText:(NSString *)text
//                      mediaType:(AVIMMessageMediaType)mediaType
//                  attachmentUrl:(NSString *)attachmentUrl
//                     attributes:(NSDictionary *)attributes
//                       metaData:(NSDictionary *)metaData;

+ (instancetype)messageWithMessageObject:(AVIMTypedMessageObject *)messageObject;
+ (instancetype)messageWithDictionary:(NSDictionary *)dictionary;
///*!
// 使用本地数据，创建富媒体消息（譬如图片、视频、音频、文件等），可补充额外数据。
// @param text － 消息文本.
// @param mediaType － 媒体类型
// @param attachedFilePath － 附件的本地路径
// @param attributes － 开发者可以附加的任何数据
// */
//+ (instancetype)messageWithText:(NSString *)text
//                      mediaType:(AVIMMessageMediaType)mediaType
//               attachedFilePath:(NSString *)attachedFilePath
//                     attributes:(NSDictionary *)attributes;

@end
