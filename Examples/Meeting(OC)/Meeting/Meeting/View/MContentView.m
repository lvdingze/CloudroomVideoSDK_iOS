//
//  MContentView.m
//  Meeting
//
//  Created by king on 2018/7/2.
//  Copyright © 2018年 BossKing10086. All rights reserved.
//

#import "MContentView.h"

#import "MTwoView.h"
#import "MTwoOneView.h"
#import "MTwoTwoView.h"

#import "MFourView.h"
#import "MFourOneView.h"
#import "MFourTwoView.h"
#import "MFourThreeView.h"
#import "MFourFourView.h"

#import "MNineView.h"
#import "MNineOneView.h"
#import "MNineTwoView.h"
#import "MNineThreeView.h"
#import "MNineFourView.h"
#import "MNineFiveView.h"
#import "MNineSixView.h"
#import "MNineSevenView.h"
#import "MNineEgihtView.h"
#import "MNineNineView.h"

#import "MeetingHelper.h"

@implementation MContentView
#pragma mark - life cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    [self _commonSetup];
}

#pragma mark - public method
- (void)updateUIViews:(NSArray<UsrVideoId *> *)dataSource localer:(NSString *)localer {
    NSUInteger count = [dataSource count];
    
    if (count == 1) {
        self.type = MContentViewTypeTwo;
        _twoView.twoOneView.usrVideoId = dataSource[0];
        _twoView.twoTwoView.usrVideoId = nil;
    } else if (count == 2) {
        self.type = MContentViewTypeTwo;
        _twoView.twoOneView.usrVideoId = dataSource[0];
        _twoView.twoTwoView.usrVideoId = dataSource[1];
    } else if (count == 3) {
        self.type = MContentViewTypeFour;
        _fourView.fourOneView.usrVideoId = dataSource[0];
        _fourView.fourTwoView.usrVideoId = dataSource[1];
        _fourView.fourThreeView.usrVideoId = dataSource[2];
        _fourView.fourFourView.usrVideoId = nil;
    } else if (count == 4) {
        self.type = MContentViewTypeFour;
        _fourView.fourOneView.usrVideoId = dataSource[0];
        _fourView.fourTwoView.usrVideoId = dataSource[1];
        _fourView.fourThreeView.usrVideoId = dataSource[2];
        _fourView.fourFourView.usrVideoId = dataSource[3];
    } else if (count == 5) {
        self.type = MContentViewTypeNine;
        _nineView.nineOneView.usrVideoId = dataSource[0];
        _nineView.nineTwoView.usrVideoId = dataSource[1];
        _nineView.nineThreeView.usrVideoId = dataSource[2];
        _nineView.nineFourView.usrVideoId = dataSource[3];
        _nineView.nineFiveView.usrVideoId = dataSource[4];
        _nineView.nineSixView.usrVideoId = nil;
        _nineView.nineSevenView.usrVideoId = nil;
        _nineView.nineEightView.usrVideoId = nil;
        _nineView.nineNineView.usrVideoId = nil;
    } else if (count == 6) {
        self.type = MContentViewTypeNine;
        _nineView.nineOneView.usrVideoId = dataSource[0];
        _nineView.nineTwoView.usrVideoId = dataSource[1];
        _nineView.nineThreeView.usrVideoId = dataSource[2];
        _nineView.nineFourView.usrVideoId = dataSource[3];
        _nineView.nineFiveView.usrVideoId = dataSource[4];
        _nineView.nineSixView.usrVideoId = dataSource[5];
        _nineView.nineSevenView.usrVideoId = nil;
        _nineView.nineEightView.usrVideoId = nil;
        _nineView.nineNineView.usrVideoId = nil;
    } else if (count == 7) {
        self.type = MContentViewTypeNine;
        _nineView.nineOneView.usrVideoId = dataSource[0];
        _nineView.nineTwoView.usrVideoId = dataSource[1];
        _nineView.nineThreeView.usrVideoId = dataSource[2];
        _nineView.nineFourView.usrVideoId = dataSource[3];
        _nineView.nineFiveView.usrVideoId = dataSource[4];
        _nineView.nineSixView.usrVideoId = dataSource[5];
        _nineView.nineSevenView.usrVideoId = dataSource[6];
        _nineView.nineEightView.usrVideoId = nil;
        _nineView.nineNineView.usrVideoId = nil;
    } else if (count == 8) {
        self.type = MContentViewTypeNine;
        _nineView.nineOneView.usrVideoId = dataSource[0];
        _nineView.nineTwoView.usrVideoId = dataSource[1];
        _nineView.nineThreeView.usrVideoId = dataSource[2];
        _nineView.nineFourView.usrVideoId = dataSource[3];
        _nineView.nineFiveView.usrVideoId = dataSource[4];
        _nineView.nineSixView.usrVideoId = dataSource[5];
        _nineView.nineSevenView.usrVideoId = dataSource[6];
        _nineView.nineEightView.usrVideoId = dataSource[7];
        _nineView.nineNineView.usrVideoId = nil;
    } else if (count >=9) {
        self.type = MContentViewTypeNine;
        _nineView.nineOneView.usrVideoId = dataSource[0];
        _nineView.nineTwoView.usrVideoId = dataSource[1];
        _nineView.nineThreeView.usrVideoId = dataSource[2];
        _nineView.nineFourView.usrVideoId = dataSource[3];
        _nineView.nineFiveView.usrVideoId = dataSource[4];
        _nineView.nineSixView.usrVideoId = dataSource[5];
        _nineView.nineSevenView.usrVideoId = dataSource[6];
        _nineView.nineEightView.usrVideoId = dataSource[7];
        _nineView.nineNineView.usrVideoId = dataSource[8];
    } else {
        _twoView.twoOneView.usrVideoId = nil;
        _twoView.twoTwoView.usrVideoId = nil;
        
        _fourView.fourOneView.usrVideoId = nil;
        _fourView.fourTwoView.usrVideoId = nil;
        _fourView.fourThreeView.usrVideoId = nil;
        _fourView.fourFourView.usrVideoId = nil;
        
        _nineView.nineOneView.usrVideoId = nil;
        _nineView.nineTwoView.usrVideoId = nil;
        _nineView.nineThreeView.usrVideoId = nil;
        _nineView.nineFourView.usrVideoId = nil;
        _nineView.nineFiveView.usrVideoId = nil;
        _nineView.nineSixView.usrVideoId = nil;
        _nineView.nineSevenView.usrVideoId = nil;
        _nineView.nineEightView.usrVideoId = nil;
        _nineView.nineNineView.usrVideoId = nil;
    }
}

- (void)displayFrame:(VideoFrame *)rawFrame userID:(UsrVideoId *)userID width:(int)width height:(int)height {
    // FIXME:在后台OpenGL渲染会发生崩溃
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        // OpenGL ES -> render YUV
        if (self.type == MContentViewTypeTwo) { // 二分屏
            if ([_twoView.twoOneView.usrVideoId.userId isEqualToString:userID.userId] && _twoView.twoOneView.usrVideoId.videoID == userID.videoID) {
                [_twoView.twoOneView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_twoView.twoTwoView.usrVideoId.userId isEqualToString:userID.userId] && _twoView.twoTwoView.usrVideoId.videoID == userID.videoID) {
                [_twoView.twoTwoView displayYUV420pData:rawFrame->dat width:width height:height];
            }
        }
        else if (self.type == MContentViewTypeFour) { // 四分屏
            if ([_fourView.fourOneView.usrVideoId.userId isEqualToString:userID.userId] && _fourView.fourOneView.usrVideoId.videoID == userID.videoID) {
                [_fourView.fourOneView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_fourView.fourTwoView.usrVideoId.userId isEqualToString:userID.userId] && _fourView.fourTwoView.usrVideoId.videoID == userID.videoID) {
                [_fourView.fourTwoView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_fourView.fourThreeView.usrVideoId.userId isEqualToString:userID.userId] && _fourView.fourThreeView.usrVideoId.videoID == userID.videoID) {
                [_fourView.fourThreeView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_fourView.fourFourView.usrVideoId.userId isEqualToString:userID.userId] && _fourView.fourFourView.usrVideoId.videoID == userID.videoID) {
                [_fourView.fourFourView displayYUV420pData:rawFrame->dat width:width height:height];
            }
        }
        else if (self.type == MContentViewTypeNine) { // 九分屏
            if ([_nineView.nineOneView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineOneView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineOneView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_nineView.nineTwoView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineTwoView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineTwoView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_nineView.nineThreeView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineThreeView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineThreeView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_nineView.nineFourView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineFourView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineFourView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_nineView.nineFiveView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineFiveView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineFiveView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_nineView.nineSixView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineSixView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineSixView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_nineView.nineSevenView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineSevenView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineSevenView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_nineView.nineEightView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineEightView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineEightView displayYUV420pData:rawFrame->dat width:width height:height];
            }
            
            if ([_nineView.nineNineView.usrVideoId.userId isEqualToString:userID.userId] && _nineView.nineNineView.usrVideoId.videoID == userID.videoID) {
                [_nineView.nineNineView displayYUV420pData:rawFrame->dat width:width height:height];
            }
        }
    }
    
    free(rawFrame->dat);
}

#pragma mark - private method
- (void)_commonSetup {
    self.backgroundColor = UIColorFromRGBA(31, 47, 65, 1.0);
}

#pragma mark - getter & setter
- (void)setType:(MContentViewType)type {
    _type = type;
    
    switch (type) {
        case MContentViewTypeTwo: {
            [UIView animateWithDuration:0.25 animations:^{
                _twoView.alpha = 1.0;
                _fourView.alpha = 0;
                _nineView.alpha = 0;
            }];
            
            break;
        }
        case MContentViewTypeFour: {
            [UIView animateWithDuration:0.25 animations:^{
                _twoView.alpha = 0;
                _fourView.alpha = 1.0;
                _nineView.alpha = 0;
            }];
            
            break;
        }
        case MContentViewTypeNine: {
            [UIView animateWithDuration:0.25 animations:^{
                _twoView.alpha = 0;
                _fourView.alpha = 0;
                _nineView.alpha = 1.0;
            }];
            
            break;
        }
    }
}
@end
