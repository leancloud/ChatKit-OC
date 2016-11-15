//
//  LCCKWeakReference.h
//  Kuber
//
//  v0.8.2 Created by Kuber on 16/4/29.
//  Copyright © 2016年 Huaxu Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^LCCKWeakReference)(void);

LCCKWeakReference makeLCCKWeakReference(id object);

id weakReferenceNonretainedObjectValue(LCCKWeakReference ref);
