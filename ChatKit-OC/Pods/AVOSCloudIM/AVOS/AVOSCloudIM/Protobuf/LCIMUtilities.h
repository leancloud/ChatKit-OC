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

#import "LCIMArray.h"
#import "LCIMMessage.h"
#import "LCIMRuntimeTypes.h"

CF_EXTERN_C_BEGIN

NS_ASSUME_NONNULL_BEGIN

/// Generates a string that should be a valid "Text Format" for the C++ version
/// of Protocol Buffers.
///
///  @param message    The message to generate from.
///  @param lineIndent A string to use as the prefix for all lines generated. Can
///                    be nil if no extra indent is needed.
///
/// @return A @c NSString with the Text Format of the message.
NSString *LCIMTextFormatForMessage(LCIMMessage *message,
                                  NSString * __nullable lineIndent);

/// Generates a string that should be a valid "Text Format" for the C++ version
/// of Protocol Buffers.
///
///  @param unknownSet The unknown field set to generate from.
///  @param lineIndent A string to use as the prefix for all lines generated. Can
///                    be nil if no extra indent is needed.
///
/// @return A @c NSString with the Text Format of the unknown field set.
NSString *LCIMTextFormatForUnknownFieldSet(LCIMUnknownFieldSet * __nullable unknownSet,
                                          NSString * __nullable lineIndent);

/// Test if the given field is set on a message.
BOOL LCIMMessageHasFieldNumberSet(LCIMMessage *self, uint32_t fieldNumber);
/// Test if the given field is set on a message.
BOOL LCIMMessageHasFieldSet(LCIMMessage *self, LCIMFieldDescriptor *field);

/// Clear the given field of a message.
void LCIMClearMessageField(LCIMMessage *self, LCIMFieldDescriptor *field);

//%PDDM-EXPAND GPB_ACCESSORS()
// This block of code is generated, do not edit it directly.


//
// Get/Set the given field of a message.
//

// Single Fields

/// Gets the value of a bytes field.
NSData *LCIMGetMessageBytesField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a bytes field.
void LCIMSetMessageBytesField(LCIMMessage *self, LCIMFieldDescriptor *field, NSData *value);

/// Gets the value of a string field.
NSString *LCIMGetMessageStringField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a string field.
void LCIMSetMessageStringField(LCIMMessage *self, LCIMFieldDescriptor *field, NSString *value);

/// Gets the value of a message field.
LCIMMessage *LCIMGetMessageMessageField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a message field.
void LCIMSetMessageMessageField(LCIMMessage *self, LCIMFieldDescriptor *field, LCIMMessage *value);

/// Gets the value of a group field.
LCIMMessage *LCIMGetMessageGroupField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a group field.
void LCIMSetMessageGroupField(LCIMMessage *self, LCIMFieldDescriptor *field, LCIMMessage *value);

/// Gets the value of a bool field.
BOOL LCIMGetMessageBoolField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a bool field.
void LCIMSetMessageBoolField(LCIMMessage *self, LCIMFieldDescriptor *field, BOOL value);

/// Gets the value of an int32 field.
int32_t LCIMGetMessageInt32Field(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of an int32 field.
void LCIMSetMessageInt32Field(LCIMMessage *self, LCIMFieldDescriptor *field, int32_t value);

/// Gets the value of an uint32 field.
uint32_t LCIMGetMessageUInt32Field(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of an uint32 field.
void LCIMSetMessageUInt32Field(LCIMMessage *self, LCIMFieldDescriptor *field, uint32_t value);

/// Gets the value of an int64 field.
int64_t LCIMGetMessageInt64Field(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of an int64 field.
void LCIMSetMessageInt64Field(LCIMMessage *self, LCIMFieldDescriptor *field, int64_t value);

/// Gets the value of an uint64 field.
uint64_t LCIMGetMessageUInt64Field(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of an uint64 field.
void LCIMSetMessageUInt64Field(LCIMMessage *self, LCIMFieldDescriptor *field, uint64_t value);

/// Gets the value of a float field.
float LCIMGetMessageFloatField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a float field.
void LCIMSetMessageFloatField(LCIMMessage *self, LCIMFieldDescriptor *field, float value);

/// Gets the value of a double field.
double LCIMGetMessageDoubleField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a double field.
void LCIMSetMessageDoubleField(LCIMMessage *self, LCIMFieldDescriptor *field, double value);

/// Get the given enum field of a message. For proto3, if the value isn't a
/// member of the enum, @c kGPBUnrecognizedEnumeratorValue will be returned.
/// LCIMGetMessageRawEnumField will bypass the check and return whatever value
/// was set.
int32_t LCIMGetMessageEnumField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Set the given enum field of a message. You can only set values that are
/// members of the enum.
void LCIMSetMessageEnumField(LCIMMessage *self, LCIMFieldDescriptor *field, int32_t value);
/// Get the given enum field of a message. No check is done to ensure the value
/// was defined in the enum.
int32_t LCIMGetMessageRawEnumField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Set the given enum field of a message. You can set the value to anything,
/// even a value that is not a member of the enum.
void LCIMSetMessageRawEnumField(LCIMMessage *self, LCIMFieldDescriptor *field, int32_t value);

// Repeated Fields

/// Gets the value of a repeated field.
///
/// The result will be @c GPB*Array or @c NSMutableArray based on the
/// field's type.
id LCIMGetMessageRepeatedField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a repeated field.
///
/// The value should be @c GPB*Array or @c NSMutableArray based on the
/// field's type.
void LCIMSetMessageRepeatedField(LCIMMessage *self, LCIMFieldDescriptor *field, id array);

// Map Fields

/// Gets the value of a map<> field.
///
/// The result will be @c GPB*Dictionary or @c NSMutableDictionary based on
/// the field's type.
id LCIMGetMessageMapField(LCIMMessage *self, LCIMFieldDescriptor *field);
/// Sets the value of a map<> field.
///
/// The object should be @c GPB*Dictionary or @c NSMutableDictionary based
/// on the field's type.
void LCIMSetMessageMapField(LCIMMessage *self, LCIMFieldDescriptor *field, id dictionary);

//%PDDM-EXPAND-END GPB_ACCESSORS()

// Returns an empty NSData to assign to byte fields when you wish
// to assign them to empty. Prevents allocating a lot of little [NSData data]
// objects.
NSData *LCIMEmptyNSData(void) __attribute__((pure));

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END


//%PDDM-DEFINE GPB_ACCESSORS()
//%
//%//
//%// Get/Set the given field of a message.
//%//
//%
//%// Single Fields
//%
//%GPB_ACCESSOR_SINGLE_FULL(Bytes, NSData, , *)
//%GPB_ACCESSOR_SINGLE_FULL(String, NSString, , *)
//%GPB_ACCESSOR_SINGLE_FULL(Message, LCIMMessage, , *)
//%GPB_ACCESSOR_SINGLE_FULL(Group, LCIMMessage, , *)
//%GPB_ACCESSOR_SINGLE(Bool, BOOL, )
//%GPB_ACCESSOR_SINGLE(Int32, int32_t, n)
//%GPB_ACCESSOR_SINGLE(UInt32, uint32_t, n)
//%GPB_ACCESSOR_SINGLE(Int64, int64_t, n)
//%GPB_ACCESSOR_SINGLE(UInt64, uint64_t, n)
//%GPB_ACCESSOR_SINGLE(Float, float, )
//%GPB_ACCESSOR_SINGLE(Double, double, )
//%/// Get the given enum field of a message. For proto3, if the value isn't a
//%/// member of the enum, @c kGPBUnrecognizedEnumeratorValue will be returned.
//%/// LCIMGetMessageRawEnumField will bypass the check and return whatever value
//%/// was set.
//%int32_t LCIMGetMessageEnumField(LCIMMessage *self, LCIMFieldDescriptor *field);
//%/// Set the given enum field of a message. You can only set values that are
//%/// members of the enum.
//%void LCIMSetMessageEnumField(LCIMMessage *self, LCIMFieldDescriptor *field, int32_t value);
//%/// Get the given enum field of a message. No check is done to ensure the value
//%/// was defined in the enum.
//%int32_t LCIMGetMessageRawEnumField(LCIMMessage *self, LCIMFieldDescriptor *field);
//%/// Set the given enum field of a message. You can set the value to anything,
//%/// even a value that is not a member of the enum.
//%void LCIMSetMessageRawEnumField(LCIMMessage *self, LCIMFieldDescriptor *field, int32_t value);
//%
//%// Repeated Fields
//%
//%/// Gets the value of a repeated field.
//%///
//%/// The result will be @c GPB*Array or @c NSMutableArray based on the
//%/// field's type.
//%id LCIMGetMessageRepeatedField(LCIMMessage *self, LCIMFieldDescriptor *field);
//%/// Sets the value of a repeated field.
//%///
//%/// The value should be @c GPB*Array or @c NSMutableArray based on the
//%/// field's type.
//%void LCIMSetMessageRepeatedField(LCIMMessage *self, LCIMFieldDescriptor *field, id array);
//%
//%// Map Fields
//%
//%/// Gets the value of a map<> field.
//%///
//%/// The result will be @c GPB*Dictionary or @c NSMutableDictionary based on
//%/// the field's type.
//%id LCIMGetMessageMapField(LCIMMessage *self, LCIMFieldDescriptor *field);
//%/// Sets the value of a map<> field.
//%///
//%/// The object should be @c GPB*Dictionary or @c NSMutableDictionary based
//%/// on the field's type.
//%void LCIMSetMessageMapField(LCIMMessage *self, LCIMFieldDescriptor *field, id dictionary);
//%

//%PDDM-DEFINE GPB_ACCESSOR_SINGLE(NAME, TYPE, AN)
//%GPB_ACCESSOR_SINGLE_FULL(NAME, TYPE, AN, )
//%PDDM-DEFINE GPB_ACCESSOR_SINGLE_FULL(NAME, TYPE, AN, TisP)
//%/// Gets the value of a##AN NAME$L field.
//%TYPE TisP##GPBGetMessage##NAME##Field(LCIMMessage *self, LCIMFieldDescriptor *field);
//%/// Sets the value of a##AN NAME$L field.
//%void GPBSetMessage##NAME##Field(LCIMMessage *self, LCIMFieldDescriptor *field, TYPE TisP##value);
//%
