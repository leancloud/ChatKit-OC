//
//  LCIMSessionService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMSessionService.h"
#import "LCIMServiceDefinition.h"

@interface LCIMSessionService()

@property (nonatomic, copy, readwrite) NSString *clientId;

@end
@implementation LCIMSessionService

- (void)openWithClientId:(NSString *)clientId callback:(LCIMBooleanResultBlock)callback {
    //TODO:
}

- (void)closeWithCallback:(LCIMBooleanResultBlock)callback {
    //TODO:
}
@end
