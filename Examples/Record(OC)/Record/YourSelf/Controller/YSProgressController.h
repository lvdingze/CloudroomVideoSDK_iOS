//
//  YSProgressController.h
//  Record
//
//  Created by king on 2017/8/16.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "BaseController.h"

@interface YSProgressController : BaseController

@property (nonatomic, assign) int queID; /**< 队列ID */
@property (nonatomic, copy) NSString *queName; /**< 队列名称 */

@end
