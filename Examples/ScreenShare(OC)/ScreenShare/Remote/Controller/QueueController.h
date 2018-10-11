//
//  QueueController.h
//  Record
//
//  Created by king on 2017/6/12.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "BaseController.h"

@class OCRModel;

@interface QueueController : BaseController

@property (nonatomic, assign) int queID; /**< 队列ID */
@property (nonatomic, copy) NSString *queName; /**< 队列名称 */
@property (nonatomic, assign) NSInteger count; /**< 排队计时 */
@property (nonatomic, assign) NSInteger position; /**< 排队位置 */
@property (nonatomic, strong) OCRModel *model; /**< OCR 认证 */

@end
