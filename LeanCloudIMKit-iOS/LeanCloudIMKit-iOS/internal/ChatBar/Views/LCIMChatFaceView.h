//
//  LCIMChatFaceView.h
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/8/21.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LCIMShowFaceViewType) {
    LCIMShowEmojiFace = 0,
    LCIMShowRecentFace,
    LCIMShowGifFace,
};

@protocol LCIMChatFaceViewDelegate <NSObject>

- (void)faceViewSendFace:(NSString *)faceName;

@end

@interface LCIMChatFaceView : UIView

@property (weak, nonatomic) id<LCIMChatFaceViewDelegate> delegate;
@property (assign, nonatomic) LCIMShowFaceViewType faceViewType;

@end
