//
//  LCCKChatFaceView.h
//  LCCKChatBarExample
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/8/21.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LCCKShowFaceViewType) {
    LCCKShowEmojiFace = 0,
    LCCKShowRecentFace,
    LCCKShowGifFace,
};
#define kLCCKTopLineBackgroundColor [UIColor colorWithRed:184/255.0f green:184/255.0f blue:184/255.0f alpha:1.0f]

@protocol LCCKChatFaceViewDelegate <NSObject>

- (void)faceViewSendFace:(NSString *)faceName;

@end

@interface LCCKChatFaceView : UIView

@property (weak, nonatomic) id<LCCKChatFaceViewDelegate> delegate;
@property (assign, nonatomic) LCCKShowFaceViewType faceViewType;

@end
