//
//  NSArray+ZLLog.h
//  新浪微博
//
//  Created by qq on 8/24/16.
//  Copyright © 2016 lei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ZLLog)

/**
 格式化输出数组
*/
- (NSString *)descriptionWithLocale:(id)locale;
@end
