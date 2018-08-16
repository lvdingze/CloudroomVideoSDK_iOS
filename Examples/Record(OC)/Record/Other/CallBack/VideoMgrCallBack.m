//
//  VideoMgrCallBack.m
//  VideoCall
//
//  Created by king on 2017/6/7.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "VideoMgrCallBack.h"

@interface VideoMgrCallBack ()

@end

@implementation VideoMgrCallBack
// 登录响应
- (void)loginSuccess:(NSString *)usrID cookie:(NSString *)cookie
{
    RLog(@"usrID:%@, cookie:%@", usrID, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:loginSuccess:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self loginSuccess:usrID cookie:cookie];
        }
    });
}

- (void)loginFail:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"sdkErr:%u, cookie:%@", sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:loginFail:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self loginFail:sdkErr cookie:cookie];
        }
    });
}

// 掉线通知
- (void)lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    RLog(@"sdkErr:%u", sdkErr);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:lineOff:)]) {
            [_videoMgrDelegate videoMgrCallBack:self lineOff:sdkErr];
        }
    });
}

// 客户端免打扰状态响应
- (void)setDNDStatusSuccess:(NSObject *)cookie
{
    // RLog(@"cookie:%@", cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:setDNDStatusSuccess:)]) {
            [_videoMgrDelegate videoMgrCallBack:self setDNDStatusSuccess:cookie];
        }
    });
}

- (void)setDNDStatusFail:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // RLog(@"sdkErr:%zd cookie:%@", sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:setDNDStatusFail:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self setDNDStatusFail:sdkErr cookie:cookie];
        }
    });
}

// 获取好友状态响应
- (void)getUserStatusRsp:(CRVIDEOSDK_ERR_DEF)sdkErr userStatus:(NSArray <UserStatus *> *)userStatus cookie:(NSString *)cookie
{
    RLog(@"sdkErr:%u count of userStatus:%lu cookie:%@", sdkErr, (unsigned long)[userStatus count], cookie);
    
    for (UserStatus *uStatus in userStatus) {
        RLog(@"userID:%@ userStatus:%ld", uStatus.userID, (long)uStatus.userStatus);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:getUserStatusRsp:userStatus:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self getUserStatusRsp:sdkErr userStatus:userStatus cookie:cookie];
        }
    });
}

// 好友状态通知
- (void)notifyUserStatus:(UserStatus *)uStatus
{
    RLog(@"userID:%@ userStatus:%ld DNDType:%d", uStatus.userID, (long)uStatus.userStatus, uStatus.DNDType);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [HUDUtil hudShow:[NSString stringWithFormat:@"%@ 已 %@", uStatus.userID, [self _getStatus:uStatus.userStatus]] delay:2 animated:YES];
        
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyUserStatus:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyUserStatus:uStatus];
        }
    });
}

- (NSString *)_getStatus:(CLIENT_STATUS)status
{
    NSString *reslt;
    switch (status) {
        case OFFLINE: {
            reslt = @"离线";
            break;
        }
        case ONLINE: {
            reslt = @"在线";
            break;
        }
        case BUSY: {
            reslt = @"繁忙";
            break;
        }
        case MEETING: {
            reslt = @"在会议中";
            break;
        }
        default: {
            reslt = @"未知状态";
            break;
        }
    }
    
    return reslt;
}

// 开始好友状态监听通知
- (void)startStatusPushRsp:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"sdkErr:%u cookie:%@", sdkErr, cookie);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:startStatusPushRsp:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self startStatusPushRsp:sdkErr cookie:cookie];
        }
    });
}

// 停止好友状态监听通知
- (void)stopStatusPushRsp:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"sdkErr:%u cookie:%@", sdkErr, cookie);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:stopStatusPushRsp:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self stopStatusPushRsp:sdkErr cookie:cookie];
        }
    });
}

// 创建会议
- (void)createMeetingSuccess:(MeetInfo *)meetInfo cookie:(NSString *)cookie
{
    // RLog(@"meetInfo.ID:%d meetInfo.pswd:%@ meetInfo.subject:%@ meetInfo.pubMeetUrl:%@ cookie:%@", meetInfo.ID, meetInfo.pswd, meetInfo.subject, meetInfo.pubMeetUrl, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:createMeetingSuccess:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self createMeetingSuccess:meetInfo cookie:cookie];
        }
    });
}

- (void)createMeetingFail:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // RLog(@"sdkErr:%zd cookie:%@", sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:createMeetingFail:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self createMeetingFail:sdkErr cookie:cookie];
        }
    });
}

- (void)getMeetingListSuccess:(NSArray <MeetInfo *> *)meetList cookie:(NSString *)cookie
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:getMeetingListSuccess:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self getMeetingListSuccess:meetList cookie:cookie];
        }
    });
}

- (void)getMeetingListFail:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:getMeetingListFail:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self getMeetingListFail:sdkErr cookie:cookie];
        }
    });
}

// 邀请他人参会响应
- (void)callSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    // RLog(@"callID:%@ cookie:%@", callID, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:callSuccess:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self callSuccess:callID cookie:cookie];
        }
    });
}

- (void)callFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // RLog(@"callID:%@ sdkErr:%zd cookie:%@", callID, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:callFail:errCode:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self callFail:callID errCode:sdkErr cookie:cookie];
        }
    });
}

// 接受他人邀请响应
- (void)acceptCallSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    // RLog(@"callID:%@ cookie:%@", callID, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:acceptCallSuccess:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self acceptCallSuccess:callID cookie:cookie];
        }
    });
}

- (void)acceptCallFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // RLog(@"callID:%@ sdkErr:%zd cookie:%@", callID, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:acceptCallFail:errCode:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self acceptCallFail:callID errCode:sdkErr cookie:cookie];
        }
    });
}

// 拒绝他人邀请响应
- (void)rejectCallSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    // RLog(@"callID:%@ cookie:%@", callID, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:rejectCallSuccess:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self rejectCallSuccess:callID cookie:cookie];
        }
    });
}

- (void)rejectCallFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // RLog(@"callID:%@ sdkErr:%zd cookie:%@", callID, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:rejectCallFail:errCode:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self rejectCallFail:callID errCode:sdkErr cookie:cookie];
        }
    });
}

// 拆除呼叫
- (void)hangupCallSuccess:(NSString *)callID cookie:(NSString *)cookie
{
    // RLog(@"callID:%@ cookie:%@", callID, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:hangupCallSuccess:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self hangupCallSuccess:callID cookie:cookie];
        }
    });
}

-(void)hangupCallFail:(NSString *)callID errCode:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // RLog(@"callID:%@ sdkErr:%zd cookie:%@", callID, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:hangupCallFail:errCode:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self hangupCallFail:callID errCode:sdkErr cookie:cookie];
        }
    });
}

// 服务端通知被邀请
- (void)notifyCallIn:(NSString *)callID meetInfo:(MeetInfo *)meetInfo callerID:(NSString *)callerID usrExtDat:(NSString *)usrExtDat
{
    // RLog(@"callID:%@ meetInfo.ID:%d meetInfo.pswd:%@ meetInfo.subject:%@ meetInfo.pubMeetUrl:%@ callerID:%@ param:%zd", callID, meetInfo.ID, meetInfo.pswd, meetInfo.subject, meetInfo.pubMeetUrl, callerID, param);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyCallIn:meetInfo:callerID:usrExtDat:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyCallIn:callID meetInfo:meetInfo callerID:callerID usrExtDat:usrExtDat];
        }
    });
}

// 服务端通知会议邀请被接受
- (void)notifyCallAccepted:(NSString *)callID meetInfo:(MeetInfo *)meetInfo usrExtDat:(NSString *)usrExtDat
{
    // RLog(@"callID:%@ meetInfo.ID:%d meetInfo.pswd:%@ meetInfo.subject:%@ meetInfo.pubMeetUrl:%@", callID, meetInfo.ID, meetInfo.pswd, meetInfo.subject, meetInfo.pubMeetUrl);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyCallAccepted:meetInfo:usrExtDat:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyCallAccepted:callID meetInfo:meetInfo usrExtDat:(NSString *)usrExtDat];
        }
    });
}

// 服务端通知邀请被拒绝
- (void)notifyCallRejected:(NSString *)callID reason:(CRVIDEOSDK_ERR_DEF)reason usrExtDat:(NSString *)usrExtDat
{
    // RLog(@"callID:%@ reason:%zd", callID, reason);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyCallRejected:reason:usrExtDat:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyCallRejected:callID reason:reason usrExtDat:(NSString *)usrExtDat];
        }
    });
}

// 服务端通知呼叫被结束
- (void)notifyCallHungup:(NSString *)callID usrExtDat:(NSString *)usrExtDat
{
    // RLog(@"callID:%@", callID);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyCallHungup:usrExtDat:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyCallHungup:callID usrExtDat:usrExtDat];
        }
    });
}

// 透明通道
// 发送信令结果
- (void)sendCmdRlst:(NSString *)sendId sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"sendId:%@ sdkErr:%u cookie:%@", sendId, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:sendCmdRlst:sdkErr:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self sendCmdRlst:sendId sdkErr:sdkErr cookie:cookie];
        }
    });
}

// 发送数据结果
- (void)sendBufferRlst:(NSString *)sendId sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"sendId:%@ sdkErr:%u cookie:%@", sendId, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:sendBufferRlst:sdkErr:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self sendBufferRlst:sendId sdkErr:sdkErr cookie:cookie];
        }
    });
}

// 发送文件结果
- (void)sendFileRlst:(NSString *)sendId fileName:(NSString *)fileName sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // RLog(@"sendId:%@ fileName:%@ sdkErr:%zd cookie:%@", sendId, fileName, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:sendFileRlst:fileName:sdkErr:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self sendFileRlst:sendId fileName:fileName sdkErr:sdkErr cookie:cookie];
        }
    });
}

// 发送数据进度(文件和数据共用)
- (void)sendProgress:(NSString *)sendId sendedLen:(int)sendedLen totalLen:(int)totalLen cookie:(NSString *)cookie
{
    // RLog(@"sendId:%@ sendedLen:%d totalLen:%d cookie:%@", sendId, sendedLen, totalLen, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:sendProgress:sendedLen:totalLen:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self sendProgress:sendId sendedLen:sendedLen totalLen:totalLen cookie:cookie];
        }
    });
}

// 取消发送数据结果
- (void)cancelSendRlst:(NSString *)sendId sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"sendId:%@ sdkErr:%u cookie:%@", sendId, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:cancelSendRlst:sdkErr:cookie:)]) {
            [_videoMgrDelegate videoMgrCallBack:self cancelSendRlst:sendId sdkErr:sdkErr cookie:cookie];
        }
    });
}

// 接收信令
- (void)notifyCmdData:(NSString *)sourceUserId data:(NSString *)data
{
    RLog(@"sourceUserId:%@ data.lenght:%@", sourceUserId, @(data.length));
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyCmdData:data:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyCmdData:sourceUserId data:data];
        }
    });
}

// 接收数据
- (void)notifyBufferData:(NSString *)sourceUserId data:(NSString *)data
{
    RLog(@"sourceUserId:%@ data.lenght:%@", sourceUserId, @(data.length));
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyBufferData:data:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyBufferData:sourceUserId data:data];
        }
    });
}

// 接收文件
- (void)notifyFileData:(NSString *)sourceUserId tmpFile:(NSString *)tmpFile orgFileName:(NSString *)orgFileName
{
    // RLog(@"sourceUserId:%@ tmpFile:%@ orgFileName:%@", sourceUserId, tmpFile, orgFileName);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyFileData:tmpFile:orgFileName:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyFileData:sourceUserId tmpFile:tmpFile orgFileName:orgFileName];
        }
    });
}

// 取消数据发送
- (void)notifyCancelSend:(NSString *)sendId
{
    // RLog(@"sendId:%@", sendId);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMgrDelegate respondsToSelector:@selector(videoMgrCallBack:notifyCancelSend:)]) {
            [_videoMgrDelegate videoMgrCallBack:self notifyCancelSend:sendId];
        }
    });
}

- (void)callMorePartyRslt:(NSString *)inviteID sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie {
    
}


- (void)cancelCallMorePartyRslt:(NSString *)inviteID sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie {
    
}


- (void)notifyCallMorePartyStatus:(NSString *)inviteID status:(CR_INVITE_STATUS)status {
    
}

@end
