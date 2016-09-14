//
//  AVSaveOption.h
//  AVOS
//
//  Created by Tang Tianyong on 1/12/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVQuery;

@interface AVSaveOption : NSObject

@property (nonatomic, assign) BOOL     fetchWhenSave;
@property (nonatomic, strong) AVQuery *query;

@end
