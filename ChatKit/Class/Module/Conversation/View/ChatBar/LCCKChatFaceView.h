//
//  LCCKChatFaceView.h
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/8/21.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LCCKShowFaceViewType) {
    LCCKShowEmojiFace = 0,
    LCCKShowRecentFace,
    LCCKShowGifFace,
};

@protocol LCCKChatFaceViewDelegate <NSObject>

- (void)faceViewSendFace:(NSString *)faceName;

@end

@interface LCCKChatFaceView : UIView

@property (weak, nonatomic) id<LCCKChatFaceViewDelegate> delegate;
@property (assign, nonatomic) LCCKShowFaceViewType faceViewType;

@end
