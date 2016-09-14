//
//  AVUploaderManager.h
//  IconMan
//
//  Created by Zhu Zeng on 3/16/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVOSCloud.h"

@interface AVUploaderManager : NSObject

@property (nonatomic, assign) AVStorageType storageType;
@property (nonatomic, assign) AVServiceRegion serviceRegion;

+(AVUploaderManager *)sharedInstance;
+ (NSString *)generateRandomString:(int)length;
+ (NSString *)generateQiniuKey;
-(void)cancelWithLocalPath:(NSString *)path;

- (void)uploadWithAVFile:(AVFile *)file progressBlock:(AVProgressBlock)progressBlock resultBlock:(AVBooleanResultBlock)resultBlock;

@end
