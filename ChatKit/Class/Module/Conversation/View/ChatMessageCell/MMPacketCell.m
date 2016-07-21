//
//  MMPacketCell.m
//  Pods
//
//  Created by lyricdon on 16/7/21.
//
//

#import "MMPacketCell.h"
#import "Masonry.h"

@interface MMPacketCell ()
@property (nonatomic, strong) UIButton *packet;
@end

@implementation MMPacketCell

- (void)setup
{
    [self.messageContentView addSubview:self.packet];
    [super setup];
}

- (void)configureCellWithData:(LCCKMessage *)message
{
    [super configureCellWithData:message];
    [self.packet setTitle:[NSString stringWithFormat:@"%td",message.money] forState:UIControlStateNormal];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"packet" ofType:@"jpg"];
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    [_packet setBackgroundImage:img forState:UIControlStateNormal];
}

- (UIButton *)packet
{
    if (_packet == nil) {
        _packet = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    }
    return _packet;
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    [self.packet mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.messageContentView).with.insets(UIEdgeInsetsMake(8, 16, 8, 16));
    }];
    
}
@end
