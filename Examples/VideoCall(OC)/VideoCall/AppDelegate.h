//
//  AppDelegate.h
//  VideoCall
//
//  Created by king on 2016/11/21.
//  Copyright © 2016年 CloudRoom. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoMgrCallBack;
@class VideoMeetingCallBack;
@class QueueCallBack;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) VideoMgrCallBack *videoMgrCallBack; /**< 管理 */
@property (nonatomic, strong) QueueCallBack *queueCallBack; /**< 队列 */
@property (nonatomic, strong) VideoMeetingCallBack *videoMeetingCallBack; /**< 会议 */

@end

