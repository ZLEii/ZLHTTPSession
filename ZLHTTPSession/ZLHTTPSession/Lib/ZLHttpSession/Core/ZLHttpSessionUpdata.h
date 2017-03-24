//
//  ZLHttpSessionUpdata.h
//  test
//
//  Created by 张磊 on 16/6/17.
//  Copyright © 2016年 lei. All rights reserved.
//
/**
 * 大文件上传，可监听进度
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^ZLHttpProgressBlock)(CGFloat progress);
typedef void (^ZLHttpCompletionBlock)(NSString *filePath, NSError *err);

@interface ZLHttpSessionUpdata : NSObject

@end
