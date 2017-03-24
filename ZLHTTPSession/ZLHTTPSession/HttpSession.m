//
//  HttpSession.m
//  ZLHTTPSession
//
//  Created by apple on 2017/3/24.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "HttpSession.h"
#import "ZLHttpSession+CredentialAuth.h"

@implementation HttpSession

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    /*
     // 通过所有
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
     
     */
    
    // 保护空间
    NSURLProtectionSpace *space = [challenge protectionSpace];
    NSString *host = space.host;
    NSLog(@"host:%@,",host);
    
    BOOL receivesCredentialSecurely = space.receivesCredentialSecurely;
    NSLog(@"iScreadentialSecurely:%@",@(receivesCredentialSecurely));
    
    // 认证方法
    NSString *authenticationMethod = space.authenticationMethod;
    NSLog(@"authenticationMethod:%@",authenticationMethod);
    
    NSString *protocol = space.protocol;
    NSLog(@"protocol:%@",protocol);
    
    NSInteger port = space.port;
    NSLog(@"port:%@",@(port));
    
    SecTrustRef trus = space.serverTrust;
    NSLog(@"trus:%@",trus);
    
    
    if([host isEqualToString:@"192.168.1.122"] && receivesCredentialSecurely) {
        // 认证方法：客户端认证
        if ([authenticationMethod isEqualToString:@"NSURLAuthenticationMethodClientCertificate"] ) {
            NSString *p12Path = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"p12"];
            NSData * p12Data = [NSData dataWithContentsOfFile:p12Path];
            
            [self authClientCerData:p12Data cerPass:@"123456" space:space success:^(NSURLCredential *credential) {
                completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            } failure:^(NSString *errorMsg) {
                // 验证失败
                NSLog(@"errorMsg = %@",errorMsg);
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
            }];
            
            
            
            //验证服务器证书------------------------------------------
        } else if([authenticationMethod isEqualToString:@"NSURLAuthenticationMethodServerTrust"]) {
            
            NSString *path = [[NSBundle mainBundle] pathForResource:@"server_client.cer" ofType:nil];
            NSData *cerData = [[NSData alloc] initWithContentsOfFile:path];
            [self authServerCerData:cerData space:space success:^{
                // 验证成功
                NSURLCredential *credential = [NSURLCredential credentialForTrust:space.serverTrust];
                completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            } failure:^(NSString *errorMsg) {
                // 验证失败
                NSLog(@"errorMsg = %@",errorMsg);
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
            }];
        } else {
            // 其他服务器连接取消连接
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
        }
    }

}

@end
