//
//  XHEmotionCollectionViewCell.m
//  MessageDisplayExample
//
//  Created by qtone-1 on 14-5-3.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import "XHEmotionCollectionViewCell.h"

@interface XHEmotionCollectionViewCell ()

/**
 *  显示表情封面的控件
 */
@property (nonatomic, weak) UIImageView *emotionImageView;

/**
 *  配置默认控件和参数
 */
- (void)setup;
@end

@implementation XHEmotionCollectionViewCell

#pragma setter method

- (void)setEmotion:(XHEmotion *)emotion {
    _emotion = emotion;
    
    // TODO:
    self.emotionImageView.image = emotion.emotionConverPhoto;
}

#pragma mark - Life cycle

- (void)setup {
    if (!_emotionImageView) {
//        UIImageView *emotionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        UIImageView *emotionImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        //emotionImageView.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:emotionImageView];
        self.emotionImageView = emotionImageView;
    }
}

- (void)awakeFromNib {
    [self setup];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.emotionImageView.frame = CGRectMake(0, 0, self.emotionSize.width, self.emotionSize.height);
}

- (void)dealloc {
    self.emotion = nil;
}

@end
