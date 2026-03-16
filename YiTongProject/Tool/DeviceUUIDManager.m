//
//  DeviceUUIDManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/24.
//

#import "DeviceUUIDManager.h"
#import <Security/Security.h>
static NSString * const kDeviceUUIDKey = @"com.shiyiyitong.device.uuid";


@implementation DeviceUUIDManager
#pragma mark - Public
+ (NSString *)deviceUUID {
    NSString *uuid = [self readUUIDFromKeychain];
    if (!uuid || uuid.length == 0) {
        uuid = [[NSUUID UUID] UUIDString];
        [self saveUUIDToKeychain:uuid];
    }
    return uuid;
}

#pragma mark - Keychain Save / Read

+ (void)saveUUIDToKeychain:(NSString *)uuid {
    NSData *data = [uuid dataUsingEncoding:NSUTF8StringEncoding];

    NSDictionary *query = @{
        (__bridge id)kSecClass:               (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount:         kDeviceUUIDKey,
        (__bridge id)kSecValueData:           data,
        (__bridge id)kSecAttrAccessible:      (__bridge id)kSecAttrAccessibleAfterFirstUnlock
    };

    // 先删除旧的（避免重复存储）
    SecItemDelete((__bridge CFDictionaryRef)query);

    // 写入新的
    SecItemAdd((__bridge CFDictionaryRef)query, NULL);
}

+ (NSString *)readUUIDFromKeychain {
    NSDictionary *query = @{
        (__bridge id)kSecClass:               (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount:         kDeviceUUIDKey,
        (__bridge id)kSecReturnData:          @YES,
        (__bridge id)kSecMatchLimit:          (__bridge id)kSecMatchLimitOne
    };

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

    if (status == errSecSuccess) {
        NSData *data = (__bridge_transfer NSData *)result;
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    return nil;
}

@end
