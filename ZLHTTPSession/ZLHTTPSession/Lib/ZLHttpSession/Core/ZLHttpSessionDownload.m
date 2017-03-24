//
//  ZLHttpSessionDownload.m
//  NameCard
//
//  Created by 张磊 on 16/6/17.
//  Copyright © 2016年 zhanglei. All rights reserved.
// 可以监听进度的下载


#import "ZLHttpSessionDownload.h"

#define TimeOut 60.0
@interface ZLHttpSessionDownload () <NSURLSessionDownloadDelegate,NSURLSessionTaskDelegate>
@property (nonatomic,strong) NSURLSession *session;
@property (nonatomic,copy) ZLHttpProgressBlock progressBlock;
@property (nonatomic,copy) ZLHttpCompletionBlock completionBlock;
@property (nonatomic,strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic,strong) NSData *resumData;
@end

@implementation ZLHttpSessionDownload

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}

- (void)downLoadFromURL:(NSString *)url progressBlock:(ZLHttpProgressBlock)progressBlock completion:(ZLHttpCompletionBlock)completionBlock {
    if (url.length == 0) {
        return;
    }

    _progressBlock = progressBlock;
    _completionBlock = completionBlock;
    
    NSString *requestURLStr = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *requestURL = [NSURL URLWithString:requestURLStr];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TimeOut];
    
    _downloadTask = [self.session downloadTaskWithRequest:request];
    
    [_downloadTask resume];
}

// 取消下载
- (BOOL)cancelDownLoadTask {
    self.resumData = nil;
    [self.downloadTask cancel];
    [self clearBlock];
    self.session = nil;
    return YES;
}

// 暂停下载
- (BOOL)pauseDownLoadTask {
    if (!self.downloadTask) {
        return NO;
    }
    // 产生断点数据
    __weak typeof(self) wSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        wSelf.resumData = resumeData;
        wSelf.downloadTask = nil;
    }];
    return YES;
}

// 恢复下载
- (BOOL)resumeDownLoadTask {
    if (self.downloadTask != nil || self.resumData.length == 0) {
        return NO;
    }
    self.downloadTask = [self.session downloadTaskWithResumeData:self.resumData];
    [self.downloadTask resume];
    self.resumData = nil;
    return YES;
}

/** 监听下载进度 */
/**
 *  监听下载进度
 *
 *  @param session                   会话描述
 *  @param downloadTask              任务描述
 *  @param bytesWritten              本次写入沙盒的大小
 *  @param totalBytesWritten         累计写入沙盒的文件大小
 *  @param totalBytesExpectedToWrite 期望写入的进度(文件总大小)
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (_progressBlock) {
        CGFloat progress = (CGFloat)totalBytesWritten / totalBytesExpectedToWrite;
        _progressBlock(progress);
    }
}

// 下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [caches stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr moveItemAtPath:location.path toPath:file error:nil];
    if (_completionBlock) {
        _completionBlock(file,nil);
    }
    [self cancelDownLoadTask];
}

// 出错监听
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (self.downloadTask == nil && self.resumData.length > 0) {    // 暂停下载
        return;
    } else if(self.downloadTask == nil && self.resumData.length == 0) { // 取消下载
        return;
    }
    // 出错
    if (_completionBlock) {
        _completionBlock(nil,error);
    }
   [self cancelDownLoadTask];
    
}

// 收到身份认证
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        /*
         NSURLSessionAuthChallengeDisposition:  枚举,处理方式
         NSURLSessionAuthChallengeUseCredential = 0,					使用指定的凭据,这可能是nil
         NSURLSessionAuthChallengePerformDefaultHandling = 1, 			默认处理挑战——如果没有这个委托实施;凭证参数被忽略
         NSURLSessionAuthChallengeCancelAuthenticationChallenge = 2,        整个请求将被取消,凭证参数被忽略
         NSURLSessionAuthChallengeRejectProtectionSpace = 3,  			拒绝保护空间
         
         */
        completionHandler(NSURLSessionAuthChallengeUseCredential,[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    }
}

- (void)clearBlock {
    if (_progressBlock) {
        _progressBlock = nil;
    }
    if (_completionBlock) {
        _completionBlock = nil;
    }
    
    if (_downloadTask) {
        _downloadTask = nil;
    }
}

- (void)dealloc {
    [self cancelDownLoadTask];
}
@end

