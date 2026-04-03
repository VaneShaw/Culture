//
//  YTVVideoPreloadManager.h
//  YiTongProject
//
//  封面 SD 预取 + 邻条 AVPlayerItem 预热（技术设计 §5 / §5.1）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YTVVideoFeedItem;
@class AVPlayerItem;

@interface YTVVideoPreloadManager : NSObject

/// 当前索引邻域：上一首 + 后 3 条封面预取；可预热条数上限内做媒体预热
- (void)warmAroundDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items;

/// 取出已预热的 item（仍保留在池内，便于回滑复用）；校验 playURL 一致；无则返回 nil
- (nullable AVPlayerItem *)takePrewarmedItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 当前 AVPlayer 正在使用的 videoId；LRU 满时淘汰不会剔除该项，避免播中丢池
- (void)setProtectedPlaybackVideoId:(nullable NSString *)videoId;

/// 切走时若池内仍有该条，将其标为最近使用，降低被 LRU 挤掉概率（配合回滑）
- (void)touchWarmEntryForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 离开分类或降载时清空池，避免多分类抢解码
- (void)invalidateAllWarmItems;

@end

NS_ASSUME_NONNULL_END
