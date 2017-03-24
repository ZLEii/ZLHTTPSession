//
//  ZLHttpSessionUpdata.m
//  test
//
//  Created by 张磊 on 16/6/17.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "ZLHttpSessionUpdata.h"
#define TimeOut 60.0

@interface ZLHttpSessionUpdata ()
@property (nonatomic,copy) ZLHttpProgressBlock progressBlock;
@property (nonatomic,copy) ZLHttpCompletionBlock completionBlock;
@end

@implementation ZLHttpSessionUpdata
- (void)postUpdataFromURL:(NSString *)url progressBlock:(ZLHttpProgressBlock)progressBlock completion:(ZLHttpCompletionBlock)completionBlock {
    if (url.length == 0) {
        return;
    }
    _progressBlock = progressBlock;
    _completionBlock = completionBlock;
    
    NSString *requestURLStr = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *requestURL = [NSURL URLWithString:requestURLStr];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TimeOut];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    
    [downloadTask resume];
}

@end
