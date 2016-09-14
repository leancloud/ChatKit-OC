//
//  LCCKPhotoProtocol.h
//  LCCKPhotoBrowser
//
//  Created by Michael Waterfall on 02/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
@import UIKit;
@import Foundation;
#import <Foundation/Foundation.h>
#import "LCCKPBConstants.h"

// Name of notification used when a photo has completed loading process
// Used to notify browser display the image
#define LCCKPhoto_LOADING_DID_END_NOTIFICATION @"LCCKPhoto_LOADING_DID_END_NOTIFICATION"

// If you wish to use your own data models for photo then they must conform
// to this protocol. See instructions for details on each method.
// Otherwise you can use the LCCKPhoto object or subclass it yourself to
// store more information per photo.
//
// You can see the LCCKPhoto class for an example implementation of this protocol
//
@protocol LCCKPhoto <NSObject>

@required

// Return underlying UIImage to be displayed
// Return nil if the image is not immediately available (loaded into memory, preferably 
// already decompressed) and needs to be loaded from a source (cache, file, web, etc)
// IMPORTANT: You should *NOT* use this method to initiate
// fetching of images from any external of source. That should be handled
// in -loadUnderlyingImageAndNotify: which may be called by the photo browser if this
// methods returns nil.
- (UIImage *)underlyingImage;

// Called when the browser has determined the underlying images is not
// already loaded into memory but needs it.
// You must load the image asyncronously (and decompress it for better performance).
// See LCCKPhoto object for an example implementation.
// When the underlying UIImage is loaded (or failed to load) you should post the following
// notification:
//
// [[NSNotificationCenter defaultCenter] postNotificationName:LCCKPhoto_LOADING_DID_END_NOTIFICATION
//                                                     object:self];
//
- (void)loadUnderlyingImageAndNotify;

// This is called when the photo browser has determined the photo data
// is no longer needed or there are low memory conditions
// You should release any underlying (possibly large and decompressed) image data
// as long as the image can be re-loaded (from cache, file, or URL)
- (void)unloadUnderlyingImage;

@optional

// Return a caption string to be displayed over the image
// Return nil to display no caption
- (NSString *)caption;

// Return placeholder UIImage to be displayed while loading underlyingImage
// Return nil if there is no placeholder
- (UIImage *)placeholderImage;

// Using placeholder image view to calculate origin frame
- (UIImageView *)placeholderImageView;

// Placeholder frame
- (CGRect)placeholderFrame;

// Loading status
- (BOOL)loadingInProgress;

// Check underlying image existed or not
- (BOOL)underlyingImageExisted;

@end