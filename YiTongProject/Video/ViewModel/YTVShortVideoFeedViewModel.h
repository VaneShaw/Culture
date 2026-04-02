//
//  YTVShortVideoFeedViewModel.h
//  YiTongProject
//
//  单分类竖滑流：列表状态、bootstrap/next 补货（技术设计阶段 3 / §4）
//

#import <Foundation/Foundation.h>

@class YTVVideoFeedItem;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTVShortVideoFeedState) {
    YTVShortVideoFeedStateIdle = 0,
    YTVShortVideoFeedStateLoading,
    YTVShortVideoFeedStateReady,
    YTVShortVideoFeedStateEmpty,
    YTVShortVideoFeedStateError,
};

typedef NS_ENUM(NSInteger, YTVShortVideoFeedSource) {
    YTVShortVideoFeedSourceCategory = 0,
    YTVShortVideoFeedSourceFavorites,
};

/// `appendedAny`：本次链式请求是否曾写入新条目；`error`：整段失败时非空（去重连拉耗尽不算错误）
typedef void (^YTVFeedLoadNextCompletion)(BOOL appendedAny, NSError *_Nullable error);

@interface YTVShortVideoFeedViewModel : NSObject

@property (nonatomic, copy, readonly) NSString *categoryKey;
@property (nonatomic, assign, readonly) YTVShortVideoFeedSource feedSource;
@property (nonatomic, assign, readonly) YTVShortVideoFeedState state;
@property (nonatomic, copy, readonly) NSArray<YTVVideoFeedItem *> *items;
@property (nonatomic, copy, readonly, nullable) NSString *lastErrorMessage;
@property (nonatomic, assign, readonly) BOOL hasMore;
/// 正在请求 next（与环形末态配合：有补货可能时不应强制跳回第一条）
@property (nonatomic, assign, readonly) BOOL ytv_isLoadingNext;
/// 分类流：首包网络 bootstrap 已结束（含失败）；用于深链单条补拉，避免与首包列表竞态覆盖
@property (nonatomic, assign, readonly) BOOL ytv_categoryBootstrapNetworkFinished;

- (instancetype)initWithCategoryKey:(NSString *)categoryKey NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// 个人中心收藏进入的竖滑流：`seedItems` 为列表传入的快照；`entryVideoId` 可空（默认从第一条起播）。
+ (instancetype)favoritesFeedViewModelWithSeedItems:(NSArray<YTVVideoFeedItem *> *)seedItems
                                       entryVideoId:(nullable NSString *)entryVideoId;

/// 收藏流首条定位下标（在 `state == Ready` 且 items 已就绪后调用）
- (NSInteger)ytv_initialDisplayIndex;

/// 首拉或重试；回调总在主线程
- (void)loadBootstrapWithCompletion:(void (^)(void))completion;

/// 根据当前展示下标检查 §4 lowWaterMark，必要时静默拉 next；回调主线程
- (void)loadNextPageIfNeededForDisplayIndex:(NSInteger)displayIndex completion:(nullable YTVFeedLoadNextCompletion)completion;

/// bootstrap / next 等错误上屏文案（含 4xx/5xx 与网络域区分）
+ (NSString *)ytv_userFacingMessageForFeedError:(nullable NSError *)error;

- (NSUInteger)numberOfItems;
- (nullable YTVVideoFeedItem *)itemAtIndex:(NSInteger)index;

/// 收藏乐观更新；失败回滚并 `success == NO`。回调主线程。
- (void)toggleFavoriteAtDisplayIndex:(NSInteger)index
                          completion:(void (^)(BOOL success, NSString * _Nullable message))completion;

/// 列表中 `videoId` 的下标，不存在返回 `-1`
- (NSInteger)ytv_indexOfVideoId:(NSString *)videoId;

/// 列表中无该 id 时请求单条并插入队首；已有则不应调用。回调主线程。
- (void)ytv_fetchInsertVideoAtHeadIfMissing:(NSString *)videoId
                                 completion:(void (^)(BOOL success, NSString * _Nullable message))completion;

@end

NS_ASSUME_NONNULL_END
