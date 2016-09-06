//
//  AVIMAudioMessage.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMTypedMessage.h"

/**
 *  Audio Message. Can be created by the audio's file path.
 */
@interface AVIMAudioMessage : AVIMTypedMessage <AVIMTypedMessageSubclassing>

/// File size in bytes.
@property(nonatomic, readonly)uint64_t size;

/// Audio's duration in seconds.
@property(nonatomic, readonly)float duration;

/// Audio format, mp3, aac, etc. Simply get it by the file extension.
@property(nonatomic, strong, readonly)NSString *format;

@end
