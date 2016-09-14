//
//  MLPViewController.h
//  MLPAutoCompleteDemo
//
//  Created by Eddy Borja on 1/23/13.
//  Copyright (c) 2013 Mainloop. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLPAutoCompleteTextFieldDelegate.h"

@class DEMODataSource;
@class MLPAutoCompleteTextField;

typedef void (^LCCKClientIDHandler)(NSString *clientID);

@interface LCCKLoginViewController : UIViewController <UITextFieldDelegate, MLPAutoCompleteTextFieldDelegate>

@property (strong, nonatomic) IBOutlet DEMODataSource *autocompleteDataSource;
@property (weak) IBOutlet MLPAutoCompleteTextField *autocompleteTextField;
@property (strong, nonatomic) IBOutlet UILabel *demoTitle;
@property (strong, nonatomic) IBOutlet UILabel *author;
@property (nonatomic, assign, getter=isAutoLogin) BOOL autoLogin;

- (void)setClientIDHandler:(LCCKClientIDHandler)clientIDHandler;

@end
