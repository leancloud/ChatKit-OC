//
//  AVExceptionHandler.h
//  paas
//
//  Created by Zhu Zeng on 8/19/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const AVOS_UncaughtExceptionHandlerAddressesKey;

@interface AVExceptionHandler : NSObject

+(void)installAVOSUncaughtExceptionHandler;
+(void)uninstallAVOSUncaughtExceptionHandler;
+ (NSArray *)backtrace;
+ (NSString*)appBuildUUID;
@end



