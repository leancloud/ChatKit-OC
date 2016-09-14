//
//  AVIMErrorUtil.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/20/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMErrorUtil.h"
#import "AVIMCommon.h"

NSString *AVOSCloudIMErrorDomain = @"AVOSCloudIMErrorDomain";

NSInteger const kAVIMErrorInvalidCommand = 1;
NSInteger const kAVIMErrorInvalidArguments = 2;
NSInteger const kAVIMErrorConversationNotFound = 3;
NSInteger const kAVIMErrorTimeout = 4;
NSInteger const kAVIMErrorConnectionLost = 5;
NSInteger const kAVIMErrorInvalidData = 6;
NSInteger const kAVIMErrorMessageTooLong = 7;
NSInteger const kAVIMErrorClientNotOpen = 8;

//NSInteger const kAVErrorObjectNotFound = 101;
//NSInteger const kAVErrorInvalidQuery = 102;
//NSInteger const kAVErrorInvalidClassName = 103;
//NSInteger const kAVErrorMissingObjectId = 104;
//NSInteger const kAVErrorInvalidKeyName = 105;
//NSInteger const kAVErrorInvalidPointer = 106;
//NSInteger const kAVErrorInvalidJSON = 107;

@implementation AVIMErrorUtil
+ (NSError *)errorWithCode:(NSInteger)code reason:(NSString *)reason {
    NSMutableDictionary *dict = nil;
    if (reason) {
        dict = [[NSMutableDictionary alloc] init];
        [dict setObject:reason forKey:@"reason"];
        [dict setObject:NSLocalizedString(reason, nil) forKey:NSLocalizedFailureReasonErrorKey];
    }
    NSError *error = [NSError errorWithDomain:AVOSCloudIMErrorDomain
                                         code:code
                                     userInfo:dict];
    return error;
}
@end
