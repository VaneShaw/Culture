//
//  YTVVideoPreloadManager.h
//  YiTongProject
//
//  封面 SD 预取 + 邻条媒体真预热（技术设计 §5 / §5.1）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YTVVideoFeedItem;
@class AVPlayerItem;

@interface YTVVideoPreloadManager : NSObject

/// 当前索引邻域：上一条 + 后两条封面预取，并对媒体资源做真预热。
- (void)warmAroundDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items;

/// 仅在预热条目已进入 Prepared 时返回可复用的 playerItem；否则返回 nil。
- (nullable AVPlayerItem *)preparedPlayerItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 当前 AVPlayer 正在使用的 videoId；裁剪 warm 池时优先保留该项。
- (void)markPlaybackProtectedVideoId:(nullable NSString *)videoId;

/// 切走时若池内仍有该条，将其标为最近访问，提升回滑命中率。
- (void)touchWarmEntryForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 按当前保留窗口裁剪 warm 池，避免无界增长与过度带宽占用。
- (void)trimWarmPoolPreservingCurrentWindow;

/// 离开分类或降载时清空池，避免多分类抢解码。
- (void)invalidateAllWarmItems;

@end

NS_ASSUME_NONNULL_END
