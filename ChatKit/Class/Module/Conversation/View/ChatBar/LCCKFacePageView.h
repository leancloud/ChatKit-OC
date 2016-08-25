//
//  LCCKFacePageView.h
//  LCCKFaceItemExample
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/12.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LCCKFacePageViewDelegate <NSObject>

- (void)selectedFaceImageWithFaceID:(NSUInteger)faceID;

@end

@interface LCCKFacePageView : UIView

@property (nonatomic, assign) NSUInteger columnsPerRow;
@property (nonatomic, copy) NSArray *datas;
@property (nonatomic, weak) id<LCCKFacePageViewDelegate> delegate;

@end
