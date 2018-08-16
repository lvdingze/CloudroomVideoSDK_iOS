//
//  ConversationController.h
//  VideoCall
//
//  Created by king on 2016/11/23.
//  Copyright © 2016年 CloudRoom. All rights reserved.
//

#import "BaseController.h"
#import "VideoMeetingCallBack.h"
#import "QueueCallBack.h"
#import "VideoMgrCallBack.h"

@interface ConversationController : BaseController  <VideoMeetingDelegate, QueueDelegate, VideoMgrDelegate>

@property (nonatomic, copy) NSString *callID;
@property (nonatomic, copy) NSString *peerID;
@property (nonatomic, strong) MeetInfo *meetInfo;
@property (nonatomic, assign) BOOL isServer;

@end
