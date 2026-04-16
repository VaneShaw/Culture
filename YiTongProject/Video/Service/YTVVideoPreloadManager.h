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
@class YTVVideoCachePlaybackDecision;

@interface YTVVideoPreloadManager : NSObject

/// 当前索引邻域：上一条 + 自适应前向若干条封面预取，并对媒体做真预热。
- (void)warmAroundDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items;
/// `pinHeadTail==YES` 时额外固定预热列表头尾各 2 条（环形无更多时避免末条邻域不含首条、wrap 冷启动）。
- (void)warmAroundDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items ringHeadTailPinned:(BOOL)pinHeadTail;

/// 浅预热命中：`ItemReady` 或更深状态时返回可复用的 playerItem；否则返回 nil。
- (nullable AVPlayerItem *)preparedPlayerItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 兜底拿一个基于同一 warming asset 构造的 playback item。
/// 即使还没到 `prepared` 状态，也能避免前台重新从 URL 冷起一条完全独立的请求。
- (nullable AVPlayerItem *)playbackSeedPlayerItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 首播前只对当前目标条做一次轻量 prime，不扩散到邻条；用于恢复场景下给首条创造 `preferred item` 命中机会。
- (void)primePlaybackItemForImmediateUse:(YTVVideoFeedItem *)item;

/// 首条首播获取最终播放 URL：优先命中本地缓存，未命中则回退远端 URL。
- (YTVVideoCachePlaybackDecision *)playbackDecisionForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 将当前条加入跨会话缓存候选，仅保留极少量条目。
- (void)prefetchPlaybackResourceForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 当前索引的 next1 是否已达到深预热（buffered-ready，可直接交给后台候场 player）。
- (BOOL)hasDeepPreparedItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 指定 next1 为深预热目标；其余条目仍保持浅预热，避免带宽与内存失控。
- (void)setDeepPrewarmTargetVideoId:(nullable NSString *)videoId;

/// 当前 AVPlayer 正在使用的 videoId；裁剪 warm 池时优先保留该项。
- (void)markPlaybackProtectedVideoId:(nullable NSString *)videoId;

/// 切走时若池内仍有该条，将其标为最近访问，提升回滑命中率。
- (void)touchWarmEntryForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 按当前保留窗口裁剪 warm 池，避免无界增长与过度带宽占用。
- (void)trimWarmPoolPreservingCurrentWindow;

/// 非激活分类降载：淘汰 warm 池中不在「当前条 + 上下邻」窗口内的条目，不发起新预热（Phase 4）。
- (void)trimWarmPoolKeepingNeighborhoodOfDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items;

/// 离开分类或降载时清空池，避免多分类抢解码。
- (void)invalidateAllWarmItems;

/// 根据网络与滑动速度更新预热策略，避免固定窗口在所有场景下都用同一套规则。
- (void)updateAdaptiveHintWithScrollVelocity:(CGFloat)velocityY;

@end

NS_ASSUME_NONNULL_END
