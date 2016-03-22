//
//  XMChatFaceView.h
//  XMChatBarExample
//
//  Created by shscce on 15/8/21.
//  Copyright (c) 2015年 xmfraker. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, XMShowFaceViewType) {
    XMShowEmojiFace = 0,
    XMShowRecentFace,
    XMShowGifFace,
};

@protocol XMChatFaceViewDelegate <NSObject>

- (void)faceViewSendFace:(NSString *)faceName;

@end

@interface XMChatFaceView : UIView

@property (weak, nonatomic) id<XMChatFaceViewDelegate> delegate;
@property (assign, nonatomic) XMShowFaceViewType faceViewType;

@end
