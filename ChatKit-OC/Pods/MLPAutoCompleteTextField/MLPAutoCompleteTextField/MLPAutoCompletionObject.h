/*
//  MLPAutoCompletionObject.h
//  
//
//  Created by Eddy Borja on 4/19/13.
//  Copyright (c) 2013 Mainloop LLC. All rights reserved.
//
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


#import <Foundation/Foundation.h>

/*
 In some cases you may want strings in an autocomplete menu to be associated to some kind of model object 
 (For example: a list of names may be
 associated with friend objects and you want to track which friend object a 
 user selects based on what name they choose from the autocomplete list.)
 
 In order to pass your model objects straight to the MLPAutoCompleteTextFieldDataSource's 
 autoCompleteTextField:possibleCompletionsForString: method, your model object must implement this protocol.
 */
@protocol MLPAutoCompletionObject <NSObject>
@required

/*Return the string that should be displayed in the autocomplete menu that 
 represents this object. (For example: a person's name.)*/
- (NSString *)autocompleteString;

@end
