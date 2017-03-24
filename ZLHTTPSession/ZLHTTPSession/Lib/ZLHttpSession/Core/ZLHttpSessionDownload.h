//
//  ZLHttpSessionDownload.h
//  NameCard
//
//  Created by 张磊 on 16/6/17.
//  Copyright © 2016年 zhanglei. All rights reserved.
//

/**
 * 大文件下载，可监听进度
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^ZLHttpProgressBlock)(CGFloat progress);
typedef void (^ZLHttpCompletionBlock)(NSString *filePath, NSError *err);

@interface ZLHttpSessionDownload : NSObject


// 创建一个下载任务
- (void)downLoadFromURL:(NSString *)url progressBlock:(ZLHttpProgressBlock)progressBlock completion:(ZLHttpCompletionBlock)completionBlock;

// 取消下载
- (BOOL)cancelDownLoadTask;
// 恢复下载
- (BOOL)resumeDownLoadTask;
// 暂停下载
- (BOOL)pauseDownLoadTask;
@end
