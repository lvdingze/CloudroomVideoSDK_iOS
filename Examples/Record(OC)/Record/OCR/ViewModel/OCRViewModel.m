//
//  OCRViewModel.m
//  BKNetwork
//
//  Created by king on 2018/6/8.
//  Copyright © 2018年 king. All rights reserved.
//

#import "OCRViewModel.h"
#import "OCRModel.h"
#import "HTTPHelper.h"

@interface OCRViewModel ()

@property (nonatomic, strong) OCRModel *model; /**< model */

@end

@implementation OCRViewModel
#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"OCRViewModel dealloc");
}

#pragma mark - public method
/* OCR 认证请求 */
- (nullable NSURLSessionDataTask *)ocrRequest:(NSDictionary *)parameters handler:(OCRViewModelResponse)handler {
    return [[HTTPHelper shareInstance] cr_POST:@"http://test-openapi.situdata.com/id/ocr" parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"totalUnitCount:%lld completedUnitCount:%lld", downloadProgress.totalUnitCount, downloadProgress.completedUnitCount);
    } handler:^(id  _Nullable response, NSError * _Nullable error) {
        NSLog(@"response:%@ error:%@", response, error);
        id result = [response objectForKey:@"result"];
        
        if ([result isKindOfClass:[NSDictionary class]]) {
            [self _handleResult:(NSDictionary *)result];
        }
        
        if (handler) {
            handler(self.model, error);
        }
    }];
}

/* 压缩图片质量,并进行 Base64 编码 */
- (NSData *)compressImage:(UIImage *)image quality:(CGFloat)quality {
    if (!image) return nil;
    
    // 压缩图片质量
    return UIImageJPEGRepresentation(image, quality);
}

/* Base64 编码 */
- (NSString *)stringFromDate:(NSData *)date {
    NSString *fileStr = [date base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    return fileStr;
}

/* 压缩图片尺寸 */
- (UIImage *)scaleImage:(UIImage *)sImage size:(CGSize)tSize {
    CGSize sSize = sImage.size;
    CGRect dstRect = (CGRect){0, 0, tSize.width, tSize.height};
    
    if (CGSizeEqualToSize(sSize, tSize) == NO) {
        CGFloat factor = sSize.width / sSize.height;
        CGFloat itemW = tSize.width;
        CGFloat itemH = itemW * 1 / factor;
        
        if (itemH > tSize.height) {
            itemH = tSize.height;
            itemW = itemH * factor;
        }
        
        dstRect = (CGRect){0, 0, itemW, itemH};
    }
    
    // FIXME: 缩放图片变形(king 20180614)
    UIGraphicsBeginImageContext(dstRect.size);
    [sImage drawInRect:dstRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (!newImage) {
        NSLog(@"<<<< scale image fail >>>>");
    } else {
        NSLog(@"sSize:%@ tSize:%@ dstRect:%@", NSStringFromCGSize(sSize), NSStringFromCGSize(tSize), NSStringFromCGRect(dstRect));
    }
    
    return newImage;
}

#pragma mark - private method
- (void)_handleResult:(NSDictionary *)result {
    NSString *address = [result objectForKey:@"address"];
    if (address.length) {
        self.model.address = address;
    }
    
    NSString *agency = [result objectForKey:@"agency"];
    if (agency.length) {
        self.model.agency = agency;
    }
    
    NSString *birthday = [result objectForKey:@"birthday"];
    if (birthday.length) {
        self.model.birthday = birthday;
    }
    
    NSString *citizenId = [result objectForKey:@"citizenId"];
    if (citizenId.length) {
        self.model.citizenId = citizenId;
    }
    
    NSString *gender = [result objectForKey:@"gender"];
    if (gender.length) {
        self.model.gender = gender;
    }
    
    NSString *name = [result objectForKey:@"name"];
    if (name.length) {
        self.model.name = name;
    }
    
    NSString *nation = [result objectForKey:@"nation"];
    if (nation.length) {
        self.model.nation = nation;
    }
    
    NSString *validDateBegin = [result objectForKey:@"validDateBegin"];
    if (validDateBegin.length) {
        self.model.validDateBegin = validDateBegin;
    }
    
    NSString *validDateEnd = [result objectForKey:@"validDateEnd"];
    if (validDateEnd.length) {
        self.model.validDateEnd = validDateEnd;
    }
}

#pragma mark - getter & setter
- (OCRModel *)model {
    if (!_model) {
        _model = [[OCRModel alloc] init];
    }
    
    return _model;
}
@end
