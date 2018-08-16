//
//  HTTPHelper.h
//  BKNetwork
//
//  Created by king on 2018/6/7.
//  Copyright © 2018年 king. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^GETProgressResponse) (NSProgress * _Nonnull downloadProgress);
typedef void (^GETPOSTResponse) (id  _Nullable response, NSError * _Nullable error);

@interface HTTPHelper : NSObject

+ (instancetype)shareInstance;

- (nullable NSURLSessionDataTask *)cr_GET:(nonnull NSString *)url
                               parameters:(nullable id)parameters
                                 progress:(GETProgressResponse)progress
                                  handler:(GETPOSTResponse)handler;
- (nullable NSURLSessionDataTask *)cr_POST:(nonnull NSString *)url
                                parameters:(nullable id)parameters
                                  progress:(GETProgressResponse)progress
                                   handler:(GETPOSTResponse)handler;
@end
