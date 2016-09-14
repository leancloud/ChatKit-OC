/*
//  MLPAutoCompleteTextFieldDataSource.h
// 
//
//  Created by Eddy Borja on 12/29/12.
//  Copyright (c) 2013 Mainloop LLC. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <Foundation/Foundation.h>

@class MLPAutoCompleteTextField;
@protocol MLPAutoCompleteTextFieldDataSource <NSObject>


@optional
//One of these two methods must be implemented to fetch autocomplete terms.


/*
 When you have the suggestions ready you must call the completionHandler block with 
 an NSArray of strings or objects implementing the MLPAutoCompletionObject protocol that 
 could be used as possible completions for the given string in textField.
 */
- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
      possibleCompletionsForString:(NSString *)string
                 completionHandler:(void(^)(NSArray *suggestions))handler;



/*
 Like the above, this method should return an NSArray of strings or objects implementing the MLPAutoCompletionObject protocol
 that could be used as possible completions for the given string in textField.
This method will be called asynchronously, so an immediate return is not necessary.
 */
- (NSArray *)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
      possibleCompletionsForString:(NSString *)string;



@end
