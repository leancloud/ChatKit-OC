//
//  NSString+MessageInputView.m
//  MessageDisplayExample
//
//  Created by qtone-1 on 14-4-24.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import "NSString+MessageInputView.h"

@implementation NSString (MessageInputView)

- (NSString *)lcim_stringByTrimingWhitespace {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSUInteger)lcim_numberOfLines {
    return [[self componentsSeparatedByString:@"\n"] count] + 1;
}

@end
