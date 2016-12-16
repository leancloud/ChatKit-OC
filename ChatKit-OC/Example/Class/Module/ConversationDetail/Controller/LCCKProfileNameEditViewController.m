//
//  LCCKProfileNameEditViewController.m
//  ChatKit-OC
//
//  Created by 陈宜龙 on 12/14/16.
//  Copyright © 2016 ElonChan. All rights reserved.
//

#import "LCCKProfileNameEditViewController.h"
#import "UIColor+LCCKExtension.h"

@interface LCCKNameForm : NSObject<FXForm>

@property (nonatomic, strong) NSString *name;

@end

@implementation LCCKNameForm

- (NSArray *)fields {
    return @[@{
                 FXFormFieldKey : @"name",
                 FXFormFieldTitle : @"群聊名称"
            }];
}

- (NSArray *)extraFields {
    return @[@{
                 FXFormFieldTitle : @"保存",
                 FXFormFieldHeader : @"",
                 FXFormFieldAction : @"onSaveCellClick:"
            }];
}

@end

@implementation LCCKProfileNameEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor lcck_colorGrayBG]];
    LCCKNameForm *nameForm = [[LCCKNameForm alloc] init];
    nameForm.name = self.placeholderName;
    self.formController.form = nameForm;
}

- (void)onSaveCellClick:(UITableViewCell <FXFormFieldCell> *)sender {
    LCCKNameForm *nameForm = sender.field.form;
    if ([nameForm.name isEqualToString:self.placeholderName]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    if (nameForm.name.length > 0) {
        [self.navigationController popViewControllerAnimated:YES];
        if ([self.delegate respondsToSelector:@selector(profileNameDidChanged:)]) {
            [self.delegate profileNameDidChanged:nameForm.name];
        }
        return;
    }
}

@end
