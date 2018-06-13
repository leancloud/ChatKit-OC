//
//  NSString+MD5.m
//  LCCKChatExample
//
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/19.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "NSString+LCCKMD5.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (LCCKMD5)

- (NSString *)lcck_MD5String {
    const char* str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    uint32_t length = (CC_LONG)strlen(str);
    CC_MD5(str, length, result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
    
    return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString];
    return ret;
}

@end
