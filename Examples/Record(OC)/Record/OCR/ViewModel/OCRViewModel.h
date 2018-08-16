//
//  OCRViewModel.h
//  BKNetwork
//
//  Created by king on 2018/6/8.
//  Copyright © 2018年 king. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OCRModel;

typedef void (^OCRViewModelResponse) (OCRModel * _Nullable response, NSError * _Nullable error);

@interface OCRViewModel : NSObject

/* OCR 认证请求 */
- (nullable NSURLSessionDataTask *)ocrRequest:(NSDictionary *)parameters handler:(OCRViewModelResponse)handler;

/* 压缩图片尺寸 */
- (UIImage *)scaleImage:(UIImage *)sImage size:(CGSize)tSize;

/* 压缩图片质量,并进行 Base64 编码 */
- (NSData *)compressImage:(UIImage *)image quality:(CGFloat)quality;

/* Base64 编码 */
- (NSString *)stringFromDate:(NSData *)date;

@end
