//
//  AVDynamicBase.h
//  RuntimeTest
//
//  Created by Qihe Bian on 9/3/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVDynamicBase : NSObject
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithJSON:(NSString *)json;
- (NSString *)JSONString;
@end
