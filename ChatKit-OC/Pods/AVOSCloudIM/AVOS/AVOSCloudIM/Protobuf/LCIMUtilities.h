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

/**
 * Generates a string that should be a valid "TextFormat" for the C++ version
 * of Protocol Buffers.
 *
 * @param message    The message to generate from.
 * @param lineIndent A string to use as the prefix for all lines generated. Can
 *                   be nil if no extra indent is needed.
 *
 * @return An NSString with the TextFormat of the message.
 **/
NSString *LCIMTextFormatForMessage(LCIMMessage *message,
                                  NSString * __nullable lineIndent);

/**
 * Generates a string that should be a valid "TextFormat" for the C++ version
 * of Protocol Buffers.
 *
 * @param unknownSet The unknown field set to generate from.
 * @param lineIndent A string to use as the prefix for all lines generated. Can
 *                   be nil if no extra indent is needed.
 *
 * @return An NSString with the TextFormat of the unknown field set.
 **/
NSString *LCIMTextFormatForUnknownFieldSet(LCIMUnknownFieldSet * __nullable unknownSet,
                                          NSString * __nullable lineIndent);

/**
 * Checks if the given field number is set on a message.
 *
 * @param self        The message to check.
 * @param fieldNumber The field number to check.
 *
 * @return YES if the field number is set on the given message.
 **/
BOOL LCIMMessageHasFieldNumberSet(LCIMMessage *self, uint32_t fieldNumber);

/**
 * Checks if the given field is set on a message.
 *
 * @param self  The message to check.
 * @param field The field to check.
 *
 * @return YES if the field is set on the given message.
 **/
BOOL LCIMMessageHasFieldSet(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Clears the given field for the given message.
 *
 * @param self  The message for which to clear the field.
 * @param field The field to clear.
 **/
void LCIMClearMessageField(LCIMMessage *self, LCIMFieldDescriptor *field);

//%PDDM-EXPAND GPB_ACCESSORS()
// This block of code is generated, do not edit it directly.


//
// Get/Set a given field from/to a message.
//

// Single Fields

/**
 * Gets the value of a bytes field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
NSData *LCIMGetMessageBytesField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a bytes field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageBytesField(LCIMMessage *self, LCIMFieldDescriptor *field, NSData *value);

/**
 * Gets the value of a string field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
NSString *LCIMGetMessageStringField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a string field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageStringField(LCIMMessage *self, LCIMFieldDescriptor *field, NSString *value);

/**
 * Gets the value of a message field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
LCIMMessage *LCIMGetMessageMessageField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a message field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageMessageField(LCIMMessage *self, LCIMFieldDescriptor *field, LCIMMessage *value);

/**
 * Gets the value of a group field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
LCIMMessage *LCIMGetMessageGroupField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a group field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageGroupField(LCIMMessage *self, LCIMFieldDescriptor *field, LCIMMessage *value);

/**
 * Gets the value of a bool field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
BOOL LCIMGetMessageBoolField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a bool field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageBoolField(LCIMMessage *self, LCIMFieldDescriptor *field, BOOL value);

/**
 * Gets the value of an int32 field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
int32_t LCIMGetMessageInt32Field(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of an int32 field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageInt32Field(LCIMMessage *self, LCIMFieldDescriptor *field, int32_t value);

/**
 * Gets the value of an uint32 field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
uint32_t LCIMGetMessageUInt32Field(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of an uint32 field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageUInt32Field(LCIMMessage *self, LCIMFieldDescriptor *field, uint32_t value);

/**
 * Gets the value of an int64 field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
int64_t LCIMGetMessageInt64Field(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of an int64 field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageInt64Field(LCIMMessage *self, LCIMFieldDescriptor *field, int64_t value);

/**
 * Gets the value of an uint64 field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
uint64_t LCIMGetMessageUInt64Field(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of an uint64 field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageUInt64Field(LCIMMessage *self, LCIMFieldDescriptor *field, uint64_t value);

/**
 * Gets the value of a float field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
float LCIMGetMessageFloatField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a float field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageFloatField(LCIMMessage *self, LCIMFieldDescriptor *field, float value);

/**
 * Gets the value of a double field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
double LCIMGetMessageDoubleField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a double field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void LCIMSetMessageDoubleField(LCIMMessage *self, LCIMFieldDescriptor *field, double value);

/**
 * Gets the given enum field of a message. For proto3, if the value isn't a
 * member of the enum, @c kGPBUnrecognizedEnumeratorValue will be returned.
 * LCIMGetMessageRawEnumField will bypass the check and return whatever value
 * was set.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 *
 * @return The enum value for the given field.
 **/
int32_t LCIMGetMessageEnumField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Set the given enum field of a message. You can only set values that are
 * members of the enum.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The enum value to set in the field.
 **/
void LCIMSetMessageEnumField(LCIMMessage *self,
                            LCIMFieldDescriptor *field,
                            int32_t value);

/**
 * Get the given enum field of a message. No check is done to ensure the value
 * was defined in the enum.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 *
 * @return The raw enum value for the given field.
 **/
int32_t LCIMGetMessageRawEnumField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Set the given enum field of a message. You can set the value to anything,
 * even a value that is not a member of the enum.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The raw enum value to set in the field.
 **/
void LCIMSetMessageRawEnumField(LCIMMessage *self,
                               LCIMFieldDescriptor *field,
                               int32_t value);

// Repeated Fields

/**
 * Gets the value of a repeated field.
 *
 * @param self  The message from which to get the field.
 * @param field The repeated field to get.
 *
 * @return A GPB*Array or an NSMutableArray based on the field's type.
 **/
id LCIMGetMessageRepeatedField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a repeated field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param array A GPB*Array or NSMutableArray based on the field's type.
 **/
void LCIMSetMessageRepeatedField(LCIMMessage *self,
                                LCIMFieldDescriptor *field,
                                id array);

// Map Fields

/**
 * Gets the value of a map<> field.
 *
 * @param self  The message from which to get the field.
 * @param field The repeated field to get.
 *
 * @return A GPB*Dictionary or NSMutableDictionary based on the field's type.
 **/
id LCIMGetMessageMapField(LCIMMessage *self, LCIMFieldDescriptor *field);

/**
 * Sets the value of a map<> field.
 *
 * @param self       The message into which to set the field.
 * @param field      The field to set.
 * @param dictionary A GPB*Dictionary or NSMutableDictionary based on the
 *                   field's type.
 **/
void LCIMSetMessageMapField(LCIMMessage *self,
                           LCIMFieldDescriptor *field,
                           id dictionary);

//%PDDM-EXPAND-END GPB_ACCESSORS()

/**
 * Returns an empty NSData to assign to byte fields when you wish to assign them
 * to empty. Prevents allocating a lot of little [NSData data] objects.
 **/
NSData *LCIMEmptyNSData(void) __attribute__((pure));

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END


//%PDDM-DEFINE GPB_ACCESSORS()
//%
//%//
//%// Get/Set a given field from/to a message.
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
//%/**
//% * Gets the given enum field of a message. For proto3, if the value isn't a
//% * member of the enum, @c kGPBUnrecognizedEnumeratorValue will be returned.
//% * LCIMGetMessageRawEnumField will bypass the check and return whatever value
//% * was set.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The field to get.
//% *
//% * @return The enum value for the given field.
//% **/
//%int32_t LCIMGetMessageEnumField(LCIMMessage *self, LCIMFieldDescriptor *field);
//%
//%/**
//% * Set the given enum field of a message. You can only set values that are
//% * members of the enum.
//% *
//% * @param self  The message into which to set the field.
//% * @param field The field to set.
//% * @param value The enum value to set in the field.
//% **/
//%void LCIMSetMessageEnumField(LCIMMessage *self,
//%                            LCIMFieldDescriptor *field,
//%                            int32_t value);
//%
//%/**
//% * Get the given enum field of a message. No check is done to ensure the value
//% * was defined in the enum.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The field to get.
//% *
//% * @return The raw enum value for the given field.
//% **/
//%int32_t LCIMGetMessageRawEnumField(LCIMMessage *self, LCIMFieldDescriptor *field);
//%
//%/**
//% * Set the given enum field of a message. You can set the value to anything,
//% * even a value that is not a member of the enum.
//% *
//% * @param self  The message into which to set the field.
//% * @param field The field to set.
//% * @param value The raw enum value to set in the field.
//% **/
//%void LCIMSetMessageRawEnumField(LCIMMessage *self,
//%                               LCIMFieldDescriptor *field,
//%                               int32_t value);
//%
//%// Repeated Fields
//%
//%/**
//% * Gets the value of a repeated field.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The repeated field to get.
//% *
//% * @return A GPB*Array or an NSMutableArray based on the field's type.
//% **/
//%id LCIMGetMessageRepeatedField(LCIMMessage *self, LCIMFieldDescriptor *field);
//%
//%/**
//% * Sets the value of a repeated field.
//% *
//% * @param self  The message into which to set the field.
//% * @param field The field to set.
//% * @param array A GPB*Array or NSMutableArray based on the field's type.
//% **/
//%void LCIMSetMessageRepeatedField(LCIMMessage *self,
//%                                LCIMFieldDescriptor *field,
//%                                id array);
//%
//%// Map Fields
//%
//%/**
//% * Gets the value of a map<> field.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The repeated field to get.
//% *
//% * @return A GPB*Dictionary or NSMutableDictionary based on the field's type.
//% **/
//%id LCIMGetMessageMapField(LCIMMessage *self, LCIMFieldDescriptor *field);
//%
//%/**
//% * Sets the value of a map<> field.
//% *
//% * @param self       The message into which to set the field.
//% * @param field      The field to set.
//% * @param dictionary A GPB*Dictionary or NSMutableDictionary based on the
//% *                   field's type.
//% **/
//%void LCIMSetMessageMapField(LCIMMessage *self,
//%                           LCIMFieldDescriptor *field,
//%                           id dictionary);
//%

//%PDDM-DEFINE GPB_ACCESSOR_SINGLE(NAME, TYPE, AN)
//%GPB_ACCESSOR_SINGLE_FULL(NAME, TYPE, AN, )
//%PDDM-DEFINE GPB_ACCESSOR_SINGLE_FULL(NAME, TYPE, AN, TisP)
//%/**
//% * Gets the value of a##AN NAME$L field.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The field to get.
//% **/
//%TYPE TisP##LCIMGetMessage##NAME##Field(LCIMMessage *self, LCIMFieldDescriptor *field);
//%
//%/**
//% * Sets the value of a##AN NAME$L field.
//% *
//% * @param self  The message into which to set the field.
//% * @param field The field to set.
//% * @param value The to set in the field.
//% **/
//%void LCIMSetMessage##NAME##Field(LCIMMessage *self, LCIMFieldDescriptor *field, TYPE TisP##value);
//%
