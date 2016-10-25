//
//  AVIMAudioMessage.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMTypedMessage.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Audio Message. Can be created by the audio's file path.
 */
@interface AVIMAudioMessage : AVIMTypedMessage <AVIMTypedMessageSubclassing>

/// File size in bytes.
@property(nonatomic, assign, readonly) uint64_t size;

/// Audio's duration in seconds.
@property(nonatomic, assign, readonly) float duration;

/// Audio format, mp3, aac, etc. Simply get it by the file extension.
@property(nonatomic, copy, readonly, nullable) NSString *format;

@end

NS_ASSUME_NONNULL_END
