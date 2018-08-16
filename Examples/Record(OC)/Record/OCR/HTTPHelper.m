//
//  HTTPHelper.m
//  BKNetwork
//
//  Created by king on 2018/6/7.
//  Copyright © 2018年 king. All rights reserved.
//

#import "HTTPHelper.h"
#import "AFNetworking.h"

@interface HTTPHelper ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation HTTPHelper
#pragma mark - singleton
+ (instancetype)shareInstance {
    static HTTPHelper *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    
    return shareInstance;
}

#pragma mark - public method
- (nullable NSURLSessionDataTask *)cr_GET:(nonnull NSString *)url
                      parameters:(nullable id)parameters
                        progress:(GETProgressResponse)progress
                         handler:(GETPOSTResponse)handler {
    return [self.manager GET:url parameters:parameters progress:progress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            handler(responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(nil, error);
        }
    }];
}

- (nullable NSURLSessionDataTask *)cr_POST:(nonnull NSString *)url
                       parameters:(nullable id)parameters
                         progress:(void (^)(NSProgress * _Nonnull))progress
                          handler:(GETPOSTResponse)handler {
    return [self.manager POST:url parameters:parameters progress:progress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            handler(responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(nil, error);
        }
    }];
}

#pragma mark - getter & setter
- (AFHTTPSessionManager *)manager {
    if (!_manager) {
        _manager = [AFHTTPSessionManager manager];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        // https://www.jianshu.com/p/dbe3c5390b88
        [_manager.requestSerializer setValue:@"23F95EB8743945EE6DF5814E1F0BCDAD" forHTTPHeaderField:@"X-Auth-Token"];
    }
    
    return _manager;
}
@end
