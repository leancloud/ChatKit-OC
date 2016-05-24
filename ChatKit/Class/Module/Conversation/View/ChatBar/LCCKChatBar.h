//
//  LCCKChatBar.h
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/8/17.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

@import UIKit;

static CGFloat const kLCCKChatBarMaxHeight = 60.0f;
static CGFloat const kLCCKChatBarMinHeight = 45.0f;
#define kFunctionViewHeight 210.0f

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

/**
 *  functionView 类型
 */
typedef NS_ENUM(NSUInteger, LCCKFunctionViewShowType){
    LCCKFunctionViewShowNothing /**< 不显示functionView */,
    LCCKFunctionViewShowFace /**< 显示表情View */,
    LCCKFunctionViewShowVoice /**< 显示录音view */,
    LCCKFunctionViewShowMore /**< 显示更多view */,
    LCCKFunctionViewShowKeyboard /**< 显示键盘 */,
};

@protocol LCCKChatBarDelegate;

/**
 *  信息输入框,支持语音,文字,表情,选择照片,拍照
 */
@interface LCCKChatBar : UIView

@property (assign, nonatomic) CGFloat superViewHeight;

@property (weak, nonatomic) id<LCCKChatBarDelegate> delegate;

/**
 *  结束输入状态
 */
- (void)endInputing;

@end

/**
 *  LCCKChatBar代理事件,发送图片,地理位置,文字,语音信息等
 */
@protocol LCCKChatBarDelegate <NSObject>


@optional

/**
 *  chatBarFrame改变回调
 *
 *  @param chatBar 
 */
- (void)chatBarFrameDidChange:(LCCKChatBar *)chatBar frame:(CGRect)frame;


/**
 *  发送图片信息,支持多张图片
 *
 *  @param chatBar
 *  @param pictures 需要发送的图片信息
 */
- (void)chatBar:(LCCKChatBar *)chatBar sendPictures:(NSArray *)pictures;

/**
 *  发送地理位置信息
 *
 *  @param chatBar
 *  @param locationCoordinate 需要发送的地址位置经纬度
 *  @param locationText       需要发送的地址位置对应信息
 */
- (void)chatBar:(LCCKChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText;

/**
 *  发送普通的文字信息,可能带有表情
 *
 *  @param chatBar
 *  @param message 需要发送的文字信息
 */
- (void)chatBar:(LCCKChatBar *)chatBar sendMessage:(NSString *)message;

/**
 *  发送语音信息
 *
 *  @param chatBar
 *  @param voiceData 语音data数据
 *  @param seconds   语音时长
 */
- (void)chatBar:(LCCKChatBar *)chatBar sendVoice:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds;

@end