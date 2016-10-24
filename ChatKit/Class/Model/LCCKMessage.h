//
//  LCCKMessage.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/21.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LCCKMessageDelegate.h"

@class AVIMTypedMessage;

@interface LCCKMessage : NSObject <NSCoding, NSCopying, LCCKMessageDelegate>

@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, copy, readonly) NSString *systemText;
@property (nonatomic, strong, readwrite) UIImage *photo;
@property (nonatomic, strong, readwrite) UIImage *thumbnailPhoto;
@property (nonatomic, copy, readonly) NSString *photoPath;
@property (nonatomic, strong, readonly) NSURL *thumbnailURL;
@property (nonatomic, strong, readonly) NSURL *originPhotoURL;
@property (nonatomic, strong, readonly) UIImage *videoConverPhoto;
@property (nonatomic, copy, readonly) NSString *videoPath;
@property (nonatomic, strong, readonly) NSURL *videoURL;

@property (nonatomic, copy, readonly) NSString *voicePath;
@property (nonatomic, strong, readonly) NSURL *voiceURL;
@property (nonatomic, copy, readonly) NSString *voiceDuration;

//@property (nonatomic, copy, readonly) NSString *emotionName;
//@property (nonatomic, copy, readonly) NSString *emotionPath;

@property (nonatomic, strong, readonly) UIImage *localPositionPhoto;
@property (nonatomic, copy, readonly) NSString *geolocations;
@property (nonatomic, strong, readonly) CLLocation *location;

@property (nonatomic, assign, readonly) AVIMMessageMediaType mediaType;
//@property (nonatomic, assign) LCCKConversationType messageGroupType;
@property (nonatomic, assign, readonly) LCCKMessageReadState messageReadState;
@property (nonatomic, copy, readonly) NSString *serverMessageId;
@property (nonatomic, assign) NSTimeInterval timestamp;

/*!
 * 有localMessageId且没有serviceMessageId的属于localMessage，其中
 * systemMessage不属于localMessage，localFeedbackText属于。
 */
@property (nonatomic, assign, getter=isLocalMessage) BOOL localMessage;
/*!
 * just for failed message store, its value is always not same to serverMessageId. value is same to timestamp.
 */
@property (nonatomic, copy, readwrite) NSString *localMessageId;

@property (nonatomic, copy, readonly) NSString *localDisplayName;

- (instancetype)initWithText:(NSString *)text
                      senderId:(NSString *)senderId
                       sender:(id<LCCKUserDelegate>)sender
                   timestamp:(NSTimeInterval)timestamp
             serverMessageId:(NSString *)serverMessageId;

- (instancetype)initWithSystemText:(NSString *)text;
+ (instancetype)systemMessageWithTimestamp:(NSTimeInterval)timestamp;
- (instancetype)initWithLocalFeedbackText:(NSString *)localFeedbackText;
+ (instancetype)localFeedbackText:(NSString *)localFeedbackText;

/**
 *  初始化图片类型的消息
 *
 *  @param photo          目标图片
 *  @param photePath      目标图片的本地路径
 *  @param thumbnailURL   目标图片在服务器的缩略图地址
 *  @param originPhotoURL 目标图片在服务器的原图地址
 *  @param sender         发送者
 *  @param date           发送时间
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithPhoto:(UIImage *)photo
               thumbnailPhoto:(UIImage *)thumbnailPhoto
                    photoPath:(NSString *)photoPath
                 thumbnailURL:(NSURL *)thumbnailURL
               originPhotoURL:(NSURL *)originPhotoURL
                       senderId:(NSString *)senderId
                       sender:(id<LCCKUserDelegate>)sender
                    timestamp:(NSTimeInterval)timestamp
              serverMessageId:(NSString *)serverMessageId;

/**
 *  初始化视频类型的消息
 *
 *  @param videoConverPhoto 目标视频的封面图
 *  @param videoPath        目标视频的本地路径，如果是下载过，或者是从本地发送的时候，会存在
 *  @param videoURL         目标视频在服务器上的地址
 *  @param sender           发送者
 *  @param date             发送时间
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithVideoConverPhoto:(UIImage *)videoConverPhoto
                               videoPath:(NSString *)videoPath
                                videoURL:(NSURL *)videoURL
                                  senderId:(NSString *)senderId
                                   sender:(id<LCCKUserDelegate>)sender
                               timestamp:(NSTimeInterval)timestamp
                         serverMessageId:(NSString *)serverMessageId;

/**
 *  初始化语音类型的消息
 *
 *  @param voicePath        目标语音的本地路径
 *  @param voiceURL         目标语音在服务器的地址
 *  @param voiceDuration    目标语音的时长
 *  @param sender           发送者
 *  @param date             发送时间
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceURL:(NSURL *)voiceURL
                    voiceDuration:(NSString *)voiceDuration
                           senderId:(NSString *)senderId
                            sender:(id<LCCKUserDelegate>)sender
                        timestamp:(NSTimeInterval)timestamp
                  serverMessageId:(NSString *)serverMessageId;

/**
 *  初始化语音类型的消息。增加已读未读标记
 *
 *  @param voicePath        目标语音的本地路径
 *  @param voiceURL         目标语音在服务器的地址
 *  @param voiceDuration    目标语音的时长
 *  @param sender           发送者
 *  @param date             发送时间
 *  @param hasRead           已读未读标记
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceURL:(NSURL *)voiceURL
                    voiceDuration:(NSString *)voiceDuration
                           senderId:(NSString *)senderId
                            sender:(id<LCCKUserDelegate>)sender
                        timestamp:(NSTimeInterval)timestamp
                           hasRead:(BOOL)hasRead
                  serverMessageId:(NSString *)serverMessageId;

- (instancetype)initWithLocalPositionPhoto:(UIImage *)localPositionPhoto
                              geolocations:(NSString *)geolocations
                                  location:(CLLocation *)location
                                    senderId:(NSString *)senderId
                                     sender:(id<LCCKUserDelegate>)sender
                                 timestamp:(NSTimeInterval)timestamp
                           serverMessageId:(NSString *)serverMessageId;

+ (id)messageWithAVIMTypedMessage:(AVIMTypedMessage *)message;

@end
