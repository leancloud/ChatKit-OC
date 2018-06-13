//
//  LCCKZoomingScrollView.m
//  LCCKPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "LCCKZoomingScrollView.h"
//#import "LCCKPhotoBrowser.h"
#import "LCCKCaptionView.h"
#import "LCCKPhoto.h"
#import "UIImage+LCCKExtension.h"

//// Declare private methods of browser
//@interface LCCKPhotoBrowser ()
//- (UIImage *)imageForPhoto:(id<LCCKPhoto>)photo;
//- (void)cancelControlHiding;
//- (void)hideControlsAfterDelay;
//- (void)toggleControls;
//@end

// Private methods and properties
@interface LCCKZoomingScrollView ()
//@property (nonatomic, weak) LCCKPhotoBrowser *photoBrowser;
@property (nonatomic, weak) id<LCCKZoomingScrollViewDelegate> photoDelegate;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
- (void)handleSingleTap:(CGPoint)touchPoint;
- (void)handleDoubleTap:(CGPoint)touchPoint;
@end

@implementation LCCKZoomingScrollView

//@synthesize photoImageView = _photoImageView, photoBrowser = _photoBrowser, photo = _photo, captionView = _captionView;
@synthesize photoImageView = _photoImageView, photo = _photo, captionView = _captionView;

- (void)dealloc {
//    LCCKLog(@"%@, %@, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%i", __LINE__]);
}

//- (id)initWithPhotoBrowser:(LCCKPhotoBrowser *)browser {
- (id)initWithPhotoDelegate:(id<LCCKZoomingScrollViewDelegate>)photoDelegate {
    if ((self = [super init])) {
        // Delegate
//        self.photoBrowser = browser;
        _photoDelegate = photoDelegate;
        
        // Long press
        _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [_longPress setMinimumPressDuration:0.2f];

		// Tap view for background
		_tapView = [[LCCKTapDetectingView alloc] initWithFrame:self.bounds];
		_tapView.tapDelegate = self;
		_tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tapView.backgroundColor = [UIColor blackColor];
        [_tapView addGestureRecognizer:_longPress];
		[self addSubview:_tapView];
        
		// Image view
		_photoImageView = [[LCCKTapDetectingImageView alloc] initWithFrame:CGRectZero];
		_photoImageView.tapDelegate = self;
		_photoImageView.backgroundColor = [UIColor blackColor];
        [_photoImageView addGestureRecognizer:_longPress];
		[self addSubview:_photoImageView];
        
        CGRect screenBound = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenBound.size.width;
        CGFloat screenHeight = screenBound.size.height;
        
//        if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
//            [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
//            screenWidth = screenBound.size.height;
//            screenHeight = screenBound.size.width;
//        }
        
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            screenWidth = screenBound.size.height;
            screenHeight = screenBound.size.width;
        }
        
        // Progress view
//        _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake((screenWidth-35.)/2., (screenHeight-35.)/2, 35.0f, 35.0f)];
        _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake((screenWidth-40)/2., (screenHeight-40)/2, 40, 40)];
        [_progressView setProgress:0.0f];
        _progressView.tag = 101;
//        _progressView.thicknessRatio = 0.1;
        _progressView.thicknessRatio = 0.2;
//        _progressView.roundedCorners = NO;
//        _progressView.trackTintColor    = browser.trackTintColor    ? self.photoBrowser.trackTintColor    : [UIColor colorWithWhite:0.2 alpha:1];
//        _progressView.progressTintColor = browser.progressTintColor ? self.photoBrowser.progressTintColor : [UIColor colorWithWhite:1.0 alpha:1];
        if ([_photoDelegate respondsToSelector:@selector(trackTintColorForZoomingScrollView:)]) {
            _progressView.trackTintColor = [_photoDelegate trackTintColorForZoomingScrollView:self]    ? [_photoDelegate trackTintColorForZoomingScrollView:self] : [UIColor colorWithWhite:0.2 alpha:1];
        } else {
            _progressView.trackTintColor = [UIColor colorWithWhite:0.2 alpha:1];
        }
        
        if ([_photoDelegate respondsToSelector:@selector(progressTintColorForZoomingScrollView:)]) {
            _progressView.progressTintColor = [_photoDelegate progressTintColorForZoomingScrollView:self] ? [_photoDelegate progressTintColorForZoomingScrollView:self] : [UIColor colorWithWhite:1.0 alpha:1];
        } else {
            _progressView.progressTintColor = [UIColor colorWithWhite:1.0 alpha:1];
        }
        _progressView.userInteractionEnabled = NO;
        
        [self addSubview:_progressView];
        
		// Setup
		self.backgroundColor = [UIColor clearColor];
		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return self;
}

- (void)setPhoto:(id<LCCKPhoto>)photo {
    _photoImageView.image = nil; // Release image
    if (_photo != photo) {
        _photo = photo;
    }
    [self displayImage];
}

- (void)prepareForReuse {
    self.photo = nil;
    [_captionView removeFromSuperview];
    self.captionView = nil;
    [self hideImageFailure];
}

#pragma mark - Long press
- (void)longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.photoDelegate respondsToSelector:@selector(longTapInZoomingScrollView:)]) {
            [self.photoDelegate longTapInZoomingScrollView:self];
        }
    }
}

#pragma mark - Animate image
- (void)animateImage {
    
    CGRect fromFrame = ({
        // Center the image as it becomes smaller than the size of the screen
        CGSize boundsSize = self.bounds.size;
        CGRect frameToCenter = [self.photo placeholderImageView].frame;
        
        // Horizontally
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
        } else {
            frameToCenter.origin.x = 0;
        }
        
        // Vertically
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
        } else {
            frameToCenter.origin.y = 0;
        }
        frameToCenter;
    });
    
    UIImage *toImage = _photoImageView.image;
    
    CGRect toFrame = ({
        // Center the image as it becomes smaller than the size of the screen
        CGSize boundsSize = self.bounds.size;
        CGRect frameToCenter = _photoImageView.frame;
        
        // Horizontally
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
        } else {
            frameToCenter.origin.x = 0;
        }
        
        // Vertically
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
        } else {
            frameToCenter.origin.y = 0;
        }
        frameToCenter;
    });
    
    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:toImage];
    resizableImageView.frame = fromFrame;
    resizableImageView.clipsToBounds = [self.photo placeholderImageView] ? [self.photo placeholderImageView].clipsToBounds : YES;
    resizableImageView.contentMode = [self.photo placeholderImageView] ? [self.photo placeholderImageView].contentMode : UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    
    [self addSubview:resizableImageView];
    
//    CGFloat animateDuration;
//    if ([self.photoDelegate respondsToSelector:@selector(animationDurationForZoomingScrollView:)]) {
//        animateDuration = [self.photoDelegate animationDurationForZoomingScrollView:self] != 0 ? [self.photoDelegate animationDurationForZoomingScrollView:self] : 0.28;
//    } else {
//        animateDuration = 0.28;
//    }
    self.photoImageView.hidden = YES;
    [UIView animateWithDuration:0.5 animations:^{
        resizableImageView.layer.frame = toFrame;
    } completion:^(BOOL finished) {
        self.photoImageView.hidden = NO;
        [resizableImageView removeFromSuperview];
    }];
}

#pragma mark - Image

// Get and display image
- (void)displayImage {
	if (_photo) {
		// Reset
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
        
		self.contentSize = CGSizeMake(0, 0);
		
		// Get image from browser as it handles ordering of fetching
//		UIImage *img = [self.photoBrowser imageForPhoto:_photo];
        UIImage *img = [self.photoDelegate imageForPhoto:_photo zoomingScrollView:self];
		if (img) {
            if (![_photo loadingInProgress]) {
                // Hide ProgressView
                _progressView.alpha = 0.0f;
//                [_progressView removeFromSuperview];
            }
            
            // Set image
			_photoImageView.image = img;
			_photoImageView.hidden = NO;
            
            // Setup photo frame
			CGRect photoImageViewFrame;
			photoImageViewFrame.origin = CGPointZero;
			photoImageViewFrame.size = img.size;
            
			_photoImageView.frame = photoImageViewFrame;
			self.contentSize = photoImageViewFrame.size;

			// Set zoom to minimum zoom
			[self setMaxMinZoomScalesForCurrentBounds];
        } else {
			// Hide image view
			_photoImageView.hidden = YES;
            
            _progressView.alpha = 1.0f;
            
            [self hideImageFailure];
		}
        
		[self setNeedsLayout];
	}
}

- (void)setProgress:(CGFloat)progress forPhoto:(LCCKPhoto*)photo {
    LCCKPhoto *p = (LCCKPhoto*)self.photo;

    if ([photo.photoURL.absoluteString isEqualToString:p.photoURL.absoluteString]) {
        if (_progressView.progress < progress) {
            [_progressView setProgress:progress animated:YES];
        }
    }
}

// Image failed so just show black!
- (void)displayImageFailure {
    _progressView.alpha = 0;
    //    [_progressView removeFromSuperview];
    
    if (!_loadingError) {
        _loadingError = [[UIImageView alloc] init];
        _loadingError.image = [UIImage lcck_imageNamed:@"LCCKPhotoBrowser_error" bundleName:@"LCCKPhotoBrowser" bundleForClass:[self class]];
        _loadingError.userInteractionEnabled = NO;
        _loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [_loadingError sizeToFit];
        [self addSubview:_loadingError];
    }
    CGRect frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                              floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2.),
                              _loadingError.frame.size.width,
                              _loadingError.frame.size.height);
    
    _loadingError.frame = frame;
    
    CGFloat animateDuration;
    if ([self.photoDelegate respondsToSelector:@selector(animationDurationForZoomingScrollView:)]) {
        animateDuration = [self.photoDelegate animationDurationForZoomingScrollView:self] != 0 ? [self.photoDelegate animationDurationForZoomingScrollView:self] : 0.28;
    } else {
        animateDuration = 0.28;
    }
    _loadingError.transform = CGAffineTransformMakeScale(0, 0);
    [UIView animateWithDuration:animateDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:6 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _loadingError.transform = CGAffineTransformMakeScale(1, 1);
    } completion:^(BOOL finished) {
    }];
//    [UIView animateWithDuration:0 animations:^{
//        _loadingError.frame = frame;
//    } completion:^(BOOL finished) {
//        ;
//    }];
}

- (void)hideImageFailure {
    if (_loadingError) {
        [_loadingError removeFromSuperview];
        _loadingError = nil;
    }
}

- (BOOL)loadingImageFailure {
    return _loadingError != nil;
}

#pragma mark - Setup

- (void)setMaxMinZoomScalesForCurrentBounds {
	// Reset
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
    
	// Bail
	if (_photoImageView.image == nil) return;
    
	// Sizes
	CGSize boundsSize = self.bounds.size;
	boundsSize.width -= 0.1;
	boundsSize.height -= 0.1;
	
    CGSize imageSize = _photoImageView.frame.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
	// If image is smaller than the screen then ensure we show it at
	// min scale of 1
    if ([self.photo loadingInProgress] || [self loadingImageFailure]) {
        if (xScale > 1 && yScale > 1) {
            minScale = 1.0;
        }
    }
    
	// Calculate Max
	CGFloat maxScale = 4.0; // Allow double scale
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		maxScale = maxScale / [[UIScreen mainScreen] scale];
		
		if (maxScale < minScale) {
			maxScale = minScale * 2;
		}
	}
    
	// Set
	self.maximumZoomScale = maxScale;
	self.minimumZoomScale = minScale;
	self.zoomScale = minScale;
    
	// Reset position
	_photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
	[self setNeedsLayout];    
}

#pragma mark - Layout

- (void)layoutSubviews {
	// Update tap view frame
	_tapView.frame = self.bounds;
    
    // Position indicators (centre does not seem to work!)
    if (_progressView.alpha != 0)
        _progressView.frame = CGRectMake(floorf((self.bounds.size.width - _progressView.frame.size.width) / 2.),
                                             floorf((self.bounds.size.height - _progressView.frame.size.height) / 2.),
                                             _progressView.frame.size.width,
                                             _progressView.frame.size.height);
    
    if (_loadingError)
        _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2.),
                                         _loadingError.frame.size.width,
                                         _loadingError.frame.size.height);
    
	// Super
	[super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	// Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter)) {
        _photoImageView.frame = frameToCenter;
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
//	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//	[_photoBrowser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    [self performSelector:@selector(handleSingleTapInZoomingScrollView:) withObject:self afterDelay:0.18];
}

- (void)handleSingleTapInZoomingScrollView:(LCCKZoomingScrollView *)zoomingScrollView {
    if ([self.photoDelegate respondsToSelector:@selector(singleTapInZoomingScrollView:)]) {
        [self.photoDelegate singleTapInZoomingScrollView:zoomingScrollView];
    }
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	// Zoom
	if (self.zoomScale == self.maximumZoomScale) {
		
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
		
	} else {
    
		// Zoom in
		[self zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
		
	}
	
//	// Delay controls
//	[_photoBrowser hideControlsAfterDelay];
    if ([self.photoDelegate respondsToSelector:@selector(doubleTapInZoomingScrollView:)]) {
        [self.photoDelegate doubleTapInZoomingScrollView:self];
    }
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch { 
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    [self handleSingleTap:[touch locationInView:view]];
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:view]];
}

@end
