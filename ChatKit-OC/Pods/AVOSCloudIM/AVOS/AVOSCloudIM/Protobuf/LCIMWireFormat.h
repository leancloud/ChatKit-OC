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

#import "LCIMRuntimeTypes.h"

CF_EXTERN_C_BEGIN

NS_ASSUME_NONNULL_BEGIN

typedef enum {
  LCIMWireFormatVarint = 0,
  LCIMWireFormatFixed64 = 1,
  LCIMWireFormatLengthDelimited = 2,
  LCIMWireFormatStartGroup = 3,
  LCIMWireFormatEndGroup = 4,
  LCIMWireFormatFixed32 = 5,
} LCIMWireFormat;

enum {
  LCIMWireFormatMessageSetItem = 1,
  LCIMWireFormatMessageSetTypeId = 2,
  LCIMWireFormatMessageSetMessage = 3
};

uint32_t LCIMWireFormatMakeTag(uint32_t fieldNumber, LCIMWireFormat wireType)
    __attribute__((const));
LCIMWireFormat LCIMWireFormatGetTagWireType(uint32_t tag) __attribute__((const));
uint32_t LCIMWireFormatGetTagFieldNumber(uint32_t tag) __attribute__((const));
BOOL LCIMWireFormatIsValidTag(uint32_t tag) __attribute__((const));

LCIMWireFormat LCIMWireFormatForType(GPBDataType dataType, BOOL isPacked)
    __attribute__((const));

#define LCIMWireFormatMessageSetItemTag \
  (LCIMWireFormatMakeTag(LCIMWireFormatMessageSetItem, LCIMWireFormatStartGroup))
#define LCIMWireFormatMessageSetItemEndTag \
  (LCIMWireFormatMakeTag(LCIMWireFormatMessageSetItem, LCIMWireFormatEndGroup))
#define LCIMWireFormatMessageSetTypeIdTag \
  (LCIMWireFormatMakeTag(LCIMWireFormatMessageSetTypeId, LCIMWireFormatVarint))
#define LCIMWireFormatMessageSetMessageTag               \
  (LCIMWireFormatMakeTag(LCIMWireFormatMessageSetMessage, \
                        LCIMWireFormatLengthDelimited))

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END
