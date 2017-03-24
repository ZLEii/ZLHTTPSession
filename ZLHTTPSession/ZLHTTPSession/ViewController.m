//
//  ViewController.m
//  ZLHTTPSession
//
//  Created by apple on 2017/3/24.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ViewController.h"
#import "HttpSession.h"

@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSString *url = @"http://www.baidu.com";

    // 获取百度首页html代码
    [HttpSession GETRequestForData:url parameters:nil maskType:1 comleteBlock:^(id responseObject) {
        NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"response:%@",result);
    } errorBlock:nil];
}


@end
