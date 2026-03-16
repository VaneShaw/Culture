//
//  NetworkMonitor.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/25.
//

#import "NetworkMonitor.h"
#import <Network/Network.h>

#import <netinet/in.h>
#import <arpa/inet.h>

@interface NetworkMonitor ()

@property (nonatomic) nw_path_monitor_t monitor;
@property (nonatomic, assign, readwrite) NetworkStatusType currentStatus;

@end
//判断 网络连接是否是 蜂窝 还是 wifi
@implementation NetworkMonitor

#pragma mark - Lifecycle

+ (instancetype)sharedMonitor {
    static NetworkMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkMonitor alloc] init];
    });
    return instance;
}
- (instancetype)init {
    if (self = [super init]) {
        _currentStatus = NetworkStatusTypeNotReachable;
    }
    return self;
}

- (void)startMonitoring {
    if (self.monitor) return; // 已经在监听

    self.monitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(self.monitor, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(self.monitor, ^(nw_path_t path) {
        NetworkStatusType newStatus = NetworkStatusTypeNotReachable;

        if (nw_path_get_status(path) == nw_path_status_satisfied) {
            if (nw_path_uses_interface_type(path, nw_interface_type_wifi)) {
                newStatus = NetworkStatusTypeWiFi;
            } else if (nw_path_uses_interface_type(path, nw_interface_type_cellular)) {
                newStatus = NetworkStatusTypeCellular;
            }
        }
        if (weakSelf.currentStatus != newStatus) {
            weakSelf.currentStatus = newStatus;
            if (weakSelf.statusChangeHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.statusChangeHandler(newStatus);
                });
            }
        }
    });
    nw_path_monitor_start(self.monitor);
}
- (void)stopMonitoring {
    if (self.monitor) {
        nw_path_monitor_cancel(self.monitor);
        self.monitor = nil;
    }
}


@end
