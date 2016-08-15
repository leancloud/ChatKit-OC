//
//  LCCKLoginDataSource.m
//  MLPAutoCompleteDemo
//
//  Created by Eddy Borja on 5/28/14.
//  Copyright (c) 2014 Mainloop. All rights reserved.
//

#import "LCCKLoginDataSource.h"
#import "LCCKExampleConstants.h"

@interface LCCKLoginDataSource ()

@property (strong, nonatomic) NSArray *countryObjects;

@end


@implementation LCCKLoginDataSource


#pragma mark - MLPAutoCompleteTextField DataSource

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
 possibleCompletionsForString:(NSString *)string
            completionHandler:(void (^)(NSArray *))handler {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        if(self.simulateLatency){
            CGFloat seconds = arc4random_uniform(4)+arc4random_uniform(4); //normal distribution
            NSLog(@"sleeping fetch of completions for %f", seconds);
            sleep(seconds);
        }
        
        NSArray *completions = [self allPeerIds];
        handler(completions);
    });
}

- (NSArray *)allPeerIds {
    NSArray *peerIds = LCCKTestPeerIds;
    return peerIds;
}

@end
