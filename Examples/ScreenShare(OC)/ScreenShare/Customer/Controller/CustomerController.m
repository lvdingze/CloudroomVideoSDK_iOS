//
//  CustomerController.m
//  Record
//
//  Created by king on 2017/6/9.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "CustomerController.h"
#import "RemoteController.h"
#import "QueueController.h"
#import "BaseNavController.h"
#import "RecordController.h"
#import "Customer.h"
#import "CustomerCell.h"
#import "AppDelegate.h"
#import "QueueCallBack.h"
#import "VideoMgrCallBack.h"
#import "RecordHelper.h"

typedef NS_ENUM(NSInteger, CustomerBarBtnType)
{
    CustomerBarBtnTypeLogout = 1,
    CustomerBarBtnTypeRefresh
};

@interface CustomerController () <QueueDelegate, VideoMgrDelegate>

@property (nonatomic, copy) NSArray<Customer *> *dataSource; /**< 数据源 */
@property (nonatomic, strong) UIAlertController *alertController; /**< 提示框 */
@property (nonatomic, assign) int queID; /**< 记录的队列ID */
@property (nonatomic, assign) NSInteger count; /**< 排队计时 */
@property (nonatomic, assign) NSInteger position; /**< 排队位置 */
@property (nonatomic, copy) NSString *callID; /**< 会话ID */
@property (nonatomic, copy) NSString *peerID; /**< 对端ID */
@property (nonatomic, strong) MeetInfo *meetInfo; /**< 会议信息 */

- (IBAction)clickBarBtnForCustomer:(UIBarButtonItem *)sender;

@end

@implementation CustomerController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForCustomer];
}

- (void)viewWillAppear:(BOOL)animated
{
    RLog(@"");
    [super viewWillAppear:animated];
    // FIXME:网络超时无提示
    [self _updateDelegate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    RLog(@"");
    [super viewDidDisappear:animated];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_dataSource count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CustomerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:customer_ID forIndexPath:indexPath];
    [self _configureCell:cell rowAtIndexPath:indexPath];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    Customer *customer = [_dataSource objectAtIndex:indexPath.row];
    int queID = customer.queueInfo.queID;
    _queID = queID;
    _count = 0;
    _position = 0;
    [self _jumpToRecord];
}

// 设置每个item的尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(([[UIScreen mainScreen] bounds].size.width - 5) * 0.5, 234);
}

// 设置每个item的UIEdgeInsets
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

// 设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 5;
}

// 设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 5;
}

#pragma mark - QueueDelegate
// 初始化结果(初始化成功:errCode为CRVIDEOSDK_NOERR)
- (void)queueCallBack:(QueueCallBack *)callback initQueueDatRslt:(CRVIDEOSDK_ERR_DEF)errCode cookie:(NSString *)cookie
{
    if (errCode == CRVIDEOSDK_NOERR) {
        CloudroomQueue *videoCallQueue = [CloudroomQueue shareInstance];
        NSArray <QueueInfo *> *queueInfoArr = [[videoCallQueue getQueueInfo] copy];
        NSMutableArray <NSNumber *> *customerQueueArr = [videoCallQueue getServiceQueues];
        NSMutableArray <Customer *> *result = [NSMutableArray array];
        
        for (QueueInfo *queueInfo in queueInfoArr) {
            Customer *customer = [[Customer alloc] init];
            QueueStatus *queueStatus = [videoCallQueue getQueueStatus:queueInfo.queID];
            customer.queueInfo = queueInfo;
            customer.queueStatus = queueStatus;
            customer.serviced = [customerQueueArr containsObject:@(queueInfo.queID)];
            [result addObject:customer];
        }
        
        _dataSource = [result copy];
        [self.collectionView reloadData];
        
        // 检查是否有正在排队
        QueuingInfo *queuingInfo = [[CloudroomQueue shareInstance] getQueuingInfo];
        if (queuingInfo.queID > 0) {
            RLog(@"queID:%d, queuingTime:%d, position:%d", queuingInfo.queID, queuingInfo.queuingTime, queuingInfo.position);
            _queID = queuingInfo.queID;
            _count = (NSInteger)queuingInfo.queuingTime;
            _position = (NSInteger)queuingInfo.position - 1;
            [self _jumpToQueue];
        }
        
        // 恢复意外关闭的视频会话
        VideoSessionInfo *sessionInfo = [videoCallQueue getSessionInfo];
        if (![NSString stringCheckEmptyOrNil:sessionInfo.callID] && sessionInfo.duration > 0) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"是否恢复意外关闭的视频会话?" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
                [[CloudroomVideoMgr shareInstance] hungupCall:sessionInfo.callID usrExtDat:nil cookie:cookie];
            }];
            UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"恢复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                //  FIXME:每次恢复成功会话都会弹"启动视频会话失败"
                _meetInfo = [[MeetInfo alloc] init];
                [_meetInfo setID:sessionInfo.meetingID];
                [_meetInfo setPswd:sessionInfo.meetingPswd];
                _peerID = sessionInfo.peerID;
                _callID = sessionInfo.callID;
                [self _jumpToRemote];
            }];
            [alertController addAction:cancelAction];
            [alertController addAction:doneAction];
            [self presentViewController:alertController animated:NO completion:nil];
        }
    }
    else {
        RLog(@"客户界面获取数据错误!");
    }
}

// 队列状态变化通知
- (void)queueCallBack:(QueueCallBack *)callback queueStatusChanged:(QueueStatus *)queStatus
{
    for (NSInteger i = 0; i < [_dataSource count]; i++) {
        Customer *customer = _dataSource[i];
        if (customer.queueStatus.queID == queStatus.queID) {
            customer.queueStatus = queStatus;
        }
    }
    
    [self.collectionView reloadData];
}

// 排队信息变化通知
- (void)queueCallBack:(QueueCallBack *)callback queuingInfoChanged:(QueuingInfo *)queuingInfo
{
    // FIXME:刷新排队信息
    [self _handleRefreshOperation];
    
    RLog(@"queID:%d, queuingTime:%d, position:%d", queuingInfo.queID, queuingInfo.queuingTime, queuingInfo.position);
    QueuingInfo *queuing = [[CloudroomQueue shareInstance] getQueuingInfo];
    RLog(@"queID:%d, queuingTime:%d, position:%d", queuing.queID, queuing.queuingTime, queuing.position);
    
    if (queuing.queID != _queID) {
        return;
    }
    
    if (!_alertController) {
        return;
    }
    
    _count = (NSInteger)queuing.queuingTime;
    _position = (NSInteger)(queuing.position - 1);
}

#pragma mark - VideoMgrDelegate
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

// 获取好友状态响应
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback getUserStatusRsp:(CRVIDEOSDK_ERR_DEF)sdkErr userStatus:(NSArray <UserStatus *> *)userStatus cookie:(NSString *)cookie
{
    
}

// 好友状态通知
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback notifyUserStatus:(UserStatus *)uStatus
{
    
}

// 开始好友状态监听通知
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback startStatusPushRsp:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    
}

// 停止好友状态监听通知
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback stopStatusPushRsp:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    
}

// 服务端通知被邀请(第三方呼入)
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback notifyCallIn:(NSString *)callID meetInfo:(MeetInfo *)meetInfo callerID:(NSString *)callerID usrExtDat:(NSString *)usrExtDat
{
    RLog(@"第三方呼入, callID:%@ callerID:%@", callID, callerID);
    
    NSString *cookie = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    CloudroomVideoMgr *cloudroomVideoMgr = [CloudroomVideoMgr shareInstance];
    _callID = callID;
    _peerID = callerID;
    _meetInfo = meetInfo;
    
    // 接受呼叫
    [cloudroomVideoMgr acceptCall:callID meetInfo:meetInfo usrExtDat:nil cookie:cookie];
}

// 接受他人邀请响应
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback acceptCallSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    // 进入视频会话
    _callID = callID;
    
    // 跳转到"回话"界面
    [self _jumpToRemote];
}

- (void)videoMgrCallBack:(VideoMgrCallBack *)callback acceptCallFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    
}

#pragma mark - selector
- (IBAction)clickBarBtnForCustomer:(UIBarButtonItem *)sender
{
    switch ([sender tag]) {
        case CustomerBarBtnTypeLogout: { // 注销
            [self _handleLogoutOperation];
            break;
        }
        case CustomerBarBtnTypeRefresh: { // 刷新
            [self _handleRefreshOperation];
            break;
        }
        default: break;
    }
}

#pragma mark - private method
/**
 初始化
 */
- (void)_setupForCustomer
{
    [self _setupForProperies];
    [self _setupForTitle];
    [self _updateDelegate];
    [self _setupForQueue];
}

/**
 设置属性
 */
- (void)_setupForProperies
{
    _queID = 0;
    _position = 0;
    _count = 0;
    
    /*
    CloudroomVideoMgr *cloudroomVideoMgr = [CloudroomVideoMgr shareInstance];
    NSString *cookie = [NSString stringWithFormat:@"%f",CFAbsoluteTimeGetCurrent()];
    [cloudroomVideoMgr startUserStatusNotify:cookie];
    [cloudroomVideoMgr getUserStatus:cookie];
     */
}

/**
 设置标题
 */
- (void)_setupForTitle
{
    NSString *title = [NSString stringWithFormat:@"%@,欢迎你!", [[RecordHelper shareInstance] nickname]];
    [self setTitle:title];
}

/**
 获取排队队列信息
 */
- (void)_setupForQueue
{
    NSString *cookie = [NSString stringWithFormat:@"%f",CFAbsoluteTimeGetCurrent()];
    CloudroomQueue *cloudroomQueue = [CloudroomQueue shareInstance];
    // 发送"请求队列信息"命令
    [cloudroomQueue initQueueDat:cookie];
}

/**
 设置cell

 @param cell cell对象
 @param indexPath 行信息
 */
- (void)_configureCell:(CustomerCell *)cell rowAtIndexPath:(NSIndexPath *)indexPath
{
    Customer *customer = [_dataSource objectAtIndex:indexPath.row];
    // TODO:不要序号
    NSString *title = [NSString stringWithFormat:@"%@(%d)", customer.queueInfo.name, customer.queueStatus.wait_num];
    [cell.iconImage setImage:[UIImage imageNamed:[NSString stringWithFormat:@"record_%zd", indexPath.row % 5]]];
    [cell.titleLabel setText:title];
    [cell.descLabel setText:customer.queueInfo.desc];
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
 刷新
 */
- (void)_handleRefreshOperation
{
    RLog(@"");
    [[CloudroomQueue shareInstance] refreshAllQueueStatus];
}

/**
 注销
 */
- (void)_handleLogoutOperation
{
    [self _jumpToLogin];
}

/**
 跳转到"登录"界面
 */
- (void)_jumpToLogin
{
    // 注销
    [[CloudroomVideoMgr shareInstance] logout];
    
    // 跳转到"登录"界面
    UIStoryboard *login = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    BaseNavController *loginNav = [login instantiateInitialViewController];
    
    if (loginNav) {
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:loginNav];
    }
}

/**
 跳转到"远程双录"界面
 */
- (void)_jumpToRemote
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
    [remoteVC setPeerID:_peerID];
    [remoteVC setMeetInfo:_meetInfo];
    
    if (remoteVC) {
        [self.navigationController pushViewController:remoteVC animated:YES];
    }
}

/**
 跳转到"业务选择"界面
 */
- (void)_jumpToRecord
{
    // 队列名称
    NSString *queName;
    for (Customer *customer in _dataSource) {
        if (customer.queueInfo.queID == _queID) {
            queName = customer.queueInfo.name;
            break;
        }
    }
    
    UIStoryboard *customer = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    RecordController *queueVC = [customer instantiateViewControllerWithIdentifier:@"RecordController"];
    [queueVC setQueID:_queID];
    [queueVC setQueName:queName];
    [queueVC setPosition:_position];
    [queueVC setCount:_count];
    
    if (queueVC) {
        [self.navigationController pushViewController:queueVC animated:YES];
    }
}

/**
 跳转到"排队"界面
 */
- (void)_jumpToQueue
{
    // 队列名称
    NSString *queName;
    for (Customer *customer in _dataSource) {
        if (customer.queueInfo.queID == _queID) {
            queName = customer.queueInfo.name;
            break;
        }
    }
    
    UIStoryboard *customer = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    QueueController *queueVC = [customer instantiateViewControllerWithIdentifier:@"QueueController"];
    [queueVC setQueID:_queID];
    [queueVC setQueName:queName];
    [queueVC setPosition:_position];
    [queueVC setCount:_count];
    
    if (queueVC) {
        [self.navigationController pushViewController:queueVC animated:YES];
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
