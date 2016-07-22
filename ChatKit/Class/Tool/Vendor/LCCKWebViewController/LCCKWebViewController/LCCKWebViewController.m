//
//  LCCKWebViewController.m
//  Pinbrowser
//
//  Created by Mikael Konutgan on 11/02/2013.
//  Copyright (c) 2013 Mikael Konutgan. All rights reserved.
//

#import "LCCKWebViewController.h"
#import "LCCKWebViewProgress.h"
#import "LCCKWebViewProgressView.h"

@interface LCCKWebViewController () <LCCKWebViewProgressDelegate>

@property (strong, nonatomic) UIWebView *webView;

@property (strong, nonatomic) UIBarButtonItem *stopLoadingButton;
@property (strong, nonatomic) UIBarButtonItem *reloadButton;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) UIBarButtonItem *forwardButton;
@property (nonatomic, strong) LCCKWebViewProgress *progressProxy;
@property (nonatomic, strong) LCCKWebViewProgressView *progressView;

@property (assign, nonatomic) BOOL toolbarPreviouslyHidden;


@end

@implementation LCCKWebViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _showsNavigationToolbar = YES;
}



-(void)webViewProgress:(LCCKWebViewProgress *)webViewProgress updateProgress:(float)progress {
    [_progressView setProgress:progress animated:YES];
    self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void)load {
    [self.webView loadRequest:self.URLRequest];
    
    if (self.navigationController.toolbarHidden) {
        self.toolbarPreviouslyHidden = YES;
        if (self.showsNavigationToolbar) {
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
}

- (void)clear {
    [self.webView loadHTMLString:@"" baseURL:nil];
    self.title = @"";
}

#pragma mark - View controller lifecycle

- (void)loadView {
    self.webView = [[UIWebView alloc] init];
    self.webView.scalesPageToFit = YES;
    self.view = self.webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _progressProxy = [[LCCKWebViewProgress alloc] init];
    _webView.delegate = _progressProxy;
    _progressProxy.webViewProxyDelegate = self;
    _progressProxy.progressDelegate = self;
    
    CGFloat progressBarHeight = 3.f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height, navigationBarBounds.size.width, progressBarHeight);
    _progressView = [[LCCKWebViewProgressView alloc] initWithFrame:barFrame];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self setupToolBarItems];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.URL) {
        [self load];
    }
    [self.navigationController.navigationBar addSubview:_progressView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webView stopLoading];
    self.webView.delegate = nil;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [_progressView removeFromSuperview];
    if (self.toolbarPreviouslyHidden && self.showsNavigationToolbar) {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

#pragma mark - URL setter/getter

- (void)setURL:(NSURL *)URL {
    self.URLRequest = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
}

- (NSURL *)URL {
    return self.URLRequest.URL;
}

#pragma mark - Helpers

- (UIImage *)backButtonImage {
    static UIImage *image;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        CGSize size = CGSizeMake(12.0, 21.0);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        path.lineWidth = 1.5;
        path.lineCapStyle = kCGLineCapButt;
        path.lineJoinStyle = kCGLineJoinMiter;
        [path moveToPoint:CGPointMake(11.0, 1.0)];
        [path addLineToPoint:CGPointMake(1.0, 11.0)];
        [path addLineToPoint:CGPointMake(11.0, 20.0)];
        [path stroke];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    
    return image;
}

- (UIImage *)forwardButtonImage {
    static UIImage *image;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        UIImage *backButtonImage = [self backButtonImage];
        
        CGSize size = backButtonImage.size;
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGFloat midX = size.width / 2.0;
        CGFloat midY = size.height / 2.0;
        
        CGContextTranslateCTM(context, midX, midY);
        CGContextRotateCTM(context, M_PI);
        
        [backButtonImage drawAtPoint:CGPointMake(-midX, -midY)];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    
    return image;
}

- (void)setupToolBarItems {
    self.stopLoadingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self.webView action:@selector(stopLoading)];
    self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.webView action:@selector(reload)];
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[self backButtonImage] style:UIBarButtonItemStylePlain target:self.webView action:@selector(goBack)];
    self.forwardButton = [[UIBarButtonItem alloc] initWithImage:[self forwardButtonImage] style:UIBarButtonItemStylePlain target:self.webView action:@selector(goForward)];
    
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *space_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    space_.width = 60.0;
    
    self.toolbarItems = @[self.stopLoadingButton, space, self.backButton, space_, self.forwardButton, space, actionButton];
}

- (void)toggleState {
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    
    NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
    
    if (self.webView.loading) {
        toolbarItems[0] = self.stopLoadingButton;
    } else {
        toolbarItems[0] = self.reloadButton;
    }
    
    self.toolbarItems = [toolbarItems copy];
}

- (void)finishLoad {
    [self toggleState];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - Button actions

- (void)action:(id)sender {
    NSArray *activityItems = self.activityItems ? self.activityItems : @[self.URL];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:self.applicationActivities];
    
    activityViewController.excludedActivityTypes = self.excludedActivityTypes;
    
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    activityViewController.popoverPresentationController.barButtonItem = self.toolbarItems.lastObject;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Web view delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self toggleState];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self finishLoad];
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.URL = self.webView.request.URL;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self finishLoad];
}

@end
