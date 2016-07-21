//
//  MMPacketViewController.m
//  ChatKit-OC
//
//  Created by lyricdon on 16/7/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "MMPacketViewController.h"

@interface MMPacketViewController ()

@end

@implementation MMPacketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStylePlain target:self action:@selector(sendLocation)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(110, 100, 100, 50)];
    [btn addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"发送" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(230, 100, 100, 50)];
    [btn2 addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [btn2 setTitle:@"取消" forState:UIControlStateNormal];
    [self.view addSubview:btn2];
}

- (void)send
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendPacket:)])
    {
        [self.delegate sendPacket:200];
    }
}
- (void)cancel
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelPacket)])
    {
        [self.delegate cancelPacket];
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendLocation {
}

@end
