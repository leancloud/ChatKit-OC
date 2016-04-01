//
//  LCIMChatMoreView.h
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/8/18.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  moreItem类型
 */
typedef NS_ENUM(NSUInteger, LCIMChatMoreItemType){
    LCIMChatMoreItemCamera = 0 /**< 显示拍照 */,
    LCIMChatMoreItemAlbum /**< 显示相册 */,
    LCIMChatMoreItemLocation /**< 显示地理位置 */,
};

@protocol LCIMChatMoreViewDataSource;
@protocol LCIMChatMoreViewDelegate;
/**
 *  更多view
 */
@interface LCIMChatMoreView : UIView

@property (weak, nonatomic) id<LCIMChatMoreViewDelegate> delegate;
@property (weak, nonatomic) id<LCIMChatMoreViewDataSource> dataSource;

@property (assign, nonatomic) NSUInteger numberPerLine;
@property (assign, nonatomic) UIEdgeInsets edgeInsets;

- (void)reloadData;

@end


@protocol LCIMChatMoreViewDelegate <NSObject>

@optional
/**
 *  moreView选中的index
 *
 *  @param moreView 对应的moreView
 *  @param index    选中的index
 */
- (void)moreView:(LCIMChatMoreView *)moreView selectIndex:(LCIMChatMoreItemType)itemType;

@end

@protocol LCIMChatMoreViewDataSource <NSObject>

@required
/**
 *  获取数组中一共有多少个titles
 *
 *  @param moreView
 *  @param titles
 *
 *  @return
 */

- (NSArray *)titlesOfMoreView:(LCIMChatMoreView *)moreView;

/**
 *  获取moreView展示的所有图片
 *
 *  @param moreView
 *  @param imageNames
 *
 *  @return
 */
- (NSArray *)imageNamesOfMoreView:(LCIMChatMoreView *)moreView;

@end