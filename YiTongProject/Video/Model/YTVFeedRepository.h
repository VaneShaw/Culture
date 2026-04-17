//
//  YTVFeedRepository.h
//  YiTongProject
//
//  POST /video/feed/bootstrap | /video/feed/next（技术设计 §4）
//

#import <Foundation/Foundation.h>

@class YTVFeedPageResult;
@class YTVVideoFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface YTVFeedRepository : NSObject

/// cursor 传 nil 或空串表示首拉
- (void)fetchBootstrapWithCategoryKey:(NSString *)categoryKey
                               cursor:(nullable NSString *)cursor
                             pageSize:(NSInteger)pageSize
                      lastVideoId:(nullable NSString *)lastVideoId
                           completion:(void (^)(YTVFeedPageResult * _Nullable result, NSError * _Nullable error))completion;

- (void)fetchNextWithCategoryKey:(NSString *)categoryKey
                          cursor:(NSString *)cursor
                        pageSize:(NSInteger)pageSize
                   lastVideoId:(nullable NSString *)lastVideoId
                      completion:(void (^)(YTVFeedPageResult * _Nullable result, NSError * _Nullable error))completion;

/// 深链单条补拉（技术设计阶段 10；路径待联调，失败时 `item == nil`）
- (void)fetchVideoItemById:(NSString *)videoId
                completion:(void (^)(YTVVideoFeedItem * _Nullable item, NSError * _Nullable error))completion;

/// 上报分享点击；成功时返回服务端最新 `share_count`，未下发时为 `-1`
- (void)reportShareWithTaleType:(NSString *)taleType
                         taleId:(NSString *)taleId
                     completion:(void (^)(BOOL success, NSInteger shareCount, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
