//
//  UIView+LCCKExtension.m
//  ChatKit
//
//  v0.8.5 Created by ElonChan on 16/6/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "UIView+LCCKExtension.h"

@implementation UIView (LCCKExtension)

- (NSMutableArray*)lcck_allSubViews {
    NSMutableArray *allSubViews = [[NSMutableArray alloc] init];
    [allSubViews addObject:self];
    for (UIView *subview in self.subviews) {
        [allSubViews addObjectsFromArray:(NSArray*)[subview lcck_allSubViews]];
    }
    return allSubViews;
}

- (void)lcck_logViewHierarchy:(LCCKViewActionBlock)viewActionBlcok {
    //view action block - freedom to the caller
    viewActionBlcok(self);
    for (UIView *subview in self.subviews) {
        [subview lcck_logViewHierarchy:viewActionBlcok];
    }
}

@end
