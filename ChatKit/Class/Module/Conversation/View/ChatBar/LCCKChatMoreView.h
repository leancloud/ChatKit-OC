//
//  LCCKChatMoreView.h
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/8/18.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  moreItem类型
 */
typedef NS_ENUM(NSUInteger, LCCKChatMoreItemType){
    LCCKChatMoreItemCamera = 0 /**< 显示拍照 */,
    LCCKChatMoreItemAlbum /**< 显示相册 */,
    LCCKChatMoreItemLocation /**< 显示地理位置 */,
};

static CGFloat const kFunctionViewHeight = 210.0f;

@protocol LCCKChatMoreViewDataSource;
@protocol LCCKChatMoreViewDelegate;
/**
 *  更多view
 */
@interface LCCKChatMoreView : UIView

@property (weak, nonatomic) id<LCCKChatMoreViewDelegate> delegate;
@property (weak, nonatomic) id<LCCKChatMoreViewDataSource> dataSource;

@property (assign, nonatomic) NSUInteger numberPerLine;
@property (assign, nonatomic) UIEdgeInsets edgeInsets;

- (void)reloadData;

@end


@protocol LCCKChatMoreViewDelegate <NSObject>

@optional
/**
 *  moreView选中的index
 *
 *  @param moreView 对应的moreView
 *  @param index    选中的index
 */
- (void)moreView:(LCCKChatMoreView *)moreView selectIndex:(LCCKChatMoreItemType)itemType;

@end

@protocol LCCKChatMoreViewDataSource <NSObject>

@required
/**
 *  获取数组中一共有多少个titles
 *
 *  @param moreView
 *  @param titles
 *
 *  @return
 */

- (NSArray *)titlesOfMoreView:(LCCKChatMoreView *)moreView;

/**
 *  获取moreView展示的所有图片
 *
 *  @param moreView
 *  @param imageNames
 *
 *  @return
 */
- (NSArray *)imageNamesOfMoreView:(LCCKChatMoreView *)moreView;

@end