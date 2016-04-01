//
//  XHDisplayMediaViewController.m
//  MessageDisplayExample
//
//  Created by qtone-1 on 14-5-6.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import "XHDisplayMediaViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface XHDisplayMediaViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@property (nonatomic, weak) UIScrollView *backgroundView;

@property (nonatomic, weak) UIImageView *photoImageView;

@end

@implementation XHDisplayMediaViewController

#pragma mark -
#pragma mark - LazyLoad Method

- (MPMoviePlayerController *)moviePlayerController {
    if (!_moviePlayerController) {
        _moviePlayerController = [[MPMoviePlayerController alloc] init];
        _moviePlayerController.repeatMode = MPMovieRepeatModeOne;
        _moviePlayerController.scalingMode = MPMovieScalingModeAspectFill;
        _moviePlayerController.view.frame = self.view.frame;
        [self.view addSubview:_moviePlayerController.view];
    }
    return _moviePlayerController;
}

/**
 *  lazy load backgroundView
 *
 *  @return UIScrollView
 */
- (UIScrollView *)backgroundView {
    if (_backgroundView == nil) {
        UIScrollView *backgroundView = [[UIScrollView alloc] initWithFrame:self.view.frame];
        backgroundView.backgroundColor = [UIColor blackColor];
        backgroundView.minimumZoomScale = 1;
        backgroundView.maximumZoomScale = 2.0;
        backgroundView.delegate = self;
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popBack:)];
        [backgroundView addGestureRecognizer:recognizer];
        //TODO:长按事件，保存本地
        [self.view addSubview:backgroundView];
        _backgroundView = backgroundView;
    }
    return _backgroundView;
}


- (UIImageView *)photoImageView {
    if (!_photoImageView) {
        UIImageView *photoImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        photoImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.backgroundView addSubview:photoImageView];
        self.backgroundView.contentSize = photoImageView.frame.size;
        [self.backgroundView scrollRectToVisible:self.view.frame animated:YES];
        _photoImageView = photoImageView;
    }
    return _photoImageView;
}

#pragma mark - Life cycle

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    [super viewWillDisappear:animated];
    if ([self.message messageMediaType] == XHBubbleMessageMediaTypeVideo) {
        [self.moviePlayerController stop];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)dealloc {
    [_moviePlayerController stop];
}

#pragma mark -
#pragma mark - Custom Method

- (void)centerContent {
    CGRect frame = self.backgroundView.frame;
    
    CGFloat top = 0, left = 0;
    if (self.backgroundView.contentSize.width < self.view.bounds.size.width) {
        left = (self.view.bounds.size.width - self.backgroundView.contentSize.width) * 0.5f;
    }
    if (self.backgroundView.contentSize.height < self.view.bounds.size.height) {
        top = (self.view.bounds.size.height - self.backgroundView.contentSize.height) * 0.5f;
    }
    
    top -= frame.origin.y;
    left -= frame.origin.x;
    
    self.backgroundView.contentInset = UIEdgeInsetsMake(top, left, top, left);
}

- (void)setMessage:(id<XHMessageModel>)message {
    _message = message;
    if ([message messageMediaType] == XHBubbleMessageMediaTypeVideo) {
        self.title = NSLocalizedStringFromTable(@"Video", @"LCIMKitString", @"详细视频");
        self.moviePlayerController.contentURL = [NSURL fileURLWithPath:[message videoPath]];
        [self.moviePlayerController play];
    } else if ([message messageMediaType] ==XHBubbleMessageMediaTypePhoto) {
        self.title = NSLocalizedStringFromTable(@"Photo", @"LCIMKitString", @"详细照片");
        self.photoImageView.image = message.photo;
        if (message.thumbnailUrl) {
            NSString *iconName = @"Placeholder_Image";
            NSString *imageString = [NSString stringWithFormat:@"Placeholder.bundle/%@", iconName];
            UIImage *image = [UIImage imageNamed:imageString];
            [self.photoImageView sd_setImageWithURL:[NSURL URLWithString:[message thumbnailUrl]] placeholderImage:image];
        }
    }
}

- (void)popBack:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark -
#pragma mark - ScrollView Delegate  Method


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.photoImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerContent];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
