//
//  LCCKFaceManager.h
//  LCCKChatBarExample
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/8/25.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#define kFaceIDKey          @"face_id"
#define kFaceNameKey        @"face_name"
#define kFaceImageNameKey   @"face_image_name"

#define kFaceRankKey        @"face_rank"
#define kFaceClickKey       @"face_click"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/**
 *  表情管理类,可以获取所有的表情名称
 *  TODO 直接获取所有的表情Dict,添加排序功能,对表情进行排序,常用表情排在前面
 */
@interface LCCKFaceManager : NSObject

+ (instancetype)shareInstance;

#pragma mark - emoji表情相关

/**
 *  获取所有的表情图片名称
 *
 *  @return 所有的表情图片名称
 */
+ (NSArray *)emojiFaces;
@property (strong, nonatomic, readonly) NSMutableArray *emojiFaceArrays;

+ (UIImage *)faceImageWithFaceID:(NSUInteger)faceID;
+ (NSString *)faceNameWithFaceID:(NSUInteger)faceID;
/**
 *  将文字中带表情的字符处理换成图片显示
 *
 *  @param text 未处理的文字
 *
 *  @return 处理后的文字
 */
+ (NSMutableAttributedString *)emotionStrWithString:(NSString *)text;
+ (void)configEmotionWithMutableAttributedString:(NSMutableAttributedString *)attributeString;
#pragma mark - 最近表情相关处理

/**
 *  获取最近使用的表情图片
 *
 *  @return
 */
+ (NSArray *)recentFaces;

/**
 *  存储一个最近使用的face
 *
 *  @param dict 包含以下key-value键值对
 *  face_id     表情id
 *  face_name   表情名称
 *  @return 是否存储成功
 */
+ (BOOL)saveRecentFace:(NSDictionary *)dict;

@end
