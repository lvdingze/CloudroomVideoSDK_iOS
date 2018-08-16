//
//  FileMgrCallBack.m
//  Record
//
//  Created by king on 2017/8/17.
//  Copyright © 2017年 CloudRoom. All rights reserved.
//

#import "FileMgrCallBack.h"

@implementation FileMgrCallBack
#pragma mark - CloudroomHttpFileMgrCallBack
- (void)fileStateChanged:(NSString *)fileName state:(HTTP_TRANSFER_STATE)state
{
    // RLog(@"fileName:%@, state:%zd", fileName, state);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_fileMgrDelegate respondsToSelector:@selector(fileMgrCallBack:fileStateChanged:state:)]) {
            [_fileMgrDelegate fileMgrCallBack:self fileStateChanged:fileName state:state];
        }
    });
}

- (void)fileHttpRspHeader:(NSString *)fileName rspHeader:(NSString *)rspHeader
{
    // RLog(@"fileName:%@, rspHeader:%@", fileName, rspHeader);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_fileMgrDelegate respondsToSelector:@selector(fileMgrCallBack:fileHttpRspHeader:rspHeader:)]) {
            [_fileMgrDelegate fileMgrCallBack:self fileHttpRspHeader:fileName rspHeader:rspHeader];
        }
    });
}

- (void)fileProgress:(NSString *)fileName finishedSize:(int)finishedSize totalSize:(int)totalSize
{
    // RLog(@"fileName:%@, finisedSize:%d, totalSize:%d", fileName, finisedSize, totalSize);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_fileMgrDelegate respondsToSelector:@selector(fileMgrCallBack:fileProgress:finishedSize:totalSize:)]) {
            [_fileMgrDelegate fileMgrCallBack:self fileProgress:fileName finishedSize:finishedSize totalSize:totalSize];
        }
    });
}

- (void)fileFinished:(NSString *)fileName rslt:(HTTP_TRANSFER_RESULT)rslt
{
    // RLog(@"fileName:%@, rslt:%zd", fileName, rslt);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_fileMgrDelegate respondsToSelector:@selector(fileMgrCallBack:fileFinished:rslt:)]) {
            [_fileMgrDelegate fileMgrCallBack:self fileFinished:fileName rslt:rslt];
        }
    });
}

- (void)fileHttpRspContent:(NSString *)fileName content:(NSString *)content
{
    // RLog(@"fileName:%@, content:%@", fileName, content);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_fileMgrDelegate respondsToSelector:@selector(fileMgrCallBack:fileHttpRspContent:content:)]) {
            [_fileMgrDelegate fileMgrCallBack:self fileHttpRspContent:fileName content:content];
        }
    });
}

- (void)fileRename:(NSString *)fileName newName:(NSString *)newName
{
    // RLog(@"fileName:%@, newName:%@", fileName, newName);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_fileMgrDelegate respondsToSelector:@selector(fileMgrCallBack:fileRename:newName:)]) {
            [_fileMgrDelegate fileMgrCallBack:self fileRename:fileName newName:newName];
        }
    });
}
@end
