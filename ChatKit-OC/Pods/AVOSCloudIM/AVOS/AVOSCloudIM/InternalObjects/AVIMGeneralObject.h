//
//  AVIMGeneralObject.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/15/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMDynamicObject.h"

@interface AVIMGeneralObject : AVIMDynamicObject
@property(nonatomic)uint width;
@property(nonatomic)uint height;
@property(nonatomic)uint64_t size;
@property(nonatomic)float duration;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *format;
@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *objId;
@property(nonatomic)float longitude;
@property(nonatomic)float latitude;
@property(nonatomic, strong)AVIMGeneralObject *metaData;
@property(nonatomic, strong)AVIMGeneralObject *location;
@end
