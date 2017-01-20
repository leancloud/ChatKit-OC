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

#import "LCIMUtilities_PackagePrivate.h"

#import <objc/runtime.h>

#import "LCIMArray_PackagePrivate.h"
#import "LCIMDescriptor_PackagePrivate.h"
#import "LCIMDictionary_PackagePrivate.h"
#import "LCIMMessage_PackagePrivate.h"
#import "LCIMUnknownField.h"
#import "LCIMUnknownFieldSet.h"

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

static void AppendTextFormatForMessage(LCIMMessage *message,
                                       NSMutableString *toStr,
                                       NSString *lineIndent);

NSData *LCIMEmptyNSData(void) {
  static dispatch_once_t onceToken;
  static NSData *defaultNSData = nil;
  dispatch_once(&onceToken, ^{
    defaultNSData = [[NSData alloc] init];
  });
  return defaultNSData;
}

// -- About Version Checks --
// There's actually 3 places these checks all come into play:
// 1. When the generated source is compile into .o files, the header check
//    happens. This is checking the protoc used matches the library being used
//    when making the .o.
// 2. Every place a generated proto header is included in a developer's code,
//    the header check comes into play again. But this time it is checking that
//    the current library headers being used still support/match the ones for
//    the generated code.
// 3. At runtime the final check here (GPBCheckRuntimeVersionsInternal), is
//    called from the generated code passing in values captured when the
//    generated code's .o was made. This checks that at runtime the generated
//    code and runtime library match.

void LCIMCheckRuntimeVersionSupport(int32_t objcRuntimeVersion) {
  // NOTE: This is passing the value captured in the compiled code to check
  // against the values captured when the runtime support was compiled. This
  // ensures the library code isn't in a different framework/library that
  // was generated with a non matching version.
  if (GOOGLE_PROTOBUF_OBJC_VERSION < objcRuntimeVersion) {
    // Library is too old for headers.
    [NSException raise:NSInternalInconsistencyException
                format:@"Linked to ProtocolBuffer runtime version %d,"
                       @" but code compiled needing atleast %d!",
                       GOOGLE_PROTOBUF_OBJC_VERSION, objcRuntimeVersion];
  }
  if (objcRuntimeVersion < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION) {
    // Headers are too old for library.
    [NSException raise:NSInternalInconsistencyException
                format:@"Proto generation source compiled against runtime"
                       @" version %d, but this version of the runtime only"
                       @" supports back to %d!",
                       objcRuntimeVersion,
                       GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION];
  }
}

// This api is no longer used for version checks. 30001 is the last version
// using this old versioning model. When that support is removed, this function
// can be removed (along with the declaration in LCIMUtilities_PackagePrivate.h).
void LCIMCheckRuntimeVersionInternal(int32_t version) {
  LCIMInternalCompileAssert(GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION == 30001,
                           time_to_remove_this_old_version_shim);
  if (version != GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION) {
    [NSException raise:NSInternalInconsistencyException
                format:@"Linked to ProtocolBuffer runtime version %d,"
                       @" but code compiled with version %d!",
                       GOOGLE_PROTOBUF_OBJC_GEN_VERSION, version];
  }
}

BOOL LCIMMessageHasFieldNumberSet(LCIMMessage *self, uint32_t fieldNumber) {
  LCIMDescriptor *descriptor = [self descriptor];
  LCIMFieldDescriptor *field = [descriptor fieldWithNumber:fieldNumber];
  return LCIMMessageHasFieldSet(self, field);
}

BOOL LCIMMessageHasFieldSet(LCIMMessage *self, LCIMFieldDescriptor *field) {
  if (self == nil || field == nil) return NO;

  // Repeated/Map don't use the bit, they check the count.
  if (LCIMFieldIsMapOrArray(field)) {
    // Array/map type doesn't matter, since GPB*Array/NSArray and
    // GPB*Dictionary/NSDictionary all support -count;
    NSArray *arrayOrMap = LCIMGetObjectIvarWithFieldNoAutocreate(self, field);
    return (arrayOrMap.count > 0);
  } else {
    return LCIMGetHasIvarField(self, field);
  }
}

void LCIMClearMessageField(LCIMMessage *self, LCIMFieldDescriptor *field) {
  // If not set, nothing to do.
  if (!LCIMGetHasIvarField(self, field)) {
    return;
  }

  if (LCIMFieldStoresObject(field)) {
    // Object types are handled slightly differently, they need to be released.
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    id *typePtr = (id *)&storage[field->description_->offset];
    [*typePtr release];
    *typePtr = nil;
  } else {
    // POD types just need to clear the has bit as the Get* method will
    // fetch the default when needed.
  }
  LCIMSetHasIvarField(self, field, NO);
}

BOOL LCIMGetHasIvar(LCIMMessage *self, int32_t idx, uint32_t fieldNumber) {
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
  if (idx < 0) {
    NSCAssert(fieldNumber != 0, @"Invalid field number.");
    BOOL hasIvar = (self->messageStorage_->_has_storage_[-idx] == fieldNumber);
    return hasIvar;
  } else {
    NSCAssert(idx != GPBNoHasBit, @"Invalid has bit.");
    uint32_t byteIndex = idx / 32;
    uint32_t bitMask = (1 << (idx % 32));
    BOOL hasIvar =
        (self->messageStorage_->_has_storage_[byteIndex] & bitMask) ? YES : NO;
    return hasIvar;
  }
}

uint32_t LCIMGetHasOneof(LCIMMessage *self, int32_t idx) {
  NSCAssert(idx < 0, @"%@: invalid index (%d) for oneof.",
            [self class], idx);
  uint32_t result = self->messageStorage_->_has_storage_[-idx];
  return result;
}

void LCIMSetHasIvar(LCIMMessage *self, int32_t idx, uint32_t fieldNumber,
                   BOOL value) {
  if (idx < 0) {
    NSCAssert(fieldNumber != 0, @"Invalid field number.");
    uint32_t *has_storage = self->messageStorage_->_has_storage_;
    has_storage[-idx] = (value ? fieldNumber : 0);
  } else {
    NSCAssert(idx != GPBNoHasBit, @"Invalid has bit.");
    uint32_t *has_storage = self->messageStorage_->_has_storage_;
    uint32_t byte = idx / 32;
    uint32_t bitMask = (1 << (idx % 32));
    if (value) {
      has_storage[byte] |= bitMask;
    } else {
      has_storage[byte] &= ~bitMask;
    }
  }
}

void LCIMMaybeClearOneof(LCIMMessage *self, LCIMOneofDescriptor *oneof,
                        int32_t oneofHasIndex, uint32_t fieldNumberNotToClear) {
  uint32_t fieldNumberSet = LCIMGetHasOneof(self, oneofHasIndex);
  if ((fieldNumberSet == fieldNumberNotToClear) || (fieldNumberSet == 0)) {
    // Do nothing/nothing set in the oneof.
    return;
  }

  // Like LCIMClearMessageField(), free the memory if an objecttype is set,
  // pod types don't need to do anything.
  LCIMFieldDescriptor *fieldSet = [oneof fieldWithNumber:fieldNumberSet];
  NSCAssert(fieldSet,
            @"%@: oneof set to something (%u) not in the oneof?",
            [self class], fieldNumberSet);
  if (fieldSet && LCIMFieldStoresObject(fieldSet)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    id *typePtr = (id *)&storage[fieldSet->description_->offset];
    [*typePtr release];
    *typePtr = nil;
  }

  // Set to nothing stored in the oneof.
  // (field number doesn't matter since setting to nothing).
  LCIMSetHasIvar(self, oneofHasIndex, 1, NO);
}

#pragma mark - IVar accessors

//%PDDM-DEFINE IVAR_POD_ACCESSORS_DEFN(NAME, TYPE)
//%TYPE LCIMGetMessage##NAME##Field(LCIMMessage *self,
//% TYPE$S            NAME$S       LCIMFieldDescriptor *field) {
//%  if (LCIMGetHasIvarField(self, field)) {
//%    uint8_t *storage = (uint8_t *)self->messageStorage_;
//%    TYPE *typePtr = (TYPE *)&storage[field->description_->offset];
//%    return *typePtr;
//%  } else {
//%    return field.defaultValue.value##NAME;
//%  }
//%}
//%
//%// Only exists for public api, no core code should use this.
//%void LCIMSetMessage##NAME##Field(LCIMMessage *self,
//%                   NAME$S     LCIMFieldDescriptor *field,
//%                   NAME$S     TYPE value) {
//%  if (self == nil || field == nil) return;
//%  GPBFileSyntax syntax = [self descriptor].file.syntax;
//%  GPBSet##NAME##IvarWithFieldInternal(self, field, value, syntax);
//%}
//%
//%void GPBSet##NAME##IvarWithFieldInternal(LCIMMessage *self,
//%            NAME$S                     LCIMFieldDescriptor *field,
//%            NAME$S                     TYPE value,
//%            NAME$S                     GPBFileSyntax syntax) {
//%  LCIMOneofDescriptor *oneof = field->containingOneof_;
//%  if (oneof) {
//%    GPBMessageFieldDescription *fieldDesc = field->description_;
//%    LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
//%  }
//%  NSCAssert(self->messageStorage_ != NULL,
//%            @"%@: All messages should have storage (from init)",
//%            [self class]);
//%#if defined(__clang_analyzer__)
//%  if (self->messageStorage_ == NULL) return;
//%#endif
//%  uint8_t *storage = (uint8_t *)self->messageStorage_;
//%  TYPE *typePtr = (TYPE *)&storage[field->description_->offset];
//%  *typePtr = value;
//%  // proto2: any value counts as having been set; proto3, it
//%  // has to be a non zero value or be in a oneof.
//%  BOOL hasValue = ((syntax == GPBFileSyntaxProto2)
//%                   || (value != (TYPE)0)
//%                   || (field->containingOneof_ != NULL));
//%  LCIMSetHasIvarField(self, field, hasValue);
//%  LCIMBecomeVisibleToAutocreator(self);
//%}
//%
//%PDDM-DEFINE IVAR_ALIAS_DEFN_OBJECT(NAME, TYPE)
//%// Only exists for public api, no core code should use this.
//%TYPE *LCIMGetMessage##NAME##Field(LCIMMessage *self,
//% TYPE$S             NAME$S       LCIMFieldDescriptor *field) {
//%  return (TYPE *)LCIMGetObjectIvarWithField(self, field);
//%}
//%
//%// Only exists for public api, no core code should use this.
//%void LCIMSetMessage##NAME##Field(LCIMMessage *self,
//%                   NAME$S     LCIMFieldDescriptor *field,
//%                   NAME$S     TYPE *value) {
//%  GPBSetObjectIvarWithField(self, field, (id)value);
//%}
//%

// Object types are handled slightly differently, they need to be released
// and retained.

void LCIMSetAutocreatedRetainedObjectIvarWithField(
    LCIMMessage *self, LCIMFieldDescriptor *field,
    id __attribute__((ns_consumed)) value) {
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[field->description_->offset];
  NSCAssert(*typePtr == NULL, @"Can't set autocreated object more than once.");
  *typePtr = value;
}

void LCIMClearAutocreatedMessageIvarWithField(LCIMMessage *self,
                                             LCIMFieldDescriptor *field) {
  if (LCIMGetHasIvarField(self, field)) {
    return;
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[field->description_->offset];
  LCIMMessage *oldValue = *typePtr;
  *typePtr = NULL;
  LCIMClearMessageAutocreator(oldValue);
  [oldValue release];
}

// This exists only for briging some aliased types, nothing else should use it.
static void GPBSetObjectIvarWithField(LCIMMessage *self,
                                      LCIMFieldDescriptor *field, id value) {
  if (self == nil || field == nil) return;
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetRetainedObjectIvarWithFieldInternal(self, field, [value retain],
                                            syntax);
}

void LCIMSetObjectIvarWithFieldInternal(LCIMMessage *self,
                                       LCIMFieldDescriptor *field, id value,
                                       GPBFileSyntax syntax) {
  LCIMSetRetainedObjectIvarWithFieldInternal(self, field, [value retain],
                                            syntax);
}

void LCIMSetRetainedObjectIvarWithFieldInternal(LCIMMessage *self,
                                               LCIMFieldDescriptor *field,
                                               id value, GPBFileSyntax syntax) {
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  GPBDataType fieldType = LCIMGetFieldDataType(field);
  BOOL isMapOrArray = LCIMFieldIsMapOrArray(field);
  BOOL fieldIsMessage = LCIMDataTypeIsMessage(fieldType);
#ifdef DEBUG
  if (value == nil && !isMapOrArray && !fieldIsMessage &&
      field.hasDefaultValue) {
    // Setting a message to nil is an obvious way to "clear" the value
    // as there is no way to set a non-empty default value for messages.
    //
    // For Strings and Bytes that have default values set it is not clear what
    // should be done when their value is set to nil. Is the intention just to
    // clear the set value and reset to default, or is the intention to set the
    // value to the empty string/data? Arguments can be made for both cases.
    // 'nil' has been abused as a replacement for an empty string/data in ObjC.
    // We decided to be consistent with all "object" types and clear the has
    // field, and fall back on the default value. The warning below will only
    // appear in debug, but the could should be changed so the intention is
    // clear.
    NSString *hasSel = NSStringFromSelector(field->hasOrCountSel_);
    NSString *propName = field.name;
    NSString *className = self.descriptor.name;
    NSLog(@"warning: '%@.%@ = nil;' is not clearly defined for fields with "
          @"default values. Please use '%@.%@ = %@' if you want to set it to "
          @"empty, or call '%@.%@ = NO' to reset it to it's default value of "
          @"'%@'. Defaulting to resetting default value.",
          className, propName, className, propName,
          (fieldType == GPBDataTypeString) ? @"@\"\"" : @"LCIMEmptyNSData()",
          className, hasSel, field.defaultValue.valueString);
    // Note: valueString, depending on the type, it could easily be
    // valueData/valueMessage.
  }
#endif  // DEBUG
  if (!isMapOrArray) {
    // Non repeated/map can be in an oneof, clear any existing value from the
    // oneof.
    LCIMOneofDescriptor *oneof = field->containingOneof_;
    if (oneof) {
      GPBMessageFieldDescription *fieldDesc = field->description_;
      LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
    }
    // Clear "has" if they are being set to nil.
    BOOL setHasValue = (value != nil);
    // Under proto3, Bytes & String fields get cleared by resetting them to
    // their default (empty) values, so if they are set to something of length
    // zero, they are being cleared.
    if ((syntax == GPBFileSyntaxProto3) && !fieldIsMessage &&
        ([value length] == 0)) {
      // Except, if the field was in a oneof, then it still gets recorded as
      // having been set so the state of the oneof can be serialized back out.
      if (!oneof) {
        setHasValue = NO;
      }
      if (setHasValue) {
        NSCAssert(value != nil, @"Should never be setting has for nil");
      } else {
        // The value passed in was retained, it must be released since we
        // aren't saving anything in the field.
        [value release];
        value = nil;
      }
    }
    LCIMSetHasIvarField(self, field, setHasValue);
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[field->description_->offset];

  id oldValue = *typePtr;

  *typePtr = value;

  if (oldValue) {
    if (isMapOrArray) {
      if (field.fieldType == LCIMFieldTypeRepeated) {
        // If the old array was autocreated by us, then clear it.
        if (LCIMDataTypeIsObject(fieldType)) {
          LCIMAutocreatedArray *autoArray = oldValue;
          if (autoArray->_autocreator == self) {
            autoArray->_autocreator = nil;
          }
        } else {
          // Type doesn't matter, it is a GPB*Array.
          LCIMInt32Array *gpbArray = oldValue;
          if (gpbArray->_autocreator == self) {
            gpbArray->_autocreator = nil;
          }
        }
      } else { // LCIMFieldTypeMap
        // If the old map was autocreated by us, then clear it.
        if ((field.mapKeyDataType == GPBDataTypeString) &&
            LCIMDataTypeIsObject(fieldType)) {
          LCIMAutocreatedDictionary *autoDict = oldValue;
          if (autoDict->_autocreator == self) {
            autoDict->_autocreator = nil;
          }
        } else {
          // Type doesn't matter, it is a GPB*Dictionary.
          LCIMInt32Int32Dictionary *gpbDict = oldValue;
          if (gpbDict->_autocreator == self) {
            gpbDict->_autocreator = nil;
          }
        }
      }
    } else if (fieldIsMessage) {
      // If the old message value was autocreated by us, then clear it.
      LCIMMessage *oldMessageValue = oldValue;
      if (LCIMWasMessageAutocreatedBy(oldMessageValue, self)) {
        LCIMClearMessageAutocreator(oldMessageValue);
      }
    }
    [oldValue release];
  }

  LCIMBecomeVisibleToAutocreator(self);
}

id LCIMGetObjectIvarWithFieldNoAutocreate(LCIMMessage *self,
                                         LCIMFieldDescriptor *field) {
  if (self->messageStorage_ == nil) {
    return nil;
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[field->description_->offset];
  return *typePtr;
}

id LCIMGetObjectIvarWithField(LCIMMessage *self, LCIMFieldDescriptor *field) {
  NSCAssert(!LCIMFieldIsMapOrArray(field), @"Shouldn't get here");
  if (LCIMGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    id *typePtr = (id *)&storage[field->description_->offset];
    return *typePtr;
  }
  // Not set...

  // Non messages (string/data), get their default.
  if (!LCIMFieldDataTypeIsMessage(field)) {
    return field.defaultValue.valueMessage;
  }

  LCIMPrepareReadOnlySemaphore(self);
  dispatch_semaphore_wait(self->readOnlySemaphore_, DISPATCH_TIME_FOREVER);
  LCIMMessage *result = LCIMGetObjectIvarWithFieldNoAutocreate(self, field);
  if (!result) {
    // For non repeated messages, create the object, set it and return it.
    // This object will not initially be visible via LCIMGetHasIvar, so
    // we save its creator so it can become visible if it's mutated later.
    result = LCIMCreateMessageWithAutocreator(field.msgClass, self, field);
    LCIMSetAutocreatedRetainedObjectIvarWithField(self, field, result);
  }
  dispatch_semaphore_signal(self->readOnlySemaphore_);
  return result;
}

// Only exists for public api, no core code should use this.
int32_t LCIMGetMessageEnumField(LCIMMessage *self, LCIMFieldDescriptor *field) {
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  return LCIMGetEnumIvarWithFieldInternal(self, field, syntax);
}

int32_t LCIMGetEnumIvarWithFieldInternal(LCIMMessage *self,
                                        LCIMFieldDescriptor *field,
                                        GPBFileSyntax syntax) {
  int32_t result = LCIMGetMessageInt32Field(self, field);
  // If this is presevering unknown enums, make sure the value is valid before
  // returning it.
  if (LCIMHasPreservingUnknownEnumSemantics(syntax) &&
      ![field isValidEnumValue:result]) {
    result = kGPBUnrecognizedEnumeratorValue;
  }
  return result;
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageEnumField(LCIMMessage *self, LCIMFieldDescriptor *field,
                            int32_t value) {
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetInt32IvarWithFieldInternal(self, field, value, syntax);
}

void LCIMSetEnumIvarWithFieldInternal(LCIMMessage *self,
                                     LCIMFieldDescriptor *field, int32_t value,
                                     GPBFileSyntax syntax) {
  // Don't allow in unknown values.  Proto3 can use the Raw method.
  if (![field isValidEnumValue:value]) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@: Attempt to set an unknown enum value (%d)",
                       [self class], field.name, value];
  }
  LCIMSetInt32IvarWithFieldInternal(self, field, value, syntax);
}

// Only exists for public api, no core code should use this.
int32_t LCIMGetMessageRawEnumField(LCIMMessage *self,
                                  LCIMFieldDescriptor *field) {
  int32_t result = LCIMGetMessageInt32Field(self, field);
  return result;
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageRawEnumField(LCIMMessage *self, LCIMFieldDescriptor *field,
                               int32_t value) {
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetInt32IvarWithFieldInternal(self, field, value, syntax);
}

BOOL LCIMGetMessageBoolField(LCIMMessage *self,
                            LCIMFieldDescriptor *field) {
  if (LCIMGetHasIvarField(self, field)) {
    // Bools are stored in the has bits to avoid needing explicit space in the
    // storage structure.
    // (the field number passed to the HasIvar helper doesn't really matter
    // since the offset is never negative)
    GPBMessageFieldDescription *fieldDesc = field->description_;
    return LCIMGetHasIvar(self, (int32_t)(fieldDesc->offset), fieldDesc->number);
  } else {
    return field.defaultValue.valueBool;
  }
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageBoolField(LCIMMessage *self,
                            LCIMFieldDescriptor *field,
                            BOOL value) {
  if (self == nil || field == nil) return;
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetBoolIvarWithFieldInternal(self, field, value, syntax);
}

void LCIMSetBoolIvarWithFieldInternal(LCIMMessage *self,
                                     LCIMFieldDescriptor *field,
                                     BOOL value,
                                     GPBFileSyntax syntax) {
  GPBMessageFieldDescription *fieldDesc = field->description_;
  LCIMOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }

  // Bools are stored in the has bits to avoid needing explicit space in the
  // storage structure.
  // (the field number passed to the HasIvar helper doesn't really matter since
  // the offset is never negative)
  LCIMSetHasIvar(self, (int32_t)(fieldDesc->offset), fieldDesc->number, value);

  // proto2: any value counts as having been set; proto3, it
  // has to be a non zero value or be in a oneof.
  BOOL hasValue = ((syntax == GPBFileSyntaxProto2)
                   || (value != (BOOL)0)
                   || (field->containingOneof_ != NULL));
  LCIMSetHasIvarField(self, field, hasValue);
  LCIMBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Int32, int32_t)
// This block of code is generated, do not edit it directly.

int32_t LCIMGetMessageInt32Field(LCIMMessage *self,
                                LCIMFieldDescriptor *field) {
  if (LCIMGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    int32_t *typePtr = (int32_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueInt32;
  }
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageInt32Field(LCIMMessage *self,
                             LCIMFieldDescriptor *field,
                             int32_t value) {
  if (self == nil || field == nil) return;
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetInt32IvarWithFieldInternal(self, field, value, syntax);
}

void LCIMSetInt32IvarWithFieldInternal(LCIMMessage *self,
                                      LCIMFieldDescriptor *field,
                                      int32_t value,
                                      GPBFileSyntax syntax) {
  LCIMOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    GPBMessageFieldDescription *fieldDesc = field->description_;
    LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  int32_t *typePtr = (int32_t *)&storage[field->description_->offset];
  *typePtr = value;
  // proto2: any value counts as having been set; proto3, it
  // has to be a non zero value or be in a oneof.
  BOOL hasValue = ((syntax == GPBFileSyntaxProto2)
                   || (value != (int32_t)0)
                   || (field->containingOneof_ != NULL));
  LCIMSetHasIvarField(self, field, hasValue);
  LCIMBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.

uint32_t LCIMGetMessageUInt32Field(LCIMMessage *self,
                                  LCIMFieldDescriptor *field) {
  if (LCIMGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    uint32_t *typePtr = (uint32_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueUInt32;
  }
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageUInt32Field(LCIMMessage *self,
                              LCIMFieldDescriptor *field,
                              uint32_t value) {
  if (self == nil || field == nil) return;
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetUInt32IvarWithFieldInternal(self, field, value, syntax);
}

void LCIMSetUInt32IvarWithFieldInternal(LCIMMessage *self,
                                       LCIMFieldDescriptor *field,
                                       uint32_t value,
                                       GPBFileSyntax syntax) {
  LCIMOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    GPBMessageFieldDescription *fieldDesc = field->description_;
    LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  uint32_t *typePtr = (uint32_t *)&storage[field->description_->offset];
  *typePtr = value;
  // proto2: any value counts as having been set; proto3, it
  // has to be a non zero value or be in a oneof.
  BOOL hasValue = ((syntax == GPBFileSyntaxProto2)
                   || (value != (uint32_t)0)
                   || (field->containingOneof_ != NULL));
  LCIMSetHasIvarField(self, field, hasValue);
  LCIMBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Int64, int64_t)
// This block of code is generated, do not edit it directly.

int64_t LCIMGetMessageInt64Field(LCIMMessage *self,
                                LCIMFieldDescriptor *field) {
  if (LCIMGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    int64_t *typePtr = (int64_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueInt64;
  }
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageInt64Field(LCIMMessage *self,
                             LCIMFieldDescriptor *field,
                             int64_t value) {
  if (self == nil || field == nil) return;
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetInt64IvarWithFieldInternal(self, field, value, syntax);
}

void LCIMSetInt64IvarWithFieldInternal(LCIMMessage *self,
                                      LCIMFieldDescriptor *field,
                                      int64_t value,
                                      GPBFileSyntax syntax) {
  LCIMOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    GPBMessageFieldDescription *fieldDesc = field->description_;
    LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  int64_t *typePtr = (int64_t *)&storage[field->description_->offset];
  *typePtr = value;
  // proto2: any value counts as having been set; proto3, it
  // has to be a non zero value or be in a oneof.
  BOOL hasValue = ((syntax == GPBFileSyntaxProto2)
                   || (value != (int64_t)0)
                   || (field->containingOneof_ != NULL));
  LCIMSetHasIvarField(self, field, hasValue);
  LCIMBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.

uint64_t LCIMGetMessageUInt64Field(LCIMMessage *self,
                                  LCIMFieldDescriptor *field) {
  if (LCIMGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    uint64_t *typePtr = (uint64_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueUInt64;
  }
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageUInt64Field(LCIMMessage *self,
                              LCIMFieldDescriptor *field,
                              uint64_t value) {
  if (self == nil || field == nil) return;
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetUInt64IvarWithFieldInternal(self, field, value, syntax);
}

void LCIMSetUInt64IvarWithFieldInternal(LCIMMessage *self,
                                       LCIMFieldDescriptor *field,
                                       uint64_t value,
                                       GPBFileSyntax syntax) {
  LCIMOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    GPBMessageFieldDescription *fieldDesc = field->description_;
    LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  uint64_t *typePtr = (uint64_t *)&storage[field->description_->offset];
  *typePtr = value;
  // proto2: any value counts as having been set; proto3, it
  // has to be a non zero value or be in a oneof.
  BOOL hasValue = ((syntax == GPBFileSyntaxProto2)
                   || (value != (uint64_t)0)
                   || (field->containingOneof_ != NULL));
  LCIMSetHasIvarField(self, field, hasValue);
  LCIMBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Float, float)
// This block of code is generated, do not edit it directly.

float LCIMGetMessageFloatField(LCIMMessage *self,
                              LCIMFieldDescriptor *field) {
  if (LCIMGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    float *typePtr = (float *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueFloat;
  }
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageFloatField(LCIMMessage *self,
                             LCIMFieldDescriptor *field,
                             float value) {
  if (self == nil || field == nil) return;
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetFloatIvarWithFieldInternal(self, field, value, syntax);
}

void LCIMSetFloatIvarWithFieldInternal(LCIMMessage *self,
                                      LCIMFieldDescriptor *field,
                                      float value,
                                      GPBFileSyntax syntax) {
  LCIMOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    GPBMessageFieldDescription *fieldDesc = field->description_;
    LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  float *typePtr = (float *)&storage[field->description_->offset];
  *typePtr = value;
  // proto2: any value counts as having been set; proto3, it
  // has to be a non zero value or be in a oneof.
  BOOL hasValue = ((syntax == GPBFileSyntaxProto2)
                   || (value != (float)0)
                   || (field->containingOneof_ != NULL));
  LCIMSetHasIvarField(self, field, hasValue);
  LCIMBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Double, double)
// This block of code is generated, do not edit it directly.

double LCIMGetMessageDoubleField(LCIMMessage *self,
                                LCIMFieldDescriptor *field) {
  if (LCIMGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    double *typePtr = (double *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueDouble;
  }
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageDoubleField(LCIMMessage *self,
                              LCIMFieldDescriptor *field,
                              double value) {
  if (self == nil || field == nil) return;
  GPBFileSyntax syntax = [self descriptor].file.syntax;
  LCIMSetDoubleIvarWithFieldInternal(self, field, value, syntax);
}

void LCIMSetDoubleIvarWithFieldInternal(LCIMMessage *self,
                                       LCIMFieldDescriptor *field,
                                       double value,
                                       GPBFileSyntax syntax) {
  LCIMOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    GPBMessageFieldDescription *fieldDesc = field->description_;
    LCIMMaybeClearOneof(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  double *typePtr = (double *)&storage[field->description_->offset];
  *typePtr = value;
  // proto2: any value counts as having been set; proto3, it
  // has to be a non zero value or be in a oneof.
  BOOL hasValue = ((syntax == GPBFileSyntaxProto2)
                   || (value != (double)0)
                   || (field->containingOneof_ != NULL));
  LCIMSetHasIvarField(self, field, hasValue);
  LCIMBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND-END (6 expansions)

// Aliases are function calls that are virtually the same.

//%PDDM-EXPAND IVAR_ALIAS_DEFN_OBJECT(String, NSString)
// This block of code is generated, do not edit it directly.

// Only exists for public api, no core code should use this.
NSString *LCIMGetMessageStringField(LCIMMessage *self,
                                   LCIMFieldDescriptor *field) {
  return (NSString *)LCIMGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageStringField(LCIMMessage *self,
                              LCIMFieldDescriptor *field,
                              NSString *value) {
  GPBSetObjectIvarWithField(self, field, (id)value);
}

//%PDDM-EXPAND IVAR_ALIAS_DEFN_OBJECT(Bytes, NSData)
// This block of code is generated, do not edit it directly.

// Only exists for public api, no core code should use this.
NSData *LCIMGetMessageBytesField(LCIMMessage *self,
                                LCIMFieldDescriptor *field) {
  return (NSData *)LCIMGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageBytesField(LCIMMessage *self,
                             LCIMFieldDescriptor *field,
                             NSData *value) {
  GPBSetObjectIvarWithField(self, field, (id)value);
}

//%PDDM-EXPAND IVAR_ALIAS_DEFN_OBJECT(Message, LCIMMessage)
// This block of code is generated, do not edit it directly.

// Only exists for public api, no core code should use this.
LCIMMessage *LCIMGetMessageMessageField(LCIMMessage *self,
                                      LCIMFieldDescriptor *field) {
  return (LCIMMessage *)LCIMGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageMessageField(LCIMMessage *self,
                               LCIMFieldDescriptor *field,
                               LCIMMessage *value) {
  GPBSetObjectIvarWithField(self, field, (id)value);
}

//%PDDM-EXPAND IVAR_ALIAS_DEFN_OBJECT(Group, LCIMMessage)
// This block of code is generated, do not edit it directly.

// Only exists for public api, no core code should use this.
LCIMMessage *LCIMGetMessageGroupField(LCIMMessage *self,
                                    LCIMFieldDescriptor *field) {
  return (LCIMMessage *)LCIMGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void LCIMSetMessageGroupField(LCIMMessage *self,
                             LCIMFieldDescriptor *field,
                             LCIMMessage *value) {
  GPBSetObjectIvarWithField(self, field, (id)value);
}

//%PDDM-EXPAND-END (4 expansions)

// LCIMGetMessageRepeatedField is defined in LCIMMessage.m

// Only exists for public api, no core code should use this.
void LCIMSetMessageRepeatedField(LCIMMessage *self, LCIMFieldDescriptor *field, id array) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != LCIMFieldTypeRepeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a repeated field.",
                       [self class], field.name];
  }
  Class expectedClass = Nil;
  switch (LCIMGetFieldDataType(field)) {
    case GPBDataTypeBool:
      expectedClass = [LCIMBoolArray class];
      break;
    case GPBDataTypeSFixed32:
    case GPBDataTypeInt32:
    case GPBDataTypeSInt32:
      expectedClass = [LCIMInt32Array class];
      break;
    case GPBDataTypeFixed32:
    case GPBDataTypeUInt32:
      expectedClass = [LCIMUInt32Array class];
      break;
    case GPBDataTypeSFixed64:
    case GPBDataTypeInt64:
    case GPBDataTypeSInt64:
      expectedClass = [LCIMInt64Array class];
      break;
    case GPBDataTypeFixed64:
    case GPBDataTypeUInt64:
      expectedClass = [LCIMUInt64Array class];
      break;
    case GPBDataTypeFloat:
      expectedClass = [LCIMFloatArray class];
      break;
    case GPBDataTypeDouble:
      expectedClass = [LCIMDoubleArray class];
      break;
    case GPBDataTypeBytes:
    case GPBDataTypeString:
    case GPBDataTypeMessage:
    case GPBDataTypeGroup:
      expectedClass = [NSMutableArray class];
      break;
    case GPBDataTypeEnum:
      expectedClass = [LCIMEnumArray class];
      break;
  }
  if (array && ![array isKindOfClass:expectedClass]) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@: Expected %@ object, got %@.",
                       [self class], field.name, expectedClass, [array class]];
  }
#endif
  GPBSetObjectIvarWithField(self, field, array);
}

#if defined(DEBUG) && DEBUG
static NSString *TypeToStr(GPBDataType dataType) {
  switch (dataType) {
    case GPBDataTypeBool:
      return @"Bool";
    case GPBDataTypeSFixed32:
    case GPBDataTypeInt32:
    case GPBDataTypeSInt32:
      return @"Int32";
    case GPBDataTypeFixed32:
    case GPBDataTypeUInt32:
      return @"UInt32";
    case GPBDataTypeSFixed64:
    case GPBDataTypeInt64:
    case GPBDataTypeSInt64:
      return @"Int64";
    case GPBDataTypeFixed64:
    case GPBDataTypeUInt64:
      return @"UInt64";
    case GPBDataTypeFloat:
      return @"Float";
    case GPBDataTypeDouble:
      return @"Double";
    case GPBDataTypeBytes:
    case GPBDataTypeString:
    case GPBDataTypeMessage:
    case GPBDataTypeGroup:
      return @"Object";
    case GPBDataTypeEnum:
      return @"Bool";
  }
}
#endif

// LCIMGetMessageMapField is defined in LCIMMessage.m

// Only exists for public api, no core code should use this.
void LCIMSetMessageMapField(LCIMMessage *self, LCIMFieldDescriptor *field,
                           id dictionary) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != LCIMFieldTypeMap) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a map<> field.",
                       [self class], field.name];
  }
  if (dictionary) {
    GPBDataType keyDataType = field.mapKeyDataType;
    GPBDataType valueDataType = LCIMGetFieldDataType(field);
    NSString *keyStr = TypeToStr(keyDataType);
    NSString *valueStr = TypeToStr(valueDataType);
    if (keyDataType == GPBDataTypeString) {
      keyStr = @"String";
    }
    Class expectedClass = Nil;
    if ((keyDataType == GPBDataTypeString) &&
        LCIMDataTypeIsObject(valueDataType)) {
      expectedClass = [NSMutableDictionary class];
    } else {
      NSString *className =
          [NSString stringWithFormat:@"GPB%@%@Dictionary", keyStr, valueStr];
      expectedClass = NSClassFromString(className);
      NSCAssert(expectedClass, @"Missing a class (%@)?", expectedClass);
    }
    if (![dictionary isKindOfClass:expectedClass]) {
      [NSException raise:NSInvalidArgumentException
                  format:@"%@.%@: Expected %@ object, got %@.",
                         [self class], field.name, expectedClass,
                         [dictionary class]];
    }
  }
#endif
  GPBSetObjectIvarWithField(self, field, dictionary);
}

#pragma mark - Misc Dynamic Runtime Utils

const char *LCIMMessageEncodingForSelector(SEL selector, BOOL instanceSel) {
  Protocol *protocol =
      objc_getProtocol(GPBStringifySymbol(LCIMMessageSignatureProtocol));
  struct objc_method_description description =
      protocol_getMethodDescription(protocol, selector, NO, instanceSel);
  return description.types;
}

#pragma mark - Text Format Support

static void AppendStringEscaped(NSString *toPrint, NSMutableString *destStr) {
  [destStr appendString:@"\""];
  NSUInteger len = [toPrint length];
  for (NSUInteger i = 0; i < len; ++i) {
    unichar aChar = [toPrint characterAtIndex:i];
    switch (aChar) {
      case '\n': [destStr appendString:@"\\n"];  break;
      case '\r': [destStr appendString:@"\\r"];  break;
      case '\t': [destStr appendString:@"\\t"];  break;
      case '\"': [destStr appendString:@"\\\""]; break;
      case '\'': [destStr appendString:@"\\\'"]; break;
      case '\\': [destStr appendString:@"\\\\"]; break;
      default:
        // This differs slightly from the C++ code in that the C++ doesn't
        // generate UTF8; it looks at the string in UTF8, but escapes every
        // byte > 0x7E.
        if (aChar < 0x20) {
          [destStr appendFormat:@"\\%d%d%d",
                                (aChar / 64), ((aChar % 64) / 8), (aChar % 8)];
        } else {
          [destStr appendFormat:@"%C", aChar];
        }
        break;
    }
  }
  [destStr appendString:@"\""];
}

static void AppendBufferAsString(NSData *buffer, NSMutableString *destStr) {
  const char *src = (const char *)[buffer bytes];
  size_t srcLen = [buffer length];
  [destStr appendString:@"\""];
  for (const char *srcEnd = src + srcLen; src < srcEnd; src++) {
    switch (*src) {
      case '\n': [destStr appendString:@"\\n"];  break;
      case '\r': [destStr appendString:@"\\r"];  break;
      case '\t': [destStr appendString:@"\\t"];  break;
      case '\"': [destStr appendString:@"\\\""]; break;
      case '\'': [destStr appendString:@"\\\'"]; break;
      case '\\': [destStr appendString:@"\\\\"]; break;
      default:
        if (isprint(*src)) {
          [destStr appendFormat:@"%c", *src];
        } else {
          // NOTE: doing hex means you have to worry about the letter after
          // the hex being another hex char and forcing that to be escaped, so
          // use octal to keep it simple.
          [destStr appendFormat:@"\\%03o", (uint8_t)(*src)];
        }
        break;
    }
  }
  [destStr appendString:@"\""];
}

static void AppendTextFormatForMapMessageField(
    id map, LCIMFieldDescriptor *field, NSMutableString *toStr,
    NSString *lineIndent, NSString *fieldName, NSString *lineEnding) {
  GPBDataType keyDataType = field.mapKeyDataType;
  GPBDataType valueDataType = LCIMGetFieldDataType(field);
  BOOL isMessageValue = LCIMDataTypeIsMessage(valueDataType);

  NSString *msgStartFirst =
      [NSString stringWithFormat:@"%@%@ {%@\n", lineIndent, fieldName, lineEnding];
  NSString *msgStart =
      [NSString stringWithFormat:@"%@%@ {\n", lineIndent, fieldName];
  NSString *msgEnd = [NSString stringWithFormat:@"%@}\n", lineIndent];

  NSString *keyLine = [NSString stringWithFormat:@"%@  key: ", lineIndent];
  NSString *valueLine = [NSString stringWithFormat:@"%@  value%s ", lineIndent,
                                                   (isMessageValue ? "" : ":")];

  __block BOOL isFirst = YES;

  if ((keyDataType == GPBDataTypeString) &&
      LCIMDataTypeIsObject(valueDataType)) {
    // map is an NSDictionary.
    NSDictionary *dict = map;
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
      #pragma unused(stop)
      [toStr appendString:(isFirst ? msgStartFirst : msgStart)];
      isFirst = NO;

      [toStr appendString:keyLine];
      AppendStringEscaped(key, toStr);
      [toStr appendString:@"\n"];

      [toStr appendString:valueLine];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
      switch (valueDataType) {
        case GPBDataTypeString:
          AppendStringEscaped(value, toStr);
          break;

        case GPBDataTypeBytes:
          AppendBufferAsString(value, toStr);
          break;

        case GPBDataTypeMessage:
          [toStr appendString:@"{\n"];
          NSString *subIndent = [lineIndent stringByAppendingString:@"    "];
          AppendTextFormatForMessage(value, toStr, subIndent);
          [toStr appendFormat:@"%@  }", lineIndent];
          break;

        default:
          NSCAssert(NO, @"Can't happen");
          break;
      }
#pragma clang diagnostic pop
      [toStr appendString:@"\n"];

      [toStr appendString:msgEnd];
    }];
  } else {
    // map is one of the GPB*Dictionary classes, type doesn't matter.
    LCIMInt32Int32Dictionary *dict = map;
    [dict enumerateForTextFormat:^(id keyObj, id valueObj) {
      [toStr appendString:(isFirst ? msgStartFirst : msgStart)];
      isFirst = NO;

      // Key always is a NSString.
      if (keyDataType == GPBDataTypeString) {
        [toStr appendString:keyLine];
        AppendStringEscaped(keyObj, toStr);
        [toStr appendString:@"\n"];
      } else {
        [toStr appendFormat:@"%@%@\n", keyLine, keyObj];
      }

      [toStr appendString:valueLine];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
      switch (valueDataType) {
        case GPBDataTypeString:
          AppendStringEscaped(valueObj, toStr);
          break;

        case GPBDataTypeBytes:
          AppendBufferAsString(valueObj, toStr);
          break;

        case GPBDataTypeMessage:
          [toStr appendString:@"{\n"];
          NSString *subIndent = [lineIndent stringByAppendingString:@"    "];
          AppendTextFormatForMessage(valueObj, toStr, subIndent);
          [toStr appendFormat:@"%@  }", lineIndent];
          break;

        case GPBDataTypeEnum: {
          int32_t enumValue = [valueObj intValue];
          NSString *valueStr = nil;
          LCIMEnumDescriptor *descriptor = field.enumDescriptor;
          if (descriptor) {
            valueStr = [descriptor textFormatNameForValue:enumValue];
          }
          if (valueStr) {
            [toStr appendString:valueStr];
          } else {
            [toStr appendFormat:@"%d", enumValue];
          }
          break;
        }

        default:
          NSCAssert(valueDataType != GPBDataTypeGroup, @"Can't happen");
          // Everything else is a NSString.
          [toStr appendString:valueObj];
          break;
      }
#pragma clang diagnostic pop
      [toStr appendString:@"\n"];

      [toStr appendString:msgEnd];
    }];
  }
}

static void AppendTextFormatForMessageField(LCIMMessage *message,
                                            LCIMFieldDescriptor *field,
                                            NSMutableString *toStr,
                                            NSString *lineIndent) {
  id arrayOrMap;
  NSUInteger count;
  LCIMFieldType fieldType = field.fieldType;
  switch (fieldType) {
    case LCIMFieldTypeSingle:
      arrayOrMap = nil;
      count = (LCIMGetHasIvarField(message, field) ? 1 : 0);
      break;

    case LCIMFieldTypeRepeated:
      // Will be NSArray or GPB*Array, type doesn't matter, they both
      // implement count.
      arrayOrMap = LCIMGetObjectIvarWithFieldNoAutocreate(message, field);
      count = [(NSArray *)arrayOrMap count];
      break;

    case LCIMFieldTypeMap: {
      // Will be GPB*Dictionary or NSMutableDictionary, type doesn't matter,
      // they both implement count.
      arrayOrMap = LCIMGetObjectIvarWithFieldNoAutocreate(message, field);
      count = [(NSDictionary *)arrayOrMap count];
      break;
    }
  }

  if (count == 0) {
    // Nothing to print, out of here.
    return;
  }

  NSString *lineEnding = @"";

  // If the name can't be reversed or support for extra info was turned off,
  // this can return nil.
  NSString *fieldName = [field textFormatName];
  if ([fieldName length] == 0) {
    fieldName = [NSString stringWithFormat:@"%u", LCIMFieldNumber(field)];
    // If there is only one entry, put the objc name as a comment, other wise
    // add it before the repeated values.
    if (count > 1) {
      [toStr appendFormat:@"%@# %@\n", lineIndent, field.name];
    } else {
      lineEnding = [NSString stringWithFormat:@"  # %@", field.name];
    }
  }

  if (fieldType == LCIMFieldTypeMap) {
    AppendTextFormatForMapMessageField(arrayOrMap, field, toStr, lineIndent,
                                       fieldName, lineEnding);
    return;
  }

  id array = arrayOrMap;
  const BOOL isRepeated = (array != nil);

  GPBDataType fieldDataType = LCIMGetFieldDataType(field);
  BOOL isMessageField = LCIMDataTypeIsMessage(fieldDataType);
  for (NSUInteger j = 0; j < count; ++j) {
    // Start the line.
    [toStr appendFormat:@"%@%@%s ", lineIndent, fieldName,
                        (isMessageField ? "" : ":")];

    // The value.
    switch (fieldDataType) {
#define FIELD_CASE(GPBDATATYPE, CTYPE, REAL_TYPE, ...)                        \
  case GPBDataType##GPBDATATYPE: {                                            \
    CTYPE v = (isRepeated ? [(LCIM##REAL_TYPE##Array *)array valueAtIndex:j]   \
                          : LCIMGetMessage##REAL_TYPE##Field(message, field)); \
    [toStr appendFormat:__VA_ARGS__, v];                                      \
    break;                                                                    \
  }

      FIELD_CASE(Int32, int32_t, Int32, @"%d")
      FIELD_CASE(SInt32, int32_t, Int32, @"%d")
      FIELD_CASE(SFixed32, int32_t, Int32, @"%d")
      FIELD_CASE(UInt32, uint32_t, UInt32, @"%u")
      FIELD_CASE(Fixed32, uint32_t, UInt32, @"%u")
      FIELD_CASE(Int64, int64_t, Int64, @"%lld")
      FIELD_CASE(SInt64, int64_t, Int64, @"%lld")
      FIELD_CASE(SFixed64, int64_t, Int64, @"%lld")
      FIELD_CASE(UInt64, uint64_t, UInt64, @"%llu")
      FIELD_CASE(Fixed64, uint64_t, UInt64, @"%llu")
      FIELD_CASE(Float, float, Float, @"%.*g", FLT_DIG)
      FIELD_CASE(Double, double, Double, @"%.*lg", DBL_DIG)

#undef FIELD_CASE

      case GPBDataTypeEnum: {
        int32_t v = (isRepeated ? [(LCIMEnumArray *)array rawValueAtIndex:j]
                                : LCIMGetMessageInt32Field(message, field));
        NSString *valueStr = nil;
        LCIMEnumDescriptor *descriptor = field.enumDescriptor;
        if (descriptor) {
          valueStr = [descriptor textFormatNameForValue:v];
        }
        if (valueStr) {
          [toStr appendString:valueStr];
        } else {
          [toStr appendFormat:@"%d", v];
        }
        break;
      }

      case GPBDataTypeBool: {
        BOOL v = (isRepeated ? [(LCIMBoolArray *)array valueAtIndex:j]
                             : LCIMGetMessageBoolField(message, field));
        [toStr appendString:(v ? @"true" : @"false")];
        break;
      }

      case GPBDataTypeString: {
        NSString *v = (isRepeated ? [(NSArray *)array objectAtIndex:j]
                                  : LCIMGetMessageStringField(message, field));
        AppendStringEscaped(v, toStr);
        break;
      }

      case GPBDataTypeBytes: {
        NSData *v = (isRepeated ? [(NSArray *)array objectAtIndex:j]
                                : LCIMGetMessageBytesField(message, field));
        AppendBufferAsString(v, toStr);
        break;
      }

      case GPBDataTypeGroup:
      case GPBDataTypeMessage: {
        LCIMMessage *v =
            (isRepeated ? [(NSArray *)array objectAtIndex:j]
                        : LCIMGetObjectIvarWithField(message, field));
        [toStr appendFormat:@"{%@\n", lineEnding];
        NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
        AppendTextFormatForMessage(v, toStr, subIndent);
        [toStr appendFormat:@"%@}", lineIndent];
        lineEnding = @"";
        break;
      }

    }  // switch(fieldDataType)

    // End the line.
    [toStr appendFormat:@"%@\n", lineEnding];

  }  // for(count)
}

static void AppendTextFormatForMessageExtensionRange(LCIMMessage *message,
                                                     NSArray *activeExtensions,
                                                     GPBExtensionRange range,
                                                     NSMutableString *toStr,
                                                     NSString *lineIndent) {
  uint32_t start = range.start;
  uint32_t end = range.end;
  for (LCIMExtensionDescriptor *extension in activeExtensions) {
    uint32_t fieldNumber = extension.fieldNumber;
    if (fieldNumber < start) {
      // Not there yet.
      continue;
    }
    if (fieldNumber > end) {
      // Done.
      break;
    }

    id rawExtValue = [message getExtension:extension];
    BOOL isRepeated = extension.isRepeated;

    NSUInteger numValues = 1;
    NSString *lineEnding = @"";
    if (isRepeated) {
      numValues = [(NSArray *)rawExtValue count];
    }

    NSString *singletonName = extension.singletonName;
    if (numValues == 1) {
      lineEnding = [NSString stringWithFormat:@"  # [%@]", singletonName];
    } else {
      [toStr appendFormat:@"%@# [%@]\n", lineIndent, singletonName];
    }

    GPBDataType extDataType = extension.dataType;
    for (NSUInteger j = 0; j < numValues; ++j) {
      id curValue = (isRepeated ? [rawExtValue objectAtIndex:j] : rawExtValue);

      // Start the line.
      [toStr appendFormat:@"%@%u%s ", lineIndent, fieldNumber,
                          (LCIMDataTypeIsMessage(extDataType) ? "" : ":")];

      // The value.
      switch (extDataType) {
#define FIELD_CASE(GPBDATATYPE, CTYPE, NUMSELECTOR, ...) \
  case GPBDataType##GPBDATATYPE: {                       \
    CTYPE v = [(NSNumber *)curValue NUMSELECTOR];        \
    [toStr appendFormat:__VA_ARGS__, v];                 \
    break;                                               \
  }

        FIELD_CASE(Int32, int32_t, intValue, @"%d")
        FIELD_CASE(SInt32, int32_t, intValue, @"%d")
        FIELD_CASE(SFixed32, int32_t, unsignedIntValue, @"%d")
        FIELD_CASE(UInt32, uint32_t, unsignedIntValue, @"%u")
        FIELD_CASE(Fixed32, uint32_t, unsignedIntValue, @"%u")
        FIELD_CASE(Int64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(SInt64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(SFixed64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(UInt64, uint64_t, unsignedLongLongValue, @"%llu")
        FIELD_CASE(Fixed64, uint64_t, unsignedLongLongValue, @"%llu")
        FIELD_CASE(Float, float, floatValue, @"%.*g", FLT_DIG)
        FIELD_CASE(Double, double, doubleValue, @"%.*lg", DBL_DIG)
        // TODO: Add a comment with the enum name from enum descriptors
        // (might not be real value, so leave it as a comment, ObjC compiler
        // name mangles differently).  Doesn't look like we actually generate
        // an enum descriptor reference like we do for normal fields, so this
        // will take a compiler change.
        FIELD_CASE(Enum, int32_t, intValue, @"%d")

#undef FIELD_CASE

        case GPBDataTypeBool:
          [toStr appendString:([(NSNumber *)curValue boolValue] ? @"true"
                                                                : @"false")];
          break;

        case GPBDataTypeString:
          AppendStringEscaped(curValue, toStr);
          break;

        case GPBDataTypeBytes:
          AppendBufferAsString((NSData *)curValue, toStr);
          break;

        case GPBDataTypeGroup:
        case GPBDataTypeMessage: {
          [toStr appendFormat:@"{%@\n", lineEnding];
          NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
          AppendTextFormatForMessage(curValue, toStr, subIndent);
          [toStr appendFormat:@"%@}", lineIndent];
          lineEnding = @"";
          break;
        }

      }  // switch(extDataType)

    }  //  for(numValues)

    // End the line.
    [toStr appendFormat:@"%@\n", lineEnding];

  }  // for..in(activeExtensions)
}

static void AppendTextFormatForMessage(LCIMMessage *message,
                                       NSMutableString *toStr,
                                       NSString *lineIndent) {
  LCIMDescriptor *descriptor = [message descriptor];
  NSArray *fieldsArray = descriptor->fields_;
  NSUInteger fieldCount = fieldsArray.count;
  const GPBExtensionRange *extensionRanges = descriptor.extensionRanges;
  NSUInteger extensionRangesCount = descriptor.extensionRangesCount;
  NSArray *activeExtensions = [[message extensionsCurrentlySet]
      sortedArrayUsingSelector:@selector(compareByFieldNumber:)];
  for (NSUInteger i = 0, j = 0; i < fieldCount || j < extensionRangesCount;) {
    if (i == fieldCount) {
      AppendTextFormatForMessageExtensionRange(
          message, activeExtensions, extensionRanges[j++], toStr, lineIndent);
    } else if (j == extensionRangesCount ||
               LCIMFieldNumber(fieldsArray[i]) < extensionRanges[j].start) {
      AppendTextFormatForMessageField(message, fieldsArray[i++], toStr,
                                      lineIndent);
    } else {
      AppendTextFormatForMessageExtensionRange(
          message, activeExtensions, extensionRanges[j++], toStr, lineIndent);
    }
  }

  NSString *unknownFieldsStr =
      LCIMTextFormatForUnknownFieldSet(message.unknownFields, lineIndent);
  if ([unknownFieldsStr length] > 0) {
    [toStr appendFormat:@"%@# --- Unknown fields ---\n", lineIndent];
    [toStr appendString:unknownFieldsStr];
  }
}

NSString *LCIMTextFormatForMessage(LCIMMessage *message, NSString *lineIndent) {
  if (message == nil) return @"";
  if (lineIndent == nil) lineIndent = @"";

  NSMutableString *buildString = [NSMutableString string];
  AppendTextFormatForMessage(message, buildString, lineIndent);
  return buildString;
}

NSString *LCIMTextFormatForUnknownFieldSet(LCIMUnknownFieldSet *unknownSet,
                                          NSString *lineIndent) {
  if (unknownSet == nil) return @"";
  if (lineIndent == nil) lineIndent = @"";

  NSMutableString *result = [NSMutableString string];
  for (LCIMUnknownField *field in [unknownSet sortedFields]) {
    int32_t fieldNumber = [field number];

#define PRINT_LOOP(PROPNAME, CTYPE, FORMAT)                                   \
  [field.PROPNAME                                                             \
      enumerateValuesWithBlock:^(CTYPE value, NSUInteger idx, BOOL * stop) {  \
    _Pragma("unused(idx, stop)");                                             \
    [result                                                                   \
        appendFormat:@"%@%d: " #FORMAT "\n", lineIndent, fieldNumber, value]; \
      }];

    PRINT_LOOP(varintList, uint64_t, %llu);
    PRINT_LOOP(fixed32List, uint32_t, 0x%X);
    PRINT_LOOP(fixed64List, uint64_t, 0x%llX);

#undef PRINT_LOOP

    // NOTE: C++ version of TextFormat tries to parse this as a message
    // and print that if it succeeds.
    for (NSData *data in field.lengthDelimitedList) {
      [result appendFormat:@"%@%d: ", lineIndent, fieldNumber];
      AppendBufferAsString(data, result);
      [result appendString:@"\n"];
    }

    for (LCIMUnknownFieldSet *subUnknownSet in field.groupList) {
      [result appendFormat:@"%@%d: {\n", lineIndent, fieldNumber];
      NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
      NSString *subUnknwonSetStr =
          LCIMTextFormatForUnknownFieldSet(subUnknownSet, subIndent);
      [result appendString:subUnknwonSetStr];
      [result appendFormat:@"%@}\n", lineIndent];
    }
  }
  return result;
}

// Helpers to decode a varint. Not using LCIMCodedInputStream version because
// that needs a state object, and we don't want to create an input stream out
// of the data.
GPB_INLINE int8_t ReadRawByteFromData(const uint8_t **data) {
  int8_t result = *((int8_t *)(*data));
  ++(*data);
  return result;
}

static int32_t ReadRawVarint32FromData(const uint8_t **data) {
  int8_t tmp = ReadRawByteFromData(data);
  if (tmp >= 0) {
    return tmp;
  }
  int32_t result = tmp & 0x7f;
  if ((tmp = ReadRawByteFromData(data)) >= 0) {
    result |= tmp << 7;
  } else {
    result |= (tmp & 0x7f) << 7;
    if ((tmp = ReadRawByteFromData(data)) >= 0) {
      result |= tmp << 14;
    } else {
      result |= (tmp & 0x7f) << 14;
      if ((tmp = ReadRawByteFromData(data)) >= 0) {
        result |= tmp << 21;
      } else {
        result |= (tmp & 0x7f) << 21;
        result |= (tmp = ReadRawByteFromData(data)) << 28;
        if (tmp < 0) {
          // Discard upper 32 bits.
          for (int i = 0; i < 5; i++) {
            if (ReadRawByteFromData(data) >= 0) {
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

NSString *LCIMDecodeTextFormatName(const uint8_t *decodeData, int32_t key,
                                  NSString *inputStr) {
  // decodData form:
  //  varint32: num entries
  //  for each entry:
  //    varint32: key
  //    bytes*: decode data
  //
  // decode data one of two forms:
  //  1: a \0 followed by the string followed by an \0
  //  2: bytecodes to transform an input into the right thing, ending with \0
  //
  // the bytes codes are of the form:
  //  0xabbccccc
  //  0x0 (all zeros), end.
  //  a - if set, add an underscore
  //  bb - 00 ccccc bytes as is
  //  bb - 10 ccccc upper first, as is on rest, ccccc byte total
  //  bb - 01 ccccc lower first, as is on rest, ccccc byte total
  //  bb - 11 ccccc all upper, ccccc byte total

  if (!decodeData || !inputStr) {
    return nil;
  }

  // Find key
  const uint8_t *scan = decodeData;
  int32_t numEntries = ReadRawVarint32FromData(&scan);
  BOOL foundKey = NO;
  while (!foundKey && (numEntries > 0)) {
    --numEntries;
    int32_t dataKey = ReadRawVarint32FromData(&scan);
    if (dataKey == key) {
      foundKey = YES;
    } else {
      // If it is a inlined string, it will start with \0; if it is bytecode it
      // will start with a code. So advance one (skipping the inline string
      // marker), and then loop until reaching the end marker (\0).
      ++scan;
      while (*scan != 0) ++scan;
      // Now move past the end marker.
      ++scan;
    }
  }

  if (!foundKey) {
    return nil;
  }

  // Decode

  if (*scan == 0) {
    // Inline string. Move over the marker, and NSString can take it as
    // UTF8.
    ++scan;
    NSString *result = [NSString stringWithUTF8String:(const char *)scan];
    return result;
  }

  NSMutableString *result =
      [NSMutableString stringWithCapacity:[inputStr length]];

  const uint8_t kAddUnderscore  = 0b10000000;
  const uint8_t kOpMask         = 0b01100000;
  // const uint8_t kOpAsIs        = 0b00000000;
  const uint8_t kOpFirstUpper     = 0b01000000;
  const uint8_t kOpFirstLower     = 0b00100000;
  const uint8_t kOpAllUpper       = 0b01100000;
  const uint8_t kSegmentLenMask = 0b00011111;

  NSInteger i = 0;
  for (; *scan != 0; ++scan) {
    if (*scan & kAddUnderscore) {
      [result appendString:@"_"];
    }
    int segmentLen = *scan & kSegmentLenMask;
    uint8_t decodeOp = *scan & kOpMask;

    // Do op specific handling of the first character.
    if (decodeOp == kOpFirstUpper) {
      unichar c = [inputStr characterAtIndex:i];
      [result appendFormat:@"%c", toupper((char)c)];
      ++i;
      --segmentLen;
    } else if (decodeOp == kOpFirstLower) {
      unichar c = [inputStr characterAtIndex:i];
      [result appendFormat:@"%c", tolower((char)c)];
      ++i;
      --segmentLen;
    }
    // else op == kOpAsIs || op == kOpAllUpper

    // Now pull over the rest of the length for this segment.
    for (int x = 0; x < segmentLen; ++x) {
      unichar c = [inputStr characterAtIndex:(i + x)];
      if (decodeOp == kOpAllUpper) {
        [result appendFormat:@"%c", toupper((char)c)];
      } else {
        [result appendFormat:@"%C", c];
      }
    }
    i += segmentLen;
  }

  return result;
}

#pragma clang diagnostic pop

#pragma mark - LCIMMessageSignatureProtocol

// A series of selectors that are used solely to get @encoding values
// for them by the dynamic protobuf runtime code. An object using the protocol
// needs to be declared for the protocol to be valid at runtime.
@interface LCIMMessageSignatureProtocol : NSObject<LCIMMessageSignatureProtocol>
@end
@implementation LCIMMessageSignatureProtocol
@end
