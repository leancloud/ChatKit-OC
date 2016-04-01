//
//  XMChatMoreView.m
//  XMChatBarExample
//
//  Created by shscce on 15/8/18.
//  Copyright (c) 2015年 xmfraker. All rights reserved.
//

#import "XMChatMoreView.h"

#import "XMChatMoreItem.h"

@interface XMChatMoreView ()<UIScrollViewDelegate>

@property (copy, nonatomic) NSArray *titles;
@property (copy, nonatomic) NSArray *imageNames;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) NSMutableArray *itemViews;

@property (assign, nonatomic) CGSize itemSize;

@end

@implementation XMChatMoreView

- (instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self.pageControl setCurrentPage:scrollView.contentOffset.x / scrollView.frame.size.width];
}

#pragma mark - Public Methods

- (void)reloadData{
    
    CGFloat itemWidth = (self.scrollView.frame.size.width - self.edgeInsets.left - self.edgeInsets.right) / self.numberPerLine;
    CGFloat itemHeight = self.scrollView.frame.size.height / 2;
    self.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    self.titles = [self.dataSource titlesOfMoreView:self];
    self.imageNames = [self.dataSource imageNamesOfMoreView:self];
    
    [self.itemViews makeObjectsPerformSelector:@selector(removeFromSuperview) withObject:nil];
    [self.itemViews removeAllObjects];
    [self setupItems];
    
}

#pragma mark - Private Methods


- (void)itemClickAction:(XMChatMoreItem *)item{
    if (self.delegate && [self.delegate respondsToSelector:@selector(moreView:selectIndex:)]) {
        [self.delegate moreView:self selectIndex:item.tag];
    }
}

- (void)setup{

    self.edgeInsets = UIEdgeInsetsMake(10, 10, 5, 10);
    self.itemViews = [NSMutableArray array];
    self.numberPerLine = 4;
    
    [self addSubview:self.scrollView];
    [self addSubview:self.pageControl];

}

- (void)setupItems{
    
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
        
        CGFloat startX = self.edgeInsets.left + column * self.itemSize.width + page * self.frame.size.width;
        CGFloat startY = line * self.itemSize.height;
        
        XMChatMoreItem *item = [[XMChatMoreItem alloc] initWithFrame:CGRectMake(startX, startY, self.itemSize.width, self.itemSize.height)];
        [item fillViewWithTitle:obj imageName:self.imageNames[idx]];
        item.tag = idx;
        [item addTarget:self action:@selector(itemClickAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:item];
        [self.itemViews addObject:item];
        column ++ ;
        
        if (idx == self.titles.count - 1) {
            [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * (page + 1), self.scrollView.frame.size.height)];
            self.pageControl.numberOfPages = page + 1;
            *stop = YES;
        }
        
    }];
}


#pragma mark - Setters

- (void)setDataSource:(id<XMChatMoreViewDataSource>)dataSource{
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets{
    _edgeInsets = edgeInsets;
    [self.scrollView setFrame:CGRectMake(0, self.edgeInsets.top, self.frame.size.width, self.frame.size.height - self.edgeInsets.top - self.edgeInsets.bottom)];
    [self reloadData];
}

- (void)setNumberPerLine:(NSUInteger)numberPerLine{
    _numberPerLine = numberPerLine;
    [self reloadData];
}

#pragma mark - Getters

- (UIScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.edgeInsets.top, self.frame.size.width, self.frame.size.height - self.edgeInsets.top - self.edgeInsets.bottom)];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 30, self.frame.size.width, 20)];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
        _pageControl.hidesForSinglePage = YES;
    }
    return _pageControl;
}

@end
