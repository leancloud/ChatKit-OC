//
//  NSString+LCCKExtension.h
//  ChatKit
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/7/12.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const LCCKURLRegex;
FOUNDATION_EXTERN NSString *const LCCKPhoneRegex;

@interface NSString (LCCKExtension)

- (BOOL)lcck_containsString:(NSString *)string;

/*!
 * 含标点符号，也返回NO
 */
- (BOOL)lcck_onlyContainsLetterAndNumber;

- (BOOL)lcck_isLink;

- (BOOL)lcck_isPhoneNumber;

- (BOOL)lcck_isUserName;

- (BOOL)lcck_isSpace;

- (NSArray<NSString *> *)lcck_allURLLinks;

- (NSArray<NSString *> *)lcck_allPhoneNumbers;

- (NSArray<NSString *> *)lcck_allUserNames;

- (BOOL)lcck_isType:(NSTextCheckingType)type;

- (NSArray<NSString *> *)lcck_allCheckingTypeWithPattern:(NSString *)pattern error:(NSError **)error;

- (NSArray<NSValue *> *)lcck_allURLsWithPattern:(NSString *)pattern error:(NSError **)error;

- (UIColor *)lcck_hexStringToColor;

- (NSString *)lcck_pathForConversationBackgroundImage;

@end
