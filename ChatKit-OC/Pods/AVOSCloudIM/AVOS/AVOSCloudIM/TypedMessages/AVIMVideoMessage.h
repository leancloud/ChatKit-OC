//
//  AVIMVideoMessage.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMTypedMessage.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Video Message.
 */
@interface AVIMVideoMessage : AVIMTypedMessage <AVIMTypedMessageSubclassing>

/// File size in bytes.
@property(nonatomic, assign, readonly) uint64_t size;

/// Duration of the video in seconds.
@property(nonatomic, assign, readonly) float duration;

/// Video format, mp4, m4v, etc. Simply get it from the file extension.
@property(nonatomic, copy, readonly, nullable) NSString *format;

@end

NS_ASSUME_NONNULL_END
