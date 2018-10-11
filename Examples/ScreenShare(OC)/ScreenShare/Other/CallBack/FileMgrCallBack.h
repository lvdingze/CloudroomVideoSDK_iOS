//
//  FileMgrCallBack.h
//  Record
//
//  Created by king on 2017/8/17.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FileMgrCallBack;

@protocol FileMgrDelegate <NSObject>

@optional
- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileStateChanged:(NSString *)fileName state:(HTTP_TRANSFER_STATE)state;
- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileHttpRspHeader:(NSString *)fileName rspHeader:(NSString *)rspHeader;
- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileProgress:(NSString *)fileName finishedSize:(int)finishedSize totalSize:(int)totalSize;
- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileFinished:(NSString *)fileName rslt:(HTTP_TRANSFER_RESULT)rslt;
- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileHttpRspContent:(NSString *)fileName content:(NSString *)content;
- (void)fileMgrCallBack:(FileMgrCallBack *)callback fileRename:(NSString *)fileName newName:(NSString *)newName;

@end

@interface FileMgrCallBack : NSObject <CloudroomHttpFileMgrCallBack>

@property (nonatomic, weak) id <FileMgrDelegate> fileMgrDelegate;

@end
