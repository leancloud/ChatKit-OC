// COSObserver.h
//
// Copyright (c) 2014 Tianyong Tang
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
// KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
// AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

typedef void(^LCObserverBlock)(id object, id target, NSDictionary *change);


@interface LCObserver : NSObject

+ (instancetype)observerForObject:(NSObject *)object;

@property (atomic, weak, readonly) NSObject *object;

- (void)addTarget:(NSObject *)target
       forKeyPath:(NSString *)keyPath
          options:(NSKeyValueObservingOptions)options
            block:(LCObserverBlock)block;

- (void)removeTarget:(NSObject *)target forKeyPath:(NSString *)keyPath;
- (void)removeTarget:(NSObject *)target;

@end


NS_INLINE
LCObserver *LCObserverMake(NSObject *object) {
    return [LCObserver observerForObject:object];
}
