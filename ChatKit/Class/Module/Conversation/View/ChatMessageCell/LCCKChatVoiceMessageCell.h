//
//  LCCKChatVoiceMessageCell.h
//  LCCKChatExample
//
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/16.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatMessageCell.h"

@interface LCCKChatVoiceMessageCell : LCCKChatMessageCell<LCCKChatMessageCellSubclassing>

@property (nonatomic, assign) LCCKVoiceMessageState voiceMessageState;

@end
