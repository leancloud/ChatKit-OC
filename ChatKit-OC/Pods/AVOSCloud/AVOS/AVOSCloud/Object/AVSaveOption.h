//
//  AVSaveOption.h
//  AVOS
//
//  Created by Tang Tianyong on 1/12/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVQuery;

NS_ASSUME_NONNULL_BEGIN

@interface AVSaveOption : NSObject

@property (nonatomic, assign) BOOL fetchWhenSave;
@property (nonatomic, strong, nullable) AVQuery *query;

@end

NS_ASSUME_NONNULL_END
