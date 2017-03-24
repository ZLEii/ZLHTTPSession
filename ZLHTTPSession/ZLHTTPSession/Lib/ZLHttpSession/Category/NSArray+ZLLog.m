//
//  NSArray+ZLLog.m
//  新浪微博
//
//  Created by qq on 8/24/16.
//  Copyright © 2016 lei. All rights reserved.
//

#import "NSArray+ZLLog.h"

@implementation NSArray (ZLLog)

/**
 *  打印数组
 */
- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *str = [NSMutableString string];
    
    [str appendString:@"[\n"];
    
    // 遍历数组的所有元素
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [str appendFormat:@"%@,\n", obj];
    }];
    
    [str appendString:@"]"];
    
    // 查出最后一个,的范围
    NSRange range = [str rangeOfString:@"," options:NSBackwardsSearch];
    if (range.length != 0) {
        // 删掉最后一个,
        [str deleteCharactersInRange:range];
    }
//    NSLog(@"%@",str);
    return str;
}
@end
