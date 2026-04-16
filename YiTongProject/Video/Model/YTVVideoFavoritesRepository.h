//
//  YTVVideoFavoritesRepository.h
//  YiTongProject
//
//  POST /video/favorite
//

#import <Foundation/Foundation.h>

@class YTVFeedPageResult;

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoFavoritesRepository : NSObject

/// 回调在主线程。`favoritesCount` 无字段时为 -1；失败时 `isFavorite` 无意义。
- (void)toggleFavoriteWithTaleType:(NSString *)taleType
                            taleId:(NSString *)taleId
                        isFavorite:(BOOL)isFavorite
                       completion:(void (^)(BOOL success, BOOL isFavorite, NSInteger favoritesCount, NSString * _Nullable message))completion;

/// `POST /user/videoFavorites/list`，结构与 Feed 分页一致（items / next_cursor / has_more）。
- (void)fetchListWithCursor:(nullable NSString *)cursor
                   pageSize:(NSInteger)pageSize
              lastVideoId:(nullable NSString *)lastVideoId
                 completion:(void (^)(YTVFeedPageResult * _Nullable result, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
