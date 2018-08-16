//
//  SDKUtil.h
//  Meeting
//
//  Created by king on 2018/7/4.
//  Copyright © 2018年 BossKing10086. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDKUtil : NSObject

+ (void)openLocalMic;
+ (void)closeLocalMic;
+ (void)openLocalCamera;
+ (void)closeLocalCamera;
+ (BOOL)isLocalCameraOpen;

+ (void)setRatio:(VIDEO_SIZE_TYPE)sizeType;
+ (void)setFps:(int)fps;
+ (void)setPriority:(int)max min:(int)min;
+ (void)setLocalCameraWHRate:(VIDEO_WHRATE_TYPE)whRate;

+ (NSString *)getStringFromRatio;
+ (NSString *)getStringFromFrame;
+ (VIDEO_SIZE_TYPE)getRatioFromString:(NSString *)ratioStr;

+ (VIDEO_STATUS)getLocalCameraStatus;
+ (AUDIO_STATUS)getLocalMicStatus;

@end
