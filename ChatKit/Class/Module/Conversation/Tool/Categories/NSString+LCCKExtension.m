//
//  NSString+LCCKExtension.m
//  ChatKit
//
//  Created by 陈宜龙 on 16/7/12.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "NSString+LCCKExtension.h"

@implementation NSString (LCCKExtension)

- (BOOL)lcck_containsString:(NSString *)string {
    if ([self rangeOfString:string].location == NSNotFound) {
        return NO;
    }
    return YES;
}

@end
