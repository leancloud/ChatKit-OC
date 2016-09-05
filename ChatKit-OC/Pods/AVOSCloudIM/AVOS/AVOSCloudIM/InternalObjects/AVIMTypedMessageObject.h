//
//  AVIMTypedMessageObject.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/8/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMDynamicObject.h"
#import "AVIMCommon.h"

@interface AVIMTypedMessageObject : AVIMDynamicObject
@property(nonatomic)int8_t _lctype;
@property(nonatomic, strong)NSString *_lctext;
@property(nonatomic, strong)NSDictionary *_lcfile;
@property(nonatomic, strong)NSDictionary *_lcloc;
@property(nonatomic, strong)NSDictionary *_lcattrs;

- (BOOL)isValidTypedMessageObject;
@end
