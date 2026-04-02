//
//  HttpTools.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "HttpTools.h"
#import "BaseDataModel.h"
#import "TokenManager.h"

#import "LoginViewController.h"
@implementation HttpTools

+ (void)getRequest:(NSString *)URLString parames:(id)parames success:(void (^)(BOOL success,BaseDataModel *response))success failure:(void (^)(NSError *error))failure {
    //[NSString stringWithFormat:@"%@%@",HOST,URLString]
    //NSString *host = [AppConfig sharedConfig].main_host;
    NSString *host = HOST;
    [[NetWorkTool sharedToolGet] requestGET:[NSString stringWithFormat:@"%@%@",host,URLString] parames:parames success:^(id responseObj) {
        BOOL flag = NO;
        BaseDataModel *model = [BaseDataModel mj_objectWithKeyValues:responseObj];
        //NSLog(@"code ---401---ccc------[%@]--[%d]------------------------33----",model.data,model.code);

        if (model.code == 401 ) {
            [[LoginManager sharedManager] handleLoginExpired];
            return ;
        }
        //-------------------------------------x-------------------
        if (model.code == 0) {
            flag = YES;
        }
        success(flag,model);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

+ (void)postRequest:(NSString *)URLString parames:(id)parames success:(void (^)(BOOL success,BaseDataModel *response))success failure:(void (^)(NSError *error))failure {
    //NSString *host = [AppConfig sharedConfig].main_host;
    NSString *host = HOST;
    NSString *strurl = [NSString stringWithFormat:@"%@%@",host,URLString];
    NSString *encoded = [strurl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    // 3. 构造 NSURL
    NSURL *url = [NSURL URLWithString:encoded];

    // 4. 校验
    if (!url) {
        NSLog(@"❌ URL 解析失败: [%@]------------------", encoded);
        return;
    } else {
       NSLog(@"✅ 即将请求 URL: [%@]--------------------", url.absoluteString);
    }
    __weak typeof(self) weakSelf = self;
    //void (^requestBlock)(void) = ^{
        
    [[NetWorkTool sharedToolPostAuthorization] requestPOST:strurl parames:parames success:^(NSURLSessionDataTask * _Nonnull task,id responseObj) {
        //===================================================
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
       
        if (model.code == 401) {   //401
        NSLog(@"------------------model.code--[%d]------------是否四0---------22-----",(int)model.code);
            
            
        //BOOL hasRetried = [[NSUserDefaults standardUserDefaults] boolForKey:@"HasRetried401"];
        //NSLog(@"---------------------hav---[%d]--------------外-------------------",hasRetried);
            /*if (!hasRetried) {
                //NSLog(@"---------------------hav---[%d]------------内---------------------",hasRetried);
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasRetried401"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [HttpTools postRequest:URLString parames:parames success:success failure:failure];
                return;
            }*/
            //NSLog(@"-----hav-------------------[%d]-----------------------------------跳登录-----",hasRetried);
            // 已经重试过了，还 401 → 跳登录
            //[MBProgressHUD showMessage:@"---------第二次401，跳转登录页---"];
            //[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"HasRetried401"];
            //[[NSUserDefaults standardUserDefaults] synchronize];
            //Login expired 登录过期
            
                [MBProgressHUD showLabel:NSLocalizedString(@"Login expired",@"")];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[LoginManager sharedManager] handleLoginExpired];
            });
            
              return;
        }
        if (model.code == 0) {
            flag = YES;
        }
        success(flag,model);
    } failure:^(NSError *error) {
        failure(error);
    }];
    
}
+ (void)postRequestUsers:(NSString *)URLString parames:(id)parames success:(void (^)(BOOL success,BaseDataModel *response))success failure:(void (^)(NSError *error))failure {
    //NSString *host = [AppConfig sharedConfig].main_host;
    NSString *host = HOST;
    NSLog(@"2ci------------");
    [[NetWorkTool sharedToolPostUsers] requestPOST:[NSString stringWithFormat:@"%@%@",host,URLString] parames:parames success:^(NSURLSessionDataTask * _Nonnull task,id responseObj) {
        //===================================================
   
        BOOL flag = NO;
        BaseDataModel *model = [BaseDataModel mj_objectWithKeyValues:responseObj];
        //NSLog(@"code ---401---ccc------[%@]--[%d]------------------------11-----",model.data,model.code);
      if (model.code == 401 ) {
          [[LoginManager sharedManager] handleLoginExpired];
          return;
        }
        
        if (model.code == 0) {
            flag = YES;
        }
        success(flag,model);
    } failure:^(NSError *error) {
        failure(error);
    }];
}
+ (UINavigationController *)currentNavigationController{
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIViewController *rootViewController = delegate.window.rootViewController;
    
    if (rootViewController.presentedViewController && [rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)rootViewController.presentedViewController;
    }
    
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)rootViewController;
    }
    
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UINavigationController *nav = ((UITabBarController *)rootViewController).selectedViewController;
        return nav;
    }
    return nil;
    
}
+ (void)setNavieationBarColor:(UINavigationController *)nav {

    nav.navigationBar.tintColor = [UIColor whiteColor];
    nav.navigationBar.barTintColor =  [UIColor colorWithRed:14.0/255.0 green:22.0/255.0 blue:47.0/255.0 alpha:1];
    UIColor *titltColor = [UIColor whiteColor];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:titltColor forKey:NSForegroundColorAttributeName];
    nav.navigationBar.titleTextAttributes = dict;
}

+ (void)uploadImageWithURL:(NSString *)url images:(NSArray <UIImage *> *)images params:(NSMutableDictionary *)params imageParamsName:(NSString *)imageParamsName success:(void (^)(BaseDataModel *result))success failure:(void (^)(NSError *))failure {
    //NSString *host = [AppConfig sharedConfig].main_host;
    NSString *host = HOST;
    [[NetWorkTool sharedToolPostAuthorization] POST:[NSString stringWithFormat:@"%@%@",host,url] parameters:[self md5Parames:params] headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (int i = 0; i < images.count; i ++) {
            NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
            formatter.dateFormat=@"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString stringWithFormat:@"%@%d.jpg",str,i];
            fileName = @"file.jpg";
            NSData *imageData = UIImageJPEGRepresentation(images[i], 0.1);
             [formData appendPartWithFileData:imageData name:[NSString stringWithFormat:@"%@",imageParamsName] fileName:fileName mimeType:@"image/jpeg"];
            //[formData appendPartWithFileData:imageData name:[NSString stringWithFormat:@"%@%d",imageParamsName,i+1] fileName:fileName mimeType:@"image/jpeg"];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (success) {
                success([BaseDataModel mj_objectWithKeyValues:responseObject]);
            }
        });
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (failure) {
                failure(error);
            }
        });
        
    }];
}

#pragma mark - *_*  *_*
+ (NSDictionary *)md5Parames:(NSMutableDictionary *)dict{
    return dict;
}

+ (NSString *)timestampString{
    //获取当前时间戳
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
    return [NSString stringWithFormat:@"%.0f", time];
}
@end
