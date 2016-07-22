//
//  LCCKWebViewController.h
//  Pinbrowser
//
//  Created by Mikael Konutgan on 11/02/2013.
//  Copyright (c) 2013 Mikael Konutgan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The `LCCKWebViewController` class is a view controller that displays the contents of a URL
 * along tith a navigation toolbar with buttons to stop/refresh the loading of the page
 * as well as buttons to go back, forward and to share the URL using a `UIActivityViewController`.
 */
@interface LCCKWebViewController : UIViewController <UIWebViewDelegate>

/**
 * The URL that will be loaded by the web view controller.
 * If there is one present when the web view appears, it will be automatically loaded, by calling `load`,
 * Otherwise, you can set a `URL` after the web view has already been loaded and then manually call `load`.
 * Automatically creates a NSURLRequest for you.
 */
@property (strong, nonatomic, nullable) NSURL *URL;

/**
 * The URL request that will be loaded by the web view controller.
 * If there is one present when the web view appears, it will be automatically loaded, by calling `load`,
 * Otherwise, you can set a `URLRequest` after the web view has already been loaded and then manually call `load`.
 * Use this to set your own request with custom headers.
 */
@property (strong, nonatomic, nullable) NSURLRequest *URLRequest;

/** 
 * The array of data objects on which to perform the activity.
 * `@[self.URL]` is used if nothing is provided.
 */
@property (strong, nonatomic, nullable) NSArray *activityItems;

/**
 * An array of `UIActivity` objects representing the custom services that your application supports.
 */
@property (strong, nonatomic, nullable) NSArray *applicationActivities;

/**
 * The list of services that should not be displayed.
 */
@property (strong, nonatomic, nullable) NSArray *excludedActivityTypes;

/**
 * A Boolean indicating whether the web view controller’s toolbar,
 * which displays a stop/refresh, back, forward and share button, is shown.
 * The default value of this property is `YES`.
 */
@property (assign, nonatomic) BOOL showsNavigationToolbar;

/**
 * Loads the given `URL`.
 * This is called automatically when the when the web view appears if a `URL` exists,
 * otehrwise it can be called manually.
 */
- (void)load;

/**
 * Clears the contents of the web view.
 */
- (void)clear;

@end

NS_ASSUME_NONNULL_END
