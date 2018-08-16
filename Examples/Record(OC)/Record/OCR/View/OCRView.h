//
//  OCRView.h
//  BKNetwork
//
//  Created by king on 2018/6/8.
//  Copyright © 2018年 king. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OCRView;

typedef void (^OCRViewBtnResponse) (OCRView *view, UIButton *sender);

@interface OCRView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *frontImageView; /**< 正面 */
@property (weak, nonatomic) IBOutlet UIImageView *backImageView; /**< 背面 */
@property (nonatomic, assign, readonly) BOOL back; /**< 背面? */
@property (nonatomic, assign, readonly) BOOL front; /**< 正面? */

- (void)setBtnClickResponse:(OCRViewBtnResponse)response;

@end
