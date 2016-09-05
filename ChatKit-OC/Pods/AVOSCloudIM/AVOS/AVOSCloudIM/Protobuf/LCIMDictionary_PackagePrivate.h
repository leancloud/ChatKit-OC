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

#import <Foundation/Foundation.h>

#import "LCIMDictionary.h"

@class LCIMCodedInputStream;
@class LCIMCodedOutputStream;
@class LCIMExtensionRegistry;
@class LCIMFieldDescriptor;

@protocol LCIMDictionaryInternalsProtocol
- (size_t)computeSerializedSizeAsField:(LCIMFieldDescriptor *)field;
- (void)writeToCodedOutputStream:(LCIMCodedOutputStream *)outputStream
                         asField:(LCIMFieldDescriptor *)field;
- (void)setGPBGenericValue:(GPBGenericValue *)value
     forGPBGenericValueKey:(GPBGenericValue *)key;
- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block;
@end

//%PDDM-DEFINE DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(KEY_NAME)
//%DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(KEY_NAME)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Object, Object)
//%PDDM-DEFINE DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(KEY_NAME)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, UInt32, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Int32, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, UInt64, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Int64, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Bool, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Float, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Double, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Enum, Enum)

//%PDDM-DEFINE DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, VALUE_NAME, HELPER)
//%@interface LCIM##KEY_NAME##VALUE_NAME##Dictionary () <LCIMDictionaryInternalsProtocol> {
//% @package
//%  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
//%}
//%EXTRA_DICTIONARY_PRIVATE_INTERFACES_##HELPER()@end
//%

//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Basic()
// Empty
//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Object()
//%- (BOOL)isInitialized;
//%- (instancetype)deepCopyWithZone:(NSZone *)zone
//%    __attribute__((ns_returns_retained));
//%
//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Enum()
//%- (NSData *)serializedDataForUnknownValue:(int32_t)value
//%                                   forKey:(GPBGenericValue *)key
//%                              keyDataType:(GPBDataType)keyDataType;
//%

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(UInt32)
// This block of code is generated, do not edit it directly.

@interface LCIMUInt32UInt32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt32Int32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt32UInt64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt32Int64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt32BoolDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt32FloatDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt32DoubleDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt32EnumDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType;
@end

@interface LCIMUInt32ObjectDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Int32)
// This block of code is generated, do not edit it directly.

@interface LCIMInt32UInt32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt32Int32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt32UInt64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt32Int64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt32BoolDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt32FloatDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt32DoubleDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt32EnumDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType;
@end

@interface LCIMInt32ObjectDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(UInt64)
// This block of code is generated, do not edit it directly.

@interface LCIMUInt64UInt32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt64Int32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt64UInt64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt64Int64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt64BoolDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt64FloatDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt64DoubleDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMUInt64EnumDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType;
@end

@interface LCIMUInt64ObjectDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Int64)
// This block of code is generated, do not edit it directly.

@interface LCIMInt64UInt32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt64Int32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt64UInt64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt64Int64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt64BoolDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt64FloatDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt64DoubleDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMInt64EnumDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType;
@end

@interface LCIMInt64ObjectDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Bool)
// This block of code is generated, do not edit it directly.

@interface LCIMBoolUInt32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMBoolInt32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMBoolUInt64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMBoolInt64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMBoolBoolDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMBoolFloatDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMBoolDoubleDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMBoolEnumDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType;
@end

@interface LCIMBoolObjectDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(String)
// This block of code is generated, do not edit it directly.

@interface LCIMStringUInt32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMStringInt32Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMStringUInt64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMStringInt64Dictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMStringBoolDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMStringFloatDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMStringDoubleDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

@interface LCIMStringEnumDictionary () <LCIMDictionaryInternalsProtocol> {
 @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(GPBGenericValue *)key
                              keyDataType:(GPBDataType)keyDataType;
@end

//%PDDM-EXPAND-END (6 expansions)

#pragma mark - NSDictionary Subclass

@interface LCIMAutocreatedDictionary : NSMutableDictionary {
  @package
  GPB_UNSAFE_UNRETAINED LCIMMessage *_autocreator;
}
@end

#pragma mark - Helpers

CF_EXTERN_C_BEGIN

// Helper to compute size when an NSDictionary is used for the map instead
// of a custom type.
size_t LCIMDictionaryComputeSizeInternalHelper(NSDictionary *dict,
                                              LCIMFieldDescriptor *field);

// Helper to write out when an NSDictionary is used for the map instead
// of a custom type.
void LCIMDictionaryWriteToStreamInternalHelper(
    LCIMCodedOutputStream *outputStream, NSDictionary *dict,
    LCIMFieldDescriptor *field);

// Helper to check message initialization when an NSDictionary is used for
// the map instead of a custom type.
BOOL LCIMDictionaryIsInitializedInternalHelper(NSDictionary *dict,
                                              LCIMFieldDescriptor *field);

// Helper to read a map instead.
void LCIMDictionaryReadEntry(id mapDictionary, LCIMCodedInputStream *stream,
                            LCIMExtensionRegistry *registry,
                            LCIMFieldDescriptor *field,
                            LCIMMessage *parentMessage);

CF_EXTERN_C_END
