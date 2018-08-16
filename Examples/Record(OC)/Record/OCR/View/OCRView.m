//
//  NetworkView.m
//  BKNetwork
//
//  Created by king on 2018/6/8.
//  Copyright © 2018年 king. All rights reserved.
//

#import "OCRView.h"

typedef NS_ENUM(NSUInteger, OCRViewBtnType) {
    OCRViewBtnTypeFront,
    OCRViewBtnTypeBack,
};

@interface OCRView ()

@property (nonatomic, assign, readwrite) BOOL back; /**< 背面? */
@property (nonatomic, assign, readwrite) BOOL front; /**< 正面? */
@property (nonatomic, copy) OCRViewBtnResponse response; /**< 回调 */

- (IBAction)clickBtnForNetwork:(UIButton *)sender;

@end

@implementation OCRView
#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"OCRView dealloc");
}

#pragma mark - public method
- (void)setBtnClickResponse:(OCRViewBtnResponse)response {
    if (response) {
        _response = [response copy];
    }
}

#pragma mark - selector
- (IBAction)clickBtnForNetwork:(UIButton *)sender {
    switch ([sender tag]) {
        case OCRViewBtnTypeFront:
            [self setBack:NO];
            [self setFront:YES];
            
            break;
        case OCRViewBtnTypeBack:
            [self setBack:YES];
            [self setFront:NO];
            
            break;
    }
    
    if (_response) {
        _response(self, sender);
    }
}
@end
