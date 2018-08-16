//
//  MChatCell.m
//  Meeting
//
//  Created by king on 2018/7/9.
//  Copyright © 2018年 BossKing10086. All rights reserved.
//

#import "MChatCell.h"
#import "MChatModel.h"
#import "Masonry.h"

@interface MChatCell ()

@property (nonatomic, strong) UILabel *contentLabel;

@end

@implementation MChatCell
#pragma mark - life cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self _commonSetup];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (!self) {
        return nil;
    }
    
    [self _commonSetup];
    
    return self;
}

#pragma mark - public method
- (CGFloat)heightForModel:(MChatModel *)model {
    self.model = model;
    
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

#pragma mark - getter & setter
- (void)setModel:(MChatModel *)model {
    _model = model;
    
    NSMutableAttributedString *comp = [[NSMutableAttributedString alloc] init];
    NSAttributedString *name = [[NSAttributedString alloc] initWithString:model.name attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: UIColorFromRGBA(57, 171, 251, 1.0)}];
    NSAttributedString *c = [[NSAttributedString alloc] initWithString:@"：" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    NSAttributedString *content = [[NSAttributedString alloc] initWithString:model.content attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    [comp appendAttributedString:name];
    [comp appendAttributedString:c];
    [comp appendAttributedString:content];
    
    _contentLabel.attributedText = comp;
}

#pragma mark - private method
- (void)_commonSetup {
    UIImageView *placeImageView  =[[UIImageView alloc] init];
    [placeImageView setImage:[UIImage imageNamed:@"chat_place_holder_30"]];
    [self.contentView addSubview:placeImageView];
    [placeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(8);
        make.width.equalTo(self.contentView).multipliedBy(0.5).offset(-16);
        make.top.equalTo(self.contentView).offset(4);
        make.bottom.equalTo(self.contentView).offset(-4);
    }];
    
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.font = [UIFont systemFontOfSize:14];
    contentLabel.textAlignment = NSTextAlignmentLeft;
    contentLabel.numberOfLines = 0;
    contentLabel.backgroundColor = [UIColor clearColor];
    // FIXME: 必须设置,否则不能正确算高 (king 20180707)
    contentLabel.preferredMaxLayoutWidth = [UIScreen mainScreen].bounds.size.width * 0.5 - 4 - 16;
    [placeImageView addSubview:contentLabel];
    [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(placeImageView).offset(2);
        make.left.equalTo(placeImageView).offset(2);
        make.bottom.equalTo(placeImageView).offset(-2);
        make.right.equalTo(placeImageView).offset(-2);
    }];
    
    _contentLabel = contentLabel;
    
    self.contentView.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
}
@end
