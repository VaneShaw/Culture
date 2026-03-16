//
//  EmailValidator.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/2.
//

#import "EmailValidator.h"

@implementation EmailValidator
+ (BOOL)isValidEmail:(NSString *)email {
    if (email.length == 0) return NO;
    // 正则表达式规则（兼容大多数标准邮箱格式）
    NSString *regex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:email];
}
+ (BOOL)isValidInput:(NSString *)text {
    // 检查用户名是否为空
    if ([text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        //[self showStatus:@"用户名不能为空" color:[UIColor redColor]];
        return NO;
    }
    return YES;
}
+ (BOOL)isValidPassword:(NSString *)text {
    // 检查密码长度是否为6位
    if (text.length < 6) {
        //[self showStatus:@"密码必须为6位字符" color:[UIColor redColor]];
        return NO;
    }
    return YES;
}

@end
