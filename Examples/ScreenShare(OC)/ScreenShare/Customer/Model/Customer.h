//
//  Customer.h
//  Record
//
//  Created by king on 2017/6/9.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Customer : NSObject

@property (nonatomic, strong) QueueInfo *queueInfo;
@property (nonatomic, strong) QueueStatus *queueStatus;
@property (nonatomic, getter = isServiced) BOOL serviced;

@end
