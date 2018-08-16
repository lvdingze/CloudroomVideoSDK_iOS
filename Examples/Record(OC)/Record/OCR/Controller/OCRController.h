//
//  OCRController.h
//  BKNetwork
//
//  Created by king on 2018/6/7.
//  Copyright © 2018年 king. All rights reserved.
//

#import "BaseController.h"

@interface OCRController : BaseController

@property (nonatomic, assign) int queID; /**< 队列ID */
@property (nonatomic, copy) NSString *queName; /**< 队列名称 */
@property (nonatomic, assign) NSInteger count; /**< 排队计时 */
@property (nonatomic, assign) NSInteger position; /**< 排队位置 */

@end

