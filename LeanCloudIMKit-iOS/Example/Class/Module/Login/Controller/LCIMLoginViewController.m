//
//  MLPViewController.m
//  MLPAutoCompleteDemo
//
//  Created by Eddy Borja on 1/23/13.
//  Copyright (c) 2013 Mainloop. All rights reserved.
//

#import "LCIMLoginViewController.h"
#import "MLPAutoCompleteTextField.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>
//#import "LCIMUserSys"
@implementation LCIMLoginViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.view setAlpha:0];
    [UIView animateWithDuration:0.2
                          delay:0.25
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self.view setAlpha:1.0];
                     }completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.autocompleteTextField setBorderStyle:UITextBorderStyleRoundedRect];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - MLPAutoCompleteTextField Delegate


- (BOOL)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
          shouldConfigureCell:(UITableViewCell *)cell
       withAutoCompleteString:(NSString *)autocompleteString
         withAttributedString:(NSAttributedString *)boldedString
        forAutoCompleteObject:(id<MLPAutoCompletionObject>)autocompleteObject
            forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    //This is your chance to customize an autocomplete tableview cell before it appears in the autocomplete tableview
    NSURL *avatorURL;
    for (NSDictionary *user in LCIMContactProfiles) {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), autocompleteString);
        if ([autocompleteString isEqualToString:user[LCIMProfileKeyPeerId]]) {
            avatorURL = [NSURL URLWithString:user[LCIMProfileKeyAvatarURL]];
        }
    }
   //TODO:
    UIImage *image = [UIImage imageNamed:@"Nepal"];
    [cell.imageView sd_setImageWithURL:avatorURL placeholderImage:image];
    return YES;
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
  didSelectAutoCompleteString:(NSString *)selectedString
       withAutoCompleteObject:(id<MLPAutoCompletionObject>)selectedObject
            forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(selectedObject){
        NSLog(@"selected object from autocomplete menu %@ with string %@", selectedObject, [selectedObject autocompleteString]);
    } else {
        NSLog(@"selected string '%@' from autocomplete menu", selectedString);
    }
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField willHideAutoCompleteTableView:(UITableView *)autoCompleteTableView {
    NSLog(@"Autocomplete table view will be removed from the view hierarchy");
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField willShowAutoCompleteTableView:(UITableView *)autoCompleteTableView {
    NSLog(@"Autocomplete table view will be added to the view hierarchy");
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField didHideAutoCompleteTableView:(UITableView *)autoCompleteTableView {
    NSLog(@"Autocomplete table view ws removed from the view hierarchy");
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField didShowAutoCompleteTableView:(UITableView *)autoCompleteTableView {
    NSLog(@"Autocomplete table view was added to the view hierarchy");
}

@end
