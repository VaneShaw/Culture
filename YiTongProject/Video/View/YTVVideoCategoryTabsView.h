//
//  YTVVideoCategoryTabsView.h
//  YiTongProject
//
//  视频页顶部分类栏（技术设计 §1，固定 4 项）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoCategoryTabsView : UIView

/// 用户点选分类（0..3）
@property (nonatomic, copy, nullable) void (^onSelectIndex)(NSInteger index);
/// 点击右侧搜索
@property (nonatomic, copy, nullable) void (^onSearchTap)(void);

- (void)ytv_setSelectedIndex:(NSInteger)index animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
