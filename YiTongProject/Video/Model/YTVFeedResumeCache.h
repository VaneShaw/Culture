//
//  YTVFeedResumeCache.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVFeedResumeCache : NSObject

+ (void)saveCategoryKey:(NSString *)categoryKey
        lastViewedVideoId:(nullable NSString *)lastViewedVideoId
         lastViewedPlayURL:(nullable NSString *)lastViewedPlayURL
       lastViewedIndexHint:(NSInteger)lastViewedIndexHint;

+ (nullable NSDictionary *)loadResumeDictionaryForCategoryKey:(NSString *)categoryKey;

@end

NS_ASSUME_NONNULL_END
