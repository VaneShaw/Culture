//
//  UserStateManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/30.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, UserVipStatus) {
    UserVipStatusType1 = 1,
    UserVipStatusType2 = 2,
    UserVipStatusType3 = 3,
    UserVipStatusType4 = 4
};
@interface UserStateManager : NSObject
+ (instancetype)shared;

#pragma mark - 会员状态
@property (nonatomic, assign, readonly) UserVipStatus vipStatus;

#pragma mark - UI 刷新标记
@property (nonatomic, assign) BOOL needRefreshVipUI;
@property (nonatomic, assign) BOOL needRefreshLoginUI; // 预留

#pragma mark - 其他状态（示例）
@property (nonatomic, assign, readonly) BOOL shouldHideVipEntry;

#pragma mark - 状态更新入口（唯一）
- (void)updateVipStatus:(UserVipStatus)vipStatus;
@end
