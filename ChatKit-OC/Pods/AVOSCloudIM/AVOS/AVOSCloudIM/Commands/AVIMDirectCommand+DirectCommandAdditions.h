//
//  AVIMDirectCommand+DirectCommandAdditions.h
//  AVOS
//
//  Created by 陈宜龙 on 16/1/8.
//  Copyright © 2016年 LeanCloud Inc. All rights reserved.
//

#import "MessagesProtoOrig.pbobjc.h"
#import "AVIMMessage.h"

@interface AVIMDirectCommand (DirectCommandAdditions)

@property(nonatomic, strong) AVIMMessage *message;

@end
