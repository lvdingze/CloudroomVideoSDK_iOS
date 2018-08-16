//
//  AppDelegate.h
//  Meeting
//
//  Created by king on 2017/2/9.
//  Copyright © 2017年 BossKing10086. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoMgrCallBack;
@class VideoMeetingCallBack;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) VideoMgrCallBack *videoMgrCallBack; /**< 管理 */
@property (nonatomic, strong) VideoMeetingCallBack *videoMeetingCallBack; /**< 房间 */

@end

