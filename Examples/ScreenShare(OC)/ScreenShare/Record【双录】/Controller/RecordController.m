//
//  RecordController.m
//  Record
//
//  Created by king on 2017/6/9.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "RecordController.h"
#import "OCRController.h"
#import "YSProgressController.h"
#import "RecordCell.h"
#import "Record.h"
#import "BaseNavController.h"

@interface RecordController () 

@property (nonatomic, copy) NSMutableArray <Record *> *dataSource; /**< 数据源 */

@end

@implementation RecordController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForRecord];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_dataSource count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    RecordCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:record_ID forIndexPath:indexPath];
    [self _configureCell:cell rowAtIndexPath:indexPath];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) { // 远程业务
        [self _jumpToOCR];
    }
    else if (indexPath.row == 1) { // 自助业务
        [self _jumpToYSProgress];
    }
}

// 设置每个item的尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(([[UIScreen mainScreen] bounds].size.width - 5) * 0.5, 234);
}

// 设置每个item的UIEdgeInsets
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

// 设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 5;
}

// 设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 5;
}

#pragma mark - private method
- (void)_setupForRecord
{
    [self _setupForProperies];
    [self _setupForTitle];
}

/**
 设置属性
 */
- (void)_setupForProperies
{
    _dataSource = [NSMutableArray arrayWithCapacity:2];
    
    // 远程双录
    Record *remote = [[Record alloc] init];
    [remote setImage:@"record_remote_icon"];
    [remote setTitle:@"远程人工办理业务"];
    [remote setDesc:@"坐席引导完成产品,业务办理"];
    [_dataSource addObject:remote];
    
    // 自助双录
    Record *yourself = [[Record alloc] init];
    [yourself setImage:@"record_yourself_icon"];
    [yourself setTitle:@"自助办理业务"];
    [yourself setDesc:@"自行完成产品,业务的办理"];
    [_dataSource addObject:yourself];
}

/**
 设置标题
 */
- (void)_setupForTitle
{
    [self.navigationItem setTitle:@"请选择服务模式"];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

/**
 设置cell
 
 @param cell cell对象
 @param indexPath 行信息
 */
- (void)_configureCell:(RecordCell *)cell rowAtIndexPath:(NSIndexPath *)indexPath
{
    Record *record = [_dataSource objectAtIndex:indexPath.row];
    [cell.iconImage setImage:[UIImage imageNamed:record.image]];
    [cell.titleLabel setText:record.title];
    [cell.descLabel setText:record.desc];
}

/**
 跳转到"登录"界面
 */
- (void)_jumpToLogin
{
    // 注销
    [[CloudroomVideoMgr shareInstance] logout];
    
    // 跳转到"登录"界面
    UIStoryboard *login = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    BaseNavController *loginNav = [login instantiateInitialViewController];
    
    if (loginNav) {
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:loginNav];
    }
}

/* 跳转到"OCR"界面 */
- (void)_jumpToOCR {
    UIStoryboard *customer = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    OCRController *ocrVC = [customer instantiateViewControllerWithIdentifier:@"OCRController"];
    [ocrVC setQueID:_queID];
    [ocrVC setQueName:_queName];
    [ocrVC setPosition:_position];
    [ocrVC setCount:_count];
    
    if (ocrVC) {
        [self.navigationController pushViewController:ocrVC animated:YES];
    }
}

- (void)_jumpToYSProgress
{
    UIStoryboard *customer = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    YSProgressController *ysProgressVC = [customer instantiateViewControllerWithIdentifier:@"YSProgressController"];
    [ysProgressVC setQueID:_queID];
    [ysProgressVC setQueName:_queName];
    
    if (ysProgressVC) {
        [self.navigationController pushViewController:ysProgressVC animated:YES];
    }
}
@end
