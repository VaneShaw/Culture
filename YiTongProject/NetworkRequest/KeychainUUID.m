//
//  KeychainUUID.m
//  YiTongProject
//
//  Created by ios01 on 2026/1/4.
//

#import "KeychainUUID.h"
#import <Security/Security.h>
@implementation KeychainUUID

+ (NSString *)getUUID {
    NSString *service = @"com.yourapp.uniqueUUID"; // 自己 App 唯一标识
    NSString *account = @"deviceUUID";
    
    // 1. 从 Keychain 读取
    NSString *uuid = [self getKeychainValueForService:service account:account];
    if (uuid) {
        return uuid;
    }
    
    // 2. 没有就生成 IDFV
    uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // 3. 保存 Keychain
    [self saveKeychainValue:uuid service:service account:account];
    
    return uuid;
}

#pragma mark - Keychain helper

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service account:(NSString *)account {
    return [@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService: service,
              (__bridge id)kSecAttrAccount: account,
              (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock
    } mutableCopy];
}

+ (void)saveKeychainValue:(NSString *)value service:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service account:account];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery); // 删除旧值
    keychainQuery[(__bridge id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

+ (NSString *)getKeychainValueForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service account:account];
    keychainQuery[(__bridge id)kSecReturnData] = @YES;
    keychainQuery[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        NSData *data = (__bridge_transfer NSData *)keyData;
        NSString *uuid = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return uuid;
    }
    return nil;
}
+ (BOOL)isEmptyString:(NSString *)str {
    if (str == nil) return YES;
    if ([str isKindOfClass:[NSNull class]]) return YES;
    if (str.length == 0) return YES;
    return NO;
}
@end
