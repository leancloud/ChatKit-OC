//
//  LCCKMessage.m
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/21.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKMessage.h"
#import "LCCKSessionService.h"
#import "LCCKUserSystemService.h"

#if __has_include(<AVOSCloudIM/AVIMTypedMessage.h>)
#import <AVOSCloudIM/AVIMTypedMessage.h>
#else
#import "AVIMTypedMessage.h"
#endif
#import "AVIMConversation+LCCKExtension.h"
#import "UIImage+LCCKExtension.h"
//#define LCCKIsDebugging 1
#import "NSObject+LCCKExtension.h"

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

//@property (nonatomic, copy)  NSString *sender;
//@property (nonatomic, copy) NSString *name;

@property (nonatomic, assign)  AVIMMessageMediaType mediaType;

@property (nonatomic, assign)  LCCKMessageReadState messageReadState;

@property (nonatomic, assign, getter=hasRead) BOOL read;

@end

@implementation LCCKMessage
@synthesize sender = _sender;
@synthesize senderId = _senderId;
@synthesize sendStatus = _sendStatus;
@synthesize conversationId = _conversationId;
@synthesize ownerType = _ownerType;

- (instancetype)initWithText:(NSString *)text
                      senderId:(NSString *)senderId
                        sender:(id<LCCKUserDelegate>)sender
                   timestamp:(NSTimeInterval)timestamp
             serverMessageId:(NSString *)serverMessageId {
    self = [super init];
    if (self) {
        _text = text;
        _sender = sender;
        _senderId = senderId;
        _timestamp = timestamp;
        _serverMessageId = serverMessageId;
        _mediaType = kAVIMMessageMediaTypeText;
    }
    return self;
}

- (NSString *)messageId {
    if (_serverMessageId) {
        return _serverMessageId;
    }
    if (_localMessageId) {
        return _localMessageId;
    }
    return nil;
}

- (BOOL)isLocalMessage {
    if (!_serverMessageId &&_localMessageId) {
        return YES;
    }
    return NO;
}

- (void)setlocalMessageId:(NSString *)localMessageId {
    _localMessageId = localMessageId;
    _timestamp = [localMessageId doubleValue];
}

+ (instancetype)systemMessageWithTimestamp:(NSTimeInterval)time {
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:time / 1000];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
#ifdef LCCKIsDebugging
    //如果定义了LCCKIsDebugging则执行从这里到#endif的代码
    [dateFormatter setDateFormat:@"MM-dd HH:mm:ss"];
#endif
    NSString *text = [dateFormatter stringFromDate:timestamp];
    LCCKMessage *timeMessage = [[LCCKMessage alloc] initWithSystemText:text];
    return timeMessage;
}

- (instancetype)initWithSystemText:(NSString *)text {
    self = [super init];
    if (self) {
        _systemText = text;
        _mediaType = kAVIMMessageMediaTypeSystem;
        _ownerType = LCCKMessageOwnerTypeSystem;
    }
    return self;
}

- (instancetype)initWithLocalFeedbackText:(NSString *)localFeedbackText {
    self = [super init];
    if (self) {
        _systemText = localFeedbackText;
        _localMessageId = [[NSUUID UUID] UUIDString];
        _timestamp = LCCK_CURRENT_TIMESTAMP;
        _mediaType = kAVIMMessageMediaTypeSystem;
        _ownerType = LCCKMessageOwnerTypeSystem;
    }
    return self;
}

+ (instancetype)localFeedbackText:(NSString *)localFeedbackText {
    return [[self alloc] initWithLocalFeedbackText:localFeedbackText];
}

- (instancetype)initWithPhoto:(UIImage *)photo
               thumbnailPhoto:(UIImage *)thumbnailPhoto
                    photoPath:(NSString *)photoPath
                 thumbnailURL:(NSURL *)thumbnailURL
               originPhotoURL:(NSURL *)originPhotoURL
                       senderId:(NSString *)senderId
                         sender:(id<LCCKUserDelegate>)sender
                    timestamp:(NSTimeInterval)timestamp
              serverMessageId:(NSString *)serverMessageId {
    self = [super init];
    if (self) {
        _photo = photo;
        _thumbnailPhoto = thumbnailPhoto;
        _photoPath = photoPath;
        _thumbnailURL = thumbnailURL;
        _originPhotoURL = originPhotoURL;
        _timestamp = timestamp;
        _serverMessageId = serverMessageId;
        _sender = sender;
        _senderId = senderId;
        _mediaType = kAVIMMessageMediaTypeImage;
    }
    return self;
}

- (instancetype)initWithVideoConverPhoto:(UIImage *)videoConverPhoto
                               videoPath:(NSString *)videoPath
                                videoURL:(NSURL *)videoURL
                                  senderId:(NSString *)senderId
                                    sender:(id<LCCKUserDelegate>)sender
                               timestamp:(NSTimeInterval)timestamp
                         serverMessageId:(NSString *)serverMessageId {
    self = [super init];
    if (self) {
        _videoConverPhoto = videoConverPhoto;
        _videoPath = videoPath;
        _videoURL = videoURL;
        _sender = sender;
        _senderId = senderId;
        _timestamp = timestamp;
        _serverMessageId = serverMessageId;
        _mediaType = kAVIMMessageMediaTypeVideo;
    }
    return self;
}

- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceURL:(NSURL *)voiceURL
                    voiceDuration:(NSString *)voiceDuration
                           senderId:(NSString *)senderId
                             sender:(id<LCCKUserDelegate>)sender
                        timestamp:(NSTimeInterval)timestamp
                  serverMessageId:(NSString *)serverMessageId {
    
    return [self initWithVoicePath:voicePath voiceURL:voiceURL voiceDuration:voiceDuration senderId:senderId sender:sender timestamp:timestamp hasRead:YES serverMessageId:serverMessageId];
}

- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceURL:(NSURL *)voiceURL
                    voiceDuration:(NSString *)voiceDuration
                           senderId:(NSString *)senderId
                             sender:(id<LCCKUserDelegate>)sender
                        timestamp:(NSTimeInterval)timestamp
                           hasRead:(BOOL)hasRead
                serverMessageId:(NSString *)serverMessageId {
    self = [super init];
    if (self) {
        _voicePath = voicePath;
        _voiceURL = voiceURL;
        _voiceDuration = voiceDuration;
        _sender = sender;
        _senderId = senderId;
        _timestamp = timestamp;
        _serverMessageId = serverMessageId;
        _read = hasRead;
        _mediaType = kAVIMMessageMediaTypeAudio;
    }
    return self;
}

//- (instancetype)initWithEmotionPath:(NSString *)emotionPath
//                               sender:(id<LCCKUserDelegate>)sender
//                             senderId:(NSString *)senderId
//                          timestamp:(NSTimeInterval)timestamp
//                    serverMessageId:(NSString *)serverMessageId {
//    return [self initWithEmotionPath:emotionPath emotionName:nil senderId:senderId sender:sender timestamp:timestamp serverMessageId:serverMessageId];
//}

//- (instancetype)initWithEmotionPath:(NSString *)emotionPath
//                        emotionName:(NSString *)emotionName
//                             senderId:(NSString *)senderId
//                               sender:(id<LCCKUserDelegate>)sender
//                          timestamp:(NSTimeInterval)timestamp
//                    serverMessageId:(NSString *)serverMessageId {
//    self = [super init];
//    if (self) {
//        _emotionPath = emotionPath;
//        _emotionName = emotionName;
//        _sender = sender;
//        _senderId = senderId;
//        _timestamp = timestamp;
//        _serverMessageId = serverMessageId;
//        _mediaType = LCCKMessageTypeEmotion;
//    }
//    return self;
//}

- (instancetype)initWithLocalPositionPhoto:(UIImage *)localPositionPhoto
                              geolocations:(NSString *)geolocations
                                  location:(CLLocation *)location
                                    senderId:(NSString *)senderId
                                      sender:(id<LCCKUserDelegate>)sender
                                 timestamp:(NSTimeInterval)timestamp
                           serverMessageId:(NSString *)serverMessageId {
    self = [super init];
    if (self) {
        _localPositionPhoto = localPositionPhoto;
        _geolocations = geolocations;
        _location = location;
        _sender = sender;
        _senderId = senderId;
        _timestamp = timestamp;
        _serverMessageId = serverMessageId;
        _mediaType = kAVIMMessageMediaTypeLocation;
    }
    return self;
}

+ (LCCKMessage *)messageWithAVIMTypedMessage:(AVIMTypedMessage *)message {
    //FIXME:自定义消息
    if ([message lcck_isCustomMessage]) {
        if ([message lcck_isSupportThisCustomMessage]) {
            return message;
        }
    }
    NSError *error = nil;
    NSString *senderId = message.clientId;
    id<LCCKUserDelegate> sender = [[LCCKUserSystemService sharedInstance] getProfileForUserId:message.clientId error:&error];
    LCCKMessage *lcckMessage;
    NSTimeInterval time = message.sendTimestamp;
    NSString *serverMessageId = message.messageId;
    //FIXME:
    AVIMMessageMediaType mediaType = message.mediaType;
    switch (mediaType) {
        case kAVIMMessageMediaTypeText: {
            AVIMTextMessage *textMsg = (AVIMTextMessage *)message;
            lcckMessage = [[LCCKMessage alloc] initWithText:textMsg.text senderId:senderId sender:sender timestamp:time serverMessageId:serverMessageId];
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
            lcckMessage = [[LCCKMessage alloc] initWithVoicePath:voicePath voiceURL:nil voiceDuration:duration senderId:senderId sender:sender timestamp:time serverMessageId:serverMessageId];
            break;
        }
            
        case kAVIMMessageMediaTypeLocation: {
            AVIMLocationMessage *locationMsg = (AVIMLocationMessage *)message;
            lcckMessage = [[LCCKMessage alloc] initWithLocalPositionPhoto:({
                NSString *imageName = @"MessageBubble_Location";
                UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
                image;})
                                                             geolocations:locationMsg.text location:[[CLLocation alloc] initWithLatitude:locationMsg.latitude longitude:locationMsg.longitude] senderId:senderId sender:sender timestamp:time serverMessageId:serverMessageId];
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
            lcckMessage = [[LCCKMessage alloc] initWithPhoto:nil thumbnailPhoto:nil photoPath:imagePath thumbnailURL:nil originPhotoURL:[NSURL URLWithString:imageMsg.file.url] senderId:senderId sender:sender timestamp:time serverMessageId:serverMessageId];
            break;
        }
            
            //#import "AVIMEmotionMessage.h"
            //        case kAVIMMessageMediaTypeEmotion: {
            //            AVIMEmotionMessage *emotionMsg = (AVIMEmotionMessage *)message;
            //            NSString *path = [[NSBundle mainBundle] pathForResource:emotionMsg.emotionPath ofType:@"gif"];
            //            lcckMessage = [[LCCKMessage alloc] initWithEmotionPath:path sender:sender timestamp:time];
            //            break;
            //        }
        case kAVIMMessageMediaTypeVideo: {
            //TODO:
            break;
        }
        default: {
            NSString *degradeContent;
            @try {
               degradeContent = [message.attributes objectForKey:LCCKCustomMessageDegradeKey];
            } @catch (NSException *exception) {} @finally {
                if (!degradeContent) {
                    degradeContent = LCCKLocalizedStrings(@"unknownMessage");
                }
            }
            lcckMessage = [[LCCKMessage alloc] initWithText:degradeContent senderId:senderId sender:sender timestamp:time serverMessageId:serverMessageId];
            LCCKLog(@"%@", LCCKLocalizedStrings(@"unknownMessage"));
            break;
        }
    }
    
    if ([[LCCKSessionService sharedInstance].clientId isEqualToString:message.clientId]) {
        lcckMessage.ownerType = LCCKMessageOwnerTypeSelf;
    } else {
        lcckMessage.ownerType = LCCKMessageOwnerTypeOther;
    }
    lcckMessage.sendStatus = message.status;

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
        
        _sender = [aDecoder decodeObjectForKey:@"sender"];
        _senderId = [aDecoder decodeObjectForKey:@"senderId"];
        
        _timestamp = [aDecoder decodeInt64ForKey:@"timestamp"];
        _serverMessageId = [aDecoder decodeObjectForKey:@"serverMessageId"];
        _localMessageId = [aDecoder decodeObjectForKey:@"localMessageId"];
        
        _conversationId = [aDecoder decodeObjectForKey:@"conversationId"];
        _mediaType = [aDecoder decodeIntForKey:@"mediaType"];
//        _messageGroupType = [aDecoder decodeIntForKey:@"messageGroupType"];
        _messageReadState = [aDecoder decodeIntForKey:@"messageReadState"];
        _ownerType = [aDecoder decodeIntForKey:@"ownerType"];
        _read = [aDecoder decodeBoolForKey:@"read"];
        _sendStatus = [aDecoder decodeIntForKey:@"sendStatus"];
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
    [aCoder encodeObject:self.sender forKey:@"sender"];
    [aCoder encodeObject:self.senderId forKey:@"senderId"];
    
    [aCoder encodeInt64:self.timestamp forKey:@"timestamp"];
    [aCoder encodeObject:self.serverMessageId forKey:@"serverMessageId"];
    [aCoder encodeObject:self.localMessageId forKey:@"localMessageId"];
    
    [aCoder encodeObject:self.conversationId forKey:@"conversationId"];
    [aCoder encodeInt:self.mediaType forKey:@"mediaType"];
//    [aCoder encodeInt:self.messageGroupType forKey:@"messageGroupType"];
    [aCoder encodeInt:self.messageReadState forKey:@"messageReadState"];
    [aCoder encodeInt:self.ownerType forKey:@"ownerType"];
    [aCoder encodeBool:self.read forKey:@"read"];
    [aCoder encodeInt:self.sendStatus forKey:@"sendStatus"];
    [aCoder encodeObject:self.photoPath forKey:@"photoPath"];
    [aCoder encodeObject:self.thumbnailPhoto forKey:@"thumbnailPhoto"];
    
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    LCCKMessage *message;
    switch (self.mediaType) {
        case kAVIMMessageMediaTypeText: {
            message = [[[self class] allocWithZone:zone] initWithText:[self.text copy]
                                                               senderId:[self.senderId copy]
                                                                 sender:[self.sender copyWithZone:nil]
                                                            timestamp:self.timestamp
                                                      serverMessageId:[self.serverMessageId copy]];
            
        }
            break;
        case kAVIMMessageMediaTypeImage: {
            message =  [[[self class] allocWithZone:zone] initWithPhoto:[self.photo copy]
                                                         thumbnailPhoto:[self.thumbnailPhoto copy]
                                                              photoPath:[self.photoPath copy]
                                                           thumbnailURL:[self.thumbnailURL copy]
                                                         originPhotoURL:[self.originPhotoURL copy]
                                                                 senderId:[self.senderId copy]
                                                                   sender:[self.sender copyWithZone:nil]
                                                              timestamp:self.timestamp
                                                        serverMessageId:[self.serverMessageId copy]];

        }
            break;
        case kAVIMMessageMediaTypeVideo: {
            message = [[[self class] allocWithZone:zone] initWithVideoConverPhoto:[self.videoConverPhoto copy]
                                                                        videoPath:[self.videoPath copy]
                                                                         videoURL:[self.videoURL copy]
                                                                           senderId:[self.senderId copy]
                                                                             sender:[self.sender copyWithZone:nil]
                                                                        timestamp:self.timestamp
                                                                  serverMessageId:[self.serverMessageId copy]];

        }
            break;
        case kAVIMMessageMediaTypeAudio: {
            message =  [[[self class] allocWithZone:zone] initWithVoicePath:[self.voicePath copy]
                                                                   voiceURL:[self.voiceURL copy]
                                                              voiceDuration:[self.voiceDuration copy]
                                                                     senderId:[self.senderId copy]
                                                                       sender:[self.sender copyWithZone:nil]
                                                                  timestamp:self.timestamp
                                                            serverMessageId:[self.serverMessageId copy]];

        }
            break;
//        case LCCKMessageTypeEmotion: {
//            message =  [[[self class] allocWithZone:zone] initWithEmotionPath:[self.emotionPath copy]
//                                                                  emotionName:[self.emotionName copy]
//                                                                       senderId:[self.senderId copy]
//                                                                         sender:[self.sender copyWithZone:nil]
//                                                                    timestamp:self.timestamp
//                                                              serverMessageId:[self.serverMessageId copy]];
//
//        }
//            break;
        case kAVIMMessageMediaTypeLocation: {
            message =  [[[self class] allocWithZone:zone] initWithLocalPositionPhoto:[self.localPositionPhoto copy]
                                                                        geolocations:[self.geolocations copy]
                                                                            location:[self.location copy]
                                                                              senderId:[self.senderId copy]
                                                                                sender:[self.sender copyWithZone:nil]
                                                                           timestamp:self.timestamp
                                                                     serverMessageId:[self.serverMessageId copy]];
        }
            break;
        case kAVIMMessageMediaTypeSystem: {
            message = [[[self class] allocWithZone:zone] initWithSystemText:[self.systemText copy]];
        }
            break;
        case kAVIMMessageMediaTypeNone: {
            //TODO:
        }
            break;
    }
    //    message.photo = [self.photo copy];
    //    message.photoPath = [self.photoPath copy];
    
    message.localMessageId = [self.localMessageId copy];
    message.conversationId = [self.conversationId copy];
    message.mediaType = self.mediaType;
//    message.messageGroupType = self.messageGroupType;
    message.messageReadState = self.messageReadState;
    message.sendStatus = self.sendStatus;
    message.read = self.read;
    return message;
}

@end