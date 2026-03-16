//
//  NetWorkTool.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "AFHTTPSessionManager.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPSessionManager.h>

NS_ASSUME_NONNULL_BEGIN
@class BaseDataModel;

@interface NetWorkTool : AFHTTPSessionManager
+ (instancetype)sharedToolGet;
+ (instancetype)sharedToolPostUsers;
+ (instancetype)sharedToolPostAuthorization;

- (void)requestGET:(NSString *)URLString parames:(id)parames success:(void (^)(id responseObj))success failure:(void (^)(NSError *error))failure;

- (void)requestPOST:(NSString *)URLString parames:(id)parames success:(void (^)(NSURLSessionDataTask * _Nonnull task,id responseObj))success failure:(void (^)(NSError *error))failure;

-(void)uploadImageWithURL:(NSString *)url image:(UIImage *)image params:(NSDictionary *)params success:(void (^)(BaseDataModel *result))success failure:(void (^)(NSError *error))failure;

- (void)uploadAudioWithURL:(NSString *)url
                audioData:(NSData *)audioData
                   params:(NSDictionary *)params
                  success:(void (^)(BaseDataModel *result))success
                   failure:(void (^)(NSError *))failure;
@end

NS_ASSUME_NONNULL_END


//------------下面注释 无用

/*
+ (instancetype)sharedToolPostAuthorizationTemp{
    static dispatch_once_t onceToken;
     static NetWorkTool *instance;

    instance = [NetWorkTool manager];
    instance.requestSerializer = [AFJSONRequestSerializer serializer];
    instance.responseSerializer = [AFJSONResponseSerializer serializer];

    NSString *authHeader = [KUSER_DEFAULT objectForKey:@"Authorization_key"];
    if(authHeader==nil){// 上传接口token
        authHeader = @"";
    }

    NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:instance.responseSerializer.acceptableContentTypes];
       [acceptableContentTypes addObjectsFromArray:@[@"application/json", @"text/json", @"text/javascript",@"text/html",@"plant/html",@"text/plain",@"text/xml",@"application/javascript"]];
       instance.responseSerializer = [AFJSONResponseSerializer serializer];
    
    if([[UserModel sharedInstance] isLogin]){
        if(authHeader.length > 0){
            [instance.requestSerializer setValue:authHeader forHTTPHeaderField:@"Authorization"];
        }
    }
    instance.responseSerializer.acceptableContentTypes = acceptableContentTypes;
     return instance;
}

+ (void)postRequestTemp:(NSString *)URLString parames:(id)parames success:(void (^)(BOOL success,BaseDataModel *response))success failure:(void (^)(NSError *error))failure {
    NSString *host = [AppConfig sharedConfig].host;
    NSString *strurl = [NSString stringWithFormat:@"%@%@",host,URLString];
    
    // 2. 对字符串做 URL 编码（防止中文、空格、特殊字符）
    NSString *encoded = [strurl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    // 3. 构造 NSURL
    NSURL *url = [NSURL URLWithString:encoded];

    // 4. 校验
    if (!url) {
        NSLog(@"❌ URL 解析失败: %@", encoded);
        return;
    } else {
        NSLog(@"✅ 即将请求 URL: %@", url.absoluteString);
    }
    
    
    [[NetWorkTool sharedToolPostAuthorization] requestPOST:strurl parames:parames success:^(NSURLSessionDataTask * _Nonnull task,id responseObj) {
  //=================================================== === === === === === === ===
  // 4. 获取响应头信息
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
        if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            // 5. 获取所有响应头字段
            NSDictionary *headers = [httpResponse allHeaderFields];
            // 6. 获取特定的 Authorization 头           Authorization
            NSString *authorizationHeader = headers[@"Authorization"];
            if (authorizationHeader) {//从接口新拿的token
                [KUSER_DEFAULT setObject:authorizationHeader forKey:@"Authorization_key"];
            }
        }
        
        BOOL flag = NO;
        BaseDataModel *model = [BaseDataModel mj_objectWithKeyValues:responseObj];
      if (model.code == 401 ) {
          [[LoginManager sharedManager] handleLoginExpired];
          return ;

        }
        if (model.code == 0) {
            flag = YES;
        }
        success(flag,model);
    } failure:^(NSError *error) {
        failure(error);

    }];
}*/
