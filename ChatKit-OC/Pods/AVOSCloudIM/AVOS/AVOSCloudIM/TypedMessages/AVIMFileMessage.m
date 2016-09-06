//
//  AVIMFileMessage.m
//  AVOS
//
//  Created by Tang Tianyong on 7/30/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMFileMessage.h"

@implementation AVIMFileMessage

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeFile;
}

@end
