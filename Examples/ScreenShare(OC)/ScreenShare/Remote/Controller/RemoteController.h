//
//  RemoteController.h
//  Record
//
//  Created by king on 2017/8/15.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "BaseController.h"
#import "VideoMeetingCallBack.h"
#import "QueueCallBack.h"
#import "VideoMgrCallBack.h"

@interface RemoteController : BaseController <VideoMeetingDelegate, QueueDelegate, VideoMgrDelegate>

@property (nonatomic, copy) NSString *callID;
@property (nonatomic, copy) NSString *callerID;
@property (nonatomic, copy) NSString *peerID;
@property (nonatomic, strong) MeetInfo *meetInfo;

@end
