//
//  VideoTabViewController.h
//  YiTongProject
//
//  视频学习模块根页（技术设计 VideoTabViewController）
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 底部 TabBar 上「视频」项在 `viewControllers` 中的索引（当前：首页0、说说1、视频2、我的3）
FOUNDATION_EXPORT const NSInteger kYTVVideoTabBarIndex;

@interface VideoTabViewController : BaseViewController

/// 深链：切到 `categoryKey` 对应分类（无效或未传则推荐），并定位/补拉 `videoId`
- (void)ytv_openDeepLinkWithVideoId:(NSString *)videoId categoryKey:(nullable NSString *)categoryKey;

@end

NS_ASSUME_NONNULL_END
