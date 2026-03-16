//
//  UserModel.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

//-------------------
#import <Foundation/Foundation.h>

@interface UserModel : NSObject

@property (nonatomic, strong, readonly) NSString *token;
@property (nonatomic, strong, readonly) NSDictionary *user;
@property (nonatomic, strong) NSDate *vipExpireDate;
+ (instancetype)sharedInstance;

/// 登录成功后保存用户信息
- (void)saveLoginInfoWithToken:(NSString *)token user:(NSDictionary *)user;

/// 退出登录
- (void)logout;

/// 是否已登录
- (BOOL)isLogin;
//是否是会员
//- (BOOL)isMember;
/// 便捷获取字段
- (NSString *)userId;
- (NSString *)username;
- (NSString *)email;
- (NSString *)avatar;
- (NSString *)mobile;

//刷新接口 ？？
//- (void)refreshUserInfoWithCompletion:(void(^)(BOOL success))completion;
@end
