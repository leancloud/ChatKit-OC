//
//  NSString+LCCKAddScale.m
//  Kuber
//
//  v0.8.5 Created by Kuber on 16/3/30.
//  Copyright © 2016年 Huaxu Technology. All rights reserved.
//

#import "NSString+LCCKAddScale.h"

@implementation NSString (LCCKAddScale)

- (NSString *)lcck_stringByAppendingScale:(CGFloat)scale {
    if (fabs(scale - 1) <= __FLT_EPSILON__ || self.length == 0 || [self hasSuffix:@"/"]) return self.copy;
    return [self stringByAppendingFormat:@"@%@x", @(scale)];
}

@end
