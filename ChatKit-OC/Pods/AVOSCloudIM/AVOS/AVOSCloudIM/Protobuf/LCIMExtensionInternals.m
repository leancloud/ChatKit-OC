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

#import "LCIMExtensionInternals.h"

#import <objc/runtime.h>

#import "LCIMCodedInputStream_PackagePrivate.h"
#import "LCIMCodedOutputStream_PackagePrivate.h"
#import "LCIMDescriptor_PackagePrivate.h"
#import "LCIMMessage_PackagePrivate.h"
#import "LCIMUtilities_PackagePrivate.h"

static id NewSingleValueFromInputStream(LCIMExtensionDescriptor *extension,
                                        LCIMCodedInputStream *input,
                                        LCIMExtensionRegistry *extensionRegistry,
                                        LCIMMessage *existingValue)
    __attribute__((ns_returns_retained));

GPB_INLINE size_t DataTypeSize(GPBDataType dataType) {
  switch (dataType) {
    case GPBDataTypeBool:
      return 1;
    case GPBDataTypeFixed32:
    case GPBDataTypeSFixed32:
    case GPBDataTypeFloat:
      return 4;
    case GPBDataTypeFixed64:
    case GPBDataTypeSFixed64:
    case GPBDataTypeDouble:
      return 8;
    default:
      return 0;
  }
}

static size_t ComputePBSerializedSizeNoTagOfObject(GPBDataType dataType, id object) {
#define FIELD_CASE(TYPE, ACCESSOR)                                     \
  case GPBDataType##TYPE:                                              \
    return LCIMCompute##TYPE##SizeNoTag([(NSNumber *)object ACCESSOR]);
#define FIELD_CASE2(TYPE)                                              \
  case GPBDataType##TYPE:                                              \
    return LCIMCompute##TYPE##SizeNoTag(object);
  switch (dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Message)
    FIELD_CASE2(Group)
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static size_t ComputeSerializedSizeIncludingTagOfObject(
    GPBExtensionDescription *description, id object) {
#define FIELD_CASE(TYPE, ACCESSOR)                                   \
  case GPBDataType##TYPE:                                            \
    return LCIMCompute##TYPE##Size(description->fieldNumber,          \
                                  [(NSNumber *)object ACCESSOR]);
#define FIELD_CASE2(TYPE)                                            \
  case GPBDataType##TYPE:                                            \
    return LCIMCompute##TYPE##Size(description->fieldNumber, object);
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Group)
    case GPBDataTypeMessage:
      if (LCIMExtensionIsWireFormat(description)) {
        return LCIMComputeMessageSetExtensionSize(description->fieldNumber,
                                                 object);
      } else {
        return LCIMComputeMessageSize(description->fieldNumber, object);
      }
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static size_t ComputeSerializedSizeIncludingTagOfArray(
    GPBExtensionDescription *description, NSArray *values) {
  if (LCIMExtensionIsPacked(description)) {
    size_t size = 0;
    size_t typeSize = DataTypeSize(description->dataType);
    if (typeSize != 0) {
      size = values.count * typeSize;
    } else {
      for (id value in values) {
        size +=
            ComputePBSerializedSizeNoTagOfObject(description->dataType, value);
      }
    }
    return size + LCIMComputeTagSize(description->fieldNumber) +
           LCIMComputeRawVarint32SizeForInteger(size);
  } else {
    size_t size = 0;
    for (id value in values) {
      size += ComputeSerializedSizeIncludingTagOfObject(description, value);
    }
    return size;
  }
}

static void WriteObjectIncludingTagToCodedOutputStream(
    id object, GPBExtensionDescription *description,
    LCIMCodedOutputStream *output) {
#define FIELD_CASE(TYPE, ACCESSOR)                      \
  case GPBDataType##TYPE:                               \
    [output write##TYPE:description->fieldNumber        \
                  value:[(NSNumber *)object ACCESSOR]]; \
    return;
#define FIELD_CASE2(TYPE)                                       \
  case GPBDataType##TYPE:                                       \
    [output write##TYPE:description->fieldNumber value:object]; \
    return;
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Group)
    case GPBDataTypeMessage:
      if (LCIMExtensionIsWireFormat(description)) {
        [output writeMessageSetExtension:description->fieldNumber value:object];
      } else {
        [output writeMessage:description->fieldNumber value:object];
      }
      return;
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static void WriteObjectNoTagToCodedOutputStream(
    id object, GPBExtensionDescription *description,
    LCIMCodedOutputStream *output) {
#define FIELD_CASE(TYPE, ACCESSOR)                             \
  case GPBDataType##TYPE:                                      \
    [output write##TYPE##NoTag:[(NSNumber *)object ACCESSOR]]; \
    return;
#define FIELD_CASE2(TYPE)               \
  case GPBDataType##TYPE:               \
    [output write##TYPE##NoTag:object]; \
    return;
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Message)
    case GPBDataTypeGroup:
      [output writeGroupNoTag:description->fieldNumber value:object];
      return;
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static void WriteArrayIncludingTagsToCodedOutputStream(
    NSArray *values, GPBExtensionDescription *description,
    LCIMCodedOutputStream *output) {
  if (LCIMExtensionIsPacked(description)) {
    [output writeTag:description->fieldNumber
              format:GPBWireFormatLengthDelimited];
    size_t dataSize = 0;
    size_t typeSize = DataTypeSize(description->dataType);
    if (typeSize != 0) {
      dataSize = values.count * typeSize;
    } else {
      for (id value in values) {
        dataSize +=
            ComputePBSerializedSizeNoTagOfObject(description->dataType, value);
      }
    }
    [output writeRawVarintSizeTAs32:dataSize];
    for (id value in values) {
      WriteObjectNoTagToCodedOutputStream(value, description, output);
    }
  } else {
    for (id value in values) {
      WriteObjectIncludingTagToCodedOutputStream(value, description, output);
    }
  }
}

void LCIMExtensionMergeFromInputStream(LCIMExtensionDescriptor *extension,
                                      BOOL isPackedOnStream,
                                      LCIMCodedInputStream *input,
                                      LCIMExtensionRegistry *extensionRegistry,
                                      LCIMMessage *message) {
  GPBExtensionDescription *description = extension->description_;
  GPBCodedInputStreamState *state = &input->state_;
  if (isPackedOnStream) {
    NSCAssert(LCIMExtensionIsRepeated(description),
              @"How was it packed if it isn't repeated?");
    int32_t length = LCIMCodedInputStreamReadInt32(state);
    size_t limit = LCIMCodedInputStreamPushLimit(state, length);
    while (LCIMCodedInputStreamBytesUntilLimit(state) > 0) {
      id value = NewSingleValueFromInputStream(extension,
                                               input,
                                               extensionRegistry,
                                               nil);
      [message addExtension:extension value:value];
      [value release];
    }
    LCIMCodedInputStreamPopLimit(state, limit);
  } else {
    id existingValue = nil;
    BOOL isRepeated = LCIMExtensionIsRepeated(description);
    if (!isRepeated && LCIMDataTypeIsMessage(description->dataType)) {
      existingValue = [message getExistingExtension:extension];
    }
    id value = NewSingleValueFromInputStream(extension,
                                             input,
                                             extensionRegistry,
                                             existingValue);
    if (isRepeated) {
      [message addExtension:extension value:value];
    } else {
      [message setExtension:extension value:value];
    }
    [value release];
  }
}

void LCIMWriteExtensionValueToOutputStream(LCIMExtensionDescriptor *extension,
                                          id value,
                                          LCIMCodedOutputStream *output) {
  GPBExtensionDescription *description = extension->description_;
  if (LCIMExtensionIsRepeated(description)) {
    WriteArrayIncludingTagsToCodedOutputStream(value, description, output);
  } else {
    WriteObjectIncludingTagToCodedOutputStream(value, description, output);
  }
}

size_t LCIMComputeExtensionSerializedSizeIncludingTag(
    LCIMExtensionDescriptor *extension, id value) {
  GPBExtensionDescription *description = extension->description_;
  if (LCIMExtensionIsRepeated(description)) {
    return ComputeSerializedSizeIncludingTagOfArray(description, value);
  } else {
    return ComputeSerializedSizeIncludingTagOfObject(description, value);
  }
}

// Note that this returns a retained value intentionally.
static id NewSingleValueFromInputStream(LCIMExtensionDescriptor *extension,
                                        LCIMCodedInputStream *input,
                                        LCIMExtensionRegistry *extensionRegistry,
                                        LCIMMessage *existingValue) {
  GPBExtensionDescription *description = extension->description_;
  GPBCodedInputStreamState *state = &input->state_;
  switch (description->dataType) {
    case GPBDataTypeBool:     return [[NSNumber alloc] initWithBool:LCIMCodedInputStreamReadBool(state)];
    case GPBDataTypeFixed32:  return [[NSNumber alloc] initWithUnsignedInt:LCIMCodedInputStreamReadFixed32(state)];
    case GPBDataTypeSFixed32: return [[NSNumber alloc] initWithInt:LCIMCodedInputStreamReadSFixed32(state)];
    case GPBDataTypeFloat:    return [[NSNumber alloc] initWithFloat:LCIMCodedInputStreamReadFloat(state)];
    case GPBDataTypeFixed64:  return [[NSNumber alloc] initWithUnsignedLongLong:LCIMCodedInputStreamReadFixed64(state)];
    case GPBDataTypeSFixed64: return [[NSNumber alloc] initWithLongLong:LCIMCodedInputStreamReadSFixed64(state)];
    case GPBDataTypeDouble:   return [[NSNumber alloc] initWithDouble:LCIMCodedInputStreamReadDouble(state)];
    case GPBDataTypeInt32:    return [[NSNumber alloc] initWithInt:LCIMCodedInputStreamReadInt32(state)];
    case GPBDataTypeInt64:    return [[NSNumber alloc] initWithLongLong:LCIMCodedInputStreamReadInt64(state)];
    case GPBDataTypeSInt32:   return [[NSNumber alloc] initWithInt:LCIMCodedInputStreamReadSInt32(state)];
    case GPBDataTypeSInt64:   return [[NSNumber alloc] initWithLongLong:LCIMCodedInputStreamReadSInt64(state)];
    case GPBDataTypeUInt32:   return [[NSNumber alloc] initWithUnsignedInt:LCIMCodedInputStreamReadUInt32(state)];
    case GPBDataTypeUInt64:   return [[NSNumber alloc] initWithUnsignedLongLong:LCIMCodedInputStreamReadUInt64(state)];
    case GPBDataTypeBytes:    return LCIMCodedInputStreamReadRetainedBytes(state);
    case GPBDataTypeString:   return LCIMCodedInputStreamReadRetainedString(state);
    case GPBDataTypeEnum:     return [[NSNumber alloc] initWithInt:LCIMCodedInputStreamReadEnum(state)];
    case GPBDataTypeGroup:
    case GPBDataTypeMessage: {
      LCIMMessage *message;
      if (existingValue) {
        message = [existingValue retain];
      } else {
        LCIMDescriptor *decriptor = [extension.msgClass descriptor];
        message = [[decriptor.messageClass alloc] init];
      }

      if (description->dataType == GPBDataTypeGroup) {
        [input readGroup:description->fieldNumber
                 message:message
            extensionRegistry:extensionRegistry];
      } else {
        // description->dataType == GPBDataTypeMessage
        if (LCIMExtensionIsWireFormat(description)) {
          // For MessageSet fields the message length will have already been
          // read.
          [message mergeFromCodedInputStream:input
                           extensionRegistry:extensionRegistry];
        } else {
          [input readMessage:message extensionRegistry:extensionRegistry];
        }
      }

      return message;
    }
  }

  return nil;
}
