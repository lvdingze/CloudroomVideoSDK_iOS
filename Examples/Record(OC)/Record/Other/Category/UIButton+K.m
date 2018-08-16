//
//  UIButton+K.m
//  Record
//
//  Created by king on 2017/8/17.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "UIButton+K.h"

@implementation UIButton (K)
#pragma mark - public method
- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state
{
    [self setBackgroundImage:[UIButton _imageWithColor:backgroundColor] forState:state];
}

#pragma mark - private method
+ (UIImage *)_imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
@end
