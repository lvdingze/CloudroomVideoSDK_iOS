//
//  AppDelegate.m
//  Record
//
//  Created by king on 2017/6/8.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

/*
 颜色搭配:
 橙色:FE6715
 边框:106 110 117(6A6E75)
 灰色:239 240 241(EFF0F1)
 红色:249 83 85(F95355)
 */

#import "AppDelegate.h"
#import "RecordHelper.h"
#import "FileMgrCallBack.h"
#import "VideoMeetingCallBack.h"
#import "VideoMgrCallBack.h"
#import "QueueCallBack.h"
#import "IQKeyboardManager.h"
#import "PathUtil.h"

@interface AppDelegate ()
@end

@implementation AppDelegate
#pragma mark - UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self _setupConfigure];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // FIXME:应用退出崩溃 added by king 201803091647
    [[CloudroomVideoSDK shareInstance] uninit];
}

#pragma mark - private method
- (void)_setupConfigure
{
    [self _setupForStatusBar];
    [self _setupForVideoCallSDK];
    [self _setupForIQKeyboard];
    [self _setupForDelegates];
}

- (void)_setupForStatusBar
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)_setupForVideoCallSDK
{
    RecordHelper *recordHelper = [RecordHelper shareInstance];
    [recordHelper readInfo];
    
    if ([NSString stringCheckEmptyOrNil:recordHelper.account] ||
        [NSString stringCheckEmptyOrNil:recordHelper.pswd] ||
        [NSString stringCheckEmptyOrNil:recordHelper.server]) {
        [recordHelper resetInfo];
    }
    
    SdkInitDat *sdkInitData = [[SdkInitDat alloc] init];
    CloudroomVideoSDK *cloudroomVideoSDK = [CloudroomVideoSDK shareInstance];
    // 设置 SDK 内部使用的文件位置
    [sdkInitData setSdkDatSavePath:[PathUtil searchPathInCacheDir:@"CloudroomVideoSDK"]];
    // 是否在控制台显示 SDK 日志
    [sdkInitData setShowSDKLogConsole:YES];
    [sdkInitData setNoCall:NO];
    [sdkInitData setNoQueue:NO];
    [sdkInitData setNoMediaDatToSvr:NO];
    [sdkInitData setTimeOut:10 * 1000];
    CRVIDEOSDK_ERR_DEF error = [cloudroomVideoSDK initSDK:sdkInitData];
    
    if (error != CRVIDEOSDK_NOERR) {
        RLog(@"VideoCallSDK init error!");
        [[CloudroomVideoSDK shareInstance] uninit];
    }
    
    // 获取 SDK 版本号
    NSLog(@"GetVideoCallSDKVer:%@", [CloudroomVideoSDK getCloudroomVideoSDKVer]);
}

// FIXME:修改键盘ToolBar按钮标题
- (void)_setupForIQKeyboard
{
    [[IQKeyboardManager sharedManager] setToolbarDoneBarButtonItemText:@"完成"];
}

- (void)_setupForDelegates
{
    // 排队
    CloudroomQueue *cloudroomQueue = [CloudroomQueue shareInstance];
    QueueCallBack *queueCallBack = [[QueueCallBack alloc] init];
    [cloudroomQueue setQueueCallback:queueCallBack];
    [self setQueueCallBack:queueCallBack];
    
    // 会议管理
    CloudroomVideoMgr *cloudroomVideoMgr = [CloudroomVideoMgr shareInstance];
    VideoMgrCallBack *videoMgrCallBack = [[VideoMgrCallBack alloc] init];
    [cloudroomVideoMgr setMgrCallback:videoMgrCallBack];
    [self setVideoMgrCallBack:videoMgrCallBack];
    
    // 会议
    CloudroomVideoMeeting *cloudroomVideoMeeting  = [CloudroomVideoMeeting shareInstance];
    VideoMeetingCallBack *videoMeetingCallBack = [[VideoMeetingCallBack alloc] init];
    [cloudroomVideoMeeting setMeetingCallBack:videoMeetingCallBack];
    [self setVideoMeetingCallBack:videoMeetingCallBack];
    
    // HTTP文件管理
    CloudroomHttpFileMgr *cloudroomHttpFileMgr = [CloudroomHttpFileMgr shareInstance];
    FileMgrCallBack *fileMgr = [[FileMgrCallBack alloc] init];
    [cloudroomHttpFileMgr setHttpFileMgrCallback:fileMgr];
    [self setFileMgrCallBack:fileMgr];
}

@end
