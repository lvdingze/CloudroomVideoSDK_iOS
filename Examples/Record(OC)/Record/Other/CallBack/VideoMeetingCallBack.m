//
//  VideoMeetingCallBack.m
//  VideoCall
//
//  Created by king on 2017/6/7.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "VideoMeetingCallBack.h"

@interface VideoMeetingCallBack ()

@end

@implementation VideoMeetingCallBack
// 入会成功；(入会失败，将自动发起releaseCall）
- (void)enterMeetingRslt:(CRVIDEOSDK_ERR_DEF)code
{
    // RLog(@"code:%zd", code);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:enterMeetingRslt:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self enterMeetingRslt:code];
        }
    });
}

// user进入了会话
- (void)userEnterMeeting:(NSString *)userID
{
    RLog(@"userID:%@", userID);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:userEnterMeeting:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self userEnterMeeting:userID];
        }
    });
}

- (void)userLeftMeeting:(NSString *)userID
{
    RLog(@"userID:%@", userID);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:userLeftMeeting:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self userLeftMeeting:userID];
        }
    });
}

// 创建会议
- (void)createMeetingSuccess:(int)meetID password:(NSString *)password cookie:(NSString *)cookie
{
    // RLog(@"meetID:%zd password:%@ cookie:%@", meetID, password, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:createMeetingSuccess:password:cookie:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self createMeetingSuccess:meetID password:password cookie:cookie];
        }
    });
}

- (void)createMeetingFail:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    // RLog(@"sdkErr:%zd cookie:%@", sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:createMeetingFail:cookie:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self createMeetingFail:sdkErr cookie:cookie];
        }
    });
}

// 结束会议的结果
- (void)stopMeetingRslt:(CRVIDEOSDK_ERR_DEF)code
{
    // RLog(@"code:%zd", code);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:stopMeetingRslt:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self stopMeetingRslt:code];
        }
    });
}

// 会议被结束了
- (void)meetingStopped
{
    // RLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBackMeetingStopped:)]) {
            [_videoMeetingDelegate videoMeetingCallBackMeetingStopped:self];
        }
    });
}

// 会议掉线
- (void)meetingDropped
{
    RLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBackMeetingDropped:)]) {
            [_videoMeetingDelegate videoMeetingCallBackMeetingDropped:self];
        }
    });
}

// 最新网络评分0~10(10分为最佳网络)
-(void)netStateChanged:(int)level
{
    // RLog(@"level:%d", level);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:netStateChanged:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self netStateChanged:level];
        }
    });
}

// 麦声音强度更新(level取值0~10)
- (void)micEnergyUpdate:(NSString *)userID oldLevel:(int)oldLevel newLevel:(int)newLevel
{
    // RLog(@"userID:%@ oldLevel:%d newLevel:%d", userID, oldLevel, newLevel);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:micEnergyUpdate:oldLevel:newLevel:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self micEnergyUpdate:userID oldLevel:oldLevel newLevel:newLevel];
        }
    });
}

// 本地音频设备有变化
- (void)audioDevChanged
{
    // RLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBackAudioDevChanged:)]) {
            [_videoMeetingDelegate videoMeetingCallBackAudioDevChanged:self];
        }
    });
}

// 音频设备状态变化
- (void)audioStatusChanged:(NSString *)userID oldStatus:(AUDIO_STATUS)oldStatus newStatus:(AUDIO_STATUS)newStatus
{
    // RLog(@"userID:%@ oldStatus:%d newStatus:%d", userID, oldStatus, newStatus);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:audioStatusChanged:oldStatus:newStatus:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self audioStatusChanged:userID oldStatus:oldStatus newStatus:newStatus];
        }
    });
}

// 视频设备状态变化
- (void)videoStatusChanged:(NSString *)userID oldStatus:(VIDEO_STATUS)oldStatus newStatus:(VIDEO_STATUS)newStatus
{
    // RLog(@"userID:%@ oldStatus:%d newStatus:%d", userID, oldStatus, newStatus);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:videoStatusChanged:oldStatus:newStatus:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self videoStatusChanged:userID oldStatus:oldStatus newStatus:newStatus];
        }
    });
}

- (void)openVideoRslt:(NSString *)devID success:(BOOL)bSuccess
{
    // RLog(@"bSuccess:%zd", bSuccess);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:openVideoRslt:success:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self openVideoRslt:devID success:bSuccess];
        }
    });
}

// 成员有新的视频图像数据到来(通过GetVideoImg获取）
- (void)notifyVideoData:(UsrVideoId *)userID frameTime:(long)frameTime
{
    // RLog(@"userID.userId:%@ userID.videoID:%d frameTime:%ld", userID.userId, userID.videoID, frameTime);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyVideoData:frameTime:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyVideoData:userID frameTime:frameTime];
        }
    });
}

// 本地视频设备有变化
- (void)videoDevChanged:(NSString *)userID
{
    // RLog(@"userID:%@", userID);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:videoDevChanged:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self videoDevChanged:userID];
        }
    });
}

- (void)defVideoChanged:(NSString *)userID videoID:(short)videoID
{
    // RLog(@"userID:%@ videoID:%d", userID, videoID);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:defVideoChanged:videoID:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self defVideoChanged:userID videoID:videoID];
        }
    });
}

// 屏幕共享操作通知
- (void)notifyScreenShareStarted
{
    // RLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBackNotifyScreenShareStarted:)]) {
            [_videoMeetingDelegate videoMeetingCallBackNotifyScreenShareStarted:self];
        }
    });
}

- (void)notifyScreenShareStopped
{
    // RLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBackNotifyScreenShareStopped:)]) {
            [_videoMeetingDelegate videoMeetingCallBackNotifyScreenShareStopped:self];
        }
    });
}

// 屏幕共享数据更新,用户收到该回调消息后应该调用getShareScreenDecodeImg获取最新的共享数据
- (void)notifyScreenShareData:(NSString *)userID changedRect:(CGRect)changedRect frameSize:(CGSize)size
{
    RLog(@"userID:%@ changedRect:%@ size:%@", userID, NSStringFromCGRect(changedRect), NSStringFromCGSize(size));
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyScreenShareData:changedRect:frameSize:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyScreenShareData:userID changedRect:changedRect frameSize:size];
        }
    });
}

// IM消息发送结果
- (void)sendIMmsgRlst:(NSString *)taskID sdkErr:(CRVIDEOSDK_ERR_DEF)sdkErr cookie:(NSString *)cookie
{
    RLog(@"taskID:%@ sdkErr:%zd cookie:%@", taskID, sdkErr, cookie);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:sendIMmsgRlst:sdkErr:cookie:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self sendIMmsgRlst:taskID sdkErr:sdkErr cookie:cookie];
        }
    });
}

// 通知收到文本消息
// FIXME:SDK接口更新导致IM回调引发崩溃 modified by king 20170902
- (void)notifyIMmsg:(NSString *)romUserID text:(NSString *)text sendTime:(int)sendTime
{
    RLog(@"romUserID:%@ text:%@", romUserID, text);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyIMmsg:text:sendTime:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyIMmsg:romUserID text:text sendTime:sendTime];
        }
    });
}

// 录制过程出错(导致录制停止)回调
- (void)recordErr:(REC_ERR_TYPE)sdkErr
{
    // RLog(@"sdkErr:%zd", sdkErr);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:recordErr:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self recordErr:sdkErr];
        }
    });
}

// 录制过程状态改变回调
- (void)recordStateChanged:(REC_STATE)state
{
    // RLog(@"state:%zd", state);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:recordStateChanged:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self recordStateChanged:state];
        }
    });
}

// 取消上传录制文件出错回调(未实现)
- (void)cancelUploadRecordFileErr:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    // RLog(@"sdkErr:%zd", sdkErr);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:cancelUploadRecordFileErr:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self cancelUploadRecordFileErr:sdkErr];
        }
    });
}

// 录制文件状态改变回调
- (void)uploadRecordFileSuccess:(NSString *)fileName fileUrl:(NSString *)fileUrl
{
    RLog(@"fileName:%@ fileUrl:%@", fileName, fileUrl);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:uploadRecordFileSuccess:fileUrl:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self uploadRecordFileSuccess:fileName fileUrl:fileUrl];
        }
    });
}

// 录制文件上传进度回调
- (void)notifyRecordFileUploadProgress:(NSString *)fileName percent:(int)percent
{
    RLog(@"fileName:%@ percent:%d", fileName, percent);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyRecordFileUploadProgress:percent:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyRecordFileUploadProgress:fileName percent:percent];
        }
    });
}


// 录制文件上传出错回调
- (void)uploadRecordFile:(NSString *)fileName err:(CRVIDEOSDK_ERR_DEF)sdkErr
{
    // RLog(@"fileName:%@ sdkErr:%zd", fileName, sdkErr);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:uploadRecordFile:err:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self uploadRecordFile:fileName err:sdkErr];
        }
    });
}

// 影音开始通知
- (void)notifyMediaStart:(NSString *)userid
{
    // RLog(@"userid:%@", userid);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyMediaStart:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyMediaStart:userid];
        }
    });
}

// 影音停止播放的通知
- (void)notifyMediaStop:(NSString *)userid reason:(MEDIA_STOP_REASON)reason
{
    // RLog(@"userid:%@ reason:%zd", userid, reason);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyMediaStop:reason:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyMediaStop:userid reason:reason];
        }
    });
}

// 影音暂停播放的通知
- (void)notifyMediaPause:(NSString *)userid bPause:(BOOL)bPause
{
    // RLog(@"userid:%@ bPause:%zd", userid, bPause);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyMediaPause:bPause:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyMediaPause:userid bPause:bPause];
        }
    });
}

// 视频帧数据已解好
- (void)notifyMemberMediaData:(NSString *)userid curPos:(int)curPos
{
    // RLog(@"userid:%@ curPos:%d", userid, curPos);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyMemberMediaData:curPos:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyMemberMediaData:userid curPos:curPos];
        }
    });
}

// 本地播放成功
- (void)notifyMediaOpened:(long)totalTime size:(CGSize)picSZ
{
    // RLog(@"totalTime:%d picSZ:%@", totalTime, NSStringFromCGSize(picSZ));
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyMediaOpened:size:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyMediaOpened:totalTime size:picSZ];
        }
    });
}


// 设定播放位置完成
- (void)notifyPlayPosSetted:(int)setPTS
{
    // RLog(@"setPTS:%d", setPTS);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyPlayPosSetted:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyPlayPosSetted:setPTS];
        }
    });
}

// 视频墙分屏模式回调
- (void)notifyVideoWallMode:(int)wallMode
{
    // RLog(@"wallMode:%d", wallMode);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyVideoWallMode:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyVideoWallMode:wallMode];
        }
    });
}

// 主视频回调
- (void)notifyMainVideo:(NSString *)userID
{
    // RLog(@"userID:%@", userID);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:notifyMainVideo:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self notifyMainVideo:userID];
        }
    });
}

- (void)notifyScreenMarkStarted
{
    RLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBackNotifyScreenMarkStarted:)]) {
            [_videoMeetingDelegate videoMeetingCallBackNotifyScreenMarkStarted:self];
        }
    });
}

- (void)notifyScreenMarkStopped
{
    RLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBackNotifyScreenMarkStopped:)]) {
            [_videoMeetingDelegate videoMeetingCallBackNotifyScreenMarkStopped:self];
        }
    });
}

- (void)enableOtherMark:(BOOL)enable
{
    RLog(@"enable:%zd", enable);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:enableOtherMark:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self enableOtherMark:enable];
        }
    });
}

- (void)sendMarkData:(MarkData *)markData
{
    RLog(@"markData.termid:%zd markData.termidSN:%zd markData.color:%zd markData.mousePosSeq:%zd", markData.termid, markData.termidSN, markData.color, [markData.mousePosSeq count]);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:sendMarkData:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self sendMarkData:markData];
        }
    });
}

- (void)sendAllMarkData:(NSArray<MarkData *> *)markDatas
{
    for (MarkData *markData in markDatas) {
        RLog(@"markData.termid:%zd markData.termidSN:%zd markData.color:%zd markData.mousePosSeq:%zd", markData.termid, markData.termidSN, markData.color, [markData.mousePosSeq count]);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBack:sendAllMarkData:)]) {
            [_videoMeetingDelegate videoMeetingCallBack:self sendAllMarkData:markDatas];
        }
    });
}

- (void)clearAllMarks;
{
    RLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoMeetingDelegate respondsToSelector:@selector(videoMeetingCallBackClearAllMarks:)]) {
            [_videoMeetingDelegate videoMeetingCallBackClearAllMarks:self];
        }
    });
}
@end
