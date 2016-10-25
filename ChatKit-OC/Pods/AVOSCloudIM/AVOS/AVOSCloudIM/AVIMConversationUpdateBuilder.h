//
//  AVIMConversationUpdateBuilder.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/8/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMCommon.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Dictionary Builder to update conversation
 */
@interface AVIMConversationUpdateBuilder : NSObject
/*!
 名称
 */
@property (nonatomic, copy, nullable) NSString *name;

/*!
 属性合集，修改此属性会覆盖 setObject:forKey: 和 removeObjectForKey: 所做的修改
 */
@property (nonatomic, strong, nullable) NSDictionary *attributes;

/*!
 生成更新字典。之后可调用 -[AVIMConversation update:callback:] 来更新对话。
 @return 更新用的字典
 */
- (NSDictionary *)dictionary;

/*!
 获取 attributes 中 key 对应的值
 @param key 获取数据的 key 值
 @return key 对应的值
 */
- (nullable id)objectForKey:(NSString *)key;

/*!
 设置 attributes 中 key 对应的值为 object
 @param object 设置的对象，传 [NSNull null] 将在服务器端删除对应的 key
 @param key 设置的 key 值
 */
- (void)setObject:(nullable id)object forKey:(NSString *)key;

/*!
 移除 attributes 中的 key
 @param key 移除的 key 值
 */
- (void)removeObjectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
