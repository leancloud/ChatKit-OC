//
//  LCIMConversationListService.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMConstants.h"

typedef void (^LCIMRecentConversationsCallback)(NSArray *conversations, NSInteger totalUnreadCount,  NSError *error);

@interface LCIMConversationListService : NSObject

+ (instancetype)sharedInstance;
- (void)fetchConversationsWithConversationIds:(NSSet *)conversationIds callback:(LCIMArrayResultBlock)callback;
- (void)findRecentConversationsWithBlock:(LCIMRecentConversationsCallback)block;

@end
