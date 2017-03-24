//
//  NSDictionary+ZLLog.h
//  新浪微博
//
//  Created by qq on 8/24/16.
//  Copyright © 2016 lei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ZLLog)
/**
 *  换行打印字典，并且把unicode代码变成中文
 */
- (NSString *)descriptionWithLocale:(id)locale;

/** 把字典打印成属性 */
- (void)pintProperty;
@end
