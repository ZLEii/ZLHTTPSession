//
//  ZLHttpSession+ZLHttpSession_SSLAuth.h
//  api_demo1
//
//  Created by qq on 2017/3/14.
//  Copyright © 2017年 lei. All rights reserved.
//

#import "ZLHttpSession.h"

// 客户端认证服务器证书
@interface ZLHttpSession (CredentialAuth)
-(void)authServerCerData:(NSData *)cerData space:(NSURLProtectionSpace *)space success:(void(^)())success failure:(void(^)(NSString *errorMsg))failure;

// 服务器认证客户端证书
-(void)authClientCerData:(NSData *)cerData cerPass:(NSString *)pass space:(NSURLProtectionSpace *)space success:(void(^)(NSURLCredential *credential))success failure:(void(^)(NSString *errorMsg))failure;

@end
