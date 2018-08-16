//
//  RecordHelper.m
//  Record
//
//  Created by king on 2017/6/9.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "RecordHelper.h"

static NSString * const RecordHelper_server = @"server";
static NSString * const RecordHelper_account = @"account";
static NSString * const RecordHelper_pswd = @"pswd";
static NSString * const RecordHelper_nickname = @"nickname";

@interface RecordHelper ()

@property (nonatomic, copy, readwrite) NSString *server; /**< 服务器地址 */
@property (nonatomic, copy, readwrite) NSString *account; /**< 账户 */
@property (nonatomic, copy, readwrite) NSString *pswd; /**< 密码 */
@property (nonatomic, copy, readwrite) NSString *nickname; /**< 登录昵称 */

@end

@implementation RecordHelper
#pragma mark - singleton
static RecordHelper *shareInstance;
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [super allocWithZone:zone];
    });
    return shareInstance;
}

#pragma mark - life cycle
- (instancetype)init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    // 争取应用在后台能多运行170s左右
    // [self _addNotifications];
    
    return self;
}

- (void)dealloc
{
    [self _removeNotifications];
}

#pragma mark - selector
- (void)appDidEnterBackground:(NSNotification *)notification
{
    RLog(@"");
    [self _doSomethingOnBackGround];
}

- (void)appWillEnterForeground:(NSNotification *)notification
{
    RLog(@"");
}

#pragma mark - public method
- (void)writeAccount:(NSString *)account pswd:(NSString *)pswd server:(NSString *)server
{
    _account = account;
    _server = server;
    _pswd = pswd;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_account forKey:RecordHelper_account];
    [userDefaults setObject:_pswd forKey:RecordHelper_pswd];
    [userDefaults setObject:_server forKey:RecordHelper_server];
    [userDefaults synchronize];
}

- (void)writeNickname:(NSString *)nickname
{
    _nickname = nickname;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_nickname forKey:RecordHelper_nickname];
    [userDefaults synchronize];
}

- (void)readInfo
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _server = [userDefaults stringForKey:RecordHelper_server];
    _account = [userDefaults stringForKey:RecordHelper_account];
    _pswd = [userDefaults stringForKey:RecordHelper_pswd];
    _nickname = [userDefaults stringForKey:RecordHelper_nickname];
}

- (void)resetInfo;
{
    [self writeAccount:@"demo@cloudroom.com" pswd:@"123456" server:@"www.cloudroom.com"];
    [self readInfo];
}

#pragma mark - private method
- (void)_addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)_removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**< 后台处理 */
- (void)_doSomethingOnBackGround
{
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // do something enter background
}
@end
