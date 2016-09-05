//
//  AVIMLocationMessage.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>

#import "AVIMLocationMessage.h"
#import "AVIMGeneralObject.h"
#import "AVIMTypedMessage_Internal.h"

@implementation AVIMLocationMessage

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeLocation;
}

+ (instancetype)messageWithText:(NSString *)text
                       latitude:(float)latitude
                      longitude:(float)longitude
                     attributes:(NSDictionary *)attributes {
    AVIMLocationMessage *message = [[self alloc] init];
    message.text = text;
    message.attributes = attributes;
    AVGeoPoint *location = [AVGeoPoint geoPointWithLatitude:latitude longitude:longitude];
    message.location = location;
    return message;
}

- (float)longitude {
    return self.location.longitude;
}

- (float)latitude {
    return self.location.latitude;
}

@end
