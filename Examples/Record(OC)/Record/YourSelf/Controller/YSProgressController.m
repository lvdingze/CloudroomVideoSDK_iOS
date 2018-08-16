//
//  YSProgressController.m
//  Record
//
//  Created by king on 2017/8/16.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "YSProgressController.h"
#import "YouSelfController.h"
#import "FileMgrCallBack.h"
#import "VideoMgrCallBack.h"
#import "VideoMeetingCallBack.h"
#import "AppDelegate.h"
#import "RecordHelper.h"
#import "PathUtil.h"

typedef NS_ENUM(NSInteger, YSProgressBtnType)
{
    YSPBTCancel = 1,
    YSPBTStart
};

@interface YSProgressController () <FileMgrDelegate, VideoMgrDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *bgImage; /**< 背景图片 */
@property (weak, nonatomic) IBOutlet UIProgressView *progressView; /**< 进度条视图 */
@property (weak, nonatomic) IBOutlet UILabel *descLabel; /**< 描述视图 */
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn; /**< 取消按钮 */
@property (weak, nonatomic) IBOutlet UIButton *startBtn; /**< 开始办理业务按钮 */
@property (nonatomic, strong) MeetInfo *meetInfo; /**< 会议信息 */

- (IBAction)clickBtnForYSProgress:(UIButton *)sender;

@end

@implementation YSProgressController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForYSProgress];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _updateDelegate];
}

- (void)dealloc
{
    [[CloudroomHttpFileMgr shareInstance] stopMgr];
    [[CloudroomVideoMeeting shareInstance] exitMeeting];
    [self _cleanDelegate];
}

#pragma mark - FileMgrDelegate
- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileStateChanged:(NSString *)fileName state:(HTTP_TRANSFER_STATE)state
{
    
}

- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileHttpRspHeader:(NSString *)fileName rspHeader:(NSString *)rspHeader
{
    
}

- (void)fileMgrCallBack:(FileMgrCallBack *)callback
           fileProgress:(NSString *)fileName
            finishedSize:(int)finishedSize
              totalSize:(int)totalSize
{
    if ([fileName hasSuffix:@"mp4"]) {
        _progressView.progress = 1 / 3.0 + finishedSize / (float)totalSize  * 1 / 3.0;
    }
    else if ([fileName hasSuffix:@"jpg"]) {
        _progressView.progress = finishedSize / (float)totalSize * 1 / 3.0;
    }
}

- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileFinished:(NSString *)fileName rslt:(HTTP_TRANSFER_RESULT)rslt
{
    if ([fileName hasSuffix:@"mp4"]) {
        // 3. 创建会议
        [self _createMeeting];
    }
}

- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileHttpRspContent:(NSString *)fileName content:(NSString *)content
{
    
}

- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileRename:(NSString *)fileName newName:(NSString *)newName
{
    
}

#pragma mark - VideoMgrDelegate
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback createMeetingSuccess:(MeetInfo *)meetInfo cookie:(NSString *)cookie
{
    _progressView.progress = 1.0;
    [_startBtn setEnabled:YES];
    [_startBtn setBackgroundColor:UIColorFromRGB(0xFE6715)];
    [_descLabel setText:[NSString stringWithFormat:@"【%@】业务准备成功", _queName]];
    _meetInfo = meetInfo;
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback createMeetingFail:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    [HUDUtil hudShow:@"创建会议失败" delay:3 animated:YES];
}

// 掉线/被踢通知
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
        [self _showAlert:@"您已被踢下线!"];
    }
    else { // 掉线
        [self _showAlert:@"您已掉线!"];
    }
}

#pragma mark - selector
- (IBAction)clickBtnForYSProgress:(UIButton *)sender
{
    switch ([sender tag]) {
        case YSPBTCancel: { // 取消
            [self _handleCancelOperation];
            break;
        }
        case YSPBTStart: { // 开始办理业务
            [self _handleStartOperation];
            break;
        }
        default: break;
    }
}

#pragma mark - private method
- (void)_setupForYSProgress
{
    [self _setupForPropries];
    [self _updateDelegate];
    [self _setupForResource];
}

- (void)_setupForPropries
{
    _progressView.progress = 0.0;
    [_cancelBtn setBackgroundColor:UIColorFromRGB(0xFE6715)];
    [_cancelBtn setEnabled:YES];
    [_cancelBtn.layer setCornerRadius:4];
    [_cancelBtn.layer masksToBounds];
    [_startBtn setBackgroundColor:UIColorFromRGB(0x6A6E75)];
    [_startBtn setEnabled:NO];
    [_startBtn.layer setCornerRadius:4];
    [_startBtn.layer masksToBounds];
    
    [_descLabel setText:[NSString stringWithFormat:@"正在准备【%@】业务", _queName]];
}

- (void)_setupForResource
{
    NSString *videoPath = [PathUtil searchPathInCacheDir:@"CloudroomVideoSDK/video.mp4"];
    NSString *imagePath = [PathUtil searchPathInCacheDir:@"CloudroomVideoSDK/read.jpg"];
    CloudroomHttpFileMgr *cloudroomHttpFileMgr = [CloudroomHttpFileMgr shareInstance];
    // TODO:先开启服务,否则后续操作无效!!!
    [cloudroomHttpFileMgr startMgr];
    /* 获取相关资源文件 */
    // 1. 获取相关图片(客户朗读申明)
    HTTPReqInfo *image = [[HTTPReqInfo alloc] init];
    [image setHttpUrl:@"http://7xkkzx.dl1.z0.glb.clouddn.com/read.jpg?attname="];
    [image setFilePathName:imagePath];
    [cloudroomHttpFileMgr startTransferFile:image];
    // 2. 获取相关视频
    HTTPReqInfo *video = [[HTTPReqInfo alloc] init];
    [video setHttpUrl:@"http://dn-huba.qbox.me/test_480p.mp4?attname="];
    [video setFilePathName:videoPath];
    [cloudroomHttpFileMgr startTransferFile:video];
}

- (void)_updateDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.fileMgrCallBack setFileMgrDelegate:self];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
}

- (void)_cleanDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.fileMgrCallBack setFileMgrDelegate:nil];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:nil];
}

- (void)_handleCancelOperation
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)_handleStartOperation
{
    NSParameterAssert(_meetInfo);
    [self _jumpTpYourSelf:_meetInfo];
}

- (void)_createMeeting
{
    RecordHelper *recordHelper = [RecordHelper shareInstance];
    NSString *subject = [NSString stringWithFormat:@"%@的会议", [recordHelper nickname]];
    NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    [[CloudroomVideoMgr shareInstance] createMeeting:subject createPswd:NO cookie:cookie];
}

- (void)_jumpTpYourSelf:(MeetInfo *)meetInfo
{
    UIStoryboard *record = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    YouSelfController *yourselfVC = [record instantiateViewControllerWithIdentifier:@"YouSelfController"];
    [yourselfVC setMeetInfo:meetInfo];
    
    if (yourselfVC) {
        [self.navigationController pushViewController:yourselfVC animated:YES];
    }
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

/* 跳转到"登录"界面 */
- (void)_jumpToLogin
{
    RLog(@"");
    
    // 注销
    [[CloudroomVideoMgr shareInstance] logout];
    
    // 跳转到"登录"界面
    UIStoryboard *login = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    BaseNavController *loginNav = [login instantiateInitialViewController];
    if (loginNav) {
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:loginNav];
    }
}
@end
