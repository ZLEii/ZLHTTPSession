//
//  ZLHTTPSessionTests.m
//  ZLHTTPSessionTests
//
//  Created by apple on 2017/3/24.
//  Copyright © 2017年 apple. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HttpSession.h"

// 添加这一句就可以异步执行了
#define WAIT do {\
[self expectationForNotification:@"RSBaseTest" object:nil handler:nil];\
[self waitForExpectationsWithTimeout:30 handler:nil];\
} while (0);

#define NOTIFY \
[[NSNotificationCenter defaultCenter]postNotificationName:@"RSBaseTest" object:nil];

@interface ZLHTTPSessionTests : XCTestCase

@end

@implementation ZLHTTPSessionTests

// 测试开始执行
- (void)setUp {
    [super setUp];
    NSLog(@"测试开始");
}

// 测试结束执行
- (void)tearDown {
    [super tearDown];
    NSLog(@"测试结束");
}

- (void)testExample {
}

// 必须test开头
- (void)testGETRequestForData {
    NSLog(@"这是单元测试");
    NSString *url = @"http://www.baidu.com";
    
    // 获取百度首页html代码
    [HttpSession GETRequestForData:url parameters:nil maskType:1 comleteBlock:^(id responseObject) {
        NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"response:%@",result);
        XCTAssertNotNil(responseObject, @"返回出错");
        NOTIFY
    } errorBlock:^(NSError *error) {
        NSLog(@"error:%@",error);
        XCTAssertNil(error, @"请求出错");
        NOTIFY //继续执行
    }];
    WAIT
}

// 性能测试
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    NSLog(@"这是单元测试开始");
    NSString *url = @"http://www.baidu.com";
    [self measureBlock:^{
        [HttpSession GETRequestForData:url parameters:nil maskType:1 comleteBlock:^(id responseObject) {
             NSLog(@"这是单元测试结束");
            NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSLog(@"response:%@",result);
            XCTAssertNotNil(responseObject, @"返回出错");
            NOTIFY
        } errorBlock:^(NSError *error) {
            NSLog(@"error:%@",error);
            XCTAssertNil(error, @"请求出错");
            NOTIFY //继续执行
        }];
        WAIT
    }];
}

@end
