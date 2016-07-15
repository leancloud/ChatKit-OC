//
//  LCCKMessage.h
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LCCKConstants.h"
#import "LCCKChatUntiles.h"
#import "LCCKUserDelegate.h"

@class AVIMTypedMessage;

@interface LCCKMessage : NSObject <NSCoding, NSCopying>

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

@property (nonatomic, copy, readonly) NSString *emotionName;
@property (nonatomic, copy, readonly) NSString *emotionPath;

@property (nonatomic, strong, readonly) UIImage *localPositionPhoto;
@property (nonatomic, copy, readonly) NSString *geolocations;
@property (nonatomic, strong, readonly) CLLocation *location;

@property (nonatomic, strong) id<LCCKUserDelegate> user;
/*!
 * 与 user 属性中 clientId 的区别在于，本属性永远不为空，但前者可能为空。
 */
@property (nonatomic, copy) NSString *userId;

@property (nonatomic, assign, readonly) NSTimeInterval timestamp;

@property (nonatomic, assign, readonly) BOOL sended;

@property (nonatomic, assign, readonly) LCCKMessageType messageMediaType;

@property (nonatomic, assign) LCCKConversationType messageGroupType;

@property (nonatomic, assign) LCCKMessageOwner bubbleMessageType;

@property (nonatomic, assign, readonly) LCCKMessageReadState messageReadState;

@property (nonatomic,assign) LCCKMessageSendState status;

@property (nonatomic, assign, readonly) BOOL isRead;


/*!
 * just for failed message store, not meaning messageId
 */
@property (nonatomic, copy, readwrite) NSString *messageId;

@property (nonatomic, copy, readwrite) NSString *conversationId;

- (instancetype)initWithText:(NSString *)text
                      userId:(NSString *)userId
                       user:(id<LCCKUserDelegate>)user
                   timestamp:(NSTimeInterval)timestamp;

- (instancetype)initWithSystemText:(NSString *)text;
+ (instancetype)systemMessageWithTimestamp:(NSTimeInterval)timestamp;
- (NSString *)getTimestampString;
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
                       userId:(NSString *)userId
                       user:(id<LCCKUserDelegate>)user
                    timestamp:(NSTimeInterval)timestamp;

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
                                  userId:(NSString *)userId
                                   user:(id<LCCKUserDelegate>)user
                               timestamp:(NSTimeInterval)timestamp;

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
                           userId:(NSString *)userId
                            user:(id<LCCKUserDelegate>)user
                        timestamp:(NSTimeInterval)timestamp;

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
                           userId:(NSString *)userId
                            user:(id<LCCKUserDelegate>)user
                        timestamp:(NSTimeInterval)timestamp
                           isRead:(BOOL)isRead;

- (instancetype)initWithLocalPositionPhoto:(UIImage *)localPositionPhoto
                              geolocations:(NSString *)geolocations
                                  location:(CLLocation *)location
                                    userId:(NSString *)userId
                                     user:(id<LCCKUserDelegate>)user
                                 timestamp:(NSTimeInterval)timestamp;
// 是否显示时间轴Label
- (BOOL)shouldDisplayTimestampForMessages:(NSArray *)messages;
+ (LCCKMessage *)messageWithAVIMTypedMessage:(AVIMTypedMessage *)message;

@end
