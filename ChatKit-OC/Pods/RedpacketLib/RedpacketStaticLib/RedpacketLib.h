//
//  RedpacketLib.h
//  RedpacketLib
//
//  Created by Mr.Yang on 16/9/20.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#ifndef RedpacketLib_h
#define RedpacketLib_h

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import "YZHRedpacketBridge.h"
#import "YZHRedpacketBridgeProtocol.h"
#import "RedpacketOpenConst.h"
#import "RedpacketMessageModel.h"
#import "RedpacketErrorCode.h"
#import "RedpacketViewControl.h"

#else
#import <RedpacketLib/YZHRedpacketBridge.h>
#import <RedpacketLib/YZHRedpacketBridgeProtocol.h>
#import <RedpacketLib/RedpacketOpenConst.h>
#import <RedpacketLib/RedpacketMessageModel.h>
#import <RedpacketLib/RedpacketErrorCode.h>
#import <RedpacketLib/RedpacketViewControl.h>

#endif

#endif /* RedpacketLib_h */
