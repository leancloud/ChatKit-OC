//
//  LCCKChatBar.h
//  LCCKChatBarExample
//
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/8/17.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

static CGFloat const kChatBarBottomOffset = 8.f;
static CGFloat const kChatBarTextViewBottomOffset = 6;
static CGFloat const kLCCKChatBarTextViewFrameMinHeight = 37.f; //kLCCKChatBarMinHeight - 2*kChatBarTextViewBottomOffset;
static CGFloat const kLCCKChatBarTextViewFrameMaxHeight = 102.f; //kLCCKChatBarMaxHeight - 2*kChatBarTextViewBottomOffset;
static CGFloat const kLCCKChatBarMaxHeight = kLCCKChatBarTextViewFrameMaxHeight + 2*kChatBarTextViewBottomOffset; //114.0f;
static CGFloat const kLCCKChatBarMinHeight = kLCCKChatBarTextViewFrameMinHeight + 2*kChatBarTextViewBottomOffset; //49.0f;

FOUNDATION_EXTERN NSString *const kLCCKBatchDeleteTextPrefix;
FOUNDATION_EXTERN NSString *const kLCCKBatchDeleteTextSuffix;


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

@property (weak, nonatomic) id<LCCKChatBarDelegate> delegate;
@property (nonatomic, readonly) UIViewController *controllerRef;

/*!
 *
 缓存输入框文字，兼具内存缓存和本地数据库缓存的作用。同时也负责着输入框内容被清空时的监听，收缩键盘。内部重写了setter方法，self.cachedText 就相当于self.textView.text，使用最重要的场景：为了显示voiceButton，self.textView.text = nil;

 */
@property (copy, nonatomic) NSString *cachedText;
@property (nonatomic, assign) LCCKFunctionViewShowType showType;

/*!
 * 在 `-presentViewController:animated:completion:` 的completion回调中调用该方法，屏蔽来自其它 ViewController 的键盘通知事件。
 */
- (void)close;

/*!
 * 对应于 `-close` 方法。
 */
- (void)open;

/*!
 * 追加后，输入框默认开启编辑模式
 */
- (void)appendString:(NSString *)string;
- (void)appendString:(NSString *)string beginInputing:(BOOL)beginInputing;
- (void)appendString:(NSString *)string mentionList:(NSArray<NSString *> *)mentionList;

/**
 *  结束输入状态
 */
- (void)endInputing;

/**
 *  进入输入状态
 */
- (void)beginInputing;

@end

/**
 *  LCCKChatBar代理事件,发送图片,地理位置,文字,语音信息等
 */
@protocol LCCKChatBarDelegate <NSObject>


@optional

/*!
 *  chatBarFrame改变回调
 *
 *  @param chatBar 
 */
- (void)chatBarFrameDidChange:(LCCKChatBar *)chatBar shouldScrollToBottom:(BOOL)shouldScrollToBottom;

/*!
 *  发送图片信息,支持多张图片
 *
 *  @param chatBar
 *  @param pictures 需要发送的图片信息
 */
- (void)chatBar:(LCCKChatBar *)chatBar sendPictures:(NSArray *)pictures;

/*!
 *  发送地理位置信息
 *
 *  @param chatBar
 *  @param locationCoordinate 需要发送的地址位置经纬度
 *  @param locationText       需要发送的地址位置对应信息
 */
- (void)chatBar:(LCCKChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText;

/*!
 *  发送普通的文字信息,可能带有表情
 *
 *  @param chatBar
 *  @param message 需要发送的文字信息
 */
- (void)chatBar:(LCCKChatBar *)chatBar sendMessage:(NSString *)message mentionList:(NSArray<NSString *> *)mentionList;

/*!
 *  发送语音信息
 *
 *  @param chatBar
 *  @param voiceData 语音data数据
 *  @param seconds   语音时长
 */
- (void)chatBar:(LCCKChatBar *)chatBar sendVoice:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds;

/*!
 *  输入了 @ 的时候
 *
 */
- (void)didInputAtSign:(LCCKChatBar *)chatBar;

- (NSArray *)regulationForBatchDeleteText;

@end
