//
//  OCRController.m
//  BKNetwork
//
//  Created by king on 2018/6/7.
//  Copyright © 2018年 king. All rights reserved.
//

#import "OCRController.h"
#import "QueueController.h"
#import "OCRView.h"
#import "OCRViewModel.h"
#import "OCRModel.h"
#import "PathUtil.h"
#import "UIImage+Rotate.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface OCRController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) OCRViewModel *viewModel; /**< viewModel */
@property (nonatomic, strong) UIImagePickerController *pickerController;
@property (nonatomic, strong) OCRModel *model; /**< OCR 认证 */

- (IBAction)clickBarBtnForOCR:(UIBarButtonItem *)sender;

@end

@implementation OCRController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    OCRView *view = (OCRView *)self.view;
    // TODO: 循环引用(king 20180608)
    weakify(self)
    [view setBtnClickResponse:^(OCRView *view, UIButton *sender) {
    strongify(self)
        [sSelf _handleCamera];
    }];
}

- (void)dealloc {
    NSLog(@"OCRController dealloc");
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *srcImage = info[UIImagePickerControllerOriginalImage];
        // FIXME: 保证图片尺寸: 640 * 480(king 20180615)
        UIImage *scaleImage = [self.viewModel scaleImage:srcImage size:(CGSize){640, 640}];
        if ((scaleImage.size.height / scaleImage.size.width) != (3 / 4.0)) {
            scaleImage = [scaleImage rotate:UIImageOrientationLeft];
        }
        
        NSData *imageData = [self.viewModel compressImage:scaleImage quality:0.5];
        UIImage *compressImage = [UIImage imageWithData:imageData];
     
        NSString *imageStr = [self.viewModel stringFromDate:imageData];
        OCRView *view = (OCRView *)self.view;
        [imageData writeToFile:[PathUtil searchPathInCacheDir:(view.back && !view.front) ? @"CloudroomVideoSDK/back.png" : @"CloudroomVideoSDK/font.png"] atomically:YES];
        NSLog(@"srcImage:%@ scaleImage:%@ compressImage:%@ imageStr:%zd", NSStringFromCGSize(srcImage.size), NSStringFromCGSize(scaleImage.size), NSStringFromCGSize(compressImage.size), imageStr.length);
        NSDictionary *info = @{@"idcard" : imageStr};
        [self dismissViewControllerAnimated:YES completion:^{
            [HUDUtil hudShowProgress:nil animated:YES];
            [self.viewModel ocrRequest:info handler:^(OCRModel * _Nullable response, NSError * _Nullable error) {
                NSLog(@"model:%@", response);
                [HUDUtil hudHiddenProgress:YES];
                [self _updateViewImage:compressImage];
                [self setModel:response];
                if (error) {
                    [HUDUtil hudShow:@"上传失败" delay:3 animated:YES];
                }
            }];
        }];
    }
}

#pragma mark - selector
- (IBAction)clickBarBtnForOCR:(UIBarButtonItem *)sender {
    if (sender.enabled) {
        [self _jumpToQueue];
    }
}

#pragma mark - private method
- (void)_handleCamera {
    [HUDUtil hudShow:@"请保持横屏拍照" delay:3 animated:YES];
    [self presentViewController:self.pickerController animated:YES completion:nil];
}

- (void)_updateViewImage:(UIImage *)image {
    OCRView *view = (OCRView *)self.view;
    
    if (view.back && !view.front) {
        [view.backImageView setImage:image];
    } else if (!view.back && view.front) {
        [view.frontImageView setImage:image];
    } else {
        [view.backImageView setImage:[UIImage imageNamed:@"back"]];
        [view.frontImageView setImage:[UIImage imageNamed:@"font"]];
    }
}

- (void)_jumpToQueue {
    UIStoryboard *customer = [UIStoryboard storyboardWithName:@"Record" bundle:nil];
    QueueController *queueVC = [customer instantiateViewControllerWithIdentifier:@"QueueController"];
    [queueVC setQueID:_queID];
    [queueVC setQueName:_queName];
    [queueVC setPosition:_position];
    [queueVC setCount:_count];
    [queueVC setModel:_model];
    
    if (queueVC) {
        [self.navigationController pushViewController:queueVC animated:YES];
    }
}

#pragma mark - getter & setter
- (UIImagePickerController *)pickerController {
    if (!_pickerController) {
        _pickerController = [[UIImagePickerController alloc] init];
        // 代理
        _pickerController.delegate = self;
        // 源:摄像头
        _pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        // 前/后
        _pickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        // 相机类型:拍照
        _pickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        // 质量
        _pickerController.videoQuality = UIImagePickerControllerQualityTypeLow;
        // 摄像头模式:拍照
        _pickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    }
    
    return _pickerController;
}

- (OCRViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[OCRViewModel alloc] init];
    }
    
    return _viewModel;
}
@end
