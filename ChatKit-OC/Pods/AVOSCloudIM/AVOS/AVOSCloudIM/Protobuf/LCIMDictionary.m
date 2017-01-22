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

#import "LCIMDictionary_PackagePrivate.h"

#import "LCIMCodedInputStream_PackagePrivate.h"
#import "LCIMCodedOutputStream_PackagePrivate.h"
#import "LCIMDescriptor_PackagePrivate.h"
#import "LCIMMessage_PackagePrivate.h"
#import "LCIMUtilities_PackagePrivate.h"

// ------------------------------ NOTE ------------------------------
// At the moment, this is all using NSNumbers in NSDictionaries under
// the hood, but it is all hidden so we can come back and optimize
// with direct CFDictionary usage later.  The reason that wasn't
// done yet is needing to support 32bit iOS builds.  Otherwise
// it would be pretty simple to store all this data in CFDictionaries
// directly.
// ------------------------------------------------------------------

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

// Used to include code only visible to specific versions of the static
// analyzer. Useful for wrapping code that only exists to silence the analyzer.
// Determine the values you want to use for BEGIN_APPLE_BUILD_VERSION,
// END_APPLE_BUILD_VERSION using:
//   xcrun clang -dM -E -x c /dev/null | grep __apple_build_version__
// Example usage:
//  #if GPB_STATIC_ANALYZER_ONLY(5621, 5623) ... #endif
#define GPB_STATIC_ANALYZER_ONLY(BEGIN_APPLE_BUILD_VERSION, END_APPLE_BUILD_VERSION) \
    (defined(__clang_analyzer__) && \
     (__apple_build_version__ >= BEGIN_APPLE_BUILD_VERSION && \
      __apple_build_version__ <= END_APPLE_BUILD_VERSION))

enum {
  kMapKeyFieldNumber = 1,
  kMapValueFieldNumber = 2,
};

static BOOL DictDefault_IsValidValue(int32_t value) {
  // Anything but the bad value marker is allowed.
  return (value != kGPBUnrecognizedEnumeratorValue);
}

//%PDDM-DEFINE SERIALIZE_SUPPORT_2_TYPE(VALUE_NAME, VALUE_TYPE, GPBDATATYPE_NAME1, GPBDATATYPE_NAME2)
//%static size_t ComputeDict##VALUE_NAME##FieldSize(VALUE_TYPE value, uint32_t fieldNum, GPBDataType dataType) {
//%  if (dataType == GPBDataType##GPBDATATYPE_NAME1) {
//%    return LCIMCompute##GPBDATATYPE_NAME1##Size(fieldNum, value);
//%  } else if (dataType == GPBDataType##GPBDATATYPE_NAME2) {
//%    return LCIMCompute##GPBDATATYPE_NAME2##Size(fieldNum, value);
//%  } else {
//%    NSCAssert(NO, @"Unexpected type %d", dataType);
//%    return 0;
//%  }
//%}
//%
//%static void WriteDict##VALUE_NAME##Field(LCIMCodedOutputStream *stream, VALUE_TYPE value, uint32_t fieldNum, GPBDataType dataType) {
//%  if (dataType == GPBDataType##GPBDATATYPE_NAME1) {
//%    [stream write##GPBDATATYPE_NAME1##:fieldNum value:value];
//%  } else if (dataType == GPBDataType##GPBDATATYPE_NAME2) {
//%    [stream write##GPBDATATYPE_NAME2##:fieldNum value:value];
//%  } else {
//%    NSCAssert(NO, @"Unexpected type %d", dataType);
//%  }
//%}
//%
//%PDDM-DEFINE SERIALIZE_SUPPORT_3_TYPE(VALUE_NAME, VALUE_TYPE, GPBDATATYPE_NAME1, GPBDATATYPE_NAME2, GPBDATATYPE_NAME3)
//%static size_t ComputeDict##VALUE_NAME##FieldSize(VALUE_TYPE value, uint32_t fieldNum, GPBDataType dataType) {
//%  if (dataType == GPBDataType##GPBDATATYPE_NAME1) {
//%    return LCIMCompute##GPBDATATYPE_NAME1##Size(fieldNum, value);
//%  } else if (dataType == GPBDataType##GPBDATATYPE_NAME2) {
//%    return LCIMCompute##GPBDATATYPE_NAME2##Size(fieldNum, value);
//%  } else if (dataType == GPBDataType##GPBDATATYPE_NAME3) {
//%    return LCIMCompute##GPBDATATYPE_NAME3##Size(fieldNum, value);
//%  } else {
//%    NSCAssert(NO, @"Unexpected type %d", dataType);
//%    return 0;
//%  }
//%}
//%
//%static void WriteDict##VALUE_NAME##Field(LCIMCodedOutputStream *stream, VALUE_TYPE value, uint32_t fieldNum, GPBDataType dataType) {
//%  if (dataType == GPBDataType##GPBDATATYPE_NAME1) {
//%    [stream write##GPBDATATYPE_NAME1##:fieldNum value:value];
//%  } else if (dataType == GPBDataType##GPBDATATYPE_NAME2) {
//%    [stream write##GPBDATATYPE_NAME2##:fieldNum value:value];
//%  } else if (dataType == GPBDataType##GPBDATATYPE_NAME3) {
//%    [stream write##GPBDATATYPE_NAME3##:fieldNum value:value];
//%  } else {
//%    NSCAssert(NO, @"Unexpected type %d", dataType);
//%  }
//%}
//%
//%PDDM-DEFINE SIMPLE_SERIALIZE_SUPPORT(VALUE_NAME, VALUE_TYPE, VisP)
//%static size_t ComputeDict##VALUE_NAME##FieldSize(VALUE_TYPE VisP##value, uint32_t fieldNum, GPBDataType dataType) {
//%  NSCAssert(dataType == GPBDataType##VALUE_NAME, @"bad type: %d", dataType);
//%  #pragma unused(dataType)  // For when asserts are off in release.
//%  return LCIMCompute##VALUE_NAME##Size(fieldNum, value);
//%}
//%
//%static void WriteDict##VALUE_NAME##Field(LCIMCodedOutputStream *stream, VALUE_TYPE VisP##value, uint32_t fieldNum, GPBDataType dataType) {
//%  NSCAssert(dataType == GPBDataType##VALUE_NAME, @"bad type: %d", dataType);
//%  #pragma unused(dataType)  // For when asserts are off in release.
//%  [stream write##VALUE_NAME##:fieldNum value:value];
//%}
//%
//%PDDM-DEFINE SERIALIZE_SUPPORT_HELPERS()
//%SERIALIZE_SUPPORT_3_TYPE(Int32, int32_t, Int32, SInt32, SFixed32)
//%SERIALIZE_SUPPORT_2_TYPE(UInt32, uint32_t, UInt32, Fixed32)
//%SERIALIZE_SUPPORT_3_TYPE(Int64, int64_t, Int64, SInt64, SFixed64)
//%SERIALIZE_SUPPORT_2_TYPE(UInt64, uint64_t, UInt64, Fixed64)
//%SIMPLE_SERIALIZE_SUPPORT(Bool, BOOL, )
//%SIMPLE_SERIALIZE_SUPPORT(Enum, int32_t, )
//%SIMPLE_SERIALIZE_SUPPORT(Float, float, )
//%SIMPLE_SERIALIZE_SUPPORT(Double, double, )
//%SIMPLE_SERIALIZE_SUPPORT(String, NSString, *)
//%SERIALIZE_SUPPORT_3_TYPE(Object, id, Message, String, Bytes)
//%PDDM-EXPAND SERIALIZE_SUPPORT_HELPERS()
// This block of code is generated, do not edit it directly.

static size_t ComputeDictInt32FieldSize(int32_t value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeInt32) {
    return LCIMComputeInt32Size(fieldNum, value);
  } else if (dataType == GPBDataTypeSInt32) {
    return LCIMComputeSInt32Size(fieldNum, value);
  } else if (dataType == GPBDataTypeSFixed32) {
    return LCIMComputeSFixed32Size(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictInt32Field(LCIMCodedOutputStream *stream, int32_t value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeInt32) {
    [stream writeInt32:fieldNum value:value];
  } else if (dataType == GPBDataTypeSInt32) {
    [stream writeSInt32:fieldNum value:value];
  } else if (dataType == GPBDataTypeSFixed32) {
    [stream writeSFixed32:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

static size_t ComputeDictUInt32FieldSize(uint32_t value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeUInt32) {
    return LCIMComputeUInt32Size(fieldNum, value);
  } else if (dataType == GPBDataTypeFixed32) {
    return LCIMComputeFixed32Size(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictUInt32Field(LCIMCodedOutputStream *stream, uint32_t value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeUInt32) {
    [stream writeUInt32:fieldNum value:value];
  } else if (dataType == GPBDataTypeFixed32) {
    [stream writeFixed32:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

static size_t ComputeDictInt64FieldSize(int64_t value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeInt64) {
    return LCIMComputeInt64Size(fieldNum, value);
  } else if (dataType == GPBDataTypeSInt64) {
    return LCIMComputeSInt64Size(fieldNum, value);
  } else if (dataType == GPBDataTypeSFixed64) {
    return LCIMComputeSFixed64Size(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictInt64Field(LCIMCodedOutputStream *stream, int64_t value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeInt64) {
    [stream writeInt64:fieldNum value:value];
  } else if (dataType == GPBDataTypeSInt64) {
    [stream writeSInt64:fieldNum value:value];
  } else if (dataType == GPBDataTypeSFixed64) {
    [stream writeSFixed64:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

static size_t ComputeDictUInt64FieldSize(uint64_t value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeUInt64) {
    return LCIMComputeUInt64Size(fieldNum, value);
  } else if (dataType == GPBDataTypeFixed64) {
    return LCIMComputeFixed64Size(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictUInt64Field(LCIMCodedOutputStream *stream, uint64_t value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeUInt64) {
    [stream writeUInt64:fieldNum value:value];
  } else if (dataType == GPBDataTypeFixed64) {
    [stream writeFixed64:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

static size_t ComputeDictBoolFieldSize(BOOL value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeBool, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return LCIMComputeBoolSize(fieldNum, value);
}

static void WriteDictBoolField(LCIMCodedOutputStream *stream, BOOL value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeBool, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeBool:fieldNum value:value];
}

static size_t ComputeDictEnumFieldSize(int32_t value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeEnum, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return LCIMComputeEnumSize(fieldNum, value);
}

static void WriteDictEnumField(LCIMCodedOutputStream *stream, int32_t value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeEnum, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeEnum:fieldNum value:value];
}

static size_t ComputeDictFloatFieldSize(float value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeFloat, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return LCIMComputeFloatSize(fieldNum, value);
}

static void WriteDictFloatField(LCIMCodedOutputStream *stream, float value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeFloat, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeFloat:fieldNum value:value];
}

static size_t ComputeDictDoubleFieldSize(double value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeDouble, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return LCIMComputeDoubleSize(fieldNum, value);
}

static void WriteDictDoubleField(LCIMCodedOutputStream *stream, double value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeDouble, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeDouble:fieldNum value:value];
}

static size_t ComputeDictStringFieldSize(NSString *value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeString, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return LCIMComputeStringSize(fieldNum, value);
}

static void WriteDictStringField(LCIMCodedOutputStream *stream, NSString *value, uint32_t fieldNum, GPBDataType dataType) {
  NSCAssert(dataType == GPBDataTypeString, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeString:fieldNum value:value];
}

static size_t ComputeDictObjectFieldSize(id value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeMessage) {
    return LCIMComputeMessageSize(fieldNum, value);
  } else if (dataType == GPBDataTypeString) {
    return LCIMComputeStringSize(fieldNum, value);
  } else if (dataType == GPBDataTypeBytes) {
    return LCIMComputeBytesSize(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictObjectField(LCIMCodedOutputStream *stream, id value, uint32_t fieldNum, GPBDataType dataType) {
  if (dataType == GPBDataTypeMessage) {
    [stream writeMessage:fieldNum value:value];
  } else if (dataType == GPBDataTypeString) {
    [stream writeString:fieldNum value:value];
  } else if (dataType == GPBDataTypeBytes) {
    [stream writeBytes:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

//%PDDM-EXPAND-END SERIALIZE_SUPPORT_HELPERS()

size_t LCIMDictionaryComputeSizeInternalHelper(NSDictionary *dict, LCIMFieldDescriptor *field) {
  GPBDataType mapValueType = LCIMGetFieldDataType(field);
  __block size_t result = 0;
  [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = LCIMComputeStringSize(kMapKeyFieldNumber, key);
    msgSize += ComputeDictObjectFieldSize(obj, kMapValueFieldNumber, mapValueType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * dict.count;
  return result;
}

void LCIMDictionaryWriteToStreamInternalHelper(LCIMCodedOutputStream *outputStream,
                                              NSDictionary *dict,
                                              LCIMFieldDescriptor *field) {
  NSCAssert(field.mapKeyDataType == GPBDataTypeString, @"Unexpected key type");
  GPBDataType mapValueType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = LCIMComputeStringSize(kMapKeyFieldNumber, key);
    msgSize += ComputeDictObjectFieldSize(obj, kMapValueFieldNumber, mapValueType);

    // Write the size and fields.
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    [outputStream writeString:kMapKeyFieldNumber value:key];
    WriteDictObjectField(outputStream, obj, kMapValueFieldNumber, mapValueType);
  }];
}

BOOL LCIMDictionaryIsInitializedInternalHelper(NSDictionary *dict, LCIMFieldDescriptor *field) {
  NSCAssert(field.mapKeyDataType == GPBDataTypeString, @"Unexpected key type");
  NSCAssert(LCIMGetFieldDataType(field) == GPBDataTypeMessage, @"Unexpected value type");
  #pragma unused(field)  // For when asserts are off in release.
  for (LCIMMessage *msg in [dict objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

// Note: if the type is an object, it the retain pass back to the caller.
static void ReadValue(LCIMCodedInputStream *stream,
                      GPBGenericValue *valueToFill,
                      GPBDataType type,
                      LCIMExtensionRegistry *registry,
                      LCIMFieldDescriptor *field) {
  switch (type) {
    case GPBDataTypeBool:
      valueToFill->valueBool = LCIMCodedInputStreamReadBool(&stream->state_);
      break;
    case GPBDataTypeFixed32:
      valueToFill->valueUInt32 = LCIMCodedInputStreamReadFixed32(&stream->state_);
      break;
    case GPBDataTypeSFixed32:
      valueToFill->valueInt32 = LCIMCodedInputStreamReadSFixed32(&stream->state_);
      break;
    case GPBDataTypeFloat:
      valueToFill->valueFloat = LCIMCodedInputStreamReadFloat(&stream->state_);
      break;
    case GPBDataTypeFixed64:
      valueToFill->valueUInt64 = LCIMCodedInputStreamReadFixed64(&stream->state_);
      break;
    case GPBDataTypeSFixed64:
      valueToFill->valueInt64 = LCIMCodedInputStreamReadSFixed64(&stream->state_);
      break;
    case GPBDataTypeDouble:
      valueToFill->valueDouble = LCIMCodedInputStreamReadDouble(&stream->state_);
      break;
    case GPBDataTypeInt32:
      valueToFill->valueInt32 = LCIMCodedInputStreamReadInt32(&stream->state_);
      break;
    case GPBDataTypeInt64:
      valueToFill->valueInt64 = LCIMCodedInputStreamReadInt32(&stream->state_);
      break;
    case GPBDataTypeSInt32:
      valueToFill->valueInt32 = LCIMCodedInputStreamReadSInt32(&stream->state_);
      break;
    case GPBDataTypeSInt64:
      valueToFill->valueInt64 = LCIMCodedInputStreamReadSInt64(&stream->state_);
      break;
    case GPBDataTypeUInt32:
      valueToFill->valueUInt32 = LCIMCodedInputStreamReadUInt32(&stream->state_);
      break;
    case GPBDataTypeUInt64:
      valueToFill->valueUInt64 = LCIMCodedInputStreamReadUInt64(&stream->state_);
      break;
    case GPBDataTypeBytes:
      [valueToFill->valueData release];
      valueToFill->valueData = LCIMCodedInputStreamReadRetainedBytes(&stream->state_);
      break;
    case GPBDataTypeString:
      [valueToFill->valueString release];
      valueToFill->valueString = LCIMCodedInputStreamReadRetainedString(&stream->state_);
      break;
    case GPBDataTypeMessage: {
      LCIMMessage *message = [[field.msgClass alloc] init];
      [stream readMessage:message extensionRegistry:registry];
      [valueToFill->valueMessage release];
      valueToFill->valueMessage = message;
      break;
    }
    case GPBDataTypeGroup:
      NSCAssert(NO, @"Can't happen");
      break;
    case GPBDataTypeEnum:
      valueToFill->valueEnum = LCIMCodedInputStreamReadEnum(&stream->state_);
      break;
  }
}

void LCIMDictionaryReadEntry(id mapDictionary,
                            LCIMCodedInputStream *stream,
                            LCIMExtensionRegistry *registry,
                            LCIMFieldDescriptor *field,
                            LCIMMessage *parentMessage) {
  GPBDataType keyDataType = field.mapKeyDataType;
  GPBDataType valueDataType = LCIMGetFieldDataType(field);

  GPBGenericValue key;
  GPBGenericValue value;
  // Zero them (but pick up any enum default for proto2).
  key.valueString = value.valueString = nil;
  if (valueDataType == GPBDataTypeEnum) {
    value = field.defaultValue;
  }

  LCIMCodedInputStreamState *state = &stream->state_;
  uint32_t keyTag =
      LCIMWireFormatMakeTag(kMapKeyFieldNumber, LCIMWireFormatForType(keyDataType, NO));
  uint32_t valueTag =
      LCIMWireFormatMakeTag(kMapValueFieldNumber, LCIMWireFormatForType(valueDataType, NO));

  BOOL hitError = NO;
  while (YES) {
    uint32_t tag = LCIMCodedInputStreamReadTag(state);
    if (tag == keyTag) {
      ReadValue(stream, &key, keyDataType, registry, field);
    } else if (tag == valueTag) {
      ReadValue(stream, &value, valueDataType, registry, field);
    } else if (tag == 0) {
      // zero signals EOF / limit reached
      break;
    } else {  // Unknown
      if (![stream skipField:tag]){
        hitError = YES;
        break;
      }
    }
  }

  if (!hitError) {
    // Handle the special defaults and/or missing key/value.
    if ((keyDataType == GPBDataTypeString) && (key.valueString == nil)) {
      key.valueString = [@"" retain];
    }
    if (LCIMDataTypeIsObject(valueDataType) && value.valueString == nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
      switch (valueDataType) {
        case GPBDataTypeString:
          value.valueString = [@"" retain];
          break;
        case GPBDataTypeBytes:
          value.valueData = [LCIMEmptyNSData() retain];
          break;
#if defined(__clang_analyzer__)
        case GPBDataTypeGroup:
          // Maps can't really have Groups as the value type, but this case is needed
          // so the analyzer won't report the posibility of send nil in for the value
          // in the NSMutableDictionary case below.
#endif
        case GPBDataTypeMessage: {
          value.valueMessage = [[field.msgClass alloc] init];
          break;
        }
        default:
          // Nothing
          break;
      }
#pragma clang diagnostic pop
    }

    if ((keyDataType == GPBDataTypeString) && LCIMDataTypeIsObject(valueDataType)) {
#if GPB_STATIC_ANALYZER_ONLY(6020053, 7000181)
     // Limited to Xcode 6.4 - 7.2, are known to fail here. The upper end can
     // be raised as needed for new Xcodes.
     //
     // This is only needed on a "shallow" analyze; on a "deep" analyze, the
     // existing code path gets this correct. In shallow, the analyzer decides
     // LCIMDataTypeIsObject(valueDataType) is both false and true on a single
     // path through this function, allowing nil to be used for the
     // setObject:forKey:.
     if (value.valueString == nil) {
       value.valueString = [@"" retain];
     }
#endif
      // mapDictionary is an NSMutableDictionary
      [(NSMutableDictionary *)mapDictionary setObject:value.valueString
                                               forKey:key.valueString];
    } else {
      if (valueDataType == GPBDataTypeEnum) {
        if (LCIMHasPreservingUnknownEnumSemantics([parentMessage descriptor].file.syntax) ||
            [field isValidEnumValue:value.valueEnum]) {
          [mapDictionary setGPBGenericValue:&value forGPBGenericValueKey:&key];
        } else {
          NSData *data = [mapDictionary serializedDataForUnknownValue:value.valueEnum
                                                               forKey:&key
                                                          keyDataType:keyDataType];
          [parentMessage addUnknownMapEntry:LCIMFieldNumber(field) value:data];
        }
      } else {
        [mapDictionary setGPBGenericValue:&value forGPBGenericValueKey:&key];
      }
    }
  }

  if (LCIMDataTypeIsObject(keyDataType)) {
    [key.valueString release];
  }
  if (LCIMDataTypeIsObject(valueDataType)) {
    [value.valueString release];
  }
}

//
// Macros for the common basic cases.
//

//%PDDM-DEFINE DICTIONARY_IMPL_FOR_POD_KEY(KEY_NAME, KEY_TYPE)
//%DICTIONARY_POD_IMPL_FOR_KEY(KEY_NAME, KEY_TYPE, , POD)
//%DICTIONARY_POD_KEY_TO_OBJECT_IMPL(KEY_NAME, KEY_TYPE, Object, id)

//%PDDM-DEFINE DICTIONARY_POD_IMPL_FOR_KEY(KEY_NAME, KEY_TYPE, KisP, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, UInt32, uint32_t, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Int32, int32_t, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, UInt64, uint64_t, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Int64, int64_t, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Bool, BOOL, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Float, float, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Double, double, KHELPER)
//%DICTIONARY_KEY_TO_ENUM_IMPL(KEY_NAME, KEY_TYPE, KisP, Enum, int32_t, KHELPER)

//%PDDM-DEFINE DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER)
//%DICTIONARY_COMMON_IMPL(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, POD, VALUE_NAME, value)

//%PDDM-DEFINE DICTIONARY_POD_KEY_TO_OBJECT_IMPL(KEY_NAME, KEY_TYPE, VALUE_NAME, VALUE_TYPE)
//%DICTIONARY_COMMON_IMPL(KEY_NAME, KEY_TYPE, , VALUE_NAME, VALUE_TYPE, POD, OBJECT, Object, object)

//%PDDM-DEFINE DICTIONARY_COMMON_IMPL(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR)
//%#pragma mark - KEY_NAME -> VALUE_NAME
//%
//%@implementation LCIM##KEY_NAME##VALUE_NAME##Dictionary {
//% @package
//%  NSMutableDictionary *_dictionary;
//%}
//%
//%+ (instancetype)dictionary {
//%  return [[[self alloc] initWith##VNAME##s:NULL forKeys:NULL count:0] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWith##VNAME##:(VALUE_TYPE)##VNAME_VAR
//%                      ##VNAME$S##  forKey:(KEY_TYPE##KisP$S##KisP)key {
//%  // Cast is needed so the compiler knows what class we are invoking initWith##VNAME##s:forKeys:count:
//%  // on to get the type correct.
//%  return [[(LCIM##KEY_NAME##VALUE_NAME##Dictionary*)[self alloc] initWith##VNAME##s:&##VNAME_VAR
//%               KEY_NAME$S VALUE_NAME$S                        ##VNAME$S##  forKeys:&key
//%               KEY_NAME$S VALUE_NAME$S                        ##VNAME$S##    count:1] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWith##VNAME##s:(const VALUE_TYPE [])##VNAME_VAR##s
//%                      ##VNAME$S##  forKeys:(const KEY_TYPE##KisP$S##KisP [])keys
//%                      ##VNAME$S##    count:(NSUInteger)count {
//%  // Cast is needed so the compiler knows what class we are invoking initWith##VNAME##s:forKeys:count:
//%  // on to get the type correct.
//%  return [[(LCIM##KEY_NAME##VALUE_NAME##Dictionary*)[self alloc] initWith##VNAME##s:##VNAME_VAR##s
//%               KEY_NAME$S VALUE_NAME$S                               forKeys:keys
//%               KEY_NAME$S VALUE_NAME$S                                 count:count] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithDictionary:(LCIM##KEY_NAME##VALUE_NAME##Dictionary *)dictionary {
//%  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
//%  // on to get the type correct.
//%  return [[(LCIM##KEY_NAME##VALUE_NAME##Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
//%  return [[[self alloc] initWithCapacity:numItems] autorelease];
//%}
//%
//%- (instancetype)init {
//%  return [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%}
//%
//%- (instancetype)initWith##VNAME##s:(const VALUE_TYPE [])##VNAME_VAR##s
//%                ##VNAME$S##  forKeys:(const KEY_TYPE##KisP$S##KisP [])keys
//%                ##VNAME$S##    count:(NSUInteger)count {
//%  self = [super init];
//%  if (self) {
//%    _dictionary = [[NSMutableDictionary alloc] init];
//%    if (count && VNAME_VAR##s && keys) {
//%      for (NSUInteger i = 0; i < count; ++i) {
//%DICTIONARY_VALIDATE_VALUE_##VHELPER(VNAME_VAR##s[i], ______)##DICTIONARY_VALIDATE_KEY_##KHELPER(keys[i], ______)        [_dictionary setObject:WRAPPED##VHELPER(VNAME_VAR##s[i]) forKey:WRAPPED##KHELPER(keys[i])];
//%      }
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithDictionary:(LCIM##KEY_NAME##VALUE_NAME##Dictionary *)dictionary {
//%  self = [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%  if (self) {
//%    if (dictionary) {
//%      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithCapacity:(NSUInteger)numItems {
//%  #pragma unused(numItems)
//%  return [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%}
//%
//%DICTIONARY_IMMUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR, )
//%
//%VALUE_FOR_KEY_##VHELPER(KEY_TYPE##KisP$S##KisP, VALUE_NAME, VALUE_TYPE, KHELPER)
//%
//%DICTIONARY_MUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR, )
//%
//%@end
//%

//%PDDM-DEFINE DICTIONARY_KEY_TO_ENUM_IMPL(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER)
//%DICTIONARY_KEY_TO_ENUM_IMPL2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, POD)
//%PDDM-DEFINE DICTIONARY_KEY_TO_ENUM_IMPL2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER)
//%#pragma mark - KEY_NAME -> VALUE_NAME
//%
//%@implementation LCIM##KEY_NAME##VALUE_NAME##Dictionary {
//% @package
//%  NSMutableDictionary *_dictionary;
//%  GPBEnumValidationFunc _validationFunc;
//%}
//%
//%@synthesize validationFunc = _validationFunc;
//%
//%+ (instancetype)dictionary {
//%  return [[[self alloc] initWithValidationFunction:NULL
//%                                         rawValues:NULL
//%                                           forKeys:NULL
//%                                             count:0] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func {
//%  return [[[self alloc] initWithValidationFunction:func
//%                                         rawValues:NULL
//%                                           forKeys:NULL
//%                                             count:0] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
//%                                        rawValue:(VALUE_TYPE)rawValue
//%                                          forKey:(KEY_TYPE##KisP$S##KisP)key {
//%  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
//%  // on to get the type correct.
//%  return [[(LCIM##KEY_NAME##VALUE_NAME##Dictionary*)[self alloc] initWithValidationFunction:func
//%               KEY_NAME$S VALUE_NAME$S                                         rawValues:&rawValue
//%               KEY_NAME$S VALUE_NAME$S                                           forKeys:&key
//%               KEY_NAME$S VALUE_NAME$S                                             count:1] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
//%                                       rawValues:(const VALUE_TYPE [])rawValues
//%                                         forKeys:(const KEY_TYPE##KisP$S##KisP [])keys
//%                                           count:(NSUInteger)count {
//%  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
//%  // on to get the type correct.
//%  return [[(LCIM##KEY_NAME##VALUE_NAME##Dictionary*)[self alloc] initWithValidationFunction:func
//%               KEY_NAME$S VALUE_NAME$S                                         rawValues:rawValues
//%               KEY_NAME$S VALUE_NAME$S                                           forKeys:keys
//%               KEY_NAME$S VALUE_NAME$S                                             count:count] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithDictionary:(LCIM##KEY_NAME##VALUE_NAME##Dictionary *)dictionary {
//%  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
//%  // on to get the type correct.
//%  return [[(LCIM##KEY_NAME##VALUE_NAME##Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
//%                                        capacity:(NSUInteger)numItems {
//%  return [[[self alloc] initWithValidationFunction:func capacity:numItems] autorelease];
//%}
//%
//%- (instancetype)init {
//%  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
//%}
//%
//%- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func {
//%  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
//%}
//%
//%- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
//%                                 rawValues:(const VALUE_TYPE [])rawValues
//%                                   forKeys:(const KEY_TYPE##KisP$S##KisP [])keys
//%                                     count:(NSUInteger)count {
//%  self = [super init];
//%  if (self) {
//%    _dictionary = [[NSMutableDictionary alloc] init];
//%    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
//%    if (count && rawValues && keys) {
//%      for (NSUInteger i = 0; i < count; ++i) {
//%DICTIONARY_VALIDATE_KEY_##KHELPER(keys[i], ______)        [_dictionary setObject:WRAPPED##VHELPER(rawValues[i]) forKey:WRAPPED##KHELPER(keys[i])];
//%      }
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithDictionary:(LCIM##KEY_NAME##VALUE_NAME##Dictionary *)dictionary {
//%  self = [self initWithValidationFunction:dictionary.validationFunc
//%                                rawValues:NULL
//%                                  forKeys:NULL
//%                                    count:0];
//%  if (self) {
//%    if (dictionary) {
//%      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
//%                                  capacity:(NSUInteger)numItems {
//%  #pragma unused(numItems)
//%  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
//%}
//%
//%DICTIONARY_IMMUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, Value, value, Raw)
//%
//%- (BOOL)getEnum:(VALUE_TYPE *)value forKey:(KEY_TYPE##KisP$S##KisP)key {
//%  NSNumber *wrapped = [_dictionary objectForKey:WRAPPED##KHELPER(key)];
//%  if (wrapped && value) {
//%    VALUE_TYPE result = UNWRAP##VALUE_NAME(wrapped);
//%    if (!_validationFunc(result)) {
//%      result = kGPBUnrecognizedEnumeratorValue;
//%    }
//%    *value = result;
//%  }
//%  return (wrapped != NULL);
//%}
//%
//%- (BOOL)getRawValue:(VALUE_TYPE *)rawValue forKey:(KEY_TYPE##KisP$S##KisP)key {
//%  NSNumber *wrapped = [_dictionary objectForKey:WRAPPED##KHELPER(key)];
//%  if (wrapped && rawValue) {
//%    *rawValue = UNWRAP##VALUE_NAME(wrapped);
//%  }
//%  return (wrapped != NULL);
//%}
//%
//%- (void)enumerateKeysAndEnumsUsingBlock:
//%    (void (^)(KEY_TYPE KisP##key, VALUE_TYPE value, BOOL *stop))block {
//%  GPBEnumValidationFunc func = _validationFunc;
//%  [_dictionary enumerateKeysAndObjectsUsingBlock:^(ENUM_TYPE##KHELPER(KEY_TYPE)##aKey,
//%                                                   ENUM_TYPE##VHELPER(VALUE_TYPE)##aValue,
//%                                                   BOOL *stop) {
//%      VALUE_TYPE unwrapped = UNWRAP##VALUE_NAME(aValue);
//%      if (!func(unwrapped)) {
//%        unwrapped = kGPBUnrecognizedEnumeratorValue;
//%      }
//%      block(UNWRAP##KEY_NAME(aKey), unwrapped, stop);
//%  }];
//%}
//%
//%DICTIONARY_MUTABLE_CORE2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, Value, Enum, value, Raw)
//%
//%- (void)setEnum:(VALUE_TYPE)value forKey:(KEY_TYPE##KisP$S##KisP)key {
//%DICTIONARY_VALIDATE_KEY_##KHELPER(key, )  if (!_validationFunc(value)) {
//%    [NSException raise:NSInvalidArgumentException
//%                format:@"LCIM##KEY_NAME##VALUE_NAME##Dictionary: Attempt to set an unknown enum value (%d)",
//%                       value];
//%  }
//%
//%  [_dictionary setObject:WRAPPED##VHELPER(value) forKey:WRAPPED##KHELPER(key)];
//%  if (_autocreator) {
//%    LCIMAutocreatedDictionaryModified(_autocreator, self);
//%  }
//%}
//%
//%@end
//%

//%PDDM-DEFINE DICTIONARY_IMMUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR, ACCESSOR_NAME)
//%- (void)dealloc {
//%  NSAssert(!_autocreator,
//%           @"%@: Autocreator must be cleared before release, autocreator: %@",
//%           [self class], _autocreator);
//%  [_dictionary release];
//%  [super dealloc];
//%}
//%
//%- (instancetype)copyWithZone:(NSZone *)zone {
//%  return [[LCIM##KEY_NAME##VALUE_NAME##Dictionary allocWithZone:zone] initWithDictionary:self];
//%}
//%
//%- (BOOL)isEqual:(id)other {
//%  if (self == other) {
//%    return YES;
//%  }
//%  if (![other isKindOfClass:[LCIM##KEY_NAME##VALUE_NAME##Dictionary class]]) {
//%    return NO;
//%  }
//%  LCIM##KEY_NAME##VALUE_NAME##Dictionary *otherDictionary = other;
//%  return [_dictionary isEqual:otherDictionary->_dictionary];
//%}
//%
//%- (NSUInteger)hash {
//%  return _dictionary.count;
//%}
//%
//%- (NSString *)description {
//%  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
//%}
//%
//%- (NSUInteger)count {
//%  return _dictionary.count;
//%}
//%
//%- (void)enumerateKeysAnd##ACCESSOR_NAME##VNAME##sUsingBlock:
//%    (void (^)(KEY_TYPE KisP##key, VALUE_TYPE VNAME_VAR, BOOL *stop))block {
//%  [_dictionary enumerateKeysAndObjectsUsingBlock:^(ENUM_TYPE##KHELPER(KEY_TYPE)##aKey,
//%                                                   ENUM_TYPE##VHELPER(VALUE_TYPE)##a##VNAME_VAR$u,
//%                                                   BOOL *stop) {
//%      block(UNWRAP##KEY_NAME(aKey), UNWRAP##VALUE_NAME(a##VNAME_VAR$u), stop);
//%  }];
//%}
//%
//%EXTRA_METHODS_##VHELPER(KEY_NAME, VALUE_NAME)- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
//%  NSUInteger count = _dictionary.count;
//%  if (count == 0) {
//%    return 0;
//%  }
//%
//%  GPBDataType valueDataType = LCIMGetFieldDataType(field);
//%  GPBDataType keyDataType = field.mapKeyDataType;
//%  __block size_t result = 0;
//%  [_dictionary enumerateKeysAndObjectsUsingBlock:^(ENUM_TYPE##KHELPER(KEY_TYPE)##aKey,
//%                                                   ENUM_TYPE##VHELPER(VALUE_TYPE)##a##VNAME_VAR$u##,
//%                                                   BOOL *stop) {
//%    #pragma unused(stop)
//%    size_t msgSize = ComputeDict##KEY_NAME##FieldSize(UNWRAP##KEY_NAME(aKey), kMapKeyFieldNumber, keyDataType);
//%    msgSize += ComputeDict##VALUE_NAME##FieldSize(UNWRAP##VALUE_NAME(a##VNAME_VAR$u), kMapValueFieldNumber, valueDataType);
//%    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
//%  }];
//%  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
//%  result += tagSize * count;
//%  return result;
//%}
//%
//%- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
//%                         asField:(LCIMFieldDescriptor *)field {
//%  GPBDataType valueDataType = LCIMGetFieldDataType(field);
//%  GPBDataType keyDataType = field.mapKeyDataType;
//%  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
//%  [_dictionary enumerateKeysAndObjectsUsingBlock:^(ENUM_TYPE##KHELPER(KEY_TYPE)##aKey,
//%                                                   ENUM_TYPE##VHELPER(VALUE_TYPE)##a##VNAME_VAR$u,
//%                                                   BOOL *stop) {
//%    #pragma unused(stop)
//%    // Write the tag.
//%    [outputStream writeInt32NoTag:tag];
//%    // Write the size of the message.
//%    size_t msgSize = ComputeDict##KEY_NAME##FieldSize(UNWRAP##KEY_NAME(aKey), kMapKeyFieldNumber, keyDataType);
//%    msgSize += ComputeDict##VALUE_NAME##FieldSize(UNWRAP##VALUE_NAME(a##VNAME_VAR$u), kMapValueFieldNumber, valueDataType);
//%    [outputStream writeInt32NoTag:(int32_t)msgSize];
//%    // Write the fields.
//%    WriteDict##KEY_NAME##Field(outputStream, UNWRAP##KEY_NAME(aKey), kMapKeyFieldNumber, keyDataType);
//%    WriteDict##VALUE_NAME##Field(outputStream, UNWRAP##VALUE_NAME(a##VNAME_VAR$u), kMapValueFieldNumber, valueDataType);
//%  }];
//%}
//%
//%SERIAL_DATA_FOR_ENTRY_##VHELPER(KEY_NAME, VALUE_NAME)- (void)setGPBGenericValue:(GPBGenericValue *)value
//%     forGPBGenericValueKey:(GPBGenericValue *)key {
//%  [_dictionary setObject:WRAPPED##VHELPER(value->##GPBVALUE_##VHELPER(VALUE_NAME)##) forKey:WRAPPED##KHELPER(key->value##KEY_NAME)];
//%}
//%
//%- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
//%  [self enumerateKeysAnd##ACCESSOR_NAME##VNAME##sUsingBlock:^(KEY_TYPE KisP##key, VALUE_TYPE VNAME_VAR, BOOL *stop) {
//%      #pragma unused(stop)
//%      block(TEXT_FORMAT_OBJ##KEY_NAME(key), TEXT_FORMAT_OBJ##VALUE_NAME(VNAME_VAR));
//%  }];
//%}
//%PDDM-DEFINE DICTIONARY_MUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR, ACCESSOR_NAME)
//%DICTIONARY_MUTABLE_CORE2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME, VNAME_VAR, ACCESSOR_NAME)
//%PDDM-DEFINE DICTIONARY_MUTABLE_CORE2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_REMOVE, VNAME_VAR, ACCESSOR_NAME)
//%- (void)add##ACCESSOR_NAME##EntriesFromDictionary:(LCIM##KEY_NAME##VALUE_NAME##Dictionary *)otherDictionary {
//%  if (otherDictionary) {
//%    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
//%    if (_autocreator) {
//%      LCIMAutocreatedDictionaryModified(_autocreator, self);
//%    }
//%  }
//%}
//%
//%- (void)set##ACCESSOR_NAME##VNAME##:(VALUE_TYPE)VNAME_VAR forKey:(KEY_TYPE##KisP$S##KisP)key {
//%DICTIONARY_VALIDATE_VALUE_##VHELPER(VNAME_VAR, )##DICTIONARY_VALIDATE_KEY_##KHELPER(key, )  [_dictionary setObject:WRAPPED##VHELPER(VNAME_VAR) forKey:WRAPPED##KHELPER(key)];
//%  if (_autocreator) {
//%    LCIMAutocreatedDictionaryModified(_autocreator, self);
//%  }
//%}
//%
//%- (void)remove##VNAME_REMOVE##ForKey:(KEY_TYPE##KisP$S##KisP)aKey {
//%  [_dictionary removeObjectForKey:WRAPPED##KHELPER(aKey)];
//%}
//%
//%- (void)removeAll {
//%  [_dictionary removeAllObjects];
//%}

//
// Custom Generation for Bool keys
//

//%PDDM-DEFINE DICTIONARY_BOOL_KEY_TO_POD_IMPL(VALUE_NAME, VALUE_TYPE)
//%DICTIONARY_BOOL_KEY_TO_VALUE_IMPL(VALUE_NAME, VALUE_TYPE, POD, VALUE_NAME, value)
//%PDDM-DEFINE DICTIONARY_BOOL_KEY_TO_OBJECT_IMPL(VALUE_NAME, VALUE_TYPE)
//%DICTIONARY_BOOL_KEY_TO_VALUE_IMPL(VALUE_NAME, VALUE_TYPE, OBJECT, Object, object)

//%PDDM-DEFINE DICTIONARY_BOOL_KEY_TO_VALUE_IMPL(VALUE_NAME, VALUE_TYPE, HELPER, VNAME, VNAME_VAR)
//%#pragma mark - Bool -> VALUE_NAME
//%
//%@implementation LCIMBool##VALUE_NAME##Dictionary {
//% @package
//%  VALUE_TYPE _values[2];
//%BOOL_DICT_HAS_STORAGE_##HELPER()}
//%
//%+ (instancetype)dictionary {
//%  return [[[self alloc] initWith##VNAME##s:NULL forKeys:NULL count:0] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWith##VNAME##:(VALUE_TYPE)VNAME_VAR
//%                      ##VNAME$S##  forKey:(BOOL)key {
//%  // Cast is needed so the compiler knows what class we are invoking initWith##VNAME##s:forKeys:count:
//%  // on to get the type correct.
//%  return [[(GPBBool##VALUE_NAME##Dictionary*)[self alloc] initWith##VNAME##s:&##VNAME_VAR
//%                    VALUE_NAME$S                        ##VNAME$S##  forKeys:&key
//%                    VALUE_NAME$S                        ##VNAME$S##    count:1] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWith##VNAME##s:(const VALUE_TYPE [])##VNAME_VAR##s
//%                      ##VNAME$S##  forKeys:(const BOOL [])keys
//%                      ##VNAME$S##    count:(NSUInteger)count {
//%  // Cast is needed so the compiler knows what class we are invoking initWith##VNAME##s:forKeys:count:
//%  // on to get the type correct.
//%  return [[(GPBBool##VALUE_NAME##Dictionary*)[self alloc] initWith##VNAME##s:##VNAME_VAR##s
//%                    VALUE_NAME$S                        ##VNAME$S##  forKeys:keys
//%                    VALUE_NAME$S                        ##VNAME$S##    count:count] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithDictionary:(GPBBool##VALUE_NAME##Dictionary *)dictionary {
//%  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
//%  // on to get the type correct.
//%  return [[(GPBBool##VALUE_NAME##Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
//%}
//%
//%+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
//%  return [[[self alloc] initWithCapacity:numItems] autorelease];
//%}
//%
//%- (instancetype)init {
//%  return [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%}
//%
//%BOOL_DICT_INITS_##HELPER(VALUE_NAME, VALUE_TYPE)
//%
//%- (instancetype)initWithCapacity:(NSUInteger)numItems {
//%  #pragma unused(numItems)
//%  return [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%}
//%
//%BOOL_DICT_DEALLOC##HELPER()
//%
//%- (instancetype)copyWithZone:(NSZone *)zone {
//%  return [[GPBBool##VALUE_NAME##Dictionary allocWithZone:zone] initWithDictionary:self];
//%}
//%
//%- (BOOL)isEqual:(id)other {
//%  if (self == other) {
//%    return YES;
//%  }
//%  if (![other isKindOfClass:[GPBBool##VALUE_NAME##Dictionary class]]) {
//%    return NO;
//%  }
//%  GPBBool##VALUE_NAME##Dictionary *otherDictionary = other;
//%  if ((BOOL_DICT_W_HAS##HELPER(0, ) != BOOL_DICT_W_HAS##HELPER(0, otherDictionary->)) ||
//%      (BOOL_DICT_W_HAS##HELPER(1, ) != BOOL_DICT_W_HAS##HELPER(1, otherDictionary->))) {
//%    return NO;
//%  }
//%  if ((BOOL_DICT_W_HAS##HELPER(0, ) && (NEQ_##HELPER(_values[0], otherDictionary->_values[0]))) ||
//%      (BOOL_DICT_W_HAS##HELPER(1, ) && (NEQ_##HELPER(_values[1], otherDictionary->_values[1])))) {
//%    return NO;
//%  }
//%  return YES;
//%}
//%
//%- (NSUInteger)hash {
//%  return (BOOL_DICT_W_HAS##HELPER(0, ) ? 1 : 0) + (BOOL_DICT_W_HAS##HELPER(1, ) ? 1 : 0);
//%}
//%
//%- (NSString *)description {
//%  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
//%  if (BOOL_DICT_W_HAS##HELPER(0, )) {
//%    [result appendFormat:@"NO: STR_FORMAT_##HELPER(VALUE_NAME)", _values[0]];
//%  }
//%  if (BOOL_DICT_W_HAS##HELPER(1, )) {
//%    [result appendFormat:@"YES: STR_FORMAT_##HELPER(VALUE_NAME)", _values[1]];
//%  }
//%  [result appendString:@" }"];
//%  return result;
//%}
//%
//%- (NSUInteger)count {
//%  return (BOOL_DICT_W_HAS##HELPER(0, ) ? 1 : 0) + (BOOL_DICT_W_HAS##HELPER(1, ) ? 1 : 0);
//%}
//%
//%BOOL_VALUE_FOR_KEY_##HELPER(VALUE_NAME, VALUE_TYPE)
//%
//%BOOL_SET_GPBVALUE_FOR_KEY_##HELPER(VALUE_NAME, VALUE_TYPE, VisP)
//%
//%- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
//%  if (BOOL_DICT_HAS##HELPER(0, )) {
//%    block(@"false", TEXT_FORMAT_OBJ##VALUE_NAME(_values[0]));
//%  }
//%  if (BOOL_DICT_W_HAS##HELPER(1, )) {
//%    block(@"true", TEXT_FORMAT_OBJ##VALUE_NAME(_values[1]));
//%  }
//%}
//%
//%- (void)enumerateKeysAnd##VNAME##sUsingBlock:
//%    (void (^)(BOOL key, VALUE_TYPE VNAME_VAR, BOOL *stop))block {
//%  BOOL stop = NO;
//%  if (BOOL_DICT_HAS##HELPER(0, )) {
//%    block(NO, _values[0], &stop);
//%  }
//%  if (!stop && BOOL_DICT_W_HAS##HELPER(1, )) {
//%    block(YES, _values[1], &stop);
//%  }
//%}
//%
//%BOOL_EXTRA_METHODS_##HELPER(Bool, VALUE_NAME)- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
//%  GPBDataType valueDataType = LCIMGetFieldDataType(field);
//%  NSUInteger count = 0;
//%  size_t result = 0;
//%  for (int i = 0; i < 2; ++i) {
//%    if (BOOL_DICT_HAS##HELPER(i, )) {
//%      ++count;
//%      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
//%      msgSize += ComputeDict##VALUE_NAME##FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
//%      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
//%    }
//%  }
//%  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
//%  result += tagSize * count;
//%  return result;
//%}
//%
//%- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
//%                         asField:(LCIMFieldDescriptor *)field {
//%  GPBDataType valueDataType = LCIMGetFieldDataType(field);
//%  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
//%  for (int i = 0; i < 2; ++i) {
//%    if (BOOL_DICT_HAS##HELPER(i, )) {
//%      // Write the tag.
//%      [outputStream writeInt32NoTag:tag];
//%      // Write the size of the message.
//%      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
//%      msgSize += ComputeDict##VALUE_NAME##FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
//%      [outputStream writeInt32NoTag:(int32_t)msgSize];
//%      // Write the fields.
//%      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
//%      WriteDict##VALUE_NAME##Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
//%    }
//%  }
//%}
//%
//%BOOL_DICT_MUTATIONS_##HELPER(VALUE_NAME, VALUE_TYPE)
//%
//%@end
//%


//
// Helpers for PODs
//

//%PDDM-DEFINE VALUE_FOR_KEY_POD(KEY_TYPE, VALUE_NAME, VALUE_TYPE, KHELPER)
//%- (BOOL)get##VALUE_NAME##:(nullable VALUE_TYPE *)value forKey:(KEY_TYPE)key {
//%  NSNumber *wrapped = [_dictionary objectForKey:WRAPPED##KHELPER(key)];
//%  if (wrapped && value) {
//%    *value = UNWRAP##VALUE_NAME(wrapped);
//%  }
//%  return (wrapped != NULL);
//%}
//%PDDM-DEFINE WRAPPEDPOD(VALUE)
//%@(VALUE)
//%PDDM-DEFINE UNWRAPUInt32(VALUE)
//%[VALUE unsignedIntValue]
//%PDDM-DEFINE UNWRAPInt32(VALUE)
//%[VALUE intValue]
//%PDDM-DEFINE UNWRAPUInt64(VALUE)
//%[VALUE unsignedLongLongValue]
//%PDDM-DEFINE UNWRAPInt64(VALUE)
//%[VALUE longLongValue]
//%PDDM-DEFINE UNWRAPBool(VALUE)
//%[VALUE boolValue]
//%PDDM-DEFINE UNWRAPFloat(VALUE)
//%[VALUE floatValue]
//%PDDM-DEFINE UNWRAPDouble(VALUE)
//%[VALUE doubleValue]
//%PDDM-DEFINE UNWRAPEnum(VALUE)
//%[VALUE intValue]
//%PDDM-DEFINE TEXT_FORMAT_OBJUInt32(VALUE)
//%[NSString stringWithFormat:@"%u", VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJInt32(VALUE)
//%[NSString stringWithFormat:@"%d", VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJUInt64(VALUE)
//%[NSString stringWithFormat:@"%llu", VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJInt64(VALUE)
//%[NSString stringWithFormat:@"%lld", VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJBool(VALUE)
//%(VALUE ? @"true" : @"false")
//%PDDM-DEFINE TEXT_FORMAT_OBJFloat(VALUE)
//%[NSString stringWithFormat:@"%.*g", FLT_DIG, VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJDouble(VALUE)
//%[NSString stringWithFormat:@"%.*lg", DBL_DIG, VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJEnum(VALUE)
//%@(VALUE)
//%PDDM-DEFINE ENUM_TYPEPOD(TYPE)
//%NSNumber *
//%PDDM-DEFINE NEQ_POD(VAL1, VAL2)
//%VAL1 != VAL2
//%PDDM-DEFINE EXTRA_METHODS_POD(KEY_NAME, VALUE_NAME)
// Empty
//%PDDM-DEFINE BOOL_EXTRA_METHODS_POD(KEY_NAME, VALUE_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD(KEY_NAME, VALUE_NAME)
//%SERIAL_DATA_FOR_ENTRY_POD_##VALUE_NAME(KEY_NAME)
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_UInt32(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Int32(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_UInt64(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Int64(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Bool(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Float(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Double(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Enum(KEY_NAME)
//%- (NSData *)serializedDataForUnknownValue:(int32_t)value
//%                                   forKey:(GPBGenericValue *)key
//%                              keyDataType:(GPBDataType)keyDataType {
//%  size_t msgSize = ComputeDict##KEY_NAME##FieldSize(key->value##KEY_NAME, kMapKeyFieldNumber, keyDataType);
//%  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, GPBDataTypeEnum);
//%  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
//%  LCIMCodedOutputStream *outputStream = [[LCIMCodedOutputStream alloc] initWithData:data];
//%  WriteDict##KEY_NAME##Field(outputStream, key->value##KEY_NAME, kMapKeyFieldNumber, keyDataType);
//%  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, GPBDataTypeEnum);
//%  [outputStream release];
//%  return data;
//%}
//%
//%PDDM-DEFINE GPBVALUE_POD(VALUE_NAME)
//%value##VALUE_NAME
//%PDDM-DEFINE DICTIONARY_VALIDATE_VALUE_POD(VALUE_NAME, EXTRA_INDENT)
// Empty
//%PDDM-DEFINE DICTIONARY_VALIDATE_KEY_POD(KEY_NAME, EXTRA_INDENT)
// Empty

//%PDDM-DEFINE BOOL_DICT_HAS_STORAGE_POD()
//%  BOOL _valueSet[2];
//%
//%PDDM-DEFINE BOOL_DICT_INITS_POD(VALUE_NAME, VALUE_TYPE)
//%- (instancetype)initWith##VALUE_NAME##s:(const VALUE_TYPE [])values
//%                 ##VALUE_NAME$S## forKeys:(const BOOL [])keys
//%                 ##VALUE_NAME$S##   count:(NSUInteger)count {
//%  self = [super init];
//%  if (self) {
//%    for (NSUInteger i = 0; i < count; ++i) {
//%      int idx = keys[i] ? 1 : 0;
//%      _values[idx] = values[i];
//%      _valueSet[idx] = YES;
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithDictionary:(GPBBool##VALUE_NAME##Dictionary *)dictionary {
//%  self = [self initWith##VALUE_NAME##s:NULL forKeys:NULL count:0];
//%  if (self) {
//%    if (dictionary) {
//%      for (int i = 0; i < 2; ++i) {
//%        if (dictionary->_valueSet[i]) {
//%          _values[i] = dictionary->_values[i];
//%          _valueSet[i] = YES;
//%        }
//%      }
//%    }
//%  }
//%  return self;
//%}
//%PDDM-DEFINE BOOL_DICT_DEALLOCPOD()
//%#if !defined(NS_BLOCK_ASSERTIONS)
//%- (void)dealloc {
//%  NSAssert(!_autocreator,
//%           @"%@: Autocreator must be cleared before release, autocreator: %@",
//%           [self class], _autocreator);
//%  [super dealloc];
//%}
//%#endif  // !defined(NS_BLOCK_ASSERTIONS)
//%PDDM-DEFINE BOOL_DICT_W_HASPOD(IDX, REF)
//%BOOL_DICT_HASPOD(IDX, REF)
//%PDDM-DEFINE BOOL_DICT_HASPOD(IDX, REF)
//%REF##_valueSet[IDX]
//%PDDM-DEFINE BOOL_VALUE_FOR_KEY_POD(VALUE_NAME, VALUE_TYPE)
//%- (BOOL)get##VALUE_NAME##:(VALUE_TYPE *)value forKey:(BOOL)key {
//%  int idx = (key ? 1 : 0);
//%  if (_valueSet[idx]) {
//%    if (value) {
//%      *value = _values[idx];
//%    }
//%    return YES;
//%  }
//%  return NO;
//%}
//%PDDM-DEFINE BOOL_SET_GPBVALUE_FOR_KEY_POD(VALUE_NAME, VALUE_TYPE, VisP)
//%- (void)setGPBGenericValue:(GPBGenericValue *)value
//%     forGPBGenericValueKey:(GPBGenericValue *)key {
//%  int idx = (key->valueBool ? 1 : 0);
//%  _values[idx] = value->value##VALUE_NAME;
//%  _valueSet[idx] = YES;
//%}
//%PDDM-DEFINE BOOL_DICT_MUTATIONS_POD(VALUE_NAME, VALUE_TYPE)
//%- (void)addEntriesFromDictionary:(GPBBool##VALUE_NAME##Dictionary *)otherDictionary {
//%  if (otherDictionary) {
//%    for (int i = 0; i < 2; ++i) {
//%      if (otherDictionary->_valueSet[i]) {
//%        _valueSet[i] = YES;
//%        _values[i] = otherDictionary->_values[i];
//%      }
//%    }
//%    if (_autocreator) {
//%      LCIMAutocreatedDictionaryModified(_autocreator, self);
//%    }
//%  }
//%}
//%
//%- (void)set##VALUE_NAME:(VALUE_TYPE)value forKey:(BOOL)key {
//%  int idx = (key ? 1 : 0);
//%  _values[idx] = value;
//%  _valueSet[idx] = YES;
//%  if (_autocreator) {
//%    LCIMAutocreatedDictionaryModified(_autocreator, self);
//%  }
//%}
//%
//%- (void)remove##VALUE_NAME##ForKey:(BOOL)aKey {
//%  _valueSet[aKey ? 1 : 0] = NO;
//%}
//%
//%- (void)removeAll {
//%  _valueSet[0] = NO;
//%  _valueSet[1] = NO;
//%}
//%PDDM-DEFINE STR_FORMAT_POD(VALUE_NAME)
//%STR_FORMAT_##VALUE_NAME()
//%PDDM-DEFINE STR_FORMAT_UInt32()
//%%u
//%PDDM-DEFINE STR_FORMAT_Int32()
//%%d
//%PDDM-DEFINE STR_FORMAT_UInt64()
//%%llu
//%PDDM-DEFINE STR_FORMAT_Int64()
//%%lld
//%PDDM-DEFINE STR_FORMAT_Bool()
//%%d
//%PDDM-DEFINE STR_FORMAT_Float()
//%%f
//%PDDM-DEFINE STR_FORMAT_Double()
//%%lf

//
// Helpers for Objects
//

//%PDDM-DEFINE VALUE_FOR_KEY_OBJECT(KEY_TYPE, VALUE_NAME, VALUE_TYPE, KHELPER)
//%- (VALUE_TYPE)objectForKey:(KEY_TYPE)key {
//%  VALUE_TYPE result = [_dictionary objectForKey:WRAPPED##KHELPER(key)];
//%  return result;
//%}
//%PDDM-DEFINE WRAPPEDOBJECT(VALUE)
//%VALUE
//%PDDM-DEFINE UNWRAPString(VALUE)
//%VALUE
//%PDDM-DEFINE UNWRAPObject(VALUE)
//%VALUE
//%PDDM-DEFINE TEXT_FORMAT_OBJString(VALUE)
//%VALUE
//%PDDM-DEFINE TEXT_FORMAT_OBJObject(VALUE)
//%VALUE
//%PDDM-DEFINE ENUM_TYPEOBJECT(TYPE)
//%ENUM_TYPEOBJECT_##TYPE()
//%PDDM-DEFINE ENUM_TYPEOBJECT_NSString()
//%NSString *
//%PDDM-DEFINE ENUM_TYPEOBJECT_id()
//%id ##
//%PDDM-DEFINE NEQ_OBJECT(VAL1, VAL2)
//%![VAL1 isEqual:VAL2]
//%PDDM-DEFINE EXTRA_METHODS_OBJECT(KEY_NAME, VALUE_NAME)
//%- (BOOL)isInitialized {
//%  for (LCIMMessage *msg in [_dictionary objectEnumerator]) {
//%    if (!msg.initialized) {
//%      return NO;
//%    }
//%  }
//%  return YES;
//%}
//%
//%- (instancetype)deepCopyWithZone:(NSZone *)zone {
//%  LCIM##KEY_NAME##VALUE_NAME##Dictionary *newDict =
//%      [[LCIM##KEY_NAME##VALUE_NAME##Dictionary alloc] init];
//%  [_dictionary enumerateKeysAndObjectsUsingBlock:^(id aKey,
//%                                                   LCIMMessage *msg,
//%                                                   BOOL *stop) {
//%    #pragma unused(stop)
//%    LCIMMessage *copiedMsg = [msg copyWithZone:zone];
//%    [newDict->_dictionary setObject:copiedMsg forKey:aKey];
//%    [copiedMsg release];
//%  }];
//%  return newDict;
//%}
//%
//%
//%PDDM-DEFINE BOOL_EXTRA_METHODS_OBJECT(KEY_NAME, VALUE_NAME)
//%- (BOOL)isInitialized {
//%  if (_values[0] && ![_values[0] isInitialized]) {
//%    return NO;
//%  }
//%  if (_values[1] && ![_values[1] isInitialized]) {
//%    return NO;
//%  }
//%  return YES;
//%}
//%
//%- (instancetype)deepCopyWithZone:(NSZone *)zone {
//%  LCIM##KEY_NAME##VALUE_NAME##Dictionary *newDict =
//%      [[LCIM##KEY_NAME##VALUE_NAME##Dictionary alloc] init];
//%  for (int i = 0; i < 2; ++i) {
//%    if (_values[i] != nil) {
//%      newDict->_values[i] = [_values[i] copyWithZone:zone];
//%    }
//%  }
//%  return newDict;
//%}
//%
//%
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_OBJECT(KEY_NAME, VALUE_NAME)
// Empty
//%PDDM-DEFINE GPBVALUE_OBJECT(VALUE_NAME)
//%valueString
//%PDDM-DEFINE DICTIONARY_VALIDATE_VALUE_OBJECT(VALUE_NAME, EXTRA_INDENT)
//%##EXTRA_INDENT$S##  if (!##VALUE_NAME) {
//%##EXTRA_INDENT$S##    [NSException raise:NSInvalidArgumentException
//%##EXTRA_INDENT$S##                format:@"Attempting to add nil object to a Dictionary"];
//%##EXTRA_INDENT$S##  }
//%
//%PDDM-DEFINE DICTIONARY_VALIDATE_KEY_OBJECT(KEY_NAME, EXTRA_INDENT)
//%##EXTRA_INDENT$S##  if (!##KEY_NAME) {
//%##EXTRA_INDENT$S##    [NSException raise:NSInvalidArgumentException
//%##EXTRA_INDENT$S##                format:@"Attempting to add nil key to a Dictionary"];
//%##EXTRA_INDENT$S##  }
//%

//%PDDM-DEFINE BOOL_DICT_HAS_STORAGE_OBJECT()
// Empty
//%PDDM-DEFINE BOOL_DICT_INITS_OBJECT(VALUE_NAME, VALUE_TYPE)
//%- (instancetype)initWithObjects:(const VALUE_TYPE [])objects
//%                        forKeys:(const BOOL [])keys
//%                          count:(NSUInteger)count {
//%  self = [super init];
//%  if (self) {
//%    for (NSUInteger i = 0; i < count; ++i) {
//%      if (!objects[i]) {
//%        [NSException raise:NSInvalidArgumentException
//%                    format:@"Attempting to add nil object to a Dictionary"];
//%      }
//%      int idx = keys[i] ? 1 : 0;
//%      [_values[idx] release];
//%      _values[idx] = (VALUE_TYPE)[objects[i] retain];
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithDictionary:(GPBBool##VALUE_NAME##Dictionary *)dictionary {
//%  self = [self initWithObjects:NULL forKeys:NULL count:0];
//%  if (self) {
//%    if (dictionary) {
//%      _values[0] = [dictionary->_values[0] retain];
//%      _values[1] = [dictionary->_values[1] retain];
//%    }
//%  }
//%  return self;
//%}
//%PDDM-DEFINE BOOL_DICT_DEALLOCOBJECT()
//%- (void)dealloc {
//%  NSAssert(!_autocreator,
//%           @"%@: Autocreator must be cleared before release, autocreator: %@",
//%           [self class], _autocreator);
//%  [_values[0] release];
//%  [_values[1] release];
//%  [super dealloc];
//%}
//%PDDM-DEFINE BOOL_DICT_W_HASOBJECT(IDX, REF)
//%(BOOL_DICT_HASOBJECT(IDX, REF))
//%PDDM-DEFINE BOOL_DICT_HASOBJECT(IDX, REF)
//%REF##_values[IDX] != nil
//%PDDM-DEFINE BOOL_VALUE_FOR_KEY_OBJECT(VALUE_NAME, VALUE_TYPE)
//%- (VALUE_TYPE)objectForKey:(BOOL)key {
//%  return _values[key ? 1 : 0];
//%}
//%PDDM-DEFINE BOOL_SET_GPBVALUE_FOR_KEY_OBJECT(VALUE_NAME, VALUE_TYPE, VisP)
//%- (void)setGPBGenericValue:(GPBGenericValue *)value
//%     forGPBGenericValueKey:(GPBGenericValue *)key {
//%  int idx = (key->valueBool ? 1 : 0);
//%  [_values[idx] release];
//%  _values[idx] = [value->valueString retain];
//%}

//%PDDM-DEFINE BOOL_DICT_MUTATIONS_OBJECT(VALUE_NAME, VALUE_TYPE)
//%- (void)addEntriesFromDictionary:(GPBBool##VALUE_NAME##Dictionary *)otherDictionary {
//%  if (otherDictionary) {
//%    for (int i = 0; i < 2; ++i) {
//%      if (otherDictionary->_values[i] != nil) {
//%        [_values[i] release];
//%        _values[i] = [otherDictionary->_values[i] retain];
//%      }
//%    }
//%    if (_autocreator) {
//%      LCIMAutocreatedDictionaryModified(_autocreator, self);
//%    }
//%  }
//%}
//%
//%- (void)setObject:(VALUE_TYPE)object forKey:(BOOL)key {
//%  if (!object) {
//%    [NSException raise:NSInvalidArgumentException
//%                format:@"Attempting to add nil object to a Dictionary"];
//%  }
//%  int idx = (key ? 1 : 0);
//%  [_values[idx] release];
//%  _values[idx] = [object retain];
//%  if (_autocreator) {
//%    LCIMAutocreatedDictionaryModified(_autocreator, self);
//%  }
//%}
//%
//%- (void)removeObjectForKey:(BOOL)aKey {
//%  int idx = (aKey ? 1 : 0);
//%  [_values[idx] release];
//%  _values[idx] = nil;
//%}
//%
//%- (void)removeAll {
//%  for (int i = 0; i < 2; ++i) {
//%    [_values[i] release];
//%    _values[i] = nil;
//%  }
//%}
//%PDDM-DEFINE STR_FORMAT_OBJECT(VALUE_NAME)
//%%@


//%PDDM-EXPAND DICTIONARY_IMPL_FOR_POD_KEY(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.

#pragma mark - UInt32 -> UInt32

@implementation LCIMUInt32UInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt32:(uint32_t)value
                              forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32UInt32Dictionary*)[self alloc] initWithUInt32s:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt32s:(const uint32_t [])values
                              forKeys:(const uint32_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32UInt32Dictionary*)[self alloc] initWithUInt32s:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32UInt32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt32UInt32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const uint32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32UInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32UInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32UInt32Dictionary class]]) {
    return NO;
  }
  LCIMUInt32UInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (^)(uint32_t key, uint32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], [aValue unsignedIntValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, [aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(uint32_t key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt32UInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Int32

@implementation LCIMUInt32Int32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt32:(int32_t)value
                             forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32Int32Dictionary*)[self alloc] initWithInt32s:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithInt32s:(const int32_t [])values
                             forKeys:(const uint32_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32Int32Dictionary*)[self alloc] initWithInt32s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32Int32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt32Int32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const uint32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32Int32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32Int32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32Int32Dictionary class]]) {
    return NO;
  }
  LCIMUInt32Int32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (^)(uint32_t key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(uint32_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt32Int32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> UInt64

@implementation LCIMUInt32UInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt64:(uint64_t)value
                              forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32UInt64Dictionary*)[self alloc] initWithUInt64s:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt64s:(const uint64_t [])values
                              forKeys:(const uint32_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32UInt64Dictionary*)[self alloc] initWithUInt64s:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32UInt64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt32UInt64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const uint32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32UInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32UInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32UInt64Dictionary class]]) {
    return NO;
  }
  LCIMUInt32UInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (^)(uint32_t key, uint64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], [aValue unsignedLongLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, [aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(uint32_t key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt32UInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Int64

@implementation LCIMUInt32Int64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt64:(int64_t)value
                             forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32Int64Dictionary*)[self alloc] initWithInt64s:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithInt64s:(const int64_t [])values
                             forKeys:(const uint32_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32Int64Dictionary*)[self alloc] initWithInt64s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32Int64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt32Int64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const uint32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32Int64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32Int64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32Int64Dictionary class]]) {
    return NO;
  }
  LCIMUInt32Int64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (^)(uint32_t key, int64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], [aValue longLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, [aValue longLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(uint32_t key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt32Int64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Bool

@implementation LCIMUInt32BoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithBools:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithBool:(BOOL)value
                            forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32BoolDictionary*)[self alloc] initWithBools:&value
                                                        forKeys:&key
                                                          count:1] autorelease];
}

+ (instancetype)dictionaryWithBools:(const BOOL [])values
                            forKeys:(const uint32_t [])keys
                              count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32BoolDictionary*)[self alloc] initWithBools:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32BoolDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt32BoolDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const uint32_t [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32BoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32BoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32BoolDictionary class]]) {
    return NO;
  }
  LCIMUInt32BoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (^)(uint32_t key, BOOL value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], [aValue boolValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, [aValue boolValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(uint32_t key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt32BoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Float

@implementation LCIMUInt32FloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithFloats:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithFloat:(float)value
                             forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32FloatDictionary*)[self alloc] initWithFloats:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithFloats:(const float [])values
                             forKeys:(const uint32_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32FloatDictionary*)[self alloc] initWithFloats:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32FloatDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt32FloatDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const uint32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32FloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32FloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32FloatDictionary class]]) {
    return NO;
  }
  LCIMUInt32FloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (^)(uint32_t key, float value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], [aValue floatValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, [aValue floatValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(uint32_t key, float value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt32FloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Double

@implementation LCIMUInt32DoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithDoubles:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithDouble:(double)value
                              forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32DoubleDictionary*)[self alloc] initWithDoubles:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithDoubles:(const double [])values
                              forKeys:(const uint32_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32DoubleDictionary*)[self alloc] initWithDoubles:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32DoubleDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt32DoubleDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const uint32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32DoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32DoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32DoubleDictionary class]]) {
    return NO;
  }
  LCIMUInt32DoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (^)(uint32_t key, double value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], [aValue doubleValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, [aValue doubleValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(uint32_t key, double value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt32DoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Enum

@implementation LCIMUInt32EnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  GPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

+ (instancetype)dictionary {
  return [[[self alloc] initWithValidationFunction:NULL
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func {
  return [[[self alloc] initWithValidationFunction:func
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        rawValue:(int32_t)rawValue
                                          forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32EnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                   rawValues:&rawValue
                                                                     forKeys:&key
                                                                       count:1] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                       rawValues:(const int32_t [])rawValues
                                         forKeys:(const uint32_t [])keys
                                           count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32EnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                   rawValues:rawValues
                                                                     forKeys:keys
                                                                       count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32EnumDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32EnumDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        capacity:(NSUInteger)numItems {
  return [[[self alloc] initWithValidationFunction:func capacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const uint32_t [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(rawValues[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32EnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32EnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32EnumDictionary class]]) {
    return NO;
  }
  LCIMUInt32EnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (^)(uint32_t key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType {
  size_t msgSize = ComputeDictUInt32FieldSize(key->valueUInt32, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, GPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  LCIMCodedOutputStream *outputStream = [[LCIMCodedOutputStream alloc] initWithData:data];
  WriteDictUInt32Field(outputStream, key->valueUInt32, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, GPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(uint32_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (^)(uint32_t key, int32_t value, BOOL *stop))block {
  GPBEnumValidationFunc func = _validationFunc;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kGPBUnrecognizedEnumeratorValue;
      }
      block([aKey unsignedIntValue], unwrapped, stop);
  }];
}

- (void)addRawEntriesFromDictionary:(LCIMUInt32EnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(uint32_t)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"LCIMUInt32EnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

#pragma mark - UInt32 -> Object

@implementation LCIMUInt32ObjectDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithObjects:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithObject:(id)object
                              forKey:(uint32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32ObjectDictionary*)[self alloc] initWithObjects:&object
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithObjects:(const id [])objects
                              forKeys:(const uint32_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt32ObjectDictionary*)[self alloc] initWithObjects:objects
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt32ObjectDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt32ObjectDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const uint32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && objects && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!objects[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil object to a Dictionary"];
        }
        [_dictionary setObject:objects[i] forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt32ObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt32ObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt32ObjectDictionary class]]) {
    return NO;
  }
  LCIMUInt32ObjectDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (^)(uint32_t key, id object, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
      block([aKey unsignedIntValue], aObject, stop);
  }];
}

- (BOOL)isInitialized {
  for (LCIMMessage *msg in [_dictionary objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  LCIMUInt32ObjectDictionary *newDict =
      [[LCIMUInt32ObjectDictionary alloc] init];
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(id aKey,
                                                   LCIMMessage *msg,
                                                   BOOL *stop) {
    #pragma unused(stop)
    LCIMMessage *copiedMsg = [msg copyWithZone:zone];
    [newDict->_dictionary setObject:copiedMsg forKey:aKey];
    [copiedMsg release];
  }];
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, [aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    WriteDictObjectField(outputStream, aObject, kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:value->valueString forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndObjectsUsingBlock:^(uint32_t key, id object, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], object);
  }];
}

- (id)objectForKey:(uint32_t)key {
  id result = [_dictionary objectForKey:@(key)];
  return result;
}

- (void)addEntriesFromDictionary:(LCIMUInt32ObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(uint32_t)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  [_dictionary setObject:object forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

//%PDDM-EXPAND DICTIONARY_IMPL_FOR_POD_KEY(Int32, int32_t)
// This block of code is generated, do not edit it directly.

#pragma mark - Int32 -> UInt32

@implementation LCIMInt32UInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt32:(uint32_t)value
                              forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32UInt32Dictionary*)[self alloc] initWithUInt32s:&value
                                                           forKeys:&key
                                                             count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt32s:(const uint32_t [])values
                              forKeys:(const int32_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32UInt32Dictionary*)[self alloc] initWithUInt32s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32UInt32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt32UInt32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const int32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32UInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32UInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32UInt32Dictionary class]]) {
    return NO;
  }
  LCIMInt32UInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (^)(int32_t key, uint32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey intValue], [aValue unsignedIntValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, [aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(int32_t key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt32UInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Int32

@implementation LCIMInt32Int32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt32:(int32_t)value
                             forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32Int32Dictionary*)[self alloc] initWithInt32s:&value
                                                         forKeys:&key
                                                           count:1] autorelease];
}

+ (instancetype)dictionaryWithInt32s:(const int32_t [])values
                             forKeys:(const int32_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32Int32Dictionary*)[self alloc] initWithInt32s:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32Int32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt32Int32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const int32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32Int32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32Int32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32Int32Dictionary class]]) {
    return NO;
  }
  LCIMInt32Int32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (^)(int32_t key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey intValue], [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(int32_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt32Int32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> UInt64

@implementation LCIMInt32UInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt64:(uint64_t)value
                              forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32UInt64Dictionary*)[self alloc] initWithUInt64s:&value
                                                           forKeys:&key
                                                             count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt64s:(const uint64_t [])values
                              forKeys:(const int32_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32UInt64Dictionary*)[self alloc] initWithUInt64s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32UInt64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt32UInt64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const int32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32UInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32UInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32UInt64Dictionary class]]) {
    return NO;
  }
  LCIMInt32UInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (^)(int32_t key, uint64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey intValue], [aValue unsignedLongLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, [aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(int32_t key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt32UInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Int64

@implementation LCIMInt32Int64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt64:(int64_t)value
                             forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32Int64Dictionary*)[self alloc] initWithInt64s:&value
                                                         forKeys:&key
                                                           count:1] autorelease];
}

+ (instancetype)dictionaryWithInt64s:(const int64_t [])values
                             forKeys:(const int32_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32Int64Dictionary*)[self alloc] initWithInt64s:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32Int64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt32Int64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const int32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32Int64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32Int64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32Int64Dictionary class]]) {
    return NO;
  }
  LCIMInt32Int64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (^)(int32_t key, int64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey intValue], [aValue longLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, [aValue longLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(int32_t key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt32Int64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Bool

@implementation LCIMInt32BoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithBools:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithBool:(BOOL)value
                            forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32BoolDictionary*)[self alloc] initWithBools:&value
                                                       forKeys:&key
                                                         count:1] autorelease];
}

+ (instancetype)dictionaryWithBools:(const BOOL [])values
                            forKeys:(const int32_t [])keys
                              count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32BoolDictionary*)[self alloc] initWithBools:values
                                                        forKeys:keys
                                                          count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32BoolDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt32BoolDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const int32_t [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32BoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32BoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32BoolDictionary class]]) {
    return NO;
  }
  LCIMInt32BoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (^)(int32_t key, BOOL value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey intValue], [aValue boolValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, [aValue boolValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(int32_t key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt32BoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Float

@implementation LCIMInt32FloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithFloats:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithFloat:(float)value
                             forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32FloatDictionary*)[self alloc] initWithFloats:&value
                                                         forKeys:&key
                                                           count:1] autorelease];
}

+ (instancetype)dictionaryWithFloats:(const float [])values
                             forKeys:(const int32_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32FloatDictionary*)[self alloc] initWithFloats:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32FloatDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt32FloatDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const int32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32FloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32FloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32FloatDictionary class]]) {
    return NO;
  }
  LCIMInt32FloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (^)(int32_t key, float value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey intValue], [aValue floatValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, [aValue floatValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(int32_t key, float value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt32FloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Double

@implementation LCIMInt32DoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithDoubles:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithDouble:(double)value
                              forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32DoubleDictionary*)[self alloc] initWithDoubles:&value
                                                           forKeys:&key
                                                             count:1] autorelease];
}

+ (instancetype)dictionaryWithDoubles:(const double [])values
                              forKeys:(const int32_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32DoubleDictionary*)[self alloc] initWithDoubles:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32DoubleDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt32DoubleDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const int32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32DoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32DoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32DoubleDictionary class]]) {
    return NO;
  }
  LCIMInt32DoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (^)(int32_t key, double value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey intValue], [aValue doubleValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, [aValue doubleValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(int32_t key, double value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt32DoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Enum

@implementation LCIMInt32EnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  GPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

+ (instancetype)dictionary {
  return [[[self alloc] initWithValidationFunction:NULL
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func {
  return [[[self alloc] initWithValidationFunction:func
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        rawValue:(int32_t)rawValue
                                          forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32EnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                  rawValues:&rawValue
                                                                    forKeys:&key
                                                                      count:1] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                       rawValues:(const int32_t [])rawValues
                                         forKeys:(const int32_t [])keys
                                           count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32EnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                  rawValues:rawValues
                                                                    forKeys:keys
                                                                      count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32EnumDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32EnumDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        capacity:(NSUInteger)numItems {
  return [[[self alloc] initWithValidationFunction:func capacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const int32_t [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(rawValues[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32EnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32EnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32EnumDictionary class]]) {
    return NO;
  }
  LCIMInt32EnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (^)(int32_t key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey intValue], [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType {
  size_t msgSize = ComputeDictInt32FieldSize(key->valueInt32, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, GPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  LCIMCodedOutputStream *outputStream = [[LCIMCodedOutputStream alloc] initWithData:data];
  WriteDictInt32Field(outputStream, key->valueInt32, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, GPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(int32_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (^)(int32_t key, int32_t value, BOOL *stop))block {
  GPBEnumValidationFunc func = _validationFunc;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kGPBUnrecognizedEnumeratorValue;
      }
      block([aKey intValue], unwrapped, stop);
  }];
}

- (void)addRawEntriesFromDictionary:(LCIMInt32EnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(int32_t)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"LCIMInt32EnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

#pragma mark - Int32 -> Object

@implementation LCIMInt32ObjectDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithObjects:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithObject:(id)object
                              forKey:(int32_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32ObjectDictionary*)[self alloc] initWithObjects:&object
                                                           forKeys:&key
                                                             count:1] autorelease];
}

+ (instancetype)dictionaryWithObjects:(const id [])objects
                              forKeys:(const int32_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt32ObjectDictionary*)[self alloc] initWithObjects:objects
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt32ObjectDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt32ObjectDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const int32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && objects && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!objects[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil object to a Dictionary"];
        }
        [_dictionary setObject:objects[i] forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt32ObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt32ObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt32ObjectDictionary class]]) {
    return NO;
  }
  LCIMInt32ObjectDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (^)(int32_t key, id object, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
      block([aKey intValue], aObject, stop);
  }];
}

- (BOOL)isInitialized {
  for (LCIMMessage *msg in [_dictionary objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  LCIMInt32ObjectDictionary *newDict =
      [[LCIMInt32ObjectDictionary alloc] init];
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(id aKey,
                                                   LCIMMessage *msg,
                                                   BOOL *stop) {
    #pragma unused(stop)
    LCIMMessage *copiedMsg = [msg copyWithZone:zone];
    [newDict->_dictionary setObject:copiedMsg forKey:aKey];
    [copiedMsg release];
  }];
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, [aKey intValue], kMapKeyFieldNumber, keyDataType);
    WriteDictObjectField(outputStream, aObject, kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:value->valueString forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndObjectsUsingBlock:^(int32_t key, id object, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], object);
  }];
}

- (id)objectForKey:(int32_t)key {
  id result = [_dictionary objectForKey:@(key)];
  return result;
}

- (void)addEntriesFromDictionary:(LCIMInt32ObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(int32_t)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  [_dictionary setObject:object forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

//%PDDM-EXPAND DICTIONARY_IMPL_FOR_POD_KEY(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.

#pragma mark - UInt64 -> UInt32

@implementation LCIMUInt64UInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt32:(uint32_t)value
                              forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64UInt32Dictionary*)[self alloc] initWithUInt32s:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt32s:(const uint32_t [])values
                              forKeys:(const uint64_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64UInt32Dictionary*)[self alloc] initWithUInt32s:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64UInt32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt64UInt32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const uint64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64UInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64UInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64UInt32Dictionary class]]) {
    return NO;
  }
  LCIMUInt64UInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (^)(uint64_t key, uint32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], [aValue unsignedIntValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, [aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(uint64_t key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt64UInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Int32

@implementation LCIMUInt64Int32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt32:(int32_t)value
                             forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64Int32Dictionary*)[self alloc] initWithInt32s:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithInt32s:(const int32_t [])values
                             forKeys:(const uint64_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64Int32Dictionary*)[self alloc] initWithInt32s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64Int32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt64Int32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const uint64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64Int32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64Int32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64Int32Dictionary class]]) {
    return NO;
  }
  LCIMUInt64Int32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (^)(uint64_t key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(uint64_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt64Int32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> UInt64

@implementation LCIMUInt64UInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt64:(uint64_t)value
                              forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64UInt64Dictionary*)[self alloc] initWithUInt64s:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt64s:(const uint64_t [])values
                              forKeys:(const uint64_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64UInt64Dictionary*)[self alloc] initWithUInt64s:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64UInt64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt64UInt64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const uint64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64UInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64UInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64UInt64Dictionary class]]) {
    return NO;
  }
  LCIMUInt64UInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (^)(uint64_t key, uint64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], [aValue unsignedLongLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, [aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(uint64_t key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt64UInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Int64

@implementation LCIMUInt64Int64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt64:(int64_t)value
                             forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64Int64Dictionary*)[self alloc] initWithInt64s:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithInt64s:(const int64_t [])values
                             forKeys:(const uint64_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64Int64Dictionary*)[self alloc] initWithInt64s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64Int64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt64Int64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const uint64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64Int64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64Int64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64Int64Dictionary class]]) {
    return NO;
  }
  LCIMUInt64Int64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (^)(uint64_t key, int64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], [aValue longLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, [aValue longLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(uint64_t key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt64Int64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Bool

@implementation LCIMUInt64BoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithBools:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithBool:(BOOL)value
                            forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64BoolDictionary*)[self alloc] initWithBools:&value
                                                        forKeys:&key
                                                          count:1] autorelease];
}

+ (instancetype)dictionaryWithBools:(const BOOL [])values
                            forKeys:(const uint64_t [])keys
                              count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64BoolDictionary*)[self alloc] initWithBools:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64BoolDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt64BoolDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const uint64_t [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64BoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64BoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64BoolDictionary class]]) {
    return NO;
  }
  LCIMUInt64BoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (^)(uint64_t key, BOOL value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], [aValue boolValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, [aValue boolValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(uint64_t key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt64BoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Float

@implementation LCIMUInt64FloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithFloats:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithFloat:(float)value
                             forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64FloatDictionary*)[self alloc] initWithFloats:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithFloats:(const float [])values
                             forKeys:(const uint64_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64FloatDictionary*)[self alloc] initWithFloats:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64FloatDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt64FloatDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const uint64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64FloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64FloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64FloatDictionary class]]) {
    return NO;
  }
  LCIMUInt64FloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (^)(uint64_t key, float value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], [aValue floatValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, [aValue floatValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(uint64_t key, float value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt64FloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Double

@implementation LCIMUInt64DoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithDoubles:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithDouble:(double)value
                              forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64DoubleDictionary*)[self alloc] initWithDoubles:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithDoubles:(const double [])values
                              forKeys:(const uint64_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64DoubleDictionary*)[self alloc] initWithDoubles:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64DoubleDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt64DoubleDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const uint64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64DoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64DoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64DoubleDictionary class]]) {
    return NO;
  }
  LCIMUInt64DoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (^)(uint64_t key, double value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], [aValue doubleValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, [aValue doubleValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(uint64_t key, double value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMUInt64DoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Enum

@implementation LCIMUInt64EnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  GPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

+ (instancetype)dictionary {
  return [[[self alloc] initWithValidationFunction:NULL
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func {
  return [[[self alloc] initWithValidationFunction:func
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        rawValue:(int32_t)rawValue
                                          forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64EnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                   rawValues:&rawValue
                                                                     forKeys:&key
                                                                       count:1] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                       rawValues:(const int32_t [])rawValues
                                         forKeys:(const uint64_t [])keys
                                           count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64EnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                   rawValues:rawValues
                                                                     forKeys:keys
                                                                       count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64EnumDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64EnumDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        capacity:(NSUInteger)numItems {
  return [[[self alloc] initWithValidationFunction:func capacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const uint64_t [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(rawValues[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64EnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64EnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64EnumDictionary class]]) {
    return NO;
  }
  LCIMUInt64EnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (^)(uint64_t key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType {
  size_t msgSize = ComputeDictUInt64FieldSize(key->valueUInt64, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, GPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  LCIMCodedOutputStream *outputStream = [[LCIMCodedOutputStream alloc] initWithData:data];
  WriteDictUInt64Field(outputStream, key->valueUInt64, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, GPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(uint64_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (^)(uint64_t key, int32_t value, BOOL *stop))block {
  GPBEnumValidationFunc func = _validationFunc;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kGPBUnrecognizedEnumeratorValue;
      }
      block([aKey unsignedLongLongValue], unwrapped, stop);
  }];
}

- (void)addRawEntriesFromDictionary:(LCIMUInt64EnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(uint64_t)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"LCIMUInt64EnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

#pragma mark - UInt64 -> Object

@implementation LCIMUInt64ObjectDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithObjects:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithObject:(id)object
                              forKey:(uint64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64ObjectDictionary*)[self alloc] initWithObjects:&object
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithObjects:(const id [])objects
                              forKeys:(const uint64_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMUInt64ObjectDictionary*)[self alloc] initWithObjects:objects
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMUInt64ObjectDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMUInt64ObjectDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const uint64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && objects && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!objects[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil object to a Dictionary"];
        }
        [_dictionary setObject:objects[i] forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMUInt64ObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMUInt64ObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMUInt64ObjectDictionary class]]) {
    return NO;
  }
  LCIMUInt64ObjectDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (^)(uint64_t key, id object, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
      block([aKey unsignedLongLongValue], aObject, stop);
  }];
}

- (BOOL)isInitialized {
  for (LCIMMessage *msg in [_dictionary objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  LCIMUInt64ObjectDictionary *newDict =
      [[LCIMUInt64ObjectDictionary alloc] init];
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(id aKey,
                                                   LCIMMessage *msg,
                                                   BOOL *stop) {
    #pragma unused(stop)
    LCIMMessage *copiedMsg = [msg copyWithZone:zone];
    [newDict->_dictionary setObject:copiedMsg forKey:aKey];
    [copiedMsg release];
  }];
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, [aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictObjectField(outputStream, aObject, kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:value->valueString forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndObjectsUsingBlock:^(uint64_t key, id object, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], object);
  }];
}

- (id)objectForKey:(uint64_t)key {
  id result = [_dictionary objectForKey:@(key)];
  return result;
}

- (void)addEntriesFromDictionary:(LCIMUInt64ObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(uint64_t)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  [_dictionary setObject:object forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

//%PDDM-EXPAND DICTIONARY_IMPL_FOR_POD_KEY(Int64, int64_t)
// This block of code is generated, do not edit it directly.

#pragma mark - Int64 -> UInt32

@implementation LCIMInt64UInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt32:(uint32_t)value
                              forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64UInt32Dictionary*)[self alloc] initWithUInt32s:&value
                                                           forKeys:&key
                                                             count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt32s:(const uint32_t [])values
                              forKeys:(const int64_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64UInt32Dictionary*)[self alloc] initWithUInt32s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64UInt32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt64UInt32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const int64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64UInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64UInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64UInt32Dictionary class]]) {
    return NO;
  }
  LCIMInt64UInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (^)(int64_t key, uint32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey longLongValue], [aValue unsignedIntValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, [aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(int64_t key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt64UInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Int32

@implementation LCIMInt64Int32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt32:(int32_t)value
                             forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64Int32Dictionary*)[self alloc] initWithInt32s:&value
                                                         forKeys:&key
                                                           count:1] autorelease];
}

+ (instancetype)dictionaryWithInt32s:(const int32_t [])values
                             forKeys:(const int64_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64Int32Dictionary*)[self alloc] initWithInt32s:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64Int32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt64Int32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const int64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64Int32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64Int32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64Int32Dictionary class]]) {
    return NO;
  }
  LCIMInt64Int32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (^)(int64_t key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey longLongValue], [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(int64_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt64Int32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> UInt64

@implementation LCIMInt64UInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt64:(uint64_t)value
                              forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64UInt64Dictionary*)[self alloc] initWithUInt64s:&value
                                                           forKeys:&key
                                                             count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt64s:(const uint64_t [])values
                              forKeys:(const int64_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64UInt64Dictionary*)[self alloc] initWithUInt64s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64UInt64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt64UInt64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const int64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64UInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64UInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64UInt64Dictionary class]]) {
    return NO;
  }
  LCIMInt64UInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (^)(int64_t key, uint64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey longLongValue], [aValue unsignedLongLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, [aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(int64_t key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt64UInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Int64

@implementation LCIMInt64Int64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt64:(int64_t)value
                             forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64Int64Dictionary*)[self alloc] initWithInt64s:&value
                                                         forKeys:&key
                                                           count:1] autorelease];
}

+ (instancetype)dictionaryWithInt64s:(const int64_t [])values
                             forKeys:(const int64_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64Int64Dictionary*)[self alloc] initWithInt64s:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64Int64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt64Int64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const int64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64Int64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64Int64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64Int64Dictionary class]]) {
    return NO;
  }
  LCIMInt64Int64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (^)(int64_t key, int64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey longLongValue], [aValue longLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, [aValue longLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(int64_t key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt64Int64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Bool

@implementation LCIMInt64BoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithBools:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithBool:(BOOL)value
                            forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64BoolDictionary*)[self alloc] initWithBools:&value
                                                       forKeys:&key
                                                         count:1] autorelease];
}

+ (instancetype)dictionaryWithBools:(const BOOL [])values
                            forKeys:(const int64_t [])keys
                              count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64BoolDictionary*)[self alloc] initWithBools:values
                                                        forKeys:keys
                                                          count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64BoolDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt64BoolDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const int64_t [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64BoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64BoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64BoolDictionary class]]) {
    return NO;
  }
  LCIMInt64BoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (^)(int64_t key, BOOL value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey longLongValue], [aValue boolValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, [aValue boolValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(int64_t key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt64BoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Float

@implementation LCIMInt64FloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithFloats:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithFloat:(float)value
                             forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64FloatDictionary*)[self alloc] initWithFloats:&value
                                                         forKeys:&key
                                                           count:1] autorelease];
}

+ (instancetype)dictionaryWithFloats:(const float [])values
                             forKeys:(const int64_t [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64FloatDictionary*)[self alloc] initWithFloats:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64FloatDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt64FloatDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const int64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64FloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64FloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64FloatDictionary class]]) {
    return NO;
  }
  LCIMInt64FloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (^)(int64_t key, float value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey longLongValue], [aValue floatValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, [aValue floatValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(int64_t key, float value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt64FloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Double

@implementation LCIMInt64DoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithDoubles:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithDouble:(double)value
                              forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64DoubleDictionary*)[self alloc] initWithDoubles:&value
                                                           forKeys:&key
                                                             count:1] autorelease];
}

+ (instancetype)dictionaryWithDoubles:(const double [])values
                              forKeys:(const int64_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64DoubleDictionary*)[self alloc] initWithDoubles:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64DoubleDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt64DoubleDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const int64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64DoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64DoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64DoubleDictionary class]]) {
    return NO;
  }
  LCIMInt64DoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (^)(int64_t key, double value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey longLongValue], [aValue doubleValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, [aValue doubleValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(int64_t key, double value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMInt64DoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Enum

@implementation LCIMInt64EnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  GPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

+ (instancetype)dictionary {
  return [[[self alloc] initWithValidationFunction:NULL
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func {
  return [[[self alloc] initWithValidationFunction:func
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        rawValue:(int32_t)rawValue
                                          forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64EnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                  rawValues:&rawValue
                                                                    forKeys:&key
                                                                      count:1] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                       rawValues:(const int32_t [])rawValues
                                         forKeys:(const int64_t [])keys
                                           count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64EnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                  rawValues:rawValues
                                                                    forKeys:keys
                                                                      count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64EnumDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64EnumDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        capacity:(NSUInteger)numItems {
  return [[[self alloc] initWithValidationFunction:func capacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const int64_t [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(rawValues[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64EnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64EnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64EnumDictionary class]]) {
    return NO;
  }
  LCIMInt64EnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (^)(int64_t key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block([aKey longLongValue], [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType {
  size_t msgSize = ComputeDictInt64FieldSize(key->valueInt64, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, GPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  LCIMCodedOutputStream *outputStream = [[LCIMCodedOutputStream alloc] initWithData:data];
  WriteDictInt64Field(outputStream, key->valueInt64, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, GPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(int64_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (^)(int64_t key, int32_t value, BOOL *stop))block {
  GPBEnumValidationFunc func = _validationFunc;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kGPBUnrecognizedEnumeratorValue;
      }
      block([aKey longLongValue], unwrapped, stop);
  }];
}

- (void)addRawEntriesFromDictionary:(LCIMInt64EnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(int64_t)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"LCIMInt64EnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

#pragma mark - Int64 -> Object

@implementation LCIMInt64ObjectDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithObjects:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithObject:(id)object
                              forKey:(int64_t)key {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64ObjectDictionary*)[self alloc] initWithObjects:&object
                                                           forKeys:&key
                                                             count:1] autorelease];
}

+ (instancetype)dictionaryWithObjects:(const id [])objects
                              forKeys:(const int64_t [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMInt64ObjectDictionary*)[self alloc] initWithObjects:objects
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMInt64ObjectDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMInt64ObjectDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const int64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && objects && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!objects[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil object to a Dictionary"];
        }
        [_dictionary setObject:objects[i] forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMInt64ObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMInt64ObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMInt64ObjectDictionary class]]) {
    return NO;
  }
  LCIMInt64ObjectDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (^)(int64_t key, id object, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
      block([aKey longLongValue], aObject, stop);
  }];
}

- (BOOL)isInitialized {
  for (LCIMMessage *msg in [_dictionary objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  LCIMInt64ObjectDictionary *newDict =
      [[LCIMInt64ObjectDictionary alloc] init];
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(id aKey,
                                                   LCIMMessage *msg,
                                                   BOOL *stop) {
    #pragma unused(stop)
    LCIMMessage *copiedMsg = [msg copyWithZone:zone];
    [newDict->_dictionary setObject:copiedMsg forKey:aKey];
    [copiedMsg release];
  }];
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aKey,
                                                   id aObject,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, [aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    WriteDictObjectField(outputStream, aObject, kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:value->valueString forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndObjectsUsingBlock:^(int64_t key, id object, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], object);
  }];
}

- (id)objectForKey:(int64_t)key {
  id result = [_dictionary objectForKey:@(key)];
  return result;
}

- (void)addEntriesFromDictionary:(LCIMInt64ObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(int64_t)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  [_dictionary setObject:object forKey:@(key)];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

//%PDDM-EXPAND DICTIONARY_POD_IMPL_FOR_KEY(String, NSString, *, OBJECT)
// This block of code is generated, do not edit it directly.

#pragma mark - String -> UInt32

@implementation LCIMStringUInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt32:(uint32_t)value
                              forKey:(NSString *)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringUInt32Dictionary*)[self alloc] initWithUInt32s:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt32s:(const uint32_t [])values
                              forKeys:(const NSString * [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringUInt32Dictionary*)[self alloc] initWithUInt32s:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMStringUInt32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMStringUInt32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const NSString * [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMStringUInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMStringUInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMStringUInt32Dictionary class]]) {
    return NO;
  }
  LCIMStringUInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (^)(NSString *key, uint32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block(aKey, [aValue unsignedIntValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, aKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, [aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(NSString *key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMStringUInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Int32

@implementation LCIMStringInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt32:(int32_t)value
                             forKey:(NSString *)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringInt32Dictionary*)[self alloc] initWithInt32s:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithInt32s:(const int32_t [])values
                             forKeys:(const NSString * [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringInt32Dictionary*)[self alloc] initWithInt32s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMStringInt32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMStringInt32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const NSString * [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMStringInt32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMStringInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMStringInt32Dictionary class]]) {
    return NO;
  }
  LCIMStringInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (^)(NSString *key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block(aKey, [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, aKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(NSString *key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMStringInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> UInt64

@implementation LCIMStringUInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt64:(uint64_t)value
                              forKey:(NSString *)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringUInt64Dictionary*)[self alloc] initWithUInt64s:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt64s:(const uint64_t [])values
                              forKeys:(const NSString * [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringUInt64Dictionary*)[self alloc] initWithUInt64s:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMStringUInt64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMStringUInt64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const NSString * [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMStringUInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMStringUInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMStringUInt64Dictionary class]]) {
    return NO;
  }
  LCIMStringUInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (^)(NSString *key, uint64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block(aKey, [aValue unsignedLongLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, aKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, [aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(NSString *key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMStringUInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Int64

@implementation LCIMStringInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt64:(int64_t)value
                             forKey:(NSString *)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringInt64Dictionary*)[self alloc] initWithInt64s:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithInt64s:(const int64_t [])values
                             forKeys:(const NSString * [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringInt64Dictionary*)[self alloc] initWithInt64s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMStringInt64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMStringInt64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const NSString * [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMStringInt64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMStringInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMStringInt64Dictionary class]]) {
    return NO;
  }
  LCIMStringInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (^)(NSString *key, int64_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block(aKey, [aValue longLongValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, aKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, [aValue longLongValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(NSString *key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMStringInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Bool

@implementation LCIMStringBoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithBools:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithBool:(BOOL)value
                            forKey:(NSString *)key {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringBoolDictionary*)[self alloc] initWithBools:&value
                                                        forKeys:&key
                                                          count:1] autorelease];
}

+ (instancetype)dictionaryWithBools:(const BOOL [])values
                            forKeys:(const NSString * [])keys
                              count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringBoolDictionary*)[self alloc] initWithBools:values
                                                         forKeys:keys
                                                           count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMStringBoolDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMStringBoolDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const NSString * [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMStringBoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMStringBoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMStringBoolDictionary class]]) {
    return NO;
  }
  LCIMStringBoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (^)(NSString *key, BOOL value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block(aKey, [aValue boolValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, aKey, kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, [aValue boolValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(NSString *key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block(key, (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMStringBoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Float

@implementation LCIMStringFloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithFloats:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithFloat:(float)value
                             forKey:(NSString *)key {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringFloatDictionary*)[self alloc] initWithFloats:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithFloats:(const float [])values
                             forKeys:(const NSString * [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringFloatDictionary*)[self alloc] initWithFloats:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMStringFloatDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMStringFloatDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const NSString * [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMStringFloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMStringFloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMStringFloatDictionary class]]) {
    return NO;
  }
  LCIMStringFloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (^)(NSString *key, float value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block(aKey, [aValue floatValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, aKey, kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, [aValue floatValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(NSString *key, float value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMStringFloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Double

@implementation LCIMStringDoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithDoubles:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithDouble:(double)value
                              forKey:(NSString *)key {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringDoubleDictionary*)[self alloc] initWithDoubles:&value
                                                            forKeys:&key
                                                              count:1] autorelease];
}

+ (instancetype)dictionaryWithDoubles:(const double [])values
                              forKeys:(const NSString * [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringDoubleDictionary*)[self alloc] initWithDoubles:values
                                                           forKeys:keys
                                                             count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMStringDoubleDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMStringDoubleDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const NSString * [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMStringDoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMStringDoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMStringDoubleDictionary class]]) {
    return NO;
  }
  LCIMStringDoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (^)(NSString *key, double value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block(aKey, [aValue doubleValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, aKey, kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, [aValue doubleValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(NSString *key, double value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(LCIMStringDoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Enum

@implementation LCIMStringEnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  GPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

+ (instancetype)dictionary {
  return [[[self alloc] initWithValidationFunction:NULL
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func {
  return [[[self alloc] initWithValidationFunction:func
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        rawValue:(int32_t)rawValue
                                          forKey:(NSString *)key {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringEnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                   rawValues:&rawValue
                                                                     forKeys:&key
                                                                       count:1] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                       rawValues:(const int32_t [])rawValues
                                         forKeys:(const NSString * [])keys
                                           count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringEnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                   rawValues:rawValues
                                                                     forKeys:keys
                                                                       count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMStringEnumDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMStringEnumDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        capacity:(NSUInteger)numItems {
  return [[[self alloc] initWithValidationFunction:func capacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const NSString * [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(rawValues[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMStringEnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMStringEnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMStringEnumDictionary class]]) {
    return NO;
  }
  LCIMStringEnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (^)(NSString *key, int32_t value, BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      block(aKey, [aValue intValue], stop);
  }];
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  NSUInteger count = _dictionary.count;
  if (count == 0) {
    return 0;
  }

  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  __block size_t result = 0;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }];
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  GPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
    #pragma unused(stop)
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, aKey, kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, [aValue intValue], kMapValueFieldNumber, valueDataType);
  }];
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType {
  size_t msgSize = ComputeDictStringFieldSize(key->valueString, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, GPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  LCIMCodedOutputStream *outputStream = [[LCIMCodedOutputStream alloc] initWithData:data];
  WriteDictStringField(outputStream, key->valueString, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, GPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(NSString *key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (^)(NSString *key, int32_t value, BOOL *stop))block {
  GPBEnumValidationFunc func = _validationFunc;
  [_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *aKey,
                                                   NSNumber *aValue,
                                                   BOOL *stop) {
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kGPBUnrecognizedEnumeratorValue;
      }
      block(aKey, unwrapped, stop);
  }];
}

- (void)addRawEntriesFromDictionary:(LCIMStringEnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"LCIMStringEnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

//%PDDM-EXPAND-END (5 expansions)


//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.

#pragma mark - Bool -> UInt32

@implementation LCIMBoolUInt32Dictionary {
 @package
  uint32_t _values[2];
  BOOL _valueSet[2];
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt32:(uint32_t)value
                              forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolUInt32Dictionary*)[self alloc] initWithUInt32s:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt32s:(const uint32_t [])values
                              forKeys:(const BOOL [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolUInt32Dictionary*)[self alloc] initWithUInt32s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolUInt32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMBoolUInt32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const BOOL [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolUInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolUInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolUInt32Dictionary class]]) {
    return NO;
  }
  LCIMBoolUInt32Dictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %u", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %u", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getUInt32:(uint32_t *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueUInt32;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%u", _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%u", _values[1]]);
  }
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (^)(BOOL key, uint32_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictUInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictUInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictUInt32Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(LCIMBoolUInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Int32, int32_t)
// This block of code is generated, do not edit it directly.

#pragma mark - Bool -> Int32

@implementation LCIMBoolInt32Dictionary {
 @package
  int32_t _values[2];
  BOOL _valueSet[2];
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt32s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt32:(int32_t)value
                             forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolInt32Dictionary*)[self alloc] initWithInt32s:&value
                                                        forKeys:&key
                                                          count:1] autorelease];
}

+ (instancetype)dictionaryWithInt32s:(const int32_t [])values
                             forKeys:(const BOOL [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt32s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolInt32Dictionary*)[self alloc] initWithInt32s:values
                                                        forKeys:keys
                                                          count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolInt32Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMBoolInt32Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const BOOL [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolInt32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolInt32Dictionary class]]) {
    return NO;
  }
  LCIMBoolInt32Dictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %d", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %d", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getInt32:(int32_t *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueInt32;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%d", _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%d", _values[1]]);
  }
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (^)(BOOL key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictInt32Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(LCIMBoolInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.

#pragma mark - Bool -> UInt64

@implementation LCIMBoolUInt64Dictionary {
 @package
  uint64_t _values[2];
  BOOL _valueSet[2];
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithUInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithUInt64:(uint64_t)value
                              forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolUInt64Dictionary*)[self alloc] initWithUInt64s:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithUInt64s:(const uint64_t [])values
                              forKeys:(const BOOL [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithUInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolUInt64Dictionary*)[self alloc] initWithUInt64s:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolUInt64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMBoolUInt64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const BOOL [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolUInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolUInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolUInt64Dictionary class]]) {
    return NO;
  }
  LCIMBoolUInt64Dictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %llu", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %llu", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getUInt64:(uint64_t *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueUInt64;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%llu", _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%llu", _values[1]]);
  }
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (^)(BOOL key, uint64_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictUInt64FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictUInt64FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictUInt64Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(LCIMBoolUInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Int64, int64_t)
// This block of code is generated, do not edit it directly.

#pragma mark - Bool -> Int64

@implementation LCIMBoolInt64Dictionary {
 @package
  int64_t _values[2];
  BOOL _valueSet[2];
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithInt64s:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithInt64:(int64_t)value
                             forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolInt64Dictionary*)[self alloc] initWithInt64s:&value
                                                        forKeys:&key
                                                          count:1] autorelease];
}

+ (instancetype)dictionaryWithInt64s:(const int64_t [])values
                             forKeys:(const BOOL [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithInt64s:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolInt64Dictionary*)[self alloc] initWithInt64s:values
                                                        forKeys:keys
                                                          count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolInt64Dictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMBoolInt64Dictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const BOOL [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolInt64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolInt64Dictionary class]]) {
    return NO;
  }
  LCIMBoolInt64Dictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %lld", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %lld", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getInt64:(int64_t *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueInt64;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%lld", _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%lld", _values[1]]);
  }
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (^)(BOOL key, int64_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictInt64FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictInt64FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictInt64Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(LCIMBoolInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Bool, BOOL)
// This block of code is generated, do not edit it directly.

#pragma mark - Bool -> Bool

@implementation LCIMBoolBoolDictionary {
 @package
  BOOL _values[2];
  BOOL _valueSet[2];
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithBools:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithBool:(BOOL)value
                            forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolBoolDictionary*)[self alloc] initWithBools:&value
                                                      forKeys:&key
                                                        count:1] autorelease];
}

+ (instancetype)dictionaryWithBools:(const BOOL [])values
                            forKeys:(const BOOL [])keys
                              count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithBools:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolBoolDictionary*)[self alloc] initWithBools:values
                                                      forKeys:keys
                                                        count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolBoolDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMBoolBoolDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const BOOL [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolBoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolBoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolBoolDictionary class]]) {
    return NO;
  }
  LCIMBoolBoolDictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %d", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %d", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getBool:(BOOL *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueBool;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", (_values[0] ? @"true" : @"false"));
  }
  if (_valueSet[1]) {
    block(@"true", (_values[1] ? @"true" : @"false"));
  }
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (^)(BOOL key, BOOL value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictBoolFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictBoolFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictBoolField(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(LCIMBoolBoolDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Float, float)
// This block of code is generated, do not edit it directly.

#pragma mark - Bool -> Float

@implementation LCIMBoolFloatDictionary {
 @package
  float _values[2];
  BOOL _valueSet[2];
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithFloats:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithFloat:(float)value
                             forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolFloatDictionary*)[self alloc] initWithFloats:&value
                                                        forKeys:&key
                                                          count:1] autorelease];
}

+ (instancetype)dictionaryWithFloats:(const float [])values
                             forKeys:(const BOOL [])keys
                               count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithFloats:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolFloatDictionary*)[self alloc] initWithFloats:values
                                                        forKeys:keys
                                                          count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolFloatDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMBoolFloatDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const BOOL [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolFloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolFloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolFloatDictionary class]]) {
    return NO;
  }
  LCIMBoolFloatDictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %f", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %f", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getFloat:(float *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueFloat;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%.*g", FLT_DIG, _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%.*g", FLT_DIG, _values[1]]);
  }
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (^)(BOOL key, float value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictFloatFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictFloatFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictFloatField(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(LCIMBoolFloatDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Double, double)
// This block of code is generated, do not edit it directly.

#pragma mark - Bool -> Double

@implementation LCIMBoolDoubleDictionary {
 @package
  double _values[2];
  BOOL _valueSet[2];
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithDoubles:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithDouble:(double)value
                              forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolDoubleDictionary*)[self alloc] initWithDoubles:&value
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithDoubles:(const double [])values
                              forKeys:(const BOOL [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithDoubles:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolDoubleDictionary*)[self alloc] initWithDoubles:values
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolDoubleDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMBoolDoubleDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const BOOL [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolDoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolDoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolDoubleDictionary class]]) {
    return NO;
  }
  LCIMBoolDoubleDictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %lf", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %lf", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getDouble:(double *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueDouble;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%.*lg", DBL_DIG, _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%.*lg", DBL_DIG, _values[1]]);
  }
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (^)(BOOL key, double value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictDoubleFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictDoubleFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictDoubleField(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(LCIMBoolDoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_OBJECT_IMPL(Object, id)
// This block of code is generated, do not edit it directly.

#pragma mark - Bool -> Object

@implementation LCIMBoolObjectDictionary {
 @package
  id _values[2];
}

+ (instancetype)dictionary {
  return [[[self alloc] initWithObjects:NULL forKeys:NULL count:0] autorelease];
}

+ (instancetype)dictionaryWithObject:(id)object
                              forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolObjectDictionary*)[self alloc] initWithObjects:&object
                                                          forKeys:&key
                                                            count:1] autorelease];
}

+ (instancetype)dictionaryWithObjects:(const id [])objects
                              forKeys:(const BOOL [])keys
                                count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithObjects:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolObjectDictionary*)[self alloc] initWithObjects:objects
                                                          forKeys:keys
                                                            count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolObjectDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithDictionary:
  // on to get the type correct.
  return [[(LCIMBoolObjectDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const BOOL [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      if (!objects[i]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Attempting to add nil object to a Dictionary"];
      }
      int idx = keys[i] ? 1 : 0;
      [_values[idx] release];
      _values[idx] = (id)[objects[i] retain];
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      _values[0] = [dictionary->_values[0] retain];
      _values[1] = [dictionary->_values[1] retain];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_values[0] release];
  [_values[1] release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolObjectDictionary class]]) {
    return NO;
  }
  LCIMBoolObjectDictionary *otherDictionary = other;
  if (((_values[0] != nil) != (otherDictionary->_values[0] != nil)) ||
      ((_values[1] != nil) != (otherDictionary->_values[1] != nil))) {
    return NO;
  }
  if (((_values[0] != nil) && (![_values[0] isEqual:otherDictionary->_values[0]])) ||
      ((_values[1] != nil) && (![_values[1] isEqual:otherDictionary->_values[1]]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return ((_values[0] != nil) ? 1 : 0) + ((_values[1] != nil) ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if ((_values[0] != nil)) {
    [result appendFormat:@"NO: %@", _values[0]];
  }
  if ((_values[1] != nil)) {
    [result appendFormat:@"YES: %@", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return ((_values[0] != nil) ? 1 : 0) + ((_values[1] != nil) ? 1 : 0);
}

- (id)objectForKey:(BOOL)key {
  return _values[key ? 1 : 0];
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  [_values[idx] release];
  _values[idx] = [value->valueString retain];
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_values[0] != nil) {
    block(@"false", _values[0]);
  }
  if ((_values[1] != nil)) {
    block(@"true", _values[1]);
  }
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (^)(BOOL key, id object, BOOL *stop))block {
  BOOL stop = NO;
  if (_values[0] != nil) {
    block(NO, _values[0], &stop);
  }
  if (!stop && (_values[1] != nil)) {
    block(YES, _values[1], &stop);
  }
}

- (BOOL)isInitialized {
  if (_values[0] && ![_values[0] isInitialized]) {
    return NO;
  }
  if (_values[1] && ![_values[1] isInitialized]) {
    return NO;
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  LCIMBoolObjectDictionary *newDict =
      [[LCIMBoolObjectDictionary alloc] init];
  for (int i = 0; i < 2; ++i) {
    if (_values[i] != nil) {
      newDict->_values[i] = [_values[i] copyWithZone:zone];
    }
  }
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_values[i] != nil) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictObjectFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_values[i] != nil) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictObjectFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictObjectField(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(LCIMBoolObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_values[i] != nil) {
        [_values[i] release];
        _values[i] = [otherDictionary->_values[i] retain];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(BOOL)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  int idx = (key ? 1 : 0);
  [_values[idx] release];
  _values[idx] = [object retain];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(BOOL)aKey {
  int idx = (aKey ? 1 : 0);
  [_values[idx] release];
  _values[idx] = nil;
}

- (void)removeAll {
  for (int i = 0; i < 2; ++i) {
    [_values[i] release];
    _values[i] = nil;
  }
}

@end

//%PDDM-EXPAND-END (8 expansions)

#pragma mark - Bool -> Enum

@implementation LCIMBoolEnumDictionary {
 @package
  GPBEnumValidationFunc _validationFunc;
  int32_t _values[2];
  BOOL _valueSet[2];
}

@synthesize validationFunc = _validationFunc;

+ (instancetype)dictionary {
  return [[[self alloc] initWithValidationFunction:NULL
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func {
  return [[[self alloc] initWithValidationFunction:func
                                         rawValues:NULL
                                           forKeys:NULL
                                             count:0] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                       rawValue:(int32_t)rawValue
                                          forKey:(BOOL)key {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolEnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                 rawValues:&rawValue
                                                                   forKeys:&key
                                                                     count:1] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                       rawValues:(const int32_t [])values
                                         forKeys:(const BOOL [])keys
                                           count:(NSUInteger)count {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolEnumDictionary*)[self alloc] initWithValidationFunction:func
                                                                 rawValues:values
                                                                   forKeys:keys
                                                                     count:count] autorelease];
}

+ (instancetype)dictionaryWithDictionary:(LCIMBoolEnumDictionary *)dictionary {
  // Cast is needed so the compiler knows what class we are invoking initWithValues:forKeys:count:
  // on to get the type correct.
  return [[(LCIMBoolEnumDictionary*)[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (instancetype)dictionaryWithValidationFunction:(GPBEnumValidationFunc)func
                                        capacity:(NSUInteger)numItems {
  return [[[self alloc] initWithValidationFunction:func capacity:numItems] autorelease];
}

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                rawValues:(const int32_t [])rawValues
                                   forKeys:(const BOOL [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = rawValues[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(LCIMBoolEnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(GPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
#pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[LCIMBoolEnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[LCIMBoolEnumDictionary class]]) {
    return NO;
  }
  LCIMBoolEnumDictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %d", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %d", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getEnum:(int32_t*)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      int32_t result = _values[idx];
      if (!_validationFunc(result)) {
        result = kGPBUnrecognizedEnumeratorValue;
      }
      *value = result;
    }
    return YES;
  }
  return NO;
}

- (BOOL)getRawValue:(int32_t*)rawValue forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (rawValue) {
      *rawValue = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (^)(BOOL key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (^)(BOOL key, int32_t rawValue, BOOL *stop))block {
  BOOL stop = NO;
  GPBEnumValidationFunc func = _validationFunc;
  int32_t validatedValue;
  if (_valueSet[0]) {
    validatedValue = _values[0];
    if (!func(validatedValue)) {
      validatedValue = kGPBUnrecognizedEnumeratorValue;
    }
    block(NO, validatedValue, &stop);
  }
  if (!stop && _valueSet[1]) {
    validatedValue = _values[1];
    if (!func(validatedValue)) {
      validatedValue = kGPBUnrecognizedEnumeratorValue;
    }
    block(YES, validatedValue, &stop);
  }
}

//%PDDM-EXPAND SERIAL_DATA_FOR_ENTRY_POD_Enum(Bool)
// This block of code is generated, do not edit it directly.

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType {
  size_t msgSize = ComputeDictBoolFieldSize(key->valueBool, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, GPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  LCIMCodedOutputStream *outputStream = [[LCIMCodedOutputStream alloc] initWithData:data];
  WriteDictBoolField(outputStream, key->valueBool, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, GPBDataTypeEnum);
  [outputStream release];
  return data;
}

//%PDDM-EXPAND-END SERIAL_DATA_FOR_ENTRY_POD_Enum(Bool)

- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += LCIMComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = LCIMComputeWireFormatTagSize(LCIMFieldNumber(field), GPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field {
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  uint32_t tag = LCIMWireFormatMakeTag(LCIMFieldNumber(field), LCIMWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      msgSize += ComputeDictInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, GPBDataTypeBool);
      WriteDictInt32Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", @(_values[0]));
  }
  if (_valueSet[1]) {
    block(@"true", @(_values[1]));
  }
}

- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueInt32;
  _valueSet[idx] = YES;
}

- (void)addRawEntriesFromDictionary:(LCIMBoolEnumDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      LCIMAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setEnum:(int32_t)value forKey:(BOOL)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"LCIMBoolEnumDictionary: Attempt to set an unknown enum value (%d)",
     value];
  }
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)setRawValue:(int32_t)rawValue forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = rawValue;
  _valueSet[idx] = YES;
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

#pragma mark - NSDictionary Subclass

@implementation LCIMAutocreatedDictionary {
  NSMutableDictionary *_dictionary;
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

#pragma mark Required NSDictionary overrides

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const id<NSCopying> [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] initWithObjects:objects
                                                       forKeys:keys
                                                         count:count];
  }
  return self;
}

- (NSUInteger)count {
  return [_dictionary count];
}

- (id)objectForKey:(id)aKey {
  return [_dictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator {
  if (_dictionary == nil) {
    _dictionary = [[NSMutableDictionary alloc] init];
  }
  return [_dictionary keyEnumerator];
}

#pragma mark Required NSMutableDictionary overrides

// Only need to call LCIMAutocreatedDictionaryModified() when adding things
// since we only autocreate empty dictionaries.

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
  if (_dictionary == nil) {
    _dictionary = [[NSMutableDictionary alloc] init];
  }
  [_dictionary setObject:anObject forKey:aKey];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(id)aKey {
  [_dictionary removeObjectForKey:aKey];
}

#pragma mark Extra things hooked

- (id)copyWithZone:(NSZone *)zone {
  if (_dictionary == nil) {
    _dictionary = [[NSMutableDictionary alloc] init];
  }
  return [_dictionary copyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
  if (_dictionary == nil) {
    _dictionary = [[NSMutableDictionary alloc] init];
  }
  return [_dictionary mutableCopyWithZone:zone];
}

- (id)objectForKeyedSubscript:(id)key {
  return [_dictionary objectForKeyedSubscript:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
  if (_dictionary == nil) {
    _dictionary = [[NSMutableDictionary alloc] init];
  }
  [_dictionary setObject:obj forKeyedSubscript:key];
  if (_autocreator) {
    LCIMAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key,
                                                    id obj,
                                                    BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:block];
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts
                                usingBlock:(void (^)(id key,
                                                     id obj,
                                                     BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsWithOptions:opts usingBlock:block];
}

@end

#pragma clang diagnostic pop
