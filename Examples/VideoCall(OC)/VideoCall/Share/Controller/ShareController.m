//
//  ShareController.m
//  VideoCall
//
//  Created by king on 2016/12/15.
//  Copyright © 2016年 CloudRoom. All rights reserved.
//

#import "ShareController.h"
#import "AppDelegate.h"
#import "VideoMgrCallBack.h"
#import "VideoMeetingCallBack.h"
#import "RotationUtil.h"
#import <CloudroomVideoSDK_IOS/CloudroomVideoSDK_IOS.h>

@interface ShareController () <VideoMeetingDelegate, VideoMgrDelegate>

@property (weak, nonatomic) IBOutlet CLShareView *shareImageView; /**< 影音共享视图 */

@end

@implementation ShareController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*
     iOS--OpenGL渲染
     http://blog.csdn.net/little_tan/article/details/44466259
     OpenGL ES画rgb数据代码
     http://www.cocoachina.com/bbs/read.php?tid=79261
     最简单的视音频播放示例5：OpenGL播放RGB/YUV
     http://blog.csdn.net/leixiaohua1020/article/details/40333583
     iOS --- OpenGLES之图片纹理
     http://icetime17.github.io/2016/03/27/2016-03/iOS-OpenGLES%E4%B9%8B%E5%9B%BE%E7%89%87%E7%BA%B9%E7%90%86/
     将像素绘制到屏幕上去
     http://answerhuang.duapp.com/index.php/2013/09/04/pixels-get-onto-the-screen/
     Render To Texture
     http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/
     iOS中位图数据处理
     http://blog.csdn.net/fww330666557/article/details/11904303
     */
    
    [self _setupForShare];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![self.navigationController isNavigationBarHidden]) {
        [self setNeedsStatusBarAppearanceUpdate];
        [self.navigationController setNavigationBarHidden:YES];
    }

    // 不灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // 灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - VideoMeetingDelegate
- (void)videoMeetingCallBackNotifyScreenShareStopped:(VideoMeetingCallBack *)callback
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"屏幕共享已结束!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// 屏幕共享数据更新,用户收到该回调消息后应该调用getShareScreenDecodeImg获取最新的共享数据
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyScreenShareData:(NSString *)userID changedRect:(CGRect)changedRect frameSize:(CGSize)size
{
    ScreenShareImg *shareData = [[CloudroomVideoMeeting shareInstance] getShareScreenDecodeImg];
    
    if(shareData == nil)
    {
        return;
    }
    if (shareData.datLength != 4 * shareData.rgbWidth * shareData.rgbHeight) {
        return;
    }
    
    [self _handleShareData:shareData->rgbDat width:shareData.rgbWidth height:shareData.rgbHeight];
}

#pragma mark - VideoMgrDelegate
// 掉线/被踢通知(无网络会同时触发:lineOff和meetingDropped!!!)
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
        [self _showAlert:@"您已被踢下线!"];
    }
    else { // 掉线
        [self _showAlert:@"您已掉线!"];
    }
}

#pragma mark - private method
/**
 初始化
 */
- (void)_setupForShare
{
    [self _setupForOrientation];
    [self _updateDelegate];
}

/**
 更新设备方向
 */
- (void)_setupForOrientation
{
    if ([RotationUtil isOrientationLandscape]) { // 如果是横屏
        [RotationUtil forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    }
}

/**
 更新代理
 */
- (void)_updateDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
    [appDelegate.videoMeetingCallBack setVideoMeetingDelegate:self];
}

/**
 处理影音共享图像数据

 @param data 图像数据
 @param w 宽
 @param h 高
 */
- (void)_handleShareData:(unsigned char *)data width:(int)w height:(int)h
{
    long size = w * h;
    if (size <= 0) {
        VCLog(@"width or height is 0!");
        return;
    }
    
    unsigned char *rgba = (unsigned char *)malloc(size * 4);
    // BGRA -> RGBA
    for (int i = 0; i < size; i++) {
        rgba[4 * i]  = data[4 * i + 2];
        rgba[4 * i + 1] = data[4 * i + 1];
        rgba[4 * i + 2] = data[4 * i];
        rgba[4 * i + 3] = data[4 * i + 3];
    }
    
    // 构造图像
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(rgba, w, h, 8,4 * w, colorSpace, kCGImageAlphaNoneSkipLast);
    if (!bitmapContext) {
        NSLog(@"位图上下文为空!");
        return;
    }
    
    CGImageRef cgRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage *image = [UIImage imageWithCGImage:cgRef];
    
    if (rgba != NULL) {
        free(rgba);// 释放原始数据
    }
    
    if (data != NULL) {
        free(data);// 释放原始数据
    }
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cgRef);
    CGContextRelease(bitmapContext);
    [_shareImageView setImage:image];
}

- (void)_showAlert:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self _jumpToLogin];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

/**
 跳转到"登录"界面
 */
- (void)_jumpToLogin
{
    VCLog(@"");
    
    // 离开会议
    [[CloudroomVideoMeeting shareInstance] exitMeeting];
    
    // 跳转到"登录"界面
    UIStoryboard *login = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    BaseNavController *loginNav = [login instantiateInitialViewController];
    if (loginNav) {
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:loginNav];
    }
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
    return UIInterfaceOrientationMaskLandscapeRight;
}

// 默认进去的类型
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}
@end
