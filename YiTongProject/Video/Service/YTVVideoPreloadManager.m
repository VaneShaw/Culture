//
//  YTVVideoPreloadManager.m
//  YiTongProject
//

#import "YTVVideoPreloadManager.h"
#import "YTVVideoFeedItem.h"
#import "YTVVideoCacheProxyManager.h"
#import "HeaderConfig.h"
#import "NetworkMonitor.h"
#import <AVFoundation/AVFoundation.h>

static const NSUInteger kYTVMediaWarmMaxItems = 18;
// 略增大前向缓冲，有利于首帧更快稳定（仍低于深预热的 4s）。
static const NSTimeInterval kYTVWarmForwardBufferDuration = 2.8;
static const NSTimeInterval kYTVWarmBufferedGoalSeconds = 0.35;
static void *kYTVWarmItemStatusContext = &kYTVWarmItemStatusContext;
static void *kYTVWarmItemLoadedTimeRangesContext = &kYTVWarmItemLoadedTimeRangesContext;
static void *kYTVWarmPlayerStatusContext = &kYTVWarmPlayerStatusContext;

typedef NS_ENUM(NSInteger, YTVVideoWarmEntryState) {
    YTVVideoWarmEntryStateIdle = 0,
    YTVVideoWarmEntryStatePreparingAsset,
    YTVVideoWarmEntryStateAssetReady,
    YTVVideoWarmEntryStateItemReady,
    YTVVideoWarmEntryStateBufferedReady,
    YTVVideoWarmEntryStateFailed,
};

/// 单条视频的预热条目：记录资源状态、最近访问时间以及可复用的 playerItem。
@interface YTVVideoWarmEntry : NSObject
@property (nonatomic, copy) NSString *videoId;
@property (nonatomic, copy) NSString *playURL;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong, nullable) AVPlayerItem *playerItem;
@property (nonatomic, strong, nullable) AVPlayerItem *bufferingItem;
@property (nonatomic, assign) YTVVideoWarmEntryState state;
@property (nonatomic, strong) NSDate *lastAccess;
@property (nonatomic, assign) BOOL isDeepTarget;
@property (nonatomic, strong, nullable) AVPlayer *bufferingPlayer;
@property (nonatomic, assign) BOOL bufferingPlayerObserved;
@property (nonatomic, assign) BOOL bufferingPrerollStarted;
@property (nonatomic, assign) BOOL bufferingPrerollFinished;
@end

@implementation YTVVideoWarmEntry
@end

@interface YTVVideoPreloadManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, YTVVideoWarmEntry *> *warmByVideoId;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *warmAccessOrder;
@property (nonatomic, copy, nullable) NSString *protectedPlaybackVideoId;
@property (nonatomic, copy, nullable) NSString *deepPrewarmTargetVideoId;
@property (nonatomic, strong) NSSet<NSString *> *preservedWarmVideoIds;
@property (nonatomic, assign) NSInteger adaptiveForwardCount;
@property (nonatomic, assign) BOOL adaptiveAllowsDeepNext2;
@property (nonatomic, assign) CGFloat lastObservedVelocityY;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *recentBackwardVideoIds;
@property (nonatomic, strong) NSSet<NSString *> *activeDeepWarmVideoIds;
@end

@implementation YTVVideoPreloadManager

- (nullable AVPlayerItem *)ytv_freshPlaybackItemForEntry:(YTVVideoWarmEntry *)entry preferredForwardBufferDuration:(NSTimeInterval)preferredForwardBufferDuration {
    if (!entry || !entry.asset) {
        return nil;
    }
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:entry.asset];
    item.preferredForwardBufferDuration = MAX(preferredForwardBufferDuration, 0.05);
    return item;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _warmByVideoId = [NSMutableDictionary dictionary];
        _warmAccessOrder = [NSMutableOrderedSet orderedSet];
        _preservedWarmVideoIds = [NSSet set];
        _adaptiveForwardCount = 3;
        _recentBackwardVideoIds = [NSMutableOrderedSet orderedSet];
        _activeDeepWarmVideoIds = [NSSet set];
    }
    return self;
}

- (void)dealloc {
    [self invalidateAllWarmItems];
}

- (void)warmAroundDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items {
    [self warmAroundDisplayIndex:displayIndex items:items ringHeadTailPinned:NO];
}

- (void)warmAroundDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items ringHeadTailPinned:(BOOL)pinHeadTail {
    if (items.count == 0) {
        self.preservedWarmVideoIds = [NSSet set];
        self.activeDeepWarmVideoIds = [NSSet set];
        return;
    }
    NSMutableArray<NSURL *> *coverURLs = [NSMutableArray array];
    NSMutableIndexSet *warmIndices = [NSMutableIndexSet indexSet];
    NSMutableSet<NSString *> *deepWarmIds = [NSMutableSet set];
    NSInteger n = (NSInteger)items.count;
    if (displayIndex >= 0 && displayIndex < n) {
        [warmIndices addIndex:(NSUInteger)displayIndex];
        YTVVideoFeedItem *focus = items[(NSUInteger)displayIndex];
        if (focus.videoId.length > 0) {
            [deepWarmIds addObject:focus.videoId];
        }
    }
    if (displayIndex > 0) {
        [warmIndices addIndex:(NSUInteger)(displayIndex - 1)];
    }
    if (displayIndex + 1 < n) {
        [warmIndices addIndex:(NSUInteger)(displayIndex + 1)];
    }
    NSInteger adaptiveForwardCount = MAX(2, self.adaptiveForwardCount);
    for (NSInteger step = 2; step <= adaptiveForwardCount; step++) {
        if (displayIndex + step < n) {
            [warmIndices addIndex:(NSUInteger)(displayIndex + step)];
        }
    }
    for (NSString *videoId in self.recentBackwardVideoIds) {
        NSUInteger idx = [items indexOfObjectPassingTest:^BOOL(YTVVideoFeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.videoId isEqualToString:videoId];
        }];
        if (idx != NSNotFound) {
            [warmIndices addIndex:idx];
        }
    }
    if (pinHeadTail && n >= 2) {
        [warmIndices addIndex:0];
        [warmIndices addIndex:(NSUInteger)(n - 1)];
        if (n >= 3) {
            [warmIndices addIndex:1];
        }
        if (n >= 4) {
            [warmIndices addIndex:(NSUInteger)(n - 2)];
        }
    }
    if (self.deepPrewarmTargetVideoId.length > 0) {
        [deepWarmIds addObject:self.deepPrewarmTargetVideoId];
    }
    if (self.adaptiveAllowsDeepNext2 && displayIndex + 1 < n) {
        YTVVideoFeedItem *next = items[(NSUInteger)(displayIndex + 1)];
        if (next.videoId.length > 0) {
            [deepWarmIds addObject:next.videoId];
        }
    }
    self.activeDeepWarmVideoIds = [deepWarmIds copy];
    NSMutableSet<NSString *> *preservedIds = [NSMutableSet set];
    if (self.protectedPlaybackVideoId.length > 0) {
        [preservedIds addObject:self.protectedPlaybackVideoId];
    }
    [warmIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        YTVVideoFeedItem *item = items[idx];
        if (item.videoId.length > 0) {
            [preservedIds addObject:item.videoId];
        }
        if (item.coverURL.length > 0) {
            NSURL *u = [NSURL URLWithString:item.coverURL];
            if (u && ![u.pathExtension.lowercaseString isEqualToString:@"gif"]) {
                [coverURLs addObject:u];
            }
        }
        [self ytv_enqueueMediaWarmForItem:item];
    }];
    [self ytv_reconcileDeepWarmStates];
    self.preservedWarmVideoIds = [preservedIds copy];
    [self trimWarmPoolPreservingCurrentWindow];
    if (coverURLs.count > 0) {
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:coverURLs];
    }
}

/// 为单条视频发起真预热：先把 asset 的 playable/tracks 异步准备好，再创建 playerItem。
- (void)ytv_enqueueMediaWarmForItem:(YTVVideoFeedItem *)item {
    if (item.videoId.length == 0 || item.playURL.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:item.playURL];
    if (!url || (![url.scheme.lowercaseString isEqualToString:@"http"] && ![url.scheme.lowercaseString isEqualToString:@"https"])) {
        return;
    }
    // 与 AV 预热并行排队落盘，比「仅首帧后再缓存当前条」更早形成 disk 命中。
    [[YTVVideoCacheProxyManager sharedManager] prefetchVideoForRemoteURLString:item.playURL];

    YTVVideoWarmEntry *entry = self.warmByVideoId[item.videoId];
    BOOL isDeepTarget = [self.activeDeepWarmVideoIds containsObject:item.videoId];
    if (entry) {
        if (![entry.playURL isEqualToString:item.playURL]) {
            [self ytv_teardownDeepWarmForEntry:entry];
            [self.warmByVideoId removeObjectForKey:item.videoId];
            [self.warmAccessOrder removeObject:item.videoId];
            entry = nil;
        } else {
            entry.isDeepTarget = isDeepTarget;
            [self ytv_touchEntry:entry];
            if (entry.state == YTVVideoWarmEntryStatePreparingAsset) {
                return;
            }
            if (isDeepTarget) {
                [self ytv_startDeepBufferIfNeededForEntry:entry];
                return;
            }
            if (entry.state == YTVVideoWarmEntryStateAssetReady || entry.state == YTVVideoWarmEntryStateItemReady || entry.state == YTVVideoWarmEntryStateBufferedReady) {
                return;
            }
        }
    }

    while (self.warmAccessOrder.count >= kYTVMediaWarmMaxItems) {
        NSString *evict = [self ytv_nextLRUEvictVideoIdSkippingProtectedWindow];
        if (!evict) {
            break;
        }
        [self.warmAccessOrder removeObject:evict];
        YTVVideoWarmEntry *evictEntry = self.warmByVideoId[evict];
        [self ytv_teardownDeepWarmForEntry:evictEntry];
        [self.warmByVideoId removeObjectForKey:evict];
    }

    if (!entry) {
        entry = [[YTVVideoWarmEntry alloc] init];
        entry.videoId = item.videoId;
        entry.playURL = item.playURL;
        self.warmByVideoId[item.videoId] = entry;
    }
    entry.asset = [AVURLAsset URLAssetWithURL:url options:nil];
    entry.playerItem = nil;
    entry.bufferingItem = nil;
    entry.isDeepTarget = isDeepTarget;
    entry.bufferingPrerollStarted = NO;
    entry.bufferingPrerollFinished = NO;
    entry.state = YTVVideoWarmEntryStatePreparingAsset;
    [self ytv_touchEntry:entry];

    __weak typeof(self) weakSelf = self;
    AVURLAsset *asset = entry.asset;
    NSString *videoId = [entry.videoId copy];
    NSString *playURL = [entry.playURL copy];
    [asset loadValuesAsynchronouslyForKeys:@[@"playable", @"tracks"] completionHandler:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            YTVVideoWarmEntry *currentEntry = self.warmByVideoId[videoId];
            if (!currentEntry || currentEntry.asset != asset || ![currentEntry.playURL isEqualToString:playURL]) {
                return;
            }
            NSError *playableError = nil;
            AVKeyValueStatus playableStatus = [asset statusOfValueForKey:@"playable" error:&playableError];
            NSError *tracksError = nil;
            AVKeyValueStatus tracksStatus = [asset statusOfValueForKey:@"tracks" error:&tracksError];
            BOOL playableReady = (playableStatus == AVKeyValueStatusLoaded && asset.playable);
            BOOL tracksReady = (tracksStatus == AVKeyValueStatusLoaded);
            if (!playableReady || !tracksReady) {
                currentEntry.state = YTVVideoWarmEntryStateFailed;
                currentEntry.playerItem = nil;
                return;
            }
            currentEntry.state = YTVVideoWarmEntryStateAssetReady;
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
            playerItem.preferredForwardBufferDuration = currentEntry.isDeepTarget ? MAX(kYTVWarmForwardBufferDuration, 4.0) : kYTVWarmForwardBufferDuration;
            currentEntry.playerItem = playerItem;
            currentEntry.state = YTVVideoWarmEntryStateItemReady;
            [self ytv_touchEntry:currentEntry];
            if (currentEntry.isDeepTarget) {
                [self ytv_startDeepBufferIfNeededForEntry:currentEntry];
            }
        });
    }];
}

- (nullable AVPlayerItem *)preparedPlayerItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL {
    YTVVideoWarmEntry *entry = [self ytv_validEntryForVideoId:videoId playURL:playURL];
    if (!entry || (entry.state != YTVVideoWarmEntryStateItemReady && entry.state != YTVVideoWarmEntryStateBufferedReady)) {
        return nil;
    }
    [self ytv_touchEntry:entry];
    NSTimeInterval preferredForwardBufferDuration = ((entry.state == YTVVideoWarmEntryStateBufferedReady || entry.bufferingPlayer != nil) && entry.asset)
        ? MAX(kYTVWarmForwardBufferDuration, 4.0)
        : kYTVWarmForwardBufferDuration;
    // Do not hand the foreground player a previously-consumed warm item instance.
    // Rebuild a fresh AVPlayerItem from the warmed asset so playback starts from a clean item state.
    return [self ytv_freshPlaybackItemForEntry:entry preferredForwardBufferDuration:preferredForwardBufferDuration];
}

- (nullable AVPlayerItem *)playbackSeedPlayerItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL {
    YTVVideoWarmEntry *entry = [self ytv_validEntryForVideoId:videoId playURL:playURL];
    if (!entry) {
        return nil;
    }
    [self ytv_touchEntry:entry];
    NSTimeInterval preferredForwardBufferDuration = (entry.state == YTVVideoWarmEntryStateBufferedReady || entry.bufferingPlayer != nil || entry.isDeepTarget)
        ? MAX(kYTVWarmForwardBufferDuration, 4.0)
        : kYTVWarmForwardBufferDuration;
    return [self ytv_freshPlaybackItemForEntry:entry preferredForwardBufferDuration:preferredForwardBufferDuration];
}

- (void)primePlaybackItemForImmediateUse:(YTVVideoFeedItem *)item {
    if (item.videoId.length == 0 || item.playURL.length == 0) {
        return;
    }
    self.protectedPlaybackVideoId = item.videoId;
    self.deepPrewarmTargetVideoId = item.videoId;
    self.activeDeepWarmVideoIds = [NSSet setWithObject:item.videoId];
    self.preservedWarmVideoIds = [NSSet setWithObject:item.videoId];
    [self ytv_enqueueMediaWarmForItem:item];
    [self ytv_reconcileDeepWarmStates];
    [self trimWarmPoolPreservingCurrentWindow];
}

- (YTVVideoCachePlaybackDecision *)playbackDecisionForVideoId:(NSString *)videoId playURL:(NSString *)playURL {
    (void)videoId;
    if (playURL.length == 0) {
        return [[YTVVideoCacheProxyManager sharedManager] playbackDecisionForRemoteURLString:@""];
    }
    return [[YTVVideoCacheProxyManager sharedManager] playbackDecisionForRemoteURLString:playURL];
}

- (void)prefetchPlaybackResourceForVideoId:(NSString *)videoId playURL:(NSString *)playURL {
    (void)videoId;
    if (playURL.length == 0) {
        return;
    }
    [[YTVVideoCacheProxyManager sharedManager] prefetchVideoForRemoteURLString:playURL];
}

- (BOOL)hasDeepPreparedItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL {
    YTVVideoWarmEntry *entry = [self ytv_validEntryForVideoId:videoId playURL:playURL];
    return entry && entry.state == YTVVideoWarmEntryStateBufferedReady;
}

- (void)setDeepPrewarmTargetVideoId:(NSString *)videoId {
    _deepPrewarmTargetVideoId = videoId.length > 0 ? [videoId copy] : nil;
    [self ytv_reconcileDeepWarmStates];
}


- (void)updateAdaptiveHintWithScrollVelocity:(CGFloat)velocityY {
    self.lastObservedVelocityY = fabs(velocityY);
    NetworkStatusType status = [NetworkMonitor sharedMonitor].currentStatus;
    BOOL fastSwipe = self.lastObservedVelocityY >= 1.15;
    if (status == NetworkStatusTypeWiFi) {
        self.adaptiveForwardCount = fastSwipe ? 5 : 4;
        self.adaptiveAllowsDeepNext2 = fastSwipe;
    } else if (status == NetworkStatusTypeCellular) {
        self.adaptiveForwardCount = fastSwipe ? 4 : 3;
        self.adaptiveAllowsDeepNext2 = NO;
    } else {
        self.adaptiveForwardCount = 3;
        self.adaptiveAllowsDeepNext2 = NO;
    }
}

- (void)markPlaybackProtectedVideoId:(NSString *)videoId {
    _protectedPlaybackVideoId = videoId.length > 0 ? [videoId copy] : nil;
}

- (void)touchWarmEntryForVideoId:(NSString *)videoId playURL:(NSString *)playURL {
    YTVVideoWarmEntry *entry = [self ytv_validEntryForVideoId:videoId playURL:playURL];
    if (!entry) {
        return;
    }
    [self ytv_touchEntry:entry];
    if (videoId.length > 0) {
        [self.recentBackwardVideoIds removeObject:videoId];
        [self.recentBackwardVideoIds insertObject:videoId atIndex:0];
        while (self.recentBackwardVideoIds.count > 3) {
            [self.recentBackwardVideoIds removeObjectAtIndex:self.recentBackwardVideoIds.count - 1];
        }
    }
}

- (void)trimWarmPoolPreservingCurrentWindow {
    while (self.warmAccessOrder.count > kYTVMediaWarmMaxItems) {
        NSString *evict = [self ytv_nextLRUEvictVideoIdSkippingProtectedWindow];
        if (!evict) {
            break;
        }
        [self.warmAccessOrder removeObject:evict];
        YTVVideoWarmEntry *evictEntry = self.warmByVideoId[evict];
        [self ytv_teardownDeepWarmForEntry:evictEntry];
        [self.warmByVideoId removeObjectForKey:evict];
    }
}

- (void)trimWarmPoolKeepingNeighborhoodOfDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items {
    NSMutableSet<NSString *> *keep = [NSMutableSet set];
    if (self.protectedPlaybackVideoId.length > 0) {
        [keep addObject:self.protectedPlaybackVideoId];
    }
    NSInteger n = (NSInteger)items.count;
    if (n > 0) {
        NSInteger maxIdx = n - 1;
        NSInteger center = displayIndex;
        if (center == NSNotFound) {
            center = 0;
        }
        center = MAX(0, MIN(center, maxIdx));
        for (NSInteger i = center - 1; i <= center + 2; i++) {
            if (i < 0 || i > maxIdx) {
                continue;
            }
            YTVVideoFeedItem *it = items[(NSUInteger)i];
            if (it.videoId.length > 0) {
                [keep addObject:it.videoId];
            }
        }
    }
    NSMutableArray<NSString *> *toRemove = [NSMutableArray array];
    for (NSString *vid in self.warmByVideoId) {
        if (![keep containsObject:vid]) {
            [toRemove addObject:vid];
        }
    }
    for (NSString *vid in toRemove) {
        YTVVideoWarmEntry *entry = self.warmByVideoId[vid];
        [self ytv_teardownDeepWarmForEntry:entry];
        [self.warmByVideoId removeObjectForKey:vid];
        [self.warmAccessOrder removeObject:vid];
    }
    self.preservedWarmVideoIds = [keep copy];
}

- (void)invalidateAllWarmItems {
    self.protectedPlaybackVideoId = nil;
    [self.recentBackwardVideoIds removeAllObjects];
    self.deepPrewarmTargetVideoId = nil;
    self.activeDeepWarmVideoIds = [NSSet set];
    self.preservedWarmVideoIds = [NSSet set];
    for (YTVVideoWarmEntry *entry in self.warmByVideoId.allValues) {
        [self ytv_teardownDeepWarmForEntry:entry];
    }
    [self.warmByVideoId removeAllObjects];
    [self.warmAccessOrder removeAllObjects];
}

- (nullable YTVVideoWarmEntry *)ytv_validEntryForVideoId:(NSString *)videoId playURL:(NSString *)playURL {
    if (videoId.length == 0 || playURL.length == 0) {
        return nil;
    }
    YTVVideoWarmEntry *entry = self.warmByVideoId[videoId];
    if (!entry || ![entry.playURL isEqualToString:playURL]) {
        return nil;
    }
    return entry;
}

- (void)ytv_touchEntry:(YTVVideoWarmEntry *)entry {
    entry.lastAccess = [NSDate date];
    [self.warmAccessOrder removeObject:entry.videoId];
    [self.warmAccessOrder addObject:entry.videoId];
}

- (void)ytv_reconcileDeepWarmStates {
    NSSet<NSString *> *deepIds = self.activeDeepWarmVideoIds ?: [NSSet set];
    for (YTVVideoWarmEntry *entry in self.warmByVideoId.allValues) {
        BOOL shouldDeep = (entry.videoId.length > 0 && [deepIds containsObject:entry.videoId]);
        if (!shouldDeep) {
            if (entry.isDeepTarget || entry.bufferingPlayer) {
                [self ytv_demoteDeepWarmEntryIfNeeded:entry];
            }
            entry.isDeepTarget = NO;
            continue;
        }
        entry.isDeepTarget = YES;
        [self ytv_startDeepBufferIfNeededForEntry:entry];
    }
}

- (void)ytv_startDeepBufferIfNeededForEntry:(YTVVideoWarmEntry *)entry {
    if (!entry || !entry.isDeepTarget || !entry.asset) {
        return;
    }
    if (entry.state == YTVVideoWarmEntryStatePreparingAsset || entry.state == YTVVideoWarmEntryStateFailed || entry.state == YTVVideoWarmEntryStateBufferedReady) {
        return;
    }
    if (!entry.playerItem) {
        entry.playerItem = [AVPlayerItem playerItemWithAsset:entry.asset];
        entry.playerItem.preferredForwardBufferDuration = MAX(kYTVWarmForwardBufferDuration, 4.0);
        entry.state = YTVVideoWarmEntryStateItemReady;
    }
    if (!entry.bufferingItem) {
        entry.bufferingItem = [AVPlayerItem playerItemWithAsset:entry.asset];
        entry.bufferingItem.preferredForwardBufferDuration = MAX(kYTVWarmForwardBufferDuration, 4.0);
    }
    if (!entry.bufferingPlayer) {
        entry.bufferingPlayer = [[AVPlayer alloc] init];
        entry.bufferingPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        entry.bufferingPlayer.automaticallyWaitsToMinimizeStalling = YES;
    }
    if (entry.bufferingPlayer.currentItem == entry.bufferingItem) {
        [self ytv_resolveDeepWarmStateForEntry:entry];
        return;
    }
    if (!entry.bufferingPlayerObserved) {
        [entry.bufferingPlayer addObserver:self
                                forKeyPath:@"status"
                                   options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                   context:kYTVWarmPlayerStatusContext];
        entry.bufferingPlayerObserved = YES;
    }
    @try {
        [entry.bufferingItem removeObserver:self forKeyPath:@"status" context:kYTVWarmItemStatusContext];
    } @catch (__unused NSException *e) {
    }
    @try {
        [entry.bufferingItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:kYTVWarmItemLoadedTimeRangesContext];
    } @catch (__unused NSException *e) {
    }
    [entry.bufferingItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:kYTVWarmItemStatusContext];
    [entry.bufferingItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:kYTVWarmItemLoadedTimeRangesContext];
    entry.bufferingPrerollStarted = NO;
    entry.bufferingPrerollFinished = NO;
    [entry.bufferingPlayer replaceCurrentItemWithPlayerItem:entry.bufferingItem];
    [entry.bufferingPlayer pause];
    [self ytv_resolveDeepWarmStateForEntry:entry];
}

- (void)ytv_demoteDeepWarmEntryIfNeeded:(YTVVideoWarmEntry *)entry {
    if (!entry) {
        return;
    }
    [self ytv_teardownDeepWarmForEntry:entry];
    if (entry.state != YTVVideoWarmEntryStateFailed && entry.asset) {
        if (!entry.playerItem) {
            entry.playerItem = [AVPlayerItem playerItemWithAsset:entry.asset];
        }
        entry.playerItem.preferredForwardBufferDuration = kYTVWarmForwardBufferDuration;
        entry.state = YTVVideoWarmEntryStateItemReady;
    }
}

- (void)ytv_teardownDeepWarmForEntry:(YTVVideoWarmEntry *)entry {
    if (!entry) {
        return;
    }
    if (entry.bufferingItem) {
        @try {
            [entry.bufferingItem removeObserver:self forKeyPath:@"status" context:kYTVWarmItemStatusContext];
        } @catch (__unused NSException *e) {
        }
        @try {
            [entry.bufferingItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:kYTVWarmItemLoadedTimeRangesContext];
        } @catch (__unused NSException *e) {
        }
    }
    if (entry.bufferingPlayerObserved) {
        @try {
            [entry.bufferingPlayer removeObserver:self forKeyPath:@"status" context:kYTVWarmPlayerStatusContext];
        } @catch (__unused NSException *e) {
        }
        entry.bufferingPlayerObserved = NO;
    }
    [entry.bufferingPlayer pause];
    [entry.bufferingPlayer replaceCurrentItemWithPlayerItem:nil];
    entry.bufferingPlayer = nil;
    entry.bufferingItem = nil;
    entry.bufferingPrerollStarted = NO;
    entry.bufferingPrerollFinished = NO;
}

- (void)ytv_resolveDeepWarmStateForEntry:(YTVVideoWarmEntry *)entry {
    if (!entry || !entry.isDeepTarget || !entry.bufferingItem || !entry.bufferingPlayer) {
        return;
    }
    AVPlayerItem *item = entry.bufferingItem;
    if (item.status == AVPlayerItemStatusFailed) {
        entry.state = YTVVideoWarmEntryStateFailed;
        return;
    }
    if (item.status != AVPlayerItemStatusReadyToPlay) {
        return;
    }
    if (entry.bufferingPlayer.status == AVPlayerStatusFailed) {
        entry.state = YTVVideoWarmEntryStateFailed;
        return;
    }
    if (entry.bufferingPlayer.status != AVPlayerStatusReadyToPlay) {
        return;
    }
    if (!entry.bufferingPrerollStarted) {
        entry.bufferingPrerollStarted = YES;
        __weak typeof(self) weakSelf = self;
        __weak YTVVideoWarmEntry *weakEntry = entry;
        [entry.bufferingPlayer prerollAtRate:0.0 completionHandler:^(BOOL finished) {
            __strong typeof(weakSelf) self = weakSelf;
            YTVVideoWarmEntry *strongEntry = weakEntry;
            if (!self || !strongEntry || !strongEntry.isDeepTarget) {
                return;
            }
            strongEntry.bufferingPrerollFinished = finished;
            if (!finished) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self ytv_resolveDeepWarmStateForEntry:strongEntry];
            });
        }];
        return;
    }
    if (!entry.bufferingPrerollFinished) {
        return;
    }
    BOOL bufferedEnough = NO;
    NSArray *ranges = item.loadedTimeRanges;
    if ([ranges isKindOfClass:[NSArray class]] && ranges.count > 0) {
        CMTimeRange tr = [[ranges firstObject] CMTimeRangeValue];
        NSTimeInterval start = CMTimeGetSeconds(tr.start);
        NSTimeInterval dur = CMTimeGetSeconds(tr.duration);
        if (isfinite(start) && isfinite(dur) && (start + dur) >= kYTVWarmBufferedGoalSeconds) {
            bufferedEnough = YES;
        }
    }
    if (!bufferedEnough && item.playbackLikelyToKeepUp) {
        bufferedEnough = YES;
    }
    if (!bufferedEnough) {
        return;
    }
    entry.state = YTVVideoWarmEntryStateBufferedReady;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context == kYTVWarmItemStatusContext || context == kYTVWarmItemLoadedTimeRangesContext) {
        YTVVideoWarmEntry *entry = [self ytv_entryForPlayerItem:(AVPlayerItem *)object];
        [self ytv_resolveDeepWarmStateForEntry:entry];
        return;
    }
    if (context == kYTVWarmPlayerStatusContext) {
        YTVVideoWarmEntry *entry = [self ytv_entryForPlayer:(AVPlayer *)object];
        [self ytv_resolveDeepWarmStateForEntry:entry];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (nullable YTVVideoWarmEntry *)ytv_entryForPlayerItem:(AVPlayerItem *)playerItem {
    if (!playerItem) {
        return nil;
    }
    for (YTVVideoWarmEntry *entry in self.warmByVideoId.allValues) {
        if (entry.playerItem == playerItem || entry.bufferingItem == playerItem) {
            return entry;
        }
    }
    return nil;
}

- (nullable YTVVideoWarmEntry *)ytv_entryForPlayer:(AVPlayer *)player {
    if (!player) {
        return nil;
    }
    for (YTVVideoWarmEntry *entry in self.warmByVideoId.allValues) {
        if (entry.bufferingPlayer == player) {
            return entry;
        }
    }
    return nil;
}

- (nullable NSString *)ytv_nextLRUEvictVideoIdSkippingProtectedWindow {
    NSString *protectedVideoId = self.protectedPlaybackVideoId;
    for (NSString *videoId in self.warmAccessOrder) {
        if (protectedVideoId.length > 0 && [videoId isEqualToString:protectedVideoId]) {
            continue;
        }
        if ([self.preservedWarmVideoIds containsObject:videoId]) {
            continue;
        }
        return videoId;
    }
    for (NSString *videoId in self.warmAccessOrder) {
        if (protectedVideoId.length > 0 && [videoId isEqualToString:protectedVideoId]) {
            continue;
        }
        return videoId;
    }
    return nil;
}

@end
