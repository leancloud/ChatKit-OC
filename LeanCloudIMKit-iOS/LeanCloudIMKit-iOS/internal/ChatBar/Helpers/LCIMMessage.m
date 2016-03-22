//
//  LCIMMessage.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import "LCIMMessage.h"

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

- (instancetype)initWithPhoto:(UIImage *)photo
                    photoPath:(NSString *)photoPath
                 thumbnailUrl:(NSString *)thumbnailUrl
               originPhotoUrl:(NSString *)originPhotoUrl
                       sender:(NSString *)sender
                    timestamp:(NSDate *)timestamp {
    self = [super init];
    if (self) {
        _photo = photo;
        _photoPath = photoPath;
        _thumbnailUrl = thumbnailUrl;
        _originPhotoUrl = originPhotoUrl;
        _sender = sender;
        _timestamp = timestamp;
        _messageMediaType = LCIMMessageTypeImage;
    }
    return self;
}

- (instancetype)initWithVideoConverPhoto:(UIImage *)videoConverPhoto
                               videoPath:(NSString *)videoPath
                                videoUrl:(NSString *)videoUrl
                                  sender:(NSString *)sender
                               timestamp:(NSDate *)timestamp{
    self = [super init];
    if (self) {
        _videoConverPhoto = videoConverPhoto;
        _videoPath = videoPath;
        _videoUrl = videoUrl;
        _sender = sender;
        _timestamp = timestamp;
        _messageMediaType = LCIMMessageTypeVideo;
    }
    return self;
}

- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceUrl:(NSString *)voiceUrl
                    voiceDuration:(NSString *)voiceDuration
                           sender:(NSString *)sender
                        timestamp:(NSDate *)timestamp{
    
    return [self initWithVoicePath:voicePath voiceUrl:voiceUrl voiceDuration:voiceDuration sender:sender timestamp:timestamp isRead:YES];
}

- (instancetype)initWithVoicePath:(NSString *)voicePath
                         voiceUrl:(NSString *)voiceUrl
                    voiceDuration:(NSString *)voiceDuration
                           sender:(NSString *)sender
                        timestamp:(NSDate *)timestamp
                           isRead:(BOOL)isRead{
    self = [super init];
    if (self) {
        _voicePath = voicePath;
        _voiceUrl = voiceUrl;
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
        
        _photo = [aDecoder decodeObjectForKey:@"photo"];
        _thumbnailUrl = [aDecoder decodeObjectForKey:@"thumbnailUrl"];
        _originPhotoUrl = [aDecoder decodeObjectForKey:@"originPhotoUrl"];
        
        _videoConverPhoto = [aDecoder decodeObjectForKey:@"videoConverPhoto"];
        _videoPath = [aDecoder decodeObjectForKey:@"videoPath"];
        _videoUrl = [aDecoder decodeObjectForKey:@"videoUrl"];
        
        _voicePath = [aDecoder decodeObjectForKey:@"voicePath"];
        _voiceUrl = [aDecoder decodeObjectForKey:@"voiceUrl"];
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
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.text forKey:@"text"];
    
    [aCoder encodeObject:self.photo forKey:@"photo"];
    [aCoder encodeObject:self.thumbnailUrl forKey:@"thumbnailUrl"];
    [aCoder encodeObject:self.originPhotoUrl forKey:@"originPhotoUrl"];
    
    [aCoder encodeObject:self.videoConverPhoto forKey:@"videoConverPhoto"];
    [aCoder encodeObject:self.videoPath forKey:@"videoPath"];
    [aCoder encodeObject:self.videoUrl forKey:@"videoUrl"];
    
    [aCoder encodeObject:self.voicePath forKey:@"voicePath"];
    [aCoder encodeObject:self.voiceUrl forKey:@"voiceUrl"];
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
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    LCIMMessage *message;
    switch (self.messageMediaType) {
        case LCIMMessageTypeText:
            message = [[[self class] allocWithZone:zone] initWithText:[self.text copy]
                                                               sender:[self.sender copy]
                                                            timestamp:[self.timestamp copy]];
        case LCIMMessageTypeImage:
            message =  [[[self class] allocWithZone:zone] initWithPhoto:[self.photo copy]
                                                              photoPath:[self.photoPath copy]
                                                           thumbnailUrl:[self.thumbnailUrl copy]
                                                         originPhotoUrl:[self.originPhotoUrl copy]
                                                                 sender:[self.sender copy]
                                                              timestamp:[self.timestamp copy]];
        case LCIMMessageTypeVideo:
            message = [[[self class] allocWithZone:zone] initWithVideoConverPhoto:[self.videoConverPhoto copy]
                                                                        videoPath:[self.videoPath copy]
                                                                         videoUrl:[self.videoUrl copy]
                                                                           sender:[self.sender copy]
                                                                        timestamp:[self.timestamp copy]];
        case LCIMMessageTypeVoice:
            message =  [[[self class] allocWithZone:zone] initWithVoicePath:[self.voicePath copy]
                                                                   voiceUrl:[self.voiceUrl copy]
                                                              voiceDuration:[self.voiceDuration copy]
                                                                     sender:[self.sender copy]
                                                                  timestamp:[self.timestamp copy]];
        case LCIMMessageTypeEmotion:
            message =  [[[self class] allocWithZone:zone] initWithEmotionPath:[self.emotionPath copy]
                                                                  emotionName:[self.emotionName copy]
                                                                       sender:[self.sender copy]
                                                                    timestamp:[self.timestamp copy]];
        case LCIMMessageTypeLocation:
            message =  [[[self class] allocWithZone:zone] initWithLocalPositionPhoto:[self.localPositionPhoto copy]
                                                                        geolocations:[self.geolocations copy]
                                                                            location:[self.location copy]
                                                                              sender:[self.sender copy]
                                                                           timestamp:[self.timestamp copy]];
            case LCIMMessageTypeSystem:
            case LCIMMessageTypeUnknow:
            //TODO:
            break;
    }
    message.avator = [self.avator copy];
    message.avatorURL = [self.avatorURL copy];
    message.photo = [self.photo copy];
    message.photoPath = [self.photoPath copy];
    message.messageId = [self.messageId copy];
    message.conversationId = [self.conversationId copy];
    message.messageMediaType = self.messageMediaType;
    message.messageGroupType = self.messageGroupType;
    message.messageReadState = self.messageReadState;
    message.status = self.status;
    return message;
}

@end