//
//  YTVVideoCategoryTabsView.h
//  YiTongProject
//
//  视频页顶部分类栏；项数与文案由 /video/tab 或本地默认配置决定
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoCategoryTabsView : UIView

/// 用户点选分类（0..count-1）
@property (nonatomic, copy, nullable) void (^onSelectIndex)(NSInteger index);
/// 点击右侧搜索
@property (nonatomic, copy, nullable) void (^onSearchTap)(void);

- (void)ytv_setSelectedIndex:(NSInteger)index animated:(BOOL)animated;
/// 重建 Segment 按钮；`titles` 为 nil 时用 `YTVVideoCategoryTitleAtIndex` 兜底
- (void)ytv_applyTabTitles:(NSArray<NSString *> * _Nullable)titles;
/// `video/tab` 未返回前隐藏选中横杠，避免先露出默认选中态。
- (void)ytv_setSelectionUnderlineHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
