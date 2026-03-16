//
//  NetWorkTool.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "NetWorkTool.h"
#import "BaseDataModel.h"

@implementation NetWorkTool
/*不带token
+ (instancetype)sharedLoginTool {
    static dispatch_once_t onceToken;
      static NetWorkTool *instance;
      dispatch_once(&onceToken, ^{
          instance = [NetWorkTool manager];
          //instance = [[super alloc]initWithBaseURL:[NSURL URLWithString:HOST]];
          instance.requestSerializer = [AFJSONRequestSerializer serializer];
          instance.responseSerializer = [AFJSONResponseSerializer serializer];
          //instance.responseSerializer = [AFHTTPResponseSerializer serializer];//新加
          NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:instance.responseSerializer.acceptableContentTypes];
          [acceptableContentTypes addObjectsFromArray:@[@"application/json",@"text/json", @"text/javascript",@"text/html",@"plant/html",@"text/plain",@"text/xml",@"application/javascript"]];
          instance.responseSerializer.acceptableContentTypes = acceptableContentTypes;
          
      });
      return instance;
}*/
+ (instancetype)sharedToolGet{//111
    static dispatch_once_t onceToken;
    static NetWorkTool *instance;
   
    //dispatch_once(&onceToken, ^{
      //instance = [[super alloc]initWithBaseURL:[NSURL URLWithString:HOST]];//=HOST=
      instance = [NetWorkTool manager];
      instance.responseSerializer = [AFJSONResponseSerializer serializer];
      AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
      requestSerializer.timeoutInterval = 60;
      instance.requestSerializer = requestSerializer;
      NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:instance.responseSerializer.acceptableContentTypes];
      [acceptableContentTypes addObjectsFromArray:@[@"application/json", @"text/json", @"text/javascript",@"text/html",@"plant/html",@"text/plain",@"text/xml",@"application/javascript"]];
      instance.responseSerializer = [AFJSONResponseSerializer serializer];
      instance.responseSerializer.acceptableContentTypes = acceptableContentTypes;
    
      //[instance.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    return instance;
}
+ (instancetype)sharedToolPostAuthorization{
    static dispatch_once_t onceToken;
     static NetWorkTool *instance;

     //dispatch_once(&onceToken, ^{
    //instance = [[super alloc]initWithBaseURL:[NSURL URLWithString:HOST]];//=HOST=
    //instance.responseSerializer = [AFJSONResponseSerializer serializer];
    //AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    //requestSerializer.timeoutInterval = 60;

    instance = [NetWorkTool manager];
    instance.requestSerializer = [AFJSONRequestSerializer serializer];
    instance.responseSerializer = [AFJSONResponseSerializer serializer];
    //instance.requestSerializer.timeoutInterval = 30.0;
    //401
    NSString *authHeader = [KUSER_DEFAULT objectForKey:@"Authorization_key"];
    if(authHeader==nil){// 上传接口token
        authHeader = @"";
    }

    NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:instance.responseSerializer.acceptableContentTypes];
    [acceptableContentTypes addObjectsFromArray:@[@"application/json", @"text/json", @"text/javascript",@"text/html",@"plant/html",@"text/plain",@"text/xml",@"application/javascript"]];
    instance.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // 获取版本号（1.0.6）
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    //上传头部
    // 获取内部版本号（Build number）
    //NSString *buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    //NSLog(@"Build Version: %@", buildVersion);
    
    [instance.requestSerializer setValue:@[@"cn",@"overseas"][IS_OVERSEAS_VERSION] forHTTPHeaderField:@"region"];
    [instance.requestSerializer setValue:@"2" forHTTPHeaderField:@"platform"];
    [instance.requestSerializer setValue:appVersion forHTTPHeaderField:@"App-Version"];
    //NSLog(@"appversion--------[%@]-----------",appVersion);
    if([[UserModel sharedInstance] isLogin]){
        if(authHeader.length > 0){
            [instance.requestSerializer setValue:authHeader forHTTPHeaderField:@"Authorization"];
        }
    }
    instance.responseSerializer.acceptableContentTypes = acceptableContentTypes;
    //[instance.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    return instance;
}
+ (instancetype)sharedToolPostUsers{
    static dispatch_once_t onceToken;
    static NetWorkTool *instance;
    instance = [NetWorkTool manager];
    instance.requestSerializer = [AFJSONRequestSerializer serializer];
    instance.responseSerializer = [AFJSONResponseSerializer serializer];

    NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:instance.responseSerializer.acceptableContentTypes];
       [acceptableContentTypes addObjectsFromArray:@[@"application/json", @"text/json", @"text/javascript",@"text/html",@"plant/html",@"text/plain",@"text/xml",@"application/javascript"]];
    instance.responseSerializer = [AFJSONResponseSerializer serializer];
    instance.responseSerializer.acceptableContentTypes = acceptableContentTypes;
    return instance;
}
#pragma mark - 自定义GET
- (void)requestGET:(NSString *)urlString parames:(id)parames success:(void (^)(id responseObj))success failure:(void (^)(NSError *error))failure{
    [self GET:urlString parameters:parames progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //NSLog(@"error------[%@]---------ing=[%@]---------111--------",error,urlString);
        failure(error);
    }];
}
#pragma mark - 自定义POST
- (void)requestPOST:(NSString *)urlString parames:(id)parames success:(void (^)(NSURLSessionDataTask * _Nonnull task,id responseObj))success failure:(void (^)(NSError *error))failure{
    
    [self POST:urlString parameters:parames progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    success(task,responseObject);
        //NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        //NSLog(@"原始响应: [%@]============11============", responseString);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       //NSLog(@"响应文本: %@]---------------221133", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
        failure(error);
    }];
}
- (NSString *)hexPreview:(NSData *)data length:(NSUInteger)maxLength {
    if (!data || data.length == 0) return @"[空数据]";
    const unsigned char *bytes = data.bytes;
    NSUInteger length = MIN(data.length, maxLength);
    NSMutableString *hex = [NSMutableString stringWithCapacity:length * 3];
    for (NSUInteger i = 0; i < length; i++) {
        [hex appendFormat:@"%02X ", bytes[i]];
        if ((i + 1) % 16 == 0) [hex appendString:@"\n"];
    }
    if (data.length > maxLength) {
        [hex appendFormat:@"\n... 已截断，总长度 %lu 字节", (unsigned long)data.length];
    }
    return hex;
}
- (void)uploadImageWithURL:(NSString *)url image:(UIImage *)image params:(NSDictionary *)params success:(void (^)(BaseDataModel *result))success failure:(void (^)(NSError *))failure{
    [self POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *imageData =UIImageJPEGRepresentation(image,0.1);
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat =@"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.jpg", str];
        [MBProgressHUD showMessage:@"正在上传"];
        //上传的参数(上传图片，以文件流的格式)
        [formData appendPartWithFileData:imageData name:@"file" fileName:fileName  mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //1[MBProgressHUD hideHUD];
            if (success) {
                success([BaseDataModel mj_objectWithKeyValues:responseObject]);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        [MBProgressHUD hideHUD];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //1[MBProgressHUD hideHUD];
            if (failure) {
                failure(error);
            }
        });
    }];
}
-(void)uploadImageWithURL:(NSString *)url images:(NSArray <UIImage *> *)images params:(NSDictionary *)params success:(void (^)(BaseDataModel *result))success failure:(void (^)(NSError *))failure{
    [self POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
         [MBProgressHUD showMessage:@"正在上传"];
        for (int i = 0; i < images.count; i ++) {
            NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
            formatter.dateFormat=@"yyyyMMddHHmmss";
            NSString *str=[formatter stringFromDate:[NSDate date]];
            NSString *fileName=[NSString stringWithFormat:@"%@.jpg",str];
            NSData *imageData = UIImageJPEGRepresentation(images[i], 0.1);
            [formData appendPartWithFileData:imageData name:[NSString stringWithFormat:@"file%d",i+1] fileName:fileName mimeType:@"image/jpeg"];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //1[MBProgressHUD hideHUD];
            if (success) {
                success([BaseDataModel mj_objectWithKeyValues:responseObject]);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //        [MBProgressHUD hideHUD];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //1[MBProgressHUD hideHUD];
            if (failure) {
                failure(error);
            }
        });
    }];
}

- (void)uploadAudioWithURL:(NSString *)url
                audioData:(NSData *)audioData
                   params:(NSDictionary *)params
                  success:(void (^)(BaseDataModel *result))success
                  failure:(void (^)(NSError *))failure {
    
    [self POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        // 创建唯一文件名（使用时间戳）
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *fileName = [NSString stringWithFormat:@"%@.m4a", [formatter stringFromDate:[NSDate date]]];
        
        // 显示上传提示
        [MBProgressHUD showMessage:@"正在上传录音文件"];
        
        // 添加音频数据到表单
        [formData appendPartWithFileData:audioData
                                    name:@"file"
                                fileName:fileName
                                mimeType:@"audio/wav"];
        
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 隐藏上传提示
            [MBProgressHUD hideHUD];
            if (success) {
                success([BaseDataModel mj_objectWithKeyValues:responseObject]);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 隐藏上传提示
            [MBProgressHUD hideHUD];
            if (failure) {
                failure(error);
            }
        });
    }];
}
@end

