//
//  ChatController.h
//  BKChat
//
//  Created by king on 2018/3/1.
//  Copyright © 2018年 king. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessages.h"

@interface ChatController : JSQMessagesViewController

@property (nonatomic, copy) NSString *callID;
@property (nonatomic, copy) NSString *peerID;

@end
