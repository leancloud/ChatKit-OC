//
//  LCCKFacePageView.m
//  LCCKFaceItemExample
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/12.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKFacePageView.h"
#import "LCCKFaceManager.h"
#import "UIImage+LCCKExtension.h"
#import "LCCKConstants.h"

/**
 *  预览表情显示的View
 */
@interface LCCKFacePreviewView : UIView

@property (weak, nonatomic) UIImageView *faceImageView /**< 展示face表情的 */;
@property (weak, nonatomic) UIImageView *backgroundImageView /**< 默认背景 */;

@end

@implementation LCCKFacePreviewView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup{
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:({
        NSString *imageName = @"preview_background";
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
        image;})
                                        ];
    [self addSubview:self.backgroundImageView = backgroundImageView];
    
    UIImageView *faceImageView = [[UIImageView alloc] init];
    [self addSubview:self.faceImageView = faceImageView];
    
    self.bounds = self.backgroundImageView.bounds;
}

/**
 *  修改faceImageView显示的图片
 *
 *  @param image 需要显示的表情图片
 */
- (void)setFaceImage:(UIImage *)image {
    if (self.faceImageView.image == image) {
        return;
    }
    [self.faceImageView setImage:image];
    [self.faceImageView sizeToFit];
    self.faceImageView.center = self.backgroundImageView.center;
    [UIView animateWithDuration:LCCKAnimateDuration animations:^{
        self.faceImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.3, 1.3);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.2 animations:^{
            self.faceImageView.transform = CGAffineTransformIdentity;
        }];
    }];
}

@end

@interface LCCKFacePageView ()

@property (nonatomic, strong) NSMutableArray *imageViews;
@property (nonatomic, strong) LCCKFacePreviewView *facePreviewView;

@end

@implementation LCCKFacePageView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageViews = [NSMutableArray array];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPress];
        self.userInteractionEnabled = YES;
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          [self.facePreviewView removeFromSuperview];
                                                      }];

        [self setup];
    }
    return self;
}

#pragma mark - Private Methods

- (void)setup {
    
    //判断是否需要重新添加所有的imageView
    if (self.imageViews && self.imageViews.count >= self.datas.count) {
        for (UIImageView *imageView in self.imageViews) {
            NSUInteger index = [self.imageViews indexOfObject:imageView];
            imageView.hidden = index >= self.datas.count;
            if (!imageView.hidden) {
                NSDictionary *faceDict = self.datas[index];
                UIImage *faceImage = [LCCKFaceManager faceImageWithFaceID:[faceDict[kFaceIDKey] integerValue]];
                imageView.tag = [faceDict[kFaceIDKey] integerValue];
                imageView.image = faceImage;
            }
        }
    } else {
        //计算每个item的大小
//        CGFloat itemWidth = MIN((self.frame.size.width - 40) / (self.columnsPerRow), self.frame.size.height/2);
        CGFloat itemWidth = (self.frame.size.width - 40) / self.columnsPerRow;
        NSUInteger currentColumn = 0;
        NSUInteger currentRow = 0;
        for (NSDictionary *faceDict in self.datas) {
            if (currentColumn >= self.columnsPerRow) {
                currentRow ++ ;
                currentColumn = 0;
            }
            //计算每一个图片的起始X位置 10(左边距) + 第几列*itemWidth + 第几页*一页的宽度
            CGFloat startX = 20 + currentColumn * itemWidth;
            //计算每一个图片的起始Y位置  第几行*每行高度
            CGFloat startY = currentRow * itemWidth;
            
            UIImageView *imageView = [self faceImageViewWithID:faceDict[kFaceIDKey]];
            [imageView setFrame:CGRectMake(startX, startY, itemWidth, itemWidth)];
            [self addSubview:imageView];
            [self.imageViews addObject:imageView];
            currentColumn ++ ;
        }
    }
}

/**
 *  根据faceID获取一个imageView实例
 *
 *  @param faceID faceID
 *
 *  @return
 */
- (UIImageView *)faceImageViewWithID:(NSString *)faceID{
    
    UIImage *faceImage = [LCCKFaceManager faceImageWithFaceID:[faceID integerValue]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:faceImage];
    imageView.userInteractionEnabled = YES;
    imageView.tag = [faceID integerValue];
    imageView.contentMode = UIViewContentModeCenter;
    
    //添加图片的点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [imageView addGestureRecognizer:tap];
    
    return imageView;
}


/**
 *  根据点击位置获取点击的imageView
 *
 *  @param point 点击的位置
 *
 *  @return 被点击的imageView
 */
- (UIImageView *)faceViewWitnInPoint:(CGPoint)point{
    for (UIImageView *imageView in self.imageViews) {
        if (CGRectContainsPoint(imageView.frame, point)) {
            return imageView;
        }
    }
    return nil;
}

#pragma mark - Response Methods

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectedFaceImageWithFaceID:)]) {
        [self.delegate selectedFaceImageWithFaceID:tap.view.tag];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    CGPoint touchPoint = [longPress locationInView:self];
    CGPoint windowPoint = [longPress locationInView:[UIApplication sharedApplication].keyWindow];
    UIImageView *touchFaceView = [self faceViewWitnInPoint:touchPoint];
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self.facePreviewView setCenter:CGPointMake(windowPoint.x, windowPoint.y - 40)];
        [self.facePreviewView setFaceImage:touchFaceView.image];
        [[UIApplication sharedApplication].keyWindow addSubview:self.facePreviewView];
    } else if (longPress.state == UIGestureRecognizerStateChanged){
        [self.facePreviewView setCenter:CGPointMake(windowPoint.x, windowPoint.y - 40)];
        [self.facePreviewView setFaceImage:touchFaceView.image];
    } else if (longPress.state == UIGestureRecognizerStateEnded) {
        [self.facePreviewView removeFromSuperview];
    }
}

#pragma mark - Getters

- (LCCKFacePreviewView *)facePreviewView {
    if (!_facePreviewView) {
        _facePreviewView = [[LCCKFacePreviewView alloc] initWithFrame:CGRectZero];
    }
    return _facePreviewView;
}

#pragma mark - Setters

- (void)setDatas:(NSArray *)datas {
    _datas = [datas copy];
    [self setup];
}

- (void)setColumnsPerRow:(NSUInteger)columnsPerRow {
    if (_columnsPerRow != columnsPerRow) {
        _columnsPerRow = columnsPerRow;
        [self.imageViews removeAllObjects];
        for (UIView *subView in self.subviews) {
            [subView removeFromSuperview];
        }
    }
}

@end
