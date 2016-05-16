//
//  LCIMMessage.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCIMMessage.h"
#import "LCIMSessionService.h"

@interface LCIMMessage()

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

@property (nonatomic, assign)  LCIMMessageType messageMediaType;

@property (nonatomic, assign)  LCIMMessageReadState messageReadState;

@property (nonatomic, assign)  BOOL isRead;

@end

@implementation LCIMMessage

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                   timestamp:(NSDate *)timestamp {
    self = [super init];
    if (self) {
        _text = text;
        _sender = sender;
        _timestamp = timestamp;
        _messageMediaType = LCIMMessageTypeText;
    }
    return self;
}

- (instancetype)initWithSystemText:(NSString *)text {
    self = [super init];
    if (self) {
        _systemText = text;
        _messageMediaType = LCIMMessageTypeSystem;
        _bubbleMessageType = LCIMMessageOwnerSystem;
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
        _messageMediaType = LCIMMessageTypeImage;
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
        _messageMediaType = LCIMMessageTypeVideo;
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
        _messageMediaType = LCIMMessageTypeVoice;
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
        _messageMediaType = LCIMMessageTypeEmotion;
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
        
        _messageMediaType = LCIMMessageTypeLocation;
    }
    return self;
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
        //TODO:        _imageSize = imageSize;
//TODO:thumbnailPhoto
        
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
    //TODO:        _imageSize = imageSize;
    //TODO:thumbnailPhoto

}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    LCIMMessage *message;
    switch (self.messageMediaType) {
        case LCIMMessageTypeText: {
            message = [[[self class] allocWithZone:zone] initWithText:[self.text copy]
                                                               sender:[self.sender copy]
                                                            timestamp:[self.timestamp copy]];
            
        }
            break;
        case LCIMMessageTypeImage: {
            message =  [[[self class] allocWithZone:zone] initWithPhoto:[self.photo copy]
                                                         thumbnailPhoto:[self.thumbnailPhoto copy]
                                                              photoPath:[self.photoPath copy]
                                                           thumbnailURL:[self.thumbnailURL copy]
                                                         originPhotoURL:[self.originPhotoURL copy]
                                                                 sender:[self.sender copy]
                                                              timestamp:[self.timestamp copy]];
        }
            break;
        case LCIMMessageTypeVideo: {
            message = [[[self class] allocWithZone:zone] initWithVideoConverPhoto:[self.videoConverPhoto copy]
                                                                        videoPath:[self.videoPath copy]
                                                                         videoURL:[self.videoURL copy]
                                                                           sender:[self.sender copy]
                                                                        timestamp:[self.timestamp copy]];
        }
            break;
        case LCIMMessageTypeVoice: {
            message =  [[[self class] allocWithZone:zone] initWithVoicePath:[self.voicePath copy]
                                                                   voiceURL:[self.voiceURL copy]
                                                              voiceDuration:[self.voiceDuration copy]
                                                                     sender:[self.sender copy]
                                                                  timestamp:[self.timestamp copy]];
        }
            break;
        case LCIMMessageTypeEmotion: {
            message =  [[[self class] allocWithZone:zone] initWithEmotionPath:[self.emotionPath copy]
                                                                  emotionName:[self.emotionName copy]
                                                                       sender:[self.sender copy]
                                                                    timestamp:[self.timestamp copy]];
        }
            break;
        case LCIMMessageTypeLocation: {
            message =  [[[self class] allocWithZone:zone] initWithLocalPositionPhoto:[self.localPositionPhoto copy]
                                                                        geolocations:[self.geolocations copy]
                                                                            location:[self.location copy]
                                                                              sender:[self.sender copy]
                                                                           timestamp:[self.timestamp copy]];
        }
            break;
        case LCIMMessageTypeSystem: {
            message = [[[self class] allocWithZone:zone] initWithSystemText:[self.systemText copy]];
        }
            break;
        case LCIMMessageTypeUnknow: {
            //TODO:
        }
            break;
    }
    message.avator = [self.avator copy];
    message.avatorURL = [self.avatorURL copy];
//    message.photo = [self.photo copy];
//    message.photoPath = [self.photoPath copy];
    //TODO:thumbnailPhoto

    message.messageId = [self.messageId copy];
    message.conversationId = [self.conversationId copy];
    message.messageMediaType = self.messageMediaType;
    message.messageGroupType = self.messageGroupType;
    message.messageReadState = self.messageReadState;
    message.status = self.status;
    return message;
}

@end