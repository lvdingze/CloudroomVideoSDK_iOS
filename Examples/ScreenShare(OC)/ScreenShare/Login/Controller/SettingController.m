//
//  SettingController.m
//  Record
//
//  Created by king on 2017/12/26.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "SettingController.h"
#import "RecordHelper.h"

typedef NS_ENUM(NSInteger, SettingBtnType)
{
    SBT_reset, // 恢复默认值
    SBT_save // 保存
};

@interface SettingController ()


@property (weak, nonatomic) IBOutlet UITextField *serverText; /**< 服务器地址 */
@property (weak, nonatomic) IBOutlet UITextField *accountText; /**< 账号 */
@property (weak, nonatomic) IBOutlet UITextField *pswdText; /**< 密码 */
@property (weak, nonatomic) IBOutlet UIButton *resetBtn; /**< 恢复默认值 */
@property (weak, nonatomic) IBOutlet UIButton *saveBtn; /**< 保存 */

- (IBAction)clickBtnForSetting:(UIButton *)sender;

@end

@implementation SettingController
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _setupForSetting];
}

#pragma mark - selector
- (IBAction)clickBtnForSetting:(UIButton *)sender
{
    switch ([sender tag]) {
        case SBT_reset: { // 恢复默认值
            // 恢复默认值操作
            [self _handleReset];
            
            break;
        }
        case SBT_save: { // 保存
            // 恢复默认值操作
            [self _handleSave];
            
            break;
        }
        default: break;
    }
}

#pragma mark - private method
- (void)_setupForSetting
{
    [self _setupForProperies];
    
    RecordHelper *recordHelper = [RecordHelper shareInstance];
    [recordHelper readInfo];
    
    if ([NSString stringCheckEmptyOrNil:recordHelper.account] ||
        [NSString stringCheckEmptyOrNil:recordHelper.pswd] ||
        [NSString stringCheckEmptyOrNil:recordHelper.server]) {
        [self _handleReset];
    }
    else {
        [_accountText setText:recordHelper.account];
        [_pswdText setText:recordHelper.pswd];
        [_serverText setText:recordHelper.server];
    }
}

- (void)_setupForProperies
{
    [_resetBtn setBackgroundColor:UIColorFromRGB(0x2899E6)];
    [_resetBtn setEnabled:YES];
    [_resetBtn.layer setCornerRadius:4];
    [_resetBtn.layer masksToBounds];
    
    [_saveBtn setBackgroundColor:UIColorFromRGB(0x2899E6)];
    [_saveBtn setEnabled:YES];
    [_saveBtn.layer setCornerRadius:4];
    [_saveBtn.layer masksToBounds];
    
    [_serverText setValue:UIColorFromRGB(0xFFFFFF) forKeyPath:@"_placeholderLabel.textColor"];
    [_accountText setValue:UIColorFromRGB(0xFFFFFF) forKeyPath:@"_placeholderLabel.textColor"];
    [_pswdText setValue:UIColorFromRGB(0xFFFFFF) forKeyPath:@"_placeholderLabel.textColor"];
}

- (void)_handleReset
{
    RecordHelper *recordHelper = [RecordHelper shareInstance];
    [recordHelper resetInfo];
    
    [_accountText setText:recordHelper.account];
    [_pswdText setText:recordHelper.pswd];
    [_serverText setText:recordHelper.server];
}

- (void)_handleSave
{
    NSString *server = _serverText.text;
    NSString *account = _accountText.text;
    NSString *pswd = _pswdText.text;
    
    if ([NSString stringCheckEmptyOrNil:server]) {
        [HUDUtil hudShow:@"服务器地址不能为空!" delay:3 animated:YES];
        return;
    }
    
    if ([NSString stringCheckEmptyOrNil:account]) {
        [HUDUtil hudShow:@"账号不能为空!" delay:3 animated:YES];
        return;
    }
    
    if ([NSString stringCheckEmptyOrNil:pswd]) {
        [HUDUtil hudShow:@"密码不能为空!" delay:3 animated:YES];
        return;
    }
    
    RecordHelper *recordHelper = [RecordHelper shareInstance];
    [recordHelper writeAccount:account pswd:pswd server:server];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}
@end
