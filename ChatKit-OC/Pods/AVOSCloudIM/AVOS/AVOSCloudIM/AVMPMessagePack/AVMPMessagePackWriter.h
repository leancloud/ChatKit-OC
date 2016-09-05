//
//  AVMPMessagePackWriter.h
//  AVMPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AVMPMessagePackWriterOptions) {
  AVMPMessagePackWriterOptionsSortDictionaryKeys = 1 << 0,
};

@interface AVMPMessagePackWriter : NSObject

- (NSMutableData *)writeObject:(id)obj options:(AVMPMessagePackWriterOptions)options error:(NSError * __autoreleasing *)error;

+ (NSMutableData *)writeObject:(id)obj error:(NSError * __autoreleasing *)error;

+ (NSMutableData *)writeObject:(id)obj options:(AVMPMessagePackWriterOptions)options error:(NSError * __autoreleasing *)error;

@end
