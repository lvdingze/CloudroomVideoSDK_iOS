//
//  RecordController.h
//  Record
//
//  Created by king on 2017/6/9.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "BaseCollectionController.h"

@interface RecordController : BaseCollectionController

@property (nonatomic, assign) int queID; /**< 队列ID */
@property (nonatomic, copy) NSString *queName; /**< 队列名称 */
@property (nonatomic, assign) NSInteger count; /**< 排队计时 */
@property (nonatomic, assign) NSInteger position; /**< 排队位置 */

@end
