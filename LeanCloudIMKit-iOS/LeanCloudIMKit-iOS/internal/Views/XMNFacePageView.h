//
//  XMNFacePageView.h
//  XMFaceItemExample
//
//  Created by shscce on 15/11/12.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XMNFacePageViewDelegate <NSObject>

- (void)selectedFaceImageWithFaceID:(NSUInteger)faceID;

@end

@interface XMNFacePageView : UIView

@property (nonatomic, assign) NSUInteger columnsPerRow;
@property (nonatomic, copy) NSArray *datas;
@property (nonatomic, weak) id<XMNFacePageViewDelegate> delegate;

@end
