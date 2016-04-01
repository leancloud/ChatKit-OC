//
//  XMChatMoreView.h
//  XMChatBarExample
//
//  Created by shscce on 15/8/18.
//  Copyright (c) 2015年 xmfraker. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  moreItem类型
 */
typedef NS_ENUM(NSUInteger, XMChatMoreItemType){
    XMChatMoreItemCamera = 0 /**< 显示拍照 */,
    XMChatMoreItemAlbum /**< 显示相册 */,
    XMChatMoreItemLocation /**< 显示地理位置 */,
};

@protocol XMChatMoreViewDataSource;
@protocol XMChatMoreViewDelegate;
/**
 *  更多view
 */
@interface XMChatMoreView : UIView

@property (weak, nonatomic) id<XMChatMoreViewDelegate> delegate;
@property (weak, nonatomic) id<XMChatMoreViewDataSource> dataSource;

@property (assign, nonatomic) NSUInteger numberPerLine;
@property (assign, nonatomic) UIEdgeInsets edgeInsets;

- (void)reloadData;

@end


@protocol XMChatMoreViewDelegate <NSObject>

@optional
/**
 *  moreView选中的index
 *
 *  @param moreView 对应的moreView
 *  @param index    选中的index
 */
- (void)moreView:(XMChatMoreView *)moreView selectIndex:(XMChatMoreItemType)itemType;

@end

@protocol XMChatMoreViewDataSource <NSObject>

@required
/**
 *  获取数组中一共有多少个titles
 *
 *  @param moreView
 *  @param titles
 *
 *  @return
 */

- (NSArray *)titlesOfMoreView:(XMChatMoreView *)moreView;

/**
 *  获取moreView展示的所有图片
 *
 *  @param moreView
 *  @param imageNames
 *
 *  @return
 */
- (NSArray *)imageNamesOfMoreView:(XMChatMoreView *)moreView;

@end