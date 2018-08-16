//
//  PMRoundTextField.m
//  Meeting
//
//  Created by king on 2018/6/27.
//  Copyright © 2018年 BossKing10086. All rights reserved.
//

#import "PMRoundTextField.h"

@implementation PMRoundTextField
#pragma mark - life cycle
- (void)awakeFromNib {
    [super awakeFromNib];
}

#pragma mark - getter & setter
- (void)setTitle:(NSString *)title {
    self.font = [UIFont systemFontOfSize:16];
    self.layer.cornerRadius = 20;
    self.layer.masksToBounds = YES;
    self.layer.borderColor = UIColorFromRGBA(41, 171, 145, 1.0).CGColor;
    self.layer.borderWidth = 1;
    [self setTextColor:UIColorFromRGBA(41, 171, 145, 1.0)];
    if (!title || title.length <= 0) {
        self.leftView = [[UIView alloc] initWithFrame:(CGRect){0, 0, 10, 10}];
    } else {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:(CGRect){0, 0, 100, 36}];
        titleLabel.textColor = UIColorFromRGBA(41, 171, 145, 1.0);
        titleLabel.font = [UIFont systemFontOfSize:14];
        
        // FIXME: 设置界面与设计图不太符 (lennon 20180718)
        NSMutableParagraphStyle *par = [[NSMutableParagraphStyle alloc]init];
        par.alignment = NSTextAlignmentJustified;
        NSDictionary *attributedDic = @{NSParagraphStyleAttributeName : par,NSKernAttributeName:@(3.75)};
        if([title isEqualToString:@"密     码："]){
            attributedDic = @{NSParagraphStyleAttributeName : par,NSKernAttributeName:@(3.1)};
        }
        else  if([title isEqualToString:@"服务器地址："])
        {
            attributedDic = @{NSParagraphStyleAttributeName : par,NSKernAttributeName:@(0.3)};
        }
        NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc]initWithString:title attributes:attributedDic];
        titleLabel.attributedText = attributedStr;
        
        titleLabel.textAlignment = NSTextAlignmentRight;
        self.leftView = titleLabel;
    }
    
    self.leftViewMode = UITextFieldViewModeAlways;
    
    _title = title;
    
}
@end
