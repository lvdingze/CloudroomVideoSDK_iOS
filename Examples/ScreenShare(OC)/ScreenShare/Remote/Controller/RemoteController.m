//
//  RemoteController.m
//  Record
//
//  Created by king on 2017/8/15.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "RemoteController.h"
#import "BaseNavController.h"
#import "ChatController.h"
#import "RatioCell.h"
#import "RecordHelper.h"
#import "VideoMeetingCallBack.h"
#import "VideoMgrCallBack.h"
#import "AppDelegate.h"
#import "RotationUtil.h"
#import "MJExtension.h"
#import "PathUtil.h"
#import "TestScreenShareTableViewController.h"

typedef NS_ENUM(NSInteger, RecordBtnType)
{
    RecordBtnHangup, // 挂断
    RecordBtnOpenClose, // 打开/关闭摄像头
    RecordBtnExchange, // 切换摄像头
    RecordBtnRatio, // 分辨率
    RecordBtnPriority, // 优先级
    RecordBtnSmooth, // 画质优先
    RecordBtnSpeed, // 速度优先
    RecordBtnWHRate, // 7 宽高比
    RecordBtnWHRate16Point9, // 宽高比:16:9
    RecordBtnWHRate4Point3, // 宽高比:4:3
    RecordBtnWHRate1Point1, // 宽高比:1:1
    RecordBtnChat
};

typedef NS_ENUM(NSInteger, RemoteState)
{
    RS_enter, // 入会
    RS_enter_success, // 入会成功
    RS_enter_fail, // 入会失败
    RS_media_start, // 影音播放开始
    RS_media_pause, // 影音播放暂停
    RS_media_stop, // 影音播放停止
    RS_share_start, // 屏幕共享开始
    RS_share_stop, // 屏幕共享停止
    RS_brush_start, // 标注开始
    RS_brush_stop, // 标注停止
    RS_exit // 离会
};

@interface RemoteController () <UITableViewDelegate, UITableViewDataSource, VideoMeetingDelegate, QueueDelegate, VideoMgrDelegate, BKBrushViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel; /**< 标题 */
@property (weak, nonatomic) IBOutlet CLMediaView *mediaView; /**< 影音 */
@property (weak, nonatomic) IBOutlet UIView *shareView;
@property (weak, nonatomic) IBOutlet CLShareView *shareImage; /**< 共享 */
@property (weak, nonatomic) IBOutlet CLBrushView *brushView; /* 画布 */
@property (weak, nonatomic) IBOutlet CLCameraFloatView *myView; /**< 我的 */
@property (weak, nonatomic) IBOutlet CLCameraFloatView *peerView; /**< 对方 */
@property (weak, nonatomic) IBOutlet UIView *toolView; /**< 工具栏 */
@property (weak, nonatomic) IBOutlet UIButton *hungupBtn; /**< 挂断 */
@property (weak, nonatomic) IBOutlet UIButton *opencloseBtn; /**< 打开/关闭摄像头 */
@property (weak, nonatomic) IBOutlet UIButton *exchangeBtn; /**< 切换摄像头 */
@property (weak, nonatomic) IBOutlet UIButton *ratioBtn; /**< 分辨率 */
@property (weak, nonatomic) IBOutlet UIButton *priorityBtn; /**< 优先级 */
@property (weak, nonatomic) IBOutlet UIButton *smoothBtn; /**< 画质优先 */
@property (weak, nonatomic) IBOutlet UIButton *speedBtn; /**< 速度优先 */
@property (weak, nonatomic) IBOutlet UITableView *tableView; /**< 分辨率列表视图 */
@property (weak, nonatomic) IBOutlet UIView *priorityView; /**< 优先级视图 */
@property (weak, nonatomic) IBOutlet UIView *ratioView; /**< 分辨率视图 */
@property (weak, nonatomic) IBOutlet UIView *whrateView; /**< 本地视频宽高比视图 */
@property (weak, nonatomic) IBOutlet UIButton *whrateBtn; /**< 本地视频宽高比按钮 */
@property (weak, nonatomic) IBOutlet UIButton *sixteenPointNineBtn; /**< 16 : 9 */
@property (weak, nonatomic) IBOutlet UIButton *fourPointThreeBtn; /**< 4 : 3 */
@property (weak, nonatomic) IBOutlet UIButton *onePointOneBtn; /**< 1 : 1 */
@property (weak, nonatomic) IBOutlet UIButton *chatBtn; /**< 聊天 */

/* 约束 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *myViewPW;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *myViewPH;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *myViewLH;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *myViewLW;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *peerViewW;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *peerViewH;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaViewH;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaViewW;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shareW;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shareH;

@property (nonatomic, copy) NSArray<UsrVideoInfo *> *cameraArray; /**< 摄像头集合 */
@property (nonatomic, assign) NSInteger curCameraIndex; /**< 当前摄像头索引 */
@property (nonatomic, strong) UsrVideoId *firstUser; /**< 记录第一个远端入会者 */
@property (nonatomic, copy) NSArray <NSString *> *ratioArr; /**< 分辨率集合 */
@property (nonatomic, assign) int curRatioIndex; /**< 当前分辨率 */
@property (nonatomic, copy) NSString *curPriorityText; /**< 当前优先级 */
@property (nonatomic, assign) MEDIA_STATE mediaState; /**< 影音共享状态 */
@property (nonatomic, assign) BOOL isShare; /**< 屏幕共享? */
@property (nonatomic, assign) VIDEO_WHRATE_TYPE curWHRate; /**< 宽高比 */
@property (nonatomic, assign) BOOL enableMark;
@property (nonatomic, assign) CGSize peerRatio;

@property (nonatomic, strong) UIAlertController *hungupVC;
@property (nonatomic, strong) UIAlertController *dropVC;
- (IBAction)clickBtnForRemote:(UIButton *)sender;

@end

@implementation RemoteController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForRemote];
}

- (void)viewWillAppear:(BOOL)animated
{
    RLog(@"");
    
    [super viewWillAppear:animated];
    
    [self _updateDelegate];
    
    if (![self.navigationController isNavigationBarHidden]) {
        [self setNeedsStatusBarAppearanceUpdate];
        [self.navigationController setNavigationBarHidden:YES];
    }
    
    // 不灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self _r_updateUIScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    RLog(@"");
    [super viewWillDisappear:animated];
    
    if ([self.navigationController isNavigationBarHidden]) {
        [self.navigationController setNavigationBarHidden:NO];
    }
    
    // 强制竖屏
    if ([RotationUtil isOrientationLandscape]) { // 如果是横屏
        [RotationUtil forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    RLog(@"");
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    if (_myView) {
        [_myView clearFrame];
    }
    
    if (_mediaView) {
        [_mediaView clearFrame];
    }
    
    if (_peerView) {
        [_peerView clearFrame];
    }
    
    // 灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
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
    [vCfg setSizeType:(_curRatioIndex)];
    // 设置码率
    // FIXME:切720 1080马赛克严重
    if (_curRatioIndex == VSIZE_SZ_1080) {
        [vCfg setMaxbps:2000000];
    }
    else if (_curRatioIndex == VSIZE_SZ_720) {
        [vCfg setMaxbps:1000000];
    }
    else if (_curRatioIndex == VSIZE_SZ_576) {
        [vCfg setMaxbps:650000];
    }
    else if (_curRatioIndex == VSIZE_SZ_480) {
        [vCfg setMaxbps:500000];
    }
    else if (_curRatioIndex == VSIZE_SZ_400) {
        [vCfg setMaxbps:420000];
    }
    else if (_curRatioIndex == VSIZE_SZ_360) {
        [vCfg setMaxbps:350000];
    }
    else if (_curRatioIndex == VSIZE_SZ_320) {
        [vCfg setMaxbps:300000];
    }
    else if (_curRatioIndex == VSIZE_SZ_288) {
        [vCfg setMaxbps:250000];
    }
    else if (_curRatioIndex == VSIZE_SZ_256) {
        [vCfg setMaxbps:200000];
    }
    else if (_curRatioIndex == VSIZE_SZ_192) {
        [vCfg setMaxbps:150000];
    }
    else if (_curRatioIndex == VSIZE_SZ_160) {
        [vCfg setMaxbps:100000];
    }
    else if (_curRatioIndex == VSIZE_SZ_128) {
        [vCfg setMaxbps:72000];
    }
    else {
        [vCfg setMaxbps:-1];
    }
    
    [cloudroomVideoMeeting setVideoCfg:vCfg];
    RLog(@"selected:%@", _ratioArr[[[cloudroomVideoMeeting getVideoCfg] sizeType]]);
    [_ratioBtn setTitle:[_ratioArr objectAtIndex:_curRatioIndex] forState:UIControlStateNormal];
    [self _ratioDismiss];
}

#pragma mark - VideoMeetingDelegate
// 入会成功(入会失败,将自动发起releaseCall)
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback enterMeetingRslt:(CRVIDEOSDK_ERR_DEF)code
{
    if (code == CRVIDEOSDK_NOERR) { // 入会成功
        // 更新状态机
        [self _updateWithState:RS_enter_success];
    }
    else { // 入会失败
        // 更新状态机
        [self _updateWithState:RS_enter_fail];
    }
}

// 结束会议
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback stopMeetingRslt:(CRVIDEOSDK_ERR_DEF)code
{
    [self _popToRoot];
}

// 会议被结束
- (void)videoMeetingCallBackMeetingStopped:(VideoMeetingCallBack *)callback
{
    [self _popToRoot];
}

// 会议掉线
- (void)videoMeetingCallBackMeetingDropped:(VideoMeetingCallBack *)callback
{
    RLog(@"");
    
    if (![NSString stringCheckEmptyOrNil:_callID]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"会话掉线,是否重试?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
            [[CloudroomVideoMgr shareInstance] hungupCall:_callID usrExtDat:nil cookie:cookie];
            // 跳转"登录"界面
            [self _jumpToLogin];
            _dropVC = nil;
        }];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 更新状态机
            [self _updateWithState:RS_enter];
            _dropVC = nil;
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:NO completion:nil];
        _dropVC = alertController;
    }
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback userEnterMeeting:(NSString *)userID
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    
    if (![myUserID isEqualToString:userID]) { // peer
        [_titleLabel setText:[NSString stringWithFormat:@"您正在和%@会话中...", _peerID]];
    }
    
    [self _subscribleCamera];
    
    [self _queryMembers];
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback userLeftMeeting:(NSString *)userID
{
    // UI 提示
    [HUDUtil hudShow:[NSString stringWithFormat:@"%@ 离开会话!", userID] delay:3 animated:YES];
    
    [self _queryMembers];
}

// 音频设备状态变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback audioStatusChanged:(NSString *)userID oldStatus:(AUDIO_STATUS)oldStatus newStatus:(AUDIO_STATUS)newStatus
{
    [self _updateOpenAndCloseMic];
}

//视频设备状态变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback videoStatusChanged:(NSString *)userID oldStatus:(VIDEO_STATUS)oldStatus newStatus:(VIDEO_STATUS)newStatus
{
    [self _setCamera];
    [self _updateOpenAndCloseCamera];
    
    // FIXME: web关闭摄像头,iOS一直显示的是最后一帧画面
    if ([_peerID isEqualToString:userID]) {
        if (newStatus == VCLOSE) {
            _mediaState = [[[CloudroomVideoMeeting shareInstance] getMediaInfo] state];
            
            if (_mediaState == MEDIA_START || _mediaState == MEDIA_PAUSE) {
                [_peerView clearFrame];
            }
            else {
                [_mediaView clearFrame];
            }
        }
    }
}

// 本地音频设备有变化
- (void)videoMeetingCallBackAudioDevChanged:(VideoMeetingCallBack *)callback
{
    [self _updateOpenAndCloseMic];
}

// 本地视频设备有变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback videoDevChanged:(NSString *)userID
{
    [self _setCamera];
    [self _updateOpenAndCloseCamera];
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
            
        }
        
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
            if ([_myView.userID isEqualToString:userID.userId]) {
                [_myView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            else if ([_peerView.userID isEqualToString:userID.userId]) {
                if (_peerRatio.width != width || _peerRatio.height != height) {
                    _peerRatio.width = width;
                    _peerRatio.height = height;
                    
                    [self.view setNeedsLayout];
                    [self.view layoutIfNeeded];
                }
                
                [_peerView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            else if ([_mediaView.userID isEqualToString:userID.userId]) {
                [_mediaView displayYUV420pData:rawFrame->dat width:width height:height];
            }
        }
        
        free(rawFrame->dat);
    }
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
        
        // TODO:影音数据 fmt != VFMT_YUV420P
        //        if (rawFrame.fmt != VFMT_YUV420P) {
        //            RLog(@"get VFMT_YUV420P error!");
        //            return;
        //        }
        
        // FIXME:在后台OpenGL渲染会发生崩溃
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            if (_mediaState == MEDIA_START || _mediaState == MEDIA_PAUSE) {
                [_mediaView displayYUV420pData:rawFrame->buf width:width height:height];
            }
        }
        
        free(rawFrame->buf);
    }
}

// 影音开始通知
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaStart:(NSString *)userid
{
    _mediaState = [[[CloudroomVideoMeeting shareInstance] getMediaInfo] state];
    
    [self _queryMembers];
    
    // 更新状态机
    [self _updateWithState:RS_media_start];
}

// 影音停止播放的通知
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaStop:(NSString *)userid reason:(MEDIA_STOP_REASON)reason
{
    // FIXME:web停止播放回放,会弹提示"影音停止播放"
    // [SVProgressHUD showInfoWithStatus:@"影音停止播放"];
    _mediaState = [[[CloudroomVideoMeeting shareInstance] getMediaInfo] state];
    
    // 更新状态机
    [self _updateWithState:RS_media_stop];
    
    [self _queryMembers];
}

// 影音暂停播放的通知
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMediaPause:(NSString *)userid bPause:(BOOL)bPause
{
    _mediaState = [[[CloudroomVideoMeeting shareInstance] getMediaInfo] state];
    
    // 更新状态机
    [self _updateWithState:RS_media_pause];
}

- (void)videoMeetingCallBackNotifyScreenShareStarted:(VideoMeetingCallBack *)callback
{
    _isShare = YES;
    
    // 更新状态机
    [self _updateWithState:RS_share_start];
    
    [self _queryMembers];
}

- (void)videoMeetingCallBackNotifyScreenShareStopped:(VideoMeetingCallBack *)callback
{
    _isShare = NO;
    
    // 更新状态机
    [self _updateWithState:RS_share_stop];
    
    [self _queryMembers];
}

// 屏幕共享数据更新,用户收到该回调消息后应该调用getShareScreenDecodeImg获取最新的共享数据
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyScreenShareData:(NSString *)userID changedRect:(CGRect)changedRect frameSize:(CGSize)size
{
    ScreenShareImg *shareData = [[CloudroomVideoMeeting shareInstance] getShareScreenDecodeImg];
    
    if(!shareData) {
        return;
    }
    
    if (shareData.datLength != 4 * shareData.rgbWidth * shareData.rgbHeight) {
        return;
    }
    
    // FIXME:区域共享未实现 modified by king 201711071024
    // FIXME:部分区域共享变形 modified by king 201711231853
    if ((_brushView.shareSrcSize.width == 0 && _brushView.shareSrcSize.height == 0) || (_brushView.shareSrcSize.width != size.width || _brushView.shareSrcSize.height!= size.height)) {
        _brushView.shareSrcSize = size;
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [_shareImage handleShareData:shareData->rgbDat width:shareData.rgbWidth height:shareData.rgbHeight];
        // [self _handleShareData:shareData->rgbDat width:shareData.rgbWidth height:shareData.rgbHeight];
    }
}

// 屏幕共享标注开始回调
- (void)videoMeetingCallBackNotifyScreenMarkStarted:(VideoMeetingCallBack *)callback
{
    [_brushView clean];
    
    // 更新状态机
    [self _updateWithState:RS_brush_start];
}

// 屏幕共享标注停止回调
- (void)videoMeetingCallBackNotifyScreenMarkStopped:(VideoMeetingCallBack *)callback
{
    [_brushView clean];
    
    // 更新状态机
    [self _updateWithState:RS_brush_stop];
}

// 屏幕共享是否允许他人标注回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback enableOtherMark:(BOOL)enable
{
    _enableMark = enable;
}

// 屏幕共享标注回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback sendMarkData:(MarkData *)markData
{
    if (markData.termid != 0) {
        [_brushView drawLine:markData];
    }
}

// 屏幕共享所有标注回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback sendAllMarkData:(NSArray<MarkData *> *)markDatas
{
    for (MarkData *markData in markDatas) {
        [_brushView drawLine:markData];
    }
}

// 清除所有屏幕共享标注回调
- (void)videoMeetingCallBackClearAllMarks:(VideoMeetingCallBack *)callback
{
    [_brushView clean];
}

#pragma mark - VideoMgrDelegate
// 掉线/被踢通知(meetingDropped -> lineOff)
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    RLog(@"");
    
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
    RLog(@"");
    
    // FIXME:挂断(被动),iOS端再次排队入会卡死
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"对方已挂断!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 更新状态机
        _hungupVC = nil;
        [self _updateWithState:RS_exit];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:NO completion:^{}];
    _hungupVC = alertController;
}

// 拆除呼叫
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback hangupCallSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    // FIXME:挂断(主动),会议仍有声音
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback hangupCallFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // 更新状态机
    [self _updateWithState:RS_exit];
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback sendCmdRlst:(NSString *)sendId sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    if (sdkErr == CRVIDEOSDK_NOERR) {
        [HUDUtil hudShow:@"发送消息成功!" delay:3 animated:YES];
    }
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback notifyCmdData:(NSString *)sourceUserId data:(NSString *)data
{
    if ([[data mj_JSONObject] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *info = [data mj_JSONObject];
        NSString *type = [info objectForKey:@"type"];
        if([type isEqualToString:@"cursorPosData"])
        {
            return;
        }else
        {
            NSString *content = [info objectForKey:@"name"];
            [HUDUtil hudShow:[NSString stringWithFormat:@"接收%@消息:%@,成功!", sourceUserId, content] delay:3 animated:YES];
        }
    }
}

#pragma mark - BKBrushViewDelegate
- (void)brushView:(CLBrushView *)brushView touchEndWithMarkData:(MarkData *)markData
{
    if (_enableMark && ![_brushView isHidden]) {
        [[CloudroomVideoMeeting shareInstance] sendMarkData:markData];
    }
}

#pragma mark - selector
- (IBAction)clickBtnForRemote:(UIButton *)sender
{
    NSInteger tag = [sender tag];
    switch (tag) {
        case RecordBtnHangup: { // 挂断
            [self _handleHangup];
            break;
        }
        case RecordBtnOpenClose: { // 开关摄像头
            [self _handleOpenOrCloseCamera];
            break;
        }
        case RecordBtnExchange: { // 切换摄像头
            [self _handleExchangeCamera];
            break;
        }
        case RecordBtnRatio: { // 分辨率
            [self _handleRatio];
            break;
        }
        case RecordBtnPriority: { // 优先级
            [self _handlePriority];
            break;
        }
        case RecordBtnSmooth: // 画质优先
        case RecordBtnSpeed: { // 速度优先
            [self _handlePriority:sender];
            break;
        }
        case RecordBtnWHRate: { // 宽高比
            [self _handleWHRate];
            break;
        }
        case RecordBtnWHRate16Point9: // 16 : 9
        case RecordBtnWHRate4Point3: // 4 : 3
        case RecordBtnWHRate1Point1:{ // 1 : 1
            [self _handleWHRate:sender];
            break;
        }
        case RecordBtnChat: { // 聊天
            [self _handleChat];
            break;
        }
        default:  break;
    }
}

- (void)clickForMedia
{
    [self _ratioDismiss];
    [self _priorityDismiss];
    [self _whrateDismiss];
    [self _showOrDismissToolView];
}

- (void)r_statusBarOrientationDidChange:(NSNotification *)notification
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

- (void)r_deviceOrientationDidChange:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch (orientation) {
        case UIDeviceOrientationUnknown: {
            RLog(@"device===>UIDeviceOrientationUnknown");
            break;
        }
        case UIDeviceOrientationPortrait: {
            RLog(@"device===>UIDeviceOrientationPortrait");
            break;
        }
        case UIDeviceOrientationPortraitUpsideDown: {
            RLog(@"device===>UIDeviceOrientationPortraitUpsideDown");
            break;
        }
        case UIDeviceOrientationLandscapeLeft: {
            RLog(@"device===>UIDeviceOrientationLandscapeLeft");
            break;
        }
        case UIDeviceOrientationLandscapeRight: {
            RLog(@"device===>UIDeviceOrientationLandscapeRight");
            break;
        }
        case UIDeviceOrientationFaceUp: {
            RLog(@"device===>UIDeviceOrientationFaceUp");
            break;
        }
        case UIDeviceOrientationFaceDown: {
            RLog(@"device===>UIDeviceOrientationFaceDown");
            break;
        }
        default: break;
    }
}

#pragma mark - private method
/* 初始化 */
- (void)_setupForRemote
{
    [self _setupPropries];
    [self _updateDelegate];
    [self _setupForNotification];
    [self _updateWithState:RS_enter];
}

/* 设置属性 */
- (void)_setupPropries
{
    [_hungupBtn.layer setCornerRadius:4];
    [_hungupBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_hungupBtn.layer setBorderWidth:1];
    [_hungupBtn.layer masksToBounds];
    
    [_opencloseBtn.layer setCornerRadius:4];
    [_opencloseBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_opencloseBtn.layer setBorderWidth:1];
    [_opencloseBtn.layer masksToBounds];
    
    [_exchangeBtn.layer setCornerRadius:4];
    [_exchangeBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_exchangeBtn.layer setBorderWidth:1];
    [_exchangeBtn.layer masksToBounds];
    
    [_ratioBtn.layer setCornerRadius:4];
    [_ratioBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_ratioBtn.layer setBorderWidth:1];
    [_ratioBtn.layer masksToBounds];
    
    [_priorityBtn.layer setCornerRadius:4];
    [_priorityBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_priorityBtn.layer setBorderWidth:1];
    [_priorityBtn.layer masksToBounds];
    
    [_smoothBtn.layer setCornerRadius:4];
    [_smoothBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
    [_smoothBtn.layer setBorderWidth:1];
    [_smoothBtn.layer masksToBounds];
    
    [_speedBtn.layer setCornerRadius:4];
    [_speedBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
    [_speedBtn.layer setBorderWidth:1];
    [_speedBtn.layer masksToBounds];
    
    [_whrateBtn.layer setCornerRadius:4];
    [_whrateBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_whrateBtn.layer setBorderWidth:1];
    [_whrateBtn.layer masksToBounds];
    
    [_sixteenPointNineBtn.layer setCornerRadius:4];
    [_sixteenPointNineBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
    [_sixteenPointNineBtn.layer setBorderWidth:1];
    [_sixteenPointNineBtn.layer masksToBounds];
    
    [_fourPointThreeBtn.layer setCornerRadius:4];
    [_fourPointThreeBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
    [_fourPointThreeBtn.layer setBorderWidth:1];
    [_fourPointThreeBtn.layer masksToBounds];
    
    [_onePointOneBtn.layer setCornerRadius:4];
    [_onePointOneBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
    [_onePointOneBtn.layer setBorderWidth:1];
    [_onePointOneBtn.layer masksToBounds];
    
    [_chatBtn.layer setCornerRadius:4];
    [_chatBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    [_chatBtn.layer setBorderWidth:1];
    [_chatBtn.layer masksToBounds];
    
    /*
     UITapGestureRecognizer *mediaTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickForMedia)];
     // FIXME:分辨率列表点击无响应
     [self.view addGestureRecognizer:mediaTap];
     */
    [_toolView setAlpha:0];
    
    // FIXME:32位真机在分辨率144x80下崩溃
    _ratioArr = @[@"224*128", @"288*160", @"336*192", @"448*256", @"512*288", @"576*320", @"640*360", @"720*400", @"848*480", @"1024*576", @"1280*720", @"1920*1080"];
    
    [_tableView setRowHeight:44];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    
    _curCameraIndex = 0;
    
    [_ratioView setAlpha:0];
    [_priorityView setAlpha:0];
    [_whrateView setAlpha:0];
    
    _brushView.backgroundColor = [UIColor clearColor];
    _brushView.brushColor = [UIColor redColor];
    _brushView.brushWidth = 1;
    _brushView.shapeType = ST_curve;
    _brushView.delegate = self;
    
    _enableMark = NO;
    _isShare = NO;
}

/* 注册通知 */
- (void)_setupForNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(r_statusBarOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(r_deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
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
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    switch (deviceOrientation) {
        case UIDeviceOrientationUnknown: {
            RLog(@"default device===>UIDeviceOrientationUnknown");
            break;
        }
        case UIDeviceOrientationPortrait: {
            RLog(@"default device===>UIDeviceOrientationPortrait");
            break;
        }
        case UIDeviceOrientationPortraitUpsideDown: {
            RLog(@"default device===>UIDeviceOrientationPortraitUpsideDown");
            break;
        }
        case UIDeviceOrientationLandscapeLeft: {
            RLog(@"default device===>UIDeviceOrientationLandscapeLeft");
            break;
        }
        case UIDeviceOrientationLandscapeRight: {
            RLog(@"default device===>UIDeviceOrientationLandscapeRight");
            break;
        }
        case UIDeviceOrientationFaceUp: {
            RLog(@"default device===>UIDeviceOrientationFaceUp");
            break;
        }
        case UIDeviceOrientationFaceDown: {
            RLog(@"default device===>UIDeviceOrientationFaceDown");
            break;
        }
        default: break;
    }
}

/* 初始化摄像头信息 */
- (void)_setupCamera
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    short defaultVideoID = [cloudroomVideoMeeting getDefaultVideo:myUserID];
    NSMutableArray <UsrVideoInfo *> *videoes = [cloudroomVideoMeeting getAllVideoInfo:myUserID];
    NSArray<UsrVideoInfo *> *cameraArray = [videoes copy];
    
    for (UsrVideoInfo *video in videoes) {
        RLog(@"userId:%@ videoName:%@ videoID:%d", video.userId, video.videoName, video.videoID);
        
        if (defaultVideoID == 0) { // 没有默认设备
            defaultVideoID = video.videoID;
            [cloudroomVideoMeeting setDefaultVideo:myUserID videoID:defaultVideoID];
        }
    }
    
    if ([cameraArray count] <= 0) {
        RLog(@"获取摄像头设备为空!");
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
    [cell.contentLabel setText:[_ratioArr objectAtIndex:indexPath.row]];
    [cell.contentLabel.layer setCornerRadius:4];
    [cell.contentLabel.layer setBorderColor:(int)indexPath.row == _curRatioIndex ? UIColorFromRGB(0xFE6715).CGColor : UIColorFromRGB(0xFFFFFF).CGColor];
    [cell.contentLabel.layer setBorderWidth:1];
    [cell.contentLabel.layer masksToBounds];
    [cell.contentLabel setBackgroundColor:[UIColor clearColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.contentView setBackgroundColor:[UIColor clearColor]];
}

/* 更新代理 */
- (void)_updateDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
    [appDelegate.videoMeetingCallBack setVideoMeetingDelegate:self];
}

/* 更新设备方向 */
- (void)_updateForOrientation
{
    if ([RotationUtil isOrientationLandscape]) { // 如果是横屏
        [RotationUtil forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    }
    else {
        [RotationUtil forceOrientation:(UIInterfaceOrientationLandscapeRight)]; // 否则，切换为横屏
    }
}


/* 状态机 */
- (void)_updateWithState:(RemoteState)state
{
    switch (state) {
        case RS_enter: { // 入会
            [_myView setHidden:YES];
            [_peerView setHidden:YES];
            [_mediaView setHidden:YES];
            [_shareImage setHidden:YES];
            [_brushView setHidden:YES];
            
            // 入会操作
            [self _enterMeeting];
            
            break;
        }
        case RS_enter_success: { // 入会成功
            [_myView setHidden:NO];
            [_peerView setHidden:NO];
            [_mediaView setHidden:NO];
            [_shareImage setHidden:YES];
            [_brushView setHidden:YES];
            
            // 入会初始化操作
            [self _enterMeetingSuccess];
            
            break;
        }
        case RS_enter_fail: { // 入会失败
            [_myView setHidden:YES];
            [_peerView setHidden:YES];
            [_mediaView setHidden:YES];
            [_shareImage setHidden:YES];
            [_brushView setHidden:YES];
            
            [self _enterMeetingFail:@"启动视频会话失败,是否重试?"];
            
            break;
        }
        case RS_media_start: { // 影音播放开始
            [_myView setHidden:NO];
            [_peerView setHidden:NO];
            [_mediaView setHidden:NO];
            
            [_shareImage setHidden:YES];
            [_brushView setHidden:YES];
            
            break;
        }
        case RS_media_pause: { // 影音播放暂停
            [_myView setHidden:NO];
            [_peerView setHidden:NO];
            [_mediaView setHidden:NO];
            
            [_shareImage setHidden:YES];
            [_brushView setHidden:YES];
            
            break;
        }
        case RS_media_stop: { // 影音播放停止
            [_myView setHidden:NO];
            [_peerView setHidden:NO];
            [_mediaView setHidden:NO];
            
            [_shareImage setHidden:YES];
            [_brushView setHidden:YES];
            
            break;
        }
        case RS_share_start: { // 屏幕共享开始
            [_myView setHidden:NO];
            [_peerView setHidden:NO];
            [_mediaView setHidden:YES];
            
            [_shareImage setHidden:NO];
            [_brushView setHidden:YES];
            
            [_shareImage setImage:nil];
            
            if (_toolView.alpha == 1) {
                [self _showOrDismissToolView];
            }
            
            break;
        }
        case RS_share_stop: { // 屏幕共享停止
            [_myView setHidden:NO];
            [_peerView setHidden:YES];
            [_mediaView setHidden:NO];
            
            [_shareImage setHidden:YES];
            [_brushView setHidden:YES];
            
            break;
        }
        case RS_brush_start: { // 标注开始
            [_myView setHidden:NO];
            [_peerView setHidden:NO];
            [_mediaView setHidden:YES];
            [_shareImage setHidden:NO];
            [_brushView setHidden:NO];
            
            if (_toolView.alpha == 1) {
                [self _showOrDismissToolView];
            }
            
            _enableMark = [[CloudroomVideoMeeting shareInstance] isEnableOtherMark];
            
            break;
        }
        case RS_brush_stop: { // 标注停止
            [_myView setHidden:NO];
            [_peerView setHidden:NO];
            [_mediaView setHidden:YES];
            [_shareImage setHidden:NO];
            [_brushView setHidden:YES];
            
            break;
        }
        case RS_exit: { // 入会
            [_mediaView setHidden:YES];
            [_myView setHidden:YES];
            [_peerView setHidden:YES];
            [_shareImage setHidden:YES];
            [_brushView setHidden:YES];
            
            // 离会操作
            [self _exitMeeting];
            
            break;
        }
        default: break;
    }
}

/* 设置默认分辨率(640*360) */
- (void)_setDefaultRatio
{
    /* 640x320 */
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:VSIZE_SZ_360 inSection:0];
    [self tableView:_tableView didSelectRowAtIndexPath:indexPath];
}

/* 设置默认优先级(画质优先) */
- (void)_setDefaultPriority
{
    /* 画质优先 */
    [self _handlePriority:_smoothBtn];
}

/* 设置默认本地视频宽高比优先级(16:9) */
- (void)_setDefaultWHRate
{
    /* 16 : 9 */
    [self _handleWHRate:_sixteenPointNineBtn];
}

/* 获取默认宽高比 */
- (void)_getDefaultWHRate
{
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [videoMeeting getVideoCfg];
    _curWHRate = vCfg.whRate;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

/* 入会操作 */
- (void)_enterMeeting
{
    // 发送"入会"命令
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *nickname = [[RecordHelper shareInstance] nickname];
    [cloudroomVideoMeeting enterMeeting:_meetInfo.ID pswd:_meetInfo.pswd userID:nickname nikeName:nickname];
}

/* 入会成功 */
- (void)_enterMeetingSuccess
{
    [HUDUtil hudShow:@"成功进入会话" delay:3 animated:YES];
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    // 自己的麦克风/扬声器
    [cloudroomVideoMeeting openMic:myUserID];
    [cloudroomVideoMeeting setMicVolume:100];
    [cloudroomVideoMeeting setSpeakerVolume:100];
    RLog(@"mic:%d speaker:%d", [cloudroomVideoMeeting getMicVolume], [cloudroomVideoMeeting getSpeakerVolume]);
    
    // 自己的摄像头
    [cloudroomVideoMeeting openVideo:myUserID];
    [self _setupCamera];
    [self _setCamera];
    [self _updateOpenAndCloseCamera];
    [self _updateOpenAndCloseMic];
    
    // 观看对方视频
    if ([cloudroomVideoMeeting isUserInMeeting:_peerID]) {
        [self _subscribleCamera];
        [_titleLabel setText:[NSString stringWithFormat:@"您正在和%@会话中...", _peerID]];
    }
    
    // 设置默认分辨率
    [self _setDefaultRatio];
    // 设置默认优先级
    [self _setDefaultPriority];
    
    _mediaState = [[[CloudroomVideoMeeting shareInstance] getMediaInfo] state];
    
    // 获取本地默认视频宽高比
    [self _setDefaultWHRate];
    
    [self _queryMembers];
    
    NSString *backPath = [PathUtil searchPathInCacheDir:@"CloudroomVideoSDK/back.png"];
    NSString *fontPath = [PathUtil searchPathInCacheDir:@"CloudroomVideoSDK/font.png"];
    
    if (backPath.length) {
        [[CloudroomVideoMgr shareInstance] sendFile:_peerID fileName:backPath];
    }
    
    if (fontPath.length) {
        [[CloudroomVideoMgr shareInstance] sendFile:_peerID fileName:fontPath];
    }
    
    //开启屏幕共享
    [cloudroomVideoMeeting startScreenShare];
    AppDelegate *deleget =  (AppDelegate*)[UIApplication sharedApplication].delegate;
    UIImageView* imageView= [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"mouse"]];
    imageView.frame = CGRectMake(0, 0, 20, 20);
    [imageView setHidden:YES];
    [[UIApplication sharedApplication].keyWindow addSubview:imageView];
    deleget.imageView = imageView;
}

- (void)_queryMembers
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSMutableArray <MemberInfo *> *members = [cloudroomVideoMeeting getAllMembers];
    NSString *myID = [cloudroomVideoMeeting getMyUserID];
    NSUInteger count = [members count];
    
    switch (count) {
        case 1: {
            _peerView.userID = nil;
            [_peerView clearFrame];
            
            _mediaView.userID = nil;
            [_mediaView clearFrame];
            
            break;
        }
        case 2: {
            if (_mediaState == MEDIA_START || _mediaState == MEDIA_PAUSE || _isShare) {
                _mediaView.userID = nil;
                [_mediaView clearFrame];
            }
            else {
                _peerView.userID = nil;
                [_peerView clearFrame];
            }
            
            break;
        }
        case 3: break;
        default: {
            _myView = nil;
            _peerView.userID = nil;
            _mediaView.userID = nil;
            [_myView clearFrame];
            [_peerView clearFrame];
            [_mediaView clearFrame];
            
            break;
        }
    }
    
    // FIXME:三方会话,一方退出,IM 聊天记录问题 added by king 20180329
    // 更新对端昵称
    /*
     if (count == 2) {
     for (MemberInfo *member in members) {
     if (![member.userId isEqualToString:myID]) {
     _peerID = member.userId;
     break;
     }
     }
     }
     */
    
    RLog(@"[======> Query Members <======]");
    for (MemberInfo *member in members) {
        NSLog(@"userId:%@ nickName:%@", member.userId, member.nickName);
        
        if ([member.userId isEqualToString:myID]) {
            _myView.userID = member.userId;
        }
        else if ([member.userId isEqualToString:_peerID]) {
            if (_mediaState == MEDIA_START || _mediaState == MEDIA_PAUSE || _isShare) {
                _peerView.userID = member.userId;
            }
            else {
                _mediaView.userID = member.userId;
            }
        }
        else if (![NSString stringCheckEmptyOrNil:member.userId]) {
            _peerView.userID = member.userId;
        }
    }
    
    [_myView setHidden:_myView.userID == nil];
    [_peerView setHidden:_peerView.userID == nil];
    [_mediaView setHidden:_mediaView.userID == nil];
}

/* 入会失败 */
- (void)_enterMeetingFail:(NSString *)message
{
    if (![NSString stringCheckEmptyOrNil:_callID]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
            [[CloudroomVideoMgr shareInstance] hungupCall:_callID usrExtDat:nil cookie:cookie];
            // 跳转"登录"界面
            [self _jumpToLogin];
        }];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 更新状态机
            [self _updateWithState:RS_enter];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:NO completion:nil];
    }
}

/* 设置摄像头信息 */
- (void)_setCamera
{
    if ([_cameraArray checkEmptyOrNil]) {
        RLog(@"没有摄像头!");
        return;
    }
    
    if (_curCameraIndex >= [_cameraArray count]) {
        RLog(@"摄像头索引越界!");
        return;
    }
    
    // 设置摄像头设备
    UsrVideoInfo *video = [_cameraArray objectAtIndex:_curCameraIndex];
    [[CloudroomVideoMeeting shareInstance] setDefaultVideo:video.userId videoID:video.videoID];
    RLog(@"当前摄像头为:%zd", _curCameraIndex);
}

/* 打开/关闭摄像头UI更新 */
- (void)_updateOpenAndCloseCamera
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    VIDEO_STATUS status = [cloudroomVideoMeeting getVideoStatus:myUserID];
    if (status == VOPEN || status == VOPENING) {
        [_opencloseBtn setTitle:@"关闭摄像头" forState:UIControlStateNormal];
    }
    else {
        [_opencloseBtn setTitle:@"打开摄像头" forState:UIControlStateNormal];
    }
    
    [self _updateExchangeBtn];
}

/* 打开/关闭麦克风UI更新 */
- (void)_updateOpenAndCloseMic
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    AUDIO_STATUS status = [cloudroomVideoMeeting getAudioStatus:myUserID];
    if (status == AOPEN || status == AOPENING) {
    }
    else {
    }
}

/* 切换摄像头UI更新 */
- (void)_updateExchangeBtn
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSMutableArray <UsrVideoId *> *watchableVideos = [cloudroomVideoMeeting getWatchableVideos];
    
    if ([watchableVideos count] > 0) {
        [cloudroomVideoMeeting watchVideos:watchableVideos];
    }
    
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    NSMutableArray <UsrVideoInfo *> *videos = [cloudroomVideoMeeting getAllVideoInfo:myUserID];
    VIDEO_STATUS status = [cloudroomVideoMeeting getVideoStatus:myUserID];
    BOOL isShow = (status == VOPEN || status == VOPENING) && [videos count] > 1;
    [_exchangeBtn setHidden:!isShow];
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

- (void)_jumpToChat
{
    // 跳转到"聊天"界面
    UIStoryboard *record = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    ChatController *chatVC = [record instantiateViewControllerWithIdentifier:@"ChatController"];
    chatVC.callID = _callID;
    chatVC.peerID = _peerID;
    
    if (chatVC) {
        [self.navigationController pushViewController:chatVC animated:YES];
    }
}

/* 注销 */
- (void)_handleHangup
{
    RLog(@"");
    
    [self _showOrDismissToolView];
    
    if ([NSString stringCheckEmptyOrNil:_callID]) {
        [HUDUtil hudShow:@"callID为空" delay:3 animated:YES];
        return;
    }

    // FIXME:web端挂断,这边alert再挂断可能会造成"callID无效"
    NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    [[CloudroomVideoMgr shareInstance] hungupCall:_callID usrExtDat:nil cookie:cookie];
    
    // 更新状态机
    [self _updateWithState:RS_exit];
}

/* 切换摄像头 */
- (void)_handleExchangeCamera
{
    RLog(@"");
    
    [self _showOrDismissToolView];
    
    if ([_cameraArray count] <= 1) {
        RLog(@"无法切换摄像头!");
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

/* 打开/关闭摄像头 */
- (void)_handleOpenOrCloseCamera
{
    RLog(@"");
    
    [self _showOrDismissToolView];
    
    // 开/关自己的摄像头
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    
    if ([_opencloseBtn.currentTitle isEqualToString:@"打开摄像头"]) {
        [cloudroomVideoMeeting openVideo:myUserID];
    }
    else {
        [cloudroomVideoMeeting closeVideo:myUserID];
        [_myView clearFrame];
    }
}

/* 分辨率 */
- (void)_handleRatio
{
    RLog(@"");
    [self _showOrDismissToolView];
    [self _priorityDismiss];
    [self _ratioShow];
    [self _whrateDismiss];
}

/* 优先级 */
- (void)_handlePriority
{
    RLog(@"");
    [self _showOrDismissToolView];
    [self _ratioDismiss];
    [self _priorityShow];
    [self _whrateDismiss];
}

/**
 优先级按钮UI更新
 @param sender 按钮对象
 */
- (void)_handlePriority:(UIButton *)sender
{
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [videoMeeting getVideoCfg];
    
    if ([sender tag] == RecordBtnSmooth) {
        [vCfg setMinQuality:22];
        [vCfg setMaxQuality:25];
        _curPriorityText = @"画质优先";
        [_priorityBtn setTitle:@"画质优先" forState:UIControlStateNormal];
    }
    else if ([sender tag] == RecordBtnSpeed) {
        [vCfg setMinQuality:22];
        [vCfg setMaxQuality:36];
        _curPriorityText = @"速度优先";
        [_priorityBtn setTitle:@"速度优先" forState:UIControlStateNormal];
    }
    
    [videoMeeting setVideoCfg:vCfg];
    [self _priorityDismiss];
}

/* 宽高比 */
- (void)_handleWHRate
{
    RLog(@"");
    [self _showOrDismissToolView];
    [self _ratioDismiss];
    [self _priorityDismiss];
    [self _whrateShow];
}

- (void)_handleWHRate:(UIButton *)sender
{
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [videoMeeting getVideoCfg];
    NSInteger tag = [sender tag];
    
    if (tag == RecordBtnWHRate16Point9) {
        vCfg.whRate = WHRATE_16_9;
        [_whrateBtn setTitle:@"16 : 9" forState:UIControlStateNormal];
    }
    else if (tag == RecordBtnWHRate4Point3) {
        vCfg.whRate = WHRATE_4_3;
        [_whrateBtn setTitle:@"4 : 3" forState:UIControlStateNormal];
    }
    else if (tag == RecordBtnWHRate1Point1) {
        vCfg.whRate = WHRATE_1_1;
        [_whrateBtn setTitle:@"1 : 1" forState:UIControlStateNormal];
    }
    
    [videoMeeting setVideoCfg:vCfg];
    
    [self _getDefaultWHRate];
    [self _whrateDismiss];
}

- (void)_handleChat
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSMutableArray <MemberInfo *> *members = [cloudroomVideoMeeting getAllMembers];
    NSUInteger count = [members count];
    
    if (count >= 3) {
        [HUDUtil hudShow:@"三方会话无法使用聊天功能!" delay:3 animated:YES];
        return;
    }
    
    [self _jumpToChat];
}

/* 分辨率视图显示/隐藏 */
- (void)_ratioShow
{
    [_tableView reloadData];
    [UIView animateWithDuration:0.25 animations:^{
        [_ratioView setAlpha:1.0];
    }];
}

- (void)_ratioDismiss
{
    [UIView animateWithDuration:0.25 animations:^{
        [_ratioView setAlpha:0];
    }];
}

/* 优先级视图显示/隐藏 */
- (void)_priorityShow
{
    if ([_curPriorityText isEqualToString:@"画质优先"]) {
        [_smoothBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
        [_speedBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
    }
    else if ([_curPriorityText isEqualToString:@"速度优先"]) {
        [_smoothBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
        [_speedBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [_priorityView setAlpha:1.0];
    }];
}

- (void)_priorityDismiss
{
    [UIView animateWithDuration:0.25 animations:^{
        [_priorityView setAlpha:0];
    }];
}

/* 宽高比视图显示 */
- (void)_whrateShow
{
    if (_curWHRate == WHRATE_16_9) {
        [_sixteenPointNineBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
        [_fourPointThreeBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
        [_onePointOneBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
    }
    else if (_curWHRate == WHRATE_4_3) {
        [_sixteenPointNineBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
        [_fourPointThreeBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
        [_onePointOneBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
    }
    else if (_curWHRate == WHRATE_1_1) {
        [_sixteenPointNineBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
        [_fourPointThreeBtn.layer setBorderColor:UIColorFromRGB(0xFFFFFF).CGColor];
        [_onePointOneBtn.layer setBorderColor:UIColorFromRGB(0xFE6715).CGColor];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [_whrateView setAlpha:1.0];
    }];
}

/* 宽高比视图隐藏 */
- (void)_whrateDismiss
{
    [UIView animateWithDuration:0.25 animations:^{
        [_whrateView setAlpha:0];
    }];
}

/* 工具栏显示/隐藏 */
- (void)_showOrDismissToolView
{
    /*
     // 透明通道测试 added by king 201712071705(注意:callerID为对端昵称)
     NSString *value = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
     NSDictionary *info = @{@"name" : value};
     // 对端:_callerID 自己:[[CloudroomVideoMeeting shareInstance] getMyUserID]
     [[CloudroomVideoMgr shareInstance] sendCmd:_callerID data:[info mj_JSONString]];
     */
    
    [UIView animateWithDuration:0.25 animations:^{
        [_toolView setAlpha:_toolView.alpha == 1 ? 0 : 1];
    }];
}

- (void)_r_updateUIScreen
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) { // iPad
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown: {
                if (_curWHRate == WHRATE_16_9) {
                    [_myViewLW setConstant:90];
                    [_myViewLH setConstant:160];
                }
                else if (_curWHRate == WHRATE_4_3) {
                    [_myViewLW setConstant:90];
                    [_myViewLH setConstant:120];
                }
                else if (_curWHRate == WHRATE_1_1) {
                    [_myViewLW setConstant:120];
                    [_myViewLH setConstant:120];
                }
                
                CGFloat ratio = _peerRatio.height / _peerRatio.width;
                CGFloat width = self.view.bounds.size.width;
                CGFloat height = self.view.bounds.size.height;
                
                if (ratio == 1) { // 1 : 1
                    [_mediaViewW setConstant:width];
                    [_mediaViewH setConstant:width];
                    [_peerViewW setConstant:120];
                    [_peerViewH setConstant:120];
                }
                else if (ratio == 0.75) { // 3 : 4
                    [_mediaViewW setConstant:width];
                    [_mediaViewH setConstant:width * 0.75];
                    [_peerViewW setConstant:160];
                    [_peerViewH setConstant:120];
                }
                else { // 9 : 16
                    [_mediaViewW setConstant:width];
                    [_mediaViewH setConstant:width * 9 / 16];
                    [_peerViewW setConstant:160];
                    [_peerViewH setConstant:90];
                }
                
                [_brushView setBrushWidth:1];
                
                break;
            }
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight: {
                if (_curWHRate == WHRATE_16_9) {
                    [_myViewLW setConstant:160];
                    [_myViewLH setConstant:90];
                }
                else if (_curWHRate == WHRATE_4_3) {
                    [_myViewLW setConstant:120];
                    [_myViewLH setConstant:90];
                }
                else if (_curWHRate == WHRATE_1_1) {
                    [_myViewLW setConstant:120];
                    [_myViewLH setConstant:120];
                }
                
                // FIXME:iPad 远端(Web)视频在本地显示被拉伸 modified by king 201709071638
                CGFloat ratio = _peerRatio.height / _peerRatio.width;
                CGFloat width = self.view.bounds.size.width;
                CGFloat height = self.view.bounds.size.height;
                
                if (ratio == 1) { // 1 : 1
                    [_mediaViewW setConstant:height];
                    [_mediaViewH setConstant:height];
                    [_peerViewW setConstant:120];
                    [_peerViewH setConstant:120];
                }
                else if (ratio == 0.75) { // 3 : 4
                    [_mediaViewW setConstant:height * 4 / 3];
                    [_mediaViewH setConstant:height];
                    [_peerViewW setConstant:160];
                    [_peerViewH setConstant:120];
                }
                else { // 9 : 16
                    [_mediaViewW setConstant:width];
                    [_mediaViewH setConstant:width * 9 / 16];
                    [_peerViewW setConstant:160];
                    [_peerViewH setConstant:90];
                }
                
                if (_toolView.alpha == 1) {
                    [self _showOrDismissToolView];
                }
                
                _brushView.brushWidth = 1 * (([UIScreen mainScreen].bounds.size.width)) / ([UIScreen mainScreen].bounds.size.height);
                
                break;
            }
            default: break;
        }
    }
    else {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown: {
                if (_curWHRate == WHRATE_16_9) {
                    [_myViewPW setConstant:90];
                    [_myViewPH setConstant:160];
                }
                else if (_curWHRate == WHRATE_4_3) {
                    [_myViewPW setConstant:90];
                    [_myViewPH setConstant:120];
                }
                else if (_curWHRate == WHRATE_1_1) {
                    [_myViewPW setConstant:120];
                    [_myViewPH setConstant:120];
                }
                
                CGFloat ratio = _peerRatio.height / _peerRatio.width;
                CGFloat width = self.view.bounds.size.width;
                
                if (ratio == 1) { // 1 : 1
                    [_mediaViewW setConstant:width];
                    [_mediaViewH setConstant:width];
                    [_peerViewW setConstant:120];
                    [_peerViewH setConstant:120];
                }
                else if (ratio == 0.75) { // 3 : 4
                    [_mediaViewW setConstant:width];
                    [_mediaViewH setConstant:width * 0.75];
                    [_peerViewW setConstant:120];
                    [_peerViewH setConstant:160];
                }
                else { // 9 : 16
                    // FIXME:远端视频随机会有白线闪现 modified by king 201712061739
                    [_mediaViewW setConstant:floor(width)];
                    [_mediaViewH setConstant:floor(width * 9 / 16.0)];
                    [_peerViewW setConstant:90];
                    [_peerViewH setConstant:160];
                }
                
                [_brushView setBrushWidth:1];
                
                break;
            }
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight: {
                if (_curWHRate == WHRATE_16_9) {
                    [_myViewLW setConstant:160];
                    [_myViewLH setConstant:90];
                }
                else if (_curWHRate == WHRATE_4_3) {
                    [_myViewLW setConstant:120];
                    [_myViewLH setConstant:90];
                }
                else if (_curWHRate == WHRATE_1_1) {
                    [_myViewLW setConstant:120];
                    [_myViewLH setConstant:120];
                }
                
                if (_toolView.alpha == 1) {
                    [self _showOrDismissToolView];
                }
                
                CGFloat ratio = _peerRatio.height / _peerRatio.width;
                CGFloat width = self.view.bounds.size.width;
                CGFloat height = self.view.bounds.size.height;
                
                if (ratio == 1) { // 1 : 1
                    [_mediaViewW setConstant:height];
                    [_mediaViewH setConstant:height];
                    [_peerViewW setConstant:120];
                    [_peerViewH setConstant:120];
                }
                else if (ratio == 0.75) { // 3 : 4
                    [_mediaViewW setConstant:height * 4 / 3];
                    [_mediaViewH setConstant:height];
                    [_peerViewW setConstant:160];
                    [_peerViewH setConstant:120];
                }
                else { // 9 : 16
                    [_mediaViewW setConstant:width];
                    [_mediaViewH setConstant:height];
                    [_peerViewW setConstant:160];
                    [_peerViewH setConstant:90];
                }
                
                _brushView.brushWidth = 1 * (([UIScreen mainScreen].bounds.size.width)) / ([UIScreen mainScreen].bounds.size.height);
                
                break;
            }
            default: break;
        }
    }
    
    CGFloat width = _shareView.bounds.size.width;
    CGFloat height = _shareView.bounds.size.height;
    CGFloat shareW = 0;
    CGFloat shareH = 0;
    
    if (_brushView.shareSrcSize.width == 0 || _brushView.shareSrcSize.height == 0) {
        shareW = 0;
        shareH = 0;
    }
    else {
        shareW = width;
        shareH = width * _brushView.shareSrcSize.height / _brushView.shareSrcSize.width;
        
        if (shareH > height) {
            shareH = height;
            shareW = height * _brushView.shareSrcSize.width / _brushView.shareSrcSize.height;
        }
    }
    
    _shareW.constant = shareW;
    _shareH.constant = shareH;
    
    RLog(@"view:%@ mediaView:%@ peerView:%@", NSStringFromCGRect(self.view.bounds), NSStringFromCGRect(_mediaView.bounds), NSStringFromCGRect(_peerView.bounds));
}

/**
 处理视频数据
 @param data 视频数据
 @param w 宽
 @param h 高
 */

/*
 - (void)_handleShareData:(unsigned char *)data width:(int)w height:(int)h
 {
 long size = w * h;
 if (size <= 0) {
 RLog(@"width or height is 0!");
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
 [_shareImage setImage:image];
 }
 
 */

/* 离开会议 */
- (void)_exitMeeting
{
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    AppDelegate *deleget =  (AppDelegate*)[UIApplication sharedApplication].delegate;
    if([cloudroomVideoMeeting isScreenShareStarted])
    {
        [cloudroomVideoMeeting stopScreenShare];
        [deleget.imageView removeFromSuperview];
    }
    
    [[CloudroomVideoMeeting shareInstance] exitMeeting];
    [self _popToRoot];
   
}

- (void)_popToRoot
{
    [self.navigationController popToRootViewControllerAnimated:YES];
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

- (IBAction)testScreenshare:(id)sender {
    
    TestScreenShareTableViewController *vc = [[TestScreenShareTableViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([touches.anyObject.view isEqual:self.view] ||
        [touches.anyObject.view isEqual:_mediaView] ||
        [touches.anyObject.view isEqual:_shareView] ||
        [touches.anyObject.view isEqual:_shareImage]) {
        [self _showOrDismissToolView];
    }
}

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
