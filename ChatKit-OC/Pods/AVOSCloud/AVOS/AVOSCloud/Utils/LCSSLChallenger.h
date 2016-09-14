//
//  LCSSLChallenger.h
//  AVOS
//
//  Created by Tang Tianyong on 6/30/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCSSLChallenger : NSObject

+ (instancetype)sharedInstance;

- (void)acceptChallenge:(NSURLAuthenticationChallenge *)challenge;

@end
