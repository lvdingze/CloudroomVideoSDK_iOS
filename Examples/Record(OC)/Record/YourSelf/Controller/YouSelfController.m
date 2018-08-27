//
//  YouSelfController.m
//  Record
//
//  Created by king on 2017/8/15.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "YouSelfController.h"
#import "BaseNavController.h"
#import "PlaybackController.h"
#import "UploadController.h"
#import "RecordHelper.h"
#import "VideoMgrCallBack.h"
#import "VideoMeetingCallBack.h"
#import "FileMgrCallBack.h"
#import "MoreBtn.h"
#import "AppDelegate.h"
#import "RotationUtil.h"
#import "NSString+JKSize.h"
#import "NSTimer+JKBlocks.h"
#import "PathUtil.h"

/* 按钮类型 */
typedef NS_ENUM(NSInteger, YourSelfBtnType)
{
    YSBT_exit = 1, // 退出系统
    YSBT_complete, // 朗读完毕
    YSBT_clear, // 清除签名
    YSBT_done, // 确认签名
    YSBT_playback, // 回放
    YSBT_upload, // 上传
    YSBT_redo // 重录
};

/* 状态机 */
typedef NS_ENUM(NSInteger, YouSelfState)
{
    YSS_init, // 初始化
    YSS_start_recording, // 开始录制
    YSS_start_playing, // 开始播放视频
    YSS_stop_playing, // 结束播放视频
    YSS_signing, // 签名
    YSS_stop_recording, // 结束录制
    YSS_show_more, // 更多
    YSS_playback, // 回放
    YSS_upload, // 上传
    YSS_exit // 退出系统
};

@interface YouSelfController () <VideoMeetingDelegate, VideoMgrDelegate, BKBrushViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel; /**< 标题 */
@property (weak, nonatomic) IBOutlet CLMediaView *mediaView; /**< 影音 */
@property (weak, nonatomic) IBOutlet CLCameraFloatView *myView; /**< 我的 */
@property (weak, nonatomic) IBOutlet UIView *readView;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@property (weak, nonatomic) IBOutlet UIView *signContent; /**< 签名 */
@property (weak, nonatomic) IBOutlet UIView *signPH;
@property (weak, nonatomic) IBOutlet CLBrushView *signView;

@property (weak, nonatomic) IBOutlet UIView *toolView; /**< 工具栏 */
@property (weak, nonatomic) IBOutlet UIButton *toolExitBtn; /**< 退出系统 */
@property (weak, nonatomic) IBOutlet UIButton *completeBtn; /**< 朗读完毕 */

@property (weak, nonatomic) IBOutlet UIView *moreView; /* 更多 */
@property (weak, nonatomic) IBOutlet UIImageView *bg; /* 背景图片 */
@property (weak, nonatomic) IBOutlet MoreBtn *playbackBtn; /**< 回放 */
@property (weak, nonatomic) IBOutlet MoreBtn *uploadBtn; /**< 上传 */
@property (weak, nonatomic) IBOutlet MoreBtn *redoBtn; /**< 重录 */
@property (weak, nonatomic) IBOutlet UIButton *moreExitBtn; /**< 退出系统 */

/* 约束 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *myViewH;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *myViewW;

@property (nonatomic, assign) BOOL isRead; /**< 正在朗读? */
@property (nonatomic, assign) BOOL isSign; /**< 正在签名? */
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIAlertController *dropVC;

- (IBAction)clickBtnForYourself:(UIButton *)sender;

@end

@implementation YouSelfController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForYourself];
    //设置视频是否支持拖动
//    [self.myView setUserInteractionEnabled:false];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![self.navigationController isNavigationBarHidden]) { // 隐藏导航栏
        [self setNeedsStatusBarAppearanceUpdate];
        [self.navigationController setNavigationBarHidden:YES];
    }
    
    // 不灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // 更新代理
    [self _updateDelegate];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // 更新UI视图
    [self _ys_updateUIScreen];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // 灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)dealloc
{
    // 清屏
    if (_myView) {
        [_myView clearFrame];
    }
    
    if (_mediaView) {
        [_mediaView clearFrame];
    }
    
    // 强制竖屏
    [self _updateOrientation];
    
    [self _stopTimer];
}

#pragma mark - VideoMeetingDelegate
/* 入会结果(入会失败,将自动发起releaseCall) */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback enterMeetingRslt:(CRVIDEOSDK_ERR_DEF)code
{
    [HUDUtil hudHiddenProgress:YES];
    
    if (code == CRVIDEOSDK_NOERR) { // 进入会话成功
        [self _enterMeetingSuccess];
    }
    else if (code == CRVIDEOSDK_MEETNOTEXIST) { // 会议不存在或已结束
        [self _showAlert:@"会议不存在或已结束"];
    }
    else { // 进入会话失败
        [self _enterMeetingFail:@"启动视频会话失败,是否重试?"];
    }
}

/* 结束会议 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback stopMeetingRslt:(CRVIDEOSDK_ERR_DEF)code
{
    
}

/* 会议被结束 */
- (void)videoMeetingCallBackMeetingStopped:(VideoMeetingCallBack *)callback
{
    // 更新状态机
    [self _updateWithState:YSS_exit];
}

/* 会议掉线 */
- (void)videoMeetingCallBackMeetingDropped:(VideoMeetingCallBack *)callback
{
    [self _enterMeetingFail:@"会话掉线,是否重试?"];
}

/* 用户进入会议 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback userEnterMeeting:(NSString *)userID
{
    [self _setDefaultCamera];
    [self _subscribleCamera];
}

/* 音频设备状态变化 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback audioStatusChanged:(NSString *)userID oldStatus:(AUDIO_STATUS)oldStatus newStatus:(AUDIO_STATUS)newStatus
{
    
}

/* 视频设备状态变化 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback videoStatusChanged:(NSString *)userID oldStatus:(VIDEO_STATUS)oldStatus newStatus:(VIDEO_STATUS)newStatus
{
    [self _setDefaultCamera];
    [self _subscribleCamera];
}

/* 本地音频设备有变化 */
- (void)videoMeetingCallBackAudioDevChanged:(VideoMeetingCallBack *)callback
{
    
}

/* 本地视频设备有变化 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback videoDevChanged:(NSString *)userID
{
    [self _setDefaultCamera];
    [self _subscribleCamera];
}

/* 成员有新的视频图像数据到来(通过GetVideoImg获取) */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyVideoData:(UsrVideoId *)userID frameTime:(long)frameTime
{
    @autoreleasepool {
        if ([userID.userId isEqualToString:[[CloudroomVideoMeeting shareInstance] getMyUserID]]) {
            VideoFrame *rawFrame = [[CloudroomVideoMeeting shareInstance] getVideoImg:userID];
            if (!rawFrame) {
                RLog(@"rawFrame nil!");
                return;
            }
            
            int length = (int)(rawFrame.datLength);
            if (length <= 0) {
                RLog(@"length equal to 0!");
                return;
            }
            
            int width = rawFrame.frameWidth;
            int height = rawFrame.frameHeight;
            int sum = width * height;
            
            if (sum <= 0) {
                RLog(@"width or height equal to 0!");
                return;
            }
            
            if (1.5 * sum != length) {
                RLog(@"data.length not equal to width * height * 1.5!");
                return;
            }
            
            if (rawFrame.fmt != VFMT_YUV420P) {
                RLog(@"get VFMT_YUV420P error!");
                return;
            }
            
            // OpenGL ES -> render YUV
            // FIXME:在后台OpenGL渲染会发生崩溃
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
                if ([[[CloudroomVideoMeeting shareInstance] getMyUserID] isEqualToString:userID.userId]) {
                    /*
                     EXC_BAD_ACCESS with glTexImage2D in GLKViewController
                     https://stackoverflow.com/questions/26082262/exc-bad-access-with-glteximage2d-in-glkviewcontroller
                     */
                    [_myView displayYUV420pData:rawFrame->dat width:width height:height];
                }
            }
            
            free(rawFrame->dat);
        }
    }
}

/* 影音开始 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaStart:(NSString *)userid
{
    // 更新状态机
    [self _updateWithState:YSS_start_playing];
}

/* 影音停止 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaStop:(NSString *)userid reason:(MEDIA_STOP_REASON)reason
{
    // 更新状态机
    [self _updateWithState:YSS_stop_playing];
}

/* 影音暂停 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaPause:(NSString *)userid bPause:(BOOL)bPause
{
    
}

/* 影音数据 */
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
        }
        
        free(rawFrame->buf);
    }
}

/* 本地播放成功 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaOpened:(long)totalTime size:(CGSize)picSZ
{
    
}

/* 设定播放位置完成 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyPlayPosSetted:(int)setPTS
{
    
}

/* 录制过程状态改变 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback recordStateChanged:(REC_STATE)state
{
    if (state == STOPPING) {
        [HUDUtil hudHiddenProgress:YES];
    }
}

#pragma mark - VideoMgrDelegate
/* 掉线/被踢通知(无网络会同时触发:lineOff和meetingDropped!!!) */
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    if (_dropVC) {
        [_dropVC dismissViewControllerAnimated:NO completion:^{
            _dropVC = nil;
            
            if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
                [self _showInfo:@"您已被踢下线!"];
            }
            else { // 掉线
                [self _showInfo:@"您已掉线!"];
            }
        }];
        return;
    }
    
    if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
        [self _showInfo:@"您已被踢下线!"];
    }
    else { // 掉线
        [self _showInfo:@"您已掉线!"];
    }
}

/* 服务端通知呼叫被结束 */
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback notifyCallHungup:(NSString *)callID usrExtDat:(NSString *)usrExtDat
{
    // FIXME:挂断(被动),iOS端再次排队入会卡死
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"对方已挂断!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 更新状态机
        [self _updateWithState:YSS_exit];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

/* 拆除呼叫 */
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback hangupCallSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    // FIXME:挂断(主动),会议仍有声音
    [[CloudroomVideoMeeting shareInstance] exitMeeting];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/* 挂断失败 */
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback hangupCallFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // 更新状态机
    [self _updateWithState:YSS_exit];
}

#pragma mark - BKBrushViewDelegate
// FIXME: 签名录制不连贯(king 20180614)
- (void)brushView:(CLBrushView *)brushView touchMovedWithImage:(UIImage *)image {
    // 设置签名资源
    [self _setPicResource:@"signature" image:image];
    
    // 更新录制布局操作
    [self _updateRecLayout];
}

- (void)brushView:(CLBrushView *)brushView touchEndWithImage:(UIImage *)image
{
    // 设置签名资源
    [self _setPicResource:@"signature" view:brushView];
    // [self _setPicResource:@"signature" image:image];
    
    // 更新录制布局操作
    [self _updateRecLayout];
}

#pragma mark - selector
/* 按钮响应 */
- (IBAction)clickBtnForYourself:(UIButton *)sender
{
    NSInteger tag = [sender tag];
    switch (tag) {
        case YSBT_exit: { // 退出系统
            [self _handleExit];
            
            break;
        }
        case YSBT_complete: { // 朗读完毕
            [self _handleComplete];
            
            break;
        }
        case YSBT_clear: { // 清除签名
            [self _handleClear];
            
            break;
        }
        case YSBT_done: { // 确认签名
            [self _handleDone];
            
            break;
        }
        case YSBT_playback: { // 回放
            [self _handlePlayback];
            
            break;
        }
        case YSBT_upload: { // 上传
            [self _handleUpload];
            
            break;
        }
        case YSBT_redo: { // 重录
            [self _handleRedo];
            
            break;
        }
        default: break;
    }
}

/* 状态栏方向发生改变 */
- (void)ys_statusBarOrientationDidChange:(NSNotification *)notification
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationUnknown: {
            RLog(@"statusBar===>UIInterfaceOrientationUnknown");
            break;
        }
        case UIInterfaceOrientationPortrait: {
            RLog(@"statusBar===>UIInterfaceOrientationPortrait");
            break;
        }
        case UIInterfaceOrientationPortraitUpsideDown: {
            RLog(@"statusBar===>UIInterfaceOrientationPortraitUpsideDown");
            break;
        }
        case UIInterfaceOrientationLandscapeLeft: {
            
            RLog(@"statusBar===>UIInterfaceOrientationLandscapeLeft");
            break;
        }
        case UIInterfaceOrientationLandscapeRight: {
            RLog(@"statusBar===>UIInterfaceOrientationLandscapeRight");
            break;
        }
        default: break;
    }
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

/* 工具栏显示/隐藏 */
- (void)showOrDismissToolView
{
    [UIView animateWithDuration:0.25 animations:^{
        [_toolView setAlpha:_toolView.alpha == 1 ? 0 : 1];
    }];
}

#pragma mark - private method
/* 初始化 */
- (void)_setupForYourself
{
    // 设置属性
    [self _setupPropries];
    // 设置通知
    [self _setupForNotification];
    // 更新代理
    [self _updateDelegate];
    // 更新状态机
    [self _updateWithState:YSS_init];
}

/* 设置属性 */
- (void)_setupPropries
{
    // 退出系统(工具栏)
    [_toolExitBtn setBackgroundColor:UIColorFromRGB(0xFE6715)];
    [_toolExitBtn.layer setCornerRadius:4];
    [_toolExitBtn.layer masksToBounds];
    
    // 朗读完毕
    [_completeBtn.layer setCornerRadius:4];
    [_completeBtn.layer masksToBounds];
    
    // 回放
    [_playbackBtn.layer setCornerRadius:4];
    [_playbackBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_playbackBtn.layer setBorderWidth:1.0];
    [_playbackBtn.layer masksToBounds];
    
    // 上传
    [_uploadBtn.layer setCornerRadius:4];
    [_uploadBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_uploadBtn.layer setBorderWidth:1.0];
    [_uploadBtn.layer masksToBounds];
    
    // 重录
    [_redoBtn.layer setCornerRadius:4];
    [_redoBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_redoBtn.layer setBorderWidth:1.0];
    [_redoBtn.layer masksToBounds];
    
    // 退出系统(更多)
    [_moreExitBtn setBackgroundColor:UIColorFromRGB(0xFE6715)];
    [_moreExitBtn.layer setCornerRadius:4];
    [_moreExitBtn.layer masksToBounds];
    
    // 工具栏手势
    UITapGestureRecognizer *mediaTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrDismissToolView)];
    [self.view addGestureRecognizer:mediaTap];
    
    // 签名
    _signView.backgroundColor = [UIColor whiteColor];
    _signView.brushColor = [UIColor redColor];
    // FIXME: 录制签名字体发虚(king 20180613)
    _signView.brushWidth = 6;
    _signView.shapeType = ST_curve;
    _signView.delegate = self;
    [_signPH.layer setBorderColor:UIColorFromRGB(0x000000).CGColor];
    [_signPH.layer setBorderWidth:1.0];
    [_signPH.layer masksToBounds];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[PathUtil searchPathInCacheDir:@"CloudroomVideoSDK/read.jpg"]];
    // 设置"风险提示"图片
    [_image setImage:image];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
}

/* 注册通知 */
- (void)_setupForNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ys_statusBarOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (statusBarOrientation) {
        case UIInterfaceOrientationUnknown: {
            RLog(@"default statusBar===>UIInterfaceOrientationUnknown");
            break;
        }
        case UIInterfaceOrientationPortrait: {
            RLog(@"default statusBar===>UIInterfaceOrientationPortrait");
            break;
        }
        case UIInterfaceOrientationPortraitUpsideDown: {
            RLog(@"default statusBar===>UIInterfaceOrientationPortraitUpsideDown");
            break;
        }
        case UIInterfaceOrientationLandscapeLeft: {
            RLog(@"default statusBar===>UIInterfaceOrientationLandscapeLeft");
            break;
        }
        case UIInterfaceOrientationLandscapeRight: {
            RLog(@"default statusBar===>UIInterfaceOrientationLandscapeRight");
            break;
        }
        default: break;
    }
}

/* 状态机 */
- (void)_updateWithState:(YouSelfState)state
{
    switch (state) {
        case YSS_init: { // 初始化
            [_titleLabel setHidden:YES];
            [_myView setHidden:YES];
            [_mediaView setHidden:YES];
            [_readView setHidden:YES];
            [_toolView setHidden:YES];
            [_signContent setHidden:YES];
            [_moreView setHidden:YES];
            
            [_toolView setAlpha:0];
            
            [_toolExitBtn setEnabled:NO];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = NO;
            _isSign = NO;
            
            // 入会操作
            [self _enterMeeting];
        
            break;
        }
        case YSS_start_recording: { // 开始录制
            [_titleLabel setHidden:NO];
            [_myView setHidden:NO];
            [_mediaView setHidden:YES];
            [_readView setHidden:YES];
            [_toolView setHidden:NO];
            [_signContent setHidden:YES];
            [_moreView setHidden:YES];
            
            [_toolExitBtn setEnabled:YES];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = NO;
            _isSign = NO;
            
            // 设置录制状态
            [_titleLabel setText:@"录制中..."];
            
            // 停止录制
            [self _stopRecording];
            
            // 延迟录制操作
            [self performSelector:@selector(_startToRecord) withObject:nil afterDelay:3];
            
            break;
        }
        case YSS_start_playing: { // 开始播放视频
            [_titleLabel setHidden:NO];
            [_myView setHidden:NO];
            [_mediaView setHidden:NO];
            [_readView setHidden:YES];
            [_toolView setHidden:NO];
            [_signContent setHidden:YES];
            [_moreView setHidden:YES];
            
            [_toolExitBtn setEnabled:YES];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = NO;
            _isSign = NO;
            
            // 设置录制状态
            [_titleLabel setText:@"录制中..."];
            
            // 更新录制布局操作
            [self _updateRecLayout];
            
            // 播放操作
            [self _playLocalMedia];
            
            break;
        }
        case YSS_stop_playing: { // 结束播放视频
            [_titleLabel setHidden:NO];
            [_myView setHidden:NO];
            [_mediaView setHidden:YES];
            
            [_readView setHidden:NO];
            [_toolView setHidden:NO];
            [_signContent setHidden:YES];
            [_moreView setHidden:YES];
            
            [_toolExitBtn setEnabled:YES];
            [_completeBtn setEnabled:YES];
            [_completeBtn setBackgroundColor:UIColorFromRGB(0xFE6715)];
            
            _isRead = YES;
            _isSign = NO;
            
            // 设置录制状态
            [_titleLabel setText:@"录制中..."];
            
            // 设置朗读文本
            [self _setPicResource:@"statement" view:_readView];
            
            // 更新录制布局操作
            [self _updateRecLayout];
            
            break;
        }
        case YSS_signing: { // 签名
            [_titleLabel setHidden:YES];
            [_myView setHidden:YES];
            [_mediaView setHidden:YES];
            [_readView setHidden:YES];
            [_toolView setHidden:YES];
            [_signContent setHidden:NO];
            [_moreView setHidden:YES];
            
            [_toolExitBtn setEnabled:NO];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = YES;
            _isSign = YES;
            
            break;
        }
        case YSS_stop_recording: { // 结束录制
            [_titleLabel setHidden:YES];
            [_myView setHidden:YES];
            [_mediaView setHidden:YES];
            [_readView setHidden:YES];
            [_toolView setHidden:YES];
            [_signContent setHidden:YES];
            [_moreView setHidden:YES];
            
            [_toolExitBtn setEnabled:NO];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = NO;
            _isSign = NO;
            
            // 停录操作
            [HUDUtil hudShowProgress:@"正在生成录制文件" animated:YES];
            // FIXME:延时操作.否则最后几帧录制不进去
            [self performSelector:@selector(_stopRecording) withObject:nil afterDelay:2];
            
            // 更新状态机
            [self _updateWithState:YSS_show_more];
            
            break;
        }
        case YSS_show_more: { // 更多
            [_titleLabel setHidden:YES];
            [_myView setHidden:YES];
            [_mediaView setHidden:YES];
            [_readView setHidden:YES];
            [_toolView setHidden:YES];
            [_signContent setHidden:YES];
            [_moreView setHidden:NO];
            
            [_toolExitBtn setEnabled:NO];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = NO;
            _isSign = NO;
            
            // 清除签名操作
            [self _handleClear];
            
            break;
        }
        case YSS_playback: { // 回放
            [_titleLabel setHidden:YES];
            [_myView setHidden:YES];
            [_mediaView setHidden:YES];
            [_readView setHidden:YES];
            [_toolView setHidden:YES];
            [_signContent setHidden:YES];
            [_moreView setHidden:NO];
            
            [_toolExitBtn setEnabled:NO];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = NO;
            _isSign = NO;
            
            // 跳转操作
            [self _jumpToPlayback];
            
            break;
        }
        case YSS_upload: { // 上传
            [_titleLabel setHidden:YES];
            [_myView setHidden:YES];
            [_mediaView setHidden:YES];
            [_readView setHidden:YES];
            [_toolView setHidden:YES];
            [_signContent setHidden:YES];
            [_moreView setHidden:NO];
            
            [_toolExitBtn setEnabled:NO];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = NO;
            _isSign = NO;
            
            // 跳转操作
            [self _jumpToUpload];
            
            break;
        }
        case YSS_exit: { // 退出系统
            [_titleLabel setHidden:YES];
            [_myView setHidden:YES];
            [_mediaView setHidden:YES];
            [_readView setHidden:YES];
            [_toolView setHidden:YES];
            [_signContent setHidden:YES];
            [_moreView setHidden:YES];
            
            [_toolExitBtn setEnabled:NO];
            [_completeBtn setEnabled:NO];
            
            [_completeBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
            
            _isRead = NO;
            _isSign = NO;
            
            // 退出操作
            [self _stopTimer];
            [self _exitMeeting];
            
            break;
        }
        default: break;
    }
}

/* 初始化摄像头 */
- (void)_setDefaultCamera
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    NSMutableArray <UsrVideoInfo *> *videoes = [cloudroomVideoMeeting getAllVideoInfo:myUserID];
    NSArray<UsrVideoInfo *> *cameraArray = [videoes copy];
    
    for (UsrVideoInfo *video in videoes) {
        RLog(@"userId:%@ videoName:%@ videoID:%d", video.userId, video.videoName, video.videoID);
        
        if (video.videoID == 2) {
            [cloudroomVideoMeeting setDefaultVideo:myUserID videoID:video.videoID];
        }
    }
    
    if ([cameraArray count] <= 0) {
        RLog(@"获取摄像头设备为空!");
    }
}

/* 设置默认分辨率(848*480) */
- (void)_setDefaultRatio
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [cloudroomVideoMeeting getVideoCfg];
    // 设置分辨率
    [vCfg setSizeType:VSIZE_SZ_480];
    // 设置码率
    // FIXME:切720 1080马赛克严重
    [vCfg setMaxbps:-1];
    [cloudroomVideoMeeting setVideoCfg:vCfg];
}

/* 设置默认优先级(画质优先) */
- (void)_setDefaultPriority
{
    /* 画质优先 */
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [videoMeeting getVideoCfg];
    [vCfg setMinQuality:22];
    [vCfg setMaxQuality:25];
    [videoMeeting setVideoCfg:vCfg];
}

/* 设置默认宽高比(16:9) */
- (void)_setDefaultWHRate
{
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [videoMeeting getVideoCfg];
    vCfg.whRate = WHRATE_16_9;
    [videoMeeting setVideoCfg:vCfg];
}

/* 更新代理 */
- (void)_updateDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
    [appDelegate.videoMeetingCallBack setVideoMeetingDelegate:self];
}

/* 更新设备方向 */
- (void)_updateOrientation
{
    if ([RotationUtil isOrientationLandscape]) { // 如果是横屏
        [RotationUtil forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    }
    else {
        [RotationUtil forceOrientation:(UIInterfaceOrientationLandscapeRight)]; // 否则，切换为横屏
    }
}

/* 更新UI视图 */
- (void)_ys_updateUIScreen
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown: { // 竖屏
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) { // iPad
                [_myViewW setConstant:90];
                [_myViewH setConstant:160];
            }
            
            if (![_moreView isHidden]) {
                [_bg setImage:[UIImage imageNamed:@"record_bg_p"]];
            }
            
            _signView.brushWidth = 6;
            
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight: { // 横屏
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) { // iPad
                [_myViewW setConstant:160];
                [_myViewH setConstant:90];
                
                CGFloat margin = (([UIScreen mainScreen].bounds.size.width - 8)) / ([UIScreen mainScreen].bounds.size.height - 8);
                _signView.brushWidth = 6 * margin;
            }
            else {
                CGFloat margin = (([UIScreen mainScreen].bounds.size.width - 240)) / ([UIScreen mainScreen].bounds.size.height - 8);
                _signView.brushWidth = 6 * margin;
            }
            
            if (![_moreView isHidden]) {
                [_bg setImage:[UIImage imageNamed:@"record_bg_h"]];
            }
            
            break;
        }
        default: break;
    }
    
    // 更新录制布局操作
    [self _updateRecLayout];
}

/* 入会 */
- (void)_enterMeeting
{
    [HUDUtil hudShowProgress:@"正在进入会话..." animated:YES];
    // 发送"入会"命令
    NSString *nickname = [[RecordHelper shareInstance] nickname];
    [[CloudroomVideoMeeting shareInstance] enterMeeting:_meetInfo.ID pswd:_meetInfo.pswd userID:nickname nikeName:nickname];
}

/* 入会成功 */
- (void)_enterMeetingSuccess
{
    // [HUDUtil hudShow:@"成功进入会话" delay:3 animated:YES];
    
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    // 自己的麦克风/扬声器
    [cloudroomVideoMeeting openMic:myUserID];
    [cloudroomVideoMeeting setMicVolume:100];
    [cloudroomVideoMeeting setSpeakerVolume:100];
    
    // 自己的摄像头
    [cloudroomVideoMeeting openVideo:myUserID];
    [self _setDefaultCamera];
    [self _subscribleCamera];
    
    // 设置默认分辨率
    [self _setDefaultRatio];
    
    // 设置默认优先级
    [self _setDefaultPriority];
    
    // 设置默认宽高比
    [self _setDefaultWHRate];
    
    // 录制操作
    [self _updateWithState:YSS_start_recording];
}

/* 入会失败 */
- (void)_enterMeetingFail:(NSString *)message
{
    if (_meetInfo.ID > 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            // 更新状态机
            [self _updateWithState:YSS_exit];
            _dropVC = nil;
        }];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[CloudroomVideoMeeting shareInstance] exitMeeting];
            // 更新状态机
            [self _updateWithState:YSS_init];
            _dropVC = nil;
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:NO completion:nil];
        _dropVC = alertController;
    }
}

- (void)_showAlert:(NSString *)message
{
    if (_meetInfo.ID > 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            // 更新状态机
            [self _updateWithState:YSS_exit];
        }];
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:NO completion:nil];
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

/* 订阅摄像头 */
- (void)_subscribleCamera
{
    RLog(@"");
    
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    NSMutableArray <UsrVideoId *> *videos = [videoMeeting getWatchableVideos];
    [videoMeeting watchVideos:videos];
}

/* 取消订阅摄像头 */
- (void)_unsubscribleCamera
{
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    [videoMeeting watchVideos:nil];
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

/* 跳转到"回放"界面 */
- (void)_jumpToPlayback
{
    RLog(@"");
    
    UIStoryboard *more = [UIStoryboard storyboardWithName:@"More" bundle:nil];
    PlaybackController *playbackVC =  [more instantiateViewControllerWithIdentifier:@"PlaybackController"];
    
    if (playbackVC) {
        [self presentViewController:playbackVC animated:NO completion:nil];
    }
}

/* 跳转到"上传"界面 */
- (void)_jumpToUpload
{
    RLog(@"");
    
    UIStoryboard *more = [UIStoryboard storyboardWithName:@"More" bundle:nil];
    UploadController *uploadVC =  [more instantiateViewControllerWithIdentifier:@"UploadController"];
    
    if (uploadVC) {
        [self presentViewController:uploadVC animated:NO completion:nil];
    }
}

/* 退出系统 */
- (void)_handleExit
{
    RLog(@"");
    
    // 更新状态机
    [self _updateWithState:YSS_exit];
}

/* 朗读完毕 */
- (void)_handleComplete
{
    RLog(@"");
    
    // 更新状态机
    [self _updateWithState:YSS_signing];
}

/* 清除签名 */
- (void)_handleClear
{
    RLog(@"");
    
    // 清除签名
    [_signView clean];
}

/* 确认签名 */
- (void)_handleDone
{
    RLog(@"");
    
    // 更新状态机
    [self _updateWithState:YSS_stop_recording];
}

/* 回放 */
- (void)_handlePlayback
{
    RLog(@"");
    
    // 更新状态机
    [self _updateWithState:YSS_playback];
}

/* 上传 */
- (void)_handleUpload
{
    RLog(@"");
    
    // 更新状态机
    [self _updateWithState:YSS_upload];
}

/* 重录 */
- (void)_handleRedo
{
    RLog(@"");
    
    // 更新状态机
    [self _updateWithState:YSS_start_recording];
}

- (void)_exitMeeting
{
    RLog(@"");
    
    [[CloudroomVideoMeeting shareInstance] exitMeeting];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/* 播放影音视频 */
- (void)_playLocalMedia
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    // TODO:获取播放文件全路径
    NSString *videoPath = [PathUtil searchPathInCacheDir:@"CloudroomVideoSDK/video.mp4"];
    NSParameterAssert(videoPath && videoPath.length > 0);
    VideoCfg *cfg = [cloudroomVideoMeeting getMediaCfg];
    [cfg setSizeType:VSIZE_SZ_360];
    [cloudroomVideoMeeting setMediaCfg:cfg];
    [cloudroomVideoMeeting startPlayMedia:videoPath bLocPlay:YES bPauseWhenFinished:NO];
}

/* 录制操作 */
- (void)_startToRecord
{
    if ([self _startRecording]) { // 录制成功
        // 开启定时器
        [self _startTimer];
        
        // 更新状态机
        [self _updateWithState:YSS_start_playing];
    }
    else { // 录制失败
        [HUDUtil hudShow:@"录制失败" delay:3 animated:YES];
        
        // 更新状态机
        [self _updateWithState:YSS_exit];
    }
}

/* 开始录制 */
- (BOOL)_startRecording
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    RecCfg *cfg = [[RecCfg alloc] init];
    // TODO:设置录制文件全路径
    // FIXME: 修改录制文件格式(king 20180606)
    [cfg setFilePathName:[PathUtil searchPathInCacheDir:[NSString stringWithFormat:@"CloudroomVideoSDK/%@_iOS.mp4", [self _getCurFileString]]]];
    [cfg setFps:20];
    [cfg setDstResolution:(CGSize){640, 360}];
    [cfg setMaxBPS:350000];
    [cfg setDefaultQP:28];
    // TODO:不要使用REC_AV_DEFAULT!!!
    [cfg setRecDataType:REC_AUDIO_LOC | REC_AUDIO_OTHER	| REC_VIDEO];
    [cfg setIsUploadOnRecording:NO];
    
    return [cloudroomVideoMeeting startRecording:cfg];
}

/* 录制内容布局 */
- (void)_updateRecLayout
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    NSMutableArray<RecContentItem *> *recordVideos = [NSMutableArray array];
    CGFloat contentW = [cloudroomVideoMeeting getRecCfg].dstResolution.width;
    CGFloat contentH = [cloudroomVideoMeeting getRecCfg].dstResolution.height;
    
    if (_isRead) { // 图片
        CGRect imgRect = (CGRect){0, 0, contentW, contentH};
        RecPictureContentItem *picture = [[RecPictureContentItem alloc] initWithRect:imgRect resID:@"statement"];
        [recordVideos addObject:picture];
    }
    else { // 影音
        CGRect mediaRect = (CGRect){0, 0, contentW, contentH};
        RecMediaContentItem *media = [[RecMediaContentItem alloc] initWithRect:mediaRect];
        [recordVideos addObject:media];
    }
    
    // 摄像头
    short camID = [cloudroomVideoMeeting getDefaultVideo:myUserID];
    CGFloat cameraH = 0;
    CGFloat cameraW = 0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown: { // 竖屏
            cameraW = 90;
            cameraH = 160;
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight: { // 横屏
            cameraW = 160;
            cameraH = 90;
            break;
        }
        default: break;
    }
    CGRect cameraRect = (CGRect){contentW - cameraW, contentH - cameraH, cameraW, cameraH};
    RecVideoContentItem *video = [[RecVideoContentItem alloc] initWithRect:cameraRect userID:myUserID camID:camID];
    [recordVideos addObject:video];
    
    // 签名
    if (_isSign) {
        // FIXME: 签名视图增大(king 20180613)
        int signW = 200;
        int signH = 120;
        CGRect signRect = (CGRect){contentW - cameraW - signW, contentH - signH, signW, signH};
        RecPictureContentItem *sign = [[RecPictureContentItem alloc] initWithRect:signRect resID:@"signature"];
        [recordVideos addObject:sign];
    }
    
    // 时间戳
    /*
    CGSize timeSize = [[_dateFormatter stringFromDate:[NSDate date]] jk_sizeWithFont:[UIFont systemFontOfSize:18] constrainedToHeight:40];
    CGFloat timeW = timeSize.width;
    CGFloat timeH = timeSize.height;
     */
    CGRect timeRect = (CGRect){4, 4, 260, 40};
    RecPictureContentItem *time = [[RecPictureContentItem alloc] initWithRect:timeRect resID:@"time"];
    [recordVideos addObject:time];
    
    [cloudroomVideoMeeting setRecordVideos:[recordVideos copy]];
}

/* 停止录制 */
- (void)_stopRecording
{
    [self _stopTimer];
    
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    [cloudroomVideoMeeting stopRecording];
}

/* 开启时间戳录制*/
- (void)_startTimer
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        
        _timer = [NSTimer jk_timerWithTimeInterval:1 block:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                RLog(@"timer");
                [self _setPicResource:@"time" str:[_dateFormatter stringFromDate:[NSDate date]]];
            });
        } repeats:YES];
        [_timer fire];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    });
}

/* 停止时间戳录制*/
- (void)_stopTimer
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

/* 设置视图资源 */
- (void)_setPicResource:(NSString *)resID view:(UIView *)view
{
    UIImage *cImage = [self _imageWithView:view];
    // UIImageJPEGRepresentation(cImage, 1.0)
    NSData *imgData = UIImagePNGRepresentation(cImage);
    UIImage *pngImg = [UIImage imageWithData:imgData];
    [self _setPicResource:resID image:pngImg];
}

/* 设置图片资源 */
- (void)_setPicResource:(NSString *)resID image:(UIImage *)image
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    MediaDataFrame *frame = [[MediaDataFrame alloc] init];
    NSInteger lenght = 0;
    // UInt32 *buf = [self _logPixelsOfImage:image length:&lenght];
    unsigned char *buf = [self _pixelRGBABytesFromImage:image length:&lenght];
    NSLog(@"RGBA length:%zd", lenght);

    if (lenght <= 0) {
        free(buf);
        buf = NULL;
        return;
    }
    
    frame.w = image.size.width;
    frame.h = image.size.height;
    frame.fmt = 28;
    frame.ms = [[NSDate date] timeIntervalSince1970] * 1000;
    frame->buf = (void *)buf;
    frame.datLength = (int)lenght;
    [cloudroomVideoMeeting setPicResource:resID mediaDataFrame:frame];
    
    free(buf);
    buf = NULL;
}

/* 设置视图资源 */
- (void)_setPicResource:(NSString *)resID str:(NSString *)str
{
    UIImage *cImage = [self _imageWithStr:str fontSize:18 textColor:[UIColor whiteColor]];
    NSData *imgData = UIImagePNGRepresentation(cImage);
    UIImage *jpgImg = [UIImage imageWithData:imgData];
    [self _setPicResource:resID image:jpgImg];
}

/*
 iOS UIImage与Bytes Pixel之间转换
 http://www.jianshu.com/p/69a5d99040fa
 */
- (unsigned char *)_pixelRGBABytesFromImage:(UIImage *)image length:(NSInteger *)length
{
    return [self _pixelRGBABytesFromImageRef:image.CGImage length:length];
}

- (unsigned char *)_pixelRGBABytesFromImageRef:(CGImageRef)imageRef length:(NSInteger *)length
{
    NSUInteger imageW = CGImageGetWidth(imageRef);
    NSUInteger imageH = CGImageGetHeight(imageRef);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * imageW;
    NSUInteger bitsPerComponent = 8;
    NSLog(@"imageW:%lu imageH:%lu bytesPerPixel:%lu", (unsigned long)imageW, (unsigned long)imageH, (unsigned long)bytesPerPixel);
    size_t imageBytes = imageW * imageH * bytesPerPixel;
    unsigned char *imageBuf = malloc(imageBytes);
    
    if (imageBytes > 0) { // 记录长度
        *length = (NSInteger)(imageBytes);
    }
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(imageBuf,
                                                 imageW,
                                                 imageH,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 space,
                                                 kCGImageAlphaPremultipliedLast); // RGBA
    
    CGRect rect = CGRectMake(0, 0, imageW, imageH);
    CGContextDrawImage(context, rect, imageRef);
    CGColorSpaceRelease(space);
    CGContextRelease(context);
    // 导致运行崩溃!!!
    // CGImageRelease(imageRef);
    
    return imageBuf;
}

- (UIImage *)_imageWithView:(UIView *)view
{
    if (!view) {
        NSLog(@"the view is nil!");
        return nil;
    }
    
    if ([view isHidden]) {
        NSLog(@"the view is hidden!");
        return nil;
    }
    
    if ([view isKindOfClass:[UIImageView class]]) {
        NSLog(@"this is an UIImageView!");
        UIImageView *imageView = (UIImageView *)view;
        return imageView.image;
    }
    
    CGSize size = view.bounds.size;
    NSLog(@"size:%@", NSStringFromCGSize(size));
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    [view.layer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (UIImage *)_imageWithStr:(NSString *)str
                  fontSize:(CGFloat)fontSize
                 textColor:(UIColor *)textColor
{
    // 获取字符串宽高
    CGSize size = [str jk_sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToHeight:40];
    NSDictionary <NSAttributedStringKey, id> *attrs = @{
                                                        NSFontAttributeName : [UIFont systemFontOfSize:fontSize],
                                                        NSForegroundColorAttributeName : textColor,
                                                        NSBackgroundColorAttributeName : [UIColor blackColor]
                                                        };
    
    // 开始
    UIGraphicsBeginImageContextWithOptions (size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    
    // 画字符串
    [str drawInRect:CGRectMake(0, 0, size.width, size.height) withAttributes:attrs];
    
    // 形成图片
    UIImage *newImage= UIGraphicsGetImageFromCurrentImageContext();
    
    // 结束
    UIGraphicsEndImageContext ();
    
    return newImage;
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

- (NSString *)_getCurFileString {
    NSDate *date =[NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy"];
    NSInteger curYear = [[formatter stringFromDate:date] integerValue];
    [formatter setDateFormat:@"MM"];
    NSInteger curMonth = [[formatter stringFromDate:date]integerValue];
    [formatter setDateFormat:@"dd"];
    NSInteger curDay = [[formatter stringFromDate:date] integerValue];
    [formatter setDateFormat:@"HH"];
    NSInteger curHour = [[formatter stringFromDate:date] integerValue];
    [formatter setDateFormat:@"mm"];
    NSInteger curMinute = [[formatter stringFromDate:date]integerValue];
    [formatter setDateFormat:@"ss"];
    NSInteger curSecond = [[formatter stringFromDate:date] integerValue];
    
    return [NSString stringWithFormat:@"%04zd-%02zd-%02zd_%02zd-%02zd-%02zd", curYear, curMonth, curDay, curHour, curMinute, curSecond];
}

#pragma mark - unused method
- (void)_saveTempPic:(UIImage*)img
{
    if (img) {
        //这里切换线程处理
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDate *date = [NSDate date];
            NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
            [dateformatter setDateFormat:@"HHmmssSSS"];
            NSString *now = [dateformatter stringFromDate:date];
            
            NSString *picPath = [NSString stringWithFormat:@"%@%@.png",[NSHomeDirectory() stringByAppendingFormat:@"/tmp/"], now];
            NSLog(@"存贮于   = %@",picPath);
            
            BOOL bSucc = NO;
            NSData *imgData = UIImagePNGRepresentation(img);
            
            if (imgData) {
                bSucc = [imgData writeToFile:picPath atomically:YES];
            }
        });
    }
}

- (void)_saveTempData:(NSData *)data
{
    if (data) {
        //这里切换线程处理
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDate *date = [NSDate date];
            NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
            [dateformatter setDateFormat:@"HHmmssSSS"];
            NSString *now = [dateformatter stringFromDate:date];
            
            NSString *picPath = [NSString stringWithFormat:@"%@___%@",[NSHomeDirectory() stringByAppendingFormat:@"/tmp/"], now];
            NSLog(@"存贮于   = %@",picPath);
            
            BOOL bSucc = NO;
            
            if (date) {
                bSucc = [data writeToFile:picPath atomically:YES];
            }
        });
    }
}

/*
 iOS: Converting UIImage to RGBA8 Bitmaps and Back
 http://paulsolt.com/blog/2010/09/ios-converting-uiimage-to-rgba8-bitmaps-and-back
 UIImage 转 Bitmap
 http://120423319.blog.163.com/blog/static/27821824201310611623211
 */
- (unsigned char *)_convertUIImageToBitmapRGBA8:(UIImage *)image length:(NSUInteger *)length
{
    CGImageRef imageRef = image.CGImage;
    
    // create a bitmap context to draw the uiimage into
    CGContextRef context = [self _getBitmapRGBA8ContextFromImage:imageRef];
    
    if (!context) {
        return NULL;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // draw image into the context to get the raw image data
    CGContextDrawImage(context, rect, imageRef);
    
    // get a pointer to the data
    unsigned char *bitmapData = (unsigned char *)CGBitmapContextGetData(context);
    
    // copy the data and release the memory (return memory allocated with new)
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t bufLength = bytesPerRow * height;
    *length = bufLength;
    
    unsigned char *newBitmap = NULL;
    
    if (bitmapData) {
        newBitmap = (unsigned char *)malloc(sizeof(unsigned char) * bytesPerRow * height);
        
        if (newBitmap) {    // copy the data
            for (int i = 0; i < bufLength; ++i) {
                newBitmap[i] = bitmapData[i];
            }
        }
        
        // free the old memory
        free(bitmapData);
    }
    else {
        NSLog(@"Error getting bitmap pixel data\n");
    }
    
    CGContextRelease(context);
    
    return newBitmap;
}

- (CGContextRef)_getBitmapRGBA8ContextFromImage:(CGImageRef)image
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t *bitmapData;
    
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    size_t bytesPerRow = width * bytesPerPixel;
    size_t bufferLength = bytesPerRow * height;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (!colorSpace) {
        NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }
    
    // allocate memory for image data
    bitmapData = (uint32_t *)malloc(bufferLength);
    
    if (!bitmapData) {
        NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    // create bitmap context
    context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast); // RGBA
    if (!context) {
        free(bitmapData);
        NSLog(@"Bitmap context not created");
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

- (UIImage *)_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer width:(int)width height:(int)height
{
    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,    // data provider
                                    NULL,        // decode
                                    YES,            // should interpolate
                                    renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if (pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);
    
    if (context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }
    
    UIImage *image = nil;
    
    if (context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        }
        else {
            image = [UIImage imageWithCGImage:imageRef];
        }
        
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    
    if (pixels) {
        free(pixels);
    }
    
    return image;
}

- (UInt32 *)_logPixelsOfImage:(UIImage *)image length:(NSInteger *)length
{
    // 1. Get pixels of image
    CGImageRef inputCGImage = [image CGImage];
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 *pixels;
    *length = (NSInteger)(height * width * sizeof(UInt32));
    pixels = (UInt32 *) calloc(height * width , sizeof(UInt32));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
    
    // 2. Iterate and log!
    NSLog(@"Brightness of image:");
    UInt32 * currentPixel = pixels;
    for (NSUInteger j = 0; j < height; j++) {
        for (NSUInteger i = 0; i < width; i++) {
            UInt32 color = *currentPixel;
            printf("%3.0f ", (R(color)+G(color)+B(color))/3.0);
            currentPixel++;
        }
        printf("\n");
    }
    
    return pixels;
    
#undef R
#undef G
#undef B
}
@end
