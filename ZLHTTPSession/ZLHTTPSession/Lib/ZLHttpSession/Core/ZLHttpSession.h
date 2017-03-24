//
//  ZLHttpSession.h
//  HttpSessionTest
//
//  Created by 张磊 on 16/6/15.
//  Copyright © 2016年 lei. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CompleteBlock)(id responseObject);
typedef void(^ErrorBlock)(NSError *error);

typedef NS_ENUM(NSUInteger,ZLHttpSessionMaskType) {
    ZLHttpSessionMaskTypeNone = 0,            //0.没有菊花效果
    ZLHttpSessionMaskTypeInteraction = 1,     //1.有菊花效果,并且可以点击屏幕
    ZLHttpSessionMaskTypeUnInteraction = 2    //2.有菊花效果,但是点击屏幕无效
};

typedef NS_ENUM(NSUInteger,ZLHttpSessionUploadImageType) {
    ZLHttpSessionUploadImageTypePNG = 0,     //png格式
    ZLHttpSessionUploadImageTypeJPG = 1,     //jpg格式
};

@interface ZLHttpSession : NSObject
/** 设置域名,如果请求域名不改变，只需设置一次，如果不需要用到请求域名，必需在请求URL前面加上https:// 或 http://开头，请求前会判断有没有加上https:// 或http:// 如果没有，则用设置的域名拼接URL */
+ (void)setHeadURL:(NSString *)url;

/** 设置请求参数的密钥串，如果不改变，只需设置一次， */
+ (void)setRequestEncryptKeyName:(NSString *)key encryptValue:(NSString *)value;

/** 是否显示出错信息的视图提醒，默认显示 */
+ (void)showErrorInfoView:(BOOL)isShow;

/**
 *  GET请求，block返回json序列化以后的数据
 *
 *  @param url           url
 *  @param param         请求参数
 *  @param maskType      遮罩类型
 *  @param completeBlock 完成的操作
 *  @param errorBlock    出错的操作
 */
+ (void)GETRequest:(NSString*)url parameters:(NSDictionary *)param maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;


/**
 *  GET请求，block返回服务器提供的NSData数据
 *
 *  @param url           url
 *  @param param         请求参数
 *  @param maskType      遮罩类型
 *  @param completeBlock 完成的操作
 *  @param errorBlock    出错的操作
 */
+ (void)GETRequestForData:(NSString*)url parameters:(NSDictionary *)param maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;

/**
 *  POST请求，block返回json序列化以后的数据
 *
 *  @param url           url
 *  @param param         请求参数
 *  @param maskType      遮罩类型
 *  @param completeBlock 完成的操作
 *  @param errorBlock    出错的操作
 */
+ (void)POSTRequest:(NSString*)url parameters:(NSDictionary *)param  maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;


/**
 *  POST请求，block返回服务器提供的NSData数据
 *
 *  @param url           url
 *  @param param         请求参数
 *  @param maskType      遮罩类型
 *  @param completeBlock 完成的操作
 *  @param errorBlock    出错的操作
 */
+ (void)POSTRequestForData:(NSString*)url parameters:(NSDictionary *)param  maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;


/**
 *  下载任务
 *  @param url           url
 *  @param maskType      遮罩类型
 *  @param completeBlock 完成以后的操作,block返回下载以后的存储地址
 *  @param errorBlock    出错的操作
 */
+ (void)downloadTask:(NSString *)url maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;

/**
 *  PUT方式上传
 *
 *  @param url           url
 *  @param data          要上传的NSData数据
 *  @param authStr       认证，可以是nil
 *  @param maskType      遮罩类型
 *  @param completeBlock 完成以后的操作
 *  @param errorBlock    出错的操作
 */
+ (void)PUTUpdataURL:(NSString *)url data:(NSData *)data authStr:(NSString *)authStr maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;

/**
 *  POST方式上传
 *
 *  @param filename      要上传的文件名
 *  @param mimeType      文件类型
 *  @param fileData      文件的NSData数据
 *  @param params        参数
 *  @param postURL       url
 *  @param maskType      遮罩类型
 *  @param completeBlock 成功的block
 *  @param errorBlock    出错的block
 */
+ (void)POSTUploadFileName:(NSString *)filename serverFileName:(NSString *)serverFileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData params:(NSDictionary *)params url:(NSString *)postURL maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;

/**
 *  POST方式上传多张图片
 *
 *  @param images             图片数组
 *  @param serverFileName   服务器上要求的名字
 *  @param imageType        要生成的图片类型
 *  @param params           参数
 *  @param postURL          url
 *  @param maskType         遮罩类型
 *  @param completeBlock    成功的block
 *  @param errorBlock       出错的block
 */
+ (void)POSTUploadImages:(NSArray<UIImage *> *)images imageType:(ZLHttpSessionUploadImageType)imageType serverFileName:(NSString *)serverFileName params:(NSDictionary *)params url:(NSString *)postURL maskType:(ZLHttpSessionMaskType)maskType comleteBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;

/**
 * 默认接受任何请求认证,可以利用category重写这个方法(实例：ZLHttpSession+AuthDelegate.m里面有),或者自定义子类
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler;
@end
