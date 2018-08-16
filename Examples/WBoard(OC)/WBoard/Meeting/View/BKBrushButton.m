//
//  BKBrushButton.m
//  WBoard
//
//  Created by cloudroom on 2018/7/30.
//  Copyright © 2018年 BossKing10086. All rights reserved.
//

#import "BKBrushButton.h"

@implementation BKBrushButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    if(self.selected)
    {
        self.layer.borderWidth = 3;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
    }else{
        self.layer.borderWidth = 0;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    
}
@end
