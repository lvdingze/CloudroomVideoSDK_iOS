//
//  RecordCell.h
//  Record
//
//  Created by king on 2017/8/15.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString * const record_ID;

@interface RecordCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@end
