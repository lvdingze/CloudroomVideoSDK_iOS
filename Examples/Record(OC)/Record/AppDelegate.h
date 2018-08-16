//
//  AppDelegate.h
//  Record
//
//  Created by king on 2017/6/8.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoMgrCallBack;
@class VideoMeetingCallBack;
@class QueueCallBack;
@class FileMgrCallBack;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) VideoMgrCallBack *videoMgrCallBack; /**< 管理 */
@property (nonatomic, strong) QueueCallBack *queueCallBack; /**< 队列 */
@property (nonatomic, strong) VideoMeetingCallBack *videoMeetingCallBack; /**< 会议 */
@property (nonatomic, strong) FileMgrCallBack *fileMgrCallBack; /**< HTTP文件管理 */

@end

