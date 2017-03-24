//
//  ZLHttpSession+ZLHttpSession_SSLAuth.m
//  api_demo1
//
//  Created by qq on 2017/3/14.
//  Copyright © 2017年 lei. All rights reserved.
//

#import "ZLHttpSession+CredentialAuth.h"

@implementation ZLHttpSession (CredentialAuth)

// 认证服务器证书
-(void)authServerCerData:(NSData *)cerData space:(NSURLProtectionSpace *)space success:(void(^)())success failure:(void(^)(NSString *errorMsg))failure {
    if(![space.authenticationMethod isEqualToString:@"NSURLAuthenticationMethodServerTrust"]) {
        if (failure) {
            failure([[NSString alloc] initWithFormat:@"服务器认证方法不为'NSURLAuthenticationMethodServerTrust',authenticationMethod='%@'",space.authenticationMethod]);
        }
        
        return;
    }
    SecTrustRef serverTrust = space.serverTrust;
    if(serverTrust == nil) {
        if (failure) {
            failure(@"space.serverTurst == nil");
        }
        
        return;
    }
    
    // 读取证书
    if (cerData == nil) {
        if (failure) {
            failure(@"证书数据为空");
        }
        
        return;
    }
    
    SecCertificateRef cerRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)cerData);
    if(cerRef == nil) {
        if (failure) {
            failure(@"不能读取证书信息,请检查证书名称");
        }
        
        return;
    }
    
    NSArray *caArray = @[(__bridge id)cerRef];
     //将读取的证书设置为服务端帧数的根证书
    OSStatus status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)caArray);
    if(!(status == errSecSuccess)) {
        if (failure) {
            failure([[NSString alloc] initWithFormat:@"设置为服务端帧数的根证书失败,status=%@",@(status)]);
        }
        
        return;
    }
    
    SecTrustResultType result = -1;
    //验证服务器的证书是否可信(有可能通过联网验证证书颁发机构)
    status = SecTrustEvaluate(serverTrust, &result);
    if(!(status == errSecSuccess)) {
        if (failure) {
            failure([[NSString alloc] initWithFormat:@"服务器证书验证失败,status=%@",@(status)]);
        }
        
        return;
    }
    // result返回结果,是否信任
    BOOL allowConnect = ((result == kSecTrustResultUnspecified) || (result == kSecTrustResultProceed));
    if(!allowConnect) {
        if (failure) {
            failure(@"不是信任的连接");
        }
         
        return;
    }
    // 全部通过验证
    if (success) {
        success();
    }
    
    
}

// 服务器认证客户端证书
-(void)authClientCerData:(NSData *)cerData cerPass:(NSString *)pass space:(NSURLProtectionSpace *)space success:(void(^)(NSURLCredential *credential))success failure:(void(^)(NSString *errorMsg))failure {
    if(![space.authenticationMethod isEqualToString:@"NSURLAuthenticationMethodClientCertificate"]) {
        failure([[NSString alloc] initWithFormat:@"服务器认证方法不为'NSURLAuthenticationMethodClientCertificate',authenticationMethod='%@'",space.authenticationMethod]);
        return;
    }

    // 读取证书
    if (cerData == nil) {
        if (failure) {
            failure(@"证书数据为空");
        }
        
        return;
    }
    
    CFDataRef inPKCS12Data = (__bridge CFDataRef)cerData;
    
    SecIdentityRef identity = NULL;
    
    OSStatus status = [self extractIdentity:inPKCS12Data identity:&identity pass:pass];
    if(status != 0 || identity == NULL) {
        if(failure) {
            failure([[NSString alloc] initWithFormat:@"提取身份失败,status=%@",@(status)]);
        }
        return;

    }
    
    SecCertificateRef certificate = NULL;
    SecIdentityCopyCertificate (identity, &certificate);
    const void *certs[] = {certificate};
    CFArrayRef arrayOfCerts = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);
    
    // NSURLCredentialPersistenceForSession:创建URL证书,在会话期间有效
    NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge NSArray*)arrayOfCerts persistence:NSURLCredentialPersistenceForSession];
    if (success) {
        success(credential);
    }
    
    if(certificate) {
        CFRelease(certificate);
    }
    
    if (arrayOfCerts) {
        CFRelease(arrayOfCerts);
        
    }
    return;
}

// 提取身份identity
- (OSStatus)extractIdentity:(CFDataRef)inP12Data identity:(SecIdentityRef*)identity pass:(NSString *)pass {
    
    CFStringRef password = (__bridge CFStringRef)(pass);//证书密码
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus securityError = SecPKCS12Import(inP12Data, options, &items);
    if (securityError == 0)
    {
        CFDictionaryRef ident = CFArrayGetValueAtIndex(items,0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(ident, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
    }
    
    if (options) {
        CFRelease(options);
    }
    
    return securityError;
}



@end
