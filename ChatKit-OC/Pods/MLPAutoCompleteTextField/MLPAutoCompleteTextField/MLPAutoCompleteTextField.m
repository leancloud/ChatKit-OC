/*
 //  MLPAutoCompleteTextField.m
 //
 //
 //  Created by Eddy Borja on 12/29/12.
 //  Copyright (c) 2013 Mainloop LLC. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MLPAutoCompleteTextField.h"
#import "MLPAutoCompletionObject.h"
#import "NSString+Levenshtein.h"
#import <QuartzCore/QuartzCore.h>


static NSString *kSortInputStringKey = @"sortInputString";
static NSString *kSortEditDistancesKey = @"editDistances";
static NSString *kSortObjectKey = @"sortObject";
static NSString *kKeyboardAccessoryInputKeyPath = @"autoCompleteTableAppearsAsKeyboardAccessory";
const NSTimeInterval DefaultAutoCompleteRequestDelay = 0.1;

@interface MLPAutoCompleteSortOperation: NSOperation
@property (strong) NSString *incompleteString;
@property (strong) NSArray *possibleCompletions;
@property (strong) id <MLPAutoCompleteSortOperationDelegate> delegate;
@property (strong) NSDictionary *boldTextAttributes;
@property (strong) NSDictionary *regularTextAttributes;

- (id)initWithDelegate:(id<MLPAutoCompleteSortOperationDelegate>)aDelegate
      incompleteString:(NSString *)string
   possibleCompletions:(NSArray *)possibleStrings;

- (NSArray *)sortedCompletionsForString:(NSString *)inputString
                    withPossibleStrings:(NSArray *)possibleTerms;
@end

static NSString *kFetchedTermsKey = @"terms";
static NSString *kFetchedStringKey = @"fetchInputString";
@interface MLPAutoCompleteFetchOperation: NSOperation
@property (strong) NSString *incompleteString;
@property (strong) MLPAutoCompleteTextField *textField;
@property (strong) id <MLPAutoCompleteFetchOperationDelegate> delegate;
@property (strong) id <MLPAutoCompleteTextFieldDataSource> dataSource;

- (id)initWithDelegate:(id<MLPAutoCompleteFetchOperationDelegate>)aDelegate
 completionsDataSource:(id<MLPAutoCompleteTextFieldDataSource>)aDataSource
 autoCompleteTextField:(MLPAutoCompleteTextField *)aTextField;

@end


static NSString *kBorderStyleKeyPath = @"borderStyle";
static NSString *kAutoCompleteTableViewHiddenKeyPath = @"autoCompleteTableView.hidden";
static NSString *kBackgroundColorKeyPath = @"backgroundColor";
static NSString *kDefaultAutoCompleteCellIdentifier = @"_DefaultAutoCompleteCellIdentifier";
@interface MLPAutoCompleteTextField ()
@property (strong, readwrite) UITableView *autoCompleteTableView;
@property (strong) NSArray *autoCompleteSuggestions;
@property (strong) NSOperationQueue *autoCompleteSortQueue;
@property (strong) NSOperationQueue *autoCompleteFetchQueue;
@property (strong) NSString *reuseIdentifier;
@property (assign) CGColorRef originalShadowColor;
@property (assign) CGSize originalShadowOffset;
@property (assign) CGFloat originalShadowOpacity;
@end



@implementation MLPAutoCompleteTextField

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc
{
    [self closeAutoCompleteTableView];
    [self stopObservingKeyPathsAndNotifications];
}

- (void)initialize
{
    [self beginObservingKeyPathsAndNotifications];
    
    [self setDefaultValuesForVariables];
    
    UITableView *newTableView = [[self class] newAutoCompleteTableViewForTextField:self];
    [self setAutoCompleteTableView:newTableView];
    
    [self styleAutoCompleteTableForBorderStyle:self.borderStyle];
}


#pragma mark - Notifications and KVO

- (void)beginObservingKeyPathsAndNotifications
{
    [self addObserver:self
           forKeyPath:kBorderStyleKeyPath
              options:NSKeyValueObservingOptionNew context:nil];
    
    
    [self addObserver:self
           forKeyPath:kAutoCompleteTableViewHiddenKeyPath
              options:NSKeyValueObservingOptionNew context:nil];
    
    
    [self addObserver:self
           forKeyPath:kBackgroundColorKeyPath
              options:NSKeyValueObservingOptionNew context:nil];
    
    [self addObserver:self
           forKeyPath:kKeyboardAccessoryInputKeyPath
              options:NSKeyValueObservingOptionNew context:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChangeWithNotification:)
                                                 name:UITextFieldTextDidChangeNotification object:self];
}

- (void)stopObservingKeyPathsAndNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self removeObserver:self forKeyPath:kBorderStyleKeyPath];
    [self removeObserver:self forKeyPath:kAutoCompleteTableViewHiddenKeyPath];
    [self removeObserver:self forKeyPath:kBackgroundColorKeyPath];
    [self removeObserver:self forKeyPath:kKeyboardAccessoryInputKeyPath];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:kBorderStyleKeyPath]) {
        [self styleAutoCompleteTableForBorderStyle:self.borderStyle];
    } else if ([keyPath isEqualToString:kAutoCompleteTableViewHiddenKeyPath]) {
        if(self.autoCompleteTableView.hidden){
            [self closeAutoCompleteTableView];
        } else {
            [self.autoCompleteTableView reloadData];
        }
    } else if ([keyPath isEqualToString:kBackgroundColorKeyPath]){
        [self styleAutoCompleteTableForBorderStyle:self.borderStyle];
    } else if ([keyPath isEqualToString:kKeyboardAccessoryInputKeyPath]){
        if(self.autoCompleteTableAppearsAsKeyboardAccessory){
            [self setAutoCompleteTableForKeyboardAppearance];
        } else {
            [self setAutoCompleteTableForDropDownAppearance];
        }
    }
}

#pragma mark - TableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = [self.autoCompleteSuggestions count];
    [self expandAutoCompleteTableViewForNumberOfRows:numberOfRows];
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSString *cellIdentifier = kDefaultAutoCompleteCellIdentifier;
    
    if(!self.reuseIdentifier){
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [self autoCompleteTableViewCellWithReuseIdentifier:cellIdentifier];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier];
    }
    NSAssert(cell, @"Unable to create cell for autocomplete table");
    
    
    id autoCompleteObject = self.autoCompleteSuggestions[indexPath.row];
    NSString *suggestedString;
    if([autoCompleteObject isKindOfClass:[NSString class]]){
        suggestedString = (NSString *)autoCompleteObject;
    } else if ([autoCompleteObject conformsToProtocol:@protocol(MLPAutoCompletionObject)]){
        suggestedString = [(id <MLPAutoCompletionObject>)autoCompleteObject autocompleteString];
    } else {
        NSAssert(0, @"Autocomplete suggestions must either be NSString or objects conforming to the MLPAutoCompletionObject protocol.");
    }
    
    
    [self configureCell:cell atIndexPath:indexPath withAutoCompleteString:suggestedString];
    
    
    return cell;
}

- (UITableViewCell *)autoCompleteTableViewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:identifier];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.textLabel setTextColor:self.textColor];
    [cell.textLabel setFont:self.font];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell
          atIndexPath:(NSIndexPath *)indexPath
withAutoCompleteString:(NSString *)string
{
    
    NSAttributedString *boldedString = nil;
    if(self.applyBoldEffectToAutoCompleteSuggestions){
        BOOL attributedTextSupport = [cell.textLabel respondsToSelector:@selector(setAttributedText:)];
        NSAssert(attributedTextSupport, @"Attributed strings on UILabels are  not supported before iOS 6.0");
        NSRange boldedRange = [[string lowercaseString]
                               rangeOfString:[self.text lowercaseString]];
        boldedString = [self boldedString:string withRange:boldedRange];
    }
    
    id autoCompleteObject = self.autoCompleteSuggestions[indexPath.row];
    if(![autoCompleteObject conformsToProtocol:@protocol(MLPAutoCompletionObject)]){
        autoCompleteObject = nil;
    }
    
    if([self.autoCompleteDelegate respondsToSelector:@selector(autoCompleteTextField:shouldConfigureCell:withAutoCompleteString:withAttributedString:forAutoCompleteObject:forRowAtIndexPath:)])
    {
        if(![self.autoCompleteDelegate autoCompleteTextField:self shouldConfigureCell:cell withAutoCompleteString:string withAttributedString:boldedString forAutoCompleteObject:autoCompleteObject forRowAtIndexPath:indexPath])
        {
            return;
        }
    }
    
    [cell.textLabel setTextColor:self.textColor];
    
    if(boldedString){
        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)]) {
            [cell.textLabel setAttributedText:boldedString];
        } else{
            [cell.textLabel setText:string];
            [cell.textLabel setFont:[UIFont fontWithName:self.font.fontName size:self.autoCompleteFontSize]];
        }
    
    } else {
        [cell.textLabel setText:string];
        [cell.textLabel setFont:[UIFont fontWithName:self.font.fontName size:self.autoCompleteFontSize]];
    }
    
    if(self.autoCompleteTableCellTextColor){
        [cell.textLabel setTextColor:self.autoCompleteTableCellTextColor];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:self.autoCompleteTableCellBackgroundColor];
}

#pragma mark - TableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.autoCompleteRowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!self.autoCompleteTableAppearsAsKeyboardAccessory){
        [self closeAutoCompleteTableView];
    }
    
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *autoCompleteString = selectedCell.textLabel.text;
    self.text = autoCompleteString;
    
    id<MLPAutoCompletionObject> autoCompleteObject = self.autoCompleteSuggestions[indexPath.row];
    if(![autoCompleteObject conformsToProtocol:@protocol(MLPAutoCompletionObject)]){
        autoCompleteObject = nil;
    }
    
    if([self.autoCompleteDelegate respondsToSelector:
        @selector(autoCompleteTextField:didSelectAutoCompleteString:withAutoCompleteObject:forRowAtIndexPath:)]){
        
        [self.autoCompleteDelegate autoCompleteTextField:self
                             didSelectAutoCompleteString:autoCompleteString
                                  withAutoCompleteObject:autoCompleteObject
                                       forRowAtIndexPath:indexPath];
    }
    
    [self finishedSearching];
}

#pragma mark - AutoComplete Sort Operation Delegate


- (void)autoCompleteTermsDidSort:(NSArray *)completions
{
    [self setAutoCompleteSuggestions:completions];
    [self.autoCompleteTableView reloadData];
}

#pragma mark - AutoComplete Fetch Operation Delegate

- (void)autoCompleteTermsDidFetch:(NSDictionary *)fetchInfo
{
    NSString *inputString = fetchInfo[kFetchedStringKey];
    NSArray *completions = fetchInfo[kFetchedTermsKey];
    
    [self.autoCompleteSortQueue cancelAllOperations];
    
    if(self.sortAutoCompleteSuggestionsByClosestMatch){
        MLPAutoCompleteSortOperation *operation =
        [[MLPAutoCompleteSortOperation alloc] initWithDelegate:self
                                              incompleteString:inputString
                                           possibleCompletions:completions];
        [self.autoCompleteSortQueue addOperation:operation];
    } else {
        [self autoCompleteTermsDidSort:completions];
    }
}

#pragma mark - Events

- (void)textFieldDidChangeWithNotification:(NSNotification *)aNotification
{
    if(aNotification.object == self){
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(fetchAutoCompleteSuggestions)
                                                   object:nil];
        
        [self performSelector:@selector(fetchAutoCompleteSuggestions)
                   withObject:nil
                   afterDelay:self.autoCompleteFetchRequestDelay];
    }
}

- (BOOL)becomeFirstResponder
{
    [self saveCurrentShadowProperties];
    
    if(self.showAutoCompleteTableWhenEditingBegins ||
       self.autoCompleteTableAppearsAsKeyboardAccessory){
        [self fetchAutoCompleteSuggestions];
    }
    
    return [super becomeFirstResponder];
}

- (void) finishedSearching
{
    [self resignFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [self restoreOriginalShadowProperties];
    if(!self.autoCompleteTableAppearsAsKeyboardAccessory){
        [self closeAutoCompleteTableView];
    }
    return [super resignFirstResponder];
}



#pragma mark - Open/Close Actions

- (void)expandAutoCompleteTableViewForNumberOfRows:(NSInteger)numberOfRows
{
    NSAssert(numberOfRows >= 0,
             @"Number of rows given for auto complete table was negative, this is impossible.");
    
    if(!self.isFirstResponder){
        return;
    }
    
    if(self.autoCompleteTableAppearsAsKeyboardAccessory){
        [self expandKeyboardAutoCompleteTableForNumberOfRows:numberOfRows];
    } else {
        [self expandDropDownAutoCompleteTableForNumberOfRows:numberOfRows];
    }
    
}

- (void)expandKeyboardAutoCompleteTableForNumberOfRows:(NSInteger)numberOfRows
{
    if(numberOfRows && (self.autoCompleteTableViewHidden == NO)){
        [self.autoCompleteTableView setAlpha:1];
    } else {
        [self.autoCompleteTableView setAlpha:0];
    }
}

- (void)expandDropDownAutoCompleteTableForNumberOfRows:(NSInteger)numberOfRows
{
    [self resetDropDownAutoCompleteTableFrameForNumberOfRows:numberOfRows];
    
    
    if(numberOfRows && (self.autoCompleteTableViewHidden == NO)){
        [self.autoCompleteTableView setAlpha:1];
        
        if(!self.autoCompleteTableView.superview){
            if([self.autoCompleteDelegate
                respondsToSelector:@selector(autoCompleteTextField:willShowAutoCompleteTableView:)]){
                [self.autoCompleteDelegate autoCompleteTextField:self
                                   willShowAutoCompleteTableView:self.autoCompleteTableView];
            }
        }
        
        [self.superview bringSubviewToFront:self];
        [self.superview insertSubview:self.autoCompleteTableView
                         belowSubview:self];
        [self.autoCompleteTableView setUserInteractionEnabled:YES];
        if(self.showTextFieldDropShadowWhenAutoCompleteTableIsOpen){
            [self.layer setShadowColor:[[UIColor blackColor] CGColor]];
            [self.layer setShadowOffset:CGSizeMake(0, 1)];
            [self.layer setShadowOpacity:0.35];
        }
    } else {
        [self closeAutoCompleteTableView];
        [self restoreOriginalShadowProperties];
        [self.autoCompleteTableView.layer setShadowOpacity:0.0];
    }
}


- (void)closeAutoCompleteTableView
{
    [self.autoCompleteTableView removeFromSuperview];
    [self restoreOriginalShadowProperties];
}


#pragma mark - Setters



- (void)setDefaultValuesForVariables
{
    [self setClipsToBounds:NO];
    [self setAutoCompleteFetchRequestDelay:DefaultAutoCompleteRequestDelay];
    [self setSortAutoCompleteSuggestionsByClosestMatch:YES];
    [self setApplyBoldEffectToAutoCompleteSuggestions:YES];
    [self setShowTextFieldDropShadowWhenAutoCompleteTableIsOpen:YES];
    [self setAutoCompleteRowHeight:40];
    [self setAutoCompleteFontSize:13];
    [self setMaximumNumberOfAutoCompleteRows:3];
    
    [self setAutoCompleteTableCellBackgroundColor:[UIColor clearColor]];
    
    UIFont *regularFont = [UIFont systemFontOfSize:13];
    [self setAutoCompleteRegularFontName:regularFont.fontName];
    
    UIFont *boldFont = [UIFont boldSystemFontOfSize:13];
    [self setAutoCompleteBoldFontName:boldFont.fontName];
    
    [self setAutoCompleteSuggestions:[NSMutableArray array]];
    
    [self setAutoCompleteSortQueue:[NSOperationQueue new]];
    self.autoCompleteSortQueue.name = [NSString stringWithFormat:@"Autocomplete Queue %i", arc4random()];
    
    [self setAutoCompleteFetchQueue:[NSOperationQueue new]];
    self.autoCompleteFetchQueue.name = [NSString stringWithFormat:@"Fetch Queue %i", arc4random()];
}


- (void)setAutoCompleteTableForKeyboardAppearance
{
    [self resetKeyboardAutoCompleteTableFrameForNumberOfRows:self.maximumNumberOfAutoCompleteRows];
    [self.autoCompleteTableView setContentInset:UIEdgeInsetsZero];
    [self.autoCompleteTableView setScrollIndicatorInsets:UIEdgeInsetsZero];
    [self setInputAccessoryView:self.autoCompleteTableView];
}

- (void)setAutoCompleteTableForDropDownAppearance
{
    [self resetDropDownAutoCompleteTableFrameForNumberOfRows:self.maximumNumberOfAutoCompleteRows];
    [self.autoCompleteTableView setContentInset:self.autoCompleteContentInsets];
    [self.autoCompleteTableView setScrollIndicatorInsets:self.autoCompleteScrollIndicatorInsets];
    [self setInputAccessoryView:nil];
}



- (void)setAutoCompleteTableViewHidden:(BOOL)autoCompleteTableViewHidden
{
    [self.autoCompleteTableView setHidden:autoCompleteTableViewHidden];
}

- (void)setAutoCompleteTableBackgroundColor:(UIColor *)autoCompleteTableBackgroundColor
{
    [self.autoCompleteTableView setBackgroundColor:autoCompleteTableBackgroundColor];
    _autoCompleteTableBackgroundColor = autoCompleteTableBackgroundColor;
}

- (void)setAutoCompleteTableBorderWidth:(CGFloat)autoCompleteTableBorderWidth
{
    [self.autoCompleteTableView.layer setBorderWidth:autoCompleteTableBorderWidth];
    _autoCompleteTableBorderWidth = autoCompleteTableBorderWidth;
}

- (void)setAutoCompleteTableBorderColor:(UIColor *)autoCompleteTableBorderColor
{
    [self.autoCompleteTableView.layer setBorderColor:[autoCompleteTableBorderColor CGColor]];
    _autoCompleteTableBorderColor = autoCompleteTableBorderColor;
}

- (void)setAutoCompleteContentInsets:(UIEdgeInsets)autoCompleteContentInsets
{
    [self.autoCompleteTableView setContentInset:autoCompleteContentInsets];
    _autoCompleteContentInsets = autoCompleteContentInsets;
}

- (void)setAutoCompleteScrollIndicatorInsets:(UIEdgeInsets)autoCompleteScrollIndicatorInsets
{
    [self.autoCompleteTableView setScrollIndicatorInsets:autoCompleteScrollIndicatorInsets];
    _autoCompleteScrollIndicatorInsets = autoCompleteScrollIndicatorInsets;
}

- (void)resetKeyboardAutoCompleteTableFrameForNumberOfRows:(NSInteger)numberOfRows
{
    [self.autoCompleteTableView.layer setCornerRadius:0];
    
    CGRect newAutoCompleteTableViewFrame = [[self class]
                                            autoCompleteTableViewFrameForTextField:self
                                            forNumberOfRows:numberOfRows];
    [self.autoCompleteTableView setFrame:newAutoCompleteTableViewFrame];
    
    [self.autoCompleteTableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.autoCompleteTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)resetDropDownAutoCompleteTableFrameForNumberOfRows:(NSInteger)numberOfRows
{
    [self.autoCompleteTableView.layer setCornerRadius:self.autoCompleteTableCornerRadius];
    
    CGRect newAutoCompleteTableViewFrame = [[self class]
                                            autoCompleteTableViewFrameForTextField:self
                                            forNumberOfRows:numberOfRows];
    
    [self.autoCompleteTableView setFrame:newAutoCompleteTableViewFrame];
    [self.autoCompleteTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)registerAutoCompleteCellNib:(UINib *)nib forCellReuseIdentifier:(NSString *)reuseIdentifier
{
    NSAssert(self.autoCompleteTableView, @"Must have an autoCompleteTableView to register cells to.");
    
    if(self.reuseIdentifier){
        [self unregisterAutoCompleteCellForReuseIdentifier:self.reuseIdentifier];
    }
    
    [self.autoCompleteTableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
    [self setReuseIdentifier:reuseIdentifier];
}


- (void)registerAutoCompleteCellClass:(Class)cellClass forCellReuseIdentifier:(NSString *)reuseIdentifier
{
    NSAssert(self.autoCompleteTableView, @"Must have an autoCompleteTableView to register cells to.");
    if(self.reuseIdentifier){
        [self unregisterAutoCompleteCellForReuseIdentifier:self.reuseIdentifier];
    }
    BOOL classSettingSupported = [self.autoCompleteTableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)];
    NSAssert(classSettingSupported, @"Unable to set class for cell for autocomplete table, in iOS 5.0 you can set a custom NIB for a reuse identifier to get similar functionality.");
    [self.autoCompleteTableView registerClass:cellClass forCellReuseIdentifier:reuseIdentifier];
    [self setReuseIdentifier:reuseIdentifier];
}


- (void)unregisterAutoCompleteCellForReuseIdentifier:(NSString *)reuseIdentifier
{
    [self.autoCompleteTableView registerNib:nil forCellReuseIdentifier:reuseIdentifier];
}


- (void)styleAutoCompleteTableForBorderStyle:(UITextBorderStyle)borderStyle
{
    if([self.autoCompleteDelegate respondsToSelector:@selector(autoCompleteTextField:shouldStyleAutoCompleteTableView:forBorderStyle:)]){
        if(![self.autoCompleteDelegate autoCompleteTextField:self
                            shouldStyleAutoCompleteTableView:self.autoCompleteTableView
                                              forBorderStyle:borderStyle]){
            return;
        }
    }
    
    switch (borderStyle) {
        case UITextBorderStyleRoundedRect:
            [self setRoundedRectStyleForAutoCompleteTableView];
            break;
        case UITextBorderStyleBezel:
        case UITextBorderStyleLine:
            [self setLineStyleForAutoCompleteTableView];
            break;
        case UITextBorderStyleNone:
            [self setNoneStyleForAutoCompleteTableView];
            break;
        default:
            break;
    }
}

- (void)setRoundedRectStyleForAutoCompleteTableView
{
    [self setAutoCompleteTableCornerRadius:8.0];
    [self setAutoCompleteTableOriginOffset:CGSizeMake(0, -18)];
    [self setAutoCompleteScrollIndicatorInsets:UIEdgeInsetsMake(18, 0, 0, 0)];
    [self setAutoCompleteContentInsets:UIEdgeInsetsMake(18, 0, 0, 0)];
    [self setAutoCompleteTableBorderWidth:1.0];
    [self setAutoCompleteTableBorderColor:[UIColor colorWithWhite:0.0 alpha:0.25]];
    
    if(self.backgroundColor == [UIColor clearColor]){
        [self setAutoCompleteTableBackgroundColor:[UIColor whiteColor]];
    } else {
        [self setAutoCompleteTableBackgroundColor:self.backgroundColor];
    }
}

- (void)setLineStyleForAutoCompleteTableView
{
    [self setAutoCompleteTableCornerRadius:0.0];
    [self setAutoCompleteTableOriginOffset:CGSizeZero];
    [self setAutoCompleteScrollIndicatorInsets:UIEdgeInsetsZero];
    [self setAutoCompleteContentInsets:UIEdgeInsetsZero];
    [self setAutoCompleteTableBorderWidth:1.0];
    [self setAutoCompleteTableBorderColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    
    if(self.backgroundColor == [UIColor clearColor]){
        [self setAutoCompleteTableBackgroundColor:[UIColor whiteColor]];
    } else {
        [self setAutoCompleteTableBackgroundColor:self.backgroundColor];
    }
}

- (void)setNoneStyleForAutoCompleteTableView
{
    [self setAutoCompleteTableCornerRadius:8.0];
    [self setAutoCompleteTableOriginOffset:CGSizeMake(0, 7)];
    [self setAutoCompleteScrollIndicatorInsets:UIEdgeInsetsZero];
    [self setAutoCompleteContentInsets:UIEdgeInsetsZero];
    [self setAutoCompleteTableBorderWidth:1.0];
    
    
    UIColor *lightBlueColor = [UIColor colorWithRed:181/255.0
                                              green:204/255.0
                                               blue:255/255.0
                                              alpha:1.0];
    [self setAutoCompleteTableBorderColor:lightBlueColor];
    
    
    UIColor *blueTextColor = [UIColor colorWithRed:23/255.0
                                             green:119/255.0
                                              blue:206/255.0
                                             alpha:1.0];
    [self setAutoCompleteTableCellTextColor:blueTextColor];
    
    if(self.backgroundColor == [UIColor clearColor]){
        [self setAutoCompleteTableBackgroundColor:[UIColor whiteColor]];
    } else {
        [self setAutoCompleteTableBackgroundColor:self.backgroundColor];
    }
}

- (void)saveCurrentShadowProperties
{
    [self setOriginalShadowColor:self.layer.shadowColor];
    [self setOriginalShadowOffset:self.layer.shadowOffset];
    [self setOriginalShadowOpacity:self.layer.shadowOpacity];
}

- (void)restoreOriginalShadowProperties
{
    [self.layer setShadowColor:self.originalShadowColor];
    [self.layer setShadowOffset:self.originalShadowOffset];
    [self.layer setShadowOpacity:self.originalShadowOpacity];
}


#pragma mark - Getters

- (BOOL)autoCompleteTableViewHidden
{
    return self.autoCompleteTableView.hidden;
}


- (void)fetchAutoCompleteSuggestions
{
    
    if(self.disableAutoCompleteTableUserInteractionWhileFetching){
        [self.autoCompleteTableView setUserInteractionEnabled:NO];
    }
    
    [self.autoCompleteFetchQueue cancelAllOperations];
    
    MLPAutoCompleteFetchOperation *fetchOperation = [[MLPAutoCompleteFetchOperation alloc]
                                                        initWithDelegate:self
                                                        completionsDataSource:self.autoCompleteDataSource
                                                        autoCompleteTextField:self];
    
    [self.autoCompleteFetchQueue addOperation:fetchOperation];
}



#pragma mark - Factory Methods

+ (UITableView *)newAutoCompleteTableViewForTextField:(MLPAutoCompleteTextField *)textField
{
    CGRect dropDownTableFrame = [[self class] autoCompleteTableViewFrameForTextField:textField];
    
    UITableView *newTableView = [[UITableView alloc] initWithFrame:dropDownTableFrame
                                                             style:UITableViewStylePlain];
    [newTableView setDelegate:textField];
    [newTableView setDataSource:textField];
    [newTableView setScrollEnabled:YES];
    [newTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    return newTableView;
}

+ (CGRect)autoCompleteTableViewFrameForTextField:(MLPAutoCompleteTextField *)textField
                                 forNumberOfRows:(NSInteger)numberOfRows
{
    CGRect newTableViewFrame = [[self class] autoCompleteTableViewFrameForTextField:textField];
    
    CGFloat height = [[self class] autoCompleteTableHeightForTextField:textField
                                                      withNumberOfRows:numberOfRows];
    newTableViewFrame.size.height = height;
    
    if(!textField.autoCompleteTableAppearsAsKeyboardAccessory){
        newTableViewFrame.size.height += textField.autoCompleteTableView.contentInset.top;
    }
    
    return newTableViewFrame;
}

+ (CGFloat)autoCompleteTableHeightForTextField:(MLPAutoCompleteTextField *)textField
                              withNumberOfRows:(NSInteger)numberOfRows
{
    CGFloat maximumHeightMultiplier = (textField.maximumNumberOfAutoCompleteRows - 0.5);
    CGFloat heightMultiplier;
    if(numberOfRows >= textField.maximumNumberOfAutoCompleteRows){
        heightMultiplier = maximumHeightMultiplier;
    } else {
        heightMultiplier = numberOfRows;
    }
    
    CGFloat height = textField.autoCompleteRowHeight * heightMultiplier;
    return height;
}

+ (CGRect)autoCompleteTableViewFrameForTextField:(MLPAutoCompleteTextField *)textField
{
    CGRect frame = textField.frame;
    frame.origin.y += textField.frame.size.height;
    frame.origin.x += textField.autoCompleteTableOriginOffset.width;
    frame.origin.y += textField.autoCompleteTableOriginOffset.height;
    frame = CGRectInset(frame, 1, 0);
    
    return frame;
}

- (NSAttributedString *)boldedString:(NSString *)string withRange:(NSRange)boldRange
{
    UIFont *boldFont = [UIFont fontWithName:self.autoCompleteBoldFontName
                                       size:self.autoCompleteFontSize];
    UIFont *regularFont = [UIFont fontWithName:self.autoCompleteRegularFontName
                                          size:self.autoCompleteFontSize];
    
    NSDictionary *boldTextAttributes = @{NSFontAttributeName : boldFont};
    NSDictionary *regularTextAttributes = @{NSFontAttributeName : regularFont};
    NSDictionary *firstAttributes;
    NSDictionary *secondAttributes;
    
    if(self.reverseAutoCompleteSuggestionsBoldEffect){
        firstAttributes = regularTextAttributes;
        secondAttributes = boldTextAttributes;
    } else {
        firstAttributes = boldTextAttributes;
        secondAttributes = regularTextAttributes;
    }
    
    NSMutableAttributedString *attributedText =
    [[NSMutableAttributedString alloc] initWithString:string
                                           attributes:firstAttributes];
    [attributedText setAttributes:secondAttributes range:boldRange];
    
    return attributedText;
}


@end







#pragma mark -
#pragma mark - MLPAutoCompleteFetchOperation
@implementation MLPAutoCompleteFetchOperation

- (void)main
{
    @autoreleasepool {
        
        if (self.isCancelled){
            return;
        }
        

        if([self.dataSource respondsToSelector:@selector(autoCompleteTextField:possibleCompletionsForString:completionHandler:)]){
            
            __block BOOL waitingForSuggestions = YES;
            __weak MLPAutoCompleteFetchOperation *operation = self;
            [self.dataSource autoCompleteTextField:self.textField
                      possibleCompletionsForString:self.incompleteString
                                 completionHandler:^(NSArray *suggestions){
                                     
                                    [operation performSelector:@selector(didReceiveSuggestions:) withObject:suggestions];
                                    waitingForSuggestions = NO;
                                 }];
            
            while(waitingForSuggestions){
                if(self.isCancelled){
                    return;
                }
            }
            
        } else if ([self.dataSource respondsToSelector:@selector(autoCompleteTextField:possibleCompletionsForString:)]){
            
            NSArray *results = [self.dataSource autoCompleteTextField:self.textField
                                possibleCompletionsForString:self.incompleteString];
            
            if(!self.isCancelled){
                [self didReceiveSuggestions:results];
            }
            
        } else {
            NSAssert(0, @"An autocomplete datasource must implement either autoCompleteTextField:possibleCompletionsForString: or autoCompleteTextField:possibleCompletionsForString:completionHandler:");
        }
        
    }
}

- (void)didReceiveSuggestions:(NSArray *)suggestions
{
    if(!self.isCancelled){
        
        if(suggestions.count){
            NSObject *firstObject = suggestions[0];
            NSAssert([firstObject isKindOfClass:[NSString class]] ||
                     [firstObject conformsToProtocol:@protocol(MLPAutoCompletionObject)],
                     @"MLPAutoCompleteTextField expects an array with objects that are either strings or conform to the MLPAutoCompletionObject protocol for possible completions.");
        }
        
        NSDictionary *resultsInfo = @{kFetchedTermsKey: suggestions,
                                      kFetchedStringKey : self.incompleteString};
        [(NSObject *)self.delegate
         performSelectorOnMainThread:@selector(autoCompleteTermsDidFetch:)
         withObject:resultsInfo
         waitUntilDone:NO];
    };
}

- (id)initWithDelegate:(id<MLPAutoCompleteFetchOperationDelegate>)aDelegate
 completionsDataSource:(id<MLPAutoCompleteTextFieldDataSource>)aDataSource
 autoCompleteTextField:(MLPAutoCompleteTextField *)aTextField
{
    self = [super init];
    if (self) {
        [self setDelegate:aDelegate];
        [self setTextField:aTextField];
        [self setDataSource:aDataSource];
        [self setIncompleteString:aTextField.text];
        
        if(!self.incompleteString){
            self.incompleteString = @"";
        }
    }
    return self;
}

- (void)dealloc
{
    [self setDelegate:nil];
    [self setTextField:nil];
    [self setDataSource:nil];
    [self setIncompleteString:nil];
}
@end





#pragma mark -
#pragma mark - MLPAutoCompleteSortOperation

@implementation MLPAutoCompleteSortOperation

- (void)main
{
    @autoreleasepool {
        
        if (self.isCancelled){
            return;
        }
        
        NSArray *results = [self sortedCompletionsForString:self.incompleteString
                                        withPossibleStrings:self.possibleCompletions];
        
        if (self.isCancelled){
            return;
        }
        
        if(!self.isCancelled){
            [(NSObject *)self.delegate
             performSelectorOnMainThread:@selector(autoCompleteTermsDidSort:)
             withObject:results
             waitUntilDone:NO];
        }
    }
}

- (id)initWithDelegate:(id<MLPAutoCompleteSortOperationDelegate>)aDelegate
      incompleteString:(NSString *)string
   possibleCompletions:(NSArray *)possibleStrings
{
    self = [super init];
    if (self) {
        [self setDelegate:aDelegate];
        [self setIncompleteString:string];
        [self setPossibleCompletions:possibleStrings];
    }
    return self;
}

- (NSArray *)sortedCompletionsForString:(NSString *)inputString withPossibleStrings:(NSArray *)possibleTerms
{
    if([inputString isEqualToString:@""]){
        return possibleTerms;
    }
    
    if(self.isCancelled){
        return [NSArray array];
    }
    
    NSMutableArray *editDistances = [NSMutableArray arrayWithCapacity:possibleTerms.count];
    
    
    for(NSObject *originalObject in possibleTerms) {
        
        NSString *currentString;
        if([originalObject isKindOfClass:[NSString class]]){
            currentString = (NSString *)originalObject;
        } else if ([originalObject conformsToProtocol:@protocol(MLPAutoCompletionObject)]){
            currentString = [(id <MLPAutoCompletionObject>)originalObject autocompleteString];
        } else {
            NSAssert(0, @"Autocompletion terms must either be strings or objects conforming to the MLPAutoCompleteObject protocol.");
        }
        
        if(self.isCancelled){
            return [NSArray array];
        }
        
        NSUInteger maximumRange = (inputString.length < currentString.length) ? inputString.length : currentString.length;
        float editDistanceOfCurrentString = [inputString asciiLevenshteinDistanceWithString:[currentString substringWithRange:NSMakeRange(0, maximumRange)]];
        
        NSDictionary * stringsWithEditDistances = @{kSortInputStringKey : currentString ,
                                                         kSortObjectKey : originalObject,
                                                  kSortEditDistancesKey : [NSNumber numberWithFloat:editDistanceOfCurrentString]};
        [editDistances addObject:stringsWithEditDistances];
    }
    
    if(self.isCancelled){
        return [NSArray array];
    }
    
    [editDistances sortUsingComparator:^(NSDictionary *string1Dictionary,
                                         NSDictionary *string2Dictionary){
        
        return [string1Dictionary[kSortEditDistancesKey]
                compare:string2Dictionary[kSortEditDistancesKey]];
        
    }];
    
    
    
    NSMutableArray *prioritySuggestions = [NSMutableArray array];
    NSMutableArray *otherSuggestions = [NSMutableArray array];
    for(NSDictionary *stringsWithEditDistances in editDistances){
        
        if(self.isCancelled){
            return [NSArray array];
        }
        
        NSObject *autoCompleteObject = stringsWithEditDistances[kSortObjectKey];
        NSString *suggestedString = stringsWithEditDistances[kSortInputStringKey];
    
        NSArray *suggestedStringComponents = [suggestedString componentsSeparatedByString:@" "];
        BOOL suggestedStringDeservesPriority = NO;
        for(NSString *component in suggestedStringComponents){
            NSRange occurrenceOfInputString = [[component lowercaseString]
                                            rangeOfString:[inputString lowercaseString]];
            
            if (occurrenceOfInputString.length != 0 && occurrenceOfInputString.location == 0) {
                suggestedStringDeservesPriority = YES;
                [prioritySuggestions addObject:autoCompleteObject];
                break;
            }
    
            if([inputString length] <= 1){
                //if the input string is very short, don't check anymore components of the input string.
                break;
            }
        }
        
        if(!suggestedStringDeservesPriority){
            [otherSuggestions addObject:autoCompleteObject];
        }

    }
    
    NSMutableArray *results = [NSMutableArray array];
    [results addObjectsFromArray:prioritySuggestions];
    [results addObjectsFromArray:otherSuggestions];
    
    
    return [NSArray arrayWithArray:results];
}

- (void)dealloc
{
    [self setDelegate:nil];
    [self setIncompleteString:nil];
    [self setPossibleCompletions:nil];
}
@end

