//
//  AVIMTypedMessage.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/8/15.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>

#import "AVIMTypedMessage.h"
#import "AVIMTypedMessage_Internal.h"
#import "AVIMGeneralObject.h"
#import "AVIMMessage_Internal.h"

NSMutableDictionary const *_typeDict = nil;

@interface AVFile ()

+(AVFile *)fileFromDictionary:(NSDictionary *)dict;
+(NSDictionary *)dictionaryFromFile:(AVFile *)file;

@end

@interface AVGeoPoint ()

+(NSDictionary *)dictionaryFromGeoPoint:(AVGeoPoint *)point;
+(AVGeoPoint *)geoPointFromDictionary:(NSDictionary *)dict;

@end

@implementation AVIMTypedMessage

@synthesize file = _file;
@synthesize location = _location;

//+ (instancetype)messageWithText:(NSString *)text
//                      mediaType:(AVIMMessageMediaType)mediaType
//                  attachmentUrl:(NSString *)attachmentUrl {
//    return [self messageWithText:text mediaType:mediaType attachmentUrl:attachmentUrl attributes:nil];
//}
//
//+ (instancetype)messageWithText:(NSString *)text
//                      mediaType:(AVIMMessageMediaType)mediaType
//                  attachmentUrl:(NSString *)attachmentUrl
//                     attributes:(NSDictionary *)attributes {
//    AVIMTypedMessage *message = [[self alloc] init];
//    message.text = text;
//    message.mediaType = mediaType;
//    message.attachmentUrl = attachmentUrl;
//    message.attributes = attributes;
//    message.ioType = AVIMMessageIOTypeOut;
//    return message;
//}
//
//+ (instancetype)messageWithText:(NSString *)text
//                      mediaType:(AVIMMessageMediaType)mediaType
//                           data:(NSData *)data {
//    return [self messageWithText:text mediaType:mediaType data:data attributes:nil];
//}
//
//+ (instancetype)messageWithText:(NSString *)text
//                      mediaType:(AVIMMessageMediaType)mediaType
//                           data:(NSData *)data
//                     attributes:(NSDictionary *)attributes {
//    AVIMTypedMessage *message = [[self alloc] init];
//    message.text = text;
//    message.mediaType = mediaType;
//    message.attributes = attributes;
//    message.ioType = AVIMMessageIOTypeOut;
//    message.data = data;
//    return message;
//}

+ (void)registerSubclass {
    if ([self conformsToProtocol:@protocol(AVIMTypedMessageSubclassing)]) {
        Class<AVIMTypedMessageSubclassing> class = self;
        AVIMMessageMediaType mediaType = [class classMediaType];
        [self registerClass:class forMediaType:mediaType];
    }
}

+ (Class)classForMediaType:(AVIMMessageMediaType)mediaType {
    Class class = [_typeDict objectForKey:@(mediaType)];
    if (!class) {
        class = [AVIMTypedMessage class];
    }
    return class;
}

+ (void)registerClass:(Class)class forMediaType:(AVIMMessageMediaType)mediaType {
    if (!_typeDict) {
        _typeDict = [[NSMutableDictionary alloc] init];
    }
    Class c = [_typeDict objectForKey:@(mediaType)];
    if (!c || [class isSubclassOfClass:c]) {
        [_typeDict setObject:class forKey:@(mediaType)];
    }
}

+ (instancetype)messageWithText:(NSString *)text
                      mediaType:(AVIMMessageMediaType)mediaType
               attachedFilePath:(NSString *)attachedFilePath
                     attributes:(NSDictionary *)attributes {
    AVIMTypedMessage *message = [[self alloc] init];
    message.text = text;
    message.mediaType = mediaType;
    message.attributes = attributes;
    message.attachedFilePath = attachedFilePath;
    return message;
}

+ (instancetype)messageWithText:(NSString *)text
               attachedFilePath:(NSString *)attachedFilePath
                     attributes:(NSDictionary *)attributes {
    AVIMTypedMessage *message = [[self alloc] init];
    message.text = text;
    message.attributes = attributes;
    message.attachedFilePath = attachedFilePath;
    return message;
}

+ (instancetype)messageWithText:(NSString *)text
                           file:(AVFile *)file
                     attributes:(NSDictionary *)attributes {
    AVIMTypedMessage *message = [[self alloc] init];
    message.text = text;
    message.attributes = attributes;
    message.file = file;
    return message;
}

+ (AVFile *)fileFromDictionary:(NSDictionary *)dictionary {
    return dictionary ? [AVFile fileFromDictionary:dictionary] : nil;
}

+ (AVGeoPoint *)locationFromDictionary:(NSDictionary *)dictionary {
    if (dictionary) {
        AVIMGeneralObject *object = [[AVIMGeneralObject alloc] initWithDictionary:dictionary];
        AVGeoPoint *location = [AVGeoPoint geoPointWithLatitude:object.latitude longitude:object.longitude];
        return location;
    } else {
        return nil;
    }
}

+ (instancetype)messageWithMessageObject:(AVIMTypedMessageObject *)messageObject {
    AVIMMessageMediaType mediaType = messageObject._lctype;
    Class class = [self classForMediaType:mediaType];
    AVIMTypedMessage *message = [[class alloc] init];
    message.messageObject = messageObject;
    message.file = [self fileFromDictionary:messageObject._lcfile];
    message.location = [self locationFromDictionary:messageObject._lcloc];
    return message;
}

+ (instancetype)messageWithDictionary:(NSDictionary *)dictionary {
    AVIMTypedMessageObject *messageObject = [[AVIMTypedMessageObject alloc] initWithDictionary:dictionary];
    return [self messageWithMessageObject:messageObject];
}

- (id)copyWithZone:(NSZone *)zone {
    AVIMTypedMessage *message = [super copyWithZone:zone];
    if (message) {
        message.messageObject = self.messageObject;
//        message.mediaType = self.mediaType;
//        message.text = self.text;
////        message.attachmentUrl = self.attachmentUrl;
//        message.attributes = self.attributes;
        message.attachedFilePath = self.attachedFilePath;
        message.file = self.file;
        message.location = self.location;
    }
    return message;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    NSData *data = [self.messageObject messagePack];
    [coder encodeObject:data forKey:@"typedMessage"];
    [coder encodeObject:self.attachedFilePath forKey:@"attachedFilePath"];
}

- (instancetype)init {
    if (![self conformsToProtocol:@protocol(AVIMTypedMessageSubclassing)]) {
        [NSException raise:@"AVIMNotSubclassException" format:@"Class does not conform AVIMTypedMessageSubclassing protocol."];
    }
    if ((self = [super init])) {
        self.mediaType = [[self class] classMediaType];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        NSData *data = [coder decodeObjectForKey:@"typedMessage"];
        NSString *attachedFilePath = [coder decodeObjectForKey:@"attachedFilePath"];
        AVIMTypedMessageObject *object = [[AVIMTypedMessageObject alloc] initWithMessagePack:data];
        self.messageObject = object;
        self.attachedFilePath = attachedFilePath;
        self.file = [[self class] fileFromDictionary:object._lcfile];
        self.location = [[self class] locationFromDictionary:object._lcloc];
    }
    return self;
}

- (AVIMTypedMessageObject *)messageObject {
    if (!_messageObject) {
        _messageObject = [[AVIMTypedMessageObject alloc] init];
    }
    return _messageObject;
}

- (AVIMMessageMediaType)mediaType {
    return self.messageObject._lctype;
}

- (void)setMediaType:(AVIMMessageMediaType)mediaType {
    self.messageObject._lctype = mediaType;
}

- (NSString *)text {
    return self.messageObject._lctext;
}

- (void)setText:(NSString *)text {
    self.messageObject._lctext = text;
}

//- (NSString *)attachmentUrl {
//    return self.messageObject.url;
//}
//
//- (void)setAttachmentUrl:(NSString *)attachmentUrl {
//    self.messageObject.url = attachmentUrl;
//}
//
- (NSDictionary *)attributes {
    return self.messageObject._lcattrs;
}

- (void)setAttributes:(NSDictionary *)attributes {
    self.messageObject._lcattrs = attributes;
}

- (AVFile *)file {
    if (_file)
        return _file;

    NSDictionary *dictionary = self.messageObject._lcfile;

    if (dictionary)
        return [AVFile fileFromDictionary:dictionary];

    return nil;
}

- (void)setFile:(AVFile *)file {
    _file = file;
    self.messageObject._lcfile = file ? [AVFile dictionaryFromFile:file] : nil;
}

- (AVGeoPoint *)location {
    if (_location)
        return _location;

    NSDictionary *dictionary = self.messageObject._lcloc;

    if (dictionary)
        return [AVGeoPoint geoPointFromDictionary:dictionary];

    return nil;
}

- (void)setLocation:(AVGeoPoint *)location {
    _location = location;
    self.messageObject._lcloc = location ? [AVGeoPoint dictionaryFromGeoPoint:location] : nil;
}

- (void)setObject:(id)object forKey:(NSString *)key {
    [self.messageObject setObject:object forKey:key];
}

- (NSString *)payload {
    NSDictionary *dict = [self.messageObject dictionary];

    if (dict.count > 0) {
        return [self.messageObject JSONString];
    } else {
        return self.content;
    }
}

//
//- (NSDictionary *)metaData {
//    return self.messageObject.metaData;
//}
//
//- (void)setMetaData:(NSDictionary *)metaData {
//    self.messageObject.metaData =metaData;
//}
@end
