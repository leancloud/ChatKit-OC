//
//  AVIMConversationOutCommand.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/8/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//  处于兼容性考虑，保留该类。该类仅仅用在conversation 缓存时，生成 SQL 中 conversationID 对应的 key。

#import "AVIMSignature.h"
#import "AVIMDynamicObject.h"
#import "AVIMCommandCommon.h"
#import "AVIMConversationQuery.h"

@interface AVIMConversationOutCommand : AVIMDynamicObject

@property (nonatomic, assign) uint16_t i;
@property (nonatomic, copy) NSString *cmd;
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, assign) NSInteger appCode;
@property (nonatomic, copy) NSString *reason;
@property (nonatomic, copy) NSString *peerId;
@property (nonatomic, assign) BOOL needResponse;
@property (nonatomic, copy) AVIMCommandResultBlock callback;

@property(nonatomic, strong) NSString *op;
@property(nonatomic, strong) NSString *cid;
@property(nonatomic, strong) NSArray *m;
@property(nonatomic, assign) bool transient;
@property(nonatomic, assign) bool muted;

@property (nonatomic, strong) AVIMSignature *signature;
@property (nonatomic, strong) NSDictionary  *attr;
@property (nonatomic, strong) NSDictionary  *where;
@property (nonatomic, strong) NSString      *sort;
@property (nonatomic, assign) uint32_t       skip;
@property (nonatomic, assign) uint32_t       limit;
@property (nonatomic, assign) BOOL           unique;
@property (nonatomic, assign) AVIMConversationQueryOption option;

@end
