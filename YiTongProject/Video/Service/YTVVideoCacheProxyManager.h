//
//  YTVVideoCacheProxyManager.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTVVideoCachePlaybackSource) {
    YTVVideoCachePlaybackSourceRemote = 0,
    YTVVideoCachePlaybackSourceDiskFile,
    YTVVideoCachePlaybackSourceProxyPlaceholder,
};

@interface YTVVideoCachePlaybackDecision : NSObject

@property (nonatomic, strong, nullable) NSURL *playbackURL;
@property (nonatomic, assign) YTVVideoCachePlaybackSource playbackSource;
@property (nonatomic, copy) NSString *sourceLabel;
@property (nonatomic, assign) BOOL canUpgradeToProxyLater;

@end

@interface YTVVideoCacheProxyManager : NSObject

+ (instancetype)sharedManager;

/// 当前阶段统一返回播放器消费的决策结果；后续可平滑替换为代理 URL。
- (YTVVideoCachePlaybackDecision *)playbackDecisionForRemoteURLString:(NSString *)remoteURLString;

/// 是否已命中本地磁盘缓存。
- (BOOL)isVideoCachedForRemoteURLString:(NSString *)remoteURLString;

/// 后台触发轻量缓存；当前阶段复用整文件磁盘缓存实现。
- (void)prefetchVideoForRemoteURLString:(NSString *)remoteURLString;

@end

NS_ASSUME_NONNULL_END
