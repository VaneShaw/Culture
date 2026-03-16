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

@end

NS_ASSUME_NONNULL_END
