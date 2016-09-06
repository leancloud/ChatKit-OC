//
//  AVIMAudioMessage.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>

#import "AVIMAudioMessage.h"
#import "AVIMGeneralObject.h"
#import "AVIMTypedMessage_Internal.h"

@implementation AVIMAudioMessage

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeAudio;
}

- (void)setSize:(uint64_t)size {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    metaData.size = size;
}

- (uint64_t)size {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    return metaData.size;
}

- (void)setFormat:(NSString *)format {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    metaData.format = format;
}

- (NSString *)format {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    return metaData.format;
}

- (void)setDuration:(float)duration {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    metaData.duration = duration;
}

- (float)duration {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    return metaData.duration;
}

@end
