//
//  YTVVideoCategoryKeys.h
//  YiTongProject
//
//  与接口 `category` 参数及技术设计 FeedContext 对齐；条数与文案由 /video/tab 覆盖。
//  未请求成功前无内置默认 Tab；仅在 /video/tab 请求失败时由 VideoTab 页应用「推荐」兜底（key=recommend）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSUInteger YTVVideoCategoryCount(void);

/// 0起；越界返回空串
FOUNDATION_EXPORT NSString *YTVVideoCategoryKeyAtIndex(NSUInteger index);

/// Segment 展示文案（接口下发或本地兜底）；越界返回 @""
FOUNDATION_EXPORT NSString *YTVVideoCategoryTitleAtIndex(NSUInteger index);

/// `tz`/`recommend`/`idiom`/`myth`/`fengshen` 等；`recommend` 与 `tz` 互为别名；未知返回 `NSNotFound`
FOUNDATION_EXPORT NSInteger YTVVideoCategoryIndexForKey(NSString *categoryKey);

/// 用接口结果覆盖 keys与标题（须在主线程调用）；`titles` 可与 `keys` 等长，不足时缺省段用 key 占位
FOUNDATION_EXPORT void YTVVideoCategorySetFeedTabConfiguration(NSArray<NSString *> *keys, NSArray<NSString *> *titles);

/// 当前配置是否与给定 keys 顺序、内容完全一致（用于避免无意义重建 Feed槽位）
FOUNDATION_EXPORT BOOL YTVVideoCategoryConfigurationMatchesKeys(NSArray<NSString *> *keys);

NS_ASSUME_NONNULL_END
