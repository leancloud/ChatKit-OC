//
//  LCCKChatMoreView.m
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/8/18.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatMoreView.h"

#import "LCCKChatMoreItem.h"
#import "Masonry.h"

#define kLCCKTopLineBackgroundColor [UIColor colorWithRed:184/255.0f green:184/255.0f blue:184/255.0f alpha:1.0f]

@interface LCCKChatMoreView ()<UIScrollViewDelegate>

@property (copy, nonatomic) NSArray *titles;
@property (copy, nonatomic) NSArray *imageNames;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) NSMutableArray *itemViews;

@property (assign, nonatomic) CGSize itemSize;

@end

@implementation LCCKChatMoreView

- (instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.pageControl setCurrentPage:scrollView.contentOffset.x / scrollView.frame.size.width];
}

#pragma mark - Public Methods

- (void)reloadData {
    CGFloat width = [UIApplication sharedApplication].keyWindow.frame.size.width;
    CGFloat height = [UIApplication sharedApplication].keyWindow.frame.size.height;
    CGFloat widthLimit = MIN(width, height);
    CGFloat itemWidth = (widthLimit - self.edgeInsets.left - self.edgeInsets.right) / self.numberPerLine;
    CGFloat itemHeight = kFunctionViewHeight / 2;
    self.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    self.titles = [self.dataSource titlesOfMoreView:self];
    self.imageNames = [self.dataSource imageNamesOfMoreView:self];
    
    [self.itemViews makeObjectsPerformSelector:@selector(removeFromSuperview) withObject:nil];
    [self.itemViews removeAllObjects];
    [self setupItems];
}

#pragma mark - Private Methods

- (void)itemClickAction:(LCCKChatMoreItem *)item {
    if (self.delegate && [self.delegate respondsToSelector:@selector(moreView:selectIndex:)]) {
        [self.delegate moreView:self selectIndex:item.tag];
    }
}

- (void)setup {
    UIImageView *topLine = [[UIImageView alloc] init];
    topLine.backgroundColor = kLCCKTopLineBackgroundColor;
    [self addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.and.top.equalTo(self);
        make.height.mas_equalTo(.5f);
    }];
    
    self.edgeInsets = UIEdgeInsetsMake(10, 10, 5, 10);
    self.itemViews = [NSMutableArray array];
    self.numberPerLine = 4;
    
    [self addSubview:self.scrollView];
    [self addSubview:self.pageControl];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self).with.insets(_edgeInsets);
    }];
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.mas_equalTo(self);
        make.bottom.mas_equalTo(self).offset(-10);
    }];
    
    [self updateConstraintsIfNeeded];
    [self layoutIfNeeded];
}

- (void)setupItems {
    __block NSUInteger line = 0;   //行数
    __block NSUInteger column = 0; //列数
    __block NSUInteger page = 0;
    [self.titles enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        if (column > 3) {
            line ++ ;
            column = 0;
        }
        if (line > 1) {
            line = 0;
            column = 0;
            page ++ ;
        }
        CGFloat width = [UIApplication sharedApplication].keyWindow.frame.size.width;
        CGFloat scrollViewWidth = width - self.edgeInsets.left - self.edgeInsets.right;
        CGFloat scrollViewHeight = kFunctionViewHeight - self.edgeInsets.top - self.edgeInsets.bottom;
        CGFloat startX = column * self.itemSize.width + page * scrollViewWidth;
        CGFloat startY = line * self.itemSize.height;
        
        LCCKChatMoreItem *item = [[LCCKChatMoreItem alloc] initWithFrame:CGRectMake(startX, startY, self.itemSize.width, self.itemSize.height)];
        [item fillViewWithTitle:obj imageName:self.imageNames[idx]];
        item.tag = idx;
        [item addTarget:self action:@selector(itemClickAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:item];
        [self.itemViews addObject:item];
        column ++;
        if (idx == self.titles.count - 1) {
            [self.scrollView setContentSize:CGSizeMake(width * (page + 1), scrollViewHeight)];
            self.pageControl.numberOfPages = page + 1;
            *stop = YES;
        }
    }];
}

#pragma mark - Setters

- (void)setDataSource:(id<LCCKChatMoreViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets{
    _edgeInsets = edgeInsets;
    [self reloadData];
}

- (void)setNumberPerLine:(NSUInteger)numberPerLine {
    _numberPerLine = numberPerLine;
    [self reloadData];
}

#pragma mark - Getters

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];//WithFrame:CGRectMake(0, self.frame.size.height - 30, self.frame.size.width, 20)];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
        _pageControl.hidesForSinglePage = YES;
    }
    return _pageControl;
}

@end

