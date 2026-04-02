//
//  YTVFeedSnapshotCache.h
//  YiTongProject
//
//  分类维度元数据快照（磁盘 JSON，技术设计 §5 FeedSnapshotCache）
//

#import <Foundation/Foundation.h>

@class YTVVideoFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface YTVFeedSnapshotCache : NSObject

/// 写入当前列表与游标（主线程调用为宜）
+ (void)saveCategoryKey:(NSString *)categoryKey
                  items:(NSArray<YTVVideoFeedItem *> *)items
             nextCursor:(NSString *)nextCursor
                hasMore:(BOOL)hasMore;

/// 读取快照字典：`items` 为 NSArray<NSDictionary *>，无文件返回 nil
+ (nullable NSDictionary *)loadSnapshotDictionaryForCategoryKey:(NSString *)categoryKey;

@end

NS_ASSUME_NONNULL_END
