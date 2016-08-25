//
//  LCCKChatVoiceMessageCell.h
//  LCCKChatExample
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/16.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatMessageCell.h"

@interface LCCKChatVoiceMessageCell : LCCKChatMessageCell<LCCKChatMessageCellSubclassing>

@property (nonatomic, assign) LCCKVoiceMessageState voiceMessageState;

@end
