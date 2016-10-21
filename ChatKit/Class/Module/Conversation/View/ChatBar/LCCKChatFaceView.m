//
//  LCCKChatFaceView.m
//  LCCKChatBarExample
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/8/21.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatFaceView.h"
#import "LCCKFaceManager.h"
#import "LCCKSwipeView.h"
#import "LCCKFacePageView.h"
#import "UIImage+LCCKExtension.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif

@interface LCCKChatFaceView ()<UIScrollViewDelegate,LCCKSwipeViewDelegate,LCCKSwipeViewDataSource,LCCKFacePageViewDelegate>

@property (nonatomic, strong) LCCKSwipeView *swipeView;
@property (strong, nonatomic) UIPageControl *pageControl;

@property (strong, nonatomic) UIView *bottomView;
@property (weak, nonatomic) UIButton *sendButton;

@property (weak, nonatomic) UIButton *recentButton /**< 显示最近表情的button */;
@property (weak, nonatomic) UIButton *emojiButton /**< 显示emoji表情Button */;

@property (assign, nonatomic) NSUInteger columnPerRow; /**< 每行显示的表情数量,6,6plus可能相应多显示  默认emoji5s显示7个 最近表情显示4个  gif表情显示4个 */
@property (assign, nonatomic) NSUInteger maxRows; /**< 每页显示的行数 默认emoji3行  最近表情2行  gif表情2行 */
@property (nonatomic, assign ,readonly) NSUInteger itemsPerPage;
@property (nonatomic, assign) NSUInteger pageCount;

@property (nonatomic, strong) NSMutableArray *faceArray;

@end

@implementation LCCKChatFaceView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

#pragma mark - LCCKSwipeViewDelegate & LCCKSwipeViewDataSource

- (UIView *)swipeView:(LCCKSwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    LCCKFacePageView *facePageView = (LCCKFacePageView *)view;
    if (!view) {
        facePageView = [[LCCKFacePageView alloc] initWithFrame:swipeView.frame];
    }
    [facePageView setColumnsPerRow:self.columnPerRow];
    if ((index + 1) * self.itemsPerPage  >= self.faceArray.count) {
        [facePageView setDatas:[self.faceArray subarrayWithRange:NSMakeRange(index * self.itemsPerPage, self.faceArray.count - index * self.itemsPerPage)]];
    } else {
        [facePageView setDatas:[self.faceArray subarrayWithRange:NSMakeRange(index * self.itemsPerPage, self.itemsPerPage)]];
    }
    facePageView.delegate = self;
    return facePageView;
}

- (NSInteger)numberOfItemsInLCCKSwipeView:(LCCKSwipeView *)swipeView {
    return self.pageCount ;
}

- (void)swipeViewCurrentItemIndexDidChange:(LCCKSwipeView *)swipeView {
    self.pageControl.currentPage = swipeView.currentPage;
}

#pragma mark - LCCKFacePageViewDelegate

- (void)selectedFaceImageWithFaceID:(NSUInteger)faceID {
    NSString *faceName = [LCCKFaceManager faceNameWithFaceID:faceID];
    if (faceID != 999) {
        [LCCKFaceManager saveRecentFace:@{
                                          @"face_id" : [NSString stringWithFormat:@"%ld",faceID],
                                          @"face_name" : faceName
                                          }
         ];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(faceViewSendFace:)]) {
        [self.delegate faceViewSendFace:faceName];
    }
}

#pragma mark - Private Methods
- (void)setupConstraints {
//    [super updateConstraints];
    [self.swipeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.width.mas_equalTo(self);
        make.bottom.mas_equalTo(self).offset(-40);
        make.top.mas_equalTo(self);
    }];
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.width.mas_equalTo(self);
        make.bottom.mas_equalTo(self.swipeView.mas_bottom);
        make.height.mas_equalTo(10);
    }];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.width.and.bottom.mas_equalTo(self);
        make.height.mas_equalTo(40);
    }];
}

- (void)setup{
    UIImageView *topLine = [[UIImageView alloc] init];//WithFrame:CGRectMake(0, 0, self.frame.size.width - 70, 1.0f)];
    topLine.backgroundColor = kLCCKTopLineBackgroundColor;
    [self addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.top.and.width.mas_equalTo(self);
        make.height.mas_equalTo(.5f);
    }];

    [self addSubview:self.swipeView];
    [self addSubview:self.pageControl];
    [self addSubview:self.bottomView];
    self.faceArray = [NSMutableArray array];
    self.faceViewType = LCCKShowEmojiFace;
    [self setupFaceView];
    self.userInteractionEnabled = YES;
    [self setupConstraints];
}

- (void)setupFaceView {
    [self.faceArray removeAllObjects];
    if (self.faceViewType == LCCKShowEmojiFace) {
        [self setupEmojiFaces];
    } else if (self.faceViewType == LCCKShowRecentFace){
        [self setupRecentFaces];
    }
    [self.swipeView reloadData];
    
}

/**
 *  初始化最近使用的表情数组
 */
- (void)setupRecentFaces{
    self.maxRows = 2;
    self.columnPerRow = 4;
    self.pageCount = 1;
    [self.faceArray removeAllObjects];
    [self.faceArray addObjectsFromArray:[LCCKFaceManager recentFaces]];
}

/**
 *  初始化所有的emoji表情数组,添加删除按钮
 */
- (void)setupEmojiFaces{
    CGFloat width = [UIApplication sharedApplication].keyWindow.frame.size.width;
    CGFloat height = [UIApplication sharedApplication].keyWindow.frame.size.height;

    self.maxRows =  height > 480 ? 3 : 4;
    self.columnPerRow = width > 320 ? 8 : 7;
    
    //计算每一页最多显示多少个表情  - 1(删除按钮)
    NSInteger pageItemCount = self.itemsPerPage - 1;
    [self.faceArray addObjectsFromArray:[LCCKFaceManager emojiFaces]];
    //获取所有的face表情dict包含face_id,face_name两个key-value
    NSMutableArray *allFaces = [NSMutableArray arrayWithArray:[LCCKFaceManager emojiFaces]];
    
    //计算页数
    self.pageCount = [allFaces count] % pageItemCount == 0 ? [allFaces count] / pageItemCount : ([allFaces count] / pageItemCount) + 1;
    
    //配置pageControl的页数
    self.pageControl.numberOfPages = self.pageCount;
    
    //循环,给每一页末尾加上一个delete图片,如果是最后一页直接在最后一个加上delete图片
    for (int i = 0; i < self.pageCount; i++) {
        if (self.pageCount - 1 == i) {
            [self.faceArray addObject:@{
                                        @"face_id" : @"999",
                                        @"face_name" : @"删除"
                                        }];
        } else {
            [self.faceArray insertObject:@{
                                           @"face_id" : @"999",
                                           @"face_name" : @"删除"
                                           }
                                 atIndex:(i + 1) * pageItemCount + i];
        }
    }
}

- (void)sendAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(faceViewSendFace:)]) {
        [self.delegate faceViewSendFace:@"发送"];
    }
}

- (void)changeFaceType:(UIButton *)button {
    self.faceViewType = button.tag;
    [self setupFaceView];
}

#pragma mark - Setters

- (void)setFaceViewType:(LCCKShowFaceViewType)faceViewType {
    if (_faceViewType != faceViewType) {
        _faceViewType = faceViewType;
        self.emojiButton.selected = _faceViewType == LCCKShowEmojiFace;
        self.recentButton.selected = _faceViewType == LCCKShowRecentFace;
    }
}

#pragma mark - Getters

- (LCCKSwipeView *)swipeView {
    if (!_swipeView) {
        _swipeView = [[LCCKSwipeView alloc] init];
        _swipeView.delegate = self;
        _swipeView.dataSource = self;
    }
    return _swipeView;
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
        _pageControl.hidesForSinglePage = YES;
//        _swipeView.backgroundColor = [UIColor whiteColor];
//        _pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth ;
    }
    return _pageControl;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];//WithFrame:CGRectMake(0, self.frame.size.height - 40, self.frame.size.width, 40)];
//        _bottomView.backgroundColor = [UIColor redColor];
//        _bottomView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        UIImageView *topLine = [[UIImageView alloc] init];//WithFrame:CGRectMake(0, 0, self.frame.size.width - 70, 1.0f)];
        topLine.backgroundColor = kLCCKTopLineBackgroundColor;
        [_bottomView addSubview:topLine];
        [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.and.top.mas_equalTo(_bottomView);
            make.height.mas_equalTo(.5f);
            make.width.mas_equalTo(_bottomView).offset(-70);
        }];
        UIButton *sendButton = [[UIButton alloc] init];//WithFrame:CGRectMake(self.frame.size.width - 70, 0, 70, 40)];
        sendButton.backgroundColor = [UIColor colorWithRed:0.0f/255.0f green:70.0f/255.0f blue:1.0f alpha:1.0f];
        [sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [sendButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:self.sendButton = sendButton];
        [sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.and.bottom.and.right.mas_equalTo(_bottomView);
            make.left.mas_equalTo(_bottomView.mas_right).offset(-70);
        }];
        UIButton *recentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [recentButton setBackgroundImage:[self imageInBundlePathForImageName:@"chat_bar_recent_normal"] forState:UIControlStateNormal];
        [recentButton setBackgroundImage:[self imageInBundlePathForImageName:@"chat_bar_recent_highlight"] forState:UIControlStateHighlighted];
        [recentButton setBackgroundImage:[self imageInBundlePathForImageName:@"chat_bar_recent_highlight"] forState:UIControlStateSelected];
        recentButton.tag = LCCKShowRecentFace;
        [recentButton addTarget:self action:@selector(changeFaceType:) forControlEvents:UIControlEventTouchUpInside];
        [recentButton sizeToFit];
//        [_bottomView addSubview:self.recentButton = recentButton];
//        [recentButton setFrame:CGRectMake(0, _bottomView.frame.size.height/2-recentButton.frame.size.height/2, recentButton.frame.size.width, recentButton.frame.size.height)];
//        [recentButton mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.mas_equalTo(_bottomView);
//            make.centerY.mas_equalTo(_bottomView);
//        }];
        UIButton *emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [emojiButton setBackgroundImage:[self imageInBundlePathForImageName:@"chat_bar_emoji_normal"] forState:UIControlStateNormal];
        [emojiButton setBackgroundImage:[self imageInBundlePathForImageName:@"chat_bar_emoji_highlight"] forState:UIControlStateHighlighted];
        [emojiButton setBackgroundImage:[self imageInBundlePathForImageName:@"chat_bar_emoji_highlight"] forState:UIControlStateSelected];
        emojiButton.tag = LCCKShowEmojiFace;
        [emojiButton addTarget:self action:@selector(changeFaceType:) forControlEvents:UIControlEventTouchUpInside];
        [emojiButton sizeToFit];
        emojiButton.selected = YES;
//        [_bottomView addSubview:self.emojiButton = emojiButton];
//        [emojiButton setFrame:CGRectMake(recentButton.frame.size.width, _bottomView.frame.size.height/2-emojiButton.frame.size.height/2, emojiButton.frame.size.width, emojiButton.frame.size.height)];
//        [emojiButton mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.mas_equalTo(_bottomView);
//            make.centerY.mas_equalTo(_bottomView);
//        }];

    }
    return _bottomView;
}

/**
 *  每一页显示的表情数量 = M每行数量*N行
 */
- (NSUInteger)itemsPerPage {
    return self.maxRows * self.columnPerRow;
}

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    return   ({
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
        image;});
}

@end
