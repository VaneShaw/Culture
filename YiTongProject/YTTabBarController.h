//
//  YTTabBarController.h
//  YiTongProject
//
//  覆盖选中索引/VC 的 setter，保证 Tab 切换时一定能刷新底部栏样式（KVO 对 selectedIndex 不可靠）。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTabBarController : UITabBarController

@end

NS_ASSUME_NONNULL_END
