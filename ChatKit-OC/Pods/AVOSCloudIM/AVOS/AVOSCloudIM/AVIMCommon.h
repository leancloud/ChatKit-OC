//
//  AVIMCommon.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/4/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AVIMConversation;

extern NSString *AVOSCloudIMErrorDomain;

extern NSInteger const kAVIMErrorInvalidCommand;  //非法的请求命令
extern NSInteger const kAVIMErrorInvalidArguments;  //非法参数
extern NSInteger const kAVIMErrorConversationNotFound;  //会话未找到
extern NSInteger const kAVIMErrorTimeout;  //请求超时
extern NSInteger const kAVIMErrorConnectionLost;  //连接断开
extern NSInteger const kAVIMErrorInvalidData;  //非法数据
extern NSInteger const kAVIMErrorMessageTooLong;  //消息内容太长
extern NSInteger const kAVIMErrorClientNotOpen;  //client 没有打开

/* AVOSCloud IM code key */
FOUNDATION_EXPORT NSString *const kAVIMCodeKey;
/* AVOSCloud IM app code key */
FOUNDATION_EXPORT NSString *const kAVIMAppCodeKey;
/* AVOSCloud IM reason key */
FOUNDATION_EXPORT NSString *const kAVIMReasonKey;
/* AVOSCloud IM detail key */
FOUNDATION_EXPORT NSString *const kAVIMDetailKey;

typedef void (^AVIMBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^AVIMIntegerResultBlock)(NSInteger number, NSError *error);
typedef void (^AVIMArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^AVIMConversationResultBlock)(AVIMConversation *conversation, NSError *error);
typedef void (^AVIMProgressBlock)(NSInteger percentDone);

/* Cache policy */
typedef NS_ENUM(int, AVIMCachePolicy) {
    /* Query from server and do not save result to local cache. */
    kAVIMCachePolicyIgnoreCache = 0,

    /* Only query from local cache. */
    kAVIMCachePolicyCacheOnly,

    /* Only query from server, and save result to local cache. */
    kAVIMCachePolicyNetworkOnly,

    /* Firstly query from local cache, if fails, query from server. */
    kAVIMCachePolicyCacheElseNetwork,

    /* Firstly query from server, if fails, query local cache. */
    kAVIMCachePolicyNetworkElseCache,

    /* Firstly query from local cache, then query from server. The callback will be called twice. */
    kAVIMCachePolicyCacheThenNetwork,
};
