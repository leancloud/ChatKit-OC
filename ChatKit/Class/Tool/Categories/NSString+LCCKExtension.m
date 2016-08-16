//
//  NSString+LCCKExtension.m
//  ChatKit
//
// v0.5.2 Created by 陈宜龙 on 16/7/12.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "NSString+LCCKExtension.h"

NSString *const LCCKURLRegex = @"(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))";
//匹配10到12位连续数字，或者带连字符/空格的固话号，空格和连字符可以省略。
NSString *const LCCKPhoneRegex =  @"\\d{3,4}[- ]?\\d{7,8}";

@implementation NSString (LCCKExtension)

- (BOOL)lcck_containsString:(NSString *)string {
    if ([self rangeOfString:string].location == NSNotFound) {
        return NO;
    }
    return YES;
}

- (BOOL)lcck_onlyContainsLetterAndNumber {
    if (![[self stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] isEqualToString:self]
        && ![[self stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]] isEqualToString:self]) {
        return YES;
    }
    return NO;
}
- (BOOL)lcck_isLink {
    return [self lcck_isType:NSTextCheckingTypeLink];
}

- (BOOL)lcck_isPhoneNumber {
    return (self.lcck_allPhoneNumbers.count > 0);
}

- (BOOL)lcck_isUserName {
    return [self hasPrefix:@"@"];
}

- (BOOL)lcck_isSpace {
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    if ([[self stringByTrimmingCharactersInSet: set] length] == 0) {
        return YES;
    }
    return NO;
}

- (NSArray<NSString *> *)lcck_allURLLinks {
    NSString *URLRegex =  LCCKURLRegex;
    NSArray *allURLLinksFromRegex = [self lcck_allCheckingTypeWithPattern:URLRegex error:nil];
    return allURLLinksFromRegex;
}

- (NSArray<NSString *> *)lcck_allPhoneNumbers {
    //匹配10到12位连续数字，或者带连字符/空格的固话号，空格和连字符可以省略。
    NSString *phoneRegex = LCCKPhoneRegex;
    NSArray *phoneNumbersFromRegex = [self lcck_allCheckingTypeWithPattern:phoneRegex error:nil];
    return phoneNumbersFromRegex;
}

- (NSArray<NSString *> *)lcck_allUserNames {
    //[^\s#@] will match everything except space characters, # and @.And remember to double escape \ when put in the objective-c string literal.
    NSString *pattern = @"@[^\\s#@]*";
    return [self lcck_allCheckingTypeWithPattern:pattern error:nil];
}

- (BOOL)lcck_isType:(NSTextCheckingType)type {
    switch (type) {
        case NSTextCheckingTypeLink:
            return ([self lcck_allMatchsWithPattern:LCCKURLRegex error:nil].count > 0);
            break;
            case NSTextCheckingTypePhoneNumber:
            return ([self lcck_allMatchsWithPattern:LCCKPhoneRegex error:nil].count > 0);
            break;
        default:
            break;
    }
    return NO;
}

- (NSArray<NSTextCheckingResult *> *)lcck_allMatchsWithPattern:(NSString *)pattern error:(NSError **)error {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:error];
    NSArray *arrayOfAllMatches = [regex matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    return arrayOfAllMatches;
}

- (NSArray *)lcck_allRangesWithPattern:(NSString *)pattern error:(NSError **)error {
    NSArray *arrayOfAllMatches = [self lcck_allMatchsWithPattern:pattern error:error];
    NSMutableArray *arrayOfCheckingType = [[NSMutableArray alloc] init];
    NSMutableArray *allRanges = [NSMutableArray arrayWithCapacity:1];
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        [allRanges addObject:[NSValue valueWithRange:match.range]];
    }
    return [allRanges copy];
}

- (NSArray<NSValue *> *)lcck_allURLsWithPattern:(NSString *)pattern error:(NSError **)error {
    NSArray *arrayOfAllMatches = [self lcck_allMatchsWithPattern:pattern error:error];
    NSMutableArray *arrayOfCheckingType = [[NSMutableArray alloc] init];
    NSMutableArray *allRanges = [NSMutableArray arrayWithCapacity:1];
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        [allRanges addObject:[NSValue valueWithRange:match.range]];
    }
    return [allRanges copy];
}

- (NSArray<NSString *> *)lcck_allCheckingTypeWithPattern:(NSString *)pattern error:(NSError **)error {
    NSArray *arrayOfAllMatches = [self lcck_allMatchsWithPattern:pattern error:error];
    NSMutableArray *arrayOfCheckingType = [[NSMutableArray alloc] init];
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        NSString* substringForMatch = [self substringWithRange:match.range];
        [arrayOfCheckingType addObject:substringForMatch];
    }
    // return non-mutable version of the array
    return [NSArray arrayWithArray:arrayOfCheckingType];
}

@end
