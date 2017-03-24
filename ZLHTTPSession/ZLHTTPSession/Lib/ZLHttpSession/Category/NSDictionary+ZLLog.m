//
//  NSDictionary+ZLLog.m
//  新浪微博
//
//  Created by qq on 8/24/16.
//  Copyright © 2016 lei. All rights reserved.
//

#import "NSDictionary+ZLLog.h"

@implementation NSDictionary (ZLLog)

/**
 *  换行打印字典，并且把unicode代码变成中文
 */
- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *str = [NSMutableString string];
    
    [str appendString:@"{\n"];
    
    // 遍历字典的所有键值对
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [str appendFormat:@"\t%@ = %@,\n", key, obj];
    }];
    
    [str appendString:@"}"];
    
    // 查出最后一个,的范围
    NSRange range = [str rangeOfString:@"," options:NSBackwardsSearch];
    if (range.length != 0) {
        // 删掉最后一个,
        [str deleteCharactersInRange:range];
    }
//    NSLog(@"%@",str);
    return str;
}

/** 把字典打印成属性 */
- (void)pintProperty {
    // 拼接属性字符串代码
    NSMutableString *strM = [NSMutableString string];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//        NSLog(@"key = %@,obj = %@",key, obj);
//        NSLog(@"class = %@",NSStringFromClass([obj class]));
        NSString *type;
        
        if ([obj isKindOfClass:[NSString class]]) {
            type = @"NSString";
        } else if ([obj isKindOfClass:[NSArray class]]){
            type = @"NSArray";
        } else if ([obj isKindOfClass:NSClassFromString(@"__NSCFNumber")]){
            NSString *numberStr = [NSString stringWithFormat:@"%@",obj];
            if ([numberStr containsString:@"."]) {
                type = @"float";
            } else {
                type = @"NSInteger";
            }
            
        } else if ([obj isKindOfClass:[NSDictionary class]]){
            type = @"NSDictionary";
        } else if ([obj isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
           type = @"BOOL";
        }
        
        // 属性字符串
        NSString *str;
        if ([type isEqualToString:@"NSString"]) {
            str = [NSString stringWithFormat:@"@property (nonatomic, copy) %@ *%@;",type,key];
        }
        else if ([type containsString:@"NS"] && ![type isEqualToString:@"NSInteger"]) {
            str = [NSString stringWithFormat:@"@property (nonatomic, strong) %@ *%@;",type,key];
        }
        else {
            str = [NSString stringWithFormat:@"@property (nonatomic, assign) %@ %@;",type,key];
        }
        
        // 每生成属性字符串，就自动换行。
        [strM appendFormat:@"\n%@\n",str];
    }];
    // 把拼接好的字符串打印出来，就好了。
    NSLog(@"%@",strM);
}
@end
