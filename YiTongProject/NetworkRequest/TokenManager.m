//
//  TokenManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/30.
//

#import "TokenManager.h"

@implementation TokenManager
+ (instancetype)sharedManager {
    static TokenManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TokenManager alloc] init];
        manager.requestQueue = [NSMutableArray array];
    });
    return manager;
}
// 更新 Token 并存储
- (void)updateToken:(NSString *)newToken {
    if (newToken && newToken.length > 0) {
        [KUSER_DEFAULT setObject:newToken forKey:@"Authorization_key"];
        [KUSER_DEFAULT synchronize];
    }
}
// 获取当前 Token
- (NSString *)currentToken {
    return [KUSER_DEFAULT objectForKey:@"Authorization_key"];
}
- (void)refreshTokenWithCompletion:(void (^)(BOOL))completion {
    if (self.isRefreshing) {
        return;
    }
    self.isRefreshing = YES;
}

@end
