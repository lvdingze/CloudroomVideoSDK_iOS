//
//  PlaybackController.m
//  Record
//
//  Created by king on 2017/8/22.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "PlaybackController.h"
#import "AppDelegate.h"
#import "VideoMgrCallBack.h"
#import "VideoMeetingCallBack.h"

typedef NS_ENUM(NSInteger, PlaybackState)
{
    PBS_init, // 初始化
    PBS_start_playback, // 开始回放
    PBS_stop_playback, // 停止回放
    PBS_playback_complete // 回放完成
};

@interface PlaybackController () <VideoMeetingDelegate, VideoMgrDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet CLMediaView *mediaView; /**< 视频 */
@property (weak, nonatomic) IBOutlet UIView *toolView; /**< 工具栏 */
@property (weak, nonatomic) IBOutlet UIButton *operationBtn; /**< 操作按钮*/
@property (weak, nonatomic) IBOutlet UISlider *slider; /* 进度条 */

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaViewW; /* 视频宽度约束 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaViewH; /* 视频高度约束 */

@property (atomic, assign) BOOL sliderTouch;
@property (atomic, assign) BOOL mediaPlay;

- (IBAction)clickBtnForPlayback:(UIButton *)sender;
- (IBAction)touchSliderForPlayback:(UISlider *)sender;

@end

@implementation PlaybackController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForPlayback];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 更新代理
    [self _updateDelegate];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // 更新UI视图
    [self _pb_updateUIScreen];
}

#pragma mark - UIGestureRecognizerDelegate
/*
 手势之间的影响
 http://www.cocoachina.com/bbs/read.php?tid=244580
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    else {
        return YES;
    }
}

#pragma mark - VideoMeetingDelegate
// 设定播放位置完成
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyPlayPosSetted:(int)setPTS
{
    
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaOpened:(long)totalTime size:(CGSize)picSZ
{
    _slider.maximumValue = totalTime;
    _slider.value = 0;
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaStart:(NSString *)userid
{
    // 更新状态机
    [self _updateWithState:PBS_start_playback];
}

// 影音停止播放的通知
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaStop:(NSString *)userid reason:(MEDIA_STOP_REASON)reason
{
    // 更新状态机
    [self _updateWithState:PBS_playback_complete];
}

// 影音暂停播放的通知
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaPause:(NSString *)userid bPause:(BOOL)bPause
{
    
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMemberMediaData:(NSString *)userid curPos:(int)curPos
{
    @autoreleasepool {
        MediaDataFrame *rawFrame = [[CloudroomVideoMeeting shareInstance] getMediaImg:userid];
        
        if (!rawFrame) {
            RLog(@"rawFrame nil!");
            return;
        }
        
        int length = (int)(rawFrame.datLength);
        if (length <= 0) {
            RLog(@"length equal to 0!");
            return;
        }
        
        int width = rawFrame.w;
        int height = rawFrame.h;
        int sum = width * height;
        
        if (sum <= 0) {
            RLog(@"width or height equal to 0!");
            return;
        }
        
        if (1.5 * sum != length) {
            RLog(@"data.length not equal to width * height * 1.5!");
            return;
        }
        
        // FIXME:在后台OpenGL渲染会发生崩溃
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            [_mediaView displayYUV420pData:rawFrame->buf width:width height:height];
            
            if (rawFrame.ms <= _slider.maximumValue && !_sliderTouch && _mediaPlay) {
                _slider.value = rawFrame.ms;
            }
        }
        
        free(rawFrame->buf);
    }
}

#pragma mark - VideoMgrDelegate
/* 掉线/被踢通知(无网络会同时触发:lineOff和meetingDropped!!!) */
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
        [self _showInfo:@"您已被踢下线!"];
    }
    else { // 掉线
        [self _showInfo:@"您已掉线!"];
    }
}

#pragma mark - selector
- (IBAction)clickBtnForPlayback:(UIButton *)sender
{
    [self _updateWithState:PBS_stop_playback];
}

- (IBAction)touchSliderForPlayback:(UISlider *)sender
{
    RLog(@"");
    
    if (_mediaPlay) {
        // int progress = (int)(sender.value / 1000);
        [[CloudroomVideoMeeting shareInstance] setPlayPos:sender.value];
    }
}

- (void)sliderTouchDown:(UISlider *)slider
{
    RLog(@"");
    _sliderTouch = YES;
}

- (void)sliderTouchDragInside:(UISlider *)slider
{
    RLog(@"");
    _sliderTouch = YES;
}

- (void)sliderTouchUpInside:(UISlider *)slider
{
    RLog(@"");
    _sliderTouch = NO;
}

- (void)sliderTouchCancel:(UISlider *)slider
{
    RLog(@"");
    _sliderTouch = NO;
}

- (void)pb_statusBarOrientationDidChange:(NSNotification *)notification
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

/**
 设置视图显示/隐藏
 */
- (void)showOrDismissToolView
{
    [UIView animateWithDuration:0.25 animations:^{
        [_toolView setAlpha:_toolView.alpha == 1 ? 0 : 1];
    }];
}

#pragma mark - private method
/* 初始化 */
- (void)_setupForPlayback
{
    // 设置属性
    [self _setupForProperies];
    // 注册通知
    [self _setupForNotification];
    // 更新代理
    [self _updateDelegate];
    // 更新状态机
    [self _updateWithState:PBS_init];
}

/* 设置属性 */
- (void)_setupForProperies
{
    [_slider setValue:0];
    [_slider setContinuous:NO];
    [_slider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_slider addTarget:self action:@selector(sliderTouchDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [_slider addTarget:self action:@selector(sliderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_slider addTarget:self action:@selector(sliderTouchCancel:) forControlEvents:UIControlEventTouchCancel];
    
    _sliderTouch = NO;
    
    [_operationBtn.layer setCornerRadius:4];
    [_operationBtn.layer masksToBounds];
    
    UITapGestureRecognizer *mediaTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrDismissToolView)];
    [mediaTap setDelegate:self];
    [self.view addGestureRecognizer:mediaTap];
    
    [_toolView setAlpha:0];
}

/* 注册通知 */
- (void)_setupForNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pb_statusBarOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

/* 更新代理 */
- (void)_updateDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
    [appDelegate.videoMeetingCallBack setVideoMeetingDelegate:self];
}

/* 状态机 */
- (void)_updateWithState:(PlaybackState)state
{
    switch (state) {
        case PBS_init: { // 初始化
            [_mediaView setHidden:YES];
            
            [_operationBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            [_operationBtn setEnabled:NO];
            
            _mediaPlay = NO;
            
            // 回放操作
            [self _startToPlayback];
            
            break;
        }
        case PBS_start_playback: { // 开始回放
            [_mediaView setHidden:NO];
            
            [_operationBtn setBackgroundColor:UIColorFromRGB(0xFE6715)];
            [_operationBtn setEnabled:YES];
            
            _mediaPlay = YES;
            
            break;
        }
        case PBS_stop_playback: { // 停止回放
            [_mediaView setHidden:YES];
            
            [_operationBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            [_operationBtn setEnabled:NO];
            
            _mediaPlay = YES;
            
            // 停止回放操作
            [self _stopToPlayback];
            
            break;
        }
        case PBS_playback_complete: { // 回放完成
            [_mediaView setHidden:YES];
            
            [_operationBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            [_operationBtn setEnabled:NO];
            
            _mediaPlay = NO;
            
            // 退出操作
            [self _handleExit];
            
            break;
        }
            
        default: break;
    }
}

/* 开始回放 */
- (void)_startToPlayback
{
    RLog(@"");
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    RecCfg *recCfg = [cloudroomVideoMeeting getRecCfg];
    NSString *videoPath = [recCfg.filePathName lastPathComponent];
    NSParameterAssert(videoPath && videoPath.length > 0);
    // TODO:回放只需要文件名+后缀
    [cloudroomVideoMeeting playbackRecordFile:videoPath];
}

/* 结束回放 */
- (void)_stopToPlayback
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    [cloudroomVideoMeeting stopPlayMedia];
}

- (void)_handleExit
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_pb_updateUIScreen
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) { // iPad
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown: { // 竖屏
                [_mediaViewW setConstant:0];
                CGFloat margin = self.view.bounds.size.height - self.view.bounds.size.width * 9 / 16;
                [_mediaViewH setConstant:-margin];
                break;
            }
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight: { // 横屏
                [_mediaViewW setConstant:0];
                [_mediaViewH setConstant:0];
                break;
            }
            default: break;
        }
    }
}

- (void)_showInfo:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self _jumpToLogin];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

/* 跳转到"登录"界面 */
- (void)_jumpToLogin
{
    RLog(@"");
    
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
/*
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (![[[touches anyObject] view] isEqual:_toolView]) {
        [self showOrDismissToolView];
    }
}
 */

// 是否支持旋转
- (BOOL)shouldAutorotate
{
    return YES;
}

// 支持的旋转类型
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

// 默认进去的类型
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}
@end
