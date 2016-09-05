//
//  AVIMTypedMessageObject.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/8/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMTypedMessageObject.h"
#import "AVIMTypedMessage_Internal.h"

@implementation AVIMTypedMessageObject
@dynamic _lctype, _lctext, _lcattrs, _lcfile, _lcloc;

- (BOOL)isValidTypedMessageObject {
    BOOL hasTypeKey = [self hasKey:@"_lctype"];
    if (!hasTypeKey) {
        return NO;
    }
    BOOL __block isSupportedThisVersion = NO;
    NSNumber *type = [self objectForKey:@"_lctype"];
    [_typeDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key intValue] == [type intValue]) {
            isSupportedThisVersion = YES;
            *stop = YES;
            return;
        }
    }];
    BOOL isValidTypedMessageObject = hasTypeKey && isSupportedThisVersion;
    return isValidTypedMessageObject;
}

@end
