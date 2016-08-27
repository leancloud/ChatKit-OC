//
//  LCCKChatImageMessageCell.h
//  LCCKChatExample
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/16.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatMessageCell.h"

@interface LCCKChatImageMessageCell : LCCKChatMessageCell<LCCKChatMessageCellSubclassing>

/**
 *  用来显示image的UIImageView
 */
@property (nonatomic, strong, readonly) UIImageView *messageImageView;

- (void)setUploadProgress:(CGFloat)uploadProgress;

@end
