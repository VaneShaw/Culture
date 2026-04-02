//
//  YTVVideoDebugSampleFeed.h
//  YiTongProject
//
//  DEBUG：20 条公网可播地址，分类 Feed 无后端时可本地联调（默认仅 DEBUG 生效）
//

#import <Foundation/Foundation.h>

@class YTVFeedPageResult;

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoDebugSampleFeed : NSObject

/// DEBUG 下首次读 UserDefaults 无键时默认为 YES；Release 恒为 NO。
+ (BOOL)isSampleFeedEnabled;

+ (void)setSampleFeedEnabled:(BOOL)enabled;

/// 全量调试条目（video_id / url / title）
+ (NSArray *)allSampleItems;

+ (YTVFeedPageResult *)bootstrapPageForCategoryKey:(NSString *)categoryKey pageSize:(NSInteger)pageSize;

+ (YTVFeedPageResult *)nextPageForCategoryKey:(NSString *)categoryKey
                                 lastVideoId:(nullable NSString *)lastVideoId
                                    pageSize:(NSInteger)pageSize;

@end

NS_ASSUME_NONNULL_END
