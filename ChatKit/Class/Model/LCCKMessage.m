//
//  LCCKMessage.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKMessage.h"
#import "LCCKSessionService.h"
#import "LCCKUserSystemService.h"

#if __has_include(<AVOSCloudIM/AVIMTypedMessage.h>)
#import <AVOSCloudIM/AVIMTypedMessage.h>
#else
#import "AVIMTypedMessage.h"
#endif
#import "AVIMConversation+LCCKAddition.h"
#import "UIImage+LCCKExtension.h"

@interface LCCKMessage()

@property (nonatomic, copy)  NSString *text;
@property (nonatomic, copy) NSString *systemText;
@property (nonatomic, copy)  NSString *photoPath;
@property (nonatomic, strong)  NSURL *thumbnailURL;
@property (nonatomic, strong)  NSURL *originPhotoURL;
@property (nonatomic, strong)  UIImage *videoConverPhoto;
@property (nonatomic, copy)  NSString *videoPath;
@property (nonatomic, strong)  NSURL *videoURL;

@property (nonatomic, copy)  NSString *voicePath;
@property (nonatomic, strong)  NSURL *voiceURL;
@property (nonatomic, copy)  NSString *voiceDuration;

@property (nonatomic, copy)  NSString *emotionName;
@property (nonatomic, copy)  NSString *emotionPath;

@property (nonatomic, strong)  UIImage *localPositionPhoto;
@property (nonatomic, copy)  NSString *geolocations;
@property (nonatomic, strong)  CLLocation *location;

@property (nonatomic, copy)  NSString *sender;

@property (nonatomic, strong)  NSDate *timestamp;

@property (nonatomic, assign)  BOOL sended;

@property (nonatomic, assign)  LCCKMessageType messageMediaType;

@property (nonatomic, assign)  LCCKMessageReadState messageReadState;

@property (nonatomic, assign)  BOOL isRead;

@end

@implementation LCCKMessage

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                   timestamp:(NSDate *)timestamp {
    self = [super init];
    if (self) {
        _text = text;
        _sender = sender;
        _timestamp = timestamp;
        _messageMediaType = LCCKMessageTypeText;
    }
    return self;
}

+ (instancetype)systemMessageWithTimestamp:(NSDate *)timestamp {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    NSString *text = [dateFormatter stringFromDate:timestamp];
    LCCKMessage *timeMessage = [[LCCKMessage alloc] initWithSystemText:text];
    return timeMessage;
}

- (instancetype)initWithSystemText:(NSString *)text {
    self = [super init];
    if (self) {
        _systemText = text;
        _messageMediaType = LCCKMessageTypeSystem;
        _bubbleMessageType = LCCKMessageOwnerSystem;
    }
    return self;
}

- (instancetype)initWithPhoto:(UIImage *)photo
               thumbnailPhoto:(UIImage *)thumbnailPhoto
                    photoPath:(NSString *)photoPath
                 thumbnailURL:(NSURL *)thumbnailURL
               originPhotoURL:(NSURL *)originPhotoURL
                       sender:(NSString *)sender
                    timestamp:(NSDate *)timestamp {
    self = [super init];
    if (self) {
        _photo = photo;
        _thumbnailPhoto = thumbnailPhoto;
        _photoPath = photoPath;
        _thumbnailURL = thumbnailURL;
        _originPhotoURL = originPhotoURL;
        _sender = sender;
        _timestamp = timestamp;
        _messageMediaType = LCCKMessageTypeImage;
    }
    return self;
}

- (instancetype)initWithVideoConverPhoto:(UIImage *)videoConverPhoto
                               videoPath:(NSString *)videoPath
                                videoURL:(NSURL *)videoURL
                                  sender:(NSString *)sender
                               timestamp:(NSDate *)timestamp{
    self = [super init];
    if (self) {
        _videoConverPhoto = videoConverPhoto;
        _videoPath = videoPath;
        _videoURL = videoURL;
        _sender = sender;
        _timestamp = timestamp;
        _messageMediaType = LCCKMessageTypeVideo;
    }
    return self;
}

- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceURL:(NSURL *)voiceURL
                    voiceDuration:(NSString *)voiceDuration
                           sender:(NSString *)sender
                        timestamp:(NSDate *)timestamp{
    
    return [self initWithVoicePath:voicePath voiceURL:voiceURL voiceDuration:voiceDuration sender:sender timestamp:timestamp isRead:YES];
}

- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceURL:(NSURL *)voiceURL
                    voiceDuration:(NSString *)voiceDuration
                           sender:(NSString *)sender
                        timestamp:(NSDate *)timestamp
                           isRead:(BOOL)isRead{
    self = [super init];
    if (self) {
        _voicePath = voicePath;
        _voiceURL = voiceURL;
        _voiceDuration = voiceDuration;
        
        _sender = sender;
        _timestamp = timestamp;
        _isRead = isRead;
        _messageMediaType = LCCKMessageTypeVoice;
    }
    return self;
}

- (instancetype)initWithEmotionPath:(NSString *)emotionPath
                             sender:(NSString *)sender
                          timestamp:(NSDate *)timestamp {
    return [self initWithEmotionPath:emotionPath emotionName:nil sender:sender timestamp:timestamp];
}

- (instancetype)initWithEmotionPath:(NSString *)emotionPath
                        emotionName:(NSString *)emotionName
                             sender:(NSString *)sender
                          timestamp:(NSDate *)timestamp {
    self = [super init];
    if (self) {
        _emotionPath = emotionPath;
        _emotionName = emotionName;
        _sender = sender;
        _timestamp = timestamp;
        _messageMediaType = LCCKMessageTypeEmotion;
    }
    return self;
}

- (instancetype)initWithLocalPositionPhoto:(UIImage *)localPositionPhoto
                              geolocations:(NSString *)geolocations
                                  location:(CLLocation *)location
                                    sender:(NSString *)sender
                                 timestamp:(NSDate *)timestamp{
    self = [super init];
    if (self) {
        _localPositionPhoto = localPositionPhoto;
        _geolocations = geolocations;
        _location = location;
        
        _sender = sender;
        _timestamp = timestamp;
        
        _messageMediaType = LCCKMessageTypeLocation;
    }
    return self;
}

// 是否显示时间轴Label
- (BOOL)shouldDisplayTimestampForMessages:(NSArray *)messages {
    BOOL containsMessage= [messages containsObject:self];
    if (!containsMessage) {
        return NO;
    }
    NSUInteger index = [messages indexOfObject:self];
    if (index == 0) {
        return YES;
    }  else {
        LCCKMessage *lastMessage = [messages objectAtIndex:index - 1];
        int interval = [self.timestamp timeIntervalSinceDate:lastMessage.timestamp];
        if (interval > 60 * 3) {
            return YES;
        } else {
            return NO;
        }
    }
}

+ (NSDate *)getTimestampDate:(int64_t)timestamp {
    return [NSDate dateWithTimeIntervalSince1970:timestamp / 1000];
}

+ (LCCKMessage *)messageWithAVIMTypedMessage:(AVIMTypedMessage *)message {
    id<LCCKUserModelDelegate> fromUser = [[LCCKUserSystemService sharedInstance] getProfileForUserId:message.clientId error:nil];
    LCCKMessage *lcckMessage;
    NSDate *time = [self getTimestampDate:message.sendTimestamp];
    //FIXME:
    AVIMMessageMediaType mediaType = message.mediaType;
    switch (mediaType) {
        case kAVIMMessageMediaTypeText: {
            AVIMTextMessage *textMsg = (AVIMTextMessage *)message;
            lcckMessage = [[LCCKMessage alloc] initWithText:textMsg.text sender:fromUser.name timestamp:time];
            break;
        }
        case kAVIMMessageMediaTypeAudio: {
            AVIMAudioMessage *audioMsg = (AVIMAudioMessage *)message;
            NSString *duration = [NSString stringWithFormat:@"%.0f", audioMsg.duration];
            NSString *voicePath;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *pathForFile = audioMsg.file.localPath;
            if ([fileManager fileExistsAtPath:pathForFile]){
                voicePath = audioMsg.file.localPath;
            } else {
                voicePath = audioMsg.file.url;
            }
            lcckMessage = [[LCCKMessage alloc] initWithVoicePath:voicePath voiceURL:nil voiceDuration:duration sender:fromUser.name timestamp:time];
            break;
        }
            
        case kAVIMMessageMediaTypeLocation: {
            AVIMLocationMessage *locationMsg = (AVIMLocationMessage *)message;
            lcckMessage = [[LCCKMessage alloc] initWithLocalPositionPhoto:({
                NSString *imageName = @"MessageBubble_Location";
                UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
                image;})
                                                             geolocations:locationMsg.text location:[[CLLocation alloc] initWithLatitude:locationMsg.latitude longitude:locationMsg.longitude] sender:fromUser.name timestamp:time];
            break;
        }
        case kAVIMMessageMediaTypeImage: {
            AVIMImageMessage *imageMsg = (AVIMImageMessage *)message;
            NSString *pathForFile = imageMsg.file.localPath;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *imagePath;
            if ([fileManager fileExistsAtPath:pathForFile]){
                imagePath = imageMsg.file.localPath;
            }
            lcckMessage = [[LCCKMessage alloc] initWithPhoto:nil thumbnailPhoto:nil photoPath:imagePath thumbnailURL:nil originPhotoURL:[NSURL URLWithString:imageMsg.file.url] sender:fromUser.name timestamp:time];
            break;
        }
            
            //#import "AVIMEmotionMessage.h"
            //        case kAVIMMessageMediaTypeEmotion: {
            //            AVIMEmotionMessage *emotionMsg = (AVIMEmotionMessage *)message;
            //            NSString *path = [[NSBundle mainBundle] pathForResource:emotionMsg.emotionPath ofType:@"gif"];
            //            lcckMessage = [[LCCKMessage alloc] initWithEmotionPath:path sender:fromUser.name timestamp:time];
            //            break;
            //        }
        case kAVIMMessageMediaTypeVideo: {
            //TODO:
            break;
        }
        default: {
            lcckMessage = [[LCCKMessage alloc] initWithText:@"未知消息" sender:fromUser.name timestamp:time];
            LCCKLog("unkonwMessage");
            break;
        }
    }
    [[LCCKConversationService sharedInstance] fecthConversationWithConversationId:message.conversationId callback:^(AVIMConversation *conversation, NSError *error) {
        lcckMessage.messageGroupType = conversation.lcck_type;
    }];
    lcckMessage.avator = nil;
    lcckMessage.avatorURL = [fromUser avatorURL];
    
    if ([[LCCKSessionService sharedInstance].clientId isEqualToString:message.clientId]) {
        lcckMessage.bubbleMessageType = LCCKMessageOwnerSelf;
    } else {
        lcckMessage.bubbleMessageType = LCCKMessageOwnerOther;
    }
    
    NSInteger msgStatuses[4] = { AVIMMessageStatusSending, AVIMMessageStatusSent, AVIMMessageStatusDelivered, AVIMMessageStatusFailed };
    NSInteger lcckMessageStatuses[4] = { LCCKMessageSendStateSending, LCCKMessageSendStateSuccess, LCCKMessageSendStateReceived, LCCKMessageSendStateFailed };
    
    if (lcckMessage.bubbleMessageType == LCCKMessageOwnerSelf) {
        LCCKMessageSendState status = LCCKMessageSendStateReceived;
        int i;
        for (i = 0; i < 4; i++) {
            if (msgStatuses[i] == message.status) {
                status = lcckMessageStatuses[i];
                break;
            }
        }
        lcckMessage.status = status;
    } else {
        lcckMessage.status = LCCKMessageSendStateReceived;
    }
    return lcckMessage;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        
        _text = [aDecoder decodeObjectForKey:@"text"];
        _systemText = [aDecoder decodeObjectForKey:@"systemText"];
        
        _photo = [aDecoder decodeObjectForKey:@"photo"];
        _thumbnailURL = [aDecoder decodeObjectForKey:@"thumbnailURL"];
        _originPhotoURL = [aDecoder decodeObjectForKey:@"originPhotoURL"];
        
        _videoConverPhoto = [aDecoder decodeObjectForKey:@"videoConverPhoto"];
        _videoPath = [aDecoder decodeObjectForKey:@"videoPath"];
        _videoURL = [aDecoder decodeObjectForKey:@"videoURL"];
        
        _voicePath = [aDecoder decodeObjectForKey:@"voicePath"];
        _voiceURL = [aDecoder decodeObjectForKey:@"voiceURL"];
        _voiceDuration = [aDecoder decodeObjectForKey:@"voiceDuration"];
        
        _emotionPath = [aDecoder decodeObjectForKey:@"emotionPath"];
        
        _localPositionPhoto = [aDecoder decodeObjectForKey:@"localPositionPhoto"];
        _geolocations = [aDecoder decodeObjectForKey:@"geolocations"];
        _location = [aDecoder decodeObjectForKey:@"location"];
        
        _avator = [aDecoder decodeObjectForKey:@"avator"];
        _avatorURL = [aDecoder decodeObjectForKey:@"avatorURL"];
        
        _sender = [aDecoder decodeObjectForKey:@"sender"];
        _timestamp = [aDecoder decodeObjectForKey:@"timestamp"];
        _messageId = [aDecoder decodeObjectForKey:@"messageId"];
        _conversationId = [aDecoder decodeObjectForKey:@"conversationId"];
        _messageMediaType = [aDecoder decodeIntForKey:@"messageMediaType"];
        _messageGroupType = [aDecoder decodeIntForKey:@"messageGroupType"];
        _messageReadState = [aDecoder decodeIntForKey:@"messageReadState"];
        
        _status = [aDecoder decodeIntForKey:@"status"];
        _photoPath = [aDecoder decodeObjectForKey:@"photoPath"];
        _thumbnailPhoto = [aDecoder decodeObjectForKey:@"thumbnailPhoto"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.systemText forKey:@"systemText"];
    
    [aCoder encodeObject:self.photo forKey:@"photo"];
    [aCoder encodeObject:self.thumbnailURL forKey:@"thumbnailURL"];
    [aCoder encodeObject:self.originPhotoURL forKey:@"originPhotoURL"];
    
    [aCoder encodeObject:self.videoConverPhoto forKey:@"videoConverPhoto"];
    [aCoder encodeObject:self.videoPath forKey:@"videoPath"];
    [aCoder encodeObject:self.videoURL forKey:@"videoURL"];
    
    [aCoder encodeObject:self.voicePath forKey:@"voicePath"];
    [aCoder encodeObject:self.voiceURL forKey:@"voiceURL"];
    [aCoder encodeObject:self.voiceDuration forKey:@"voiceDuration"];
    
    [aCoder encodeObject:self.emotionPath forKey:@"emotionPath"];
    
    [aCoder encodeObject:self.localPositionPhoto forKey:@"localPositionPhoto"];
    [aCoder encodeObject:self.geolocations forKey:@"geolocations"];
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.avator forKey:@"avator"];
    [aCoder encodeObject:self.avatorURL forKey:@"avatorURL"];
    [aCoder encodeObject:self.sender forKey:@"sender"];
    [aCoder encodeObject:self.timestamp forKey:@"timestamp"];
    [aCoder encodeObject:self.messageId forKey:@"messageId"];
    [aCoder encodeObject:self.conversationId forKey:@"conversationId"];
    [aCoder encodeInt:self.messageMediaType forKey:@"messageMediaType"];
    [aCoder encodeInt:self.messageGroupType forKey:@"messageGroupType"];
    [aCoder encodeInt:self.messageReadState forKey:@"messageReadState"];
    
    [aCoder encodeInt:self.status forKey:@"status"];
    [aCoder encodeObject:self.photoPath forKey:@"photoPath"];
    [aCoder encodeObject:self.thumbnailPhoto forKey:@"thumbnailPhoto"];
    
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    LCCKMessage *message;
    switch (self.messageMediaType) {
        case LCCKMessageTypeText: {
            message = [[[self class] allocWithZone:zone] initWithText:[self.text copy]
                                                               sender:[self.sender copy]
                                                            timestamp:[self.timestamp copy]];
            
        }
            break;
        case LCCKMessageTypeImage: {
            message =  [[[self class] allocWithZone:zone] initWithPhoto:[self.photo copy]
                                                         thumbnailPhoto:[self.thumbnailPhoto copy]
                                                              photoPath:[self.photoPath copy]
                                                           thumbnailURL:[self.thumbnailURL copy]
                                                         originPhotoURL:[self.originPhotoURL copy]
                                                                 sender:[self.sender copy]
                                                              timestamp:[self.timestamp copy]];
        }
            break;
        case LCCKMessageTypeVideo: {
            message = [[[self class] allocWithZone:zone] initWithVideoConverPhoto:[self.videoConverPhoto copy]
                                                                        videoPath:[self.videoPath copy]
                                                                         videoURL:[self.videoURL copy]
                                                                           sender:[self.sender copy]
                                                                        timestamp:[self.timestamp copy]];
        }
            break;
        case LCCKMessageTypeVoice: {
            message =  [[[self class] allocWithZone:zone] initWithVoicePath:[self.voicePath copy]
                                                                   voiceURL:[self.voiceURL copy]
                                                              voiceDuration:[self.voiceDuration copy]
                                                                     sender:[self.sender copy]
                                                                  timestamp:[self.timestamp copy]];
        }
            break;
        case LCCKMessageTypeEmotion: {
            message =  [[[self class] allocWithZone:zone] initWithEmotionPath:[self.emotionPath copy]
                                                                  emotionName:[self.emotionName copy]
                                                                       sender:[self.sender copy]
                                                                    timestamp:[self.timestamp copy]];
        }
            break;
        case LCCKMessageTypeLocation: {
            message =  [[[self class] allocWithZone:zone] initWithLocalPositionPhoto:[self.localPositionPhoto copy]
                                                                        geolocations:[self.geolocations copy]
                                                                            location:[self.location copy]
                                                                              sender:[self.sender copy]
                                                                           timestamp:[self.timestamp copy]];
        }
            break;
        case LCCKMessageTypeSystem: {
            message = [[[self class] allocWithZone:zone] initWithSystemText:[self.systemText copy]];
        }
            break;
        case LCCKMessageTypeUnknow: {
            //TODO:
        }
            break;
    }
    message.avator = [self.avator copy];
    message.avatorURL = [self.avatorURL copy];
    //    message.photo = [self.photo copy];
    //    message.photoPath = [self.photoPath copy];
    
    message.messageId = [self.messageId copy];
    message.conversationId = [self.conversationId copy];
    message.messageMediaType = self.messageMediaType;
    message.messageGroupType = self.messageGroupType;
    message.messageReadState = self.messageReadState;
    message.status = self.status;
    return message;
}

@end