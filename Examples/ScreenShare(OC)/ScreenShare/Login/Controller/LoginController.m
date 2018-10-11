//
//  LoginController.m
//  Record
//
//  Created by king on 2017/6/8.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "LoginController.h"
#import "CustomerController.h"
#import "SettingController.h"
#import "RecordHelper.h"
#import "AppDelegate.h"
#import "VideoMgrCallBack.h"
#import "IQUIView+IQKeyboardToolbar.h"

#import <netdb.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

typedef NS_ENUM(NSInteger, LoginBtnType)
{
    LBT_login, // 登录
    LBT_setting // 设置
};

@interface LoginController () <VideoMgrDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionLabel; /**< 版本号 */
@property (weak, nonatomic) IBOutlet UIView *nicknameView; /**< 昵称视图 */
@property (weak, nonatomic) IBOutlet UIButton *loginBtn; /**< 登录按钮 */
@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField; /**< 昵称 */

- (IBAction)clickBtnForLogin:(UIButton *)sender;

@end

@implementation LoginController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForLogin];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    
    [self _updateDelegate];
}

#pragma mark - VideoMgrDelegate
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback loginSuccess:(NSString *)usrID cookie:(NSString *)cookie
{
    [HUDUtil hudHiddenProgress:YES];
    [self _jumpToCustomer];
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback loginFail:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    [HUDUtil hudHiddenProgress:YES];
    
    // FIXME:概率性登录卡死不回调 added by king 20161216
    if (sdkErr == CRVIDEOSDK_NOSERVER_RSP) {
        [HUDUtil hudShow:@"服务器无响应!" delay:3 animated:YES];
    }
    else if (sdkErr == CRVIDEOSDK_LOGINSTATE_ERROR) {
        [HUDUtil hudShow:@"登陆状态不对!" delay:3 animated:YES];
        [[CloudroomVideoMgr shareInstance] logout];
    }
    else if (sdkErr == CRVIDEOSDK_ANCTPSWD_ERR) {
        [HUDUtil hudShow:@"帐号密码不正确!" delay:3 animated:YES];
    }
    else {
        [HUDUtil hudShow:@"登录失败!" delay:3 animated:YES];
    }
}

#pragma mark - selector
/**
 按钮响应
 
 @param sender 按钮对象
 */
- (IBAction)clickBtnForLogin:(UIButton *)sender
{
    switch ([sender tag]) {
        case LBT_login: { // 登录
            // 登录操作
            [self _handleLogin];
            
            break;
        }
        case LBT_setting: { // 设置
            // 设置操作
            [self _handleSetting];
            
            break;
        }
        default: break;
    }
}

/**
 键盘Tool视图按钮响应

 @param textView 键盘文本框
 */
- (void)hasDone:(UITextField *)textView
{
    [self.view endEditing:YES];
    [self clickBtnForLogin:_loginBtn];
}

#pragma mark - private method
/**
 初始化操作
 */
- (void)_setupForLogin
{
    [self _setupForProperies];
    [self _updateDelegate];
}

/**
 设置属性
 */
- (void)_setupForProperies
{
    // SDK版本号
    [_versionLabel setText:[NSString stringWithFormat:@"SDK版本号:%@",[CloudroomVideoSDK getCloudroomVideoSDKVer]]];
    
    // 设置边框
    [_nicknameView.layer setCornerRadius:22];
    [_nicknameView.layer setBorderColor:UIColorFromRGB(0x6A6E75).CGColor];
    [_nicknameView.layer setBorderWidth:1];
    [_nicknameView.layer masksToBounds];
    [_loginBtn.layer setCornerRadius:22];
    [_loginBtn.layer masksToBounds];
    
    // 设置placeholder颜色
    [_nicknameTextField setValue:UIColorFromRGB(0xFFFFFF) forKeyPath:@"_placeholderLabel.textColor"];
    
    [_nicknameTextField setCustomDoneTarget:self action:@selector(hasDone:)];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // TODO:保留登录信息 added by king 20170902
    RecordHelper *recordHelper = [RecordHelper shareInstance];
    [recordHelper readInfo];
    [_nicknameTextField setText:recordHelper.nickname];
}

/**
 更新代理
 */
- (void)_updateDelegate
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
}

/**
 登录操作
 */
- (void)_handleLogin
{
    RLog(@"");
    
    NSString *nickname = _nicknameTextField.text;
    if ([NSString stringCheckEmptyOrNil:nickname]) {
        [HUDUtil hudShow:@"昵称不能为空!" delay:3 animated:YES];
        return;
    }
    
    // 云屋 SDK 登陆账号,实际开发中,请联系云屋工作人员获取
    RecordHelper *recordHelper = [RecordHelper shareInstance];
    [recordHelper readInfo];
    // 账号
    NSString *account = recordHelper.account;
    // 密码通过 MD5 以后(小写十六位)
    NSString *pswd = recordHelper.pswd;
    // 服务器地址
    NSString *server = recordHelper.server;
    
    if ([NSString stringCheckEmptyOrNil:server]) {
        [HUDUtil hudShow:@"服务器地址不能为空!" delay:3 animated:YES];
        return;
    }
    
    if ([NSString stringCheckEmptyOrNil:account]) {
        [HUDUtil hudShow:@"账号不能为空!" delay:3 animated:YES];
        return;
    }
    
    if ([NSString stringCheckEmptyOrNil:pswd]) {
        [HUDUtil hudShow:@"密码不能为空!" delay:3 animated:YES];
        return;
    }
    
    NSString *md5Pswd = [NSString md5:recordHelper.pswd];
    
    RLog(@"server:%@ nickname:%@ account:%@ pswd:%@", server, nickname, account, md5Pswd);
    
    CloudroomVideoMgr *cloudroomVideoMgr = [CloudroomVideoMgr shareInstance];
    LoginDat *loginData = [[LoginDat alloc] init];
    [loginData setNickName:nickname];
    [loginData setAuthAcnt:account];
    [loginData setAuthPswd:md5Pswd];
    [loginData setPrivAcnt:nickname];
    
    [recordHelper writeAccount:account pswd:pswd server:server];
    [recordHelper writeNickname:nickname];
    
    // 域名转IP
    /*
    NSString *ip_Port;
    if ([serverIP containsString:@":"]) {
        NSArray <NSString *> *strs = [serverIP componentsSeparatedByString:@":"];
        
        if ([strs count] > 1) {
            NSString *hostToIP = [self _getIPFromHostName:[strs firstObject]];
            ip_Port = [NSString stringWithFormat:@"%@:%@", hostToIP, strs[1]];
        }
        else {
            ip_Port = [self _getIPFromHostName:[strs firstObject]];
        }
    }
    else {
        ip_Port = [self _getIPFromHostName:serverIP];
    }
     
    NSLog(@"IP+Port:%@", ip_Port);
     */
    
    // 设置服务器地址
    [[CloudroomVideoSDK shareInstance] setServerAddr:server];
    
    [HUDUtil hudShowProgress:@"正在登录..." animated:YES];
    
    // 开始上传日志
    [[CloudroomVideoSDK shareInstance] startLogReport:nickname server:@"logserver.cloudroom.com:12005"];
    
    [self _updateDelegate];
    
    [[CloudroomVideoSDK shareInstance] writeLog:SDK_LOG_LEVEL_INFO message:@"登录操作"];
    
    // 发送"登录"命令
    NSString *cookie = [NSString stringWithFormat:@"%f",CFAbsoluteTimeGetCurrent()];
    [cloudroomVideoMgr login:loginData cookie:cookie];
}

/**
 设置操作
 */
- (void)_handleSetting
{
    RLog(@"");
    
    [self _jumpToSetting];
}

/**
 跳转到"业务选择"界面
 */
- (void)_jumpToRecord
{
    RLog(@"");
    
    UIStoryboard *record = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    UINavigationController *recordNav =  [record instantiateInitialViewController];
    
    if (recordNav) {
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:recordNav];
    }
}

/**
 跳转到客户信息界面
 */
- (void)_jumpToCustomer
{
    RLog(@"");
    
    UIStoryboard *customer = [UIStoryboard storyboardWithName:@"Customer" bundle:nil];
    UINavigationController *customerNav =  [customer instantiateInitialViewController];
    
    if (customerNav) {
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:customerNav];
    }
}

/**
 跳转到"服务器设置"界面
 */
- (void)_jumpToSetting
{
    RLog(@"");
    
    UIStoryboard *login = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    SettingController *settingVC =  [login instantiateViewControllerWithIdentifier:@"SettingController"];
    
    if (settingVC) {
        [self.navigationController pushViewController:settingVC animated:YES];
    }
}

/**
 域名转IP
 @param hostname 域名
 @return IP
 */
- (NSString *)_getIPFromHostName:(const NSString *)hostname
{
    const char *hostN= [hostname UTF8String];
    struct hostent *phot;
    
    @try {
        phot = gethostbyname(hostN);
    } @catch (NSException *exception) {
        return nil;
    }
    
    if(phot == NULL) {
        return nil;
    }
    
    struct in_addr ip_addr;
    
    memcpy(&ip_addr, phot->h_addr_list[0], 4);
    
    char ip[20] = {0};
    
    inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
    
    NSString *strIPAddress = [NSString stringWithUTF8String:ip];
    
    return strIPAddress;
}

#pragma mark - override
// FIXME:点击界面任意空白地方收起键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}
@end
