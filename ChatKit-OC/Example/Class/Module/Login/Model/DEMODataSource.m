//
//  DEMODataSource.m
//  MLPAutoCompleteDemo
//
//  Created by Eddy Borja on 5/28/14.
//  Copyright (c) 2014 Mainloop. All rights reserved.
//
@import UIKit;
@import Foundation;

///-----------------------------------------------------------------------------------
///---------------------用以产生Demo中的联系人数据的宏定义-------------------------------
///-----------------------------------------------------------------------------------

#define LCIMProfileKeyPeerId        @"peerId"
#define LCIMProfileKeyName          @"username"
#define LCIMProfileKeyAvatarURL     @"avatarURL"
#define LCIMDeveloperPeerId @"571dae7375c4cd3379024b2f"

//TODO:add more friends
#define LCIMContactProfiles \
@[ \
    @{ LCIMProfileKeyPeerId:LCIMDeveloperPeerId, LCIMProfileKeyName:@"LCIMKit小秘书", LCIMProfileKeyAvatarURL:@"http://image17-c.poco.cn/mypoco/myphoto/20151211/16/17338872420151211164742047.png" },\
    @{ LCIMProfileKeyPeerId:@"Tom", LCIMProfileKeyName:@"Tom", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/tom_and_jerry2.jpg" },\
    @{ LCIMProfileKeyPeerId:@"Jerry", LCIMProfileKeyName:@"Jerry", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/jerry.jpg" },\
    @{ LCIMProfileKeyPeerId:@"Harry", LCIMProfileKeyName:@"Harry", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/young_harry.jpg" },\
    @{ LCIMProfileKeyPeerId:@"William", LCIMProfileKeyName:@"William", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/william_shakespeare.jpg" },\
    @{ LCIMProfileKeyPeerId:@"Bob", LCIMProfileKeyName:@"Bob", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/bath_bob.jpg" },\
]

#define LCIMContactPeerIds \
    [LCIMContactProfiles valueForKeyPath:LCIMProfileKeyPeerId]

#define LCIMTestPersonProfiles \
@[ \
    @{ LCIMProfileKeyPeerId:@"Tom" },\
    @{ LCIMProfileKeyPeerId:@"Jerry" },\
    @{ LCIMProfileKeyPeerId:@"Harry" },\
    @{ LCIMProfileKeyPeerId:@"William" },\
    @{ LCIMProfileKeyPeerId:@"Bob" },\
]

#define LCIMTestPeerIds \
    [LCIMTestPersonProfiles valueForKeyPath:LCIMProfileKeyPeerId]


#import "DEMODataSource.h"
#import "DEMOCustomAutoCompleteObject.h"

@interface DEMODataSource ()

@property (strong, nonatomic) NSArray *countryObjects;

@end


@implementation DEMODataSource


#pragma mark - MLPAutoCompleteTextField DataSource


//example of asynchronous fetch:
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
        
        NSArray *completions;
        if(self.testWithAutoCompleteObjectsInsteadOfStrings){
            completions = [self allCountryObjects];
        } else {
            completions = [self allCountries];
        }
        
        handler(completions);
    });
}

/*
 - (NSArray *)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
 possibleCompletionsForString:(NSString *)string
 {
 
 if(self.simulateLatency){
 CGFloat seconds = arc4random_uniform(4)+arc4random_uniform(4); //normal distribution
 NSLog(@"sleeping fetch of completions for %f", seconds);
 sleep(seconds);
 }
 
 NSArray *completions;
 if(self.testWithAutoCompleteObjectsInsteadOfStrings){
 completions = [self allCountryObjects];
 } else {
 completions = [self allCountries];
 }
 
 return completions;
 }
 */

- (NSArray *)allCountryObjects
{
    if(!self.countryObjects){
        NSArray *countryNames = [self allCountries];
        NSMutableArray *mutableCountries = [NSMutableArray new];
        for(NSString *countryName in countryNames){
            DEMOCustomAutoCompleteObject *country = [[DEMOCustomAutoCompleteObject alloc] initWithCountry:countryName];
            [mutableCountries addObject:country];
        }
        
        [self setCountryObjects:[NSArray arrayWithArray:mutableCountries]];
    }
    
    return self.countryObjects;
}


- (NSArray *)allCountries
{
    NSArray *countries = LCIMTestPeerIds;
    
    return countries;
}





@end
