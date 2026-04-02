//
//  YTVShortVideoFeedViewController.h
//  YiTongProject
//
//  单分类竖滑 Feed（技术设计 ShortVideoFeedViewController，阶段 3）
//

#import "BaseViewController.h"

@class YTVVideoFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface YTVShortVideoFeedViewController : BaseViewController

@property (nonatomic, copy, readonly) NSString *categoryKey;

- (instancetype)initWithCategoryKey:(NSString *)categoryKey;

/// 从「我的-收藏」进入：`seedItems` 为当前列表快照；`entryVideoId` 为点击的那条。
- (instancetype)initWithFavoritesSeedItems:(NSArray *)seedItems
                              entryVideoId:(nullable NSString *)entryVideoId;

/// 当前分类成为可见（横向切到本页）：首进拉 bootstrap，再次进入恢复播放
- (void)ytv_activateCategoryFeed;

/// 横向切走本分类：暂停并释放当前 item，降低解码与带宽占用（技术设计「非当前分类降载」）
- (void)ytv_deactivateCategoryFeed;

/// 分类流：深链进入时滚到已存在条目或单条补拉；收藏流忽略
- (void)ytv_handleDeepLinkWithEntryVideoId:(NSString *)videoId;

@end

NS_ASSUME_NONNULL_END
