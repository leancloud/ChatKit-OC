//
//  AVMPMessagePackReader.h
//  AVMPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AVMPMessagePackReaderOptions) {
  AVMPMessagePackReaderOptionsUseOrderedDictionary = 1 << 0,
};


@interface AVMPMessagePackReader : NSObject

@property (readonly) size_t index;

- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithData:(NSData *)data options:(AVMPMessagePackReaderOptions)options;

- (id)readObject:(NSError * __autoreleasing *)error;

+ (id)readData:(NSData *)data error:(NSError * __autoreleasing *)error;

+ (id)readData:(NSData *)data options:(AVMPMessagePackReaderOptions)options error:(NSError * __autoreleasing *)error;

@end
