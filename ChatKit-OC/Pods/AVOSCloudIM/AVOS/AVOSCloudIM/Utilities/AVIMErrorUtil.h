//
//  AVIMErrorUtil.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/20/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVIMErrorUtil : NSObject
+ (NSError *)errorWithCode:(NSInteger)code reason:(NSString *)reason;
@end
