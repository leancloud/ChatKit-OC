//
//  MJDIYHeader.m
//  MJRefreshExample
//
//  v0.7.0 Created by MJ Lee on 15/6/13.
//  Copyright © 2015年 小码哥. All rights reserved.
//

#import "LCCKConversationRefreshHeader.h"

@interface LCCKConversationRefreshHeader()
@property (nonatomic, strong) UIActivityIndicatorView *loadMoreActivityIndicatorView;
@property (nonatomic, strong) UIView *headerContainerView;
@end

@implementation LCCKConversationRefreshHeader

#pragma mark - 重写方法
#pragma mark 在这里做一些初始化配置（比如添加子控件）

- (void)prepare
{
    [super prepare];
    // 设置控件的高度
    self.mj_h = 50;
    [self addSubview:self.headerContainerView];
}

- (UIView *)headerContainerView {
    if (!_headerContainerView) {
        _headerContainerView = [[UIView alloc] init];
        _headerContainerView.backgroundColor = self.backgroundColor;
#ifdef LCCKDebugging
        _headerContainerView.backgroundColor = [UIColor redColor];
#endif
        [_headerContainerView addSubview:self.loadMoreActivityIndicatorView];
    }
    return _headerContainerView;
}

- (UIActivityIndicatorView *)loadMoreActivityIndicatorView {
    if (!_loadMoreActivityIndicatorView) {
        _loadMoreActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
#ifdef LCCKDebugging
        _loadMoreActivityIndicatorView.backgroundColor = [UIColor blueColor];
#endif
    }
    return _loadMoreActivityIndicatorView;
}

#pragma mark 在这里设置子控件的位置和尺寸
- (void)placeSubviews
{
    [super placeSubviews];
    self.headerContainerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.mj_h);
    self.loadMoreActivityIndicatorView.center = CGPointMake(CGRectGetWidth(_headerContainerView.bounds) / 2.0, CGRectGetHeight(_headerContainerView.bounds) / 2.0);

}

#pragma mark 监听scrollView的contentOffset改变
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change
{
    [super scrollViewContentOffsetDidChange:change];

}

#pragma mark 监听scrollView的contentSize改变
- (void)scrollViewContentSizeDidChange:(NSDictionary *)change
{
    [super scrollViewContentSizeDidChange:change];
    
}

#pragma mark 监听scrollView的拖拽状态改变
- (void)scrollViewPanStateDidChange:(NSDictionary *)change
{
    [super scrollViewPanStateDidChange:change];

}

#pragma mark 监听控件的刷新状态
- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState;
    
    switch (state) {
        case MJRefreshStateIdle:
            
//            if (self.loadMoreActivityIndicatorView.isAnimating) {
//                [self.loadMoreActivityIndicatorView stopAnimating];
//            }
            if (!self.loadMoreActivityIndicatorView.isAnimating) {
                [self.loadMoreActivityIndicatorView startAnimating];
            }
            
            break;

        case MJRefreshStatePulling:
            
//            if (self.loadMoreActivityIndicatorView.isAnimating) {
//                [self.loadMoreActivityIndicatorView stopAnimating];
//            }
            if (!self.loadMoreActivityIndicatorView.isAnimating) {
                [self.loadMoreActivityIndicatorView startAnimating];
            }
            break;

        case MJRefreshStateRefreshing:
            if (!self.loadMoreActivityIndicatorView.isAnimating) {
                [self.loadMoreActivityIndicatorView startAnimating];
            }
            
            break;

            
        default:
            break;
    }
}

#pragma mark 监听拖拽比例（控件被拖出来的比例）
- (void)setPullingPercent:(CGFloat)pullingPercent
{

}

@end
