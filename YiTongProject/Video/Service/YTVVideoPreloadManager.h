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

/// 取出已预热的 item（取出后从池移除）；无则返回 nil
- (nullable AVPlayerItem *)takePrewarmedItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL;

/// 离开分类或降载时清空池，避免多分类抢解码
- (void)invalidateAllWarmItems;

@end

NS_ASSUME_NONNULL_END
