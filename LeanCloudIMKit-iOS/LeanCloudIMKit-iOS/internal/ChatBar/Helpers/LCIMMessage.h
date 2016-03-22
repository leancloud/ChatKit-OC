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

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, copy) NSString *photoPath;
@property (nonatomic, copy) NSString *thumbnailUrl;
@property (nonatomic, copy) NSString *originPhotoUrl;
@property (nonatomic, strong) UIImage *videoConverPhoto;
@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) NSString *videoUrl;

@property (nonatomic, copy) NSString *voicePath;
@property (nonatomic, copy) NSString *voiceUrl;
@property (nonatomic, copy) NSString *voiceDuration;

@property (nonatomic, copy) NSString *emotionName;
@property (nonatomic, copy) NSString *emotionPath;

@property (nonatomic, strong) UIImage *localPositionPhoto;
@property (nonatomic, copy) NSString *geolocations;
@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, strong) UIImage *avator;
@property (nonatomic, strong) NSURL *avatorURL;

@property (nonatomic, copy) NSString *sender;

@property (nonatomic, strong) NSDate *timestamp;

@property (nonatomic, assign) BOOL sended;

@property (nonatomic, assign) LCIMMessageType messageMediaType;

@property (nonatomic, assign) LCIMMessageChat messageGroupType;

@property (nonatomic, assign) LCIMMessageOwner bubbleMessageType;

@property (nonatomic, assign) LCIMMessageReadState messageReadState;

@property (nonatomic,assign) LCIMMessageSendState status;

@property (nonatomic, assign) BOOL isRead;


/*!
 * just for failed message store, not meaning messageId
 */
@property (nonatomic, copy) NSString *messageId;

@property (nonatomic, copy) NSString *conversationId;

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                   timestamp:(NSDate *)timestamp;


/**
 *  初始化图片类型的消息
 *
 *  @param photo          目标图片
 *  @param photePath      目标图片的本地路径
 *  @param thumbnailUrl   目标图片在服务器的缩略图地址
 *  @param originPhotoUrl 目标图片在服务器的原图地址
 *  @param sender         发送者
 *  @param date           发送时间
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithPhoto:(UIImage *)photo
                    photoPath:(NSString *)photoPath
                 thumbnailUrl:(NSString *)thumbnailUrl
               originPhotoUrl:(NSString *)originPhotoUrl
                       sender:(NSString *)sender
                    timestamp:(NSDate *)timestamp;

/**
 *  初始化视频类型的消息
 *
 *  @param videoConverPhoto 目标视频的封面图
 *  @param videoPath        目标视频的本地路径，如果是下载过，或者是从本地发送的时候，会存在
 *  @param videoUrl         目标视频在服务器上的地址
 *  @param sender           发送者
 *  @param date             发送时间
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithVideoConverPhoto:(UIImage *)videoConverPhoto
                               videoPath:(NSString *)videoPath
                                videoUrl:(NSString *)videoUrl
                                  sender:(NSString *)sender
                               timestamp:(NSDate *)timestamp;

/**
 *  初始化语音类型的消息
 *
 *  @param voicePath        目标语音的本地路径
 *  @param voiceUrl         目标语音在服务器的地址
 *  @param voiceDuration    目标语音的时长
 *  @param sender           发送者
 *  @param date             发送时间
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceUrl:(NSString *)voiceUrl
                    voiceDuration:(NSString *)voiceDuration
                           sender:(NSString *)sender
                        timestamp:(NSDate *)timestamp;

/**
 *  初始化语音类型的消息。增加已读未读标记
 *
 *  @param voicePath        目标语音的本地路径
 *  @param voiceUrl         目标语音在服务器的地址
 *  @param voiceDuration    目标语音的时长
 *  @param sender           发送者
 *  @param date             发送时间
 *  @param isRead           已读未读标记
 *
 *  @return 返回Message model 对象
 */
- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceUrl:(NSString *)voiceUrl
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
