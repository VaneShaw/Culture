//
//  YTVFavoritesListViewModel.h
//  YiTongProject
//
//  我的-收藏 列表（技术设计 §8 / 阶段 9）
//

#import <Foundation/Foundation.h>

@class YTVVideoFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface YTVFavoritesListViewModel : NSObject

@property (nonatomic, copy, readonly) NSArray<YTVVideoFeedItem *> *items;
@property (nonatomic, assign, readonly) BOOL isLoading;

/// 未登录时清空内存列表（避免上一账号缓存误显）
- (void)clearItemsForLogout;

/// 仅读磁盘快照（用于进入页面瞬间铺列表）
- (void)loadDiskCacheOnly;

/// 先读 `__favorites_list__` 磁盘快照刷新 UI，再请求第一页覆盖（主线程回调）
- (void)reloadFromCacheThenNetworkWithCompletion:(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
