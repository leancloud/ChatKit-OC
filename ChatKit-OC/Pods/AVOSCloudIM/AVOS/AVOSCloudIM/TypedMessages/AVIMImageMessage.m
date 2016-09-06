//
//  AVIMImageMessage.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>

#import "AVIMImageMessage.h"
#import "AVIMGeneralObject.h"
#import "AVIMTypedMessage_Internal.h"

@implementation AVIMImageMessage

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeImage;
}

- (void)setWidth:(uint)width {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    metaData.width = width;
}

- (uint)width {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    return metaData.width;
}

- (void)setHeight:(uint)height {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    metaData.height = height;
}

- (uint)height {
    AVIMGeneralObject *metaData = [[AVIMGeneralObject alloc] initWithMutableDictionary:self.file.metaData];
    return metaData.height;
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
@end
