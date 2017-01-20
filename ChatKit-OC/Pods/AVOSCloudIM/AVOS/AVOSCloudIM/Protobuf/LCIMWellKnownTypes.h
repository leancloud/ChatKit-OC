// Protocol Buffers - Google's data interchange format
// Copyright 2015 Google Inc.  All rights reserved.
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

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(LCIM_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define LCIM_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if LCIM_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/LCIMAny.pbobjc.h>
 #import <Protobuf/LCIMDuration.pbobjc.h>
 #import <Protobuf/LCIMTimestamp.pbobjc.h>
#else
 #import "google/protobuf/LCIMAny.pbobjc.h"
 #import "google/protobuf/LCIMDuration.pbobjc.h"
 #import "google/protobuf/LCIMTimestamp.pbobjc.h"
#endif

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Errors

/** NSError domain used for errors. */
extern NSString *const LCIMWellKnownTypesErrorDomain;

/** Error code for NSError with LCIMWellKnownTypesErrorDomain. */
typedef NS_ENUM(NSInteger, LCIMWellKnownTypesErrorCode) {
  /** The type_url could not be computed for the requested LCIMMessage class. */
  LCIMWellKnownTypesErrorCodeFailedToComputeTypeURL = -100,
  /** type_url in a Any doesn’t match that of the requested LCIMMessage class. */
  LCIMWellKnownTypesErrorCodeTypeURLMismatch = -101,
};

#pragma mark - LCIMTimestamp

/**
 * Category for LCIMTimestamp to work with standard Foundation time/date types.
 **/
@interface LCIMTimestamp (LCIMWellKnownTypes)

/** The NSDate representation of this LCIMTimestamp. */
@property(nonatomic, readwrite, strong) NSDate *date;

/**
 * The NSTimeInterval representation of this LCIMTimestamp.
 *
 * @note: Not all second/nanos combinations can be represented in a
 * NSTimeInterval, so getting this could be a lossy transform.
 **/
@property(nonatomic, readwrite) NSTimeInterval timeIntervalSince1970;

/**
 * Initializes a LCIMTimestamp with the given NSDate.
 *
 * @param date The date to configure the LCIMTimestamp with.
 *
 * @return A newly initialized LCIMTimestamp.
 **/
- (instancetype)initWithDate:(NSDate *)date;

/**
 * Initializes a LCIMTimestamp with the given NSTimeInterval.
 *
 * @param timeIntervalSince1970 Time interval to configure the LCIMTimestamp with.
 *
 * @return A newly initialized LCIMTimestamp.
 **/
- (instancetype)initWithTimeIntervalSince1970:(NSTimeInterval)timeIntervalSince1970;

@end

#pragma mark - LCIMDuration

/**
 * Category for LCIMDuration to work with standard Foundation time type.
 **/
@interface LCIMDuration (LCIMWellKnownTypes)

/**
 * The NSTimeInterval representation of this LCIMDuration.
 *
 * @note: Not all second/nanos combinations can be represented in a
 * NSTimeInterval, so getting this could be a lossy transform.
 **/
@property(nonatomic, readwrite) NSTimeInterval timeIntervalSince1970;

/**
 * Initializes a LCIMDuration with the given NSTimeInterval.
 *
 * @param timeIntervalSince1970 Time interval to configure the LCIMDuration with.
 *
 * @return A newly initialized LCIMDuration.
 **/
- (instancetype)initWithTimeIntervalSince1970:(NSTimeInterval)timeIntervalSince1970;

@end

#pragma mark - LCIMAny

/**
 * Category for LCIMAny to help work with the message within the object.
 **/
@interface LCIMAny (LCIMWellKnownTypes)

/**
 * Convenience method to create a LCIMAny containing the serialized message.
 * This uses type.googleapis.com/ as the type_url's prefix.
 *
 * @param message  The message to be packed into the LCIMAny.
 * @param errorPtr Pointer to an error that will be populated if something goes
 *                 wrong.
 *
 * @return A newly configured LCIMAny with the given message, or nil on failure.
 */
+ (nullable instancetype)anyWithMessage:(nonnull LCIMMessage *)message
                                  error:(NSError **)errorPtr;

/**
 * Convenience method to create a LCIMAny containing the serialized message.
 *
 * @param message       The message to be packed into the LCIMAny.
 * @param typeURLPrefix The URL prefix to apply for type_url.
 * @param errorPtr      Pointer to an error that will be populated if something
 *                      goes wrong.
 *
 * @return A newly configured LCIMAny with the given message, or nil on failure.
 */
+ (nullable instancetype)anyWithMessage:(nonnull LCIMMessage *)message
                          typeURLPrefix:(nonnull NSString *)typeURLPrefix
                                  error:(NSError **)errorPtr;

/**
 * Initializes a LCIMAny to contain the serialized message. This uses
 * type.googleapis.com/ as the type_url's prefix.
 *
 * @param message  The message to be packed into the LCIMAny.
 * @param errorPtr Pointer to an error that will be populated if something goes
 *                 wrong.
 *
 * @return A newly configured LCIMAny with the given message, or nil on failure.
 */
- (nullable instancetype)initWithMessage:(nonnull LCIMMessage *)message
                                   error:(NSError **)errorPtr;

/**
 * Initializes a LCIMAny to contain the serialized message.
 *
 * @param message       The message to be packed into the LCIMAny.
 * @param typeURLPrefix The URL prefix to apply for type_url.
 * @param errorPtr      Pointer to an error that will be populated if something
 *                      goes wrong.
 *
 * @return A newly configured LCIMAny with the given message, or nil on failure.
 */
- (nullable instancetype)initWithMessage:(nonnull LCIMMessage *)message
                           typeURLPrefix:(nonnull NSString *)typeURLPrefix
                                   error:(NSError **)errorPtr;

/**
 * Packs the serialized message into this LCIMAny. This uses
 * type.googleapis.com/ as the type_url's prefix.
 *
 * @param message  The message to be packed into the LCIMAny.
 * @param errorPtr Pointer to an error that will be populated if something goes
 *                 wrong.
 *
 * @return Whether the packing was successful or not.
 */
- (BOOL)packWithMessage:(nonnull LCIMMessage *)message
                  error:(NSError **)errorPtr;

/**
 * Packs the serialized message into this LCIMAny.
 *
 * @param message       The message to be packed into the LCIMAny.
 * @param typeURLPrefix The URL prefix to apply for type_url.
 * @param errorPtr      Pointer to an error that will be populated if something
 *                      goes wrong.
 *
 * @return Whether the packing was successful or not.
 */
- (BOOL)packWithMessage:(nonnull LCIMMessage *)message
          typeURLPrefix:(nonnull NSString *)typeURLPrefix
                  error:(NSError **)errorPtr;

/**
 * Unpacks the serialized message as if it was an instance of the given class.
 *
 * @note When checking type_url, the base URL is not checked, only the fully
 *       qualified name.
 *
 * @param messageClass The class to use to deserialize the contained message.
 * @param errorPtr     Pointer to an error that will be populated if something
 *                     goes wrong.
 *
 * @return An instance of the given class populated with the contained data, or
 *         nil on failure.
 */
- (nullable LCIMMessage *)unpackMessageClass:(Class)messageClass
                                      error:(NSError **)errorPtr;

@end

NS_ASSUME_NONNULL_END
