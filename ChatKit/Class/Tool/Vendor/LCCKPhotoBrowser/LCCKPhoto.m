//
//  LCCKPhoto.m
//  LCCKPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "LCCKPhoto.h"
#import "LCCKPhotoBrowser.h"

// Private
@interface LCCKPhoto () {
    // Image Sources
    NSString *_photoPath;

    // Image
    UIImage *_underlyingImage;

    // Other
    NSString *_caption;
    BOOL _loadingInProgress;
    CGRect _placeholderFrame;
}

// Properties
@property (nonatomic, strong) UIImage *underlyingImage;
@property (nonatomic, assign) CGRect placeholderFrame;

// Methods
- (void)imageLoadingComplete;

@end

// LCCKPhoto
@implementation LCCKPhoto

// Properties
@synthesize underlyingImage = _underlyingImage, 
photoURL = _photoURL,
caption = _caption, loadingInProgress = _loadingInProgress, placeholderFrame = _placeholderFrame;

- (void)dealloc {
//    LCCKLog(@"%@, %@, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%i", __LINE__]);
}

#pragma mark Class Methods

+ (LCCKPhoto *)photoWithImage:(UIImage *)image {
	return [[LCCKPhoto alloc] initWithImage:image];
}

+ (LCCKPhoto *)photoWithFilePath:(NSString *)path {
	return [[LCCKPhoto alloc] initWithFilePath:path];
}

+ (LCCKPhoto *)photoWithURL:(NSURL *)url {
	return [[LCCKPhoto alloc] initWithURL:url];
}

+ (NSArray *)photosWithImages:(NSArray *)imagesArray {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:imagesArray.count];
    
    for (UIImage *image in imagesArray) {
        if ([image isKindOfClass:[UIImage class]]) {
            LCCKPhoto *photo = [LCCKPhoto photoWithImage:image];
            [photos addObject:photo];
        }
    }
    
    return photos;
}

+ (NSArray *)photosWithFilePaths:(NSArray *)pathsArray {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:pathsArray.count];
    
    for (NSString *path in pathsArray) {
        if ([path isKindOfClass:[NSString class]]) {
            LCCKPhoto *photo = [LCCKPhoto photoWithFilePath:path];
            [photos addObject:photo];
        }
    }
    
    return photos;
}

+ (NSArray *)photosWithURLs:(NSArray *)urlsArray {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:urlsArray.count];
    
    for (id url in urlsArray) {
        if ([url isKindOfClass:[NSURL class]]) {
            LCCKPhoto *photo = [LCCKPhoto photoWithURL:url];
            [photos addObject:photo];
        }
        else if ([url isKindOfClass:[NSString class]]) {
            LCCKPhoto *photo = [LCCKPhoto photoWithURL:[NSURL URLWithString:url]];
            [photos addObject:photo];
        }
    }
    
    return photos;
}

#pragma mark NSObject

- (id)initWithImage:(UIImage *)image {
	if ((self = [super init])) {
		self.underlyingImage = image;
	}
	return self;
}

- (id)initWithFilePath:(NSString *)path {
	if ((self = [super init])) {
		_photoPath = [path copy];
	}
	return self;
}

- (id)initWithURL:(NSURL *)url {
	if ((self = [super init])) {
		_photoURL = [url copy];
	}
	return self;
}

#pragma mark - Public methods
- (BOOL)underlyingImageExisted {
    return _underlyingImage != nil || [[NSFileManager defaultManager] fileExistsAtPath:_photoPath] || [[SDImageCache sharedImageCache] diskImageExistsWithKey:_photoURL.absoluteString];
}

#pragma mark - Private methods
- (UIImage *)imageFromPlaceholderImageView {
    UIGraphicsBeginImageContextWithOptions(_placeholderImageView.bounds.size, YES, [UIScreen mainScreen].scale);
    [_placeholderImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Accessors
- (void)setPlaceholderImageView:(UIImageView *)placeholderImageView {
    _placeholderImageView = placeholderImageView;
    _placeholderFrame = [placeholderImageView.superview convertRect:placeholderImageView.frame toView:nil];
}

#pragma mark LCCKPhoto Protocol Methods

//- (UIImageView *)placeholderImageView {
//    if (!_placeholderImageView) {
//        _placeholderImageView = ({
//            UIImageView *imageView = [[UIImageView alloc] init];
//            imageView.contentMode = UIViewContentModeScaleAspectFill;
//            imageView.clipsToBounds = YES;
//            imageView.image = _placeholderImage;
//            imageView;
//        });
//    }
//    return _placeholderImageView;
//}

- (UIImage *)placeholderImage {
    if (_placeholderImage) {
        return _placeholderImage;
    } else {
//        if (_loadingInProgress) {
//            return [self imageFromPlaceholderImageView];
//        } else {
//            return _placeholderImageView.image;
//        }
        return [self imageFromPlaceholderImageView];
    }
}

- (UIImage *)underlyingImage {
    if ([[NSFileManager defaultManager] fileExistsAtPath:_photoPath]) {
        return [UIImage imageWithContentsOfFile:_photoPath];
    }
    if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:_photoURL.absoluteString]) {
        return [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:_photoURL.absoluteString];
    }
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (_loadingInProgress) {
        return;
    }
    _loadingInProgress = YES;
    if (self.underlyingImage) {
        // Image already loaded
        [self imageLoadingComplete];
    } else {
        if (_photoPath) {
            // Load async from file
            [self performSelectorInBackground:@selector(loadImageFromFileAsync) withObject:nil];
        } else if (_photoURL) {
            // Load async from web (using SDWebImageManager)
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            [manager downloadImageWithURL:_photoURL options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                CGFloat progress = ((CGFloat)receivedSize)/((CGFloat)expectedSize);
                if (self.progressUpdateBlock) {
                    self.progressUpdateBlock(progress);
                }
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
//                if (image) {
//                    self.underlyingImage = image;
//                    [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
//                }
                self.underlyingImage = image;
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            }];

        } else {
            // Failed - no source
            self.underlyingImage = nil;
            [self imageLoadingComplete];
        }
    }
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
    _loadingInProgress = NO;

	if (self.underlyingImage && (_photoPath || _photoURL)) {
		self.underlyingImage = nil;
	}
}

#pragma mark - Async Loading

/*- (UIImage *)decodedImageWithImage:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    // System only supports RGB, set explicitly and prevent context error
    // if the downloaded image is not the supported format
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 CGImageGetWidth(imageRef),
                                                 CGImageGetHeight(imageRef),
                                                 8,
                                                 // width * 4 will be enough because are in ARGB format, don't read from the image
                                                 CGImageGetWidth(imageRef) * 4,
                                                 colorSpace,
                                                 // kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
                                                 // makes system don't need to do extra conversion when displayed.
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    
    if ( ! context) {
        return nil;
    }
    
    CGRect rect = (CGRect){CGPointZero, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)};
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [[UIImage alloc] initWithCGImage:decompressedImageRef];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}*/

- (UIImage *)decodedImageWithImage:(UIImage *)image {
    if (image.images)
    {
        // Do not decode animated images
        return image;
    }
    
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1)
    {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3)
    {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 colorSpace,
                                                 bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    // If failed, return undecompressed image
    if (!context) return image;
	
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
	
    CGContextRelease(context);
	
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

// Called in background
// Load image in background from local file
- (void)loadImageFromFileAsync {
    @autoreleasepool {
        @try {
            self.underlyingImage = [UIImage imageWithContentsOfFile:_photoPath];
            if (!_underlyingImage) {
                //LCCKLog(@"Error loading photo from path: %@", _photoPath);
            }
        } @finally {
            self.underlyingImage = [self decodedImageWithImage: self.underlyingImage];
            [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
        }
    }
}

// Called on main
- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKPhoto_LOADING_DID_END_NOTIFICATION
                                                        object:self];
}

@end
