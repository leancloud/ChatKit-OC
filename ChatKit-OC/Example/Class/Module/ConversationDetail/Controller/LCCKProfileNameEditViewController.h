//
//  LCCKProfileNameEditViewController.h
//  ChatKit-OC
//
//  Created by 陈宜龙 on 12/14/16.
//  Copyright © 2016 ElonChan. All rights reserved.
//

#import <FXForms/FXForms.h>

@protocol LCCKProfileNameEditViewControllerDelegate <NSObject>

- (void)profileNameDidChanged:(NSString *)name;

@end

@interface LCCKProfileNameEditViewController : FXFormViewController

@property (nonatomic, copy) NSString *placeholderName;

@property (nonatomic, weak) id<LCCKProfileNameEditViewControllerDelegate> delegate;

@end
