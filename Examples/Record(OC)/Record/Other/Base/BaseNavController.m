//
//  BaseNavController.m
//  VideoCall
//
//  Created by king on 2016/11/22.
//  Copyright © 2016年 CloudRoom. All rights reserved.
//

#import "BaseNavController.h"

@interface BaseNavController ()

@end

@implementation BaseNavController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupUIForBaseNav];
}

#pragma mark - private method
- (void)_setupUIForBaseNav
{
    [self _setupForNavBarTheme];
}

#pragma mark - private method
- (void)_setupForNavBarTheme
{
    UINavigationBar *barAppearance = [UINavigationBar appearance];
    NSMutableDictionary *textAttrs = [[NSMutableDictionary alloc] init];
    // 设置 title 颜色
    textAttrs[NSForegroundColorAttributeName] = UIColorFromRGB(0xFFFFFF);
    // 设置 title 字体
    textAttrs[NSFontAttributeName] = [UIFont boldSystemFontOfSize:18];
    [barAppearance setTitleTextAttributes:textAttrs];
    // 设置 item 颜色
    [barAppearance setTintColor:UIColorFromRGB(0xFFFFFF)];
    // 设置 NavBar 背景色
    [barAppearance setBackgroundImage:[UIImage imageNamed:@"navBar_bg"] forBarMetrics:UIBarMetricsDefault];
    // 隐藏 NavBar 底部黑线
    [barAppearance setShadowImage:[[UIImage alloc] init]];
    // NavBar 不透明
    [barAppearance setTranslucent:NO];
}

- (void)setupForBarButtonItemTheme
{
    UIBarButtonItem *barButtomAppearance = [UIBarButtonItem appearance];
    NSMutableDictionary *normaltextAttrs = [[NSMutableDictionary alloc] init];
    // 设置 item 颜色
    normaltextAttrs[NSForegroundColorAttributeName] = UIColorFromRGB(0xFFFFFF);
    // 设置 item 字体
    normaltextAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:16];
    [barButtomAppearance setTitleTextAttributes:normaltextAttrs forState:UIControlStateNormal];
}

#pragma mark - override
- (BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}
@end
