//
//  SDKUtil.m
//  Meeting
//
//  Created by king on 2018/7/4.
//  Copyright © 2018年 BossKing10086. All rights reserved.
//

#import "SDKUtil.h"

@implementation SDKUtil
/* 打开本地麦克风 */
+ (void)openLocalMic {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    AUDIO_STATUS status = [cloudroomVideoMeeting getAudioStatus:myUserID];
    
    if (status != AOPEN && status != AOPENING) {
        [cloudroomVideoMeeting openMic:myUserID];
    }
}

/* 关闭本地麦克风 */
+ (void)closeLocalMic {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    AUDIO_STATUS status = [cloudroomVideoMeeting getAudioStatus:myUserID];
    
    if (status == AOPEN || status == AOPENING) {
        [cloudroomVideoMeeting closeMic:myUserID];
    }
}

/* 打开本地摄像头 */
+ (void)openLocalCamera {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    VIDEO_STATUS status = [cloudroomVideoMeeting getVideoStatus:myUserID];
    
    if (status != VOPEN && status != VOPENING) {
        [cloudroomVideoMeeting openVideo:myUserID];
    }
}

/* 关闭本地摄像头 */
+ (void)closeLocalCamera {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    VIDEO_STATUS status = [cloudroomVideoMeeting getVideoStatus:myUserID];
    
    if (status == VOPEN || status == VOPENING) {
        [cloudroomVideoMeeting closeVideo:myUserID];
    }
}

+ (BOOL)isLocalCameraOpen {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    VIDEO_STATUS status = [cloudroomVideoMeeting getVideoStatus:myUserID];
    
    return status == VOPEN || status == VOPENING;
}

+ (void)setRatio:(VIDEO_SIZE_TYPE)sizeType {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [cloudroomVideoMeeting getVideoCfg];
    
    [vCfg setSizeType:sizeType];
    [vCfg setMaxbps:[self _getMaxBpsFromSizeType:sizeType]];
    
    [cloudroomVideoMeeting setVideoCfg:vCfg];
}

+ (void)setFps:(int)fps {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [cloudroomVideoMeeting getVideoCfg];
    
    [vCfg setFps:fps];
    
    [cloudroomVideoMeeting setVideoCfg:vCfg];
}

+ (void)setPriority:(int)max min:(int)min {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [cloudroomVideoMeeting getVideoCfg];
    
    // 画质优先(max: 25 min: 22)
    // 速度优先(max: 36 min: 22)
    [vCfg setMaxQuality:max];
    [vCfg setMinQuality:min];
    
    [cloudroomVideoMeeting setVideoCfg:vCfg];
}

+ (void)setLocalCameraWHRate:(VIDEO_WHRATE_TYPE)whRate {
    CloudroomVideoMeeting *videoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [videoMeeting getVideoCfg];
    
    vCfg.whRate = whRate;
    
    [videoMeeting setVideoCfg:vCfg];
}

+ (NSString *)getStringFromRatio {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [cloudroomVideoMeeting getVideoCfg];
    NSString *result = nil;
    switch (vCfg.sizeType) {
        case VSIZE_SZ_360: {
            result = @"360*360";
            break;
        }
        case VSIZE_SZ_480: {
            result = @"480*480";
            break;
        }
        case VSIZE_SZ_720: {
            result = @"720*720";
            break;
        }
        default: {
            result = @"other";
            break;
        }
    }
    
    return result;
}

+ (NSString *)getStringFromFrame {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    VideoCfg *vCfg = [cloudroomVideoMeeting getVideoCfg];
    return [NSString stringWithFormat:@"%d", vCfg.fps];
}

+ (VIDEO_SIZE_TYPE)getRatioFromString:(NSString *)ratioStr {
    VIDEO_SIZE_TYPE result = VSIZE_SZ_128;
    
    if ([ratioStr isEqualToString:@"360*360"]) {
        result = VSIZE_SZ_360;
    } else if ([ratioStr isEqualToString:@"480*480"]) {
        result = VSIZE_SZ_480;
    } else if ([ratioStr isEqualToString:@"720*720"]) {
        result = VSIZE_SZ_720;
    }
    
    return result;
}

+ (VIDEO_STATUS)getLocalCameraStatus {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    
    return [cloudroomVideoMeeting getVideoStatus:myUserID];
}

+ (AUDIO_STATUS)getLocalMicStatus {
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    NSString *myUserID = [cloudroomVideoMeeting getMyUserID];
    
    return [cloudroomVideoMeeting getAudioStatus:myUserID];
}

#pragma mark - private method
+ (int)_getMaxBpsFromSizeType:(VIDEO_SIZE_TYPE)sizeType {
    int maxBps = -1;
    switch (sizeType) {
        case VSIZE_SZ_128: { maxBps = 72000; break; }
        case VSIZE_SZ_160: { maxBps = 100000; break; }
        case VSIZE_SZ_192: { maxBps = 150000; break; }
        case VSIZE_SZ_256: { maxBps = 200000; break; }
        case VSIZE_SZ_288: { maxBps = 250000; break; }
        case VSIZE_SZ_320: { maxBps = 300000; break; }
        case VSIZE_SZ_360: { maxBps = 350000; break; }
        case VSIZE_SZ_400: { maxBps = 420000; break; }
        case VSIZE_SZ_480: { maxBps = 500000; break; }
        case VSIZE_SZ_576: { maxBps = 650000; break; }
        case VSIZE_SZ_720: { maxBps = 1000000; break; }
        case VSIZE_SZ_1080: { maxBps = 2000000; break; }
    }
    
    return maxBps;
}
@end
