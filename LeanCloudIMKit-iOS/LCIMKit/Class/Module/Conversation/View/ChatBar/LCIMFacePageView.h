//
//  LCIMFacePageView.h
//  LCIMFaceItemExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/12.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LCIMFacePageViewDelegate <NSObject>

- (void)selectedFaceImageWithFaceID:(NSUInteger)faceID;

@end

@interface LCIMFacePageView : UIView

@property (nonatomic, assign) NSUInteger columnsPerRow;
@property (nonatomic, copy) NSArray *datas;
@property (nonatomic, weak) id<LCIMFacePageViewDelegate> delegate;

@end
