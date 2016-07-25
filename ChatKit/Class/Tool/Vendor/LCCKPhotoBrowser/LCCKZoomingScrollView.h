//
//  LCCKZoomingScrollView.h
//  LCCKPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKPhotoProtocol.h"
#import "LCCKTapDetectingImageView.h"
#import "LCCKTapDetectingView.h"

#import <DACircularProgress/DACircularProgressView.h>

//@class LCCKPhotoBrowser, LCCKPhoto, LCCKCaptionView;
@class LCCKPhoto, LCCKCaptionView;

@protocol LCCKZoomingScrollViewDelegate;

@interface LCCKZoomingScrollView : UIScrollView <UIScrollViewDelegate, LCCKTapDetectingImageViewDelegate, LCCKTapDetectingViewDelegate> {
	
//	LCCKPhotoBrowser *__weak _photoBrowser;
    id<LCCKPhoto> _photo;
	
    // This view references the related caption view for simplified handling in photo browser
    LCCKCaptionView *_captionView;
    
	LCCKTapDetectingView *_tapView; // for background taps
    
    DACircularProgressView *_progressView;
    
    UIImageView *_loadingError;
}

@property (nonatomic, strong) LCCKTapDetectingImageView *photoImageView;
@property (nonatomic, strong) LCCKCaptionView *captionView;
@property (nonatomic, strong) id<LCCKPhoto> photo;

//- (id)initWithPhotoBrowser:(LCCKPhotoBrowser *)browser;
- (id)initWithPhotoDelegate:(id<LCCKZoomingScrollViewDelegate>)photoDelegate;
- (void)displayImage;
- (void)displayImageFailure;
- (void)setProgress:(CGFloat)progress forPhoto:(LCCKPhoto*)photo;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

- (void)animateImage;

@end

@protocol LCCKZoomingScrollViewDelegate <NSObject>

@required
- (UIImage *)imageForPhoto:(id<LCCKPhoto>)photo zoomingScrollView:(LCCKZoomingScrollView *)zoomingScrollView;

@optional
- (UIColor *)trackTintColorForZoomingScrollView:(LCCKZoomingScrollView *)zoomingScrollView;
- (UIColor *)progressTintColorForZoomingScrollView:(LCCKZoomingScrollView *)zoomingScrollView;
- (CGFloat)animationDurationForZoomingScrollView:(LCCKZoomingScrollView *)zoomingScrollView;

- (void)singleTapInZoomingScrollView:(LCCKZoomingScrollView *)zoomingScrollView;
- (void)doubleTapInZoomingScrollView:(LCCKZoomingScrollView *)zoomingScrollView;
- (void)longTapInZoomingScrollView:(LCCKZoomingScrollView *)zoomingScrollView;

@end
