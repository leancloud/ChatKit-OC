//
//   Copyright 2012 Square Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import <Foundation/Foundation.h>
#import <Security/SecCertificate.h>

typedef NS_ENUM(NSInteger, AVIMReadyState) {
    AVIM_CONNECTING   = 1,
    AVIM_OPEN         = 2,
    AVIM_CLOSING      = 3,
    AVIM_CLOSED       = 4,
};

typedef enum AVIMStatusCode : NSInteger {
    AVIMStatusCodeNormal = 1000,
    AVIMStatusCodeGoingAway = 1001,
    AVIMStatusCodeProtocolError = 1002,
    AVIMStatusCodeUnhandledType = 1003,
    // 1004 reserved.
    AVIMStatusNoStatusReceived = 1005,
    // 1004-1006 reserved.
    AVIMStatusCodeInvalidUTF8 = 1007,
    AVIMStatusCodePolicyViolated = 1008,
    AVIMStatusCodeMessageTooBig = 1009,
} AVIMStatusCode;

typedef NS_ENUM(NSInteger, AVIMSSLPinningMode) {
    AVIMSSLPinningModeNone        = 0,
    AVIMSSLPinningModeCertificate = 1,
    AVIMSSLPinningModePublicKey   = 2
};

@class AVIMWebSocket;

extern NSString *const AVIMWebSocketErrorDomain;
extern NSString *const AVIMHTTPResponseErrorKey;

#pragma mark - AVIMWebSocketDelegate

@protocol AVIMWebSocketDelegate;

#pragma mark - AVIMWebSocket

@interface AVIMWebSocket : NSObject <NSStreamDelegate>

@property (nonatomic, weak) id <AVIMWebSocketDelegate> delegate;

@property (nonatomic, readonly) AVIMReadyState readyState;
@property (nonatomic, readonly, retain) NSURL *url;


@property (nonatomic, readonly) CFHTTPMessageRef receivedHTTPHeaders;

// Optional array of cookies (NSHTTPCookie objects) to apply to the connections
@property (nonatomic, readwrite) NSArray * requestCookies;

// This returns the negotiated protocol.
// It will be nil until after the handshake completes.
@property (nonatomic, readonly, copy) NSString *protocol;
@property (nonatomic, assign) AVIMSSLPinningMode SSLPinningMode;

// Protocols should be an array of strings that turn into Sec-WebSocket-Protocol.
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates;
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols;
- (id)initWithURLRequest:(NSURLRequest *)request;

// Some helper constructors.
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates;
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;
- (id)initWithURL:(NSURL *)url;

// Delegate queue will be dispatch_main_queue by default.
// You cannot set both OperationQueue and dispatch_queue.
- (void)setDelegateOperationQueue:(NSOperationQueue*) queue;
- (void)setDelegateDispatchQueue:(dispatch_queue_t) queue;

// By default, it will schedule itself on +[NSRunLoop AVIM_networkRunLoop] using defaultModes.
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
- (void)unscheduleFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;

// AVIMWebSockets are intended for one-time-use only.  Open should be called once and only once.
- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

// Send Data (can be nil) in a ping message.
- (void)sendPing:(NSData *)data;

@end

#pragma mark - AVIMWebSocketDelegate

@protocol AVIMWebSocketDelegate <NSObject>

// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(AVIMWebSocket *)webSocket didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(AVIMWebSocket *)webSocket;
- (void)webSocket:(AVIMWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(AVIMWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
- (void)webSocket:(AVIMWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;

@end

#pragma mark - NSURLRequest (CertificateAdditions)

@interface NSURLRequest (CertificateAdditions)

@property (nonatomic, retain, readonly) NSArray *AVIM_SSLPinnedCertificates;

@end

#pragma mark - NSMutableURLRequest (CertificateAdditions)

@interface NSMutableURLRequest (CertificateAdditions)

@property (nonatomic, retain) NSArray *AVIM_SSLPinnedCertificates;

@end

#pragma mark - NSRunLoop (AVIMWebSocket)

@interface NSRunLoop (AVIMWebSocket)

+ (NSRunLoop *)AVIM_networkRunLoop;

@end
