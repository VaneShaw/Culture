//
//  EmailValidator.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmailValidator : NSObject
// 判断字符串是否为合法邮箱格式
//验证邮箱
+ (BOOL)isValidEmail:(NSString *)email;
+ (BOOL)isValidInput:(NSString *)text;
+ (BOOL)isValidPassword:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
//验证手机号
