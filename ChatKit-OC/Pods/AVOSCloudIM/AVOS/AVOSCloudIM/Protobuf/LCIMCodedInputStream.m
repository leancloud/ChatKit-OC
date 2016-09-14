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

#import "LCIMCodedInputStream_PackagePrivate.h"

#import "LCIMDictionary_PackagePrivate.h"
#import "LCIMMessage_PackagePrivate.h"
#import "LCIMUnknownFieldSet_PackagePrivate.h"
#import "LCIMUtilities_PackagePrivate.h"
#import "LCIMWireFormat.h"

static const NSUInteger kDefaultRecursionLimit = 64;

static void CheckSize(GPBCodedInputStreamState *state, size_t size) {
  size_t newSize = state->bufferPos + size;
  if (newSize > state->bufferSize) {
    [NSException raise:NSParseErrorException format:@""];
  }
  if (newSize > state->currentLimit) {
    // Fast forward to end of currentLimit;
    state->bufferPos = state->currentLimit;
    [NSException raise:NSParseErrorException format:@""];
  }
}

static int8_t ReadRawByte(GPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int8_t));
  return ((int8_t *)state->bytes)[state->bufferPos++];
}

static int32_t ReadRawLittleEndian32(GPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int32_t));
  int32_t value = OSReadLittleInt32(state->bytes, state->bufferPos);
  state->bufferPos += sizeof(int32_t);
  return value;
}

static int64_t ReadRawLittleEndian64(GPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int64_t));
  int64_t value = OSReadLittleInt64(state->bytes, state->bufferPos);
  state->bufferPos += sizeof(int64_t);
  return value;
}

static int32_t ReadRawVarint32(GPBCodedInputStreamState *state) {
  int8_t tmp = ReadRawByte(state);
  if (tmp >= 0) {
    return tmp;
  }
  int32_t result = tmp & 0x7f;
  if ((tmp = ReadRawByte(state)) >= 0) {
    result |= tmp << 7;
  } else {
    result |= (tmp & 0x7f) << 7;
    if ((tmp = ReadRawByte(state)) >= 0) {
      result |= tmp << 14;
    } else {
      result |= (tmp & 0x7f) << 14;
      if ((tmp = ReadRawByte(state)) >= 0) {
        result |= tmp << 21;
      } else {
        result |= (tmp & 0x7f) << 21;
        result |= (tmp = ReadRawByte(state)) << 28;
        if (tmp < 0) {
          // Discard upper 32 bits.
          for (int i = 0; i < 5; i++) {
            if (ReadRawByte(state) >= 0) {
              return result;
            }
          }
          [NSException raise:NSParseErrorException
                      format:@"Unable to read varint32"];
        }
      }
    }
  }
  return result;
}

static int64_t ReadRawVarint64(GPBCodedInputStreamState *state) {
  int32_t shift = 0;
  int64_t result = 0;
  while (shift < 64) {
    int8_t b = ReadRawByte(state);
    result |= (int64_t)(b & 0x7F) << shift;
    if ((b & 0x80) == 0) {
      return result;
    }
    shift += 7;
  }
  [NSException raise:NSParseErrorException format:@"Unable to read varint64"];
  return 0;
}

static void SkipRawData(GPBCodedInputStreamState *state, size_t size) {
  CheckSize(state, size);
  state->bufferPos += size;
}

double LCIMCodedInputStreamReadDouble(GPBCodedInputStreamState *state) {
  int64_t value = ReadRawLittleEndian64(state);
  return LCIMConvertInt64ToDouble(value);
}

float LCIMCodedInputStreamReadFloat(GPBCodedInputStreamState *state) {
  int32_t value = ReadRawLittleEndian32(state);
  return LCIMConvertInt32ToFloat(value);
}

uint64_t LCIMCodedInputStreamReadUInt64(GPBCodedInputStreamState *state) {
  uint64_t value = ReadRawVarint64(state);
  return value;
}

uint32_t LCIMCodedInputStreamReadUInt32(GPBCodedInputStreamState *state) {
  uint32_t value = ReadRawVarint32(state);
  return value;
}

int64_t LCIMCodedInputStreamReadInt64(GPBCodedInputStreamState *state) {
  int64_t value = ReadRawVarint64(state);
  return value;
}

int32_t LCIMCodedInputStreamReadInt32(GPBCodedInputStreamState *state) {
  int32_t value = ReadRawVarint32(state);
  return value;
}

uint64_t LCIMCodedInputStreamReadFixed64(GPBCodedInputStreamState *state) {
  uint64_t value = ReadRawLittleEndian64(state);
  return value;
}

uint32_t LCIMCodedInputStreamReadFixed32(GPBCodedInputStreamState *state) {
  uint32_t value = ReadRawLittleEndian32(state);
  return value;
}

int32_t LCIMCodedInputStreamReadEnum(GPBCodedInputStreamState *state) {
  int32_t value = ReadRawVarint32(state);
  return value;
}

int32_t LCIMCodedInputStreamReadSFixed32(GPBCodedInputStreamState *state) {
  int32_t value = ReadRawLittleEndian32(state);
  return value;
}

int64_t LCIMCodedInputStreamReadSFixed64(GPBCodedInputStreamState *state) {
  int64_t value = ReadRawLittleEndian64(state);
  return value;
}

int32_t LCIMCodedInputStreamReadSInt32(GPBCodedInputStreamState *state) {
  int32_t value = LCIMDecodeZigZag32(ReadRawVarint32(state));
  return value;
}

int64_t LCIMCodedInputStreamReadSInt64(GPBCodedInputStreamState *state) {
  int64_t value = LCIMDecodeZigZag64(ReadRawVarint64(state));
  return value;
}

BOOL LCIMCodedInputStreamReadBool(GPBCodedInputStreamState *state) {
  return ReadRawVarint32(state) != 0;
}

int32_t LCIMCodedInputStreamReadTag(GPBCodedInputStreamState *state) {
  if (LCIMCodedInputStreamIsAtEnd(state)) {
    state->lastTag = 0;
    return 0;
  }

  state->lastTag = ReadRawVarint32(state);
  if (state->lastTag == 0) {
    // If we actually read zero, that's not a valid tag.
    [NSException raise:NSParseErrorException
                format:@"Invalid last tag %d", state->lastTag];
  }
  return state->lastTag;
}

NSString *LCIMCodedInputStreamReadRetainedString(
    GPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  NSString *result;
  if (size == 0) {
    result = @"";
  } else {
    CheckSize(state, size);
    result = [[NSString alloc] initWithBytes:&state->bytes[state->bufferPos]
                                      length:size
                                    encoding:NSUTF8StringEncoding];
    state->bufferPos += size;
    if (!result) {
#ifdef DEBUG
      // https://developers.google.com/protocol-buffers/docs/proto#scalar
      NSLog(@"UTF-8 failure, is some field type 'string' when it should be "
            @"'bytes'?");
#endif
      [NSException raise:NSParseErrorException
                  format:@"Invalid UTF-8 for a 'string'"];
    }
  }
  return result;
}

NSData *LCIMCodedInputStreamReadRetainedBytes(GPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  if (size < 0) return nil;
  CheckSize(state, size);
  NSData *result = [[NSData alloc] initWithBytes:state->bytes + state->bufferPos
                                          length:size];
  state->bufferPos += size;
  return result;
}

NSData *LCIMCodedInputStreamReadRetainedBytesNoCopy(
    GPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  if (size < 0) return nil;
  CheckSize(state, size);
  // Cast is safe because freeWhenDone is NO.
  NSData *result = [[NSData alloc]
      initWithBytesNoCopy:(void *)(state->bytes + state->bufferPos)
                   length:size
             freeWhenDone:NO];
  state->bufferPos += size;
  return result;
}

size_t LCIMCodedInputStreamPushLimit(GPBCodedInputStreamState *state,
                                    size_t byteLimit) {
  byteLimit += state->bufferPos;
  size_t oldLimit = state->currentLimit;
  if (byteLimit > oldLimit) {
    [NSException raise:NSInvalidArgumentException
                format:@"byteLimit > oldLimit: %tu > %tu", byteLimit, oldLimit];
  }
  state->currentLimit = byteLimit;
  return oldLimit;
}

void LCIMCodedInputStreamPopLimit(GPBCodedInputStreamState *state,
                                 size_t oldLimit) {
  state->currentLimit = oldLimit;
}

size_t LCIMCodedInputStreamBytesUntilLimit(GPBCodedInputStreamState *state) {
  return state->currentLimit - state->bufferPos;
}

BOOL LCIMCodedInputStreamIsAtEnd(GPBCodedInputStreamState *state) {
  return (state->bufferPos == state->bufferSize) ||
         (state->bufferPos == state->currentLimit);
}

void LCIMCodedInputStreamCheckLastTagWas(GPBCodedInputStreamState *state,
                                        int32_t value) {
  if (state->lastTag != value) {
    [NSException raise:NSParseErrorException
                format:@"Last tag: %d should be %d", state->lastTag, value];
  }
}

@implementation LCIMCodedInputStream

+ (instancetype)streamWithData:(NSData *)data {
  return [[[self alloc] initWithData:data] autorelease];
}

- (instancetype)initWithData:(NSData *)data {
  if ((self = [super init])) {
#ifdef DEBUG
    NSCAssert([self class] == [LCIMCodedInputStream class],
              @"Subclassing of LCIMCodedInputStream is not allowed.");
#endif
    buffer_ = [data retain];
    state_.bytes = (const uint8_t *)[data bytes];
    state_.bufferSize = [data length];
    state_.currentLimit = state_.bufferSize;
  }
  return self;
}

- (void)dealloc {
  [buffer_ release];
  [super dealloc];
}

- (int32_t)readTag {
  return LCIMCodedInputStreamReadTag(&state_);
}

- (void)checkLastTagWas:(int32_t)value {
  LCIMCodedInputStreamCheckLastTagWas(&state_, value);
}

- (BOOL)skipField:(int32_t)tag {
  switch (GPBWireFormatGetTagWireType(tag)) {
    case GPBWireFormatVarint:
      LCIMCodedInputStreamReadInt32(&state_);
      return YES;
    case GPBWireFormatFixed64:
      SkipRawData(&state_, sizeof(int64_t));
      return YES;
    case GPBWireFormatLengthDelimited:
      SkipRawData(&state_, ReadRawVarint32(&state_));
      return YES;
    case GPBWireFormatStartGroup:
      [self skipMessage];
      LCIMCodedInputStreamCheckLastTagWas(
          &state_, GPBWireFormatMakeTag(GPBWireFormatGetTagFieldNumber(tag),
                                        GPBWireFormatEndGroup));
      return YES;
    case GPBWireFormatEndGroup:
      return NO;
    case GPBWireFormatFixed32:
      SkipRawData(&state_, sizeof(int32_t));
      return YES;
  }
  [NSException raise:NSParseErrorException format:@"Invalid tag %d", tag];
  return NO;
}

- (void)skipMessage {
  while (YES) {
    int32_t tag = LCIMCodedInputStreamReadTag(&state_);
    if (tag == 0 || ![self skipField:tag]) {
      return;
    }
  }
}

- (BOOL)isAtEnd {
  return LCIMCodedInputStreamIsAtEnd(&state_);
}

- (size_t)position {
  return state_.bufferPos;
}

- (double)readDouble {
  return LCIMCodedInputStreamReadDouble(&state_);
}

- (float)readFloat {
  return LCIMCodedInputStreamReadFloat(&state_);
}

- (uint64_t)readUInt64 {
  return LCIMCodedInputStreamReadUInt64(&state_);
}

- (int64_t)readInt64 {
  return LCIMCodedInputStreamReadInt64(&state_);
}

- (int32_t)readInt32 {
  return LCIMCodedInputStreamReadInt32(&state_);
}

- (uint64_t)readFixed64 {
  return LCIMCodedInputStreamReadFixed64(&state_);
}

- (uint32_t)readFixed32 {
  return LCIMCodedInputStreamReadFixed32(&state_);
}

- (BOOL)readBool {
  return LCIMCodedInputStreamReadBool(&state_);
}

- (NSString *)readString {
  return [LCIMCodedInputStreamReadRetainedString(&state_) autorelease];
}

- (void)readGroup:(int32_t)fieldNumber
              message:(LCIMMessage *)message
    extensionRegistry:(LCIMExtensionRegistry *)extensionRegistry {
  if (state_.recursionDepth >= kDefaultRecursionLimit) {
    [NSException raise:NSParseErrorException
                format:@"recursionDepth(%tu) >= %tu", state_.recursionDepth,
                       kDefaultRecursionLimit];
  }
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self extensionRegistry:extensionRegistry];
  LCIMCodedInputStreamCheckLastTagWas(
      &state_, GPBWireFormatMakeTag(fieldNumber, GPBWireFormatEndGroup));
  --state_.recursionDepth;
}

- (void)readUnknownGroup:(int32_t)fieldNumber
                 message:(LCIMUnknownFieldSet *)message {
  if (state_.recursionDepth >= kDefaultRecursionLimit) {
    [NSException raise:NSParseErrorException
                format:@"recursionDepth(%tu) >= %tu", state_.recursionDepth,
                       kDefaultRecursionLimit];
  }
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self];
  LCIMCodedInputStreamCheckLastTagWas(
      &state_, GPBWireFormatMakeTag(fieldNumber, GPBWireFormatEndGroup));
  --state_.recursionDepth;
}

- (void)readMessage:(LCIMMessage *)message
    extensionRegistry:(LCIMExtensionRegistry *)extensionRegistry {
  int32_t length = ReadRawVarint32(&state_);
  if (state_.recursionDepth >= kDefaultRecursionLimit) {
    [NSException raise:NSParseErrorException
                format:@"recursionDepth(%tu) >= %tu", state_.recursionDepth,
                       kDefaultRecursionLimit];
  }
  size_t oldLimit = LCIMCodedInputStreamPushLimit(&state_, length);
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self extensionRegistry:extensionRegistry];
  LCIMCodedInputStreamCheckLastTagWas(&state_, 0);
  --state_.recursionDepth;
  LCIMCodedInputStreamPopLimit(&state_, oldLimit);
}

- (void)readMapEntry:(id)mapDictionary
    extensionRegistry:(LCIMExtensionRegistry *)extensionRegistry
                field:(LCIMFieldDescriptor *)field
        parentMessage:(LCIMMessage *)parentMessage {
  int32_t length = ReadRawVarint32(&state_);
  if (state_.recursionDepth >= kDefaultRecursionLimit) {
    [NSException raise:NSParseErrorException
                format:@"recursionDepth(%tu) >= %tu", state_.recursionDepth,
                       kDefaultRecursionLimit];
  }
  size_t oldLimit = LCIMCodedInputStreamPushLimit(&state_, length);
  ++state_.recursionDepth;
  LCIMDictionaryReadEntry(mapDictionary, self, extensionRegistry, field,
                         parentMessage);
  LCIMCodedInputStreamCheckLastTagWas(&state_, 0);
  --state_.recursionDepth;
  LCIMCodedInputStreamPopLimit(&state_, oldLimit);
}

- (NSData *)readBytes {
  return [LCIMCodedInputStreamReadRetainedBytes(&state_) autorelease];
}

- (uint32_t)readUInt32 {
  return LCIMCodedInputStreamReadUInt32(&state_);
}

- (int32_t)readEnum {
  return LCIMCodedInputStreamReadEnum(&state_);
}

- (int32_t)readSFixed32 {
  return LCIMCodedInputStreamReadSFixed32(&state_);
}

- (int64_t)readSFixed64 {
  return LCIMCodedInputStreamReadSFixed64(&state_);
}

- (int32_t)readSInt32 {
  return LCIMCodedInputStreamReadSInt32(&state_);
}

- (int64_t)readSInt64 {
  return LCIMCodedInputStreamReadSInt64(&state_);
}

@end
