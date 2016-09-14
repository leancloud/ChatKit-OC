//
//  AVPartialInputStream.m
//  AVOS
//
//  Created by Qihe Bian on 8/21/14.
//
//

#import "AVPartialInputStream.h"
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#import "AVLogger.h"

@interface AVPartialInputStream () <NSStreamDelegate> {
    int _fd;
    __weak id <NSStreamDelegate> _delegate;
    uint64_t _fileSize;
    NSUInteger _events;
    NSStreamStatus _status;
    BOOL _delegateValid;
    
    CFReadStreamClientCallBack _clientCallback;
    CFStreamClientContext      _clientContext;
    CFOptionFlags              _clientFlags;
}
@property(nonatomic, strong)NSString *path;
@property(nonatomic, strong)NSError *error;
//@property (nonatomic) NSUInteger delivered;
//@property (assign) id <NSStreamDelegate> delegate;
@end
@implementation AVPartialInputStream
- (instancetype)initWithFileAtPath:(NSString *)path {
    if ((self = [super init])) {
        self.path = path;
        [self _setStatus:NSStreamStatusNotOpen];
        _delegate = self;
        _events = 0;
        _delegateValid = NO;
    }
    return self;
}

- (id<NSStreamDelegate>)delegate {
    return _delegate;
}

- (void)setDelegate:(id<NSStreamDelegate>)delegate {
    if ([self streamStatus] == NSStreamStatusClosed || [self streamStatus] == NSStreamStatusError) {
        _delegateValid = NO;
    } else {
        if (!delegate) {
            _delegate = self;
        } else {
            _delegate = delegate;
        }
        /* We don't want to send any events the the delegate after the
         * stream has been closed.
         */
        _delegateValid = [_delegate respondsToSelector: @selector(stream:handleEvent:)];
    }
}
- (void)open {
    uint64_t index = self.offset / (1 << 22);
    AVLoggerD(@"open %llu", index);
    if (_status != NSStreamStatusNotOpen)
    {
        AVLoggerD(@"Attempt to re-open stream %@", self);
    }
    [self _setStatus: NSStreamStatusOpening];
    const char *p = [self.path UTF8String];
    _fd = open(p, O_RDONLY);
    if (_fd == -1) {
        char *errMsg = strerror(errno);
        NSString *errorMessage = [[NSString alloc] initWithFormat:@"%s", errMsg];
        self.error = [[NSError alloc] initWithDomain:@"AVPartialInputStream" code:errno userInfo:@{@"reason":errorMessage}];
        [self _setStatus: NSStreamStatusError];
        return;
    }
    struct stat st;
    fstat(_fd, &st);
    _fileSize = st.st_size;
    off_t r = lseek(_fd, self.offset, SEEK_SET);
    if (r == -1) {
        char *errMsg = strerror(errno);
        NSString *errorMessage = [[NSString alloc] initWithFormat:@"%s", errMsg];
        self.error = [[NSError alloc] initWithDomain:@"AVPartialInputStream" code:errno userInfo:@{@"reason":errorMessage}];
        [self _setStatus: NSStreamStatusError];
        return;
    }
    [self _sendEvent: NSStreamEventOpenCompleted];
}
- (void)close {
    uint64_t index = self.offset / (1 << 22);
    AVLoggerD(@"close %llu", index);
    if (_status == NSStreamStatusNotOpen || _status == NSStreamStatusClosed)
    {
        AVLoggerD(@"Attempt to close unopened stream %@", self);
    }
    close(_fd);
    [self _setStatus: NSStreamStatusClosed];
    /* We don't want to send any events to the delegate after the
     * stream has been closed.
     */
    _delegateValid = NO;
}
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    off_t cur = lseek(_fd, 0, SEEK_CUR);
    AVLoggerD(@"read %llu", cur);
    if ([self streamStatus] == NSStreamStatusClosed || [self streamStatus] == NSStreamStatusAtEnd) {
        return 0;
    }
    uint64_t l = len;
    if (l > self.maxLength) {
        l = self.maxLength;
    }
    _events &= ~NSStreamEventHasBytesAvailable;
    [self _setStatus:NSStreamStatusReading];
    
    ssize_t s = read(_fd, buffer, l);
    if (s == -1) {
        char *errMsg = strerror(errno);
        NSString *errorMessage = [[NSString alloc] initWithFormat:@"%s", errMsg];
        self.error = [[NSError alloc] initWithDomain:@"AVPartialInputStream" code:errno userInfo:@{@"reason":errorMessage}];
        [self _setStatus:NSStreamStatusError];
//        [self _sendEvent:NSStreamEventErrorOccurred];
    } else if (s == 0 || s == _fileSize - self.offset || s == self.maxLength) {
        [self _setStatus: NSStreamStatusAtEnd];
    }
    return s;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    return NO;
}

- (BOOL)hasBytesAvailable {
    off_t cur = lseek(_fd, 0, SEEK_CUR);
    // AVLoggerD(@"hasBytesAvailable %llu cur:%llu offset:%llu max:%llu", index, cur, self.offset, self.offset + self.maxLength);
    if (cur >= self.offset + self.maxLength || cur >= _fileSize) {
        // AVLoggerD(@"NO");
        return NO;
    }
    // AVLoggerD(@"YES");
    return YES;
}

- (NSStreamStatus)streamStatus
{
//    if (_status == NSStreamStatusNotOpen || _status == NSStreamStatusClosed) {
//        return _status;
//    }
//    off_t cur = lseek(_fd, 0, SEEK_CUR);
//    if (_status != NSStreamStatusClosed && (cur >= self.offset + self.maxLength || cur >= _fileSize))
//    {
//        _status = NSStreamStatusAtEnd;
//    }
    return _status;
}
- (NSError *)streamError {
    return [self.error copy];
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    //    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow] target:self selector:@selector(_dispatch) userInfo:nil repeats:<#(BOOL)#>]
    //    aRunLoop addTimer:<#(NSTimer *)#> forMode:<#(NSString *)#>
    [aRunLoop performSelector:@selector(_dispatch) target:self argument:nil order:0 modes:@[mode]];
}
- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    [aRunLoop cancelPerformSelectorsWithTarget:self];
}
//- (void)_scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
//    //    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow] target:self selector:@selector(_dispatch) userInfo:nil repeats:<#(BOOL)#>]
//    //    aRunLoop addTimer:<#(NSTimer *)#> forMode:<#(NSString *)#>
//    [aRunLoop performSelector:@selector(_dispatch) target:self argument:nil order:0 modes:@[mode]];
//}

- (void)_scheduleInCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)mode {
    
    [[NSRunLoop currentRunLoop] performSelector:@selector(_dispatch) target:self argument:nil order:0 modes:@[(__bridge NSString *)mode]];
}

- (BOOL)_setCFClientFlags:(CFOptionFlags)flags
                 callback:(CFReadStreamClientCallBack)callback
                  context:(CFStreamClientContext *)context {
    if ( context && context->version != 0 )
        return NO;
    
    if ( _clientContext.release )
        _clientContext.release(_clientContext.info);
    
    _clientContext = (CFStreamClientContext) { 0 };
    if ( context )
        _clientContext = *context;
    
    if ( _clientContext.retain )
        _clientContext.retain(_clientContext.info);
    
    _clientFlags = flags;
    _clientCallback = callback;
    
    return YES;
}

- (void)_unscheduleFromCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)mode {
    [[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];
}
#pragma mark -
#pragma mark NSURLConnection Hacks

//- (void) _scheduleInCFRunLoop: (NSRunLoop *) inRunLoop forMode: (id) inMode
//{
//    // Safe to ignore this?
//}
//
//- (void) _setCFClientFlags: (CFOptionFlags)inFlags
//                  callback: (CFReadStreamClientCallBack) inCallback
//                   context: (CFStreamClientContext) inContext
//{
//    // Safe to ignore this?
//}

- (void)_sendEvent:(NSStreamEvent)event {
//    if ([self.delegate respondsToSelector:@selector(stream:handleEvent:)]) {
//        dispatch_async(dispatch_get_current_queue(), ^{
//            [self.delegate stream:self handleEvent:event];
//        });
//    }
    if (event == NSStreamEventNone) {
        return;
    } else if (event == NSStreamEventOpenCompleted) {
        if ((_events & event) == 0) {
            _events |= NSStreamEventOpenCompleted;
            if (_delegateValid) {
                [_delegate stream: self handleEvent: NSStreamEventOpenCompleted];
            }
        }
    } else if (event == NSStreamEventHasBytesAvailable)
    {
        if ((_events & NSStreamEventOpenCompleted) == 0)
        {
            _events |= NSStreamEventOpenCompleted;
            if (_delegateValid == YES)
            {
                [_delegate stream: self
                      handleEvent: NSStreamEventOpenCompleted];
            }
        }
        if ((_events & NSStreamEventHasBytesAvailable) == 0)
        {
            _events |= NSStreamEventHasBytesAvailable;
            if (_delegateValid == YES)
            {
                [_delegate stream: self
                      handleEvent: NSStreamEventHasBytesAvailable];
            }
        }
    }
    else if (event == NSStreamEventErrorOccurred)
    {
        if ((_events & NSStreamEventErrorOccurred) == 0)
        {
            _events |= NSStreamEventErrorOccurred;
            if (_delegateValid == YES)
            {
                [_delegate stream: self
                      handleEvent: NSStreamEventErrorOccurred];
            }
        }
    }
    else if (event == NSStreamEventEndEncountered)
    {
        if ((_events & NSStreamEventEndEncountered) == 0)
        {
            _events |= NSStreamEventEndEncountered;
            if (_delegateValid == YES)
            {
                [_delegate stream: self
                      handleEvent: NSStreamEventEndEncountered];
            }
        }
    }
    else
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"Unknown event (%"PRIuPTR") passed to _sendEvent:",
         event];
    }
}

- (void) _resetEvents: (NSUInteger)mask
{
    _events &= ~mask;
}

- (void) _setStatus: (NSStreamStatus)status
{
    _status = status;
}

- (void) _dispatch {
    if (_status == NSStreamStatusError) {
        AVLoggerD(@"error %@", [self streamError]);
        [self _sendEvent: NSStreamEventErrorOccurred];
    }
    BOOL av = [self hasBytesAvailable];

    NSStreamEvent myEvent = av ? NSStreamEventHasBytesAvailable :
    NSStreamEventEndEncountered;
    NSStreamStatus myStatus = av ? NSStreamStatusOpen : NSStreamStatusAtEnd;
//    if (myStatus == NSStreamStatusAtEnd) {
//        uint64_t index = self.offset / (1 << 22);
//        AVLoggerD(@"eof %llu", index);
//    }
    [self _setStatus: myStatus];
    [self _sendEvent: myEvent];
    [self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}
@end
