//
//  UserModel.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "UserModel.h"
@interface UserModel ()
@property (nonatomic, strong, readwrite) NSString *token;
@property (nonatomic, strong, readwrite) NSDictionary *user;
@end

@implementation UserModel

#pragma mark - 单例
+ (instancetype)sharedInstance {
    static UserModel *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];

        // 从 NSUserDefaults 恢复数据
        NSString *savedToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserToken"];
        NSDictionary *savedUser = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserInfo"];

        instance.token = savedToken ?: @"";
        instance.user = [instance safeUserDictionary:savedUser];
    });
    return instance;
}

// 禁止外部使用 alloc/init/new/copy
+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)mutableCopyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark - 登录保存
- (void)saveLoginInfoWithToken:(NSString *)token user:(NSDictionary *)user {
    self.token = token ?: @"";
    self.user = [self safeUserDictionary:user];

    [[NSUserDefaults standardUserDefaults] setObject:self.token forKey:@"UserToken"];
    [[NSUserDefaults standardUserDefaults] setObject:self.user forKey:@"UserInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
#pragma mark - 退出登录
- (void)logout {
    if (IS_UM_SDK) {
      NSString *userId = [[UserModel sharedInstance] userId];
      [[UMAnalyticsManager sharedManager] trackUserLogout:userId];
    }
    self.token = @"";
    self.user = @{};

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //退出时清空所有
    [[IDStorageManager sharedManager] clearAllSavedValues];
}

#pragma mark - 是否已登录
- (BOOL)isLogin {
    //NSString *name = [[UserModel sharedInstance] username];
    //NSString *userId = [[UserModel sharedInstance] userId];
    //NSLog(@"------token-[%@]-------name[%@]------userid[%@]--",self.token,name,userId);
    return self.token.length > 6;
}

#pragma mark - 便捷 getter
- (NSString *)userId {
    return [self safeString:self.user[@"id"]];
}
- (NSString *)username {
    return [self safeString:self.user[@"username"]];
}
- (NSString *)email {
    return [self safeString:self.user[@"email"]];
}
- (NSString *)avatar {
    return [self safeString:self.user[@"avatar"]];
}
- (NSString *)mobile {
    return [self safeString:self.user[@"mobile"]];
}
#pragma mark - 工具方法
- (NSDictionary *)safeUserDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    NSMutableDictionary *safeDict = [NSMutableDictionary dictionary];
    NSArray *keys = @[@"id", @"username", @"email", @"avatar",@"mobile"];
    for (NSString *key in keys) {
        id value = dict[key];
        safeDict[key] = [self safeString:value];
    }
    return [safeDict copy];
}

- (NSString *)safeString:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@", value];
    } else {
        return @"";
    }
}
//- (BOOL)isMember {
    //return [[NSUserDefaults standardUserDefaults] boolForKey:@"isMember"];
//}
@end
/*
 iOS 虚拟支付 安全 流程 需要判断是否登录，是否是会员，中文地区用人民币，跟英文地区用美元 ，使用oc语言，先用文字描述 逻辑 需要注意事项 分成几个类来写合适 if([[UserModel sharedInstance] isLogin]){已登录 } if(IS_OVERSEAS_VERSION){英文地区} else {中文地区}
 //需要考虑 安全性 越狱问题
 //支付逻辑 是非会员用户可以选择 购买会员，购买会员后可以看更多故事内容， 用户可以试用7天 7天后可以自动扣款，每个月可以自动续费购买会员，也可以设置关闭，用户购买会员后可以在两天内退款
 
 
 
 会员购买流程
 非会员用户选择购买会员：
 可试用7天（Trial）
 试用结束后自动扣款
 每月可以自动续费，可设置关闭
 购买会员后两天内可退款
 
 */
