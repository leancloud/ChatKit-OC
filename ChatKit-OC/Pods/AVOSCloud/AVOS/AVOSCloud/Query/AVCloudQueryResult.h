//
//  AVCloudQueryResult.h
//  AVOS
//
//  Created by Qihe Bian on 9/22/14.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVCloudQueryResult : NSObject
/**
 *  查询结果的 className
 */
@property(nonatomic, copy, readonly) NSString *className;

/**
 *  查询的结果 AVObject 对象列表
 */
@property(nonatomic, strong, readonly) NSArray *results;

/**
 *  查询 count 结果, 只有使用 select count(*) ... 时有效
 */
@property(nonatomic, assign, readonly) NSUInteger count;

@end

typedef void(^AVCloudQueryCallback)(AVCloudQueryResult * _Nullable result, NSError * _Nullable error);

NS_ASSUME_NONNULL_END
