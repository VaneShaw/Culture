//
//  HttpTools.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <Foundation/Foundation.h>
#import "NetWorkTool.h"
NS_ASSUME_NONNULL_BEGIN

@interface HttpTools : NSObject

+ (void)getRequest:(NSString *)URLString parames:(id)parames success:(void (^)(BOOL success,BaseDataModel *response))success failure:(void (^)(NSError *error))failure;
+ (void)postRequest:(NSString *)URLString parames:(id)parames success:(void (^)(BOOL success,BaseDataModel *response))success failure:(void (^)(NSError *error))failure;

+ (void)postRequestUsers:(NSString *)URLString parames:(id)parames success:(void (^)(BOOL success,BaseDataModel *response))success failure:(void (^)(NSError *error))failure;


+ (void)uploadImageWithURL:(NSString *)url images:(NSArray <UIImage *> *)images params:(NSMutableDictionary *)params imageParamsName:(NSString *)imageParamsName success:(void (^)(BaseDataModel *result))success failure:(void (^)(NSError *))failure;

/// multipart/form-data POST：`parameters` 为 nil，业务字段与文件均在 HTTP Body，不拼 URL Query。
/// `fields` 为文本表单项；`fileURL` 可选，字段名默认 `read_audio`
+ (void)postMultipartRequest:(NSString *)URLString
                      fields:(NSDictionary<NSString *, NSString *> *)fields
                     fileURL:(NSURL * _Nullable)fileURL
                 fileFieldName:(NSString * _Nullable)fileFieldName
                     success:(void (^)(BOOL success, BaseDataModel *response))success
                     failure:(void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
