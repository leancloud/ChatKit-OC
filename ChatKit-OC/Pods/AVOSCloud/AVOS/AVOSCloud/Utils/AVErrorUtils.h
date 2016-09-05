//
//  AVErrorUtils.h
//  LeanCloud
//
//  Created by Zhu Zeng on 3/23/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kAVErrorDomain;
extern NSString * const kAVErrorUnknownText;

typedef NS_ENUM(NSInteger, AVLocalErrorCode) {
    AVLocalErrorCodeInvalidArgument = 10000
};

@interface AVErrorUtils : NSObject

+(NSError *)errorWithCode:(NSInteger)code;
+(NSError *)errorWithCode:(NSInteger)code errorText:(NSString *)text;
+ (NSError *)errorWithText:(NSString *)text;

+(NSError *)internalServerError;
+(NSError *)fileNotFoundError;
+(NSError *)dataNotAvailableError;

+ (NSError *)errorFromJSON:(id)JSON;
+ (NSString *)errorTextFromError:(NSError *)error;
+ (NSError *)errorFromAVError:(NSError *)error;

@end
