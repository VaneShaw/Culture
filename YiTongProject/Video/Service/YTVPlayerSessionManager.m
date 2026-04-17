//
//  YTVPlayerSessionManager.m
//  YiTongProject
//

#import "YTVPlayerSessionManager.h"
#import "AudioManager.h"
#import "MediaPlayManager.h"
#import <AVFoundation/AVFoundation.h>

static void *kYTVPlayerItemStatusContext = &kYTVPlayerItemStatusContext;
static void *kYTVPlayerLayerReadyForDisplayContext = &kYTVPlayerLayerReadyForDisplayContext;
static void *kYTVStandbyPlayerItemStatusContext = &kYTVStandbyPlayerItemStatusContext;
static void *kYTVStandbyPlayerItemLoadedTimeRangesContext = &kYTVStandbyPlayerItemLoadedTimeRangesContext;
static void *kYTVStandbyPlayerStatusContext = &kYTVStandbyPlayerStatusContext;
static const NSTimeInterval kYTVStandbyBufferGoalSeconds = 0.35;
static const NSTimeInterval kYTVForegroundStartBufferSeconds = 0.15;
static const NSTimeInterval kYTVForegroundSteadyBufferSeconds = 2.8;
static const NSTimeInterval kYTVForegroundStallRecoveryBufferSeconds = 4.0;

@interface YTVPlayerSessionManager ()
@property (nonatomic, strong, readwrite) AVPlayer *player;
@property (nonatomic, assign, readwrite) NSUInteger currentRequestId;
@property (nonatomic, strong, nullable) AVPlayerItem *observedItem;
@property (nonatomic, weak, nullable) AVPlayerLayer *observedPlayerLayer;
@property (nonatomic, copy, nullable) void (^pendingReadyCompletion)(NSError * _Nullable error);
@property (nonatomic, assign) NSUInteger pendingReadyRequestId;
@property (nonatomic, assign) NSUInteger firstFrameRequestId;
@property (nonatomic, assign) BOOL firstFrameDeliveredForCurrentRequest;
@property (nonatomic, strong) NSDate *currentReplaceStartDate;
@property (nonatomic, strong) AVPlayer *standbyPlayer;
@property (nonatomic, strong, nullable) AVPlayerItem *standbyObservedItem;
@property (nonatomic, copy, nullable) NSString *standbyURLString;
@property (nonatomic, copy, nullable) void (^standbyReadyCompletion)(BOOL ready, NSError * _Nullable error);
@property (nonatomic, assign) BOOL standbyReady;
@property (nonatomic, assign) BOOL standbyPrerollStarted;
@property (nonatomic, assign) BOOL standbyPrerollFinished;
@property (nonatomic, assign) NSUInteger standbyGeneration;
@end

@implementation YTVPlayerSessionManager

- (void)ytv_prepareForegroundPlayerForAggressiveStartup {
    self.player.automaticallyWaitsToMinimizeStalling = NO;
}

- (void)ytv_applyMinimumForwardBufferDuration:(NSTimeInterval)duration toPlayerItem:(AVPlayerItem *)item {
    if (!item) {
        return;
    }
    item.preferredForwardBufferDuration = MAX(item.preferredForwardBufferDuration, MAX(duration, 0.05));
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _foregroundBufferDuration = kYTVForegroundStartBufferSeconds;
        _standbyBufferGoalDuration = kYTVStandbyBufferGoalSeconds;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ytv_handleAppDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    @try {
        [_standbyPlayer removeObserver:self forKeyPath:@"status" context:kYTVStandbyPlayerStatusContext];
    } @catch (__unused NSException *e) {
    }
    [self clearPlayback];
}

- (void)ytv_handleAppDidEnterBackground {
    [self pause];
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        _player.automaticallyWaitsToMinimizeStalling = NO;
    }
    return _player;
}

- (AVPlayer *)standbyPlayer {
    if (!_standbyPlayer) {
        _standbyPlayer = [[AVPlayer alloc] init];
        _standbyPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        _standbyPlayer.automaticallyWaitsToMinimizeStalling = YES;
        [_standbyPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:kYTVStandbyPlayerStatusContext];
    }
    return _standbyPlayer;
}

- (void)replacePlaybackWithURL:(NSURL *)url completion:(void (^)(NSError * _Nullable))completion {
    [self replacePlaybackWithURL:url preferredPrewarmedPlayerItem:nil playerLayer:nil completion:completion];
}

/// 替换播放资源并同时绑定首帧观察层；completion 仅表示 item 已 ready 或失败。
- (NSUInteger)replacePlaybackWithURL:(NSURL *)url
          preferredPrewarmedPlayerItem:(AVPlayerItem *)prewarmedItem
                            playerLayer:(AVPlayerLayer *)playerLayer
                             completion:(void (^)(NSError * _Nullable))completion {
    if (!url) {
        if (completion) {
            NSError *err = [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"URL is nil"}];
            completion(err);
        }
        return 0;
    }
    AVPlayerItem *item = nil;
    if ([prewarmedItem isKindOfClass:[AVPlayerItem class]]) {
        AVAsset *asset = prewarmedItem.asset;
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            NSURL *assetURL = [(AVURLAsset *)asset URL];
            if (assetURL && [assetURL.absoluteString isEqualToString:url.absoluteString]) {
                item = prewarmedItem;
            }
        }
    }
    if (!item) {
        item = [[AVPlayerItem alloc] initWithURL:url];
    }
    [self ytv_prepareForegroundPlayerForAggressiveStartup];
    [self ytv_applyMinimumForwardBufferDuration:self.foregroundBufferDuration toPlayerItem:item];
    self.currentRequestId += 1;
    NSUInteger requestId = self.currentRequestId;
    self.currentReplaceStartDate = [NSDate date];
    self.firstFrameDeliveredForCurrentRequest = NO;
    [self clearStandbyPlayback];
    [self ytv_bindPlayerLayerForFirstFrameObservation:playerLayer requestId:requestId];
    [self ytv_installObservedPlayerItem:item requestId:requestId completion:completion];
    return requestId;
}

- (void)prepareStandbyPlaybackWithURL:(NSURL *)url
               preferredPlayerItem:(AVPlayerItem *)prewarmedItem
                         completion:(void (^)(BOOL ready, NSError * _Nullable error))completion {
    if (!url) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"YTVPlayerSessionManager" code:-11 userInfo:@{NSLocalizedDescriptionKey: @"standby URL is nil"}]);
        }
        return;
    }
    NSString *u = url.absoluteString ?: @"";
    if (u.length == 0) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"YTVPlayerSessionManager" code:-12 userInfo:@{NSLocalizedDescriptionKey: @"standby URL string empty"}]);
        }
        return;
    }
    if (self.standbyReady && [self.standbyURLString isEqualToString:u] && self.standbyObservedItem) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    AVPlayerItem *item = nil;
    if ([prewarmedItem isKindOfClass:[AVPlayerItem class]]) {
        AVAsset *asset = prewarmedItem.asset;
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            NSURL *assetURL = [(AVURLAsset *)asset URL];
            if (assetURL && [assetURL.absoluteString isEqualToString:u]) {
                // 候场与前台不可共享同一个 AVPlayerItem；这里只复用同源 asset，重新创建 item。
                item = [AVPlayerItem playerItemWithAsset:asset];
            }
        }
    }
    if (!item) {
        item = [[AVPlayerItem alloc] initWithURL:url];
    }
    item.preferredForwardBufferDuration = MAX(item.preferredForwardBufferDuration, 1.2);
    if (self.standbyObservedItem && [self.standbyURLString isEqualToString:u]) {
        self.standbyReadyCompletion = completion;
        [self ytv_resolveStandbyStateForItem:self.standbyObservedItem generation:self.standbyGeneration];
        return;
    }
    self.standbyGeneration += 1;
    self.standbyReady = NO;
    self.standbyPrerollStarted = NO;
    self.standbyPrerollFinished = NO;
    self.standbyURLString = u;
    self.standbyReadyCompletion = completion;
    [self ytv_installStandbyObservedItem:item generation:self.standbyGeneration];
}

- (BOOL)hasStandbyPlaybackMatchingURL:(NSURL *)url {
    NSString *u = url.absoluteString ?: @"";
    return u.length > 0 && self.standbyReady && [self.standbyURLString isEqualToString:u] && self.standbyObservedItem != nil;
}

- (BOOL)standbyPlaybackReadyForURL:(NSURL *)url {
    return [self hasStandbyPlaybackMatchingURL:url];
}

- (NSUInteger)promoteStandbyPlaybackMatchingURL:(NSURL *)url
                                     playerLayer:(AVPlayerLayer *)playerLayer
                                      completion:(void (^)(NSError * _Nullable error))completion {
    return [self promoteStandbyPlaybackByRebuildingItemMatchingURL:url playerLayer:playerLayer completion:completion];
}

- (NSUInteger)promoteStandbyPlaybackByRebuildingItemMatchingURL:(NSURL *)url
                                                    playerLayer:(AVPlayerLayer *)playerLayer
                                                     completion:(void (^)(NSError * _Nullable error))completion {
    if (![self hasStandbyPlaybackMatchingURL:url]) {
        return 0;
    }
    AVPlayerItem *standbyItem = self.standbyObservedItem;
    AVPlayerItem *item = nil;
    if ([standbyItem.asset isKindOfClass:[AVURLAsset class]]) {
        NSURL *assetURL = [(AVURLAsset *)standbyItem.asset URL];
        if (assetURL && [assetURL.absoluteString isEqualToString:(url.absoluteString ?: @"")]) {
            item = [AVPlayerItem playerItemWithAsset:standbyItem.asset];
        }
    }
    if (!item) {
        item = [[AVPlayerItem alloc] initWithURL:url];
    }
    [self ytv_prepareForegroundPlayerForAggressiveStartup];
    [self ytv_applyMinimumForwardBufferDuration:self.foregroundBufferDuration toPlayerItem:item];
    self.currentRequestId += 1;
    NSUInteger requestId = self.currentRequestId;
    self.currentReplaceStartDate = [NSDate date];
    self.firstFrameDeliveredForCurrentRequest = NO;
    [self clearStandbyPlayback];
    [self ytv_bindPlayerLayerForFirstFrameObservation:playerLayer requestId:requestId];
    [self ytv_installObservedPlayerItem:item requestId:requestId completion:completion];
    return requestId;
}

- (void)clearStandbyPlayback {
    [self ytv_removeStandbyItemObservers];
    self.standbyURLString = nil;
    self.standbyReadyCompletion = nil;
    self.standbyReady = NO;
    self.standbyPrerollStarted = NO;
    self.standbyPrerollFinished = NO;
    [self.standbyPlayer pause];
    [self.standbyPlayer replaceCurrentItemWithPlayerItem:nil];
}

- (void)promoteCurrentPlaybackToSteadyState {
    AVPlayerItem *item = self.player.currentItem;
    if (!item) {
        return;
    }
    self.player.automaticallyWaitsToMinimizeStalling = YES;
    [self ytv_applyMinimumForwardBufferDuration:kYTVForegroundSteadyBufferSeconds toPlayerItem:item];
}

- (void)recoverCurrentPlaybackAfterStall {
    AVPlayerItem *item = self.player.currentItem;
    if (!item) {
        return;
    }
    self.player.automaticallyWaitsToMinimizeStalling = YES;
    [self ytv_applyMinimumForwardBufferDuration:kYTVForegroundStallRecoveryBufferSeconds toPlayerItem:item];
    [self.player play];
}

- (void)bindPlayerLayerForFirstFrameObservation:(AVPlayerLayer *)playerLayer {
    [self ytv_bindPlayerLayerForFirstFrameObservation:playerLayer requestId:self.currentRequestId];
}

/// 绑定当前渲染层，readyForDisplay 仅对当前 request 生效。
- (void)ytv_bindPlayerLayerForFirstFrameObservation:(AVPlayerLayer *)playerLayer requestId:(NSUInteger)requestId {
    [self ytv_removeFirstFrameObserver];
    self.observedPlayerLayer = playerLayer;
    self.firstFrameRequestId = requestId;
    if (!playerLayer) {
        return;
    }
    [playerLayer addObserver:self
                  forKeyPath:@"readyForDisplay"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:kYTVPlayerLayerReadyForDisplayContext];
}

/// 安装 item 观察者并记录当前 request，对旧回调做隔离。
- (void)ytv_installObservedPlayerItem:(AVPlayerItem *)item requestId:(NSUInteger)requestId completion:(void (^)(NSError * _Nullable))completion {
    [self ytv_removeItemObservers];
    self.pendingReadyCompletion = completion;
    self.pendingReadyRequestId = requestId;
    self.observedItem = item;
    [item addObserver:self
           forKeyPath:@"status"
              options:NSKeyValueObservingOptionNew
              context:kYTVPlayerItemStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ytv_itemFailedToPlay:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ytv_itemDidPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:item];
    [self.player replaceCurrentItemWithPlayerItem:item];
    [self ytv_resolvePendingIfTerminalStatusForItem:item];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context == kYTVPlayerItemStatusContext) {
        [self ytv_resolvePendingIfTerminalStatusForItem:(AVPlayerItem *)object];
        return;
    }
    if (context == kYTVStandbyPlayerItemStatusContext) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        if (item == self.standbyObservedItem) {
            if (item.status == AVPlayerItemStatusReadyToPlay) {
            }
        }
        [self ytv_resolveStandbyStateForItem:item];
        return;
    }
    if (context == kYTVStandbyPlayerItemLoadedTimeRangesContext) {
        [self ytv_resolveStandbyStateForItem:(AVPlayerItem *)object];
        return;
    }
    if (context == kYTVStandbyPlayerStatusContext) {
        if (self.standbyObservedItem) {
            if (self.standbyPlayer.status == AVPlayerStatusReadyToPlay) {
            }
        }
        [self ytv_resolveStandbyStateForItem:self.standbyObservedItem];
        return;
    }
    if (context == kYTVPlayerLayerReadyForDisplayContext) {
        [self ytv_handleReadyForDisplayChanged:(AVPlayerLayer *)object];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

/// 渲染层真正 readyForDisplay 后再发首帧事件，避免 ReadyToPlay 过早揭封面。
- (void)ytv_handleReadyForDisplayChanged:(AVPlayerLayer *)playerLayer {
    if (!playerLayer || playerLayer != self.observedPlayerLayer) {
        return;
    }
    if (!playerLayer.readyForDisplay || self.firstFrameDeliveredForCurrentRequest) {
        return;
    }
    self.firstFrameDeliveredForCurrentRequest = YES;
    [self ytv_emitEvent:YTVPlayerSessionEventTypeFirstFrameRendered requestId:self.firstFrameRequestId error:nil];
}

/// 在 status 已达 Ready/Failed 时触发一次性 completion
- (void)ytv_resolvePendingIfTerminalStatusForItem:(AVPlayerItem *)item {
    if (!item || item != self.observedItem) {
        return;
    }
    switch (item.status) {
        case AVPlayerItemStatusReadyToPlay:
            [self ytv_emitEvent:YTVPlayerSessionEventTypeItemReady requestId:self.pendingReadyRequestId error:nil];
            [self ytv_deliverPendingWithError:nil];
            break;
        case AVPlayerItemStatusFailed: {
            NSError *err = item.error ?: [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                                             code:-2
                                                         userInfo:@{NSLocalizedDescriptionKey: @"AVPlayerItem failed"}];
            [self ytv_emitEvent:YTVPlayerSessionEventTypePlayFailed requestId:self.pendingReadyRequestId error:err];
            [self ytv_deliverPendingWithError:err];
            break;
        }
        default:
            break;
    }
}

- (void)ytv_deliverPendingWithError:(NSError *)error {
    void (^block)(NSError *) = self.pendingReadyCompletion;
    self.pendingReadyCompletion = nil;
    self.pendingReadyRequestId = 0;
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block(error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(error);
        });
    }
}

- (void)ytv_itemFailedToPlay:(NSNotification *)note {
    NSError *err = note.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    NSError *out = err ?: [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                              code:-3
                                          userInfo:@{NSLocalizedDescriptionKey: @"Playback failed"}];
    [self ytv_emitEvent:YTVPlayerSessionEventTypePlayFailed requestId:self.pendingReadyRequestId ?: self.currentRequestId error:out];
    if (self.pendingReadyCompletion) {
        [self ytv_deliverPendingWithError:out];
    }
}

/// 单条视频播放结束后自动回到开头继续播，保持短视频循环体验。
- (void)ytv_itemDidPlayToEnd:(NSNotification *)note {
    AVPlayerItem *item = note.object;
    if (!item || item != self.observedItem) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [item seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !finished || item != self.observedItem) {
            return;
        }
        [self.player play];
    }];
}

/// 当前切源启动到现在的耗时，便于观察 item ready 与首帧的差距。
- (NSTimeInterval)ytv_elapsedMillisecondsSinceCurrentReplaceStart {
    if (!self.currentReplaceStartDate) {
        return 0;
    }
    return [[NSDate date] timeIntervalSinceDate:self.currentReplaceStartDate] * 1000.0;
}

/// 将播放事件统一派发到主线程，供 VC 校验 requestId 后更新 UI。
- (void)ytv_emitEvent:(YTVPlayerSessionEventType)eventType requestId:(NSUInteger)requestId error:(NSError *)error {
    YTVPlayerSessionEventHandler handler = self.eventHandler;
    if (!handler || requestId == 0) {
        return;
    }
    if ([NSThread isMainThread]) {
        handler(eventType, requestId, error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(eventType, requestId, error);
        });
    }
}

- (void)ytv_removeItemObservers {
    if (_observedItem) {
        @try {
            [_observedItem removeObserver:self forKeyPath:@"status" context:kYTVPlayerItemStatusContext];
        } @catch (__unused NSException *e) {
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                      object:_observedItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_observedItem];
        _observedItem = nil;
    }
}

- (void)ytv_removeFirstFrameObserver {
    if (_observedPlayerLayer) {
        @try {
            [_observedPlayerLayer removeObserver:self forKeyPath:@"readyForDisplay" context:kYTVPlayerLayerReadyForDisplayContext];
        } @catch (__unused NSException *e) {
        }
        _observedPlayerLayer = nil;
    }
    self.firstFrameRequestId = 0;
}

- (void)play {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StopAudioPlayerNotification" object:nil];
    [[AudioManager sharedManager] pausePlayback];
    [[MediaPlayManager sharedManager] stopCurrentVideo];
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                           error:&sessionError];
    if (!sessionError) {
        [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    }
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)clearPlayback {
    [self clearStandbyPlayback];
    [self ytv_removeItemObservers];
    [self ytv_removeFirstFrameObserver];
    self.pendingReadyCompletion = nil;
    self.pendingReadyRequestId = 0;
    self.firstFrameDeliveredForCurrentRequest = NO;
    self.currentReplaceStartDate = nil;
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

- (void)ytv_installStandbyObservedItem:(AVPlayerItem *)item generation:(NSUInteger)generation {
    [self ytv_removeStandbyItemObservers];
    self.standbyObservedItem = item;
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:kYTVStandbyPlayerItemStatusContext];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:kYTVStandbyPlayerItemLoadedTimeRangesContext];
    [self.standbyPlayer replaceCurrentItemWithPlayerItem:item];
    [self.standbyPlayer pause];
    [self ytv_resolveStandbyStateForItem:item generation:generation];
}

/// 候场预热要等 item 先 ReadyToPlay，再触发 preroll；否则 AVPlayer 会在主线程抛断言。
- (void)ytv_resolveStandbyStateForItem:(AVPlayerItem *)item {
    [self ytv_resolveStandbyStateForItem:item generation:self.standbyGeneration];
}

- (void)ytv_resolveStandbyStateForItem:(AVPlayerItem *)item generation:(NSUInteger)generation {
    if (!item || item != self.standbyObservedItem || self.standbyReady || generation != self.standbyGeneration) {
        return;
    }
    if (item.status == AVPlayerItemStatusFailed) {
        NSError *err = item.error ?: [NSError errorWithDomain:@"YTVPlayerSessionManager" code:-14 userInfo:@{NSLocalizedDescriptionKey: @"standby item failed"}];
        [self ytv_deliverStandbyReady:NO error:err];
        return;
    }
    if (item.status != AVPlayerItemStatusReadyToPlay) {
        return;
    }
    if (self.standbyPlayer.status == AVPlayerStatusFailed) {
        NSError *playerError = self.standbyPlayer.error ?: [NSError errorWithDomain:@"YTVPlayerSessionManager" code:-15 userInfo:@{NSLocalizedDescriptionKey: @"standby player failed"}];
        [self ytv_deliverStandbyReady:NO error:playerError];
        return;
    }
    if (self.standbyPlayer.status != AVPlayerStatusReadyToPlay) {
        return;
    }
    if (!self.standbyPrerollStarted) {
        self.standbyPrerollStarted = YES;
        __weak typeof(self) weakSelf = self;
        [self.standbyPlayer prerollAtRate:0.0 completionHandler:^(BOOL finished) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || generation != self.standbyGeneration) {
                return;
            }
            self.standbyPrerollFinished = finished;
            if (!finished) {
                [self ytv_deliverStandbyReady:NO error:[NSError errorWithDomain:@"YTVPlayerSessionManager" code:-13 userInfo:@{NSLocalizedDescriptionKey: @"standby preroll cancelled"}]];
                return;
            }
            [self ytv_resolveStandbyStateForItem:item generation:generation];
        }];
        return;
    }
    BOOL bufferedEnough = NO;
    NSArray *ranges = item.loadedTimeRanges;
    if ([ranges isKindOfClass:[NSArray class]] && ranges.count > 0) {
        CMTimeRange tr = [[ranges firstObject] CMTimeRangeValue];
        NSTimeInterval start = CMTimeGetSeconds(tr.start);
        NSTimeInterval dur = CMTimeGetSeconds(tr.duration);
        if (isfinite(start) && isfinite(dur) && (start + dur) >= self.standbyBufferGoalDuration) {
            bufferedEnough = YES;
        }
    }
    if (!bufferedEnough && item.playbackLikelyToKeepUp) {
        bufferedEnough = YES;
    }
    if (!bufferedEnough) {
        return;
    }
    self.standbyReady = YES;
    [self ytv_deliverStandbyReady:YES error:nil];
}

- (void)ytv_deliverStandbyReady:(BOOL)ready error:(NSError *)error {
    void (^block)(BOOL, NSError *) = self.standbyReadyCompletion;
    self.standbyReadyCompletion = nil;
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block(ready, error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(ready, error);
        });
    }
}

- (void)ytv_removeStandbyItemObservers {
    if (_standbyObservedItem) {
        @try {
            [_standbyObservedItem removeObserver:self forKeyPath:@"status" context:kYTVStandbyPlayerItemStatusContext];
        } @catch (__unused NSException *e) {
        }
        @try {
            [_standbyObservedItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:kYTVStandbyPlayerItemLoadedTimeRangesContext];
        } @catch (__unused NSException *e) {
        }
        _standbyObservedItem = nil;
    }
}

@end
