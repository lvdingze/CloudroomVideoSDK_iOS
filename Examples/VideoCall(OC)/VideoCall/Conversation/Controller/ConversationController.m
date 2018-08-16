//
//  ConversationController.m
//  VideoCall
//
//  Created by king on 2016/11/23.
//  Copyright © 2016年 CloudRoom. All rights reserved.
//

#import "ConversationController.h"
#import "RatioCell.h"
#import "RotationUtil.h"
#import "AppDelegate.h"
#import "CallHelper.h"
#import "VideoView.h"
#import "NSTimer+JKBlocks.h"
#import "TimeUtil.h"
#import <CloudroomVideoSDK_IOS/CloudroomVideoSDK_IOS.h>

typedef NS_ENUM(NSInteger, ConversationBtnType)
{
    ConversationBtnTypeExchange = 1, // 切换摄像头
    ConversationBtnTypeHangup, // 挂断
    ConversationBtnTypeSpeed, // 速度优先
    ConversationBtnTypeQuality, // 画质优先
    ConversationBtnTypeRatio, // 分辨率
    ConversationBtnTypeSerRec // 云端录制
};

typedef NS_ENUM(NSInteger, ConversationSwitchType)
{
    ConversationSwitchTypeSelfMic = 1, // 切换麦克风
    ConversationSwitchTypeSelfCamera // 切换摄像头
};

@interface ConversationController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet VideoView *selfView; /**< 自己的视图 */
@property (weak, nonatomic) IBOutlet VideoView *peerView; /**< 对方的视图 */
@property (weak, nonatomic) IBOutlet UIImageView *netImageView; /**< 网络状态 */
@property (weak, nonatomic) IBOutlet UIImageView *selfMicImageView; /**< 自己的麦 */
@property (weak, nonatomic) IBOutlet UIImageView *peerMicImageView; /**< 对方的麦 */
@property (weak, nonatomic) IBOutlet UILabel *descLabel; /**< 标题 */
@property (weak, nonatomic) IBOutlet UILabel *countLabel; /**< 通话时长 */
@property (weak, nonatomic) IBOutlet UISwitch *selfCameraSwitch; /**< 开关摄像头(本地) */
@property (weak, nonatomic) IBOutlet UISwitch *selfMicSwitch; /**< 开关麦克风 */
@property (weak, nonatomic) IBOutlet UIButton *selfCameraExBtn; /**< 切换摄像头(本地) */
@property (weak, nonatomic) IBOutlet UIButton *qualityBtn; /**< 画质优先按钮 */
@property (weak, nonatomic) IBOutlet UIButton *speedBtn; /**< 速度优先按钮 */
@property (weak, nonatomic) IBOutlet UIView *ratioView; /** 分辨率视图 */
@property (weak, nonatomic) IBOutlet UITableView *tableView; /**< 列表视图 */
@property (weak, nonatomic) IBOutlet UIButton *ratioBtn; /**< 分辨率按钮 */
@property (weak, nonatomic) IBOutlet UIButton *serRecBtn;
@property (nonatomic, copy) NSArray <NSString *> *ratioArr; /**< 分辨率集合 */
@property (nonatomic, copy) NSArray<UsrVideoInfo *> *cameraArray; /**< 摄像头集合 */
@property (nonatomic, assign) NSInteger curCameraIndex; /**< 当前摄像头索引 */
@property (nonatomic, strong) NSTimer *countTimer; /**< 通话计时器 */
@property (nonatomic, assign) NSInteger count; /**< 计数 */
@property (nonatomic, strong) UsrVideoId *firstUser; /**< 记录第一个远端用户 */
@property (nonatomic, assign) int curRatioIndex; /**< 当前分辨率 */
@property (nonatomic, assign) CGSize peerSize; /**< 对端画面尺寸大小 */

@property (nonatomic, strong) UIAlertController *hungupVC;
@property (nonatomic, strong) UIAlertController *dropVC;

- (IBAction)clickBtnForConversation:(UIButton *)sender;
- (IBAction)clickSwitchForConversation:(UISwitch *)sender;

@end

@implementation ConversationController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForConversation];
}

- (void)dealloc
{
    VCLog(@"");
    
    if (_selfView) {
        [_selfView clearFrame];
    }
    
    if (_peerView) {
        [_peerView clearFrame];
    }
    
    [self _uninstallCountTimer];
    
    // 灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
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
    [self _updateDelegate];
    
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    if ([videoMeeting isUserInMeeting:_peerID]) {
        [self _subscribleCamera];
    }
    
    // 恢复自身视频
    NSString *ownerUserID = [[CallHelper shareInstance] nickname];
    if (_selfCameraSwitch.on) {
        [videoMeeting openVideo:ownerUserID];
    }
    else {
        [videoMeeting closeVideo:ownerUserID];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([RotationUtil isOrientationLandscape]) { // 如果是横屏
        [RotationUtil forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    }
    else {
        [RotationUtil forceOrientation:(UIInterfaceOrientationLandscapeRight)]; // 否则,切换为横屏
    }
    
    if ([self.navigationController isNavigationBarHidden]) {
        [self.navigationController setNavigationBarHidden:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    if ([videoMeeting isUserInMeeting:_peerID]) {
        [self _unsubscribleCamera];
    }
    
    // 关闭自身视频
    NSString *ownerUserID = [[CallHelper shareInstance] nickname];
    VIDEO_STATUS status = [videoMeeting getVideoStatus:ownerUserID];
    if (status == VOPEN) {
        [videoMeeting closeVideo:ownerUserID];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_ratioArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"RatioCell";
    RatioCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    [self _configureCell:cell rowAtIndexPath:indexPath];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [cloudroomVideoMeeting getVideoCfg];
    _curRatioIndex = (int)indexPath.row;
    // 设置分辨率
    [vCfg setSizeType:_curRatioIndex];
    // 设置码率
    // FIXME:切720 1080马赛克严重
    [vCfg setMaxbps:-1];
    [cloudroomVideoMeeting setVideoCfg:vCfg];
    VCLog(@"selected:%@", _ratioArr[[[cloudroomVideoMeeting getVideoCfg] sizeType]]);
    [_ratioBtn setTitle:[_ratioArr objectAtIndex:_curRatioIndex] forState:UIControlStateNormal];
    [self _ratioDismiss];
}

#pragma mark - VideoMeetingDelegate
// 最新网络评分0~10(10分为最佳网络)
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback netStateChanged:(int)level
{
    if (level < 0 || level > 10) {
        VCLog(@"netState level error!");
        return;
    }
    
    int netLevel = [self _getLevel:level];
    [_netImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"conf_network_state_icon_%d", netLevel]]];
}

// 麦声音强度更新(level取值:0~10)
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback micEnergyUpdate:(NSString *)userID oldLevel:(int)oldLevel newLevel:(int)newLevel
{
    if (oldLevel == newLevel) {
        return;
    }
    
    int micLevel = [self _getLevel:newLevel];
    
    if ([[[CloudroomVideoMeeting shareInstance] getMyUserID] isEqualToString:userID]) { // self
        [_selfMicImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"conf_sound_on_icon_%d", micLevel]]];
    }
    else { // peer
        [_peerMicImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"conf_sound_on_icon_%d", micLevel]]];
    }
}


// 音频设备状态变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback audioStatusChanged:(NSString *)userID oldStatus:(AUDIO_STATUS)oldStatus newStatus:(AUDIO_STATUS)newStatus
{
    [self _updateMic];
}

//视频设备状态变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback videoStatusChanged:(NSString *)userID oldStatus:(VIDEO_STATUS)oldStatus newStatus:(VIDEO_STATUS)newStatus
{
    [self _setCamera];
    [self _updateCamera];
    
    if (_isServer) {
        [self _updateSvrRecordingLayout];
    }
    
    // FIXME:关闭摄像头扔保留最后一帧 added by king 20180427
    if (newStatus == VCLOSE) {
        if (userID == _peerID) {
            [_peerView clearFrame];
        }
        else {
            [_selfView clearFrame];
        }
    }
}

// 成员有新的视频图像数据到来(通过GetVideoImg获取)
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyVideoData:(UsrVideoId *)userID frameTime:(long)frameTime
{
    @autoreleasepool {
        // FIXME: 当会议由多方(或者PC端有多个摄像头时)仅显示第一个摄像头内容
        // FIXME: 会议中对方手机切换摄像头,导致画面卡住
        if (!_firstUser && userID.videoID < 0 && ![userID.userId isEqualToString:[[CloudroomVideoMeeting shareInstance] getMyUserID]]) {
            _firstUser = userID;
        }
        
        if (([userID.userId isEqualToString:_firstUser.userId] && (userID.videoID < 0)) ||
            ([userID.userId isEqualToString:[[CloudroomVideoMeeting shareInstance] getMyUserID]])) {
            VideoFrame *rawFrame = [[CloudroomVideoMeeting shareInstance] getVideoImg:userID];
            if (!rawFrame) {
                VCLog(@"rawFrame nil!");
                return;
            }
            
            int length = (int)(rawFrame.datLength);
            if (length <= 0) {
                VCLog(@"length equal to 0!");
                return;
            }
            
            int width = rawFrame.frameWidth;
            int height = rawFrame.frameHeight;
            int sum = width * height;
            
            if (sum <= 0) {
                VCLog(@"width or height equal to 0!");
                return;
            }
            
            if (1.5 * sum != length) {
                VCLog(@"data.length not equal to width * height * 1.5!");
                return;
            }
            
            if (rawFrame.fmt != VFMT_YUV420P) {
                VCLog(@"get VFMT_YUV420P error!");
                return;
            }
            
            // FIXME:在后台OpenGL渲染会发生崩溃
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
                // OpenGL ES -> render YUV
                if ([[[CloudroomVideoMeeting shareInstance] getMyUserID] isEqualToString:userID.userId]) { // self
                    [_selfView displayYUV420pData:rawFrame->dat width:width height:height];
                }
                else { // peer
                    if (_peerSize.width != width || _peerSize.height != height) {
                        _peerSize = CGSizeMake(width, height);
                        [self _updateSvrRecordingLayout];
                    }
                    
                    [_peerView displayYUV420pData:rawFrame->dat width:width height:height];
                }
            }
            
            free(rawFrame->dat);
        }
    }
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback userEnterMeeting:(NSString *)userID
{
    if (![[[CloudroomVideoMeeting shareInstance] getMyUserID] isEqualToString:userID]) { // peer
        [self.descLabel setText:[NSString stringWithFormat:@"您正在和%@会话中...", _peerID]];
    }
    
    [self _subscribleCamera];
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback userLeftMeeting:(NSString *)userID
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"对方已挂断!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self _uninstallCountTimer];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// 入会成功(入会失败,将自动发起releaseCall)
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback enterMeetingRslt:(CRVIDEOSDK_ERR_DEF)code
{
    [HUDUtil hudHiddenProgress:YES];
    
    if (code == CRVIDEOSDK_NOERR) { // 进入会话成功
        [self _enterMeetingSuccess];
        
        
    }
    else { // 进入会话失败
        [self _enterMeetingFail:@"启动视频会话失败,是否重试?"];
    }
}

// 结束会议
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback endMeetingRslt:(CRVIDEOSDK_ERR_DEF)code
{
    if (code == CRVIDEOSDK_NOERR) {
        [[CloudroomVideoMeeting shareInstance] exitMeeting];
    }
}

// 会议被结束
- (void)videoMeetingCallBackMeetingStopped:(VideoMeetingCallBack *)callback
{
    [[CloudroomVideoMeeting shareInstance] exitMeeting];
}

// 会议掉线
- (void)videoMeetingCallBackMeetingDropped:(VideoMeetingCallBack *)callback
{
    VideoSessionInfo *sessionInfo = [[CloudroomQueue shareInstance] getSessionInfo];
    VCLog(@"callID:%@ duration:%d", sessionInfo.callID, sessionInfo.duration);
    
    if (![NSString stringCheckEmptyOrNil:sessionInfo.callID]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"会话掉线,是否重试?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self _uninstallCountTimer];
            NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
            [[CloudroomVideoMgr shareInstance] hungupCall:sessionInfo.callID usrExtDat:nil cookie:cookie];
            [self _jumpToLogin];
            _dropVC = nil;
        }];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [HUDUtil hudShowProgress:@"正在进入会话..." animated:YES];
            [[CloudroomVideoMeeting shareInstance] enterMeeting:sessionInfo.meetingID pswd:sessionInfo.meetingPswd userID:sessionInfo.callID nikeName:sessionInfo.callID];
            _dropVC = nil;
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:NO completion:nil];
        _dropVC = alertController;
    }
    else {
        [HUDUtil hudShow:@"进入会话失败" delay:3 animated:YES];
    }
}

// 本地音频设备有变化
- (void)videoMeetingCallBackAudioDevChanged:(VideoMeetingCallBack *)callback
{
    [self _updateMic];
}

// 本地视频设备有变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback videoDevChanged:(NSString *)userID
{
    [self _setCamera];
    [self _updateCamera];
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback defVideoChanged:(NSString *)userID videoID:(short)videoID
{
    [self _setCamera];
    [self _updateCamera];
    
    if (_isServer) {
        [self _updateSvrRecordingLayout];
    }
}

// 屏幕共享操作通知
- (void)videoMeetingCallBackNotifyScreenShareStarted:(VideoMeetingCallBack *)callback
{
    [self _jumpToShare];
}

// 云端录制状态改变
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback svrRecordStateChanged:(REC_STATE)state err:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    VCLog(@"======>svrRecordStateChanged:%zd", [[CloudroomVideoMeeting shareInstance] getSvrRecordState]);
    
    switch (state) {
        case NO_RECORD: {
            [_serRecBtn setTitle:@"开始录制" forState:UIControlStateNormal];
            [HUDUtil hudHiddenProgress:YES];
            
            break;
        }
        case RECORDING: {
            [_serRecBtn setTitle:@"结束录制" forState:UIControlStateNormal];
            [HUDUtil hudHiddenProgress:YES];
            
            break;
        }
        case STARTING:
        case PAUSED:
        case STOPPING: break;
    }
}

//  云端录制设备改变
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback svrRecVideosChanged:(NSArray <RecContentItem *> *)videoIDs
{
    
}

#pragma mark - VideoMgrDelegate
// 掉线/被踢通知(无网络会同时触发:lineOff和meetingDropped!!!)
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    if (_hungupVC) {
        [_hungupVC dismissViewControllerAnimated:NO completion:^{
            _hungupVC = nil;
            
            if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
                [self _showAlert:@"您已被踢下线!"];
            }
            else { // 掉线
                [self _showAlert:@"您已掉线!"];
            }
        }];
        return;
    }
    
    if (_dropVC) {
        [_dropVC dismissViewControllerAnimated:NO completion:^{
            _dropVC = nil;
            
            if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
                [self _showAlert:@"您已被踢下线!"];
            }
            else { // 掉线
                [self _showAlert:@"您已掉线!"];
            }
        }];
        return;
    }
    
    if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
        [self _showAlert:@"您已被踢下线!"];
    }
    else { // 掉线
        [self _showAlert:@"您已掉线!"];
    }
}

// 服务端通知呼叫被结束
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback notifyCallHungup:(NSString *)callID usrExtDat:(NSString *)usrExtDat
{
    // FIXME:挂断(被动),iOS端再次排队入会卡死
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"对方已挂断!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _hungupVC = nil;
        CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
        
        // 停止云端录制
        [self _stopSvrRecording];
        
        // 离开会议
        [cloudroomVideoMeeting exitMeeting];
        [self _uninstallCountTimer];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:NO completion:^{}];
    _hungupVC = alertController;
}

// 拆除呼叫
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback hangupCallSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    [HUDUtil hudHiddenProgress:YES];
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    
    [self _stopSvrRecording];
    
    // FIXME:挂断(主动),会议仍有声音
    [cloudroomVideoMeeting exitMeeting];
    [self _uninstallCountTimer];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback hangupCallFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    [HUDUtil hudHiddenProgress:YES];
    
    if (sdkErr == CRVIDEOSDK_INVALID_CALLID) {
        [HUDUtil hudShow:@"无效的呼叫ID" delay:3 animated:YES];
    }
    else {
        [HUDUtil hudShow:@"挂断失败" delay:3 animated:YES];
    }
    
    [self _uninstallCountTimer];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - selector

/**
 UIButton响应

 @param sender UIButton对象
 */
- (IBAction)clickBtnForConversation:(UIButton *)sender
{
    switch ([sender tag]) {
        case ConversationBtnTypeExchange: { // 切换本地摄像头
            [self _handleCameraExOperation];
            
            break;
        }
        case ConversationBtnTypeHangup: { // 挂断
            [self _handleHangupOperation];
            
            break;
        }
        case ConversationBtnTypeSpeed:
        case ConversationBtnTypeQuality: {
            [self _handleVideoQualityOperation:sender];
            
            break;
        }
        case ConversationBtnTypeRatio: { // 分辨率
            [self _handleRatioOperation];
            
            break;
        }
        case ConversationBtnTypeSerRec: { // 云端录制
            [self _handleSerRecOperation:sender];
            
            break;
        }
    }
}

/**
 UISwitch响应

 @param sender UISwitch对象
 */
- (IBAction)clickSwitchForConversation:(UISwitch *)sender
{
    switch ([sender tag]) {
        case ConversationSwitchTypeSelfMic: { // 开/关麦克风
            [self _handleSelfMicOperation:sender];
            break;
        }
        case ConversationSwitchTypeSelfCamera: { // 开/关摄像头
            [self _handleSelfCameraOperation:sender];
            break;
        }
        default: break;
    }
}

#pragma mark - private method
/**
 初始化
 */
- (void)_setupForConversation
{
    [self _setupForProperies];
    [self _setupForOrientation];
    [self _updateDelegate];
    [self _enterMeeting];
}

/**
 初始化属性
 */
- (void)_setupForProperies
{
    _curCameraIndex = 0;
    // FIXME:32位真机在分辨率144x80下崩溃
    _ratioArr = @[@"224*128", @"288*160", @"336*192", @"448*256", @"512*288", @"576*320", @"640*360", @"720*400", @"848*480", @"1024*576", @"1280*720", @"1920*1080"]; // @"144*80",
    [_ratioView setAlpha:0];
    [_ratioBtn setHidden:YES];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    UIColor *borderColor = [UIColor colorWithRed:250 / 255.0 green:79 / 255.0 blue:19 / 255.0 alpha:1.0];
    [_ratioBtn.layer setCornerRadius:4];
    [_ratioBtn.layer setBorderColor:borderColor.CGColor];
    [_ratioBtn.layer setBorderWidth:1];
    [_ratioBtn.layer masksToBounds];
    
    [_serRecBtn.layer setCornerRadius:4];
    [_serRecBtn.layer setBorderColor:borderColor.CGColor];
    [_serRecBtn.layer setBorderWidth:1];
    [_serRecBtn.layer masksToBounds];
    [_serRecBtn setHidden:YES];
}

/**
 初始化设备方向
 */
- (void)_setupForOrientation
{
    if ([RotationUtil isOrientationLandscape]) { // 如果是横屏
        [RotationUtil forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    }
    else {
        [RotationUtil forceOrientation:(UIInterfaceOrientationLandscapeRight)]; // 否则，切换为横屏
    }
}

/**
 初始化摄像头
 */
- (void)_setupCamera
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    short defaultVideoID = [cloudroomVideoMeeting getDefaultVideo:myUserID];
    NSMutableArray <UsrVideoInfo *> *videoes = [cloudroomVideoMeeting getAllVideoInfo:myUserID];
    NSArray<UsrVideoInfo *> *cameraArray = [videoes copy];
    
    for (UsrVideoInfo *video in videoes) {
        VCLog(@"userId:%@ videoName:%@ videoID:%d", video.userId, video.videoName, video.videoID);
        
        if (defaultVideoID == 0) { // 没有默认设备
            defaultVideoID = video.videoID;
            [cloudroomVideoMeeting setDefaultVideo:myUserID videoID:defaultVideoID];
        }
    }
    
    if ([cameraArray count] <= 0) {
        VCLog(@"获取摄像头设备为空!");
        return;
    }
    
    _cameraArray = cameraArray;
}

/**
 配置cell

 @param cell cell对象
 @param indexPath 行信息
 */
- (void)_configureCell:(RatioCell *)cell rowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *nomalColor = [UIColor whiteColor];
    UIColor *selectedColor = [UIColor colorWithRed:250 / 255.0 green:79 / 255.0 blue:19 / 255.0 alpha:1.0];
    [cell.contentLabel setText:[_ratioArr objectAtIndex:indexPath.row]];
    [cell.contentLabel.layer setCornerRadius:4];
    [cell.contentLabel.layer setBorderColor:(int)indexPath.row == _curRatioIndex ? selectedColor.CGColor : nomalColor.CGColor];
    [cell.contentLabel.layer setBorderWidth:1];
    [cell.contentLabel.layer masksToBounds];
    [cell.contentLabel setBackgroundColor:[UIColor clearColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.contentView setBackgroundColor:[UIColor clearColor]];
}

/**
 进入会议
 */
- (void)_enterMeeting
{
    [HUDUtil hudShowProgress:@"正在进入会话..." animated:YES];
    // 发送"入会"命令
    NSString *nickname = [[CallHelper shareInstance] nickname];
    VCLog(@"enterMeeting:ID:%d pswd:%@ userID:%@ nickname:%@", _meetInfo.ID, _meetInfo.pswd, nickname, nickname);
    [[CloudroomVideoMeeting shareInstance] enterMeeting:_meetInfo.ID pswd:_meetInfo.pswd userID:nickname nikeName:nickname];
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
 设置摄像头
 */
- (void)_setCamera
{
    if ([_cameraArray checkEmptyOrNil]) {
        VCLog(@"没有摄像头!");
        return;
    }
    
    if (_curCameraIndex >= [_cameraArray count]) {
        VCLog(@"摄像头索引越界!");
        return;
    }
    
    // 设置摄像头设备
    UsrVideoInfo *video = [_cameraArray objectAtIndex:_curCameraIndex];
    [[CloudroomVideoMeeting shareInstance] setDefaultVideo:video.userId videoID:video.videoID];
    VCLog(@"当前摄像头为:%zd", _curCameraIndex);
}

/**
 开/关摄像头UI更新
 */
- (void)_updateCamera
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    VIDEO_STATUS status = [cloudroomVideoMeeting getVideoStatus:myUserID];
    
    if (status == VOPEN || status == VOPENING) {
        [_selfCameraSwitch setOn:YES];
    }
    else {
        [_selfCameraSwitch setOn:NO];
    }
    
    [self _updateSwitch];
}

/**
 开/关麦克风UI更新
 */
- (void)_updateMic
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    AUDIO_STATUS status = [cloudroomVideoMeeting getAudioStatus:myUserID];
    
    if (status == AOPEN || status == AOPENING) {
        [_selfMicSwitch setOn:YES];
    }
    else {
        [_selfMicSwitch setOn:NO];
    }
}

/**
 切换摄像头UI更新
 */
- (void)_updateSwitch
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    NSMutableArray <UsrVideoId *> *watchableVideos = [cloudroomVideoMeeting getWatchableVideos];
    
    if ([watchableVideos count] > 0) {
        [cloudroomVideoMeeting watchVideos:watchableVideos];
    }
    
    NSMutableArray <UsrVideoInfo *> *videos = [cloudroomVideoMeeting getAllVideoInfo:myUserID];
    VIDEO_STATUS status = [cloudroomVideoMeeting getVideoStatus:myUserID];
    BOOL isShow = (status == VOPEN || status == VOPENING) && [videos count] > 1;
    [_selfCameraExBtn setHidden:!isShow];
}

/**
 切换摄像头
 */
- (void)_handleCameraExOperation
{
    VCLog(@"");
    
    if ([_cameraArray count] <= 1) {
        VCLog(@"无法切换摄像头!");
        return;
    }
    
    if (_curCameraIndex == 0) {
        _curCameraIndex = 1;
    }
    else {
        _curCameraIndex = 0;
    }
    
    [self _setCamera];
}

/**
 挂断
 */
- (void)_handleHangupOperation
{
    VCLog(@"");
    
    if ([NSString stringCheckEmptyOrNil:_callID]) {
        [HUDUtil hudShow:@"callID为空" delay:3 animated:YES];
        return;
    }
    
    // FIXME:web端挂断,这边alert再挂断可能会造成"callID无效"
    NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    [HUDUtil hudShowProgress:@"正在挂断..." animated:YES];
    [[CloudroomVideoMgr shareInstance] hungupCall:_callID usrExtDat:nil cookie:cookie];
}

/**
 开/关麦克风

 @param sender UISwitch对象
 */
- (void)_handleSelfMicOperation:(UISwitch *)sender
{
    VCLog(@"");
    
    // 开/关自己的麦克风
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    
    if (sender.on) {
        [cloudroomVideoMeeting openMic:myUserID];
    }
    else {
        [cloudroomVideoMeeting closeMic:myUserID];
    }
}

/**
 开/关摄像头

 @param sender UISwitch对象
 */
- (void)_handleSelfCameraOperation:(UISwitch *)sender
{
    VCLog(@"");
    
    // 开/关自己的摄像头
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    
    if (sender.on) {
        [cloudroomVideoMeeting openVideo:myUserID];
    }
    else {
        [cloudroomVideoMeeting closeVideo:myUserID];
    }
}

/**
 设置优先级

 @param sender UIButton对象
 */
- (void)_handleVideoQualityOperation:(UIButton *)sender
{
    NSInteger index = [sender tag];
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [videoMeeting getVideoCfg];
    
    if (index == ConversationBtnTypeSpeed) {
        VCLog(@"speedBtn click!");
        [_speedBtn setSelected:YES];
        [_qualityBtn setSelected:NO];
        vCfg.minQuality = 22;
        vCfg.maxQuality = 36;
    }
    else if (index == ConversationBtnTypeQuality) {
        VCLog(@"qualityBtn click!");
        [_speedBtn setSelected:NO];
        [_qualityBtn setSelected:YES];
        vCfg.minQuality = 22;
        vCfg.maxQuality = 25;
    }
    
    [videoMeeting setVideoCfg:vCfg];
    VideoCfg *cfg = [videoMeeting getVideoCfg];
    VCLog(@"vCfg:%d %d %d %d, %d", cfg.sizeType, cfg.fps, cfg.maxbps, cfg.minQuality, cfg.maxQuality);
}

/**
 设置分辨率
 */
- (void)_handleRatioOperation
{
    if (_ratioView.alpha == 0) {
        [self _ratioShow];
    }
    else {
        [self _ratioDismiss];
    }
}

/* 云端录制 */
- (void)_handleSerRecOperation:(UIButton *)sender {
    // FIXME: 防止因网络原因,导致录制文件形成失败(king 20180605)
    [HUDUtil hudShowProgress:nil animated:YES];
    
    if ([[sender titleForState:UIControlStateNormal] isEqualToString:@"开始录制"]) {
        [self _startSvrRecording];
    } else {
        [self _stopSvrRecording];
    }
}

/**
 入会成功
 */
- (void)_enterMeetingSuccess
{
    [HUDUtil hudShow:@"成功进入会话" delay:3 animated:YES];
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    // 自己的麦克风/扬声器
    [cloudroomVideoMeeting openMic:myUserID];
    [cloudroomVideoMeeting setMicVolume:100];
    [cloudroomVideoMeeting getMicVolume];
    [cloudroomVideoMeeting setSpeakerVolume:100];
    [cloudroomVideoMeeting getSpeakerVolume];
    
    // 自己的摄像头
    [cloudroomVideoMeeting openVideo:myUserID];
    [self _setupCamera];
    [self _setCamera];
    [self _updateCamera];
    [self _updateMic];
    
    // 观看对方视频
    if ([cloudroomVideoMeeting isUserInMeeting:_peerID]) {
        [self _subscribleCamera];
        [_descLabel setText:[NSString stringWithFormat:@"您正在和%@会话中...", _peerID]];
    }
     
    NSMutableArray <MemberInfo *> *members = [cloudroomVideoMeeting getAllMembers];
    for (MemberInfo *info in members) {
        NSString *nickname = [cloudroomVideoMeeting getNickName:info.userId];
        MemberInfo *memberInfo = [cloudroomVideoMeeting getMemberInfo:info.userId];
        VCLog(@"nickname:%@, audioStatus:%d, videoStatus:%d", nickname, memberInfo.audioStatus, memberInfo.videoStatus);
    }
    
    [self _installCountTimer];
    
    [_ratioBtn setHidden:NO];
    [_serRecBtn setHidden:!_isServer];
    
    // 设置默认分辨率
    [self _setDefaultRatio];
    // 设置默认优先级
    [self _setDefaultPriority];
}

/**
 入会失败
 @param message 失败信息
 */
- (void)_enterMeetingFail:(NSString *)message
{
    VideoSessionInfo *sessionInfo = [[CloudroomQueue shareInstance] getSessionInfo];
    // callID:23ba044d-bb5f-490d-b30e-27a2212de346 duration:0
    VCLog(@"callID:%@ duration:%d", sessionInfo.callID, sessionInfo.duration);
    
    if (![NSString stringCheckEmptyOrNil:sessionInfo.callID]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self _uninstallCountTimer];
            NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
            [[CloudroomVideoMgr shareInstance] hungupCall:sessionInfo.callID usrExtDat:nil cookie:cookie];
            [self _jumpToLogin];
        }];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [HUDUtil hudShowProgress:@"正在进入会话..." animated:YES];
            [[CloudroomVideoMeeting shareInstance] enterMeeting:sessionInfo.meetingID pswd:sessionInfo.meetingPswd userID:sessionInfo.callID nikeName:sessionInfo.callID];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:NO completion:nil];
    }
    else {
        [HUDUtil hudShow:@"进入会话失败" delay:3 animated:YES];
    }
}

/**
 获取音频能量等级

 @param energy 能量参数
 @return 能量等级
 */
- (int)_getLevel:(int)energy
{
    int audioLevel = 0;
    switch (energy) {
        case 0: { audioLevel = 0; break; }
        case 1:
        case 2:
        case 3: { audioLevel = 1; break; }
        case 4:
        case 5:
        case 6: { audioLevel = 2; break; }
        case 7:
        case 8:
        case 9:
        case 10: { audioLevel = 3; break; }
        default: { audioLevel = 0; break; }
    }
    
    return audioLevel;
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

/**
 跳转到"影音共享"界面
 */
- (void)_jumpToShare
{
    VCLog(@"");
    
    // 跳转到"登录"界面
    UIStoryboard *share = [UIStoryboard storyboardWithName:@"Share" bundle:nil];
    BaseController *shareVC = [share instantiateViewControllerWithIdentifier:@"ShareController"];
    if (shareVC) {
        [self.navigationController pushViewController:shareVC animated:YES];
    }
}

//TODO:添加通话时长 added by king 20161213
/**
 开启定时器
 */
- (void)_installCountTimer
{
    [self _uninstallCountTimer];
    
    _countTimer = [NSTimer jk_scheduledTimerWithTimeInterval:1.0 block:^{
        _count++;
        [_countLabel setText:[NSString stringWithFormat:@"通话时长:%@", [TimeUtil getFormatTimeString:_count]]];
    } repeats:YES];
}

/**
 关闭定时器
 */
- (void)_uninstallCountTimer
{
    if (_countTimer) {
        [_countTimer invalidate];
        _countTimer = nil;
    }
    
    _count = 0;
}

/**
 订阅摄像头
 */
- (void)_subscribleCamera
{
    VCLog(@"");
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    NSMutableArray <UsrVideoId *> *videos = [videoMeeting getWatchableVideos];
    
    for (UsrVideoId *user in videos) {
        VCLog(@"userId:%@ videoID:%d", user.userId, user.videoID);
    }
    
    [videoMeeting watchVideos:videos];
}

/**
 取消订阅摄像头
 */
- (void)_unsubscribleCamera
{
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    [videoMeeting watchVideos:nil];
}

/**
 设置默认分辨率
 */
- (void)_setDefaultRatio
{
    /* 848*480 */
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:VSIZE_SZ_480 inSection:0];
    [self tableView:_tableView didSelectRowAtIndexPath:indexPath];
}

/**
 设置默认优先级
 */
- (void)_setDefaultPriority
{
    /* 质量优先 */
    [self _handleVideoQualityOperation:_qualityBtn];
}

/**
 分辨率视图显示
 */
- (void)_ratioShow
{
    [_tableView reloadData];
    [UIView animateWithDuration:0.25 animations:^{
        [_ratioView setAlpha:1.0];
    }];
}

/**
 分辨率视图隐藏
 */
- (void)_ratioDismiss
{
    [UIView animateWithDuration:0.25 animations:^{
        [_ratioView setAlpha:0];
    }];
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

/* 开始云端录制 */
- (void)_startSvrRecording {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    RecCfg *cfg = [[RecCfg alloc] init];
    // TODO:设置录制文件全路径
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *fileName = [NSString stringWithFormat:@"record_%.0f.mp4", timeStamp];
    [cfg setFilePathName:fileName];
    [cfg setFps:20];
    // FIXME: 分辨率改为: 848 x 480(king 20180605)
    [cfg setDstResolution:(CGSize){848, 480}];
    // FIXME: 设置码率:500kbps(king 20180611)
    [cfg setMaxBPS:500000];
    [cfg setDefaultQP:28];
    // TODO:不要使用REC_AV_DEFAULT!!!
    [cfg setRecDataType:REC_AUDIO_LOC | REC_AUDIO_OTHER | REC_VIDEO];
    [cfg setIsUploadOnRecording:YES];
    // FIXME: 修改录制文件格式(king 20180606)
    [cfg setServerPathFileName:[NSString stringWithFormat:@"/%@/%@_iOS.mp4", [self _getCurDirString], [self _getCurFileString]]];
    [cfg setCreateRepairFile:YES];
    
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    NSMutableArray<RecContentItem *> *recordVideos = [NSMutableArray array];
    CGFloat contentW = cfg.dstResolution.width;
    CGFloat contentH = cfg.dstResolution.height;
    
    // 远端摄像头
    short remoteCamID = [cloudroomVideoMeeting getDefaultVideo:_peerID];
    CGFloat remoteCamW = contentW;
    CGFloat remoteCamH = contentH;
    
    if (_peerSize.width != 0 && _peerSize.height != 0) {
        CGFloat scale = _peerSize.width / (_peerSize.height * 1.0);
        
        remoteCamH = contentW * 1 / scale;
        if (remoteCamH > contentH) {
            remoteCamH = contentH;
            remoteCamW = contentH * scale;
        }
    }
    
    CGRect remoteCamRect = (CGRect){(contentW - remoteCamW) * 0.5, (contentH - remoteCamH) * 0.5, remoteCamW, remoteCamH};
    VCLog(@"remoteCamRect:%@ peerID:%@ remoteCamID:%d peerSize:%@", NSStringFromCGRect(remoteCamRect), _peerID, remoteCamID, NSStringFromCGSize(_peerSize));
    RecVideoContentItem *remote = [[RecVideoContentItem alloc] initWithRect:remoteCamRect userID:_peerID camID:remoteCamID];
    [recordVideos addObject:remote];
    
    // 本地摄像头
    short localCamID = [cloudroomVideoMeeting getDefaultVideo:myUserID];
    CGFloat localCamW = 320;
    CGFloat localCamH = 180;
    CGRect localCamRect = (CGRect){contentW - localCamW, contentH - localCamH, localCamW, localCamH};
    VCLog(@"localCamRect:%@ myUserID:%@ localCamID:%d", NSStringFromCGRect(localCamRect), myUserID, localCamID);
    RecVideoContentItem *local = [[RecVideoContentItem alloc] initWithRect:localCamRect userID:myUserID camID:localCamID];
    [recordVideos addObject:local];
    
    // 开始云端录制
    [cloudroomVideoMeeting startSvrRecording:cfg contents:[recordVideos copy]];
}

/* 结束云端录制 */
- (void)_stopSvrRecording {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    [cloudroomVideoMeeting stopSvrRecording];
}

// FIXME: 录制布局改为互看模式(king 20180605)
- (void)_updateSvrRecordingLayout
{
    if (![[_serRecBtn titleForState:UIControlStateNormal] isEqualToString:@"结束录制"]) {
        return;
    }
    
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    CGFloat contentW = [cloudroomVideoMeeting getSvrRecordCfg].dstResolution.width;
    CGFloat contentH = [cloudroomVideoMeeting getSvrRecordCfg].dstResolution.height;
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    NSMutableArray<RecContentItem *> *recordVideos = [NSMutableArray array];
    
    // 远端摄像头
    short remoteCamID = [cloudroomVideoMeeting getDefaultVideo:_peerID];
    CGFloat remoteCamW = contentW;
    CGFloat remoteCamH = contentH;
    
    if (_peerSize.width != 0 && _peerSize.height != 0) {
        CGFloat scale = _peerSize.width / (_peerSize.height * 1.0);
        
        remoteCamH = contentW * 1 / scale;
        if (remoteCamH > contentH) {
            remoteCamH = contentH;
            remoteCamW = contentH * scale;
        }
    }
    
    CGRect remoteCamRect = (CGRect){(contentW - remoteCamW) * 0.5, (contentH - remoteCamH) * 0.5, remoteCamW, remoteCamH};
    VCLog(@"remoteCamRect:%@ peerID:%@ remoteCamID:%d peerSize:%@", NSStringFromCGRect(remoteCamRect), _peerID, remoteCamID, NSStringFromCGSize(_peerSize));
    RecVideoContentItem *remote = [[RecVideoContentItem alloc] initWithRect:remoteCamRect userID:_peerID camID:remoteCamID];
    [recordVideos addObject:remote];
    
    // 本地摄像头
    short localCamID = [cloudroomVideoMeeting getDefaultVideo:myUserID];
    CGFloat localCamW = 320;
    CGFloat localCamH = 180;
    CGRect localCamRect = (CGRect){contentW - localCamW, contentH - localCamH, localCamW, localCamH};
    VCLog(@"localCamRect:%@ myUserID:%@ localCamID:%d", NSStringFromCGRect(localCamRect), myUserID, localCamID);
    RecVideoContentItem *local = [[RecVideoContentItem alloc] initWithRect:localCamRect userID:myUserID camID:localCamID];
    [recordVideos addObject:local];
    
    [cloudroomVideoMeeting setSvrRecVideos:recordVideos];
}

- (NSString *)_getCurDirString {
    NSDate *curDate = [NSDate date];
    NSCalendarUnit uints = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *components =  [[NSCalendar currentCalendar] components:uints  fromDate:curDate];
    
    return [NSString stringWithFormat:@"%04zd-%02zd-%02zd", components.year, components.month, components.day];
}

- (NSString *)_getCurFileString {
    NSDate *curDate = [NSDate date];
    NSCalendarUnit uints = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components =  [[NSCalendar currentCalendar] components:uints  fromDate:curDate];
    
    return [NSString stringWithFormat:@"%04zd-%02zd-%02zd_%02zd-%02zd-%02zd", components.year, components.month, components.day, components.hour, components.minute, components.second];
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
     return NO;
}
@end
