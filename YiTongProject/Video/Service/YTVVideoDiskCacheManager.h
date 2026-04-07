//
//  YTVVideoDiskCacheManager.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoDiskCacheManager : NSObject

+ (instancetype)sharedManager;

- (nullable NSURL *)cachedFileURLForRemoteURLString:(NSString *)remoteURLString;

- (void)cacheVideoIfNeededForRemoteURLString:(NSString *)remoteURLString;

- (void)trimCacheIfNeeded;
- (NSUInteger)cachedItemCount;
- (unsigned long long)cachedBytes;

@end

NS_ASSUME_NONNULL_END
