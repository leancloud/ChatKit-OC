//
//  AVIMImageMessage.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMTypedMessage.h"

/**
 *  Image Message. Can be created by the image's file path.
 */
@interface AVIMImageMessage : AVIMTypedMessage <AVIMTypedMessageSubclassing>

/// Width of the image in pixels.
@property(nonatomic, readonly)uint width;

/// Height of the image in pixels.
@property(nonatomic, readonly)uint height;

/// File size in bytes.
@property(nonatomic, readonly)uint64_t size;

/// Image format, png, jpg, etc. Simply get it from the file extension.
@property(nonatomic, strong, readonly)NSString *format;

@end
