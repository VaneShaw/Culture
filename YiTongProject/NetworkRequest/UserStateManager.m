//
//  UserStateManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/30.
//

#import "UserStateManager.h"

@implementation UserStateManager{
    UserVipStatus _vipStatus;
    BOOL _shouldHideVipEntry;
}
+ (instancetype)shared {
    static UserStateManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[UserStateManager alloc] init];
    });
    return manager;
}

#pragma mark - 状态更新

- (void)updateVipStatus:(UserVipStatus)vipStatus {
    if (_vipStatus == vipStatus) return;

    _vipStatus = vipStatus;
 
    // 🔔 标记 UI 需要刷新
    self.needRefreshVipUI = YES;
    // 🔔 发通知（即时页面用）
    //[[NSNotificationCenter defaultCenter]
        //postNotificationName:IAP_Membership_Notification
        //object:nil];
}

#pragma mark - Getter

- (UserVipStatus)vipStatus {
    return _vipStatus;
}

- (BOOL)shouldHideVipEntry {
    return _shouldHideVipEntry;
}
@end
