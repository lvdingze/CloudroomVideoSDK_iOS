//
//  MContentView.h
//  Meeting
//
//  Created by king on 2018/7/2.
//  Copyright © 2018年 BossKing10086. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MShareView, MTwoView, MFourView, MNineView, VideoFrame, UsrVideoId;

typedef NS_ENUM(NSInteger, MContentViewType) {
    MContentViewTypeTwo, // 二分屏
    MContentViewTypeFour, // 四分屏
    MContentViewTypeNine // 九分屏
};

@interface MContentView : UIView

@property (nonatomic, weak) IBOutlet MShareView *shareImageView; /**< 屏幕共享 */
@property (nonatomic, weak) IBOutlet MTwoView *twoView; /**< 二分屏 */
@property (nonatomic, weak) IBOutlet MFourView *fourView; /**< 四分屏 */
@property (nonatomic, weak) IBOutlet MNineView *nineView; /**< 九分屏 */
@property (nonatomic, assign) MContentViewType type; /**< 分屏模式 */

- (void)updateUIViews:(NSArray<UsrVideoId *> *)dataSource localer:(NSString *)localer;
- (void)displayFrame:(VideoFrame *)rawFrame userID:(UsrVideoId *)userID width:(int)width height:(int)height;

@end
