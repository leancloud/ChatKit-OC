//
//  AVIMImageMessage.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMTypedMessage.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Image Message. Can be created by the image's file path.
 */
@interface AVIMImageMessage : AVIMTypedMessage <AVIMTypedMessageSubclassing>

/// Width of the image in pixels.
@property(nonatomic, assign, readonly) uint width;

/// Height of the image in pixels.
@property(nonatomic, assign, readonly) uint height;

/// File size in bytes.
@property(nonatomic, assign, readonly) uint64_t size;

/// Image format, png, jpg, etc. Simply get it from the file extension.
@property(nonatomic, copy, readonly, nullable) NSString *format;

@end

NS_ASSUME_NONNULL_END
