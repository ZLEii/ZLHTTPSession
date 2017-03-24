//
//  ZLHttpSession.m
//  HttpSessionTest
//
//  Created by 张磊 on 16/6/15.
//  Copyright © 2016年 lei. All rights reserved.
//

// 最后更新:2016.9.3 17时

#import "ZLHttpSession.h"
#import "ShowErrorView.h"
#import "RealReachability.h"
#import "NSArray+ZLLog.h"
#import "NSDictionary+ZLLog.h"

#define TimeOut 30.0
#define ZLFileBoundary @"fileBoundary"
#define ZLNewLien @"\r\n"
#define ZLEncode(str) [str dataUsingEncoding:NSUTF8StringEncoding]

#ifdef DEBUG
#define DLog(...) NSLog(__VA_ARGS__)
#else
#define DLog(...)
#endif

typedef NS_ENUM(NSUInteger,ZLHttpMethodType) {
    ZLHttpMethodTypePOST = 0,
    ZLHttpMethodTypeGET = 1
};

typedef NS_ENUM(NSUInteger,ZLHttpResponseType) {
    ZLHttpResponseTypeJSONSerialization = 0,
    ZLHttpResponseTypeOriginalData = 1
};


@interface ZLHttpSession() <NSURLSessionTaskDelegate>
@property (nonatomic,strong) NSURLSession *session;
@property (nonatomic,strong) ShowErrorView *showErrorView;
@property (nonatomic,copy) NSString *requestHeadUrl;
@property (nonatomic,strong) UIActivityIndicatorView *activityView;
@property (nonatomic,assign) int maskCount;
@property (nonatomic,strong) UIView *hubView;
@property (nonatomic, copy) NSString *requestEncryptKey;
@property (nonatomic, copy) NSString *requestEncryptValue;
@property (nonatomic,assign) BOOL isShowErrorinfo;
@end

@implementation ZLHttpSession

static ZLHttpSession *sharedSession;
+ (ZLHttpSession *)sharedSession {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedSession = [[self alloc] init];
        [GLobalRealReachability startNotifier];
    });
    return sharedSession;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSession = [[super allocWithZone:zone] init];
    });
    return sharedSession;
}
// 重写父类方法
- (id)copyWithZone:(NSZone *)zone {
    return sharedSession;
}


+ (void)setRequestEncryptKeyName:(NSString *)key encryptValue:(NSString *)value {
    [ZLHttpSession sharedSession].requestEncryptKey = key;
    [ZLHttpSession sharedSession].requestEncryptValue = value;
}

- (instancetype)init {
    if (self = [super init]) {
        //配置
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];;
        _showErrorView = [ShowErrorView showerrorView];
        _showErrorView.userInteractionEnabled = YES;
        _activityView = [[UIActivityIndicatorView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _activityView.color = [UIColor blackColor];
        _isShowErrorinfo = YES;
    }
    return self;
}


// 设置域名
+ (void)setHeadURL:(NSString *)url {
    [self sharedSession].requestHeadUrl = url;
}

// 是否显示出错信息的视图，默认显示
+ (void)showErrorInfoView:(BOOL)isShow {
    [ZLHttpSession sharedSession].isShowErrorinfo = isShow;
}

// 判断是否以 "http://" 开头, 如果没有,加上域名
- (NSString *)jointPrefixURLStr:(NSString *)originalUrlStr {
    if ([originalUrlStr hasPrefix:@"http://"] || [originalUrlStr hasPrefix:@"https://"]) {
        return originalUrlStr;
    }
    if (_requestHeadUrl.length > 0) {
        return [_requestHeadUrl stringByAppendingString:originalUrlStr];
    }
    return originalUrlStr;
}

/************************* 下载操作 ******************************/
#pragma mark 下载操作
// 下载完成以后 block 返回文件地址
+ (void)downloadTask:(NSString *)url maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    ZLHttpSession *httpSession = [self sharedSession];
    [httpSession downloadTask:url maskType:maskType comleteBlock:completeBlock errorBlock:errorBlock];
    
}

// 下载完成以后 block 返回文件地址
- (void)downloadTask:(NSString *)url maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    if (![self connectedToNetworkWithErrorBlock:errorBlock]) {
        return;
    }
    NSURL *requestURL  = [NSURL URLWithString:[ZLHttpSession urlConversionFromOriginalURL:url]];
    __weak typeof(self) wSelf = self;
    NSURLSessionDownloadTask *task = [_session downloadTaskWithURL:requestURL completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [wSelf maskStopAnimation:maskType];
        if (error) {
            [wSelf showErrorWithStatus:@"下载出错"];
            if (errorBlock) {
                errorBlock(error);
            }
        } else {
            //下载完成以后会自动删除,所以所以要把下载完成以后的文件复制或剪切到别的文件夹
            NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            // response.suggestedFilename: 建议的文件名,一般和服务器端的文件名一致
            NSString *file = [caches stringByAppendingPathComponent:response.suggestedFilename];
            // 将临时文件剪切或者复制到Caches文件夹
            NSFileManager *mgr = [NSFileManager defaultManager];
            // AtPath:剪切前的文件夹路径, ToPath:剪切后的文件夹路径
            [mgr moveItemAtPath:location.path toPath:file error:nil];
            if (completeBlock) {
                completeBlock(file);
            }
        }
    }];
    [wSelf maskAnimation:maskType];
    [task resume];
}

/************************* 上传操作 ******************************/
#pragma mark PUT上传操作
+ (void)PUTUpdataURL:(NSString *)url data:(NSData *)data authStr:(NSString *)authStr maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    ZLHttpSession *httpSession = [self sharedSession];
    [httpSession PUTUpdataURL:url data:data authStr:authStr maskType:maskType comleteBlock:completeBlock errorBlock:errorBlock];
}


- (void)PUTUpdataURL:(NSString *)url data:(NSData *)data authStr:(NSString *)authStr maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    if (![self connectedToNetworkWithErrorBlock:errorBlock]) {
        return;
    }
    NSURL *requestURL  = [NSURL URLWithString:[ZLHttpSession urlConversionFromOriginalURL:url]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TimeOut];
    request.HTTPMethod = @"PUT";
    // 设置用户授权
    if (authStr) {
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *base64Str = [authData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        NSString *auth = [NSString stringWithFormat:@"BASIC %@", base64Str];
        [request setValue:auth forHTTPHeaderField:@"Authorization"];
    }
    
    __weak typeof(self) wSelf = self;
    NSURLSessionUploadTask *task = [_session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [wSelf maskStopAnimation:maskType];
        [wSelf requestFinish:data response:response error:error responseType:ZLHttpResponseTypeJSONSerialization comleteBlock:completeBlock errorBlock:errorBlock];
    }];
    [wSelf maskAnimation:maskType];
    [task resume];
}

// POST上传
/**
 * filename:文件名
 * mimeType:文件类型
 * fileData:文件二进制数据
 * parms:非文件类型参数
 * postUrl:上传地址
 **/
#pragma mark POST上传操作
+ (void)POSTUploadFileName:(NSString *)filename serverFileName:(NSString *)serverFileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData params:(NSDictionary *)params url:(NSString *)postURL maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    ZLHttpSession *httpSession = [self sharedSession];
    NSString *requestUrl = [httpSession jointPrefixURLStr:postURL];
    [httpSession POSTUploadFileName:filename serverFileName:serverFileName mimeType:mimeType fileData:fileData params:params url:requestUrl maskType:maskType comleteBlock:completeBlock errorBlock:errorBlock];
    
}
- (void)POSTUploadFileName:(NSString *)filename serverFileName:(NSString *)serverFileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData params:(NSDictionary *)params url:(NSString *)postURL maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock
{
    if (![self connectedToNetworkWithErrorBlock:errorBlock]) {
        return;
    };
    // 1.请求路径
    NSURL *url = [NSURL URLWithString:[ZLHttpSession urlConversionFromOriginalURL:postURL]];
    
    // 2.创建一个POST请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TimeOut];
    request.HTTPMethod = @"POST";
    
    // 3.设置请求体
    NSMutableData *body = [NSMutableData data];
    
    // 3.1.文件参数
    [body appendData:ZLEncode(@"--")];
    [body appendData:ZLEncode(ZLFileBoundary)];
    [body appendData:ZLEncode(ZLNewLien)];
    
    ////name是服务器给的文件地址参数,filename是文件名
    NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"",serverFileName, filename];
    [body appendData:ZLEncode(disposition)];
    [body appendData:ZLEncode(ZLNewLien)];
    
    NSString *type = [NSString stringWithFormat:@"Content-Type: %@", mimeType];
    [body appendData:ZLEncode(type)];
    [body appendData:ZLEncode(ZLNewLien)];
    
    [body appendData:ZLEncode(ZLNewLien)];
    [body appendData:fileData];
    [body appendData:ZLEncode(ZLNewLien)];
    
    // 3.2.非文件参数
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [body appendData:ZLEncode(@"--")];
        [body appendData:ZLEncode(ZLFileBoundary)];
        [body appendData:ZLEncode(ZLNewLien)];
        
        NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", key];
        [body appendData:ZLEncode(disposition)];
        [body appendData:ZLEncode(ZLNewLien)];
        
        [body appendData:ZLEncode(ZLNewLien)];
        [body appendData:ZLEncode([obj description])];
        [body appendData:ZLEncode(ZLNewLien)];
    }];
    // 3.3.结束标记
    [body appendData:ZLEncode(@"--")];
    [body appendData:ZLEncode(ZLFileBoundary)];
    [body appendData:ZLEncode(@"--")];
    [body appendData:ZLEncode(ZLNewLien)];
    request.HTTPBody = body;
    // 4.设置请求头(告诉服务器这次传给你的是文件数据，告诉服务器现在发送的是一个文件上传请求)
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", ZLFileBoundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    // 5.发送请求
    __weak typeof(self) wSelf = self;
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [wSelf maskStopAnimation:maskType];
        [wSelf requestFinish:data response:response error:error responseType:ZLHttpResponseTypeJSONSerialization comleteBlock:completeBlock errorBlock:errorBlock];
    }];
    [wSelf maskAnimation:maskType];
    [task resume];
    
}

/************************* 上传多张图片 ******************************/
+ (void)POSTUploadImages:(NSArray<UIImage *> *)images imageType:(ZLHttpSessionUploadImageType)imageType serverFileName:(NSString *)serverFileName params:(NSDictionary *)params url:(NSString *)postURL maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    ZLHttpSession *httpSession = [self sharedSession];
    NSString *requestUrl = [httpSession jointPrefixURLStr:postURL];
    
    [httpSession POSTUploadImages:images imageType:imageType serverFileName:serverFileName params:params url:requestUrl maskType:maskType comleteBlock:completeBlock errorBlock:errorBlock];
}

- (void)POSTUploadImages:(NSArray<UIImage *> *)images imageType:(ZLHttpSessionUploadImageType)imageType serverFileName:(NSString *)serverFileName params:(NSDictionary *)params url:(NSString *)postURL maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock
{
    if (![self connectedToNetworkWithErrorBlock:errorBlock]) {
        return;
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1.请求路径
        NSURL *url = [NSURL URLWithString:[ZLHttpSession urlConversionFromOriginalURL:postURL]];
        
        // 2.创建一个POST请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TimeOut];
        request.HTTPMethod = @"POST";
        
        // 3.设置请求体
        NSMutableData *body = [NSMutableData data];
        
        // 3.1.文件参数
        
        // 是否是jpg格式
        BOOL isJPG = (imageType == ZLHttpSessionUploadImageTypeJPG ? YES : NO);
        NSString *fileSuffix = isJPG ? @".jpg" : @".png";
        NSString *mimeType = isJPG ? @"image/jpeg" : @"image/png";
        
        // 遍历数组，添加多张图片
        for (int i = 0; i < images.count; i++) {
            UIImage *image = images[i];
            NSData *fileData = isJPG ? UIImageJPEGRepresentation(image, 0.1) : UIImagePNGRepresentation(image);
            // 产生文件名:时间戳+1百万以内的随机数
            int rand = arc4random_uniform(1000000);
            NSString *time = [[NSString stringWithFormat:@"%@",@([[NSDate date] timeIntervalSince1970])] stringByReplacingOccurrencesOfString:@"." withString:@""];
            NSString *filename = [NSString stringWithFormat:@"%@%@%@",time,@(rand),fileSuffix];
            DLog(@"filename = %@",filename);
            
            [body appendData:ZLEncode(@"--")];
            [body appendData:ZLEncode(ZLFileBoundary)];
            [body appendData:ZLEncode(ZLNewLien)];
            //添加图片参数,name是服务器给的文件地址参数,filename是文件名
            NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"",serverFileName, filename];
            [body appendData:ZLEncode(disposition)];
            [body appendData:ZLEncode(ZLNewLien)];
            
            NSString *type = [NSString stringWithFormat:@"Content-Type: %@", mimeType];
            [body appendData:ZLEncode(type)];
            [body appendData:ZLEncode(ZLNewLien)];
            // 添加文件data
            [body appendData:ZLEncode(ZLNewLien)];
            [body appendData:fileData];
            [body appendData:ZLEncode(ZLNewLien)];
        }
        
        //        [body appendData:ZLEncode(@"--")];
        //        [body appendData:ZLEncode(ZLFileBoundary)];
        //        [body appendData:ZLEncode(@"--")];
        //        [body appendData:ZLEncode(ZLNewLien)];
        
        // 3.2.非文件参数
        [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [body appendData:ZLEncode(@"--")];
            [body appendData:ZLEncode(ZLFileBoundary)];
            [body appendData:ZLEncode(ZLNewLien)];
            
            NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", key];
            [body appendData:ZLEncode(disposition)];
            [body appendData:ZLEncode(ZLNewLien)];
            
            [body appendData:ZLEncode(ZLNewLien)];
            [body appendData:ZLEncode([obj description])];
            [body appendData:ZLEncode(ZLNewLien)];
        }];
        // 3.3.结束标记
        [body appendData:ZLEncode(@"--")];
        [body appendData:ZLEncode(ZLFileBoundary)];
        [body appendData:ZLEncode(@"--")];
        [body appendData:ZLEncode(ZLNewLien)];
        request.HTTPBody = body;
        // 4.设置请求头(告诉服务器这次传给你的是文件数据，告诉服务器现在发送的是一个文件上传请求)
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", ZLFileBoundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        // 5.发送请求
        __weak typeof(self) wSelf = self;
        NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            [wSelf maskStopAnimation:maskType];
            [wSelf requestFinish:data response:response error:error responseType:ZLHttpResponseTypeJSONSerialization comleteBlock:completeBlock errorBlock:errorBlock];
        }];
        [wSelf maskAnimation:maskType];
        [task resume];
    });
}

/************************* 请求短数据 ******************************/
/************************* Get请求 ******************************/
#pragma mark GET请求
+ (void)GETRequest:(NSString*)url parameters:(NSDictionary *)param maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    ZLHttpSession *httpSession = [self sharedSession];
    NSString *requestUrl = [httpSession jointPrefixURLStr:url];
    [httpSession connectionRequest:requestUrl parameters:param responseType:ZLHttpResponseTypeJSONSerialization maskType:maskType comleteBlock:completeBlock errorBlock:errorBlock httpmethod:ZLHttpMethodTypeGET];
}

/**
 *  Get请求返回NSData数据
 */
+ (void)GETRequestForData:(NSString*)url parameters:(NSDictionary *)param maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    ZLHttpSession *httpSession = [self sharedSession];
    NSString *requestUrl = [httpSession jointPrefixURLStr:url];
    [httpSession connectionRequest:requestUrl parameters:param responseType:ZLHttpResponseTypeOriginalData maskType:maskType comleteBlock:completeBlock errorBlock:errorBlock httpmethod:ZLHttpMethodTypeGET];
}


/************************* Post请求 ******************************/
#pragma mark Post请求
+ (void)POSTRequest:(NSString*)url parameters:(NSDictionary *)param  maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    ZLHttpSession *httpSession = [self sharedSession];
    NSString *requestUrl = [httpSession jointPrefixURLStr:url];
    [httpSession connectionRequest:requestUrl parameters:param responseType:ZLHttpResponseTypeJSONSerialization maskType:maskType comleteBlock:completeBlock errorBlock:errorBlock httpmethod:ZLHttpMethodTypePOST];
}

/**
 *  post请求返回NSData数据
 */
+ (void)POSTRequestForData:(NSString*)url parameters:(NSDictionary *)param  maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    ZLHttpSession *httpSession = [self sharedSession];
    NSString *requestUrl = [httpSession jointPrefixURLStr:url];
    [httpSession connectionRequest:requestUrl parameters:param responseType:ZLHttpResponseTypeOriginalData maskType:maskType comleteBlock:completeBlock errorBlock:errorBlock httpmethod:ZLHttpMethodTypePOST];
}


/************************* 开始请求 ******************************/
- (void)connectionRequest:(NSString*)url parameters:(NSDictionary *)param responseType:(ZLHttpResponseType)responseType maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock httpmethod:(ZLHttpMethodType)type {
    if (![self connectedToNetworkWithErrorBlock:errorBlock]) {
        return;
    }
    NSMutableURLRequest *request = [self setupRequest:type requestUrl:url param:param];
    __weak typeof(self) wSelf = self;
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self maskStopAnimation:maskType];
        [wSelf requestFinish:data response:response error:error responseType:responseType comleteBlock:completeBlock errorBlock:errorBlock];
    }];
    [self maskAnimation:maskType];
    [task resume];
}

// 请求完成
- (void)requestFinish:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error responseType:(ZLHttpResponseType)responseType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock {
    
    NSError *err = [self isRequestErr:error response:response];
    if (err) {  // 请求出错
        if (errorBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(err);
            });
        }
    } else {
        if (responseType == ZLHttpResponseTypeOriginalData) {   // 返回NSData数据
            if (completeBlock) {
                completeBlock(data);
            }
        } else {    // 返回序列化以后的数据
            id responseObject = [self serializationFromData:data];
            if (!responseObject) {  // 序列化出错
                if (errorBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        errorBlock(error);
                    });
                }
            } else {
                if (completeBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completeBlock(responseObject);
                    });
                }
            }
        }
    }
}

// NSURLResponse *response, NSError *error
- (NSError *)isRequestErr:(NSError *)error response:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
//    DLog(@"响应码:%ld",(long)httpResponse.statusCode);
    //请求出错
    NSError *err = error;
    if (httpResponse.statusCode != 200) {
        if (httpResponse.statusCode < 0) {
            // 未知错误
            [self showErrorWithStatus:@"连接网络失败"];
        } else {
            // 根据相应码获取错误信息
            NSString *msg = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
            [self showErrorWithStatus:[NSString stringWithFormat:@"status:%ld,%@",(long)httpResponse.statusCode,msg]];
        }
        if (!err) {
            // 连接不到服务器，但是又没有错误信息的情况，返回未知错误类型
            [NSError errorWithDomain:@"连接网络失败" code:httpResponse.statusCode userInfo:nil];
        }
        return err;
    }
    return nil;
}

// 序列化NSData
- (id)serializationFromData:(NSData *)data {
    /****************************** 用于测试 **********************************/
    
        NSString *datastr= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        DLog(@"data转String:%@",datastr);
    
    
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error || !object) {
        DLog(@"序列化json错误:error = %@",error);
        [self showErrorWithStatus:@"数据解析失败"];
        return nil;
    }
    
    /****************************** 用于测试 **********************************/
//    DLog(@"object = %@",[object descriptionWithLocale:nil]);
    
    return object;
}

#pragma mark 创建一个NSMutableURLRequest
- (NSMutableURLRequest *)setupRequest:(ZLHttpMethodType)method requestUrl:(NSString *)url  param:(NSDictionary *)param {
    // 如果有中文要转码
    NSString *urlStr = [ZLHttpSession urlConversionFromOriginalURL:url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TimeOut];
    
    NSString *httpMethod = (method == ZLHttpMethodTypePOST) ? @"POST" : @"GET";
    [request setHTTPMethod:httpMethod];
    //如果有参数
    if (param) {
        NSString *strParam = [ZLHttpSession requestParameStr:param];
        if (method == ZLHttpMethodTypePOST) {    // POST请求
            //设置请求体
            NSData *paraData = [strParam dataUsingEncoding:NSUTF8StringEncoding];
            [request setHTTPBody:paraData];
        } else {   // GET请求
            request.URL = [NSURL URLWithString:[ZLHttpSession urlConversionFromOriginalURL:[NSString stringWithFormat:@"%@&%@",urlStr,strParam]]];
        }
    }
    return request;
}

// 添加网络指示器动画
- (void)maskAnimation:(ZLHttpSessionMaskType)maskType {
    if (maskType != ZLHttpSessionMaskTypeNone) {   // 有菊花动画
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
            [[UIApplication sharedApplication].keyWindow addSubview:_activityView];
            _activityView.hidden = NO;
            [_activityView startAnimating];
            _activityView.userInteractionEnabled = (maskType == ZLHttpSessionMaskTypeUnInteraction ? YES : NO);
            _maskCount++;
        });
    }
}

// 移除网络指示器动画
- (void)maskStopAnimation:(ZLHttpSessionMaskType)maskType {
    if (maskType != ZLHttpSessionMaskTypeNone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _maskCount--;
            if (_maskCount <= 0) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
                [_activityView stopAnimating];
                _activityView.hidden = YES;
                [_activityView removeFromSuperview];
            }
        });
    }
}

//把字典参数转成字符串参数
+ (NSString *)requestParameStr:(NSDictionary *)paraDic {
    NSMutableString *paraString = [NSMutableString string];
    NSArray *keys = [paraDic allKeys];
    for (int i = 0; i < keys.count; i++) {
        NSString *key = [keys objectAtIndex:i];
        NSString *value = paraDic[key];
        [paraString appendFormat:@"%@=%@&",key,value];
    }
    // 去掉最后一个&
    NSRange range = [paraString rangeOfString:@"&" options:NSBackwardsSearch];
    if (range.length != 0) {
        [paraString deleteCharactersInRange:range];
    }
    // 设置请求密钥串
    if (([ZLHttpSession sharedSession].requestEncryptKey.length > 0) && ([ZLHttpSession sharedSession].requestEncryptValue.length > 0)) {
        [paraString appendFormat:@"&%@=%@",[ZLHttpSession sharedSession].requestEncryptKey,[ZLHttpSession sharedSession].requestEncryptValue];
    }
    DLog(@"paraStr = %@",paraString);
    return paraString;
}

// 没联网的处理
- (BOOL)connectedToNetworkWithErrorBlock:(ErrorBlock)errorBlock {
    //判断是否联网
    if (![ZLHttpSession connectedToNetwork]) {
        [self showErrorWithStatus:@"网络似乎已断开"];
        if (errorBlock) {
            NSError *err = [NSError errorWithDomain:@"网络似乎已断开" code:0 userInfo:nil];
            errorBlock(err);
        }
        [self showErrorWithStatus:@"网络似乎已断开"];
        return NO;
    }
    return YES;
}

// 如果URL有中文，转换成百分号
+ (NSString *)urlConversionFromOriginalURL:(NSString *)originalURL {
    // iOS9以下
    if ([[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
        return [originalURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    return [originalURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

#pragma mrak 判断是否联网
+ (BOOL)connectedToNetwork
{
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    if ((status ==  RealStatusNotReachable) || (status == RealStatusUnknown)) {
        return NO;
    }
    return YES;
}

#pragma mark 显示错误提示
- (void)showErrorWithStatus:(NSString *)info {
    if (!self.isShowErrorinfo) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        _showErrorView.frame = window.bounds;
        [window addSubview:_showErrorView];
        _showErrorView.infoStr = info;
        [window bringSubviewToFront:_showErrorView];
        [UIView animateWithDuration:0.2 animations:^{
            _showErrorView.alpha = 1;
        } completion:nil];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.2 animations:^{
            _showErrorView.alpha = 0;
        } completion:^(BOOL finished) {
            [_showErrorView removeFromSuperview];
        }];
    });
}


// 默认接受任何请求认证,可以利用category重写这个方法,或者自定义子类
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

/*
#pragma mark NSURLSession Delegate
// 收到身份验证 
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    NSURLProtectionSpace *space = [challenge protectionSpace];
        NSString *host = space.host;
    NSLog(@"host:%@,",host);
    
    BOOL receivesCredentialSecurely = space.receivesCredentialSecurely;
     NSLog(@"iScreadentialSecurely:%@",@(receivesCredentialSecurely));
    
    NSString *authenticationMethod = space.authenticationMethod;
    NSLog(@"authenticationMethod:%@",authenticationMethod);
    
    NSString *protocol = space.protocol;
    NSLog(@"protocol:%@",protocol);
    
    NSInteger port = space.port;
    NSLog(@"port:%@",@(port));
    
    SecTrustRef trus = space.serverTrust;
    NSLog(@"trus:%@",trus);
    
    
    if([host isEqualToString:@"192.168.1.122"] && receivesCredentialSecurely) {
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
            // 其他服务器连接
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
        }
    }
}

*/




@end
