//
//  LCCKProgressHUD.m
//  LCCKChatBarExample
//
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/8/17.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKProgressHUD.h"
#import "UIImage+LCCKExtension.h"
static CGFloat const kLCCKVolumeMaxTimeLength = 15;
@interface LCCKProgressHUD ()

@property (assign, nonatomic) CGFloat angle;
//@property (strong, nonatomic) NSTimer *timer;
//@property (strong, nonatomic) UIImageView *edgeImageView;
@property (strong, nonatomic) UILabel *centerLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (assign, nonatomic) LCCKProgressState progressState;
@property (assign, nonatomic) NSTimeInterval seconds;

@property (nonatomic, strong, readonly) UIWindow *overlayWindow;

@property (strong, nonatomic) UIView *bgView;
@property (strong, nonatomic) UIImageView *cancleImageView;
@property (strong, nonatomic) UIImageView *volumeImageView;
@property (strong, nonatomic) UIImageView *soundImageView;
@property (assign, nonatomic) CGFloat countdownTime;

@end

@implementation LCCKProgressHUD
@synthesize overlayWindow = _overlayWindow;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup{
    
    [self addSubview:self.bgView];
    
    [self.bgView addSubview:self.cancleImageView];
    [self.bgView addSubview:self.volumeImageView];
    [self.bgView addSubview:self.soundImageView];
//    [self addSubview:self.edgeImageView];
    [self.bgView addSubview:self.centerLabel];
    [self.bgView addSubview:self.subTitleLabel];
    [self.bgView addSubview:self.titleLabel];
}

#pragma mark - Private Methods

- (void)show {
    self.angle = 0.0f;
    self.seconds = 0;
    self.subTitleLabel.text = @"手指上滑,取消发送";
    self.subTitleLabel.backgroundColor = [UIColor clearColor];
//    self.centerLabel.text = @"15";
    self.countdownTime = kLCCKVolumeMaxTimeLength;
    self.titleLabel.text = @"录音时间";
//    [self timer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!self.superview)
            [[UIApplication sharedApplication].keyWindow addSubview:self];
        [UIView animateWithDuration:.5 animations:^{
                self.alpha = 1;
        } completion:nil];
        [self setNeedsDisplay];
    });
    
    self.titleLabel.alpha = 0;
    self.centerLabel.alpha = 0;
    
    _cancleImageView.alpha = 0;
    _soundImageView.alpha = 1;
    _volumeImageView.alpha = 1;
}

- (void)timerAction {
    self.angle -= 3;
    self.seconds ++ ;
    
    float second = self.countdownTime;
    if (second <= 10.0f) {
        _cancleImageView.alpha = 0;
        _soundImageView.alpha = 0;
        _volumeImageView.alpha = 0;
        self.centerLabel.alpha = 1;
    }
    //超时做调整
//    if (second <= 0.1f) {
//        [[LCCKProgressHUD sharedView]dismiss];
//    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.09];
    UIView.AnimationRepeatAutoreverses = YES;
//    self.edgeImageView.transform = CGAffineTransformMakeRotation(self.angle * (M_PI / 180.0f));
    if (second <= 10.0f) {
        self.centerLabel.textColor = [UIColor redColor];
    } else {
        self.centerLabel.textColor = [UIColor yellowColor];
    }
    self.countdownTime = second-0.1;
    self.centerLabel.text = [NSString stringWithFormat:@"%.0f",self.countdownTime];
    [UIView commitAnimations];
}

- (void)setSubTitle:(NSString *)subTitle {
    self.subTitleLabel.text = subTitle;
    if ([subTitle isEqualToString:@"松开手指,取消发送"]) {
        self.subTitleLabel.backgroundColor = [[UIColor redColor]colorWithAlphaComponent:0.7];
    } else if ([subTitle isEqualToString:@"手指上滑,取消发送"]) {
        self.subTitleLabel.backgroundColor = [UIColor clearColor];
    }
    
    if ((kLCCKVolumeMaxTimeLength - self.seconds/10.0) <= 10) {
        return;
    }
    if ([subTitle isEqualToString:@"松开手指,取消发送"]) {
        _cancleImageView.alpha = 1;
        _soundImageView.alpha = 0;
        _volumeImageView.alpha = 0;
    } else if ([subTitle isEqualToString:@"手指上滑,取消发送"]) {
        _cancleImageView.alpha = 0;
        _soundImageView.alpha = 1;
        _volumeImageView.alpha = 1;
    }
}

- (void)changeVolumeImageView:(float)volume timeLength:(NSTimeInterval)timeLength{
    NSString *imageName = @"";
    if (volume <= -50) {
        imageName = @"RecordingSignal001";
    } else if (volume <= -40) {
        imageName = @"RecordingSignal002";
    } else if (volume <= -31) {
        imageName = @"RecordingSignal003";
    } else if (volume <= -21) {
        imageName = @"RecordingSignal004";
    } else if (volume <= -13) {
        imageName = @"RecordingSignal005";
    } else if (volume <= -7) {
        imageName = @"RecordingSignal006";
    } else if (volume <= -3) {
        imageName = @"RecordingSignal007";
    } else {
        imageName = @"RecordingSignal008";
    }
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
    self.volumeImageView.image = image;
    
    self.seconds = timeLength;
    if ((kLCCKVolumeMaxTimeLength - self.seconds/10.0) <= 10) {
        _cancleImageView.alpha = 0;
        _soundImageView.alpha = 0;
        _volumeImageView.alpha = 0;
        self.centerLabel.alpha = 1;
        self.centerLabel.textColor = [UIColor redColor];
        self.centerLabel.font = [UIFont systemFontOfSize:60];
    } else {
        self.centerLabel.textColor = [UIColor yellowColor];
    }
    self.centerLabel.text = [NSString stringWithFormat:@"%.0f",(kLCCKVolumeMaxTimeLength - self.seconds/10.0)];
}

- (void)dismiss{
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.timer invalidate];
//        self.timer = nil;
        self.subTitleLabel.text = nil;
        self.titleLabel.text = nil;
        self.centerLabel.font = [UIFont systemFontOfSize:20];
        self.centerLabel.textColor = [UIColor whiteColor];
        
        CGFloat timeLonger;
        if (self.progressState == LCCKProgressShort) {
            timeLonger = 1;
        } else {
            timeLonger = 0.6;
        }
        [UIView animateWithDuration:timeLonger
                              delay:0
                            options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.alpha = 0;
                         }
                         completion:^(BOOL finished){
                             if(self.alpha == 0) {
                                 [self removeFromSuperview];
                                 
                                 NSMutableArray *windows = [[NSMutableArray alloc] initWithArray:[UIApplication sharedApplication].windows];
                                 [windows removeObject:self.overlayWindow];
                                 
                                 [windows enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIWindow *window, NSUInteger idx, BOOL *stop) {
                                     if([window isKindOfClass:[UIWindow class]] && window.windowLevel == UIWindowLevelNormal) {
                                         [window makeKeyWindow];
                                         *stop = YES;
                                     }
                                 }];
                             }
                         }];
    });
}


#pragma mark - Setters

- (void)setProgressState:(LCCKProgressState)progressState {
    switch (progressState) {
        case LCCKProgressSuccess:
            self.centerLabel.text = @"录音成功";
            break;
        case LCCKProgressShort:
            self.centerLabel.text = @"时间太短,请重试";
            break;
        case LCCKProgressError:
            self.centerLabel.text = @"录音失败";
            break;
        case LCCKProgressMessage:
            break;
    }
    self.centerLabel.font = [UIFont systemFontOfSize:20];
    self.centerLabel.textColor = [UIColor whiteColor];
}


#pragma mark - Getters

//- (NSTimer *)timer{
//    if (_timer) {
//        [_timer invalidate];
//        _timer = nil;
//    }
//    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
//                                               target:self
//                                             selector:@selector(timerAction)
//                                             userInfo:nil
//                                              repeats:YES];
//    return _timer;
//}

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 136, 136)];
        _bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        _bgView.center = CGPointMake([[UIScreen mainScreen] bounds].size.width/2,[[UIScreen mainScreen] bounds].size.height/2);
        _bgView.layer.cornerRadius = 5.0;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

- (UILabel *)centerLabel{
    if (!_centerLabel) {
        _centerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 150, 60)];
        _centerLabel.backgroundColor = [UIColor clearColor];
        _centerLabel
        .center = CGPointMake([self.bgView bounds].size.width/2,[self.bgView bounds].size.height/2-10);
        _centerLabel.text = [NSString stringWithFormat:@"%f",self.countdownTime];
        _centerLabel.textAlignment = NSTextAlignmentCenter;
        _centerLabel.font = [UIFont systemFontOfSize:20];
        _centerLabel.textColor = [UIColor yellowColor];

    }
    return _centerLabel;
}

//- (UIImageView *)edgeImageView {
//    if (!_edgeImageView) {
//        _edgeImageView = [[UIImageView alloc]initWithImage:({
//            NSString *imageName = @"chat_bar_record_circle";
//            UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
//            image;})
//                          ];
//        _edgeImageView.center =  CGPointMake([[UIScreen mainScreen] bounds].size.width/2,[[UIScreen mainScreen] bounds].size.height/2);
//    }
//    return _edgeImageView;
//}
- (UIImageView *)cancleImageView {
    if (!_cancleImageView) {
        _cancleImageView = [[UIImageView alloc]initWithImage:({
            NSString *imageName = @"RecordCancel";
            UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
            image;})
                          ];
        _cancleImageView.center =  CGPointMake([self.bgView bounds].size.width/2,[self.bgView bounds].size.height/2-10);
    }
    return _cancleImageView;
}

- (UIImageView *)volumeImageView {
    if (!_volumeImageView) {
        _volumeImageView = [[UIImageView alloc]initWithImage:({
            NSString *imageName = @"RecordingSignal001";
            UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
            image;})
                            ];
        _volumeImageView.center =  CGPointMake([self.bgView bounds].size.width/2+30,[self.bgView bounds].size.height/2-10);
    }
    return _volumeImageView;
}

- (UIImageView *)soundImageView {
    if (!_soundImageView) {
        _soundImageView = [[UIImageView alloc]initWithImage:({
            NSString *imageName = @"RecordingBkg";
            UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
            image;})
                            ];
        _soundImageView.center =  CGPointMake([self.bgView bounds].size.width/2-14,[self.bgView bounds].size.height/2-10);
    }
    return _soundImageView;
}


- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 20)];
        _titleLabel.center = CGPointMake([self.bgView bounds].size.width/2,[self.bgView bounds].size.height/2 - 30);
        _titleLabel.text = @"录音时间";
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}


- (UILabel *)subTitleLabel{
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 126, 20)];
        _subTitleLabel.center = CGPointMake([self.bgView bounds].size.width/2,[self.bgView bounds].size.height/2 + 48);
        _subTitleLabel.text = @"手指上滑,取消发送";
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
        _subTitleLabel.font = [UIFont boldSystemFontOfSize:14];
        _subTitleLabel.textColor = [UIColor whiteColor];
        _subTitleLabel.layer.cornerRadius = 3.0;
        _subTitleLabel.layer.masksToBounds = YES;
    }
    return _subTitleLabel;
}

- (UIWindow *)overlayWindow {
    if(!_overlayWindow) {
        _overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _overlayWindow.userInteractionEnabled = NO;
        [_overlayWindow makeKeyAndVisible];
    }
    return _overlayWindow;
}

#pragma mark - Class Methods

+ (LCCKProgressHUD *)sharedView {
    static dispatch_once_t once;
    static LCCKProgressHUD *sharedView;
    dispatch_once(&once, ^ {
        sharedView = [[LCCKProgressHUD alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//        sharedView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        sharedView.backgroundColor = [UIColor clearColor];
    });
    return sharedView;
}

+ (void)show {
    [[LCCKProgressHUD sharedView] show];
}

+ (void)dismissWithProgressState:(LCCKProgressState)progressState {
    [[LCCKProgressHUD sharedView] setProgressState:progressState];
    [[LCCKProgressHUD sharedView] dismiss];
}

+ (void)dismissWithMessage:(NSString *)message {
    [[LCCKProgressHUD sharedView] setProgressState:LCCKProgressMessage];
    [LCCKProgressHUD sharedView].centerLabel.text = message;
    [[LCCKProgressHUD sharedView] dismiss];
}

+ (void)changeSubTitle:(NSString *)str
{
    [[LCCKProgressHUD sharedView] setSubTitle:str];
}

+ (NSTimeInterval)seconds{
    return [[LCCKProgressHUD sharedView] seconds] / 10;
}

+ (void)realtimeChangeVolumeImageView:(float)volume timeLength:(NSTimeInterval)timeLength{
    [[LCCKProgressHUD sharedView] changeVolumeImageView:volume timeLength:timeLength];
}

@end
