//
//  LCCKURL.m
//  Pods
//
//  Created by 陈宜龙 on 16/7/22.
//
//

#import "LCCKURL.h"
#import "NSString+LCCKExtension.h"

@implementation LCCKURL

- (instancetype)initWithURLString:(NSString *)URLString range:(NSRange)range {
    if (self = [super init]) {
        _urlString = URLString;
        _range = range;
    }
    return self;
}

+ (instancetype)urlWithURLString:(NSString *)URLString range:(NSRange)range; {
    LCCKURL *url = [[LCCKURL alloc] initWithURLString:URLString range:range];
    return url;
}

@end
