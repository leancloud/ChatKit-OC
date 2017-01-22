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

#import "LCIMWireFormat.h"

#import "LCIMUtilities_PackagePrivate.h"

enum {
  LCIMWireFormatTagTypeBits = 3,
  LCIMWireFormatTagTypeMask = 7 /* = (1 << LCIMWireFormatTagTypeBits) - 1 */,
};

uint32_t LCIMWireFormatMakeTag(uint32_t fieldNumber, LCIMWireFormat wireType) {
  return (fieldNumber << LCIMWireFormatTagTypeBits) | wireType;
}

LCIMWireFormat LCIMWireFormatGetTagWireType(uint32_t tag) {
  return (LCIMWireFormat)(tag & LCIMWireFormatTagTypeMask);
}

uint32_t LCIMWireFormatGetTagFieldNumber(uint32_t tag) {
  return LCIMLogicalRightShift32(tag, LCIMWireFormatTagTypeBits);
}

BOOL LCIMWireFormatIsValidTag(uint32_t tag) {
  uint32_t formatBits = (tag & LCIMWireFormatTagTypeMask);
  // The valid LCIMWireFormat* values are 0-5, anything else is not a valid tag.
  BOOL result = (formatBits <= 5);
  return result;
}

LCIMWireFormat LCIMWireFormatForType(GPBDataType type, BOOL isPacked) {
  if (isPacked) {
    return LCIMWireFormatLengthDelimited;
  }

  static const LCIMWireFormat format[GPBDataType_Count] = {
      LCIMWireFormatVarint,           // GPBDataTypeBool
      LCIMWireFormatFixed32,          // GPBDataTypeFixed32
      LCIMWireFormatFixed32,          // GPBDataTypeSFixed32
      LCIMWireFormatFixed32,          // GPBDataTypeFloat
      LCIMWireFormatFixed64,          // GPBDataTypeFixed64
      LCIMWireFormatFixed64,          // GPBDataTypeSFixed64
      LCIMWireFormatFixed64,          // GPBDataTypeDouble
      LCIMWireFormatVarint,           // GPBDataTypeInt32
      LCIMWireFormatVarint,           // GPBDataTypeInt64
      LCIMWireFormatVarint,           // GPBDataTypeSInt32
      LCIMWireFormatVarint,           // GPBDataTypeSInt64
      LCIMWireFormatVarint,           // GPBDataTypeUInt32
      LCIMWireFormatVarint,           // GPBDataTypeUInt64
      LCIMWireFormatLengthDelimited,  // GPBDataTypeBytes
      LCIMWireFormatLengthDelimited,  // GPBDataTypeString
      LCIMWireFormatLengthDelimited,  // GPBDataTypeMessage
      LCIMWireFormatStartGroup,       // GPBDataTypeGroup
      LCIMWireFormatVarint            // GPBDataTypeEnum
  };
  return format[type];
}
