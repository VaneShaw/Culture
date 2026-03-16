//
//  NetworkMonitor.h
//  YiTongProject
//
//  Created by ios01 on 2025/8/25.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

typedef NS_ENUM(NSInteger, NetworkStatusType) {
    NetworkStatusTypeNotReachable = 0,  // 无网络
    NetworkStatusTypeWiFi,              // Wi-Fi
    NetworkStatusTypeCellular           // 蜂窝数据
};


@interface NetworkMonitor : NSObject

+ (instancetype)sharedMonitor;

/// 当前网络状态
@property (nonatomic, assign, readonly) NetworkStatusType currentStatus;

/// 网络状态变化回调
@property (nonatomic, copy, nullable) void (^statusChangeHandler)(NetworkStatusType status);

/// 开始监听网络
- (void)startMonitoring;

/// 停止监听网络
- (void)stopMonitoring;


@end
