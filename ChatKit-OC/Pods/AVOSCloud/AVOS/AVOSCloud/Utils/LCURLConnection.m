//
//  LCURLConnection.m
//  AVOS
//
//  Created by Tang Tianyong on 12/10/15.
//  Copyright © 2015 LeanCloud Inc. All rights reserved.
//

#import "LCURLConnection.h"

@implementation LCURLConnection

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse *__autoreleasing *)response error:(NSError *__autoreleasing *)error {
#if !TARGET_OS_WATCH
    return [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
#else
    __block NSData *data = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
        data = taskData;

        if (response)
            *response = taskResponse;

        if (error)
            *error = taskError;

        dispatch_semaphore_signal(semaphore);
    }] resume];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return data;
#endif
}

@end
