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

typedef enum {
    AVSR_CONNECTING   = 0,
    AVSR_OPEN         = 1,
    AVSR_CLOSING      = 2,
    AVSR_CLOSED       = 3,
} AVSRReadyState;

@class AVSRWebSocket;

extern NSString *const AVSRWebSocketErrorDomain;

#pragma mark - AVSRWebSocketDelegate

@protocol AVSRWebSocketDelegate;

#pragma mark - AVSRWebSocket

@interface AVSRWebSocket : NSObject <NSStreamDelegate>

@property (nonatomic, assign) id <AVSRWebSocketDelegate> delegate;

@property (nonatomic, readonly) AVSRReadyState readyState;
@property (nonatomic, readonly, retain) NSURL *url;

// This returns the negotiated protocol.
// It will be nil until after the handshake completes.
@property (nonatomic, readonly, copy) NSString *protocol;

// Protocols should be an array of strings that turn into Sec-WebSocket-Protocol.
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols;
- (id)initWithURLRequest:(NSURLRequest *)request;

// Some helper constructors.
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;
- (id)initWithURL:(NSURL *)url;

// Delegate queue will be dispatch_main_queue by default.
// You cannot set both OperationQueue and dispatch_queue.
- (void)setDelegateOperationQueue:(NSOperationQueue*) queue;
- (void)setDelegateDispatchQueue:(dispatch_queue_t) queue;

// By default, it will schedule itself on +[NSRunLoop AVSR_networkRunLoop] using defaultModes.
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
- (void)unscheduleFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;

// AVSRWebSockets are intended for one-time-use only.  Open should be called once and only once.
- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

// send a Ping Frame
- (void)sendPing;
- (void)disconnect;
@end

#pragma mark - AVSRWebSocketDelegate

@protocol AVSRWebSocketDelegate <NSObject>

// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(AVSRWebSocket *)webSocket didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(AVSRWebSocket *)webSocket;
- (void)webSocket:(AVSRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(AVSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
- (void)webSocket:(AVSRWebSocket *)webSocket didReceivePongFrame:(id)data;
@end

#pragma mark - NSURLRequest (CertificateAdditions)

@interface NSURLRequest (CertificateAdditions)

@property (nonatomic, retain, readonly) NSArray *SR_SSLPinnedCertificates;

@end

#pragma mark - NSMutableURLRequest (CertificateAdditions)

@interface NSMutableURLRequest (CertificateAdditions)

@property (nonatomic, retain) NSArray *SR_SSLPinnedCertificates;

@end

#pragma mark - NSRunLoop (AVSRWebSocket)

@interface NSRunLoop (AVSRWebSocket)

+ (NSRunLoop *)AVSR_networkRunLoop;

@end
