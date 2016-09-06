/*
 //  MLPAutoCompleteTextField.h
 //
 //
 //  Created by Eddy Borja on 12/29/12.
 //  Copyright (c) 2013 Mainloop LLC. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#import <UIKit/UIKit.h>
#import "MLPAutoCompleteTextFieldDataSource.h"
#import "MLPAutoCompleteTextFieldDelegate.h"

@protocol MLPAutoCompleteSortOperationDelegate <NSObject>
- (void)autoCompleteTermsDidSort:(NSArray *)completions;
@end

@protocol MLPAutoCompleteFetchOperationDelegate <NSObject>
- (void)autoCompleteTermsDidFetch:(NSDictionary *)fetchInfo;
@end


@interface MLPAutoCompleteTextField : UITextField <UITableViewDataSource, UITableViewDelegate, MLPAutoCompleteSortOperationDelegate, MLPAutoCompleteFetchOperationDelegate>

@property (strong, readonly) UITableView *autoCompleteTableView;

@property (strong) IBOutlet id <MLPAutoCompleteTextFieldDataSource> autoCompleteDataSource;
@property (weak) IBOutlet id <MLPAutoCompleteTextFieldDelegate> autoCompleteDelegate;

@property (assign) NSTimeInterval autoCompleteFetchRequestDelay; //default is 0.1, if you fetch from a web service you may want this higher to prevent multiple calls happening very quickly.
@property (assign) BOOL sortAutoCompleteSuggestionsByClosestMatch;
@property (assign) BOOL applyBoldEffectToAutoCompleteSuggestions;
@property (assign) BOOL reverseAutoCompleteSuggestionsBoldEffect;
@property (assign) BOOL showTextFieldDropShadowWhenAutoCompleteTableIsOpen;
@property (assign) BOOL showAutoCompleteTableWhenEditingBegins; //only applies for drop down style autocomplete tables.
@property (assign) BOOL disableAutoCompleteTableUserInteractionWhileFetching;
@property (assign) BOOL autoCompleteTableAppearsAsKeyboardAccessory; //if set to TRUE, the autocomplete table will appear as a keyboard input accessory view rather than a drop down.


@property (assign) BOOL autoCompleteTableViewHidden;

@property (assign) CGFloat autoCompleteFontSize;
@property (strong) NSString *autoCompleteBoldFontName;
@property (strong) NSString *autoCompleteRegularFontName;

@property (assign) NSInteger maximumNumberOfAutoCompleteRows;
@property (assign) CGFloat autoCompleteRowHeight;
@property (assign) CGSize autoCompleteTableOriginOffset;
@property (assign) CGFloat autoCompleteTableCornerRadius; //only applies for drop down style autocomplete tables.
@property (nonatomic, assign) UIEdgeInsets autoCompleteContentInsets;
@property (nonatomic, assign) UIEdgeInsets autoCompleteScrollIndicatorInsets;
@property (nonatomic, strong) UIColor *autoCompleteTableBorderColor;
@property (nonatomic, assign) CGFloat autoCompleteTableBorderWidth;
@property (nonatomic, strong) UIColor *autoCompleteTableBackgroundColor;
@property (strong) UIColor *autoCompleteTableCellBackgroundColor;
@property (strong) UIColor *autoCompleteTableCellTextColor;


- (void)registerAutoCompleteCellNib:(UINib *)nib forCellReuseIdentifier:(NSString *)reuseIdentifier;

- (void)registerAutoCompleteCellClass:(Class)cellClass forCellReuseIdentifier:(NSString *)reuseIdentifier;

@end


