//
//  MeetingController.m
//  Meeting
//
//  Created by king on 2017/11/14.
//  Copyright © 2017年 BossKing10086. All rights reserved.
//

#import "MeetingController.h"

#import "MContentView.h"
#import "MBottomView.h"
#import "MTopView.h"
#import "MFrameView.h"
#import "MRatioView.h"
#import "MShareView.h"
#import "MChatView.h"

#import "MTwoView.h"
#import "MTwoOneView.h"
#import "MTwoTwoView.h"

#import "MFourView.h"
#import "MFourOneView.h"
#import "MFourTwoView.h"
#import "MFourThreeView.h"
#import "MFourFourView.h"

#import "MNineView.h"
#import "MNineOneView.h"
#import "MNineTwoView.h"
#import "MNineThreeView.h"
#import "MNineFourView.h"
#import "MNineFiveView.h"
#import "MNineSixView.h"
#import "MNineSevenView.h"
#import "MNineEgihtView.h"
#import "MNineNineView.h"

#import "AppDelegate.h"
#import "VideoMeetingCallBack.h"
#import "VideoMgrCallBack.h"
#import "MeetingHelper.h"
#import "SDKUtil.h"
#import "IQKeyboardManager.h"
#import "MChatModel.h"

@interface MeetingController () <VideoMeetingDelegate, VideoMgrDelegate, BKBrushViewDelegate>

@property (nonatomic, weak) IBOutlet MContentView *contentView; /**< 分屏 */
@property (nonatomic, weak) IBOutlet MBottomView *bottomView; /**< 操作 */
@property (nonatomic, weak) IBOutlet MFrameView *frameView; /**< 帧率视*/
@property (nonatomic, weak) IBOutlet MRatioView *ratioView; /**< 分辨率 */
@property (nonatomic, weak) IBOutlet MShareView *shareView; /**< 屏幕共享 */
@property (nonatomic, strong) MChatView *chatView; /**< IM */

@property (nonatomic, strong) NSMutableArray<UsrVideoId *> *members; /**< 会议成员 */
@property (nonatomic, copy) NSArray<NSString *> *ratioArr; /**< 分辨率集合 */
@property (nonatomic, copy) NSArray<UsrVideoInfo *> *cameraArray; /**< 摄像头集合 */
@property (nonatomic, strong) NSMutableArray<MChatModel *> *messages;
@property (nonatomic, assign) NSInteger curCameraIndex; /**< 当前摄像头索引 */
@property (nonatomic, strong) UIAlertController *dropVC; /**< 掉线弹框 */
@property (nonatomic, assign) BOOL enableMark; /**< 标注? */

@end

@implementation MeetingController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self _commonSetup];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[IQKeyboardManager sharedManager] setEnable:YES];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[IQKeyboardManager sharedManager] setEnable:NO];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
    
    // 不灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // FIXME:屏幕共享结束回调接收不到 added by king 20170905
    [self _updateDelegate];
}

#pragma mark - VideoMgrDelegate
// 掉线通知
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr {
    if (_dropVC) {
        [_dropVC dismissViewControllerAnimated:NO completion:^{
            _dropVC = nil;
            
            if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
                [self _showAlert:@"您已被踢下线!"];
            } else { // 掉线
                [self _showAlert:@"您已掉线!"];
            }
        }];
        return;
    }
    
    if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
        [self _showAlert:@"您已被踢下线!"];
    } else { // 掉线
        [self _showAlert:@"您已掉线!"];
    }
}

#pragma mark - VideoMeetingDelegate
// 入会结果
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback enterMeetingRslt:(CRVIDEOSDK_ERR_DEF)code {
    [HUDUtil hudHiddenProgress:YES];
    
    if (code == CRVIDEOSDK_NOERR) {
        [self _enterMeetingSuccess];
    } else if (code == CRVIDEOSDK_MEETROOMLOCKED) {// FIXME:会议加锁后,进入会议提示语不正确 added by king 201711291513
        [self _enterMeetingFail:@"会议已加锁!"];
    } else {
        [self _enterMeetingFail:@"进入会议失败!"];
    }
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback userEnterMeeting:(NSString *)userID {
    NSString *text = [NSString stringWithFormat:@"%@进入会议!", userID];
    [HUDUtil hudShow:text delay:3 animated:YES];
    
    for (MemberInfo *member in [[CloudroomVideoMeeting shareInstance] getAllMembers]) {
        MLog(@"userId:%@ nickName:%@", member.userId, member.nickName);
    }
    
    [self _subscribeCamera];
    [self _updateVideoInfo];
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback userLeftMeeting:(NSString *)userID {
    NSString *text = [NSString stringWithFormat:@"%@离开会议!", userID];
    [HUDUtil hudShow:text delay:3 animated:YES];
    
    [self _subscribeCamera];
    [self _updateVideoInfo];
}

// 会议被结束
- (void)videoMeetingCallBackMeetingStopped:(VideoMeetingCallBack *)callback {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"会议已结束!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self _jumpToPMeeting];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// 会议掉线
- (void)videoMeetingCallBackMeetingDropped:(VideoMeetingCallBack *)callback {
    [self _showReEnter:@"会议掉线!"];
}

// 成员有新的视频图像数据到来(通过GetVideoImg获取
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyVideoData:(UsrVideoId *)userID frameTime:(long)frameTime {
    @autoreleasepool {
        VideoFrame *rawFrame = [[CloudroomVideoMeeting shareInstance] getVideoImg:userID];
        
        if (!rawFrame) {
            MLog(@"rawFrame nil!");
            return;
        }
        
        int length = (int)(rawFrame.datLength);
        if (length <= 0) {
            MLog(@"length equal to 0!");
            return;
        }
        
        int width = rawFrame.frameWidth;
        int height = rawFrame.frameHeight;
        int sum = width * height;
        
        if (sum <= 0) {
            MLog(@"width or height equal to 0!");
            return;
        }
        
        if (1.5 * sum != length) {
            MLog(@"data.length not equal to width * height * 1.5!");
            return;
        }
        
        if (rawFrame.fmt != VFMT_YUV420P) {
            MLog(@"get VFMT_YUV420P error!");
            return;
        }
        
        [_contentView displayFrame:rawFrame userID:(UsrVideoId *)userID width:width height:height];
    }
}

// 本地音频设备有变化
- (void)videoMeetingCallBackAudioDevChanged:(VideoMeetingCallBack *)callback {
    [self _updateMic];
}

// 音频设备状态变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback audioStatusChanged:(NSString *)userID oldStatus:(AUDIO_STATUS)oldStatus newStatus:(AUDIO_STATUS)newStatus {
    [self _updateMic];
}

// 视频设备状态变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback videoStatusChanged:(NSString *)userID oldStatus:(VIDEO_STATUS)oldStatus newStatus:(VIDEO_STATUS)newStatus {
    [self _setCamera];
    [self _updateCamera];
    
    // 订阅摄像头
    [self _subscribeCamera];
    [self _updateVideoInfo];
}

// 本地视频设备有变化
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback videoDevChanged:(NSString *)userID {
    [self _setCamera];
    [self _updateCamera];
    
    // 订阅摄像头
    [self _subscribeCamera];
    [self _updateVideoInfo];
}

// 屏幕共享操作通知
- (void)videoMeetingCallBackNotifyScreenShareStarted:(VideoMeetingCallBack *)callback {
    [HUDUtil hudShow:@"屏幕共享已开始" delay:3 animated:YES];
    
    _shareView.alpha = 1.0;
}

- (void)videoMeetingCallBackNotifyScreenShareStopped:(VideoMeetingCallBack *)callback {
    [HUDUtil hudShow:@"屏幕共享已结束" delay:3 animated:YES];
    
    _shareView.alpha = 0;
}

// 屏幕共享数据更新,用户收到该回调消息后应该调用getShareScreenDecodeImg获取最新的共享数据
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyScreenShareData:(NSString *)userID changedRect:(CGRect)changedRect frameSize:(CGSize)size {
    ScreenShareImg *shareData = [[CloudroomVideoMeeting shareInstance] getShareScreenDecodeImg];
    
    if(!shareData) {
        return;
    }
    
    if (shareData.datLength != 4 * shareData.rgbWidth * shareData.rgbHeight) {
        return;
    }
    
    // FIXME:区域共享被拉伸 modified by king 201711201338
    // FIXME:部分区域共享被拉伸 modified by king 201711231753
    if ((_shareView.shareSrcSize.width == 0 && _shareView.shareSrcSize.height == 0) ||
        (_shareView.shareSrcSize.width != size.width || _shareView.shareSrcSize.height!= size.height)) {
        _shareView.shareSrcSize = size;
    }
    
    [_shareView.shareImageView handleShareData:shareData->rgbDat width:shareData.rgbWidth height:shareData.rgbHeight];
}

// 视频墙分屏模式回调(0:互看 1:1分屏 2:2分屏 3:4分屏 4:5分屏 5:6分屏 6:9分屏 7:13分屏 8:16分屏)
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyVideoWallMode:(int)wallMode {
}

// IM 消息发送结果
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback sendIMmsgRlst:(NSString *)taskID sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie {
    if (sdkErr != CRVIDEOSDK_NOERR) {
        [HUDUtil hudShow:@"消息发送失败" delay:3 animated:YES];
    }
}

// 通知收到 IM 消息
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyIMmsg:(NSString *)romUserID text:(NSString *)text sendTime:(int)sendTime {
    if (![_chatView isShow]) {
        [_chatView showAnimation];
    }
    
    MChatModel *chatModel = [[MChatModel alloc] initWithName:romUserID content:text];
    [self.messages addObject:chatModel];
    _chatView.message = [self.messages copy];
}

// 屏幕共享标注开始回调
- (void)videoMeetingCallBackNotifyScreenMarkStarted:(VideoMeetingCallBack *)callback {
    [_shareView.brushView clean];
    
    // 更新状态机
    _enableMark = [[CloudroomVideoMeeting shareInstance] isEnableOtherMark];
    
    NSLog(@"enableOtherMark:%@", _enableMark ? @"YES" : @"NO");
}

// 屏幕共享标注停止回调
- (void)videoMeetingCallBackNotifyScreenMarkStopped:(VideoMeetingCallBack *)callback {
    [_shareView.brushView clean];
}

// 屏幕共享是否允许他人标注回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback enableOtherMark:(BOOL)enable {
    _enableMark = enable;
    
    NSLog(@"enableOtherMark:%@", _enableMark ? @"YES" : @"NO");
}

// 屏幕共享标注回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback sendMarkData:(MarkData *)markData {
    if (markData.termid != 0) {
        [_shareView.brushView drawLine:markData];
    }
}

// 屏幕共享所有标注回调
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback sendAllMarkData:(NSArray<MarkData *> *)markDatas {
    for (MarkData *markData in markDatas) {
        [_shareView.brushView drawLine:markData];
    }
}

// 清除所有屏幕共享标注回调
- (void)videoMeetingCallBackClearAllMarks:(VideoMeetingCallBack *)callback {
    [_shareView.brushView clean];
}

#pragma mark - BKBrushViewDelegate
- (void)brushView:(CLBrushView *)brushView touchEndWithMarkData:(MarkData *)markData {
    if (_enableMark && _shareView.alpha != 0) {
        [[CloudroomVideoMeeting shareInstance] sendMarkData:markData];
    }
}

#pragma mark - private method
- (void)_commonSetup {
    // 设置属性
    [self _setupProperty];
    // 更新代理
    [self _updateDelegate];
    // 入会操作
    [self _enterMeeting];
}

/**
 设置属性
 */
- (void)_setupProperty {
    /* 聊天 */
    MChatView *chatView = [[MChatView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:chatView];
    [self.view insertSubview:chatView belowSubview:_bottomView];
    _chatView = chatView;
    [_chatView setTextFieldShouldReturn:^(MChatView *chatView, NSString *text) {
        NSLog(@"send message:%@", text);
        // 发送 IM 消息
        CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
        NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
        [cloudroomVideoMeeting sendIMmsg:text toUserID:nil cookie:cookie];
    }];
    [_chatView setTitle:[NSString stringWithFormat:@"会议ID:%d", _meetInfo.ID]];
    
    _curCameraIndex = 0;
    
    weakify(self)
    [_bottomView setResponse:^(MBottomView *view, UIButton *sender) {
        strongify(wSelf)
        
        switch ([sender tag]) {
            case MBottomViewBtnTypeMic: {
                [sSelf _handleMic:sender];
                break;
            }
            case MBottomViewBtnTypeCamera: {
                [sSelf _handleCamera:sender];
                break;
            }
            case MBottomViewBtnTypeChat: {
                [sSelf _handleChat];
                break;
            }
            case MBottomViewBtnTypeExCamera: {
                [sSelf _handleExCamera];
                break;
            }
            case MBottomViewBtnTypeRatio: {
                [sSelf _handleRatio];
                break;
            }
            case MBottomViewBtnTypeExit: {
                [sSelf _handleExit];
                break;
            }
            case MBottomViewBtnTypeFrame: {
                [wSelf _handleFrame];
                break;
            }
        }
    }];
    
    /* 分辨率 */
    _ratioView.dataSource = @[@"640*360", @"848*480", @"1280*720"];
    [_ratioView setResponse:^(MRatioView *view, UIButton *sender, NSString *value) {
        switch ([sender tag]) {
            case MRatioViewBtnTypeCancel: break;
            case MRatioViewBtnTypeDone: [SDKUtil setRatio:[SDKUtil getRatioFromString:value]]; break;
        }
    }];
    
    /* 帧率 */
    _frameView.dataSource = @[@"10", @"15", @"24"];
    [_frameView setResponse:^(MFrameView *view, UIButton *sender, NSString *value) {
        switch ([sender tag]) {
            case MFrameViewBtnTypeCancel: break;
            case MFrameViewBtnTypeDone: [SDKUtil setFps:[value intValue]]; break;
        }
    }];
    
    _shareView.brushView.backgroundColor = [UIColor clearColor];
    _shareView.brushView.brushColor = [UIColor redColor];
    _shareView.brushView.brushWidth = 1;
    _shareView.brushView.shapeType = ST_curve;
    _shareView.brushView.delegate = self;
}

- (void)_setStatusBarBG {
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = UIColorFromRGBA(0, 0, 0, 0.5);
    }
}

/**
 初始化摄像头信息
 */
- (void)_setupForCamera {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    short curVideoID = [cloudroomVideoMeeting getDefaultVideo:myUserID];
    NSMutableArray <UsrVideoInfo *> *videoes = [cloudroomVideoMeeting getAllVideoInfo:myUserID];
    NSArray<UsrVideoInfo *> *cameraArray = [videoes copy];
    
    for (UsrVideoInfo *video in videoes) {
        MLog(@"userId:%@ videoName:%@ videoID:%d", video.userId, video.videoName, video.videoID);
        
        if (curVideoID == 0) { // 没有默认设备
            curVideoID = video.videoID;
            [cloudroomVideoMeeting setDefaultVideo:myUserID videoID:curVideoID];
        }
    }
    
    if ([cameraArray count] <= 0) {
        MLog(@"获取摄像头设备为空!");
        return;
    }
    
    _cameraArray = cameraArray;
}

/**
 设置摄像头
 */
- (void)_setCamera {
    if ([_cameraArray checkEmptyOrNil]) {
        MLog(@"没有摄像头!");
        return;
    }
    
    if (_curCameraIndex >= [_cameraArray count]) {
        MLog(@"摄像头索引越界!");
        return;
    }
    
    // 设置摄像头设备
    UsrVideoInfo *video = [_cameraArray objectAtIndex:_curCameraIndex];
    [[CloudroomVideoMeeting shareInstance] setDefaultVideo:video.userId videoID:video.videoID];
    MLog(@"当前摄像头为:%zd", _curCameraIndex);
}

/**
 订阅摄像头
 */
- (void)_subscribeCamera {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSMutableArray <UsrVideoId *> *watchableVideos = [cloudroomVideoMeeting getWatchableVideos];
    
    if ([watchableVideos count] > 0) {
        [cloudroomVideoMeeting watchVideos:watchableVideos];
    }
}

/* 入会操作 */
- (void)_enterMeeting {
    if (_meetInfo.ID > 0) {
        [HUDUtil hudShowProgress:@"正在进入会议..." animated:YES];
        CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
        NSString *nickname = [[MeetingHelper shareInstance] nickname];
        [cloudroomVideoMeeting enterMeeting:_meetInfo.ID pswd:_meetInfo.pswd userID:nickname nikeName:nickname];
    }
}

/* 入会成功 */
- (void)_enterMeetingSuccess {
    // 打开本地麦克风
    [SDKUtil openLocalMic];
    // 打开本地摄像头
    [SDKUtil openLocalCamera];
    
    [self _updateMic];
    
    [self _setupForCamera];
    
    // 订阅摄像头
    [self _setCamera];
    [self _updateCamera];
    [self _subscribeCamera];
    [self _updateVideoInfo];
    
    // 设置默认分辨率: 640*360
    [SDKUtil setRatio:VSIZE_SZ_360];
    // 设置默认帧率: 15
    [SDKUtil setFps:15];
    // 设置默认优先级: 画质优先
    [SDKUtil setPriority:25 min:22];
    // 设置默认宽高比
    [SDKUtil setLocalCameraWHRate:WHRATE_1_1];
    // 白板测试
    // [self _boardTest];
}

/**
 入会失败
 @param message 失败信息
 */
- (void)_enterMeetingFail:(NSString *)message {
    [HUDUtil hudShow:message delay:3 animated:YES];
    
    if (_meetInfo.ID > 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self _jumpToPMeeting];
        }];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self _enterMeeting];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:NO completion:nil];
    }
}

/**
 重登操作
 @param message 重登信息
 */
- (void)_showReEnter:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"离开会议" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self _jumpToPMeeting];
        _dropVC = nil;
    }];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重新登录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 离开会议
        [[CloudroomVideoMeeting shareInstance] exitMeeting];
        // 重新入会
        [self _enterMeeting];
        _dropVC = nil;
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:NO completion:^{}];
    _dropVC = alertController;
}

/* 掉线/被踢下线 */
- (void)_showAlert:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self _jumpToPMeeting];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// TODO: 更新操作
/* 更新代理 */
- (void)_updateDelegate {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
    [appDelegate.videoMeetingCallBack setVideoMeetingDelegate:self];
}

/* 更新摄像头开关 UI */
- (void)_updateCamera {
    VIDEO_STATUS status = [SDKUtil getLocalCameraStatus];
    [_bottomView updateCamera:!(status == AOPEN || status == AOPENING)];
}

/* 更新麦克风开关 UI */
- (void)_updateMic {
    AUDIO_STATUS status = [SDKUtil getLocalMicStatus];
    [_bottomView updateMic:!(status == VOPEN || status == VOPENING)];
}

/* 更新会议成员 */
- (void)_updateVideoInfo {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    NSMutableArray <UsrVideoId *> *watchableVideos = [cloudroomVideoMeeting getWatchableVideos];
    NSMutableArray <UsrVideoId *> *diff = [NSMutableArray array];
    NSMutableArray <UsrVideoId *> *remove = [NSMutableArray array];
    
    // 找到不同元素
    if ([self.members count] <= 0) {
        [diff addObjectsFromArray:watchableVideos];
    }
    else {
        for (UsrVideoId *obj1 in watchableVideos) {
            BOOL find = NO;
            for (UsrVideoId *obj2 in self.members) {
                if ([obj1.userId isEqualToString:obj2.userId] && obj1.videoID == obj2.videoID) {
                    find = YES;
                    break;
                }
            }
            
            if (find == NO) {
                [diff addObject:obj1];
            }
        }
        
        // 找到删除元素
        for (UsrVideoId *obj1 in self.members) {
            BOOL find = NO;
            for (UsrVideoId *obj2 in watchableVideos) {
                if ([obj1.userId isEqualToString:obj2.userId] && obj1.videoID == obj2.videoID) {
                    find = YES;
                    break;
                }
            }
            
            if (find == NO) {
                [remove addObject:obj1];
            }
        }
        
        for (UsrVideoId *usrVideoId in remove) {
            [self.members removeObject:usrVideoId];
        }
    }
    
    [self.members addObjectsFromArray:diff];
    
    [_contentView updateUIViews:self.members localer:myUserID];
}

// TODO: 按钮响应事件
/* 开/关麦克风 */
- (void)_handleMic:(UIButton *)sender {
    if (sender.selected) {
        [SDKUtil closeLocalMic];
        
    } else {
        [SDKUtil openLocalMic];
    }
}

- (void)_handleChat {
    [_chatView clickShow];
}

/* 开/关摄像头 */
- (void)_handleCamera:(UIButton *)sender {
    if (sender.selected) {
        [SDKUtil closeLocalCamera];
    } else {
        [SDKUtil openLocalCamera];
    }
}

/* 切换摄像头 */
- (void)_handleExCamera {
    // FIXME: 切换摄像头之前,先检测是否关闭 (king 20180717)
    if (![SDKUtil isLocalCameraOpen]) {
        [HUDUtil hudShow:@"摄像头已关闭" delay:3 animated:YES];
        return;
    }
    
    if ([_cameraArray count] <= 1) {
        MLog(@"无法切换摄像头!");
        return;
    }
    
    if (_curCameraIndex == 0) {
        _curCameraIndex = 1;
    } else {
        _curCameraIndex = 0;
    }
    
    [self _setCamera];
}

/* 分辨率 */
- (void)_handleRatio {
    _ratioView.curRatio = [SDKUtil getStringFromRatio];
    [_ratioView showAnimation];
}

/* 退出 */
- (void)_handleExit {
    // FIXME: 退出会议,防止误操作 (king 20180717)
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"离开会议?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    UIAlertAction *done = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self _jumpToPMeeting];
    }];
    [alertVC addAction:cancel];
    [alertVC addAction:done];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)_handleFrame {
    _frameView.curFrame = [SDKUtil getStringFromFrame];
    [_frameView showAnimation];
}

/* 跳转到"预入会"界面 */
- (void)_jumpToPMeeting {
    // 离开会议
    [[CloudroomVideoMeeting shareInstance] exitMeeting];
    // 注销
    [[CloudroomVideoMgr shareInstance] logout];
    // 退出界面
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - getter & setter
- (NSMutableArray<UsrVideoId *> *)members {
    if (!_members) {
        _members = [NSMutableArray array];
    }
    
    return _members;
}

- (NSMutableArray<MChatModel *> *)messages {
    if (!_messages) {
        _messages = [NSMutableArray array];
    }
    
    return _messages;
}

#pragma mark - override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    
    if (![touch.view isEqual:_bottomView]) {
        if (_chatView.isShow) {
            [_chatView hideAnimation];
        } else {
            [_chatView showAnimation];
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

// TODO: 测试白板功能 (king 20180716)
- (void)_boardTest {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    SubPage *subPage = [cloudroomVideoMeeting createBoard:@"iOS's board" width:320 height:340 pageCount:1];
    // 创建白板
    [cloudroomVideoMeeting initBoardPageDat:subPage boardPageNo:0 imgID:@"" elemets:@""];
    NSString *element = @"{\"color\":4279208171,\"dot\":[{\"x\":0,\"y\":0},{\"x\":0,\"y\":0},{\"x\":4,\"y\":3},{\"x\":8,\"y\":4},{\"x\":12,\"y\":6},{\"x\":17,\"y\":7},{\"x\":23,\"y\":10},{\"x\":27,\"y\":13},{\"x\":31,\"y\":14},{\"x\":35,\"y\":16},{\"x\":40,\"y\":18},{\"x\":46,\"y\":20},{\"x\":50,\"y\":21},{\"x\":56,\"y\":22},{\"x\":63,\"y\":23},{\"x\":71,\"y\":23},{\"x\":80,\"y\":23},{\"x\":86,\"y\":23},{\"x\":92,\"y\":23},{\"x\":98,\"y\":23},{\"x\":104,\"y\":23},{\"x\":111,\"y\":23},{\"x\":121,\"y\":23},{\"x\":129,\"y\":23},{\"x\":136,\"y\":23},{\"x\":143,\"y\":23},{\"x\":149,\"y\":23},{\"x\":154,\"y\":23},{\"x\":160,\"y\":23},{\"x\":166,\"y\":23},{\"x\":171,\"y\":23},{\"x\":172,\"y\":23},{\"x\":174,\"y\":23}],\"elementID\":\"1.53\",\"left\":52,\"orderID\":1002,\"pixel\":2,\"style\":1,\"top\":74,\"type\":4}";
    // 添加白板图元
    [cloudroomVideoMeeting addBoardElement:subPage boardPageNo:0 elementData:element];
    // 删除白板图元
    [cloudroomVideoMeeting delBoardElement:subPage boardPageNo:0 elementIDs:@[@"1.53"]];
    // 关闭白板
    [cloudroomVideoMeeting closeBoard:subPage];
}
@end
