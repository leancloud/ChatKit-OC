//
//  AVIMTypedMessage+LCCKExtension.h
//  ChatKit
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/5/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <AVOSCloudIM/AVOSCloudIM.h>
@class LCCKMessage;

@interface AVIMTypedMessage (LCCKExtension)

- (BOOL)lcck_isSupportThisCustomMessage;

+ (AVIMTypedMessage *)lcck_messageWithLCCKMessage:(LCCKMessage *)message;
- (void)lcck_setObject:(id)object forKey:(NSString *)key;

@end
