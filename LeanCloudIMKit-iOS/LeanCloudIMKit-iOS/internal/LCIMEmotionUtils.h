//
//  LCIMEmotionUtils.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//  表情工具类，提供表情、转换表情与文本


#import <Foundation/Foundation.h>
#import "LCIMKit.h"

@interface LCIMEmotionUtils : NSObject

/**
 *  获取 XHEmotionManager Array
 */
+ (NSArray *)emotionManagers;


/**
 *  :smile: 文本转换成原生表情
 */
+ (NSString *)emojiStringFromString:(NSString *)text;

/**
 *  原生表情转换成 :smile: 文本
 */
+ (NSString *)plainStringFromEmojiString:(NSString *)emojiText;

/*!
 *  方便开发者把本地表情保存到云端，调用一次保存到后台
 */
+ (void)saveEmotions;

+ (void)findEmotionWithName:(NSString *)name block:(AVFileResultBlock)block;

@end
