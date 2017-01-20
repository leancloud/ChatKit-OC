//
//  AVIMBlockHelper.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/9/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMCommon.h"

@interface AVIMBlockHelper : NSObject

+ (void)callBooleanResultBlock:(AVIMBooleanResultBlock)block
                         error:(NSError *)error;

+ (void)callIntegerResultBlock:(AVIMIntegerResultBlock)block
                        number:(NSInteger)number
                         error:(NSError *)error;

+ (void)callArrayResultBlock:(AVIMArrayResultBlock)block
                       array:(NSArray *)array
                       error:(NSError *)error;

+ (void)callConversationResultBlock:(AVIMConversationResultBlock)block
                       conversation:(AVIMConversation *)conversation
                              error:(NSError *)error;

+ (AVIMBooleanResultBlock)calledOnceBlockWithBooleanResultBlock:(AVIMBooleanResultBlock)block;

@end
