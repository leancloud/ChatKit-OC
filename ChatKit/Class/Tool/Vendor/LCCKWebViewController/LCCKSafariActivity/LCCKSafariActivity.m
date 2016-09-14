//
//  LCCKSafariActivity.m
//  Pinbrowser
//
//  Created by Mikael Konutgan on 12/02/2013.
//  Copyright (c) 2013 Mikael Konutgan. All rights reserved.
//

#import "LCCKSafariActivity.h"
#import "UIImage+LCCKExtension.h"

@interface LCCKSafariActivity ()

@property (strong, nonatomic) NSURL *URL;

@end

@implementation LCCKSafariActivity

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Open in Safari", @"Open the URL in Safari.");
}

- (UIImage *)activityImage {
    return [UIImage lcck_imageNamed:@"safari-icon" bundleName:@"Other" bundleForClass:[self class]];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
            return YES;
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
            self.URL = activityItem;
            
            return;
        }
    }
}

- (void)performActivity {
    [[UIApplication sharedApplication] openURL:self.URL];
    [self activityDidFinish:YES];
}

@end
