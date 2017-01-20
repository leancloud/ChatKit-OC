//
//  AVMPMessagePackWriter.m
//  AVMPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "AVMPMessagePackWriter.h"

#include "avmp.h"

#import "AVMPOrderedDictionary.h"
#import "AVMPDefines.h"

@interface AVMPMessagePackWriter ()
@property NSMutableData *data;
@end

@implementation AVMPMessagePackWriter

- (size_t)write:(const void *)data count:(size_t)count {
  [_data appendBytes:data length:count];
  return count;
}

static bool mp_reader(avmp_ctx_t *ctx, void *data, size_t limit) {
  return 0;
}

static size_t mp_writer(avmp_ctx_t *ctx, const void *data, size_t count) {
  AVMPMessagePackWriter *mp = (__bridge AVMPMessagePackWriter *)ctx->buf;
  return [mp write:data count:count];
}

- (NSMutableData *)writeObject:(id)obj options:(AVMPMessagePackWriterOptions)options error:(NSError * __autoreleasing *)error {
  _data = [NSMutableData data];
  
  avmp_ctx_t ctx;
  avmp_init(&ctx, (__bridge void *)self, mp_reader, mp_writer);
  
  if (![self writeObject:obj options:options context:&ctx error:error]) {
    return nil;
  }
  
  return _data;
}

+ (NSMutableData *)writeObject:(id)obj error:(NSError * __autoreleasing *)error {
  return [self writeObject:obj options:0 error:error];
}

+ (NSMutableData *)writeObject:(id)obj options:(AVMPMessagePackWriterOptions)options error:(NSError * __autoreleasing *)error {
  AVMPMessagePackWriter *messagePack = [[AVMPMessagePackWriter alloc] init];
  [messagePack writeObject:obj options:options error:error];
  return messagePack.data;
}

- (BOOL)writeNumber:(NSNumber *)number context:(avmp_ctx_t *)context error:(NSError * __autoreleasing *)error {
  if (strcmp([number objCType], @encode(bool)) == 0) {
    avmp_write_bool(context, number.boolValue);
    return YES;
  }
  
  CFNumberType numberType = CFNumberGetType((CFNumberRef)number);
  switch (numberType)	{
    case kCFNumberFloat32Type:
    case kCFNumberFloatType:
    case kCFNumberCGFloatType:
      avmp_write_float(context, number.floatValue);
      return YES;
    case kCFNumberFloat64Type:
    case kCFNumberDoubleType:
      avmp_write_double(context, number.doubleValue);
      return YES;
    default:
      break;
  }
  
  if ([number compare:@(0)] >= 0) {
    avmp_write_uint(context, number.unsignedLongLongValue);
    return YES;
  } else {
    avmp_write_sint(context, number.longLongValue);
    return YES;
  }
}

- (BOOL)writeObject:(id)obj options:(AVMPMessagePackWriterOptions)options context:(avmp_ctx_t *)context error:(NSError * __autoreleasing *)error {
  if ([obj isKindOfClass:[NSArray class]]) {
    if (!avmp_write_array(context, (uint32_t)[obj count])) {
      if (error) *error = [NSError errorWithDomain:@"AVMPMessagePack" code:102 userInfo:@{NSLocalizedDescriptionKey: @"Error writing array"}];
      return NO;
    }
    for (id element in obj) {
      if (![self writeObject:element options:options context:context error:error]) {
        return NO;
      }
    }
  } else if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[AVMPOrderedDictionary class]]) {
    if (!avmp_write_map(context, (uint32_t)[obj count])) {
      if (error) *error = [NSError errorWithDomain:@"AVMPMessagePack" code:102 userInfo:@{NSLocalizedDescriptionKey: @"Error writing map"}];
      return NO;
    }
    
    NSEnumerator *keyEnumerator;
    if ((options & AVMPMessagePackWriterOptionsSortDictionaryKeys) == AVMPMessagePackWriterOptionsSortDictionaryKeys) {
      keyEnumerator = [[[obj allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectEnumerator];
    } else {
      keyEnumerator = [obj keyEnumerator];
    }
    
    for (id key in keyEnumerator) {      
      if (![self writeObject:key options:options context:context error:error]) {
        return NO;
      }
      if (![self writeObject:obj[key] options:options context:context error:error]) {
        return NO;
      }
    }
  } else if ([obj isKindOfClass:[NSString class]]) {
    const char *str = ((NSString*)obj).UTF8String;
    size_t len = strlen(str);
    if (!avmp_write_str(context, str, (uint32_t)len)) {
      if (error) *error = [NSError errorWithDomain:@"AVMPMessagePack" code:102 userInfo:@{NSLocalizedDescriptionKey: @"Error writing string"}];
      return NO;
    }
  } else if ([obj isKindOfClass:[NSNumber class]]) {
    [self writeNumber:obj context:context error:error];
  } else if ([obj isKindOfClass:[NSNull class]]) {
    if (!avmp_write_nil(context)) {
      if (error) *error = [NSError errorWithDomain:@"AVMPMessagePack" code:102 userInfo:@{NSLocalizedDescriptionKey: @"Error writing nil"}];
      return NO;
    }
  } else if ([obj isKindOfClass:[NSData class]]) {
    if (!avmp_write_bin(context, [obj bytes], (uint32_t)[obj length])) {
      if (error) *error = [NSError errorWithDomain:@"AVMPMessagePack" code:102 userInfo:@{NSLocalizedDescriptionKey: @"Error writing binary"}];
      return NO;
    }
  } else {
    NSString *errorDescription = [NSString stringWithFormat:@"Unable to write object: %@", obj];
    if (error) *error = [NSError errorWithDomain:@"AVMPMessagePack" code:102 userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
    return NO;
  }
  return YES;
}

@end
