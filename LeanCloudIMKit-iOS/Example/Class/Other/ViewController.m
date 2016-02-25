//
//  ViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "ViewController.h"
#import "LCIMUser.h"
#import "LCIMKit.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[LCIMKit sharedInstance] userSystemService] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback) {
        NSMutableArray<id<LCIMUserModelDelegate>> *userList = [NSMutableArray array];
        for (NSString *userId in userIds) {
            //MyUser is a subclass of AVUser, conforming to the LCIMUserModelDelegate protocol.
            AVQuery *query = [LCIMUser query];
            NSError *error = nil;
            LCIMUser *object = (LCIMUser *)[query getObjectWithId:userId error:&error];
            if (error == nil) {
                [userList addObject:object];
            } else {
                if (callback) {
                    callback(nil, error);
                    return;
                }
            }
        }
        if (callback) {
            callback(userList, nil);
        }
    }
     ];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

@end