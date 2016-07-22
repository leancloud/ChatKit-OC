//
//  NSString+LCCKExtension.h
//  ChatKit
//
//  Created by 陈宜龙 on 16/7/12.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const LCCKURLRegex;
FOUNDATION_EXTERN NSString *const LCCKPhoneRegex;

@class LCCKURL;

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

//- (NSArray<NSString *> *)lcck_allCheckingType:(NSTextCheckingType)type error:(NSError **)error;

- (NSArray<NSString *> *)lcck_allCheckingTypeWithPattern:(NSString *)pattern error:(NSError **)error;

- (NSArray *)lcck_allRangesWithPattern:(NSString *)pattern error:(NSError **)error;
- (NSArray<LCCKURL *> *)lcck_allURLModels;

@end
