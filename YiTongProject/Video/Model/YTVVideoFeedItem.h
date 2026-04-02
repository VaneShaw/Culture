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

+ (instancetype)itemWithDictionary:(NSDictionary *)dict;

/// 与 `itemWithDictionary:` 字段一致，供 `FeedSnapshotCache` 落盘
- (NSDictionary *)ytv_toSnapshotDictionary;

@end

NS_ASSUME_NONNULL_END
