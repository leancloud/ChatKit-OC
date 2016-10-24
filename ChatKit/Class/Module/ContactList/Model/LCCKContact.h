//
//  LCCKContact.h
//  ChatKit
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/7/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKUserDelegate.h"

@interface LCCKContact : NSObject <LCCKUserDelegate>

@property (nonatomic, assign, getter = isChecked) BOOL checked;

@end
