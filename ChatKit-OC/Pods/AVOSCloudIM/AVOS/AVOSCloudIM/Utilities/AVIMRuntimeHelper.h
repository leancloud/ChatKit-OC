//
//  AVIMRuntimeHelper.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/26/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVIMRuntimeHelper : NSObject
+ (void)callMethodWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments returnValue:(void *)returnValue;
+ (void)callMethodWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments;
+ (void)callMethodInMainThreadWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments;
@end
