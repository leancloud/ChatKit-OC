//
//  LCURLConnection.h
//  AVOS
//
//  Created by Tang Tianyong on 12/10/15.
//  Copyright © 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCURLConnection : NSObject

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

@end
