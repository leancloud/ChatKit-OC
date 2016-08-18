//
//  LCCKContact.h
//  ChatKit
//
//  v0.5.4 Created by 陈宜龙 on 16/7/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKUserDelegate.h"

@interface LCCKContact : NSObject <LCCKUserDelegate>

@property (nonatomic, assign, getter = isChecked) BOOL checked;

@end
