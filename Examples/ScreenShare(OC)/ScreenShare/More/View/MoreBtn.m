//
//  MoreBtn.m
//  Record
//
//  Created by king on 2017/8/21.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "MoreBtn.h"

#define viewW self.bounds.size.width
#define viewH self.bounds.size.height
#define viewCenterX self.center.x

const CGFloat ratio = 0.55;

@implementation MoreBtn
#pragma mark - life cycle
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (!self) {
        return nil;
    }
    
    [self _setup];
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    [self _setup];
    
    return self;
}

#pragma mark - private method
- (void)_setup
{
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
}

#pragma mark - override
- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGFloat w = viewH * ratio;
    CGFloat h = w;
    CGFloat x = (viewW - w) * 0.5;
    CGFloat y = 0;
    return (CGRect){x, y, w, h};
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGFloat x = 0;
    CGFloat y = viewH * (1 - ratio);
    CGFloat w = viewW;
    CGFloat h = viewH * ratio;
    return (CGRect){x, y, w, h};
}
@end
