//
//  LCIMMessage.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LCIMConstants.h"
#import "LCIMChatUntiles.h"

@interface LCIMMessage : NSObject <NSCoding, NSCopying>

@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, copy, readonly) NSString *systemText;
@property (nonatomic, strong, readwrite) UIImage *photo;
@property (nonatomic, copy, readonly) NSString *photoPath;
@property (nonatomic, strong, readonly) NSURL *thumbnailURL;
@property (nonatomic, strong, readonly) NSURL *originPhotoURL;
@property (nonatomic, strong, readonly) UIImage *videoConverPhoto;
@property (nonatomic, copy, readonly) NSString *videoPath;
@property (nonatomic, strong, readonly) NSURL *videoURL;

@property (nonatomic, copy, readonly) NSString *voicePath;
@property (nonatomic, strong, readonly) NSURL *voiceURL;
@property (nonatomic, copy, readonly) NSString *voiceDuration;

@property (nonatomic, copy, readonly) NSString *emotionName;
@property (nonatomic, copy, readonly) NSString *emotionPath;

@property (nonatomic, strong, readonly) UIImage *localPositionPhoto;
@property (nonatomic, copy, readonly) NSString *geolocations;
@property (nonatomic, strong, readonly) CLLocation *location;

@property (nonatomic, strong, readwrite) UIImage *avator;
@property (nonatomic, strong, readwrite) NSURL *avatorURL;

@property (nonatomic, copy, readonly) NSString *sender;

@property (nonatomic, strong, readonly) NSDate *timestamp;

@property (nonatomic, assign, readonly) BOOL sended;

@property (nonatomic, assign, readonly) LCIMMessageType messageMediaType;

@property (nonatomic, assign) LCIMConversationType messageGroupType;

@property (nonatomic, assign) LCIMMessageOwner bubbleMessageType;

@property (nonatomic, assign, readonly) LCIMMessageReadState messageReadState;

@property (nonatomic,assign) LCIMMessageSendState status;

@property (nonatomic, assign, readonly) BOOL isRead;


/*!
 * just for failed message store, not meaning messageId
 */
@property (nonatomic, copy, readwrite) NSString *messageId;

@property (nonatomic, copy, readwrite) NSString *conversationId;

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                   timestamp:(NSDate *)timestamp;

- (instancetype)initWithSystemText:(NSString *)text;

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
                    photoPath:(NSString *)photoPath
                 thumbnailURL:(NSURL *)thumbnailURL
               originPhotoURL:(NSURL *)originPhotoURL
                       sender:(NSString *)sender
                    timestamp:(NSDate *)timestamp;

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
                                  sender:(NSString *)sender
                               timestamp:(NSDate *)timestamp;

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
                           sender:(NSString *)sender
                        timestamp:(NSDate *)timestamp;

/**
 *  初始化语音类型的消息。增加已读未读标记
 *
 *  @param voicePath        目标语音的本地路径
 *  @param voiceURL         目标语音在服务器的地址
 *  @param voiceDuration    目标语音的时长
 *  @param sender           发送者
 *  @param date             发送时间
 *  @param isRead           已读未读标记
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceURL:(NSURL *)voiceURL
                    voiceDuration:(NSString *)voiceDuration
                           sender:(NSString *)sender
                        timestamp:(NSDate *)timestamp
                           isRead:(BOOL)isRead;

- (instancetype)initWithEmotionPath:(NSString *)emotionPath
                             sender:(NSString *)sender
                          timestamp:(NSDate *)timestamp;

- (instancetype)initWithEmotionPath:(NSString *)emotionPath
                        emotionName:(NSString *)emotionName
                             sender:(NSString *)sender
                          timestamp:(NSDate *)timestamp;

- (instancetype)initWithLocalPositionPhoto:(UIImage *)localPositionPhoto
                              geolocations:(NSString *)geolocations
                                  location:(CLLocation *)location
                                    sender:(NSString *)sender
                                 timestamp:(NSDate *)timestamp;

@end
