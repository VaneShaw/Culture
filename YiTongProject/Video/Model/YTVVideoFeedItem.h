//
//  YTVVideoFeedItem.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 视频流单条模型（技术设计 VideoFeedItem）
@interface YTVVideoFeedItem : NSObject

@property (nonatomic, copy) NSString *videoId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *playURL;
@property (nonatomic, copy, nullable) NSString *playURLType;
@property (nonatomic, copy, nullable) NSString *coverURL;
@property (nonatomic, copy, nullable) NSString *fullTextURL;
@property (nonatomic, assign) BOOL isFavorite;
/// 服务端返回的收藏数；未下发时为 -1
@property (nonatomic, assign) NSInteger favoritesCount;
@property (nonatomic, copy, nullable) NSString *shareURL;
@property (nonatomic, copy, nullable) NSString *cacheKey;
@property (nonatomic, copy, nullable) NSString *cursorToken;
@property (nonatomic, assign) NSInteger durationMs;
/// 收藏时间（毫秒时间戳）；列表展示用，未下发为 0
@property (nonatomic, assign) long long favoritedAtMs;

/// 客户端专用：自然像素宽高是否已就绪（接口字段或 AVAsset 探测）；不入 `ytv_toSnapshotDictionary`
@property (nonatomic, assign) BOOL ytv_hasNaturalVideoSize;
@property (nonatomic, assign) CGFloat ytv_naturalVideoWidth;
@property (nonatomic, assign) CGFloat ytv_naturalVideoHeight;

+ (instancetype)itemWithDictionary:(NSDictionary *)dict;

/// 与 `itemWithDictionary:` 字段一致，供 `FeedSnapshotCache` 落盘
- (NSDictionary *)ytv_toSnapshotDictionary;

/// 宽明显大于高时视为横版（竖滑流中居中条带 + 全屏入口）
- (BOOL)ytv_isLandscapeNaturalVideo;

@end

NS_ASSUME_NONNULL_END
