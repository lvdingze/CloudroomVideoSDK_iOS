//
//  UploadController.m
//  Record
//
//  Created by king on 2017/8/22.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "UploadController.h"
#import "AppDelegate.h"
#import "VideoMgrCallBack.h"
#import "VideoMeetingCallBack.h"

typedef NS_ENUM(NSInteger, UploadState)
{
    US_init, // 初始化
    US_start_to_upload, // 开始上传
    US_uploading, // 正在上传
    US_cancel_upload, // 取消上传
    US_upload_complete, // 上传完成
};

@interface UploadController () <VideoMeetingDelegate, VideoMgrDelegate>

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIButton *operationBtn;

@property (nonatomic, copy) NSString *fileName;

- (IBAction)clickBtnForUpload:(UIButton *)sender;

@end

@implementation UploadController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForUpload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 更新代理
    [self _updateDelegate];
}

#pragma mark - VideoMeetingDelegate
// 录制过程出错(导致录制停止)回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback recordErr:(REC_ERR_TYPE)sdkErr
{
    
}

// 录制过程状态改变回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback recordStateChanged:(REC_STATE)state
{
    
}

// 取消上传录制文件出错回调(未实现)
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback cancelUploadRecordFileErr:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    
}

// 录制文件上传出错回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback uploadRecordFile:(NSString *)fileName err:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    
}

// 录制文件状态改变回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback uploadRecordFileSuccess:(NSString *)fileName fileUrl:(NSString *)fileUrl
{
    _fileName = fileName;
    
    _progressView.progress = 1.0;
    
    // 更新状态机
    [self _updateWithState:US_upload_complete];
}

// 录制文件上传进度回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyRecordFileUploadProgress:(NSString *)fileName percent:(int)percent
{
    RLog(@"");
    
    _progressView.progress = percent / 100.0;
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
- (IBAction)clickBtnForUpload:(UIButton *)sender
{
    if ([[sender titleForState:UIControlStateNormal] isEqualToString:@"取消上传"]) {
        // 更新状态机
        [self _updateWithState:US_cancel_upload];
    }
    else if ([[sender titleForState:UIControlStateNormal] isEqualToString:@"关闭"]) {
        // 退出操作
        [self _handleExit];
    }
}

#pragma mark - private method
/* 初始化 */
- (void)_setupForUpload
{
    // 设置属性
    [self _setupForProperies];
    // 更新代理
    [self _updateDelegate];
    // 更新状态机
    [self _updateWithState:US_init];
}

/* 设置属性 */
- (void)_setupForProperies
{
    [_progressView setProgress:0];
    
    [_operationBtn setBackgroundColor:UIColorFromRGB(0xFE6715)];
    [_operationBtn.layer setCornerRadius:4];
    [_operationBtn.layer masksToBounds];
}

/* 更新代理 */
- (void)_updateDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
    [appDelegate.videoMeetingCallBack setVideoMeetingDelegate:self];
}

/* 状态机 */
- (void)_updateWithState:(UploadState)state
{
    switch (state) {
        case US_init: { // 初始化
            [_progressView setHidden:YES];
            [_descLabel setHidden:YES];
            [_operationBtn setHidden:YES];
            
            // 上传操作
            [self _startToUpload];
            
            break;
        }
        case US_start_to_upload: { // 开始上传
            [_progressView setHidden:NO];
            [_descLabel setHidden:NO];
            [_operationBtn setHidden:NO];
            
            [_operationBtn setTitle:@"取消上传" forState:UIControlStateNormal];
            
            break;
        }
        case US_uploading: { // 上传中
            [_progressView setHidden:NO];
            [_descLabel setHidden:NO];
            [_operationBtn setHidden:NO];
            
            [_descLabel setText:[NSString stringWithFormat:@"%@ 正在上传", _fileName]];
            
            break;
        }
        case US_cancel_upload: { // 取消上传
            [_progressView setHidden:NO];
            [_descLabel setHidden:NO];
            [_operationBtn setHidden:NO];
            
            // 取消上传操作
            [self _cancelToUpload];
            
            // 退出操作
            [self _handleExit];
            
            break;
        }
        case US_upload_complete: { // 上传完成
            [_progressView setHidden:NO];
            [_descLabel setHidden:NO];
            [_operationBtn setHidden:NO];
            
            [_descLabel setText:[NSString stringWithFormat:@"%@ 上传完成", _fileName]];
            
            [_operationBtn setTitle:@"关闭" forState:UIControlStateNormal];
            
            break;
        }
        default: break;
    }
}

/* 上传操作 */
- (void)_startToUpload
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    RecCfg *recCfg = [cloudroomVideoMeeting getRecCfg];
    NSString *videoPath = [recCfg.filePathName lastPathComponent];
    NSString *fileName = nil;
    
    if (!videoPath || videoPath.length <= 0) {
        RLog(@"videoPath is nil or empty");
        return;
    }
    
    for (RecFileShow *file in [cloudroomVideoMeeting getAllRecordFiles]) {
        if ([file.fileName isEqualToString:videoPath]) {
            fileName = file.fileName;
            break;
        }
    }
    
    if (!fileName || fileName.length <= 0) {
        RLog(@"fileName is nil or empty");
        return;
    }
    
    // FIXME: 修改录制文件格式(king 20180606)
    [cloudroomVideoMeeting uploadRecordFile:fileName svrPathFileName:[NSString stringWithFormat:@"%@/%@", [self _getCurDirString], videoPath]];
    
    [self _updateWithState:US_start_to_upload];
}

/* 取消上传操作 */
- (void)_cancelToUpload
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    RecCfg *recCfg = [cloudroomVideoMeeting getRecCfg];
    NSString *videoPath = [recCfg.filePathName lastPathComponent];
    NSString *fileName = nil;
    
    if (!videoPath || videoPath.length <= 0) {
        RLog(@"videoPath is nil or empty");
        return;
    }
    
    for (RecFileShow *file in [cloudroomVideoMeeting getAllRecordFiles]) {
        if ([file.fileName isEqualToString:videoPath]) {
            fileName = file.fileName;
            break;
        }
    }
    
    if (!fileName || fileName.length <= 0) {
        RLog(@"fileName is nil or empty");
        return;
    }
    
    [cloudroomVideoMeeting cancelUploadRecordFile:fileName];
}

- (void)_handleExit
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (NSString *)_getCurDirString {
    NSDate *date =[NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy"];
    NSInteger curYear = [[formatter stringFromDate:date] integerValue];
    [formatter setDateFormat:@"MM"];
    NSInteger curMonth = [[formatter stringFromDate:date]integerValue];
    [formatter setDateFormat:@"dd"];
    NSInteger curDay = [[formatter stringFromDate:date] integerValue];
    
    return [NSString stringWithFormat:@"%04zd-%02zd-%02zd", curYear, curMonth, curDay];
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
@end
