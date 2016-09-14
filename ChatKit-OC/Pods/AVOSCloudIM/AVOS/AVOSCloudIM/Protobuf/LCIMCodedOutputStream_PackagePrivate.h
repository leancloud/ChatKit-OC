// Protocol Buffers - Google's data interchange format
// Copyright 2016 Google Inc.  All rights reserved.
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

#import "LCIMCodedOutputStream.h"

NS_ASSUME_NONNULL_BEGIN

CF_EXTERN_C_BEGIN

size_t LCIMComputeDoubleSize(int32_t fieldNumber, double value)
    __attribute__((const));
size_t LCIMComputeFloatSize(int32_t fieldNumber, float value)
    __attribute__((const));
size_t LCIMComputeUInt64Size(int32_t fieldNumber, uint64_t value)
    __attribute__((const));
size_t LCIMComputeInt64Size(int32_t fieldNumber, int64_t value)
    __attribute__((const));
size_t LCIMComputeInt32Size(int32_t fieldNumber, int32_t value)
    __attribute__((const));
size_t LCIMComputeFixed64Size(int32_t fieldNumber, uint64_t value)
    __attribute__((const));
size_t LCIMComputeFixed32Size(int32_t fieldNumber, uint32_t value)
    __attribute__((const));
size_t LCIMComputeBoolSize(int32_t fieldNumber, BOOL value)
    __attribute__((const));
size_t LCIMComputeStringSize(int32_t fieldNumber, NSString *value)
    __attribute__((const));
size_t LCIMComputeGroupSize(int32_t fieldNumber, LCIMMessage *value)
    __attribute__((const));
size_t LCIMComputeUnknownGroupSize(int32_t fieldNumber,
                                  LCIMUnknownFieldSet *value)
    __attribute__((const));
size_t LCIMComputeMessageSize(int32_t fieldNumber, LCIMMessage *value)
    __attribute__((const));
size_t LCIMComputeBytesSize(int32_t fieldNumber, NSData *value)
    __attribute__((const));
size_t LCIMComputeUInt32Size(int32_t fieldNumber, uint32_t value)
    __attribute__((const));
size_t LCIMComputeSFixed32Size(int32_t fieldNumber, int32_t value)
    __attribute__((const));
size_t LCIMComputeSFixed64Size(int32_t fieldNumber, int64_t value)
    __attribute__((const));
size_t LCIMComputeSInt32Size(int32_t fieldNumber, int32_t value)
    __attribute__((const));
size_t LCIMComputeSInt64Size(int32_t fieldNumber, int64_t value)
    __attribute__((const));
size_t LCIMComputeTagSize(int32_t fieldNumber) __attribute__((const));
size_t LCIMComputeWireFormatTagSize(int field_number, GPBDataType dataType)
    __attribute__((const));

size_t LCIMComputeDoubleSizeNoTag(double value) __attribute__((const));
size_t LCIMComputeFloatSizeNoTag(float value) __attribute__((const));
size_t LCIMComputeUInt64SizeNoTag(uint64_t value) __attribute__((const));
size_t LCIMComputeInt64SizeNoTag(int64_t value) __attribute__((const));
size_t LCIMComputeInt32SizeNoTag(int32_t value) __attribute__((const));
size_t LCIMComputeFixed64SizeNoTag(uint64_t value) __attribute__((const));
size_t LCIMComputeFixed32SizeNoTag(uint32_t value) __attribute__((const));
size_t LCIMComputeBoolSizeNoTag(BOOL value) __attribute__((const));
size_t LCIMComputeStringSizeNoTag(NSString *value) __attribute__((const));
size_t LCIMComputeGroupSizeNoTag(LCIMMessage *value) __attribute__((const));
size_t LCIMComputeUnknownGroupSizeNoTag(LCIMUnknownFieldSet *value)
    __attribute__((const));
size_t LCIMComputeMessageSizeNoTag(LCIMMessage *value) __attribute__((const));
size_t LCIMComputeBytesSizeNoTag(NSData *value) __attribute__((const));
size_t LCIMComputeUInt32SizeNoTag(int32_t value) __attribute__((const));
size_t LCIMComputeEnumSizeNoTag(int32_t value) __attribute__((const));
size_t LCIMComputeSFixed32SizeNoTag(int32_t value) __attribute__((const));
size_t LCIMComputeSFixed64SizeNoTag(int64_t value) __attribute__((const));
size_t LCIMComputeSInt32SizeNoTag(int32_t value) __attribute__((const));
size_t LCIMComputeSInt64SizeNoTag(int64_t value) __attribute__((const));

// Note that this will calculate the size of 64 bit values truncated to 32.
size_t LCIMComputeSizeTSizeAsInt32NoTag(size_t value) __attribute__((const));

size_t LCIMComputeRawVarint32Size(int32_t value) __attribute__((const));
size_t LCIMComputeRawVarint64Size(int64_t value) __attribute__((const));

// Note that this will calculate the size of 64 bit values truncated to 32.
size_t LCIMComputeRawVarint32SizeForInteger(NSInteger value)
    __attribute__((const));

// Compute the number of bytes that would be needed to encode a
// MessageSet extension to the stream.  For historical reasons,
// the wire format differs from normal fields.
size_t LCIMComputeMessageSetExtensionSize(int32_t fieldNumber, LCIMMessage *value)
    __attribute__((const));

// Compute the number of bytes that would be needed to encode an
// unparsed MessageSet extension field to the stream.  For
// historical reasons, the wire format differs from normal fields.
size_t LCIMComputeRawMessageSetExtensionSize(int32_t fieldNumber, NSData *value)
    __attribute__((const));

size_t LCIMComputeEnumSize(int32_t fieldNumber, int32_t value)
    __attribute__((const));

CF_EXTERN_C_END

NS_ASSUME_NONNULL_END
