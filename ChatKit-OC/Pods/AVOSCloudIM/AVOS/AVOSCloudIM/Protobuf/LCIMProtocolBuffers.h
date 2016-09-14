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

#import "LCIMBootstrap.h"

#import "LCIMArray.h"
#import "LCIMCodedInputStream.h"
#import "LCIMCodedOutputStream.h"
#import "LCIMDescriptor.h"
#import "LCIMDictionary.h"
#import "LCIMExtensionRegistry.h"
#import "LCIMMessage.h"
#import "LCIMRootObject.h"
#import "LCIMUnknownField.h"
#import "LCIMUnknownFieldSet.h"
#import "LCIMUtilities.h"
#import "LCIMWellKnownTypes.h"
#import "LCIMWireFormat.h"

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(LCIM_USE_PROTOBUF_FRAMEWORK_IMPORTS)
#define LCIM_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

// Well-known proto types
#if LCIM_USE_PROTOBUF_FRAMEWORK_IMPORTS
#import <Protobuf/LCIMAny.pbobjc.h>
#import <Protobuf/LCIMApi.pbobjc.h>
#import <Protobuf/LCIMDuration.pbobjc.h>
#import <Protobuf/LCIMEmpty.pbobjc.h>
#import <Protobuf/LCIMFieldMask.pbobjc.h>
#import <Protobuf/LCIMSourceContext.pbobjc.h>
#import <Protobuf/LCIMStruct.pbobjc.h>
#import <Protobuf/LCIMTimestamp.pbobjc.h>
#import <Protobuf/LCIMType.pbobjc.h>
#import <Protobuf/LCIMWrappers.pbobjc.h>
#else
#import "google/protobuf/LCIMAny.pbobjc.h"
#import "google/protobuf/LCIMApi.pbobjc.h"
#import "google/protobuf/LCIMDuration.pbobjc.h"
#import "google/protobuf/LCIMEmpty.pbobjc.h"
#import "google/protobuf/LCIMFieldMask.pbobjc.h"
#import "google/protobuf/LCIMSourceContext.pbobjc.h"
#import "google/protobuf/LCIMStruct.pbobjc.h"
#import "google/protobuf/LCIMTimestamp.pbobjc.h"
#import "google/protobuf/LCIMType.pbobjc.h"
#import "google/protobuf/LCIMWrappers.pbobjc.h"
#endif
