//
//  OCRModel.h
//  BKNetwork
//
//  Created by king on 2018/6/8.
//  Copyright © 2018年 king. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCRModel : NSObject

@property (nonatomic, copy) NSString *address; /**< 住址 */
@property (nonatomic, copy) NSString *agency; /**< 签发机关 */
@property (nonatomic, copy) NSString *birthday; /**< 出生 */
@property (nonatomic, copy) NSString *citizenId; /**< 公民身份号码 */
@property (nonatomic, copy) NSString *gender; /**< 民族 */
@property (nonatomic, copy) NSString *name; /**< 姓名 */
@property (nonatomic, copy) NSString *nation; /**< 性别 */
@property (nonatomic, copy) NSString *validDateBegin; /**< 有效期限 */
@property (nonatomic, copy) NSString *validDateEnd; /**< 有效期限 */

@end
