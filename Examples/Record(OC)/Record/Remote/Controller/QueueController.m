//
//  QueueController.m
//  Record
//
//  Created by king on 2017/6/12.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "QueueController.h"
#import "RemoteController.h"
#import "AppDelegate.h"
#import "QueueCallBack.h"
#import "VideoMgrCallBack.h"
#import "NSTimer+JKBlocks.h"
#import "TimeUtil.h"
#import "RecordHelper.h"
#import "MJExtension.h"
#import "OCRModel.h"

@interface QueueController () <QueueDelegate, VideoMgrDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel; /**< 标题 */
@property (weak, nonatomic) IBOutlet UILabel *timeLabel; /**< 时间 */
@property (weak, nonatomic) IBOutlet UILabel *descLabel; /**< 排队描述 */
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn; /**< 取消 */
@property (nonatomic, copy) NSString *callID; /**< 会话ID */
@property (nonatomic, copy) NSString *callerID; /**< 对端昵称 */
@property (nonatomic, copy) NSString *peerID; /**< 对端ID */
@property (nonatomic, strong) MeetInfo *meetInfo; /**< 会议信息 */
@property (nonatomic, strong) NSTimer *queueTimer; /**< 定时器 */

@property (nonatomic, assign) BOOL fromBG; /**< 是否从后台切换至前台? */
@property (nonatomic, assign) BOOL stopQueuing; /**< 停止排队 */
@property (nonatomic, assign) BOOL stopQueuingRslt; /**< 停止排队结果 */
@property (nonatomic, assign) BOOL notifyCallIn; /**< 通知呼入 */

- (IBAction)clickForQueue:(UIButton *)sender;

@end

@implementation QueueController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForQueue];
}

- (void)viewWillAppear:(BOOL)animated
{
    RLog(@"");
    [super viewWillAppear:animated];
    [self _updateDelegate];
    [self _addNotificcation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    RLog(@"");
    [super viewWillDisappear:animated];
    [self _removeNotificcation];
}

- (void)dealloc
{
    [self _stopTimer];
    
    if (!_stopQueuing) {
        NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
        [[CloudroomQueue shareInstance] stopQueuing:cookie];
        [self _handleCancelQueue];
    }
}

#pragma mark - QueueDelegate
// 排队信息变化通知
- (void)queueCallBack:(QueueCallBack *)callback queuingInfoChanged:(QueuingInfo *)queuingInfo
{
    // FIXME:刷新排队信息
    [self _handleRefreshOperation];
    
    RLog(@"queID:%d, queuingTime:%d, position:%d", queuingInfo.queID, queuingInfo.queuingTime, queuingInfo.position);
    QueuingInfo *queuing = [[CloudroomQueue shareInstance] getQueuingInfo];
    RLog(@"queID:%d, queuingTime:%d, position:%d", queuing.queID, queuing.queuingTime, queuing.position);
    
    /*
    if (queuing.queID == -1 && self && [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
     */
    
    if (queuing.queID != _queID) {
        return;
    }
    
    _count = (NSInteger)queuing.queuingTime;
    _position = (NSInteger)(queuing.position - 1);
}

// 开始排队结果
- (void)queueCallBack:(QueueCallBack *)callback startQueuingRslt:(CRVIDEOSDK_ERR_DEF)errCode cookie:(NSString *)cookie;
{
    [HUDUtil hudHiddenProgress:YES];
    
    if (errCode != CRVIDEOSDK_NOERR) {
        [HUDUtil hudShow:@"排队失败" delay:3 animated:YES];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self _startTimer];
    }
}

// 停止排队结果
- (void)queueCallBack:(QueueCallBack *)callback stopQueuingRslt:(CRVIDEOSDK_ERR_DEF)errCode cookie:(NSString *)cookie
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
        if (errCode != CRVIDEOSDK_NOERR) {
            [HUDUtil hudShow:@"停止排队失败" delay:3 animated:YES];
        }
        
        if (_stopQueuingRslt && _notifyCallIn) {
            CloudroomVideoMgr *cloudroomVideoMgr = [CloudroomVideoMgr shareInstance];
            // iOS端取消排队,Web端接受排队,此特殊情况下,拒绝呼叫
            [cloudroomVideoMgr rejectCall:_callID usrExtDat:nil cookie:cookie];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark - VideoMgrDelegate
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback loginSuccess:(NSString *)usrID cookie:(NSString *)cookie
{
    // 3. 开始排队
    [self _startQueue];
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback loginFail:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    [HUDUtil hudHiddenProgress:YES];
    [HUDUtil hudShow:@"登录失败!" delay:3 animated:YES];
    [self _jumpToLogin];
}

// 4. 接受他人邀请响应
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback acceptCallSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    // 进入视频会话
    _callID = callID;
    
    // 跳转到"回话"界面
    [self _jumpToRecordScreen];
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback acceptCallFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    
}

// 2. 服务端通知被邀请
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback notifyCallIn:(NSString *)callID meetInfo:(MeetInfo *)meetInfo callerID:(NSString *)callerID usrExtDat:(NSString *)usrExtDat
{
    _notifyCallIn = YES;
    
    RLog(@"通知呼入, callID:%@ callerID:%@", callID, callerID);
    
    NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    CloudroomVideoMgr *cloudroomVideoMgr = [CloudroomVideoMgr shareInstance];
    _callID = callID;
    _callerID = callerID;
    _peerID = callerID;
    _meetInfo = meetInfo;
    [self _stopTimer];
    
    if (_stopQueuingRslt && _notifyCallIn) {
        // iOS端取消排队,Web端接受排队,此特殊情况下,拒绝呼叫
        [cloudroomVideoMgr rejectCall:callID usrExtDat:nil cookie:cookie];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        // 3. 接受呼叫
        [cloudroomVideoMgr acceptCall:callID meetInfo:meetInfo usrExtDat:nil cookie:cookie];
    }
}

// 掉线/被踢通知
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    if (_fromBG) {
        _fromBG = NO;
        return;
    }
    
    // FIXME: 手机端排队断网,iOS无任何提示仍在排队
    if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
        [self _showAlert:@"您已被踢下线!"];
    }
    else { // 掉线
        [self _showAlert:@"您已掉线!"];
    }
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback sendCmdRlst:(NSString *)sendId sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"sendId:%@ sdkErr:%zd cookie:%@", sendId, sdkErr, cookie);
}

// 发送数据结果
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback sendBufferRlst:(NSString *)sendId sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"sendId:%@ sdkErr:%zd cookie:%@", sendId, sdkErr, cookie);
}

#pragma mark - selector
/**
 按钮响应

 @param sender 按钮对象
 */
- (IBAction)clickForQueue:(UIButton *)sender
{
    [self _handleCancelQueue];
}

- (void)qc_appDidEnterBackground:(NSNotification *)notification
{
    RLog(@"");
    
    // 停止排队
    NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    [[CloudroomQueue shareInstance] stopQueuing:cookie];
    
    RLog(@"background stopQueuing");
}

- (void)qc_appWillEnterForeground:(NSNotification *)notification
{
    RLog(@"");
    
    RecordHelper *recordHelper = [RecordHelper shareInstance];
    CloudroomVideoMgr *cloudroomVideoMgr = [CloudroomVideoMgr shareInstance];
    
    _fromBG = YES;
    
    // 1. 注销
    [cloudroomVideoMgr logout];
    
    // 2. 登录
    NSString *md5Pswd = [NSString md5:recordHelper.pswd];
    NSString *cookie = [NSString stringWithFormat:@"%f",CFAbsoluteTimeGetCurrent()];
    LoginDat *loginData = [[LoginDat alloc] init];
    [loginData setNickName:recordHelper.nickname];
    [loginData setAuthAcnt:recordHelper.account];
    [loginData setAuthPswd:md5Pswd];
    [loginData setPrivAcnt:recordHelper.nickname];
    [[CloudroomVideoSDK shareInstance] setServerAddr:recordHelper.server];
    [HUDUtil hudShowProgress:@"正在恢复连接..." animated:YES];
    [cloudroomVideoMgr login:loginData cookie:cookie];
}

#pragma mark - private method
/**
 初始化
 */
- (void)_setupForQueue
{
    [self _setupForProperies];
    [self _updateDelegate];
    [self _startQueue];
}

/**
 设置属性
 */
- (void)_setupForProperies
{
    [_timeLabel.layer setCornerRadius:30];
    [_timeLabel.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_timeLabel.layer setBorderWidth:4];
    [_timeLabel.layer masksToBounds];
    [_cancelBtn.layer setCornerRadius:6];
    // C5C7C7
    [_cancelBtn.layer setBorderColor:UIColorFromRGB(0x6A6E75).CGColor];
    [_cancelBtn.layer setBorderWidth:1];
    [_cancelBtn.layer masksToBounds];
    
    _count = 0;
    _stopQueuingRslt = NO;
    _notifyCallIn = NO;
    _stopQueuing = NO;
    
    // FIXME:排队信息需要展示队列名称
    NSString *title = [NSString stringWithFormat:@"您正在排队等候【%@】服务中,已等待", _queName];
    [_titleLabel setText:title];
}

- (void)_addNotificcation
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(qc_appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(qc_appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)_removeNotificcation
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 更新代理
 */
- (void)_updateDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.queueCallBack setQueueDelegate:self];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
}

/**
 开始排队
 */
- (void)_startQueue
{
    RLog(@"");
    
    NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    NSDictionary *ocrInfo = [_model mj_keyValues];
    NSDictionary *usrDic = @{@"type" : @"OCR",
                             @"OCRInfo" : ocrInfo ? ocrInfo :@{}};
    NSString *usrStr = [usrDic mj_JSONString];
    [[CloudroomQueue shareInstance] startQueuing:_queID usrExtDat:usrStr cookie:cookie];
}

/**
 开始排队
 */
- (void)_stopQueue
{
    RLog(@"");
    
    _stopQueuing = YES;
    NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    [[CloudroomQueue shareInstance] stopQueuing:cookie];
}

/**
 刷新
 */
- (void)_handleRefreshOperation
{
    RLog(@"");
    [[CloudroomQueue shareInstance] refreshAllQueueStatus];
}

/**
 取消排队
 */
- (void)_handleCancelQueue
{
    [self _stopQueue];
}

/**
 跳转到"会话"界面
 */
- (void)_jumpToRecordScreen
{
    if ([NSString stringCheckEmptyOrNil:_callID]) {
        RLog(@"callID is empty!");
        return;
    }
    
    if ([NSString stringCheckEmptyOrNil:_peerID]) {
        RLog(@"peerUserID is empty");
    }
    
    UIStoryboard *record = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    RemoteController *remoteVC = [record instantiateViewControllerWithIdentifier:@"RemoteController"];
    [remoteVC setCallID:_callID];
    [remoteVC setCallerID:_callerID];
    [remoteVC setPeerID:_peerID];
    [remoteVC setMeetInfo:_meetInfo];
    
    if (remoteVC) {
        [self.navigationController pushViewController:remoteVC animated:YES];
    }
}

/**
 跳转到"登录"界面
 */
- (void)_jumpToLogin
{
    // 注销
    [[CloudroomVideoMgr shareInstance] logout];
    [self _stopTimer];
    
    // 跳转到"登录"界面
    UIStoryboard *login = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    BaseNavController *loginNav = [login instantiateInitialViewController];
    
    if (loginNav) {
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:loginNav];
    }
}

/**
 开始计时
 */
- (void)_startTimer
{
    [self _stopTimer];
    // 创建定时器
    weakify(self);
    _queueTimer = [NSTimer jk_scheduledTimerWithTimeInterval:1 block:^{
        strongify(self);
        if (sSelf) {
            [sSelf->_timeLabel setText:[NSString stringWithFormat:@"%@", [TimeUtil getFormatTimeString:sSelf->_count]]];
            NSString *descText = [NSString stringWithFormat:@"前面还有 %zd 位用户", sSelf->_position];
            [sSelf->_descLabel setText:descText];
            sSelf->_count++;
        }
    } repeats:YES];
    [_queueTimer fire];
}

/**
 停止计时
 */
- (void)_stopTimer
{
    if ([_queueTimer isValid]) {
        [_queueTimer invalidate];
        _queueTimer = nil;
        _count = 0;
        _position = 0;
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
@end
