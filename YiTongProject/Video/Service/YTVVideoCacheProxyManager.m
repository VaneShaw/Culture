//
//  YTVVideoCacheProxyManager.m
//  YiTongProject
//

#import "YTVVideoCacheProxyManager.h"
#import "YTVVideoDiskCacheManager.h"

@implementation YTVVideoCachePlaybackDecision
@end

@implementation YTVVideoCacheProxyManager

+ (instancetype)sharedManager {
    static YTVVideoCacheProxyManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YTVVideoCacheProxyManager alloc] init];
    });
    return manager;
}

- (YTVVideoCachePlaybackDecision *)playbackDecisionForRemoteURLString:(NSString *)remoteURLString {
    YTVVideoCachePlaybackDecision *decision = [[YTVVideoCachePlaybackDecision alloc] init];
    decision.playbackSource = YTVVideoCachePlaybackSourceRemote;
    decision.sourceLabel = @"remote";
    decision.canUpgradeToProxyLater = YES;
    if (remoteURLString.length == 0) {
        decision.playbackURL = nil;
        return decision;
    }
    NSURL *cachedURL = [[YTVVideoDiskCacheManager sharedManager] cachedFileURLForRemoteURLString:remoteURLString];
    if (cachedURL) {
        decision.playbackURL = cachedURL;
        decision.playbackSource = YTVVideoCachePlaybackSourceDiskFile;
        decision.sourceLabel = @"disk";
        return decision;
    }
    decision.playbackURL = [NSURL URLWithString:remoteURLString];
    return decision;
}

- (BOOL)isVideoCachedForRemoteURLString:(NSString *)remoteURLString {
    if (remoteURLString.length == 0) {
        return NO;
    }
    return ([[YTVVideoDiskCacheManager sharedManager] cachedFileURLForRemoteURLString:remoteURLString] != nil);
}

- (void)prefetchVideoForRemoteURLString:(NSString *)remoteURLString {
    if (remoteURLString.length == 0) {
        return;
    }
    [[YTVVideoDiskCacheManager sharedManager] cacheVideoIfNeededForRemoteURLString:remoteURLString];
}

@end
