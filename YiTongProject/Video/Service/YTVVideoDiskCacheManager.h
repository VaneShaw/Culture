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

@end

NS_ASSUME_NONNULL_END
