// LCCKMenuItem.h
//
// Copyright (c) 2012 Peter Steinberger (http://petersteinberger.com)
// This code is a part of http://pspdfkit.com and has been put under MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>

/**
    This subclass adds support for a block-based action on UIMenuItem.
    If you are as annoyed about the missing target/action pattern, you will love this.
 
    If you use LCCKMenuItem with the classic initWithTitle:selector initializer,
    this will work and be handled just like a UIMenuItem.
 */
@interface LCCKMenuItem : UIMenuItem

// Initialize LCCKMenuItem with a block.
- (id)initWithTitle:(NSString *)title block:(void(^)())block;

// Menu Item can be enabled/disabled. (disable simply hides it from the UIMenuController)
@property(nonatomic, assign, getter=isEnabled) BOOL enabled;

// Action block.
@property(nonatomic, copy) void(^block)();


/**
    Installs the menu handler. Needs to be called once per class.
    (A good place is the +load method)

    Following methods will be swizzled:
    - canBecomeFirstResponder (if object doesn't already return YES)
    - canPerformAction:withSender:
    - methodSignatureForSelector:
    - forwardInvocation:
    
    The original implementation will be called if the LCCKMenuItem selector is not detected.

    @parm object can be an instance or a class.
*/
+ (void)installMenuHandlerForObject:(id)object;

@end
