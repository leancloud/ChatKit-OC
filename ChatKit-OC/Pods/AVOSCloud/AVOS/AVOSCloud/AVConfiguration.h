//
//  AVConfiguration.h
//  AVOS
//
//  Created by Tang Tianyong on 7/29/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVConfiguration : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy, readonly) NSString *applicationId;
@property (nonatomic, copy, readonly) NSString *applicationKey;

@end
