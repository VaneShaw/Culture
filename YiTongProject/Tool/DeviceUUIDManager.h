//
//  DeviceUUIDManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeviceUUIDManager : NSObject
/// 获取设备唯一ID（自动生成+存储）
/// App 卸载重装保持不变
+ (NSString *)deviceUUID;

@end

NS_ASSUME_NONNULL_END
