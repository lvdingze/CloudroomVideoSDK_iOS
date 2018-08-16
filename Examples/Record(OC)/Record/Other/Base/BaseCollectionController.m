//
//  BaseCollectionController.m
//  Record
//
//  Created by king on 2017/6/9.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "BaseCollectionController.h"

@interface BaseCollectionController ()

@end

@implementation BaseCollectionController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForCollection];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 显示导航栏
    if ([self.navigationController isNavigationBarHidden]) {
        [self.navigationController setNavigationBarHidden:NO];
    }
}

- (void)dealloc
{
    RLog(@"%@", [self class]);
}

#pragma mark - private method
- (void)_setupForCollection
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

#pragma mark - override
// 是否支持旋转
- (BOOL)shouldAutorotate
{
    return YES;
}

// 支持的旋转类型
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

// 默认进去的类型
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
