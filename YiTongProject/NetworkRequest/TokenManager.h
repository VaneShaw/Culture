//
//  TokenManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TokenManager : NSObject
@property (nonatomic, assign) BOOL isRefreshing; // 是否正在更新 Token
@property (nonatomic, strong) NSMutableArray<void(^)(void)> *requestQueue; // 待重试请求队列

+ (instancetype)sharedManager;

- (void)updateToken:(NSString *)newToken;
- (NSString *)currentToken;
- (void)refreshTokenWithCompletion:(void(^)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
