// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// https://developers.google.com/protocol-buffers/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "LCIMUnknownFieldSet_PackagePrivate.h"

#import "LCIMCodedInputStream_PackagePrivate.h"
#import "LCIMCodedOutputStream.h"
#import "LCIMUnknownField_PackagePrivate.h"
#import "LCIMUtilities.h"
#import "LCIMWireFormat.h"

#pragma mark Helpers

static void checkNumber(int32_t number) {
  if (number == 0) {
    [NSException raise:NSInvalidArgumentException
                format:@"Zero is not a valid field number."];
  }
}

@implementation LCIMUnknownFieldSet {
 @package
  CFMutableDictionaryRef fields_;
}

static void CopyWorker(const void *key, const void *value, void *context) {
#pragma unused(key)
  LCIMUnknownField *field = value;
  LCIMUnknownFieldSet *result = context;

  LCIMUnknownField *copied = [field copy];
  [result addField:copied];
  [copied release];
}

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (id)copyWithZone:(NSZone *)zone {
  LCIMUnknownFieldSet *result = [[LCIMUnknownFieldSet allocWithZone:zone] init];
  if (fields_) {
    CFDictionaryApplyFunction(fields_, CopyWorker, result);
  }
  return result;
}

- (void)dealloc {
  if (fields_) {
    CFRelease(fields_);
  }
  [super dealloc];
}

- (BOOL)isEqual:(id)object {
  BOOL equal = NO;
  if ([object isKindOfClass:[LCIMUnknownFieldSet class]]) {
    LCIMUnknownFieldSet *set = (LCIMUnknownFieldSet *)object;
    if ((fields_ == NULL) && (set->fields_ == NULL)) {
      equal = YES;
    } else if ((fields_ != NULL) && (set->fields_ != NULL)) {
      equal = CFEqual(fields_, set->fields_);
    }
  }
  return equal;
}

- (NSUInteger)hash {
  // Return the hash of the fields dictionary (or just some value).
  if (fields_) {
    return CFHash(fields_);
  }
  return (NSUInteger)[LCIMUnknownFieldSet class];
}

#pragma mark - Public Methods

- (BOOL)hasField:(int32_t)number {
  ssize_t key = number;
  return fields_ ? (CFDictionaryGetValue(fields_, (void *)key) != nil) : NO;
}

- (LCIMUnknownField *)getField:(int32_t)number {
  ssize_t key = number;
  LCIMUnknownField *result =
      fields_ ? CFDictionaryGetValue(fields_, (void *)key) : nil;
  return result;
}

- (NSUInteger)countOfFields {
  return fields_ ? CFDictionaryGetCount(fields_) : 0;
}

- (NSArray *)sortedFields {
  if (!fields_) return [NSArray array];
  size_t count = CFDictionaryGetCount(fields_);
  ssize_t keys[count];
  LCIMUnknownField *values[count];
  CFDictionaryGetKeysAndValues(fields_, (const void **)keys,
                               (const void **)values);
  struct LCIMFieldPair {
    ssize_t key;
    LCIMUnknownField *value;
  } pairs[count];
  for (size_t i = 0; i < count; ++i) {
    pairs[i].key = keys[i];
    pairs[i].value = values[i];
  };
  qsort_b(pairs, count, sizeof(struct LCIMFieldPair),
          ^(const void *first, const void *second) {
            const struct LCIMFieldPair *a = first;
            const struct LCIMFieldPair *b = second;
            return (a->key > b->key) ? 1 : ((a->key == b->key) ? 0 : -1);
          });
  for (size_t i = 0; i < count; ++i) {
    values[i] = pairs[i].value;
  };
  return [NSArray arrayWithObjects:values count:count];
}

#pragma mark - Internal Methods

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)output {
  if (!fields_) return;
  size_t count = CFDictionaryGetCount(fields_);
  ssize_t keys[count];
  LCIMUnknownField *values[count];
  CFDictionaryGetKeysAndValues(fields_, (const void **)keys,
                               (const void **)values);
  if (count > 1) {
    struct LCIMFieldPair {
      ssize_t key;
      LCIMUnknownField *value;
    } pairs[count];

    for (size_t i = 0; i < count; ++i) {
      pairs[i].key = keys[i];
      pairs[i].value = values[i];
    };
    qsort_b(pairs, count, sizeof(struct LCIMFieldPair),
            ^(const void *first, const void *second) {
              const struct LCIMFieldPair *a = first;
              const struct LCIMFieldPair *b = second;
              return (a->key > b->key) ? 1 : ((a->key == b->key) ? 0 : -1);
            });
    for (size_t i = 0; i < count; ++i) {
      LCIMUnknownField *value = pairs[i].value;
      [value writeToOutput:output];
    }
  } else {
    [values[0] writeToOutput:output];
  }
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString
      stringWithFormat:@"<%@ %p>: TextFormat: {\n", [self class], self];
  NSString *textFormat = LCIMTextFormatForUnknownFieldSet(self, @"  ");
  [description appendString:textFormat];
  [description appendString:@"}"];
  return description;
}

static void LCIMUnknownFieldSetSerializedSize(const void *key, const void *value,
                                             void *context) {
#pragma unused(key)
  LCIMUnknownField *field = value;
  size_t *result = context;
  *result += [field serializedSize];
}

- (size_t)serializedSize {
  size_t result = 0;
  if (fields_) {
    CFDictionaryApplyFunction(fields_, LCIMUnknownFieldSetSerializedSize,
                              &result);
  }
  return result;
}

static void LCIMUnknownFieldSetWriteAsMessageSetTo(const void *key,
                                                  const void *value,
                                                  void *context) {
#pragma unused(key)
  LCIMUnknownField *field = value;
  LCIMCodedOutputStream *output = context;
  [field writeAsMessageSetExtensionToOutput:output];
}

- (void)writeAsMessageSetTo:(LCIMCodedOutputStream *)output {
  if (fields_) {
    CFDictionaryApplyFunction(fields_, LCIMUnknownFieldSetWriteAsMessageSetTo,
                              output);
  }
}

static void LCIMUnknownFieldSetSerializedSizeAsMessageSet(const void *key,
                                                         const void *value,
                                                         void *context) {
#pragma unused(key)
  LCIMUnknownField *field = value;
  size_t *result = context;
  *result += [field serializedSizeAsMessageSetExtension];
}

- (size_t)serializedSizeAsMessageSet {
  size_t result = 0;
  if (fields_) {
    CFDictionaryApplyFunction(
        fields_, LCIMUnknownFieldSetSerializedSizeAsMessageSet, &result);
  }
  return result;
}

- (NSData *)data {
  NSMutableData *data = [NSMutableData dataWithLength:self.serializedSize];
  LCIMCodedOutputStream *output =
      [[LCIMCodedOutputStream alloc] initWithData:data];
  [self writeToCodedOutputStream:output];
  [output release];
  return data;
}

+ (BOOL)isFieldTag:(int32_t)tag {
  return LCIMWireFormatGetTagWireType(tag) != LCIMWireFormatEndGroup;
}

- (void)addField:(LCIMUnknownField *)field {
  int32_t number = [field number];
  checkNumber(number);
  if (!fields_) {
    // Use a custom dictionary here because the keys are numbers and conversion
    // back and forth from NSNumber isn't worth the cost.
    fields_ = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL,
                                        &kCFTypeDictionaryValueCallBacks);
  }
  ssize_t key = number;
  CFDictionarySetValue(fields_, (const void *)key, field);
}

- (LCIMUnknownField *)mutableFieldForNumber:(int32_t)number create:(BOOL)create {
  ssize_t key = number;
  LCIMUnknownField *existing =
      fields_ ? CFDictionaryGetValue(fields_, (const void *)key) : nil;
  if (!existing && create) {
    existing = [[LCIMUnknownField alloc] initWithNumber:number];
    // This retains existing.
    [self addField:existing];
    [existing release];
  }
  return existing;
}

static void LCIMUnknownFieldSetMergeUnknownFields(const void *key,
                                                 const void *value,
                                                 void *context) {
#pragma unused(key)
  LCIMUnknownField *field = value;
  LCIMUnknownFieldSet *self = context;

  int32_t number = [field number];
  checkNumber(number);
  LCIMUnknownField *oldField = [self mutableFieldForNumber:number create:NO];
  if (oldField) {
    [oldField mergeFromField:field];
  } else {
    // Merge only comes from GPBMessage's mergeFrom:, so it means we are on
    // mutable message and are an mutable instance, so make sure we need
    // mutable fields.
    LCIMUnknownField *fieldCopy = [field copy];
    [self addField:fieldCopy];
    [fieldCopy release];
  }
}

- (void)mergeUnknownFields:(LCIMUnknownFieldSet *)other {
  if (other && other->fields_) {
    CFDictionaryApplyFunction(other->fields_,
                              LCIMUnknownFieldSetMergeUnknownFields, self);
  }
}

- (void)mergeFromData:(NSData *)data {
  LCIMCodedInputStream *input = [[LCIMCodedInputStream alloc] initWithData:data];
  [self mergeFromCodedInputStream:input];
  [input checkLastTagWas:0];
  [input release];
}

- (void)mergeVarintField:(int32_t)number value:(int32_t)value {
  checkNumber(number);
  [[self mutableFieldForNumber:number create:YES] addVarint:value];
}

- (BOOL)mergeFieldFrom:(int32_t)tag input:(LCIMCodedInputStream *)input {
  NSAssert(LCIMWireFormatIsValidTag(tag), @"Got passed an invalid tag");
  int32_t number = LCIMWireFormatGetTagFieldNumber(tag);
  LCIMCodedInputStreamState *state = &input->state_;
  switch (LCIMWireFormatGetTagWireType(tag)) {
    case LCIMWireFormatVarint: {
      LCIMUnknownField *field = [self mutableFieldForNumber:number create:YES];
      [field addVarint:LCIMCodedInputStreamReadInt64(state)];
      return YES;
    }
    case LCIMWireFormatFixed64: {
      LCIMUnknownField *field = [self mutableFieldForNumber:number create:YES];
      [field addFixed64:LCIMCodedInputStreamReadFixed64(state)];
      return YES;
    }
    case LCIMWireFormatLengthDelimited: {
      NSData *data = LCIMCodedInputStreamReadRetainedBytes(state);
      LCIMUnknownField *field = [self mutableFieldForNumber:number create:YES];
      [field addLengthDelimited:data];
      [data release];
      return YES;
    }
    case LCIMWireFormatStartGroup: {
      LCIMUnknownFieldSet *unknownFieldSet = [[LCIMUnknownFieldSet alloc] init];
      [input readUnknownGroup:number message:unknownFieldSet];
      LCIMUnknownField *field = [self mutableFieldForNumber:number create:YES];
      [field addGroup:unknownFieldSet];
      [unknownFieldSet release];
      return YES;
    }
    case LCIMWireFormatEndGroup:
      return NO;
    case LCIMWireFormatFixed32: {
      LCIMUnknownField *field = [self mutableFieldForNumber:number create:YES];
      [field addFixed32:LCIMCodedInputStreamReadFixed32(state)];
      return YES;
    }
  }
}

- (void)mergeMessageSetMessage:(int32_t)number data:(NSData *)messageData {
  [[self mutableFieldForNumber:number create:YES]
      addLengthDelimited:messageData];
}

- (void)addUnknownMapEntry:(int32_t)fieldNum value:(NSData *)data {
  LCIMUnknownField *field = [self mutableFieldForNumber:fieldNum create:YES];
  [field addLengthDelimited:data];
}

- (void)mergeFromCodedInputStream:(LCIMCodedInputStream *)input {
  while (YES) {
    int32_t tag = LCIMCodedInputStreamReadTag(&input->state_);
    if (tag == 0 || ![self mergeFieldFrom:tag input:input]) {
      break;
    }
  }
}

- (void)getTags:(int32_t *)tags {
  if (!fields_) return;
  size_t count = CFDictionaryGetCount(fields_);
  ssize_t keys[count];
  CFDictionaryGetKeysAndValues(fields_, (const void **)keys, NULL);
  for (size_t i = 0; i < count; ++i) {
    tags[i] = (int32_t)keys[i];
  }
}

#pragma clang diagnostic pop

@end
