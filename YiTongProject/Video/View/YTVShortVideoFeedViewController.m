//
//  YTVShortVideoFeedViewController.m
//  YiTongProject
//

#import "YTVShortVideoFeedViewController.h"
#import "YTVShortVideoFeedViewModel.h"
#import "YTVShortVideoCell.h"
#import "YTVVideoRenderView.h"
#import "YTVPlayerSessionManager.h"
#import "YTVVideoFeedItem.h"
#import "YTVVideoPreloadManager.h"
#import "YTVVideoCacheProxyManager.h"
#import "VideoTextWebViewController.h"
#import "YTVVideoPRDShareHelper.h"
#import "HeaderConfig.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>

#define YTVFeedWrapLog(...)

static NSString * const kYTVShortVideoCellId = @"YTVShortVideoCell";
static NSString * const kYTVPlaybackPerfLogPrefix = @"[YTVPlaybackPerf]";
static const NSTimeInterval kYTVPlaybackInstantStartThresholdSeconds = 0.5;
static const NSTimeInterval kYTVPlaybackStallLogThresholdSeconds = 0.2;
static const NSTimeInterval kYTVStartupPrimePollIntervalSeconds = 0.04;
static const NSTimeInterval kYTVStartupPrimeMaxWaitSeconds = 0.90;
static const CGFloat kYTVStartupScrollLockCorrectionThreshold = 1.0;
static const NSTimeInterval kYTVFirstFrameProbeDelayShortSeconds = 0.25;
static const NSTimeInterval kYTVFirstFrameProbeDelayLongSeconds = 0.90;
static void *kYTVPlaybackPlayerTimeControlStatusContext = &kYTVPlaybackPlayerTimeControlStatusContext;
/// 内联全屏：在窗口 safeArea 基础上再保证的最小留白（返回与进度条左对齐）
static const CGFloat kYTVInlineFullscreenHostChromeInset = 16.0;

/// 将 overlay 四边到 window 安全矩形的最小距离换算为内边距（含 stage 旋转；用坐标转换，不依赖 overlay.safeArea）
static UIEdgeInsets YTVInlineFullscreenChromeInsetsMatchingWindowSafeArea(UIView *overlay, UIWindow *win) {
    UIEdgeInsets m = UIEdgeInsetsZero;
    if (!overlay || !win || CGRectIsEmpty(overlay.bounds)) {
        return m;
    }
    CGRect b = overlay.bounds;
    UIEdgeInsets si = win.safeAreaInsets;
    CGSize ws = win.bounds.size;
    CGRect safeRect = CGRectMake(si.left, si.top, ws.width - si.left - si.right, ws.height - si.top - si.bottom);
    CGFloat midX = CGRectGetMidX(b);
    CGFloat midY = CGRectGetMidY(b);
    CGFloat H = CGRectGetHeight(b);
    CGFloat W = CGRectGetWidth(b);
    if (H < 1.0 || W < 1.0) {
        return m;
    }
    BOOL (^inSafe)(CGPoint) = ^BOOL(CGPoint pInOverlay) {
        CGPoint pw = [overlay convertPoint:pInOverlay toView:win];
        return CGRectContainsPoint(safeRect, pw);
    };
    CGFloat lo, hi, mid;
    lo = 0;
    hi = H;
    for (NSInteger i = 0; i < 22; i++) {
        mid = (lo + hi) * 0.5f;
        if (inSafe(CGPointMake(midX, CGRectGetMinY(b) + mid))) {
            hi = mid;
        } else {
            lo = mid;
        }
    }
    m.top = (CGFloat)ceil((double)hi);
    lo = 0;
    hi = W;
    for (NSInteger i = 0; i < 22; i++) {
        mid = (lo + hi) * 0.5f;
        if (inSafe(CGPointMake(CGRectGetMinX(b) + mid, midY))) {
            hi = mid;
        } else {
            lo = mid;
        }
    }
    m.left = (CGFloat)ceil((double)hi);
    lo = 0;
    hi = H;
    for (NSInteger i = 0; i < 22; i++) {
        mid = (lo + hi) * 0.5f;
        if (inSafe(CGPointMake(midX, CGRectGetMaxY(b) - mid))) {
            hi = mid;
        } else {
            lo = mid;
        }
    }
    m.bottom = (CGFloat)ceil((double)hi);
    lo = 0;
    hi = W;
    for (NSInteger i = 0; i < 22; i++) {
        mid = (lo + hi) * 0.5f;
        if (inSafe(CGPointMake(CGRectGetMaxX(b) - mid, midY))) {
            hi = mid;
        } else {
            lo = mid;
        }
    }
    m.right = (CGFloat)ceil((double)hi);
    for (NSInteger k = 0; k < 48; k++) {
        CGPoint corner = CGPointMake(CGRectGetMinX(b) + m.left, CGRectGetMinY(b) + m.top);
        if (inSafe(corner)) {
            break;
        }
        m.left += 1.f;
        m.top += 1.f;
    }
    m.left = MAX(m.left, kYTVInlineFullscreenHostChromeInset);
    m.bottom = MAX(m.bottom, kYTVInlineFullscreenHostChromeInset);
    m.right = MAX(m.right, kYTVInlineFullscreenHostChromeInset);
    return m;
}

static BOOL YTVInlineFullscreenEdgeInsetsAlmostEqual(UIEdgeInsets a, UIEdgeInsets b) {
    return fabs(a.top - b.top) < 0.5 && fabs(a.left - b.left) < 0.5 && fabs(a.bottom - b.bottom) < 0.5 && fabs(a.right - b.right) < 0.5;
}

/// 内联全屏时间展示：00:00（分:秒）
static NSString *YTVInlineFullscreenFormatMinuteSecond(Float64 seconds) {
    if (!isfinite(seconds) || seconds < 0) {
        seconds = 0;
    }
    long long total = (long long)llround(seconds);
    long long m = total / 60;
    long long s = total % 60;
    return [NSString stringWithFormat:@"%02lld:%02lld", m, s];
}

typedef NS_ENUM(NSInteger, YTVFeedPlaybackState) {
    YTVFeedPlaybackStateIdle = 0,
    YTVFeedPlaybackStateSwitching,
    YTVFeedPlaybackStatePlaying,
    YTVFeedPlaybackStateStandbyPreparing,
    YTVFeedPlaybackStateFailed,
};

@interface YTVShortVideoFeedViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching>
@property (nonatomic, copy, readwrite) NSString *categoryKey;
@property (nonatomic, assign) BOOL ytv_isFavoritesFeed;
@property (nonatomic, copy) NSArray *favoritesSeedItems;
@property (nonatomic, copy, nullable) NSString *favoritesEntryVideoId;
@property (nonatomic, assign) BOOL ytv_categoryFeedActive;
@property (nonatomic, assign) BOOL ytv_bootstrapStarted;
@property (nonatomic, strong) YTVShortVideoFeedViewModel *feedViewModel;
@property (nonatomic, strong) YTVPlayerSessionManager *playerSession;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *stateOverlay;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, assign) NSInteger currentPlayIndex;
@property (nonatomic, strong) YTVVideoPreloadManager *preloadManager;
@property (nonatomic, copy, nullable) NSString *ytv_currentPlaybackSourceLabel;
@property (nonatomic, assign) CFTimeInterval ytv_currentPlaybackStartTime;
@property (nonatomic, assign) CFTimeInterval ytv_currentPlaybackReplaceStartTime;
@property (nonatomic, assign) CFTimeInterval ytv_currentPlaybackItemReadyTime;
@property (nonatomic, assign) CFTimeInterval ytv_currentPlaybackFirstFrameTime;
@property (nonatomic, strong, nullable) NSURL *ytv_currentPlaybackResolvedURL;
@property (nonatomic, assign) BOOL ytv_currentPlaybackResolvedURLIsLocal;
@property (nonatomic, assign) unsigned long long ytv_currentPlaybackResolvedFileBytes;
@property (nonatomic, assign) BOOL ytv_currentPlaybackUsedPreferredItem;
@property (nonatomic, assign) BOOL ytv_currentPlaybackStartedWithStartupGate;
@property (nonatomic, assign) BOOL ytv_pendingFeedReloadAligningToActivePlayback;
@property (nonatomic, copy, nullable) NSString *pendingDeepLinkVideoId;
@property (nonatomic, strong) UIImageView *stateEmptyImageView;
@property (nonatomic, strong) UIView *nextLoadFailureBar;
@property (nonatomic, strong) UILabel *nextLoadFailureLabel;
@property (nonatomic, strong) UIButton *nextLoadFailureRetryButton;
/// 在「末条触发的补页」已结束且当前仍停在末条、列表条数未增加时置 YES（含请求失败或成功但无新条/全去重）；用于接口仍标 hasMore 时也能回绕，且不会在列表中段补货误判。
@property (nonatomic, assign) BOOL ytv_allowWrapFromLastAfterTailFetchIdle;
/// `scrollViewWillEndDragging` 中已判定应回绕到首条，但 paging 可能忽略 `targetContentOffset` 时在减速结束再强制对齐。
@property (nonatomic, assign) BOOL ytv_pendingManualWrapToHead;
/// 用户点击画面暂停后为 YES，中央显示播放图标；切条或代码里 `play` 后清 NO
@property (nonatomic, assign) BOOL ytv_userPausedWithPlayHint;
/// 跟手滚动时上次已预热的「预计落屏」索引，避免 `scrollViewDidScroll` 重复刷池
@property (nonatomic, assign) NSInteger ytv_lastProvisionalWarmIndex;
@property (nonatomic, assign) NSInteger ytv_lastProvisionalWarmVelocityBucket;
/// 首次进页/首帧未出前，暂停非关键 warm，避免多条并发抢首播带宽。
@property (nonatomic, assign) BOOL ytv_deferNonCriticalWarmUntilFirstFrame;
/// 当前候场的下一条索引；用于前滑秒开候场命中。
@property (nonatomic, assign) NSInteger ytv_standbyTargetIndex;
/// 当前待完成播放绑定的索引；切换中用于过滤旧回调。
@property (nonatomic, assign) NSInteger ytv_pendingBindIndex;
/// 切源中为 YES，首帧/失败后复位。
@property (nonatomic, assign) BOOL ytv_isSwitchingPlayback;
@property (nonatomic, assign) YTVFeedPlaybackState ytv_playbackState;
/// 当前索引已拿到首帧，用于同 URL 复绑时立即揭封面。
@property (nonatomic, assign) BOOL ytv_currentPlaybackFirstFrameReady;
/// 当前绑定对应的播放器 requestId；只响应同一次切源回调。
@property (nonatomic, assign) NSUInteger ytv_pendingPlaybackRequestId;
@property (nonatomic, copy, nullable) NSString *ytv_pendingPlaybackURLString;
@property (nonatomic, assign) BOOL ytv_currentPlaybackFromBootstrapRestore;
@property (nonatomic, assign) BOOL ytv_perfObserversInstalled;
@property (nonatomic, assign) BOOL ytv_perfSessionActive;
@property (nonatomic, copy, nullable) NSString *ytv_perfSessionVideoId;
@property (nonatomic, assign) NSInteger ytv_perfSessionIndex;
@property (nonatomic, assign) CFTimeInterval ytv_perfPlaySegmentStartTime;
@property (nonatomic, assign) CFTimeInterval ytv_perfStallStartTime;
@property (nonatomic, assign) NSTimeInterval ytv_perfAccumulatedPlayDuration;
@property (nonatomic, assign) NSTimeInterval ytv_perfAccumulatedStallDuration;
@property (nonatomic, assign) NSUInteger ytv_perfStallCount;
@property (nonatomic, assign) NSInteger ytv_pendingStartupPrimePlaybackIndex;
@property (nonatomic, assign) NSUInteger ytv_pendingStartupPrimePlaybackToken;
@property (nonatomic, assign) BOOL ytv_startupScrollLockEnabled;
@property (nonatomic, strong, nullable) YTVVideoFeedItem *ytv_startupPresentationItem;
@property (nonatomic, assign) NSInteger ytv_startupPresentationIndex;
/// 抖音式内联全屏：同一 `renderView` 旋转放大，不模态、不 replace item。
@property (nonatomic, assign) BOOL ytv_inlineFullscreenActive;
@property (nonatomic, strong, nullable) UIView *ytv_inlineFullscreenHostView;
@property (nonatomic, weak, nullable) YTVShortVideoCell *ytv_inlineFullscreenSourceCell;
@property (nonatomic, weak, nullable) YTVVideoRenderView *ytv_inlineFullscreenRenderView;
@property (nonatomic, assign) CGRect ytv_inlineFullscreenStartFrameInHost;
/// 承载视频 + 操作蒙层，整体旋转；控件只约束在 overlay 内，勿再锚到 host
@property (nonatomic, strong, nullable) UIView *ytv_inlineFullscreenStageView;
/// 盖在 renderView 上，与 stage 同向旋转；返回/进度条边距由 window safeArea 换算
@property (nonatomic, strong, nullable) UIView *ytv_inlineFullscreenOverlayView;
@property (nonatomic, strong, nullable) UIButton *ytv_inlineFullscreenBackButton;
@property (nonatomic, strong, nullable) UIButton *ytv_inlineFullscreenCenterPlayButton;
@property (nonatomic, strong, nullable) UISlider *ytv_inlineFullscreenProgressSlider;
@property (nonatomic, strong, nullable) UILabel *ytv_inlineFullscreenCurrentTimeLabel;
@property (nonatomic, strong, nullable) UILabel *ytv_inlineFullscreenDurationLabel;
@property (nonatomic, strong, nullable) id ytv_inlineFullscreenTimeObserver;
@property (nonatomic, assign) BOOL ytv_inlineFullscreenScrubbing;
@property (nonatomic, assign) UIEdgeInsets ytv_inlineFullscreenLastAppliedChromeInsets;
/// 为 NO 时不在 layout 回调里改 chrome 边距，避免旋转动画中间帧算错并产生终态跳动
@property (nonatomic, assign) BOOL ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled;
- (void)ytv_updateInlineFullscreenChromeInsetsFromWindowSafeArea;
- (void)ytv_probeNaturalVideoSizeIfNeededForItem:(YTVVideoFeedItem *)item;
- (nullable NSURL *)ytv_assetURLFromPlayURLString:(NSString *)playURL;
- (void)ytv_applyVideoLayoutHintForVideoId:(NSString *)videoId;
- (void)ytv_inlineFullscreenRemoveTimeObserverIfNeeded;
- (void)ytv_inlineFullscreenInstallTimeObserver;
- (void)ytv_inlineFullscreenSyncProgressUIFromPlayer;
- (void)ytv_inlineFullscreenUpdateCenterPlayButtonAppearance;
- (void)ytv_onInlineFullscreenCenterPlayTap;
- (void)ytv_onInlineFullscreenSliderTouchDown;
- (void)ytv_onInlineFullscreenSliderRelease;
- (Float64)ytv_inlineFullscreenDurationSeconds;
- (void)ytv_inlineFullscreenSeekToNormalized:(float)n;
- (void)ytv_inlineFullscreenUpdateTimeLabels;
- (void)ytv_prepareStandbyPlaybackForTargetIndex:(NSInteger)targetIdx;
- (void)ytv_warmAroundProvisionalDisplayIndex:(NSInteger)idx scrollVelocityY:(CGFloat)velocityY;
- (CGFloat)ytv_normalizedScrollVelocityYForScrollView:(UIScrollView *)scrollView pageHeight:(CGFloat)pageHeight;
- (NSInteger)ytv_provisionalWarmVelocityBucketForVelocityY:(CGFloat)velocityY;
- (NSInteger)ytv_predictedExtendedPageForScrollView:(UIScrollView *)scrollView pageHeight:(CGFloat)pageHeight velocityY:(CGFloat)velocityY;
- (BOOL)ytv_shouldDeferNonCriticalStartupWork;
- (NSInteger)ytv_targetIndexMatchingActivePlaybackInCurrentFeed;
- (void)ytv_applyDeferredFeedReloadAligningToActivePlaybackIfNeeded;
- (void)ytv_updateVisibleCellsSwipeDim;
- (void)ytv_refreshVisibleCellsInteractionChrome;
- (void)ytv_onFavoriteChromeTapFromCell:(YTVShortVideoCell *)cell;
- (void)ytv_onShareChromeTapFromCell:(YTVShortVideoCell *)cell;
- (void)ytv_onFullScreenChromeTapFromCell:(YTVShortVideoCell *)cell;
- (void)ytv_onChromeSeeAllTapFromCell:(YTVShortVideoCell *)cell;
- (void)ytv_installPlaybackPerformanceObserversIfNeeded;
- (void)ytv_removePlaybackPerformanceObserversIfNeeded;
- (void)ytv_resetPlaybackPerformanceTrackingForItem:(YTVVideoFeedItem *)item index:(NSInteger)index;
- (void)ytv_finalizePlaybackPerformanceLogIfNeededWithReason:(NSString *)reason error:(nullable NSError *)error;
- (void)ytv_handlePlaybackTimeControlStatusChanged;
- (void)ytv_handlePlaybackStalledNotification:(NSNotification *)notification;
- (void)ytv_beginPlaybackActiveSegmentIfNeeded;
- (void)ytv_endPlaybackActiveSegmentIfNeeded;
- (void)ytv_beginPlaybackStallIfNeededWithReason:(NSString *)reason;
- (void)ytv_endPlaybackStallIfNeededWithReason:(NSString *)reason;
- (void)ytv_updatePlaybackResolvedURLMetadata:(nullable NSURL *)resolvedURL;
- (nullable YTVVideoFeedItem *)ytv_perfSessionItem;
- (NSString *)ytv_perfAssetTypeForItem:(nullable YTVVideoFeedItem *)item;
- (Float64)ytv_perfDurationSecondsForItem:(nullable YTVVideoFeedItem *)item;
- (CGSize)ytv_perfNaturalSizeForItem:(nullable YTVVideoFeedItem *)item;
- (void)ytv_appendPlaybackMaterialInfoToLogLine:(NSMutableString *)line item:(nullable YTVVideoFeedItem *)item;
- (void)ytv_appendPlaybackResolvedLocationToLogLine:(NSMutableString *)line;
- (void)ytv_appendPlaybackRequestFlagsToLogLine:(NSMutableString *)line;
- (NSString *)ytv_playerWaitingReasonLabel;
- (void)ytv_cancelPendingStartupPrimePlayback;
- (BOOL)ytv_scheduleStartupPrimePlaybackIfNeededAtIndex:(NSInteger)index;
- (void)ytv_continueStartupPrimePlaybackPollingWithToken:(NSUInteger)token
                                                   index:(NSInteger)index
                                           bootstrapItem:(YTVVideoFeedItem *)bootstrapItem
                                               startTime:(CFTimeInterval)startTime;
- (void)ytv_applyPlaybackForBootstrapItem:(YTVVideoFeedItem *)item bindIdx:(NSInteger)bindIdx;
- (void)ytv_applyPlaybackForItem:(YTVVideoFeedItem *)item
                         bindIdx:(NSInteger)bindIdx
    preserveStartupPresentation:(BOOL)preserveStartupPresentation;
- (void)ytv_setStartupPresentationItem:(nullable YTVVideoFeedItem *)item index:(NSInteger)index;
- (void)ytv_clearStartupPresentationItem;
- (nullable YTVVideoFeedItem *)ytv_displayItemForDataIndex:(NSInteger)dataIdx;
- (NSInteger)ytv_resolvedFeedIndexForVideoId:(NSString *)videoId
                                      playURL:(NSString *)playURL
                                fallbackIndex:(NSInteger)fallbackIndex;
- (NSInteger)ytv_resolvedFeedIndexForPresentedDataIndex:(NSInteger)dataIdx;
- (void)ytv_scheduleFirstFrameProbeForRequestId:(NSUInteger)requestId index:(NSInteger)index delay:(NSTimeInterval)delay reason:(NSString *)reason;
- (void)ytv_runFirstFrameProbeForRequestId:(NSUInteger)requestId index:(NSInteger)index reason:(NSString *)reason;
- (BOOL)ytv_shouldAllowWrapFromLastToHead;
- (BOOL)ytv_scrollView:(UIScrollView *)scrollView atLastPageWantsNextWithVelocity:(CGPoint)velocity pageHeight:(CGFloat)h maxIndex:(NSInteger)maxIdx;
- (BOOL)ytv_isScrollViewVisuallyOnLastPage:(UIScrollView *)scrollView pageHeight:(CGFloat)h maxIndex:(NSInteger)maxIdx;
/// 是否已滑到当前 `contentSize` 允许的竖直方向尽头（与 ViewModel 条数解耦，避免列表有 16 条但布局高度只够 10 条时永远无法满足 idxPage==maxIdx）
- (BOOL)ytv_scrollViewAtEffectiveVerticalEndForWrap:(UIScrollView *)scrollView;
/// 无更多且≥2 条：首尾各多 1 个重复 cell（末条/首条），形成可双向无限滑的闭环
- (BOOL)ytv_loopRingScrollActive;
/// 环形无更多时预热池须钉住列表头尾，避免在末条邻域预热不到首条导致 wrap 冷启动。
- (BOOL)ytv_shouldPinHeadTailInWarmPool;
- (NSInteger)ytv_collectionDisplayItemCount;
- (CGFloat)ytv_contentOffsetYForRealIndex:(NSInteger)realIdx pageHeight:(CGFloat)h;
- (void)ytv_applyContentOffsetForRealIndex:(NSInteger)realIdx;
- (NSInteger)ytv_collectionItemIndexForRealIndex:(NSInteger)realIdx;
- (NSInteger)ytv_dataItemIndexForCollectionItem:(NSInteger)collectionItem;
- (NSInteger)ytv_realPlaybackIndexFromExtendedPage:(NSInteger)extPage nData:(NSInteger)nData;
@end

@implementation YTVShortVideoFeedViewController

- (instancetype)initWithCategoryKey:(NSString *)categoryKey {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _categoryKey = [categoryKey copy] ?: @"";
        _ytv_isFavoritesFeed = NO;
        _currentPlayIndex = NSNotFound;
        _ytv_lastProvisionalWarmIndex = NSNotFound;
        _ytv_lastProvisionalWarmVelocityBucket = NSNotFound;
        _ytv_deferNonCriticalWarmUntilFirstFrame = NO;
        _ytv_pendingStartupPrimePlaybackIndex = NSNotFound;
        _ytv_startupPresentationIndex = NSNotFound;
        _ytv_pendingBindIndex = NSNotFound;
        _ytv_standbyTargetIndex = NSNotFound;
        _ytv_inlineFullscreenLastAppliedChromeInsets = (UIEdgeInsets){ -999, -999, -999, -999 };
        _ytv_playbackState = YTVFeedPlaybackStateIdle;
    }
    return self;
}

- (instancetype)initWithFavoritesSeedItems:(NSArray *)seedItems entryVideoId:(NSString *)entryVideoId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _ytv_isFavoritesFeed = YES;
        _favoritesSeedItems = [seedItems copy] ?: @[];
        _favoritesEntryVideoId = [entryVideoId copy];
        _categoryKey = @"__favorites__";
        _currentPlayIndex = NSNotFound;
        _ytv_lastProvisionalWarmIndex = NSNotFound;
        _ytv_lastProvisionalWarmVelocityBucket = NSNotFound;
        _ytv_deferNonCriticalWarmUntilFirstFrame = NO;
        _ytv_pendingStartupPrimePlaybackIndex = NSNotFound;
        _ytv_startupPresentationIndex = NSNotFound;
        _ytv_pendingBindIndex = NSNotFound;
        _ytv_standbyTargetIndex = NSNotFound;
        _ytv_inlineFullscreenLastAppliedChromeInsets = (UIEdgeInsets){ -999, -999, -999, -999 };
        _ytv_playbackState = YTVFeedPlaybackStateIdle;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)dealloc {
    [self ytv_finalizePlaybackPerformanceLogIfNeededWithReason:@"dealloc" error:nil];
    [self ytv_removePlaybackPerformanceObserversIfNeeded];
    if (_playerSession) {
        _playerSession.eventHandler = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    if (self.ytv_isFavoritesFeed) {
        self.feedViewModel = [YTVShortVideoFeedViewModel favoritesFeedViewModelWithSeedItems:self.favoritesSeedItems
                                                                                entryVideoId:self.favoritesEntryVideoId];
    } else {
        self.feedViewModel = [[YTVShortVideoFeedViewModel alloc] initWithCategoryKey:self.categoryKey];
    }
    self.ytv_lastProvisionalWarmIndex = NSNotFound;
    self.ytv_lastProvisionalWarmVelocityBucket = NSNotFound;
    self.ytv_pendingBindIndex = NSNotFound;
    __weak typeof(self) weakSelf = self;
    self.playerSession.eventHandler = ^(YTVPlayerSessionEventType eventType, NSUInteger requestId, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_handlePlayerSessionEvent:eventType requestId:requestId error:error];
    };
    [self ytv_installPlaybackPerformanceObserversIfNeeded];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.stateOverlay];
    [self.stateOverlay addSubview:self.stateEmptyImageView];
    [self.stateOverlay addSubview:self.stateLabel];
    [self.stateOverlay addSubview:self.retryButton];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.stateEmptyImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.stateOverlay);
        make.bottom.equalTo(self.stateLabel.mas_top).offset(-20);
        make.width.height.mas_equalTo(120);
    }];
    [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.stateOverlay);
        make.centerY.equalTo(self.stateOverlay).offset(24);
        make.left.greaterThanOrEqualTo(self.stateOverlay).offset(32);
        make.right.lessThanOrEqualTo(self.stateOverlay).offset(-32);
    }];
    [self.retryButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.stateLabel.mas_bottom).offset(20);
        make.centerX.equalTo(self.stateOverlay);
    }];
    [self.view addSubview:self.nextLoadFailureBar];
    [self.nextLoadFailureBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.left.greaterThanOrEqualTo(self.view).offset(12);
        make.right.lessThanOrEqualTo(self.view).offset(-12);
        make.width.lessThanOrEqualTo(@300);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-8);
    }];
    self.stateOverlay.hidden = YES;
    [self ytv_refreshInteractionChrome];
    if (self.ytv_isFavoritesFeed) {
        [self addGlobalBackButton];
        self.ytv_bootstrapStarted = YES;
        self.ytv_categoryFeedActive = YES;
        __weak typeof(self) weakSelf = self;
        [self.feedViewModel loadBootstrapWithCompletion:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            [self ytv_reloadUIForViewModelState];
        }];
    }
}

- (void)ytv_installPlaybackPerformanceObserversIfNeeded {
    if (self.ytv_perfObserversInstalled) {
        return;
    }
    AVPlayer *player = self.playerSession.player;
    if (!player) {
        return;
    }
    [player addObserver:self
             forKeyPath:@"timeControlStatus"
                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                context:kYTVPlaybackPlayerTimeControlStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ytv_handlePlaybackStalledNotification:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:nil];
    self.ytv_perfObserversInstalled = YES;
}

- (void)ytv_removePlaybackPerformanceObserversIfNeeded {
    if (!self.ytv_perfObserversInstalled) {
        return;
    }
    AVPlayer *player = _playerSession.player;
    if (player) {
        @try {
            [player removeObserver:self forKeyPath:@"timeControlStatus" context:kYTVPlaybackPlayerTimeControlStatusContext];
        } @catch (__unused NSException *e) {
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemPlaybackStalledNotification
                                                  object:nil];
    self.ytv_perfObserversInstalled = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context == kYTVPlaybackPlayerTimeControlStatusContext) {
        [self ytv_handlePlaybackTimeControlStatusChanged];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)ytv_handlePlaybackStalledNotification:(NSNotification *)notification {
    AVPlayerItem *item = notification.object;
    if (!item || item != self.playerSession.player.currentItem) {
        return;
    }
    if (!self.ytv_perfSessionActive || !self.ytv_currentPlaybackFirstFrameReady || self.ytv_userPausedWithPlayHint) {
        return;
    }
    [self ytv_beginPlaybackStallIfNeededWithReason:@"stalled_notification"];
}

- (void)ytv_handlePlaybackTimeControlStatusChanged {
    if (!self.ytv_perfSessionActive) {
        return;
    }
    AVPlayer *player = self.playerSession.player;
    switch (player.timeControlStatus) {
        case AVPlayerTimeControlStatusPlaying:
            [self ytv_endPlaybackStallIfNeededWithReason:@"resume_playing"];
            if (self.ytv_currentPlaybackFirstFrameReady && !self.ytv_userPausedWithPlayHint) {
                [self ytv_beginPlaybackActiveSegmentIfNeeded];
            }
            break;
        case AVPlayerTimeControlStatusPaused:
            [self ytv_endPlaybackStallIfNeededWithReason:@"paused"];
            [self ytv_endPlaybackActiveSegmentIfNeeded];
            break;
        case AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate:
            [self ytv_endPlaybackActiveSegmentIfNeeded];
            if (self.ytv_currentPlaybackFirstFrameReady && !self.ytv_userPausedWithPlayHint) {
                [self ytv_beginPlaybackStallIfNeededWithReason:[self ytv_playerWaitingReasonLabel]];
            }
            break;
    }
}

- (void)ytv_resetPlaybackPerformanceTrackingForItem:(YTVVideoFeedItem *)item index:(NSInteger)index {
    self.ytv_perfSessionActive = (item.videoId.length > 0);
    self.ytv_perfSessionVideoId = item.videoId ?: @"";
    self.ytv_perfSessionIndex = index;
    self.ytv_perfPlaySegmentStartTime = 0;
    self.ytv_perfStallStartTime = 0;
    self.ytv_perfAccumulatedPlayDuration = 0;
    self.ytv_perfAccumulatedStallDuration = 0;
    self.ytv_perfStallCount = 0;
}

- (void)ytv_appendPlaybackRequestFlagsToLogLine:(NSMutableString *)line {
    if (!line) {
        return;
    }
    [line appendFormat:@" startup_gate=%@", self.ytv_currentPlaybackStartedWithStartupGate ? @"YES" : @"NO"];
    [line appendFormat:@" preferred_item=%@", self.ytv_currentPlaybackUsedPreferredItem ? @"YES" : @"NO"];
}

- (BOOL)ytv_shouldDeferNonCriticalStartupWork {
    return self.ytv_deferNonCriticalWarmUntilFirstFrame && !self.ytv_currentPlaybackFirstFrameReady;
}

- (BOOL)ytv_shouldPreserveBootstrapPresentationDuringDeferredReload {
    return self.ytv_currentPlaybackFromBootstrapRestore
        && self.ytv_pendingFeedReloadAligningToActivePlayback
        && [self ytv_shouldDeferNonCriticalStartupWork];
}

- (BOOL)ytv_shouldLockScrollForStartupPlayback {
    if (!self.ytv_categoryFeedActive || self.ytv_inlineFullscreenActive) {
        return NO;
    }
    if (self.feedViewModel.state != YTVShortVideoFeedStateReady || self.collectionView.hidden) {
        return NO;
    }
    if (self.currentPlayIndex == NSNotFound || self.feedViewModel.numberOfItems == 0) {
        return NO;
    }
    return [self ytv_shouldDeferNonCriticalStartupWork];
}

- (void)ytv_correctContentOffsetForStartupScrollLockIfNeeded {
    if (![self ytv_shouldLockScrollForStartupPlayback]) {
        return;
    }
    CGFloat pageH = self.collectionView.bounds.size.height;
    if (pageH < 1) {
        return;
    }
    CGFloat expectedY = [self ytv_contentOffsetYForRealIndex:self.currentPlayIndex pageHeight:pageH];
    CGFloat currentY = self.collectionView.contentOffset.y;
    if (!isfinite(expectedY) || !isfinite(currentY)) {
        return;
    }
    if (fabs(currentY - expectedY) < kYTVStartupScrollLockCorrectionThreshold) {
        return;
    }
    [self.collectionView setContentOffset:CGPointMake(0, expectedY) animated:NO];
    NSLog(@"%@ startup_gate_scroll_lock idx=%ld enabled=YES offY=%.2f expectedY=%.2f corrected=YES",
          kYTVPlaybackPerfLogPrefix,
          (long)self.currentPlayIndex,
          currentY,
          expectedY);
}

- (void)ytv_updateStartupScrollLockIfNeeded {
    BOOL shouldLock = [self ytv_shouldLockScrollForStartupPlayback];
    if (self.collectionView) {
        self.collectionView.scrollEnabled = (!self.ytv_inlineFullscreenActive && !shouldLock);
    }
    if (shouldLock) {
        [self ytv_correctContentOffsetForStartupScrollLockIfNeeded];
    }
    if (self.ytv_startupScrollLockEnabled == shouldLock) {
        return;
    }
    self.ytv_startupScrollLockEnabled = shouldLock;
    NSLog(@"%@ startup_gate_scroll_lock idx=%ld enabled=%@ offY=%.2f",
          kYTVPlaybackPerfLogPrefix,
          (long)self.currentPlayIndex,
          shouldLock ? @"YES" : @"NO",
          self.collectionView.contentOffset.y);
}

- (void)ytv_cancelPendingStartupPrimePlayback {
    self.ytv_pendingStartupPrimePlaybackIndex = NSNotFound;
    self.ytv_pendingStartupPrimePlaybackToken += 1;
}

- (void)ytv_setStartupPresentationItem:(YTVVideoFeedItem *)item index:(NSInteger)index {
    if (!item || index == NSNotFound) {
        [self ytv_clearStartupPresentationItem];
        return;
    }
    self.ytv_startupPresentationItem = item;
    self.ytv_startupPresentationIndex = index;
}

- (void)ytv_clearStartupPresentationItem {
    self.ytv_startupPresentationItem = nil;
    self.ytv_startupPresentationIndex = NSNotFound;
}

- (YTVVideoFeedItem *)ytv_displayItemForDataIndex:(NSInteger)dataIdx {
    if ([self ytv_shouldDeferNonCriticalStartupWork]
        && self.ytv_startupPresentationItem
        && self.ytv_startupPresentationIndex == dataIdx) {
        return self.ytv_startupPresentationItem;
    }
    return [self.feedViewModel itemAtIndex:dataIdx];
}

- (NSInteger)ytv_resolvedFeedIndexForVideoId:(NSString *)videoId
                                      playURL:(NSString *)playURL
                                fallbackIndex:(NSInteger)fallbackIndex {
    NSInteger count = (NSInteger)self.feedViewModel.numberOfItems;
    if (count <= 0) {
        return NSNotFound;
    }
    if (videoId.length > 0) {
        NSInteger idx = [self.feedViewModel ytv_indexOfVideoId:videoId];
        if (idx >= 0) {
            return idx;
        }
    }
    if (playURL.length > 0) {
        NSUInteger idx = [self.feedViewModel.items indexOfObjectPassingTest:^BOOL(YTVVideoFeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.playURL isEqualToString:playURL];
        }];
        if (idx != NSNotFound) {
            return (NSInteger)idx;
        }
    }
    if (fallbackIndex >= 0 && fallbackIndex < count) {
        return fallbackIndex;
    }
    return NSNotFound;
}

- (NSInteger)ytv_resolvedFeedIndexForPresentedDataIndex:(NSInteger)dataIdx {
    YTVVideoFeedItem *displayItem = [self ytv_displayItemForDataIndex:dataIdx];
    if (!displayItem) {
        return NSNotFound;
    }
    return [self ytv_resolvedFeedIndexForVideoId:displayItem.videoId
                                         playURL:displayItem.playURL
                                   fallbackIndex:dataIdx];
}

- (BOOL)ytv_scheduleStartupPrimePlaybackIfNeededAtIndex:(NSInteger)index {
    if (!self.feedViewModel.ytv_bootstrapLoadedFromSnapshot) {
        return NO;
    }
    if (![self ytv_shouldDeferNonCriticalStartupWork]) {
        return NO;
    }
    if (self.currentPlayIndex != index || self.ytv_isSwitchingPlayback || self.ytv_pendingBindIndex != NSNotFound) {
        return NO;
    }
    NSString *sourceLabel = self.feedViewModel.ytv_initialVideoSourceLabel ?: @"";
    if (![sourceLabel hasPrefix:@"resume"] && ![sourceLabel isEqualToString:@"snapshot_first"]) {
        return NO;
    }
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:index];
    if (!item || item.videoId.length == 0 || item.playURL.length == 0) {
        return NO;
    }
    [self ytv_setStartupPresentationItem:item index:index];
    YTVVideoCachePlaybackDecision *cacheDecision = [self.preloadManager playbackDecisionForVideoId:item.videoId playURL:item.playURL];
    if (cacheDecision.playbackSource == YTVVideoCachePlaybackSourceDiskFile) {
        return NO;
    }
    if ([self.preloadManager preparedPlayerItemForVideoId:item.videoId playURL:item.playURL]) {
        return NO;
    }
    [self.preloadManager primePlaybackItemForImmediateUse:item];
    self.ytv_pendingStartupPrimePlaybackIndex = index;
    self.ytv_pendingStartupPrimePlaybackToken += 1;
    NSUInteger token = self.ytv_pendingStartupPrimePlaybackToken;
    NSLog(@"%@ startup_prime_begin idx=%ld videoId=%@ budget=%.0fms poll=%.0fms source=%@",
          kYTVPlaybackPerfLogPrefix,
          (long)index,
          item.videoId ?: @"<nil>",
          kYTVStartupPrimeMaxWaitSeconds * 1000.0,
          kYTVStartupPrimePollIntervalSeconds * 1000.0,
          sourceLabel.length > 0 ? sourceLabel : @"unknown");
    [self ytv_updateStartupScrollLockIfNeeded];
    [self ytv_continueStartupPrimePlaybackPollingWithToken:token
                                                     index:index
                                             bootstrapItem:item
                                                 startTime:CACurrentMediaTime()];
    return YES;
}

- (void)ytv_continueStartupPrimePlaybackPollingWithToken:(NSUInteger)token
                                                   index:(NSInteger)index
                                           bootstrapItem:(YTVVideoFeedItem *)bootstrapItem
                                               startTime:(CFTimeInterval)startTime {
    if (self.ytv_pendingStartupPrimePlaybackToken != token || self.ytv_pendingStartupPrimePlaybackIndex != index) {
        return;
    }
    if (!self.ytv_categoryFeedActive
        || self.feedViewModel.state != YTVShortVideoFeedStateReady
        || self.currentPlayIndex != index) {
        [self ytv_cancelPendingStartupPrimePlayback];
        return;
    }
    BOOL preferredReady = [self.preloadManager preparedPlayerItemForVideoId:bootstrapItem.videoId playURL:bootstrapItem.playURL] != nil;
    YTVVideoCachePlaybackDecision *decision = [self.preloadManager playbackDecisionForVideoId:bootstrapItem.videoId playURL:bootstrapItem.playURL];
    BOOL localFileReady = (decision.playbackSource == YTVVideoCachePlaybackSourceDiskFile);
    NSTimeInterval elapsed = MAX(CACurrentMediaTime() - startTime, 0);
    BOOL timedOut = (elapsed >= kYTVStartupPrimeMaxWaitSeconds);
    if (preferredReady || localFileReady || timedOut) {
        self.ytv_pendingStartupPrimePlaybackIndex = NSNotFound;
        YTVVideoFeedItem *currentItem = [self.feedViewModel itemAtIndex:index];
        BOOL feedItemMatchesBootstrap = (currentItem != nil
                                         && ((bootstrapItem.videoId.length > 0 && [currentItem.videoId isEqualToString:bootstrapItem.videoId])
                                             || (bootstrapItem.playURL.length > 0 && [currentItem.playURL isEqualToString:bootstrapItem.playURL])));
        NSLog(@"%@ startup_prime_fire idx=%ld videoId=%@ preferred_ready=%@ local_file=%@ waited=%.0fms timed_out=%@ feed_match=%@",
              kYTVPlaybackPerfLogPrefix,
              (long)index,
              bootstrapItem.videoId ?: @"<nil>",
              preferredReady ? @"YES" : @"NO",
              localFileReady ? @"YES" : @"NO",
              elapsed * 1000.0,
              timedOut ? @"YES" : @"NO",
              feedItemMatchesBootstrap ? @"YES" : @"NO");
        if (feedItemMatchesBootstrap) {
            [self ytv_applyPlaybackForCurrentIndexIfPossible];
        } else {
            [self ytv_applyPlaybackForBootstrapItem:bootstrapItem bindIdx:index];
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kYTVStartupPrimePollIntervalSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_continueStartupPrimePlaybackPollingWithToken:token
                                                         index:index
                                                 bootstrapItem:bootstrapItem
                                                     startTime:startTime];
    });
}

- (NSInteger)ytv_targetIndexMatchingActivePlaybackInCurrentFeed {
    NSInteger fallback = self.currentPlayIndex;
    if (fallback == NSNotFound) {
        fallback = 0;
    }
    return [self ytv_resolvedFeedIndexForVideoId:self.ytv_perfSessionVideoId
                                         playURL:self.ytv_pendingPlaybackURLString
                                   fallbackIndex:fallback];
}

- (void)ytv_applyDeferredFeedReloadAligningToActivePlaybackIfNeeded {
    if (!self.ytv_pendingFeedReloadAligningToActivePlayback) {
        return;
    }
    self.ytv_pendingFeedReloadAligningToActivePlayback = NO;
    [self ytv_clearStartupPresentationItem];
    NSInteger previousIndex = self.currentPlayIndex;
    NSInteger targetIdx = [self ytv_targetIndexMatchingActivePlaybackInCurrentFeed];
    if (targetIdx == NSNotFound) {
        return;
    }
    NSLog(@"%@ deferred_reload_apply from_idx=%ld to_idx=%ld videoId=%@",
          kYTVPlaybackPerfLogPrefix,
          (long)previousIndex,
          (long)targetIdx,
          self.ytv_perfSessionVideoId.length > 0 ? self.ytv_perfSessionVideoId : @"<nil>");
    self.currentPlayIndex = targetIdx;
    if (self.ytv_perfSessionActive) {
        self.ytv_perfSessionIndex = targetIdx;
    }
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    [self ytv_applyContentOffsetForRealIndex:targetIdx];
    [self ytv_syncVisibleCellsForActivePlaybackIndex:targetIdx];
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:targetIdx];
    if (self.ytv_currentPlaybackFirstFrameReady && cell) {
        [cell ytv_clearPlaybackFailureState];
        [cell ytv_hideCoverAfterFirstFrameAnimated:NO];
    }
    [self ytv_refreshInteractionChrome];
}

- (BOOL)ytv_preserveStartupPlaybackWhileDeferringFeedReloadIfNeededAtIndex:(NSInteger)bindIdx {
    if (![self ytv_shouldPreserveBootstrapPresentationDuringDeferredReload]) {
        return NO;
    }
    BOOL hasActiveOrPendingPlayback = self.ytv_perfSessionActive
        || self.ytv_pendingPlaybackRequestId != 0
        || self.ytv_pendingBindIndex != NSNotFound
        || self.ytv_pendingPlaybackURLString.length > 0
        || self.playerSession.player.currentItem != nil;
    if (!hasActiveOrPendingPlayback) {
        return NO;
    }
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:bindIdx];
    if (cell) {
        [self ytv_syncVisibleCellsForActivePlaybackIndex:bindIdx];
        [cell ytv_showCoverImmediately];
        [cell ytv_clearPlaybackFailureState];
        [cell.renderView attachPlayer:self.playerSession.player];
        [self.playerSession bindPlayerLayerForFirstFrameObservation:cell.renderView.playerLayer];
    }
    NSLog(@"%@ preserve_startup_playback idx=%ld videoId=%@ reason=deferred_feed_reload cell_bound=%@",
          kYTVPlaybackPerfLogPrefix,
          (long)bindIdx,
          self.ytv_perfSessionVideoId.length > 0 ? self.ytv_perfSessionVideoId : @"<nil>",
          cell ? @"YES" : @"NO");
    return YES;
}

- (void)ytv_beginPlaybackActiveSegmentIfNeeded {
    if (!self.ytv_perfSessionActive || self.ytv_perfPlaySegmentStartTime > 0) {
        return;
    }
    self.ytv_perfPlaySegmentStartTime = CACurrentMediaTime();
}

- (void)ytv_endPlaybackActiveSegmentIfNeeded {
    if (self.ytv_perfPlaySegmentStartTime <= 0) {
        return;
    }
    self.ytv_perfAccumulatedPlayDuration += (CACurrentMediaTime() - self.ytv_perfPlaySegmentStartTime);
    self.ytv_perfPlaySegmentStartTime = 0;
}

- (void)ytv_beginPlaybackStallIfNeededWithReason:(NSString *)reason {
    if (!self.ytv_perfSessionActive || self.ytv_perfStallStartTime > 0) {
        return;
    }
    self.ytv_perfStallStartTime = CACurrentMediaTime();
    (void)reason;
}

- (void)ytv_endPlaybackStallIfNeededWithReason:(NSString *)reason {
    if (self.ytv_perfStallStartTime <= 0) {
        return;
    }
    NSTimeInterval duration = CACurrentMediaTime() - self.ytv_perfStallStartTime;
    self.ytv_perfStallStartTime = 0;
    if (duration < kYTVPlaybackStallLogThresholdSeconds) {
        return;
    }
    self.ytv_perfStallCount += 1;
    self.ytv_perfAccumulatedStallDuration += duration;
    NSLog(@"%@ stall idx=%ld videoId=%@ source=%@ duration=%.0fms reason=%@",
          kYTVPlaybackPerfLogPrefix,
          (long)self.ytv_perfSessionIndex,
          self.ytv_perfSessionVideoId ?: @"<nil>",
          self.ytv_currentPlaybackSourceLabel ?: @"unknown",
          duration * 1000.0,
          reason ?: @"unknown");
}

- (void)ytv_updatePlaybackResolvedURLMetadata:(NSURL *)resolvedURL {
    self.ytv_currentPlaybackResolvedURL = resolvedURL;
    self.ytv_currentPlaybackResolvedURLIsLocal = NO;
    self.ytv_currentPlaybackResolvedFileBytes = 0;
    if (!resolvedURL) {
        return;
    }
    NSString *scheme = resolvedURL.scheme.lowercaseString;
    if (![scheme isEqualToString:@"file"]) {
        return;
    }
    self.ytv_currentPlaybackResolvedURLIsLocal = YES;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:resolvedURL.path error:nil];
    NSNumber *fileSize = [attrs isKindOfClass:[NSDictionary class]] ? attrs[NSFileSize] : nil;
    if ([fileSize isKindOfClass:[NSNumber class]]) {
        self.ytv_currentPlaybackResolvedFileBytes = fileSize.unsignedLongLongValue;
    }
}

- (nullable YTVVideoFeedItem *)ytv_perfSessionItem {
    if (self.ytv_perfSessionVideoId.length == 0) {
        return nil;
    }
    NSInteger idx = [self.feedViewModel ytv_indexOfVideoId:self.ytv_perfSessionVideoId];
    if (idx < 0) {
        return nil;
    }
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:idx];
    if (!item || ![item.videoId isEqualToString:self.ytv_perfSessionVideoId]) {
        return nil;
    }
    return item;
}

- (NSString *)ytv_perfAssetTypeForItem:(YTVVideoFeedItem *)item {
    NSString *type = item.playURLType.lowercaseString;
    if (type.length > 0) {
        return type;
    }
    NSURL *remoteURL = [self ytv_assetURLFromPlayURLString:item.playURL];
    NSString *remoteExt = remoteURL.pathExtension.lowercaseString;
    if ([remoteExt isEqualToString:@"m3u8"]) {
        return @"hls";
    }
    if (remoteExt.length > 0) {
        return remoteExt;
    }
    NSString *resolvedExt = self.ytv_currentPlaybackResolvedURL.pathExtension.lowercaseString;
    if ([resolvedExt isEqualToString:@"m3u8"]) {
        return @"hls";
    }
    if (resolvedExt.length > 0) {
        return resolvedExt;
    }
    NSString *scheme = remoteURL.scheme.lowercaseString;
    if ([scheme isEqualToString:@"file"]) {
        return @"file";
    }
    return @"unknown";
}

- (Float64)ytv_perfDurationSecondsForItem:(YTVVideoFeedItem *)item {
    Float64 duration = 0;
    AVPlayerItem *playerItem = self.playerSession.player.currentItem;
    if (playerItem) {
        duration = CMTimeGetSeconds(playerItem.duration);
    }
    if ((!isfinite(duration) || duration <= 0) && item.durationMs > 0) {
        duration = item.durationMs / 1000.0;
    }
    if (!isfinite(duration) || duration < 0) {
        duration = 0;
    }
    return duration;
}

- (CGSize)ytv_perfNaturalSizeForItem:(YTVVideoFeedItem *)item {
    if (item.ytv_hasNaturalVideoSize && item.ytv_naturalVideoWidth >= 1.0 && item.ytv_naturalVideoHeight >= 1.0) {
        return CGSizeMake(item.ytv_naturalVideoWidth, item.ytv_naturalVideoHeight);
    }
    AVPlayerItem *playerItem = self.playerSession.player.currentItem;
    if (playerItem) {
        CGSize presentationSize = playerItem.presentationSize;
        if (isfinite(presentationSize.width) && isfinite(presentationSize.height)
            && presentationSize.width >= 1.0 && presentationSize.height >= 1.0) {
            return presentationSize;
        }
    }
    return CGSizeZero;
}

- (void)ytv_appendPlaybackMaterialInfoToLogLine:(NSMutableString *)line item:(YTVVideoFeedItem *)item {
    if (!line || !item) {
        return;
    }
    [line appendFormat:@" asset_type=%@", [self ytv_perfAssetTypeForItem:item]];
    if (item.playURL.length > 0) {
        [line appendFormat:@" remote_url=%@", item.playURL];
    }
    Float64 durationSeconds = [self ytv_perfDurationSecondsForItem:item];
    if (durationSeconds > 0) {
        [line appendFormat:@" duration=%.3fs", durationSeconds];
    }
    CGSize naturalSize = [self ytv_perfNaturalSizeForItem:item];
    if (naturalSize.width >= 1.0 && naturalSize.height >= 1.0) {
        [line appendFormat:@" natural_size=%.0fx%.0f", naturalSize.width, naturalSize.height];
    }
}

- (void)ytv_appendPlaybackResolvedLocationToLogLine:(NSMutableString *)line {
    if (!line) {
        return;
    }
    [line appendFormat:@" local_file=%@", self.ytv_currentPlaybackResolvedURLIsLocal ? @"YES" : @"NO"];
    if (!self.ytv_currentPlaybackResolvedURLIsLocal) {
        return;
    }
    [line appendFormat:@" cache_bytes=%llu", self.ytv_currentPlaybackResolvedFileBytes];
    if (self.ytv_currentPlaybackResolvedURL.path.length > 0) {
        [line appendFormat:@" cache_path=%@", self.ytv_currentPlaybackResolvedURL.path];
    }
}

- (NSString *)ytv_playerWaitingReasonLabel {
    if (@available(iOS 10.0, *)) {
        NSString *reason = self.playerSession.player.reasonForWaitingToPlay;
        if ([reason isEqualToString:AVPlayerWaitingToMinimizeStallsReason]) {
            return @"minimize_stalls";
        }
        if ([reason isEqualToString:AVPlayerWaitingWhileEvaluatingBufferingRateReason]) {
            return @"evaluating_buffering_rate";
        }
        if ([reason isEqualToString:AVPlayerWaitingWithNoItemToPlayReason]) {
            return @"no_item";
        }
    }
    return @"unknown";
}

- (void)ytv_finalizePlaybackPerformanceLogIfNeededWithReason:(NSString *)reason error:(NSError *)error {
    if (!self.ytv_perfSessionActive) {
        return;
    }
    YTVVideoFeedItem *item = [self ytv_perfSessionItem];
    [self ytv_endPlaybackActiveSegmentIfNeeded];
    if (self.ytv_perfStallStartTime > 0) {
        NSTimeInterval ongoingStall = CACurrentMediaTime() - self.ytv_perfStallStartTime;
        self.ytv_perfStallStartTime = 0;
        if (ongoingStall >= kYTVPlaybackStallLogThresholdSeconds) {
            self.ytv_perfStallCount += 1;
            self.ytv_perfAccumulatedStallDuration += ongoingStall;
        }
    }
    NSTimeInterval readyMs = self.ytv_currentPlaybackItemReadyTime > 0 && self.ytv_currentPlaybackReplaceStartTime > 0
        ? (self.ytv_currentPlaybackItemReadyTime - self.ytv_currentPlaybackReplaceStartTime) * 1000.0
        : -1;
    NSTimeInterval ttffMs = self.ytv_currentPlaybackFirstFrameTime > 0 && self.ytv_currentPlaybackReplaceStartTime > 0
        ? (self.ytv_currentPlaybackFirstFrameTime - self.ytv_currentPlaybackReplaceStartTime) * 1000.0
        : -1;
    NSTimeInterval readyToFirstFrameMs = (readyMs >= 0 && ttffMs >= 0) ? MAX(ttffMs - readyMs, 0) : -1;
    BOOL instant = (ttffMs >= 0 && ttffMs <= (kYTVPlaybackInstantStartThresholdSeconds * 1000.0));
    NSMutableString *line = [NSMutableString stringWithFormat:@"%@ session_end idx=%ld videoId=%@ source=%@ reason=%@ play=%.0fms stall=%.0fms stall_count=%lu instant=%@",
                             kYTVPlaybackPerfLogPrefix,
                             (long)self.ytv_perfSessionIndex,
                             self.ytv_perfSessionVideoId ?: @"<nil>",
                             self.ytv_currentPlaybackSourceLabel ?: @"unknown",
                             reason ?: @"unknown",
                             self.ytv_perfAccumulatedPlayDuration * 1000.0,
                             self.ytv_perfAccumulatedStallDuration * 1000.0,
                             (unsigned long)self.ytv_perfStallCount,
                             instant ? @"YES" : @"NO"];
    if (readyMs >= 0) {
        [line appendFormat:@" item_ready=%.0fms", readyMs];
    }
    if (ttffMs >= 0) {
        [line appendFormat:@" ttff=%.0fms", ttffMs];
    } else {
        [line appendString:@" ttff=<none>"];
    }
    if (readyToFirstFrameMs >= 0) {
        [line appendFormat:@" ready_to_first_frame=%.0fms", readyToFirstFrameMs];
    }
    [self ytv_appendPlaybackRequestFlagsToLogLine:line];
    [self ytv_appendPlaybackResolvedLocationToLogLine:line];
    [self ytv_appendPlaybackMaterialInfoToLogLine:line item:item];
    if (error.localizedDescription.length > 0) {
        [line appendFormat:@" error=%@", error.localizedDescription];
    }
    NSLog(@"%@", line);
    self.ytv_perfSessionActive = NO;
    self.ytv_perfSessionVideoId = nil;
    self.ytv_perfSessionIndex = NSNotFound;
    self.ytv_perfPlaySegmentStartTime = 0;
    self.ytv_perfStallStartTime = 0;
    self.ytv_perfAccumulatedPlayDuration = 0;
    self.ytv_perfAccumulatedStallDuration = 0;
    self.ytv_perfStallCount = 0;
    self.ytv_currentPlaybackResolvedURL = nil;
    self.ytv_currentPlaybackResolvedURLIsLocal = NO;
    self.ytv_currentPlaybackResolvedFileBytes = 0;
    self.ytv_currentPlaybackUsedPreferredItem = NO;
    self.ytv_currentPlaybackStartedWithStartupGate = NO;
}

- (void)ytv_activateCategoryFeed {
    if (self.ytv_categoryFeedActive) {
        if (self.feedViewModel.state == YTVShortVideoFeedStateReady) {
            /// 切回分类时若 `AVPlayer` 上仍是当前条 URL，`ytv_applyPlaybackForCurrentIndexIfPossible` 会走复用分支，仅 re-attach layer。
            [self ytv_applyPlaybackForCurrentIndexIfPossible];
            [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
            [self.playerSession play];
            self.ytv_userPausedWithPlayHint = NO;
            [self ytv_syncPausedPlayHintForCurrentCell];
        }
        return;
    }
    self.ytv_categoryFeedActive = YES;
    if (!self.ytv_bootstrapStarted) {
        self.ytv_bootstrapStarted = YES;
        __weak typeof(self) weakSelf = self;
        [self.feedViewModel loadBootstrapWithCompletion:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            [self ytv_reloadUIForViewModelState];
        }];
    } else if (self.feedViewModel.state == YTVShortVideoFeedStateReady) {
        [self ytv_applyPlaybackForCurrentIndexIfPossible];
        [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
        [self.playerSession play];
        self.ytv_userPausedWithPlayHint = NO;
        [self ytv_syncPausedPlayHintForCurrentCell];
    }
}

- (void)ytv_deactivateCategoryFeed {
    [self ytv_dismissInlineFullscreenIfNeededAnimated:NO];
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    [self ytv_cancelPendingStartupPrimePlayback];
    [self ytv_clearStartupPresentationItem];
    self.ytv_categoryFeedActive = NO;
    self.ytv_userPausedWithPlayHint = NO;
    self.ytv_deferNonCriticalWarmUntilFirstFrame = NO;
    self.ytv_pendingFeedReloadAligningToActivePlayback = NO;
    [self ytv_updateStartupScrollLockIfNeeded];
    [self ytv_detachPlayerFromVisibleCells];
    [self.playerSession pause];
    [self ytv_reduceInactiveCategoryResources];
    self.ytv_lastProvisionalWarmIndex = NSNotFound;
    self.ytv_lastProvisionalWarmVelocityBucket = NSNotFound;
    [self ytv_refreshInteractionChrome];
}

/// Phase 4：非当前分类只淘汰远端 warm，保留当前条与邻域已在池内的预热条目。
- (void)ytv_reduceInactiveCategoryResources {
    if (self.feedViewModel.state != YTVShortVideoFeedStateReady || self.feedViewModel.numberOfItems == 0) {
        [self.preloadManager trimWarmPoolKeepingNeighborhoodOfDisplayIndex:NSNotFound items:@[]];
        return;
    }
    NSInteger idx = self.currentPlayIndex;
    if (idx == NSNotFound) {
        idx = 0;
    }
    NSInteger maxIdx = (NSInteger)self.feedViewModel.numberOfItems - 1;
    idx = MAX(0, MIN(idx, maxIdx));
    [self.preloadManager trimWarmPoolKeepingNeighborhoodOfDisplayIndex:idx items:self.feedViewModel.items];
}

- (void)ytv_deactivateCategoryFeedReleasingPlayback {
    [self ytv_dismissInlineFullscreenIfNeededAnimated:NO];
    [self ytv_clearStartupPresentationItem];
    self.ytv_categoryFeedActive = NO;
    self.ytv_userPausedWithPlayHint = NO;
    self.ytv_deferNonCriticalWarmUntilFirstFrame = NO;
    self.ytv_pendingFeedReloadAligningToActivePlayback = NO;
    [self ytv_updateStartupScrollLockIfNeeded];
    [self ytv_detachPlayerFromVisibleCells];
    [self.playerSession pause];
    [self ytv_finalizePlaybackPerformanceLogIfNeededWithReason:@"release_playback" error:nil];
    [self.playerSession clearPlayback];
    [self.preloadManager invalidateAllWarmItems];
    self.ytv_lastProvisionalWarmIndex = NSNotFound;
    self.ytv_lastProvisionalWarmVelocityBucket = NSNotFound;
    [self ytv_resetPlaybackBindingStateToIdle];
    self.ytv_pendingPlaybackURLString = nil;
    [self ytv_refreshInteractionChrome];
}

- (void)ytv_detachPlayerFromVisibleCells {
    for (UICollectionViewCell *raw in self.collectionView.visibleCells) {
        if ([raw isKindOfClass:[YTVShortVideoCell class]]) {
            YTVShortVideoCell *cell = (YTVShortVideoCell *)raw;
            [cell.renderView attachPlayer:nil];
            [cell ytv_showCoverImmediately];
            [cell ytv_clearPlaybackFailureState];
            [cell ytv_setPausedPlayHintVisible:NO];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self ytv_hideNextLoadFailureBar];
    if (!self.ytv_inlineFullscreenActive) {
        [self.playerSession pause];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self ytv_refreshInteractionChrome];
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    if (self.ytv_inlineFullscreenActive) {
        return;
    }
    if (self.currentPlayIndex != NSNotFound && self.feedViewModel.state == YTVShortVideoFeedStateReady) {
        [self ytv_applyPlaybackForCurrentIndexIfPossible];
        [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
        [self.playerSession play];
        self.ytv_userPausedWithPlayHint = NO;
        [self ytv_syncPausedPlayHintForCurrentCell];
    }
}

- (BOOL)prefersStatusBarHidden {
    return self.ytv_inlineFullscreenActive;
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    /// TabBar / 容器晚一帧写入 safeArea 时，避免右侧列先按旧 inset 摆在中间再跳变。
    [self.view setNeedsLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.ytv_inlineFullscreenActive && self.ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled) {
        [self ytv_updateInlineFullscreenChromeInsetsFromWindowSafeArea];
    }
    [self ytv_updateVisibleCellsSwipeDim];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
        __strong typeof(weakSelf) self = weakSelf;
        [self.collectionView.collectionViewLayout invalidateLayout];
    } completion:nil];
}

#pragma mark - UI state

- (void)ytv_reloadUIForViewModelState {
    self.ytv_allowWrapFromLastAfterTailFetchIdle = NO;
    self.ytv_pendingManualWrapToHead = NO;
    switch (self.feedViewModel.state) {
        case YTVShortVideoFeedStateLoading: {
            [self ytv_clearStartupPresentationItem];
            self.stateOverlay.hidden = NO;
            self.collectionView.hidden = NO;
            self.stateEmptyImageView.hidden = YES;
            self.retryButton.hidden = YES;
            self.stateLabel.text = NSLocalizedString(@"YTV_feed_loading_hint", @"");
            break;
        }
        case YTVShortVideoFeedStateError: {
            [self ytv_clearStartupPresentationItem];
            self.stateOverlay.hidden = NO;
            self.stateEmptyImageView.hidden = YES;
            self.stateLabel.text = self.feedViewModel.lastErrorMessage.length
                ? self.feedViewModel.lastErrorMessage
                : NSLocalizedString(@"YTV_feed_load_failed", @"");
            self.retryButton.hidden = NO;
            self.collectionView.hidden = YES;
            break;
        }
        case YTVShortVideoFeedStateEmpty: {
            [self ytv_clearStartupPresentationItem];
            self.stateOverlay.hidden = NO;
            if (self.ytv_isFavoritesFeed) {
                self.stateLabel.text = NSLocalizedString(@"YTV_favorites_feed_empty", @"");
            } else if ([self.categoryKey isEqualToString:@"fengshen"]) {
                self.stateLabel.text = NSLocalizedString(@"YTV_feed_empty_fengshen", @"");
            } else {
                self.stateLabel.text = NSLocalizedString(@"YTV_feed_empty", @"");
            }
            self.retryButton.hidden = self.ytv_isFavoritesFeed ? NO : YES;
            self.collectionView.hidden = YES;
            self.stateEmptyImageView.hidden = (self.stateEmptyImageView.image == nil);
            break;
        }
        case YTVShortVideoFeedStateReady: {
            self.stateOverlay.hidden = YES;
            self.stateEmptyImageView.hidden = YES;
            [self ytv_hideNextLoadFailureBar];
            self.collectionView.hidden = NO;
            BOOL keepCurrentPlayback = self.feedViewModel.ytv_bootstrapLoadedFromSnapshot
                && self.currentPlayIndex != NSNotFound
                && self.feedViewModel.numberOfItems > 0
                && (self.ytv_currentPlaybackFirstFrameReady
                    || self.ytv_isSwitchingPlayback
                    || self.ytv_pendingBindIndex != NSNotFound
                    || self.ytv_currentPlaybackFromBootstrapRestore);
            NSInteger startIdx = [self.feedViewModel ytv_initialDisplayIndex];
            if (self.feedViewModel.numberOfItems > 0) {
                NSInteger maxIdx = (NSInteger)self.feedViewModel.numberOfItems - 1;
                startIdx = MAX(0, MIN(startIdx, maxIdx));
            } else {
                startIdx = 0;
            }
            if (keepCurrentPlayback) {
                BOOL shouldKeepStartupGate = [self ytv_shouldDeferNonCriticalStartupWork];
                NSInteger safeIdx = MIN(MAX(self.currentPlayIndex, 0), (NSInteger)self.feedViewModel.numberOfItems - 1);
                self.currentPlayIndex = safeIdx;
                if (!shouldKeepStartupGate) {
                    self.ytv_deferNonCriticalWarmUntilFirstFrame = NO;
                }
                self.ytv_currentPlaybackFromBootstrapRestore = YES;
                if (shouldKeepStartupGate) {
                    self.ytv_pendingFeedReloadAligningToActivePlayback = YES;
                    break;
                }
                [self.collectionView reloadData];
                [self.collectionView layoutIfNeeded];
                [self ytv_applyContentOffsetForRealIndex:safeIdx];
                if (self.ytv_categoryFeedActive) {
                    [self.preloadManager warmAroundDisplayIndex:safeIdx items:self.feedViewModel.items ringHeadTailPinned:[self ytv_shouldPinHeadTailInWarmPool]];
                    [self ytv_maybePrefetchNextForDisplayIndex:safeIdx];
                    [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
                }
                break;
            }
            [self.collectionView reloadData];
            [self.collectionView layoutIfNeeded];
            self.ytv_userPausedWithPlayHint = NO;
            self.ytv_lastProvisionalWarmIndex = NSNotFound;
            self.ytv_lastProvisionalWarmVelocityBucket = NSNotFound;
            self.ytv_deferNonCriticalWarmUntilFirstFrame = YES;
            self.ytv_pendingFeedReloadAligningToActivePlayback = NO;
            [self ytv_resetPlaybackBindingStateToIdle];
            self.currentPlayIndex = startIdx;
            self.ytv_currentPlaybackFromBootstrapRestore = self.feedViewModel.ytv_bootstrapLoadedFromSnapshot;
            YTVVideoFeedItem *startupItem = self.feedViewModel.ytv_bootstrapLoadedFromSnapshot ? [self.feedViewModel itemAtIndex:startIdx] : nil;
            [self ytv_setStartupPresentationItem:startupItem index:(startupItem ? startIdx : NSNotFound)];
            if (self.feedViewModel.numberOfItems > 0) {
                NSInteger colItem = [self ytv_collectionItemIndexForRealIndex:startIdx];
                NSIndexPath *ip = [NSIndexPath indexPathForItem:colItem inSection:0];
                [self.collectionView scrollToItemAtIndexPath:ip
                                            atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                                    animated:NO];
            }
            if (self.ytv_categoryFeedActive) {
                BOOL scheduledStartupPrime = [self ytv_scheduleStartupPrimePlaybackIfNeededAtIndex:startIdx];
                if (!scheduledStartupPrime) {
                    [self ytv_applyPlaybackForCurrentIndexIfPossible];
                }
                if (![self ytv_shouldDeferNonCriticalStartupWork]) {
                    [self ytv_maybePrefetchNextForDisplayIndex:startIdx];
                }
            }
            break;
        }
        default:
            break;
    }
    [self ytv_updateStartupScrollLockIfNeeded];
    [self ytv_refreshInteractionChrome];
    [self ytv_tryConsumePendingDeepLink];
}

- (void)ytv_handleDeepLinkWithEntryVideoId:(NSString *)videoId {
    if (self.ytv_isFavoritesFeed || videoId.length == 0) {
        return;
    }
    self.pendingDeepLinkVideoId = [videoId copy];
    [self ytv_tryConsumePendingDeepLink];
}

- (void)ytv_tryConsumePendingDeepLink {
    if (self.ytv_isFavoritesFeed) {
        self.pendingDeepLinkVideoId = nil;
        return;
    }
    NSString *want = [self.pendingDeepLinkVideoId copy];
    if (want.length == 0) {
        return;
    }
    if (self.feedViewModel.state == YTVShortVideoFeedStateLoading) {
        return;
    }
    NSInteger idx = [self.feedViewModel ytv_indexOfVideoId:want];
    if (idx >= 0) {
        self.pendingDeepLinkVideoId = nil;
        [self ytv_focusDisplayIndexForDeepLink:idx];
        return;
    }
    if (!self.feedViewModel.ytv_categoryBootstrapNetworkFinished) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.feedViewModel ytv_fetchInsertVideoAtHeadIfMissing:want completion:^(BOOL success, NSString * _Nullable message) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (![self.pendingDeepLinkVideoId isEqualToString:want]) {
            return;
        }
        self.pendingDeepLinkVideoId = nil;
        if (!success) {
            if (message.length > 0) {
                [MBProgressHUD showLabel:message];
            }
            return;
        }
        [self ytv_focusDisplayIndexForDeepLink:0];
    }];
}

- (void)ytv_focusDisplayIndexForDeepLink:(NSInteger)idx {
    if (idx < 0 || idx >= (NSInteger)self.feedViewModel.numberOfItems) {
        return;
    }
    [self ytv_cancelPendingStartupPrimePlayback];
    self.stateOverlay.hidden = YES;
    self.collectionView.hidden = NO;
    self.ytv_userPausedWithPlayHint = NO;
    self.ytv_lastProvisionalWarmIndex = NSNotFound;
    self.ytv_lastProvisionalWarmVelocityBucket = NSNotFound;
    self.ytv_deferNonCriticalWarmUntilFirstFrame = YES;
    self.ytv_pendingFeedReloadAligningToActivePlayback = NO;
    [self ytv_clearStartupPresentationItem];
    [self ytv_resetPlaybackBindingStateToIdle];
    self.currentPlayIndex = idx;
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    CGFloat pageH = self.collectionView.bounds.size.height;
    if (pageH > 0) {
        [self ytv_applyContentOffsetForRealIndex:idx];
    } else {
        NSInteger colItem = [self ytv_collectionItemIndexForRealIndex:idx];
        NSIndexPath *ip = [NSIndexPath indexPathForItem:colItem inSection:0];
        [self.collectionView scrollToItemAtIndexPath:ip
                                    atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                            animated:NO];
    }
    if (self.ytv_categoryFeedActive) {
        [self ytv_updateStartupScrollLockIfNeeded];
        [self ytv_applyPlaybackForCurrentIndexIfPossible];
        if (![self ytv_shouldDeferNonCriticalStartupWork]) {
            [self ytv_maybePrefetchNextForDisplayIndex:idx];
        }
    }
    [self ytv_refreshInteractionChrome];
}

- (void)ytv_onRetryTap {
    __weak typeof(self) weakSelf = self;
    [self.feedViewModel loadBootstrapWithCompletion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_reloadUIForViewModelState];
    }];
}

#pragma mark - Scroll → 播放绑定（分页结束后再换源，技术设计 §2）

- (BOOL)ytv_shouldAllowWrapFromLastToHead {
    if (!self.ytv_categoryFeedActive) {
        return NO;
    }
    if (self.feedViewModel.ytv_isLoadingNext) {
        return NO;
    }
    return !self.feedViewModel.hasMore || self.ytv_allowWrapFromLastAfterTailFetchIdle;
}

- (BOOL)ytv_scrollView:(UIScrollView *)scrollView atLastPageWantsNextWithVelocity:(CGPoint)velocity pageHeight:(CGFloat)h maxIndex:(NSInteger)maxIdx {
    static const CGFloat kYTVWrapUpVelocityThreshold = 0.02f;
    if (velocity.y > kYTVWrapUpVelocityThreshold) {
        return YES;
    }
    CGFloat maxYByCount = (CGFloat)maxIdx * h;
    CGFloat maxScrollY = MAX(0, scrollView.contentSize.height - scrollView.bounds.size.height);
    CGFloat capY = MIN(maxYByCount, maxScrollY);
    if (scrollView.contentOffset.y > capY + 0.5f) {
        return YES;
    }
    return NO;
}

- (BOOL)ytv_isScrollViewVisuallyOnLastPage:(UIScrollView *)scrollView pageHeight:(CGFloat)h maxIndex:(NSInteger)maxIdx {
    if (h < 1 || maxIdx < 0) {
        return NO;
    }
    CGFloat maxY = (CGFloat)maxIdx * h;
    CGFloat y = scrollView.contentOffset.y;
    NSInteger idx = (NSInteger)llround(y / h);
    idx = MAX(0, MIN(idx, maxIdx));
    return idx >= maxIdx && fabs(y - maxY) < h * 0.2f;
}

- (BOOL)ytv_scrollViewAtEffectiveVerticalEndForWrap:(UIScrollView *)scrollView {
    CGFloat bh = scrollView.bounds.size.height;
    CGFloat ch = scrollView.contentSize.height;
    if (ch < 1 || bh < 1) {
        return NO;
    }
    CGFloat maxOffY = MAX(0, ch - bh);
    return scrollView.contentOffset.y >= maxOffY - 3.0;
}

- (BOOL)ytv_loopRingScrollActive {
    if (!self.ytv_categoryFeedActive) {
        return NO;
    }
    if (self.feedViewModel.state != YTVShortVideoFeedStateReady) {
        return NO;
    }
    if (self.feedViewModel.numberOfItems < 2) {
        return NO;
    }
    return !self.feedViewModel.hasMore;
}

- (BOOL)ytv_shouldPinHeadTailInWarmPool {
    return [self ytv_loopRingScrollActive];
}

- (NSInteger)ytv_collectionDisplayItemCount {
    NSInteger n = (NSInteger)self.feedViewModel.numberOfItems;
    if (n < 1) {
        return 0;
    }
    if ([self ytv_loopRingScrollActive]) {
        return n + 2;
    }
    return n;
}

- (CGFloat)ytv_contentOffsetYForRealIndex:(NSInteger)realIdx pageHeight:(CGFloat)h {
    if (h < 1) {
        return 0;
    }
    NSInteger n = (NSInteger)self.feedViewModel.numberOfItems;
    if (n < 1) {
        return 0;
    }
    realIdx = MAX(0, MIN(realIdx, n - 1));
    if ([self ytv_loopRingScrollActive]) {
        return (CGFloat)(realIdx + 1) * h;
    }
    return (CGFloat)realIdx * h;
}

- (void)ytv_applyContentOffsetForRealIndex:(NSInteger)realIdx {
    CGFloat h = self.collectionView.bounds.size.height;
    if (h < 1) {
        return;
    }
    CGFloat y = [self ytv_contentOffsetYForRealIndex:realIdx pageHeight:h];
    [self.collectionView setContentOffset:CGPointMake(0, y) animated:NO];
}

- (NSInteger)ytv_collectionItemIndexForRealIndex:(NSInteger)realIdx {
    NSInteger n = (NSInteger)self.feedViewModel.numberOfItems;
    if (n < 1) {
        return 0;
    }
    realIdx = MAX(0, MIN(realIdx, n - 1));
    if ([self ytv_loopRingScrollActive]) {
        return realIdx + 1;
    }
    return realIdx;
}

- (NSInteger)ytv_dataItemIndexForCollectionItem:(NSInteger)collectionItem {
    NSInteger n = (NSInteger)self.feedViewModel.numberOfItems;
    if (n < 1) {
        return 0;
    }
    if (![self ytv_loopRingScrollActive]) {
        return MAX(0, MIN(collectionItem, n - 1));
    }
    if (collectionItem <= 0) {
        return n - 1;
    }
    if (collectionItem >= n + 1) {
        return 0;
    }
    return collectionItem - 1;
}

- (NSInteger)ytv_realPlaybackIndexFromExtendedPage:(NSInteger)extPage nData:(NSInteger)nData {
    if (nData < 1) {
        return 0;
    }
    if (![self ytv_loopRingScrollActive] || nData < 2) {
        return MAX(0, MIN(extPage, nData - 1));
    }
    if (extPage <= 0) {
        return nData - 1;
    }
    if (extPage >= nData + 1) {
        return 0;
    }
    return extPage - 1;
}

- (void)ytv_warmAroundProvisionalDisplayIndex:(NSInteger)idx {
    [self ytv_warmAroundProvisionalDisplayIndex:idx scrollVelocityY:0];
}

- (void)ytv_warmAroundProvisionalDisplayIndex:(NSInteger)idx scrollVelocityY:(CGFloat)velocityY {
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    if ([self ytv_shouldDeferNonCriticalStartupWork]) {
        return;
    }
    if (self.feedViewModel.state != YTVShortVideoFeedStateReady) {
        return;
    }
    NSUInteger nItems = self.feedViewModel.numberOfItems;
    if (nItems == 0) {
        return;
    }
    NSInteger maxIdx = (NSInteger)nItems - 1;
    NSInteger clamped = MAX(0, MIN(idx, maxIdx));
    NSInteger velocityBucket = [self ytv_provisionalWarmVelocityBucketForVelocityY:velocityY];
    if (clamped == self.ytv_lastProvisionalWarmIndex && velocityBucket == self.ytv_lastProvisionalWarmVelocityBucket) {
        return;
    }
    self.ytv_lastProvisionalWarmIndex = clamped;
    self.ytv_lastProvisionalWarmVelocityBucket = velocityBucket;
    [self.preloadManager updateAdaptiveHintWithScrollVelocity:velocityY];
    [self.preloadManager warmAroundDisplayIndex:clamped items:self.feedViewModel.items ringHeadTailPinned:[self ytv_shouldPinHeadTailInWarmPool]];
}

- (CGFloat)ytv_normalizedScrollVelocityYForScrollView:(UIScrollView *)scrollView pageHeight:(CGFloat)pageHeight {
    if (!scrollView.isDragging || pageHeight < 1) {
        return 0;
    }
    CGFloat velocityY = [scrollView.panGestureRecognizer velocityInView:scrollView].y;
    if (!isfinite(velocityY)) {
        return 0;
    }
    return velocityY / pageHeight;
}

- (NSInteger)ytv_provisionalWarmVelocityBucketForVelocityY:(CGFloat)velocityY {
    CGFloat absVelocity = fabs(velocityY);
    if (absVelocity >= 0.95f) {
        return 2;
    }
    if (absVelocity >= 0.28f) {
        return 1;
    }
    return 0;
}

- (NSInteger)ytv_predictedExtendedPageForScrollView:(UIScrollView *)scrollView pageHeight:(CGFloat)pageHeight velocityY:(CGFloat)velocityY {
    NSInteger maxPageIdx = [self ytv_collectionDisplayItemCount] - 1;
    if (pageHeight < 1 || maxPageIdx < 0) {
        return NSNotFound;
    }
    CGFloat rawPage = scrollView.contentOffset.y / pageHeight;
    rawPage = MAX(0, MIN(rawPage, (CGFloat)maxPageIdx));
    NSInteger predicted = (NSInteger)llround(rawPage);
    CGFloat absVelocity = fabs(velocityY);
    if (absVelocity < 0.12f) {
        return predicted;
    }
    NSInteger lowerPage = (NSInteger)floor(rawPage);
    CGFloat progress = rawPage - lowerPage;
    if (velocityY > 0) {
        BOOL headingNext = (progress >= 0.18f) || (absVelocity >= 0.65f);
        predicted = lowerPage + (headingNext ? 1 : 0);
    } else {
        NSInteger upperPage = (NSInteger)ceil(rawPage);
        BOOL headingPrev = (progress <= 0.82f) || (absVelocity >= 0.65f);
        predicted = upperPage - (headingPrev ? 1 : 0);
    }
    return MAX(0, MIN(predicted, maxPageIdx));
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.collectionView) {
        return;
    }
    CGFloat pageH = self.collectionView.bounds.size.height;
    if (pageH < 1) {
        return;
    }
    if ([self ytv_shouldLockScrollForStartupPlayback]) {
        [self ytv_updateStartupScrollLockIfNeeded];
        [self ytv_updateVisibleCellsSwipeDim];
        return;
    }
    NSInteger extPage = (NSInteger)llround(scrollView.contentOffset.y / pageH);
    NSInteger nData = (NSInteger)self.feedViewModel.numberOfItems;
    CGFloat velocityY = [self ytv_normalizedScrollVelocityYForScrollView:scrollView pageHeight:pageH];
    NSInteger predictedExtPage = [self ytv_predictedExtendedPageForScrollView:scrollView pageHeight:pageH velocityY:velocityY];
    NSInteger realWarm = [self ytv_realPlaybackIndexFromExtendedPage:extPage nData:nData];
    NSInteger predictedWarm = (predictedExtPage == NSNotFound)
        ? realWarm
        : [self ytv_realPlaybackIndexFromExtendedPage:predictedExtPage nData:nData];
    NSInteger warmTarget = (scrollView.isDragging ? predictedWarm : realWarm);
    [self ytv_warmAroundProvisionalDisplayIndex:warmTarget scrollVelocityY:velocityY];
    if (![self ytv_shouldDeferNonCriticalStartupWork]
        && scrollView.isDragging
        && predictedWarm != NSNotFound
        && predictedWarm != self.currentPlayIndex) {
        [self ytv_prepareStandbyPlaybackForTargetIndex:predictedWarm];
    }
    [self ytv_updateVisibleCellsSwipeDim];
}

/// 流边界：无更多时用首尾环形重复页（`ytv_loopRingScrollActive`）；否则用 target=0 + pending 兜底。
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView != self.collectionView) {
        return;
    }
    self.ytv_pendingManualWrapToHead = NO;
    if (!self.ytv_categoryFeedActive) {
        YTVFeedWrapLog(@"willEndDragging: 跳过 categoryFeedActive=NO");
        return;
    }
    NSInteger n = (NSInteger)self.feedViewModel.numberOfItems;
    if (n < 2) {
        YTVFeedWrapLog(@"willEndDragging: 跳过 列表条数 n=%ld < 2", (long)n);
        return;
    }
    CGFloat h = scrollView.bounds.size.height;
    if (h < 1) {
        YTVFeedWrapLog(@"willEndDragging: 跳过 pageH=%.2f", h);
        return;
    }
    BOOL ringOn = [self ytv_loopRingScrollActive];
    NSInteger displayCount = [self ytv_collectionDisplayItemCount];
    NSInteger maxPageIdx = displayCount - 1;
    NSInteger idxPage = (NSInteger)llround(scrollView.contentOffset.y / h);
    idxPage = MAX(0, MIN(idxPage, maxPageIdx));
    NSInteger dataMaxIdx = n - 1;
    if (!ringOn) {
        BOOL allowWrapToHead = [self ytv_shouldAllowWrapFromLastToHead];
        BOOL wantsNext = [self ytv_scrollView:scrollView atLastPageWantsNextWithVelocity:velocity pageHeight:h maxIndex:dataMaxIdx];
        BOOL onLastByIndex = (idxPage >= dataMaxIdx);
        BOOL atEffectiveEnd = [self ytv_scrollViewAtEffectiveVerticalEndForWrap:scrollView];
        CGFloat maxScrollY = MAX(0, scrollView.contentSize.height - scrollView.bounds.size.height);
        BOOL shouldWrap = wantsNext && allowWrapToHead && (onLastByIndex || atEffectiveEnd);
        self.ytv_pendingManualWrapToHead = shouldWrap;
        CGFloat maxY = (CGFloat)dataMaxIdx * h;
        YTVFeedWrapLog(@"willEndDragging: ring=0 idxPage=%ld dataMax=%ld curPlay=%ld offY=%.2f maxY=%.2f contentH=%.2f maxScrollY=%.2f vy=%.4f onLastIdx=%d atEnd=%d wantsNext=%d allowWrap=%d shouldJump0=%d ->targetY=%.2f",
            (long)idxPage, (long)dataMaxIdx, (long)self.currentPlayIndex, scrollView.contentOffset.y, maxY, scrollView.contentSize.height, maxScrollY, velocity.y,
            (int)onLastByIndex, (int)atEffectiveEnd, (int)wantsNext, (int)allowWrapToHead, (int)shouldWrap, targetContentOffset->y);
        if (shouldWrap) {
            *targetContentOffset = CGPointMake(0, 0);
            YTVFeedWrapLog(@"willEndDragging: 已把 targetContentOffset 改为 0（无环形兜底）");
        }
    } else {
        YTVFeedWrapLog(@"willEndDragging: ring=1 displayPages=%ld idxPage=%ld dataMax=%ld curPlay=%ld offY=%.2f vy=%.4f ->targetY=%.2f（系统分页，首尾重复页）",
            (long)displayCount, (long)idxPage, (long)dataMaxIdx, (long)self.currentPlayIndex, scrollView.contentOffset.y, velocity.y, targetContentOffset->y);
    }
    NSInteger targetExt = (NSInteger)llround(targetContentOffset->y / h);
    targetExt = MAX(0, MIN(targetExt, maxPageIdx));
    NSInteger warmDataIdx = [self ytv_realPlaybackIndexFromExtendedPage:targetExt nData:n];
    [self ytv_warmAroundProvisionalDisplayIndex:warmDataIdx scrollVelocityY:velocity.y];
    if (![self ytv_shouldDeferNonCriticalStartupWork]) {
        [self ytv_prepareStandbyPlaybackForTargetIndex:warmDataIdx];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.collectionView) {
        return;
    }
    [self ytv_syncVisibleCellsForActivePlaybackIndex:self.currentPlayIndex];
    if (self.ytv_pendingManualWrapToHead && ![self ytv_loopRingScrollActive]) {
        YTVFeedWrapLog(@"didEndDecelerating: pendingManualWrap=YES offY=%.2f", scrollView.contentOffset.y);
        self.ytv_pendingManualWrapToHead = NO;
        CGFloat h = scrollView.bounds.size.height;
        NSInteger n = (NSInteger)self.feedViewModel.numberOfItems;
        if (h >= 1 && n >= 2) {
            NSInteger maxIdx = n - 1;
            BOOL onLastVisually = [self ytv_isScrollViewVisuallyOnLastPage:scrollView pageHeight:h maxIndex:maxIdx];
            BOOL atEffectiveEnd = [self ytv_scrollViewAtEffectiveVerticalEndForWrap:scrollView];
            BOOL allow = [self ytv_shouldAllowWrapFromLastToHead];
            YTVFeedWrapLog(@"didEndDecelerating: 兜底 visuallyOnLast=%d atEffectiveEnd=%d allowWrap=%d", (int)onLastVisually, (int)atEffectiveEnd, (int)allow);
            if ((onLastVisually || atEffectiveEnd) && allow) {
                [scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
                YTVFeedWrapLog(@"didEndDecelerating: 已 setContentOffset(0) 强制回第一条");
            }
        }
    }
    [self ytv_syncPlayIndexFromContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView != self.collectionView) {
        return;
    }
    [self ytv_syncVisibleCellsForActivePlaybackIndex:self.currentPlayIndex];
    if (!decelerate) {
        YTVFeedWrapLog(@"didEndDragging: willDecelerate=NO pendingWrap=%d offY=%.2f", (int)self.ytv_pendingManualWrapToHead, scrollView.contentOffset.y);
        if (self.ytv_pendingManualWrapToHead && ![self ytv_loopRingScrollActive]) {
            self.ytv_pendingManualWrapToHead = NO;
            CGFloat h = scrollView.bounds.size.height;
            NSInteger n = (NSInteger)self.feedViewModel.numberOfItems;
            if (h >= 1 && n >= 2) {
                NSInteger maxIdx = n - 1;
                BOOL onLastVisually = [self ytv_isScrollViewVisuallyOnLastPage:scrollView pageHeight:h maxIndex:maxIdx];
                BOOL atEffectiveEnd = [self ytv_scrollViewAtEffectiveVerticalEndForWrap:scrollView];
                BOOL allow = [self ytv_shouldAllowWrapFromLastToHead];
                YTVFeedWrapLog(@"didEndDragging: 兜底 visuallyOnLast=%d atEffectiveEnd=%d allowWrap=%d", (int)onLastVisually, (int)atEffectiveEnd, (int)allow);
                if ((onLastVisually || atEffectiveEnd) && allow) {
                    [scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
                    YTVFeedWrapLog(@"didEndDragging: 已 setContentOffset(0) 强制回第一条");
                }
            }
        }
        [self ytv_syncPlayIndexFromContentOffset];
    } else {
        YTVFeedWrapLog(@"didEndDragging: willDecelerate=YES pendingWrap=%d（等 didEndDecelerating）", (int)self.ytv_pendingManualWrapToHead);
    }
}

- (void)ytv_syncPlayIndexFromContentOffset {
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    if ([self ytv_shouldDeferNonCriticalStartupWork]) {
        [self ytv_updateStartupScrollLockIfNeeded];
        if (self.currentPlayIndex != NSNotFound
            && (self.ytv_pendingStartupPrimePlaybackIndex != NSNotFound
                || self.ytv_isSwitchingPlayback
                || self.ytv_pendingBindIndex != NSNotFound
                || self.ytv_pendingFeedReloadAligningToActivePlayback)) {
            NSLog(@"%@ startup_gate_hold_index idx=%ld offY=%.2f pending_prime=%@ switching=%@ pending_bind=%ld pending_reload=%@",
                  kYTVPlaybackPerfLogPrefix,
                  (long)self.currentPlayIndex,
                  self.collectionView.contentOffset.y,
                  self.ytv_pendingStartupPrimePlaybackIndex != NSNotFound ? @"YES" : @"NO",
                  self.ytv_isSwitchingPlayback ? @"YES" : @"NO",
                  (long)self.ytv_pendingBindIndex,
                  self.ytv_pendingFeedReloadAligningToActivePlayback ? @"YES" : @"NO");
        }
        return;
    }
    CGFloat pageH = self.collectionView.bounds.size.height;
    if (pageH < 1 || self.feedViewModel.numberOfItems == 0) {
        return;
    }
    NSInteger nData = (NSInteger)self.feedViewModel.numberOfItems;
    NSInteger extPage = (NSInteger)llround(self.collectionView.contentOffset.y / pageH);
    if ([self ytv_loopRingScrollActive] && nData >= 2) {
        if (extPage <= 0) {
            YTVFeedWrapLog(@"syncPlayIdxFromOffset: 环形顶重复末条 ext=%ld -> 对齐真实末条", (long)extPage);
            [self.collectionView setContentOffset:CGPointMake(0, (CGFloat)nData * pageH) animated:NO];
            extPage = nData;
        } else if (extPage >= nData + 1) {
            YTVFeedWrapLog(@"syncPlayIdxFromOffset: 环形底重复首条 ext=%ld -> 对齐真实首条", (long)extPage);
            [self.collectionView setContentOffset:CGPointMake(0, pageH) animated:NO];
            extPage = 1;
        }
    }
    NSInteger idx = [self ytv_realPlaybackIndexFromExtendedPage:extPage nData:nData];
    NSInteger maxIdx = nData - 1;
    idx = MAX(0, MIN(idx, maxIdx));
    if (idx == maxIdx || idx != self.currentPlayIndex) {
        YTVFeedWrapLog(@"syncPlayIdxFromOffset: offY=%.2f idx=%ld maxIdx=%ld curPlay=%ld sameIdx=%d",
            self.collectionView.contentOffset.y, (long)idx, (long)maxIdx, (long)self.currentPlayIndex, (int)(idx == self.currentPlayIndex));
    }
    if (idx == self.currentPlayIndex) {
        [self ytv_resyncPlaybackAroundCurrentIndex];
        return;
    }
    [self ytv_beginPlaybackSwitchToIndex:idx fromOldIndex:self.currentPlayIndex];
}

- (void)ytv_maybePrefetchNextForDisplayIndex:(NSInteger)idx {
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    if ([self ytv_shouldDeferNonCriticalStartupWork]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    NSInteger keepIndex = self.currentPlayIndex;
    NSInteger countAtRequest = (NSInteger)self.feedViewModel.numberOfItems;
    NSInteger maxIdxAtRequest = countAtRequest > 0 ? countAtRequest - 1 : NSNotFound;
    BOOL requestWhileOnLastLoaded = (maxIdxAtRequest != NSNotFound && idx == maxIdxAtRequest);
    YTVFeedWrapLog(@"maybePrefetch: displayIdx=%ld nItems=%ld onLastReq=%d", (long)idx, (long)countAtRequest, (int)requestWhileOnLastLoaded);
    [self.feedViewModel loadNextPageIfNeededForDisplayIndex:idx completion:^(BOOL appendedAny, NSUInteger appendedCount, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (appendedAny) {
            self.ytv_allowWrapFromLastAfterTailFetchIdle = NO;
        } else {
            NSInteger maxNow = (NSInteger)self.feedViewModel.numberOfItems - 1;
            BOOL stillOnLast = (maxNow >= 0 && self.currentPlayIndex == maxNow);
            if (requestWhileOnLastLoaded) {
                if (stillOnLast && !self.feedViewModel.ytv_isLoadingNext) {
                    self.ytv_allowWrapFromLastAfterTailFetchIdle = YES;
                } else if (!stillOnLast) {
                    self.ytv_allowWrapFromLastAfterTailFetchIdle = NO;
                }
            } else if (!stillOnLast) {
                self.ytv_allowWrapFromLastAfterTailFetchIdle = NO;
            }
        }
        YTVFeedWrapLog(@"prefetchDone: idx=%ld appended=%d appendedCount=%lu err=%@ hasMore=%d loadNext=%d tailIdle=%d curPlay=%ld",
            (long)idx, (int)appendedAny, (unsigned long)appendedCount, error.localizedDescription ?: @"(nil)",
            self.feedViewModel.hasMore, self.feedViewModel.ytv_isLoadingNext, self.ytv_allowWrapFromLastAfterTailFetchIdle,
            (long)self.currentPlayIndex);
        if (error != nil && !appendedAny) {
            NSString *msg = [YTVShortVideoFeedViewModel ytv_userFacingMessageForFeedError:error];
            [self ytv_showNextLoadFailureWithMessage:msg];
        }
        if (!appendedAny) {
            NSInteger expect = [self ytv_collectionDisplayItemCount];
            NSInteger actual = (NSInteger)[self.collectionView numberOfItemsInSection:0];
            if (expect != actual && expect > 0 && self.feedViewModel.state == YTVShortVideoFeedStateReady) {
                NSInteger keep = self.currentPlayIndex;
                if (keep == NSNotFound) {
                    keep = 0;
                }
                keep = MAX(0, MIN(keep, (NSInteger)self.feedViewModel.numberOfItems - 1));
                [self.collectionView reloadData];
                [self.collectionView layoutIfNeeded];
                [self ytv_applyContentOffsetForRealIndex:keep];
                YTVFeedWrapLog(@"prefetchDone: reloadData 同步环形 cell expect=%ld actual=%ld", (long)expect, (long)actual);
            }
            return;
        }
        [self ytv_hideNextLoadFailureBar];
        NSUInteger newDataCount = self.feedViewModel.numberOfItems;
        if (appendedCount == 0 || newDataCount < appendedCount) {
            return;
        }
        NSUInteger oldDataCount = newDataCount - appendedCount;
        NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
        if ([self ytv_loopRingScrollActive]) {
            for (NSUInteger ext = oldDataCount + 1; ext <= newDataCount; ext++) {
                [indexPaths addObject:[NSIndexPath indexPathForItem:ext inSection:0]];
            }
        } else {
            for (NSUInteger i = oldDataCount; i < newDataCount; i++) {
                [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
            }
        }
        [self.collectionView performBatchUpdates:^{
            [self.collectionView insertItemsAtIndexPaths:indexPaths];
        } completion:^(__unused BOOL finished) {
            if (keepIndex != NSNotFound && keepIndex < (NSInteger)newDataCount) {
                [self ytv_applyContentOffsetForRealIndex:keepIndex];
            }
            NSInteger expectAfter = [self ytv_collectionDisplayItemCount];
            NSInteger actualAfter = (NSInteger)[self.collectionView numberOfItemsInSection:0];
            if (expectAfter != actualAfter && expectAfter > 0 && self.feedViewModel.state == YTVShortVideoFeedStateReady) {
                NSInteger keep = keepIndex != NSNotFound ? keepIndex : self.currentPlayIndex;
                if (keep == NSNotFound) {
                    keep = 0;
                }
                keep = MAX(0, MIN(keep, (NSInteger)self.feedViewModel.numberOfItems - 1));
                [self.collectionView reloadData];
                [self.collectionView layoutIfNeeded];
                [self ytv_applyContentOffsetForRealIndex:keep];
                YTVFeedWrapLog(@"insertDone: reloadData 补环形 expect=%ld actual=%ld", (long)expectAfter, (long)actualAfter);
            }
            [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
        }];
    }];
}

/// 预取即将出现的页内容：提前 warm 媒体并把封面压入图片缓存，减少首次展示页的卡顿感。
- (void)ytv_prefetchContentForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (!self.ytv_categoryFeedActive || self.feedViewModel.state != YTVShortVideoFeedStateReady) {
        self.ytv_standbyTargetIndex = NSNotFound;
        [self.preloadManager setDeepPrewarmTargetVideoId:nil];
        [self.playerSession clearStandbyPlayback];
        return;
    }
    if (indexPaths.count == 0) {
        return;
    }
    NSMutableArray<NSURL *> *coverURLs = [NSMutableArray array];
    NSInteger furthestIndex = NSNotFound;
    NSInteger maxIndex = (NSInteger)self.feedViewModel.numberOfItems - 1;
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.section != 0) {
            continue;
        }
        NSInteger idx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)indexPath.item];
        idx = MAX(0, MIN(idx, maxIndex));
        furthestIndex = (furthestIndex == NSNotFound) ? idx : MAX(furthestIndex, idx);
        YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:idx];
        if (item.coverURL.length > 0) {
            NSURL *url = [NSURL URLWithString:item.coverURL];
            if (url) {
                [coverURLs addObject:url];
            }
        }
    }
    if (coverURLs.count > 0) {
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:coverURLs];
    }
    if (self.ytv_deferNonCriticalWarmUntilFirstFrame && !self.ytv_currentPlaybackFirstFrameReady) {
        return;
    }
    if (furthestIndex != NSNotFound) {
        [self.preloadManager warmAroundDisplayIndex:furthestIndex items:self.feedViewModel.items ringHeadTailPinned:[self ytv_shouldPinHeadTailInWarmPool]];
    }
}

/// 当前页未发生切换时，只补预热、补货和浮层状态，不重复进入切源链路。
- (void)ytv_resyncPlaybackAroundCurrentIndex {
    if (self.currentPlayIndex == NSNotFound) {
        [self ytv_refreshInteractionChrome];
        return;
    }
    [self ytv_maybePrefetchNextForDisplayIndex:self.currentPlayIndex];
    [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
    [self ytv_refreshInteractionChrome];
}

/// 播放页真正切换时，先记录旧索引的 warm 命中，再进入新的绑定流程。
- (void)ytv_beginPlaybackSwitchToIndex:(NSInteger)newIndex fromOldIndex:(NSInteger)oldIndex {
    [self ytv_cancelPendingStartupPrimePlayback];
    [self ytv_clearStartupPresentationItem];
    [self ytv_hideNextLoadFailureBar];
    NSInteger nItems = (NSInteger)self.feedViewModel.numberOfItems;
    NSInteger tailIdx = nItems > 0 ? nItems - 1 : NSNotFound;
    if (tailIdx != NSNotFound && newIndex != tailIdx) {
        self.ytv_allowWrapFromLastAfterTailFetchIdle = NO;
    }
    self.ytv_userPausedWithPlayHint = NO;
    if (oldIndex != NSNotFound && oldIndex != newIndex) {
        [self ytv_finalizePlaybackPerformanceLogIfNeededWithReason:@"switch_index" error:nil];
    }
    if (oldIndex != NSNotFound && oldIndex != newIndex) {
        NSUInteger n = self.feedViewModel.numberOfItems;
        if (oldIndex >= 0 && (NSUInteger)oldIndex < n) {
            YTVVideoFeedItem *oldItem = [self.feedViewModel itemAtIndex:oldIndex];
            if (oldItem) {
                [self.preloadManager touchWarmEntryForVideoId:oldItem.videoId playURL:oldItem.playURL];
            }
        }
    }
    self.currentPlayIndex = newIndex;
    self.ytv_currentPlaybackFromBootstrapRestore = NO;
    self.ytv_playbackState = YTVFeedPlaybackStateIdle;
    YTVVideoFeedItem *newItem = [self.feedViewModel itemAtIndex:newIndex];
    if (newItem) {
        [self.feedViewModel ytv_recordLastViewedVideoId:newItem.videoId playURL:newItem.playURL indexHint:newIndex];
    }
    self.ytv_pendingBindIndex = newIndex;
    self.ytv_currentPlaybackFirstFrameReady = NO;
    self.ytv_pendingPlaybackURLString = nil;
    self.ytv_standbyTargetIndex = NSNotFound;
    [self ytv_applyPlaybackForCurrentIndexIfPossible];
    [self ytv_resyncPlaybackAroundCurrentIndex];
}

/// 当前播放稳定后，继续向下 3 条做保温，减少用户继续下滑时的冷切概率。
- (void)ytv_primeUpcomingWarmItemsForCurrentPlayback {
    if (!self.ytv_categoryFeedActive || self.feedViewModel.state != YTVShortVideoFeedStateReady) {
        return;
    }
    if (self.ytv_deferNonCriticalWarmUntilFirstFrame && !self.ytv_currentPlaybackFirstFrameReady) {
        return;
    }
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    NSInteger nData = (NSInteger)self.feedViewModel.numberOfItems;
    NSInteger deepIdx = self.currentPlayIndex + 1;
    if (deepIdx >= 0 && deepIdx < nData) {
        YTVVideoFeedItem *next = [self.feedViewModel itemAtIndex:deepIdx];
        [self.preloadManager setDeepPrewarmTargetVideoId:next.videoId];
    } else if ([self ytv_loopRingScrollActive] && nData >= 2 && self.currentPlayIndex == nData - 1) {
        YTVVideoFeedItem *head = [self.feedViewModel itemAtIndex:0];
        [self.preloadManager setDeepPrewarmTargetVideoId:head.videoId];
    } else {
        [self.preloadManager setDeepPrewarmTargetVideoId:nil];
    }
    [self.preloadManager warmAroundDisplayIndex:self.currentPlayIndex items:self.feedViewModel.items ringHeadTailPinned:[self ytv_shouldPinHeadTailInWarmPool]];
    NSInteger standbyIdx = self.currentPlayIndex + 1;
    if (standbyIdx >= nData) {
        if ([self ytv_loopRingScrollActive] && nData >= 2) {
            standbyIdx = 0;
        } else {
            standbyIdx = -1;
        }
    }
    [self ytv_prepareStandbyPlaybackForTargetIndex:standbyIdx];
}

/// 切源 token 与切换标记回到空闲，用于列表重置、失败或当前条不可播。
- (void)ytv_resetPlaybackBindingStateToIdle {
    self.ytv_isSwitchingPlayback = NO;
    self.ytv_playbackState = YTVFeedPlaybackStateIdle;
    self.ytv_pendingPlaybackRequestId = 0;
    self.ytv_pendingBindIndex = NSNotFound;
    self.ytv_pendingPlaybackURLString = nil;
    self.ytv_currentPlaybackFirstFrameReady = NO;
}

/// 首帧已上屏：结束切换态，并把 `pendingPlaybackRequestId` 与当前会话对齐，避免后续杂散事件误匹配。
- (void)ytv_commitPlaybackBindingAfterFirstFrame {
    self.ytv_isSwitchingPlayback = NO;
    self.ytv_playbackState = YTVFeedPlaybackStatePlaying;
    self.ytv_pendingBindIndex = NSNotFound;
    self.ytv_currentPlaybackFirstFrameReady = YES;
    self.ytv_pendingPlaybackRequestId = self.playerSession.currentRequestId;
}

/// 当前条无有效网络播放地址时：暂停、解除保护位并清空绑定状态。
- (void)ytv_resetPlaybackSessionForInvalidCurrentItem {
    [self ytv_cancelPendingStartupPrimePlayback];
    [self ytv_clearStartupPresentationItem];
    [self.preloadManager markPlaybackProtectedVideoId:nil];
    [self.playerSession pause];
    [self ytv_finalizePlaybackPerformanceLogIfNeededWithReason:@"invalid_item" error:nil];
    self.ytv_deferNonCriticalWarmUntilFirstFrame = NO;
    self.ytv_pendingFeedReloadAligningToActivePlayback = NO;
    [self ytv_updateStartupScrollLockIfNeeded];
    [self ytv_resetPlaybackBindingStateToIdle];
    self.ytv_currentPlaybackResolvedURL = nil;
    self.ytv_currentPlaybackResolvedURLIsLocal = NO;
    self.ytv_currentPlaybackResolvedFileBytes = 0;
    self.ytv_userPausedWithPlayHint = NO;
    [self ytv_syncPausedPlayHintForCurrentCell];
}

- (void)ytv_scheduleFirstFrameProbeForRequestId:(NSUInteger)requestId index:(NSInteger)index delay:(NSTimeInterval)delay reason:(NSString *)reason {
    if (requestId == 0 || index == NSNotFound || delay <= 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_runFirstFrameProbeForRequestId:requestId index:index reason:reason];
    });
}

- (void)ytv_runFirstFrameProbeForRequestId:(NSUInteger)requestId index:(NSInteger)index reason:(NSString *)reason {
    if (requestId == 0
        || requestId != self.ytv_pendingPlaybackRequestId
        || index == NSNotFound
        || self.currentPlayIndex != index
        || self.ytv_currentPlaybackFirstFrameReady) {
        return;
    }
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:index];
    if (!cell) {
        cell = [self ytv_currentCellForPlaybackIndex:index];
    }
    BOOL cellBound = (cell != nil);
    if (cellBound) {
        [cell.renderView attachPlayer:self.playerSession.player];
        [self.playerSession bindPlayerLayerForFirstFrameObservation:cell.renderView.playerLayer];
    }
    NSTimeInterval readyMs = self.ytv_currentPlaybackItemReadyTime > 0 && self.ytv_currentPlaybackReplaceStartTime > 0
        ? (self.ytv_currentPlaybackItemReadyTime - self.ytv_currentPlaybackReplaceStartTime) * 1000.0
        : -1;
    NSTimeInterval elapsedMs = self.ytv_currentPlaybackReplaceStartTime > 0
        ? (CACurrentMediaTime() - self.ytv_currentPlaybackReplaceStartTime) * 1000.0
        : -1;
    NSMutableString *line = [NSMutableString stringWithFormat:@"%@ first_frame_probe idx=%ld request=%lu reason=%@ cell_bound=%@",
                             kYTVPlaybackPerfLogPrefix,
                             (long)index,
                             (unsigned long)requestId,
                             reason.length > 0 ? reason : @"unknown",
                             cellBound ? @"YES" : @"NO"];
    if (readyMs >= 0) {
        [line appendFormat:@" item_ready=%.0fms", readyMs];
    }
    if (elapsedMs >= 0) {
        [line appendFormat:@" elapsed=%.0fms", elapsedMs];
    }
    NSLog(@"%@", line);
}

/// 当前 item URL 已经命中时，直接复用现有播放会话并恢复当前 cell 的展示状态。
- (void)ytv_resumePlaybackForCurrentItemAtIndex:(NSInteger)bindIdx cell:(YTVShortVideoCell * _Nullable)cell {
    YTVVideoFeedItem *resumeItem = [self.feedViewModel itemAtIndex:bindIdx];
    if (resumeItem) {
        [self ytv_probeNaturalVideoSizeIfNeededForItem:resumeItem];
    }
    self.ytv_isSwitchingPlayback = NO;
    self.ytv_playbackState = YTVFeedPlaybackStatePlaying;
    self.ytv_pendingPlaybackRequestId = self.playerSession.currentRequestId;
    if (self.ytv_currentPlaybackFirstFrameReady && cell) {
        [cell ytv_hideCoverAfterFirstFrameAnimated:NO];
    }
    [self.playerSession play];
    self.ytv_userPausedWithPlayHint = NO;
    [self ytv_refreshInteractionChrome];
    (void)bindIdx;
}

- (void)ytv_prepareStandbyPlaybackForTargetIndex:(NSInteger)targetIdx {
    if (!self.ytv_categoryFeedActive || self.feedViewModel.state != YTVShortVideoFeedStateReady) {
        return;
    }
    if ([self ytv_shouldDeferNonCriticalStartupWork]) {
        return;
    }
    if (targetIdx < 0 || targetIdx >= (NSInteger)self.feedViewModel.numberOfItems) {
        self.ytv_standbyTargetIndex = NSNotFound;
        [self.preloadManager setDeepPrewarmTargetVideoId:nil];
        [self.playerSession clearStandbyPlayback];
        return;
    }
    if (targetIdx == self.currentPlayIndex) {
        return;
    }
    if (targetIdx == self.ytv_standbyTargetIndex) {
        return;
    }
    YTVVideoFeedItem *target = [self.feedViewModel itemAtIndex:targetIdx];
    NSURL *url = [self ytv_assetURLFromPlayURLString:target.playURL];
    NSString *scheme = url.scheme.lowercaseString;
    if (!target || target.videoId.length == 0 || !url || (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"file"])) {
        return;
    }
    self.ytv_standbyTargetIndex = targetIdx;
    self.ytv_playbackState = YTVFeedPlaybackStateStandbyPreparing;
    [self.preloadManager setDeepPrewarmTargetVideoId:target.videoId];
    [self.preloadManager warmAroundDisplayIndex:MAX(self.currentPlayIndex, 0) items:self.feedViewModel.items ringHeadTailPinned:[self ytv_shouldPinHeadTailInWarmPool]];
    AVPlayerItem *prepared = [self.preloadManager preparedPlayerItemForVideoId:target.videoId playURL:target.playURL];
    __weak typeof(self) weakSelf = self;
    [self.playerSession prepareStandbyPlaybackWithURL:url preferredPlayerItem:prepared completion:^(BOOL ready, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (self.ytv_standbyTargetIndex != targetIdx) {
            return;
        }
        (void)ready;
        (void)error;
    }];
}

/// 进入真正的切源流程：准备当前 cell、消费预热 item，并在回调里二次校验 pendingBindIndex。
- (void)ytv_replacePlaybackForItem:(YTVVideoFeedItem *)item
                               url:(NSURL *)url
                           bindIdx:(NSInteger)bindIdx
                              cell:(YTVShortVideoCell * _Nullable)cell {
    [self ytv_cancelPendingStartupPrimePlayback];
    NSString *targetURLString = url.absoluteString ?: @"";
    if (self.ytv_isSwitchingPlayback
        && self.ytv_pendingBindIndex == bindIdx
        && self.ytv_pendingPlaybackURLString.length > 0
        && [self.ytv_pendingPlaybackURLString isEqualToString:targetURLString]) {
        return;
    }
    [self ytv_finalizePlaybackPerformanceLogIfNeededWithReason:@"replace_playback" error:nil];
    self.ytv_isSwitchingPlayback = YES;
    self.ytv_playbackState = YTVFeedPlaybackStateSwitching;
    self.ytv_currentPlaybackFirstFrameReady = NO;
    self.ytv_pendingPlaybackURLString = targetURLString;
    self.ytv_currentPlaybackStartTime = CACurrentMediaTime();
    self.ytv_currentPlaybackReplaceStartTime = self.ytv_currentPlaybackStartTime;
    self.ytv_currentPlaybackItemReadyTime = 0;
    self.ytv_currentPlaybackFirstFrameTime = 0;
    self.ytv_currentPlaybackSourceLabel = self.feedViewModel.ytv_initialVideoSourceLabel ?: @"unknown";
    self.ytv_currentPlaybackUsedPreferredItem = NO;
    self.ytv_currentPlaybackStartedWithStartupGate = self.ytv_deferNonCriticalWarmUntilFirstFrame;
    [self ytv_resetPlaybackPerformanceTrackingForItem:item index:bindIdx];
    AVPlayerItem *prewarmed = [self.preloadManager preparedPlayerItemForVideoId:item.videoId playURL:item.playURL];
    AVPlayerItem *playbackSeedItem = nil;
    YTVVideoCachePlaybackDecision *cacheDecision = [self.preloadManager playbackDecisionForVideoId:item.videoId playURL:item.playURL];
    NSURL *playbackURL = cacheDecision.playbackURL;
    BOOL localCacheHit = (cacheDecision.playbackSource == YTVVideoCachePlaybackSourceDiskFile);
    if (!localCacheHit && !prewarmed && self.ytv_currentPlaybackStartedWithStartupGate) {
        playbackSeedItem = [self.preloadManager playbackSeedPlayerItemForVideoId:item.videoId playURL:item.playURL];
    }
    NSUInteger expectedRequestId = self.playerSession.currentRequestId + 1;
    self.ytv_pendingPlaybackRequestId = expectedRequestId;
    __weak typeof(self) weakSelf = self;
    AVPlayerLayer *playerLayer = cell ? cell.renderView.playerLayer : nil;
    __block NSUInteger requestId = 0;
    BOOL standbyReady = [self.playerSession standbyPlaybackReadyForURL:url];
    if (standbyReady) {
        self.ytv_currentPlaybackSourceLabel = [NSString stringWithFormat:@"%@+standby", self.ytv_currentPlaybackSourceLabel ?: @"unknown"];
        [self ytv_updatePlaybackResolvedURLMetadata:url];
        requestId = [self.playerSession promoteStandbyPlaybackByRebuildingItemMatchingURL:url playerLayer:playerLayer completion:^(NSError * _Nullable error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            if (self.currentPlayIndex != bindIdx || self.ytv_pendingBindIndex != bindIdx || self.ytv_pendingPlaybackRequestId != requestId) {
                return;
            }
            if (error) {
                [self ytv_failPlaybackAtIndex:bindIdx error:error];
                return;
            }
            [self.playerSession play];
            self.ytv_userPausedWithPlayHint = NO;
            [self ytv_refreshInteractionChrome];
        }];
    } else {
        NSURL *effectiveURL = playbackURL ?: url;
        [self ytv_updatePlaybackResolvedURLMetadata:effectiveURL];
        if (localCacheHit) {
            self.ytv_currentPlaybackSourceLabel = [NSString stringWithFormat:@"%@+%@", self.ytv_currentPlaybackSourceLabel ?: @"unknown", cacheDecision.sourceLabel ?: @"disk"];
        } else if (prewarmed) {
            self.ytv_currentPlaybackSourceLabel = [NSString stringWithFormat:@"%@+warm", self.ytv_currentPlaybackSourceLabel ?: @"unknown"];
            self.ytv_currentPlaybackUsedPreferredItem = YES;
        } else if (playbackSeedItem) {
            self.ytv_currentPlaybackSourceLabel = [NSString stringWithFormat:@"%@+warm_seed", self.ytv_currentPlaybackSourceLabel ?: @"unknown"];
        }
        requestId = [self.playerSession replacePlaybackWithURL:effectiveURL
                                       preferredPrewarmedPlayerItem:(localCacheHit ? nil : (prewarmed ?: playbackSeedItem))
                                                         playerLayer:playerLayer
                                                          completion:^(NSError * _Nullable error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            if (self.currentPlayIndex != bindIdx || self.ytv_pendingBindIndex != bindIdx || self.ytv_pendingPlaybackRequestId != requestId) {
                return;
            }
            if (error) {
                [self ytv_failPlaybackAtIndex:bindIdx error:error];
                return;
            }
            [self.playerSession play];
            self.ytv_userPausedWithPlayHint = NO;
            [self ytv_refreshInteractionChrome];
        }];
    }
    NSMutableString *beginLine = [NSMutableString stringWithFormat:@"%@ request_begin idx=%ld videoId=%@ source=%@ standby_ready=%@",
                                  kYTVPlaybackPerfLogPrefix,
                                  (long)bindIdx,
                                  item.videoId ?: @"<nil>",
                                  self.ytv_currentPlaybackSourceLabel ?: @"unknown",
                                  standbyReady ? @"YES" : @"NO"];
    [self ytv_appendPlaybackRequestFlagsToLogLine:beginLine];
    [beginLine appendFormat:@" cell_visible=%@", cell ? @"YES" : @"NO"];
    [self ytv_appendPlaybackResolvedLocationToLogLine:beginLine];
    [self ytv_appendPlaybackMaterialInfoToLogLine:beginLine item:item];
    NSLog(@"%@", beginLine);
    if (requestId != expectedRequestId && requestId != 0) {
        self.ytv_pendingPlaybackRequestId = requestId;
    }
}

- (void)ytv_applyPlaybackForItem:(YTVVideoFeedItem *)item
                         bindIdx:(NSInteger)bindIdx
    preserveStartupPresentation:(BOOL)preserveStartupPresentation {
    if (!self.ytv_categoryFeedActive || !item) {
        return;
    }
    if (preserveStartupPresentation) {
        [self ytv_setStartupPresentationItem:item index:bindIdx];
    }
    NSURL *assetURL = [self ytv_assetURLFromPlayURLString:item.playURL];
    NSString *assetScheme = assetURL.scheme.lowercaseString;
    if (!assetURL || (![assetScheme isEqualToString:@"http"] && ![assetScheme isEqualToString:@"https"] && ![assetScheme isEqualToString:@"file"])) {
        [self ytv_resetPlaybackSessionForInvalidCurrentItem];
        return;
    }
    YTVVideoCachePlaybackDecision *cacheDecision = [self.preloadManager playbackDecisionForVideoId:item.videoId playURL:item.playURL];
    NSURL *expectedPlaybackURL = cacheDecision.playbackURL ?: assetURL;
    [self.preloadManager markPlaybackProtectedVideoId:item.videoId];
    [self ytv_probeNaturalVideoSizeIfNeededForItem:item];
    self.ytv_pendingBindIndex = bindIdx;
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:bindIdx];
    if (cell) {
        [self ytv_prepareCellForSwitchingPlaybackAtIndex:bindIdx];
    } else {
        [self.playerSession bindPlayerLayerForFirstFrameObservation:nil];
    }
    AVPlayerItem *currentItem = self.playerSession.player.currentItem;
    if (currentItem && [currentItem.asset isKindOfClass:[AVURLAsset class]]) {
        NSURL *currentURL = [(AVURLAsset *)currentItem.asset URL];
        if (currentURL && expectedPlaybackURL && [currentURL.absoluteString isEqualToString:expectedPlaybackURL.absoluteString]) {
            [self ytv_resumePlaybackForCurrentItemAtIndex:bindIdx cell:cell];
            return;
        }
    }
    [self ytv_replacePlaybackForItem:item url:assetURL bindIdx:bindIdx cell:cell];
}

/// 绑定当前播放索引到共享 player；揭封面必须等待首帧事件，而不是仅靠 ReadyToPlay。
- (void)ytv_applyPlaybackForCurrentIndexIfPossible {
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    if (self.currentPlayIndex >= (NSInteger)self.feedViewModel.numberOfItems) {
        return;
    }
    NSInteger bindIdx = self.currentPlayIndex;
    if (self.ytv_pendingStartupPrimePlaybackIndex == bindIdx
        && [self ytv_shouldDeferNonCriticalStartupWork]
        && !self.ytv_isSwitchingPlayback
        && self.ytv_pendingBindIndex == NSNotFound) {
        return;
    }
    if ([self ytv_preserveStartupPlaybackWhileDeferringFeedReloadIfNeededAtIndex:bindIdx]) {
        return;
    }
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:bindIdx];
    [self ytv_applyPlaybackForItem:item bindIdx:bindIdx preserveStartupPresentation:NO];
}

- (void)ytv_applyPlaybackForBootstrapItem:(YTVVideoFeedItem *)item bindIdx:(NSInteger)bindIdx {
    if (!self.ytv_categoryFeedActive || !item) {
        return;
    }
    [self ytv_applyPlaybackForItem:item bindIdx:bindIdx preserveStartupPresentation:YES];
}

/// 点击整页任意区域统一切换暂停/继续播放。
- (void)ytv_handleVideoTapFromCell:(YTVShortVideoCell *)cell {
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
    NSInteger tapData = ip ? [self ytv_dataItemIndexForCollectionItem:(NSInteger)ip.item] : NSNotFound;
    if (!ip || tapData != self.currentPlayIndex) {
        return;
    }
    if (self.ytv_userPausedWithPlayHint) {
        [self.playerSession play];
        self.ytv_userPausedWithPlayHint = NO;
    } else {
        [self.playerSession pause];
        self.ytv_userPausedWithPlayHint = YES;
    }
    [self ytv_syncPausedPlayHintForCurrentCell];
}

/// 不强求 collectionView 立即布局；只有当前页 cell 已经可见时才返回，避免切页瞬间额外触发布局压力。
- (YTVShortVideoCell *)ytv_visibleCellForPlaybackIndexIfAvailable:(NSInteger)index {
    if (index == NSNotFound || index < 0 || index >= (NSInteger)self.feedViewModel.numberOfItems) {
        return nil;
    }
    for (UICollectionViewCell *rawCell in self.collectionView.visibleCells) {
        if (![rawCell isKindOfClass:[YTVShortVideoCell class]]) {
            continue;
        }
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:rawCell];
        NSInteger dataIdx = indexPath ? [self ytv_dataItemIndexForCollectionItem:(NSInteger)indexPath.item] : NSNotFound;
        if (indexPath && dataIdx == index) {
            return (YTVShortVideoCell *)rawCell;
        }
    }
    return nil;
}

- (YTVShortVideoCell *)ytv_currentCellForPlaybackIndex:(NSInteger)index {
    if (index == NSNotFound || index < 0 || index >= (NSInteger)self.feedViewModel.numberOfItems) {
        return nil;
    }
    NSInteger colItem = [self ytv_collectionItemIndexForRealIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:colItem inSection:0];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (![cell isKindOfClass:[YTVShortVideoCell class]]) {
        return nil;
    }
    return (YTVShortVideoCell *)cell;
}

/// 切源前统一准备当前 cell，先保封面，再挂共享 player。
/// 共享 player 只允许挂在当前播放 cell，其它可见 cell 一律回到封面态，避免半拖动时双页同时播同一条视频。
- (void)ytv_syncVisibleCellsForActivePlaybackIndex:(NSInteger)activeIndex {
    for (UICollectionViewCell *rawCell in self.collectionView.visibleCells) {
        if (![rawCell isKindOfClass:[YTVShortVideoCell class]]) {
            continue;
        }
        YTVShortVideoCell *cell = (YTVShortVideoCell *)rawCell;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        NSInteger dataIdx = indexPath ? [self ytv_dataItemIndexForCollectionItem:(NSInteger)indexPath.item] : NSNotFound;
        BOOL isActive = (indexPath != nil && dataIdx == activeIndex);
        if (isActive) {
            [cell renderView].playerLayer.player = self.playerSession.player;
            continue;
        }
        [cell.renderView attachPlayer:nil];
        [cell ytv_showCoverImmediately];
        [cell ytv_clearPlaybackFailureState];
        [cell ytv_setPausedPlayHintVisible:NO];
    }
}

- (void)ytv_prepareCellForSwitchingPlaybackAtIndex:(NSInteger)index {
    [self ytv_syncVisibleCellsForActivePlaybackIndex:index];
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:index];
    if (!cell) {
        [self.playerSession bindPlayerLayerForFirstFrameObservation:nil];
        return;
    }
    [cell ytv_showCoverImmediately];
    [cell ytv_clearPlaybackFailureState];
    [cell.renderView attachPlayer:self.playerSession.player];
    [self.playerSession bindPlayerLayerForFirstFrameObservation:cell.renderView.playerLayer];
}

- (void)ytv_bindPlaybackToCurrentCellIfNeeded:(YTVShortVideoCell *)cell
                                    dataIndex:(NSInteger)dataIdx
                                       reason:(NSString *)reason {
    if (!cell) {
        return;
    }
    BOOL current = (dataIdx == self.currentPlayIndex);
    if (current) {
        [cell.renderView attachPlayer:self.playerSession.player];
        [self.playerSession bindPlayerLayerForFirstFrameObservation:cell.renderView.playerLayer];
        if (self.ytv_currentPlaybackFirstFrameReady) {
            [cell ytv_hideCoverAfterFirstFrameAnimated:NO];
        } else {
            [cell ytv_showCoverImmediately];
        }
        if (self.ytv_isSwitchingPlayback
            || [self ytv_shouldDeferNonCriticalStartupWork]
            || [self ytv_shouldPreserveBootstrapPresentationDuringDeferredReload]) {
            NSLog(@"%@ visible_cell_bind idx=%ld videoId=%@ reason=%@ first_frame=%@ switching=%@",
                  kYTVPlaybackPerfLogPrefix,
                  (long)dataIdx,
                  self.ytv_perfSessionVideoId.length > 0 ? self.ytv_perfSessionVideoId : @"<nil>",
                  reason ?: @"unknown",
                  self.ytv_currentPlaybackFirstFrameReady ? @"YES" : @"NO",
                  self.ytv_isSwitchingPlayback ? @"YES" : @"NO");
        }
    } else {
        [cell.renderView attachPlayer:nil];
        [cell ytv_showCoverImmediately];
        [cell ytv_clearPlaybackFailureState];
    }
    [cell ytv_setPausedPlayHintVisible:current && self.ytv_userPausedWithPlayHint];
}

/// 首帧真正到达后再揭封面，并结束本次切换态。
- (void)ytv_finishFirstFrameAtIndex:(NSInteger)index {
    BOOL releasingStartupGate = self.ytv_deferNonCriticalWarmUntilFirstFrame;
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:index];
    [cell ytv_clearPlaybackFailureState];
    [cell ytv_hideCoverAfterFirstFrameAnimated:YES];
    [self ytv_commitPlaybackBindingAfterFirstFrame];
    self.ytv_deferNonCriticalWarmUntilFirstFrame = NO;
    [self ytv_applyDeferredFeedReloadAligningToActivePlaybackIfNeeded];
    [self ytv_updateStartupScrollLockIfNeeded];
    self.ytv_pendingPlaybackURLString = nil;
    self.ytv_currentPlaybackFromBootstrapRestore = NO;
    [self ytv_clearStartupPresentationItem];
    YTVVideoFeedItem *item = [self ytv_perfSessionItem];
    if (!item) {
        item = [self.feedViewModel itemAtIndex:index];
    }
    if (item) {
        NSInteger actualIndex = [self.feedViewModel ytv_indexOfVideoId:item.videoId];
        NSInteger recordIndex = actualIndex >= 0 ? actualIndex : index;
        [self.feedViewModel ytv_recordLastViewedVideoId:item.videoId playURL:item.playURL indexHint:recordIndex];
        [self.preloadManager prefetchPlaybackResourceForVideoId:item.videoId playURL:item.playURL];
        NSTimeInterval readyMs = self.ytv_currentPlaybackItemReadyTime > 0 && self.ytv_currentPlaybackReplaceStartTime > 0
            ? (self.ytv_currentPlaybackItemReadyTime - self.ytv_currentPlaybackReplaceStartTime) * 1000.0
            : -1;
        NSTimeInterval ttffMs = (CACurrentMediaTime() - self.ytv_currentPlaybackStartTime) * 1000.0;
        NSTimeInterval readyToFirstFrameMs = (readyMs >= 0) ? MAX(ttffMs - readyMs, 0) : -1;
        BOOL instant = (ttffMs <= (kYTVPlaybackInstantStartThresholdSeconds * 1000.0));
        NSInteger logIndex = actualIndex >= 0 ? actualIndex : index;
        NSMutableString *line = [NSMutableString stringWithFormat:@"%@ first_frame idx=%ld videoId=%@ source=%@ ttff=%.0fms instant=%@",
                                 kYTVPlaybackPerfLogPrefix,
                                 (long)logIndex,
                                 item.videoId ?: @"<nil>",
                                 self.ytv_currentPlaybackSourceLabel ?: @"unknown",
                                 ttffMs,
                                 instant ? @"YES" : @"NO"];
        if (readyMs >= 0) {
            [line appendFormat:@" item_ready=%.0fms", readyMs];
        }
        if (readyToFirstFrameMs >= 0) {
            [line appendFormat:@" ready_to_first_frame=%.0fms", readyToFirstFrameMs];
        }
        [self ytv_appendPlaybackRequestFlagsToLogLine:line];
        [self ytv_appendPlaybackResolvedLocationToLogLine:line];
        [self ytv_appendPlaybackMaterialInfoToLogLine:line item:item];
        NSLog(@"%@", line);
        [self ytv_beginPlaybackActiveSegmentIfNeeded];
        if (releasingStartupGate) {
            NSLog(@"%@ startup_gate_release idx=%ld videoId=%@ reason=first_frame",
                  kYTVPlaybackPerfLogPrefix,
                  (long)(actualIndex >= 0 ? actualIndex : index),
                  item.videoId ?: @"<nil>");
        }
    }
    NSInteger nData = (NSInteger)self.feedViewModel.numberOfItems;
    NSInteger standbyIdx = index + 1;
    if (standbyIdx >= nData) {
        if ([self ytv_loopRingScrollActive] && nData >= 2) {
            standbyIdx = 0;
        } else {
            standbyIdx = -1;
        }
    }
    [self ytv_prepareStandbyPlaybackForTargetIndex:standbyIdx];
    [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
}

/// 播放失败时保留封面，避免露出黑底或旧帧。
- (void)ytv_failPlaybackAtIndex:(NSInteger)index error:(NSError *)error {
    [self ytv_cancelPendingStartupPrimePlayback];
    [self ytv_clearStartupPresentationItem];
    [self ytv_finalizePlaybackPerformanceLogIfNeededWithReason:@"play_failed" error:error];
    if (self.ytv_deferNonCriticalWarmUntilFirstFrame) {
        YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:index];
        NSLog(@"%@ startup_gate_release idx=%ld videoId=%@ reason=play_failed",
              kYTVPlaybackPerfLogPrefix,
              (long)index,
              item.videoId ?: @"<nil>");
    }
    self.ytv_deferNonCriticalWarmUntilFirstFrame = NO;
    self.ytv_pendingFeedReloadAligningToActivePlayback = NO;
    [self ytv_updateStartupScrollLockIfNeeded];
    [self ytv_resetPlaybackBindingStateToIdle];
    self.ytv_playbackState = YTVFeedPlaybackStateFailed;
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:index];
    [cell ytv_showPlaybackFailureState];
    [self ytv_refreshInteractionChrome];
    (void)error;
}

/// 仅响应当前绑定对应的 requestId，避免快速连滑时旧回调污染 UI。
- (void)ytv_handlePlayerSessionEvent:(YTVPlayerSessionEventType)eventType requestId:(NSUInteger)requestId error:(NSError *)error {
    if (requestId == 0 || requestId != self.ytv_pendingPlaybackRequestId) {
        return;
    }
    NSInteger bindIdx = self.ytv_pendingBindIndex;
    if (bindIdx == NSNotFound || self.currentPlayIndex != bindIdx) {
        return;
    }
    switch (eventType) {
        case YTVPlayerSessionEventTypeItemReady:
            self.ytv_currentPlaybackItemReadyTime = CACurrentMediaTime();
            [self ytv_scheduleFirstFrameProbeForRequestId:requestId
                                                    index:bindIdx
                                                    delay:kYTVFirstFrameProbeDelayShortSeconds
                                                   reason:@"item_ready_250ms"];
            [self ytv_scheduleFirstFrameProbeForRequestId:requestId
                                                    index:bindIdx
                                                    delay:kYTVFirstFrameProbeDelayLongSeconds
                                                   reason:@"item_ready_900ms"];
            break;
        case YTVPlayerSessionEventTypeFirstFrameRendered:
            self.ytv_currentPlaybackFirstFrameTime = CACurrentMediaTime();
            [self ytv_finishFirstFrameAtIndex:bindIdx];
            break;
        case YTVPlayerSessionEventTypePlayFailed:
            [self ytv_failPlaybackAtIndex:bindIdx error:error];
            break;
    }
}

- (void)ytv_syncPausedPlayHintForCurrentCell {
    if (self.currentPlayIndex == NSNotFound) {
        for (UICollectionViewCell *raw in self.collectionView.visibleCells) {
            if ([raw isKindOfClass:[YTVShortVideoCell class]]) {
                [(YTVShortVideoCell *)raw ytv_setPausedPlayHintVisible:NO];
            }
        }
        return;
    }
    for (UICollectionViewCell *raw in self.collectionView.visibleCells) {
        if (![raw isKindOfClass:[YTVShortVideoCell class]]) {
            continue;
        }
        YTVShortVideoCell *c = (YTVShortVideoCell *)raw;
        NSIndexPath *rip = [self.collectionView indexPathForCell:c];
        NSInteger dataIdx = rip ? [self ytv_dataItemIndexForCollectionItem:(NSInteger)rip.item] : NSNotFound;
        BOOL isCurrent = (rip != nil && dataIdx == self.currentPlayIndex);
        [c ytv_setPausedPlayHintVisible:isCurrent && self.ytv_userPausedWithPlayHint];
    }
}

#pragma mark - 浮层互动（技术设计 §7 / 阶段 6）

- (void)ytv_refreshInteractionChrome {
    [self ytv_refreshVisibleCellsInteractionChrome];
    [self ytv_syncPausedPlayHintForCurrentCell];
}

/// 每条 cell 自带左下文案与右侧收藏/分享，随竖滑与视频同一图层移动。
- (void)ytv_refreshVisibleCellsInteractionChrome {
    if ([self ytv_shouldPreserveBootstrapPresentationDuringDeferredReload]) {
        return;
    }
    BOOL chromeOk = self.ytv_categoryFeedActive
        && self.feedViewModel.state == YTVShortVideoFeedStateReady
        && self.feedViewModel.numberOfItems > 0;
    NSInteger maxIdx = (NSInteger)self.feedViewModel.numberOfItems - 1;
    for (UICollectionViewCell *raw in self.collectionView.visibleCells) {
        if (![raw isKindOfClass:[YTVShortVideoCell class]]) {
            continue;
        }
        YTVShortVideoCell *cell = (YTVShortVideoCell *)raw;
        NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
        if (!ip) {
            [cell ytv_configureInteractionChromeWithItem:nil chromeEnabled:NO];
            continue;
        }
        NSInteger dataIdx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)ip.item];
        if (dataIdx < 0 || dataIdx > maxIdx) {
            [cell ytv_configureInteractionChromeWithItem:nil chromeEnabled:NO];
            continue;
        }
        YTVVideoFeedItem *item = [self ytv_displayItemForDataIndex:dataIdx];
        [cell ytv_configureInteractionChromeWithItem:item chromeEnabled:chromeOk];
    }
}

/// 跟手滑动：离屏中心越远整页越暗（含互动层），贴近抖音观感。
- (void)ytv_updateVisibleCellsSwipeDim {
    if (self.ytv_inlineFullscreenActive) {
        return;
    }
    CGFloat pageH = self.collectionView.bounds.size.height;
    if (pageH < 1) {
        return;
    }
    CGFloat viewportCenterY = self.collectionView.contentOffset.y + pageH * 0.5f;
    /// 略强于抖音常见值，便于感知；用略小于一页的归一化距离让「将走未走」阶段就更明显。
    static const CGFloat kYTVSwipeDimMaxAlpha = 0.68f;
    static const CGFloat kYTVSwipeDimFullAtPageFraction = 0.62f;
    for (UICollectionViewCell *raw in self.collectionView.visibleCells) {
        if (![raw isKindOfClass:[YTVShortVideoCell class]]) {
            continue;
        }
        YTVShortVideoCell *cell = (YTVShortVideoCell *)raw;
        CGRect cf = cell.frame;
        CGFloat cellCenterY = CGRectGetMidY(cf);
        CGFloat dist = (CGFloat)fabs((double)(cellCenterY - viewportCenterY));
        CGFloat denom = pageH * kYTVSwipeDimFullAtPageFraction;
        CGFloat progress = denom > 0.5f ? (dist / denom) : 0.f;
        if (progress > 1.f) {
            progress = 1.f;
        }
        CGFloat alpha = progress * kYTVSwipeDimMaxAlpha;
        [cell ytv_setSwipeDimOpacity:alpha];
    }
}

/// 将 `playURL` 规范为可交给 AVURLAsset 的 NSURL（含 file:// 与无 scheme 的绝对路径）。
- (nullable NSURL *)ytv_assetURLFromPlayURLString:(NSString *)playURL {
    if (playURL.length == 0) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:playURL];
    if (url && url.scheme.length > 0) {
        return url;
    }
    if ([playURL hasPrefix:@"/"]) {
        return [NSURL fileURLWithPath:playURL];
    }
    return nil;
}

/// 无接口宽高时异步读 tracks，避免竖滑首帧前无法区分横竖；失败则按竖版默认（全屏条）
- (void)ytv_probeNaturalVideoSizeIfNeededForItem:(YTVVideoFeedItem *)item {
    if (!item || item.ytv_hasNaturalVideoSize || item.playURL.length == 0) {
        return;
    }
    NSURL *url = [self ytv_assetURLFromPlayURLString:item.playURL];
    NSString *sc = url.scheme.lowercaseString;
    if (!url || (![sc isEqualToString:@"http"] && ![sc isEqualToString:@"https"] && ![sc isEqualToString:@"file"])) {
        return;
    }
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:@{ AVURLAssetPreferPreciseDurationAndTimingKey : @NO }];
    __weak typeof(self) weakSelf = self;
    NSString *videoId = [item.videoId copy];
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        AVKeyValueStatus st = [asset statusOfValueForKey:@"tracks" error:nil];
        CGFloat nw = 0;
        CGFloat nh = 0;
        if (st == AVKeyValueStatusLoaded) {
            NSArray<AVAssetTrack *> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if (tracks.count > 0) {
                AVAssetTrack *t = tracks.firstObject;
                CGSize ds = CGSizeApplyAffineTransform(t.naturalSize, t.preferredTransform);
                nw = (CGFloat)fabs(ds.width);
                nh = (CGFloat)fabs(ds.height);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || videoId.length == 0) {
                return;
            }
            NSInteger idx = [self.feedViewModel ytv_indexOfVideoId:videoId];
            if (idx < 0) {
                return;
            }
            YTVVideoFeedItem *it = [self.feedViewModel itemAtIndex:idx];
            if (!it || ![it.videoId isEqualToString:videoId] || it.ytv_hasNaturalVideoSize) {
                return;
            }
            if (nw >= 1.0 && nh >= 1.0) {
                it.ytv_naturalVideoWidth = nw;
                it.ytv_naturalVideoHeight = nh;
            } else {
                it.ytv_naturalVideoWidth = 1080;
                it.ytv_naturalVideoHeight = 1920;
            }
            it.ytv_hasNaturalVideoSize = YES;
            [self ytv_applyVideoLayoutHintForVideoId:videoId];
        });
    }];
}

- (void)ytv_applyVideoLayoutHintForVideoId:(NSString *)videoId {
    if (videoId.length == 0) {
        return;
    }
    NSInteger idx = [self.feedViewModel ytv_indexOfVideoId:videoId];
    if (idx < 0) {
        return;
    }
    NSInteger colItem = [self ytv_collectionItemIndexForRealIndex:idx];
    NSIndexPath *ip = [NSIndexPath indexPathForItem:colItem inSection:0];
    UICollectionViewCell *raw = [self.collectionView cellForItemAtIndexPath:ip];
    if ([raw isKindOfClass:[YTVShortVideoCell class]]) {
        YTVShortVideoCell *cell = (YTVShortVideoCell *)raw;
        YTVVideoFeedItem *it = [self.feedViewModel itemAtIndex:idx];
        [cell ytv_applyVideoLayoutFromFeedItem:it];
        BOOL chromeOk = self.ytv_categoryFeedActive && self.feedViewModel.state == YTVShortVideoFeedStateReady && self.feedViewModel.numberOfItems > 0;
        [cell ytv_configureInteractionChromeWithItem:[self ytv_displayItemForDataIndex:idx] chromeEnabled:chromeOk];
    }
    if (self.ytv_startupPresentationItem
        && [self.ytv_startupPresentationItem.videoId isEqualToString:videoId]
        && self.ytv_startupPresentationIndex != NSNotFound) {
        YTVVideoFeedItem *it = [self.feedViewModel itemAtIndex:idx];
        if (it) {
            self.ytv_startupPresentationItem.ytv_naturalVideoWidth = it.ytv_naturalVideoWidth;
            self.ytv_startupPresentationItem.ytv_naturalVideoHeight = it.ytv_naturalVideoHeight;
            self.ytv_startupPresentationItem.ytv_hasNaturalVideoSize = it.ytv_hasNaturalVideoSize;
        }
        NSInteger startupColItem = [self ytv_collectionItemIndexForRealIndex:self.ytv_startupPresentationIndex];
        NSIndexPath *startupIP = [NSIndexPath indexPathForItem:startupColItem inSection:0];
        UICollectionViewCell *startupRaw = [self.collectionView cellForItemAtIndexPath:startupIP];
        if ([startupRaw isKindOfClass:[YTVShortVideoCell class]]) {
            YTVShortVideoCell *startupCell = (YTVShortVideoCell *)startupRaw;
            YTVVideoFeedItem *displayItem = [self ytv_displayItemForDataIndex:self.ytv_startupPresentationIndex];
            [startupCell ytv_applyVideoLayoutFromFeedItem:displayItem];
            BOOL chromeOk = self.ytv_categoryFeedActive && self.feedViewModel.state == YTVShortVideoFeedStateReady && self.feedViewModel.numberOfItems > 0;
            [startupCell ytv_configureInteractionChromeWithItem:displayItem chromeEnabled:chromeOk];
        }
    }
}

- (void)ytv_onChromeSeeAllTapFromCell:(YTVShortVideoCell *)cell {
    NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
    if (!ip) {
        return;
    }
    NSInteger dataIdx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)ip.item];
    NSInteger idx = [self ytv_resolvedFeedIndexForPresentedDataIndex:dataIdx];
    if (idx < 0 || idx >= (NSInteger)self.feedViewModel.numberOfItems) {
        return;
    }
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:idx];
    if (item.fullTextURL.length > 0) {
        NSURL *u = [NSURL URLWithString:item.fullTextURL];
        NSString *scheme = u.scheme.lowercaseString;
        if (!u || (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"])) {
            [MBProgressHUD showLabel:NSLocalizedString(@"YTV_full_text_invalid", @"")];
            return;
        }
        VideoTextWebViewController *web = [[VideoTextWebViewController alloc] initWithPageURL:u];
        [self.navigationController pushViewController:web animated:YES];
        return;
    }
    [MBProgressHUD showLabel:NSLocalizedString(@"YTV_feed_demo_see_all_toast", @"")];
}

- (void)ytv_showNextLoadFailureWithMessage:(NSString *)msg {
    if (!self.ytv_categoryFeedActive || self.feedViewModel.state != YTVShortVideoFeedStateReady) {
        return;
    }
    self.nextLoadFailureLabel.text = msg.length ? msg : NSLocalizedString(@"YTV_feed_next_failed_hint", @"");
    self.nextLoadFailureBar.hidden = NO;
    [self.view bringSubviewToFront:self.nextLoadFailureBar];
}

- (void)ytv_hideNextLoadFailureBar {
    self.nextLoadFailureBar.hidden = YES;
}

- (void)ytv_onNextLoadFailureRetryTap {
    [self ytv_hideNextLoadFailureBar];
    self.ytv_allowWrapFromLastAfterTailFetchIdle = NO;
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    [self ytv_maybePrefetchNextForDisplayIndex:self.currentPlayIndex];
}

- (void)ytv_onFavoriteChromeTapFromCell:(YTVShortVideoCell *)cell {
    if (![LoginManager checkLoginAndPresentIfNeededFrom:self]) {
        return;
    }
    NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
    if (!ip) {
        return;
    }
    NSInteger dataIdx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)ip.item];
    NSInteger idx = [self ytv_resolvedFeedIndexForPresentedDataIndex:dataIdx];
    if (idx < 0 || idx >= (NSInteger)self.feedViewModel.numberOfItems) {
        return;
    }
    NSInteger idxBefore = idx;
    __weak typeof(self) weakSelf = self;
    [self.feedViewModel toggleFavoriteAtDisplayIndex:idx completion:^(BOOL success, NSString *message) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_refreshInteractionChrome];
        if (!success && message.length > 0) {
            [MBProgressHUD showLabel:message];
            return;
        }
        if (success && self.feedViewModel.feedSource == YTVShortVideoFeedSourceFavorites) {
            NSUInteger n = self.feedViewModel.numberOfItems;
            if (n == 0) {
                [self.navigationController popViewControllerAnimated:YES];
                return;
            }
            NSInteger newIdx = MIN(idxBefore, (NSInteger)n - 1);
            newIdx = MAX(0, newIdx);
            self.ytv_userPausedWithPlayHint = NO;
            self.ytv_lastProvisionalWarmIndex = NSNotFound;
            self.ytv_lastProvisionalWarmVelocityBucket = NSNotFound;
            self.currentPlayIndex = newIdx;
            [self.collectionView reloadData];
            [self.collectionView layoutIfNeeded];
            [self ytv_applyContentOffsetForRealIndex:newIdx];
            [self ytv_applyPlaybackForCurrentIndexIfPossible];
            [self ytv_maybePrefetchNextForDisplayIndex:newIdx];
            [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
        }
    }];
    [self ytv_refreshInteractionChrome];
}

- (void)ytv_onFullScreenChromeTapFromCell:(YTVShortVideoCell *)cell {
    NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
    if (!ip) {
        return;
    }
    NSInteger dataIdx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)ip.item];
    if (dataIdx != self.currentPlayIndex) {
        return;
    }
    NSInteger idx = [self ytv_resolvedFeedIndexForPresentedDataIndex:dataIdx];
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:idx];
    if (!item || item.playURL.length == 0) {
        return;
    }
    if (!item.ytv_hasNaturalVideoSize || ![item ytv_isLandscapeNaturalVideo]) {
        return;
    }
    NSURL *u = [self ytv_assetURLFromPlayURLString:item.playURL];
    NSString *s = u.scheme.lowercaseString;
    if (!u || (![s isEqualToString:@"http"] && ![s isEqualToString:@"https"] && ![s isEqualToString:@"file"])) {
        return;
    }
    [self ytv_enterInlineFullscreenAnimated];
}

#pragma mark - 内联全屏（抖音式：同 renderView 旋转扩大，播放不中断）

- (void)ytv_onInlineFullscreenBackTap {
    [self ytv_exitInlineFullscreenAnimated];
}

/// 全屏遮罩挂在 window 上才能盖住主 TabBar；window 尚未挂上时用 Tab 根视图或当前 VC 视图兜底。
- (UIView *)ytv_inlineFullscreenContainerView {
    UIWindow *win = self.view.window;
    if (win) {
        return win;
    }
    if (self.tabBarController.view) {
        return self.tabBarController.view;
    }
    if (self.navigationController.view) {
        return self.navigationController.view;
    }
    return self.view;
}

- (void)ytv_dismissInlineFullscreenIfNeededAnimated:(BOOL)animated {
    if (!self.ytv_inlineFullscreenActive && !self.ytv_inlineFullscreenHostView) {
        return;
    }
    if (animated) {
        [self ytv_exitInlineFullscreenAnimated];
    } else {
        [self ytv_teardownInlineFullscreenImmediate];
    }
}

- (void)ytv_teardownInlineFullscreenImmediate {
    [self ytv_inlineFullscreenRemoveTimeObserverIfNeeded];
    YTVShortVideoCell *srcChrome = self.ytv_inlineFullscreenSourceCell;
    YTVVideoRenderView *rv = self.ytv_inlineFullscreenRenderView;
    UIView *host = self.ytv_inlineFullscreenHostView;
    UIView *stage = self.ytv_inlineFullscreenStageView;
    UIView *overlay = self.ytv_inlineFullscreenOverlayView;
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:self.currentPlayIndex];
    if (!cell) {
        cell = self.ytv_inlineFullscreenSourceCell;
    }
    if (stage) {
        stage.transform = CGAffineTransformIdentity;
        stage.frame = self.ytv_inlineFullscreenStartFrameInHost;
    }
    if (rv) {
        rv.transform = CGAffineTransformIdentity;
        rv.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [rv removeFromSuperview];
        if (cell) {
            [cell.contentView insertSubview:rv atIndex:0];
            [cell setNeedsLayout];
            [cell layoutIfNeeded];
        }
        [self.playerSession bindPlayerLayerForFirstFrameObservation:rv.playerLayer];
    }
    if (overlay) {
        [overlay removeFromSuperview];
    }
    if (stage) {
        [stage removeFromSuperview];
    }
    self.ytv_inlineFullscreenStageView = nil;
    self.ytv_inlineFullscreenOverlayView = nil;
    self.ytv_inlineFullscreenBackButton = nil;
    self.ytv_inlineFullscreenCenterPlayButton = nil;
    self.ytv_inlineFullscreenProgressSlider = nil;
    self.ytv_inlineFullscreenCurrentTimeLabel = nil;
    self.ytv_inlineFullscreenDurationLabel = nil;
    self.ytv_inlineFullscreenScrubbing = NO;
    if (host) {
        [host removeFromSuperview];
    }
    self.ytv_inlineFullscreenHostView = nil;
    self.ytv_inlineFullscreenActive = NO;
    self.ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled = NO;
    self.ytv_inlineFullscreenLastAppliedChromeInsets = (UIEdgeInsets){ -999, -999, -999, -999 };
    if (srcChrome) {
        [srcChrome ytv_setInteractionChromeSuppressed:NO];
    }
    self.ytv_inlineFullscreenSourceCell = nil;
    self.ytv_inlineFullscreenRenderView = nil;
    self.collectionView.scrollEnabled = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    [self ytv_refreshInteractionChrome];
    [self ytv_syncPausedPlayHintForCurrentCell];
    [self ytv_updateVisibleCellsSwipeDim];
}

/// 返回 / 进度条相对 overlay 的边距：按 window safeArea 与当前旋转算，避免压状态栏、刘海或底部 Home 条
- (void)ytv_updateInlineFullscreenChromeInsetsFromWindowSafeArea {
    if (!self.ytv_inlineFullscreenActive) {
        return;
    }
    UIView *overlay = self.ytv_inlineFullscreenOverlayView;
    UIView *host = self.ytv_inlineFullscreenHostView;
    UIButton *back = self.ytv_inlineFullscreenBackButton;
    UISlider *slider = self.ytv_inlineFullscreenProgressSlider;
    UILabel *curL = self.ytv_inlineFullscreenCurrentTimeLabel;
    UILabel *durL = self.ytv_inlineFullscreenDurationLabel;
    if (!overlay || !host || !back || !slider || !curL || !durL) {
        return;
    }
    UIWindow *win = host.window ?: self.view.window;
    if (!win) {
        return;
    }
    UIEdgeInsets next = YTVInlineFullscreenChromeInsetsMatchingWindowSafeArea(overlay, win);
    if (YTVInlineFullscreenEdgeInsetsAlmostEqual(self.ytv_inlineFullscreenLastAppliedChromeInsets, next)) {
        return;
    }
    self.ytv_inlineFullscreenLastAppliedChromeInsets = next;
    [UIView performWithoutAnimation:^{
        [back mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(overlay).offset(next.top);
            make.left.equalTo(overlay).offset(next.left);
        }];
        [slider mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(overlay).offset(next.left);
            make.right.equalTo(overlay).offset(-next.right);
            make.bottom.equalTo(overlay).offset(-next.bottom);
        }];
        [curL mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(overlay).offset(next.left);
            make.bottom.equalTo(slider.mas_top).offset(-6);
        }];
        [durL mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(overlay).offset(-next.right);
            make.bottom.equalTo(curL);
        }];
        [host setNeedsLayout];
        [host layoutIfNeeded];
    }];
}

- (void)ytv_enterInlineFullscreenAnimated {
    if (self.ytv_inlineFullscreenActive) {
        return;
    }
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:self.currentPlayIndex];
    if (!cell) {
        cell = [self ytv_currentCellForPlaybackIndex:self.currentPlayIndex];
    }
    if (!cell) {
        return;
    }
    YTVVideoRenderView *rv = cell.renderView;
    UIView *fsContainer = [self ytv_inlineFullscreenContainerView];
    CGRect startInContainer = [rv convertRect:rv.bounds toView:fsContainer];
    UIView *host = [[UIView alloc] initWithFrame:fsContainer.bounds];
    host.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    host.backgroundColor = [UIColor blackColor];
    CGRect startInHost = [host convertRect:startInContainer fromView:fsContainer];
    self.ytv_inlineFullscreenStartFrameInHost = startInHost;
    self.ytv_inlineFullscreenActive = YES;
    self.ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled = NO;
    self.ytv_inlineFullscreenLastAppliedChromeInsets = (UIEdgeInsets){ -999, -999, -999, -999 };
    self.ytv_inlineFullscreenSourceCell = cell;
    [cell ytv_setInteractionChromeSuppressed:YES];
    self.ytv_inlineFullscreenRenderView = rv;
    self.ytv_inlineFullscreenHostView = host;
    [fsContainer addSubview:host];
    [fsContainer bringSubviewToFront:host];
    [rv removeFromSuperview];
    rv.transform = CGAffineTransformIdentity;
    UIView *stage = [[UIView alloc] initWithFrame:startInHost];
    stage.backgroundColor = [UIColor clearColor];
    stage.clipsToBounds = NO;
    self.ytv_inlineFullscreenStageView = stage;
    [host addSubview:stage];
    rv.frame = stage.bounds;
    rv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    rv.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [stage addSubview:rv];
    UIView *overlay = [[UIView alloc] initWithFrame:stage.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [UIColor clearColor];
    overlay.userInteractionEnabled = YES;
    /// 旋转结束前隐藏操作层，避免先用小 stage 算边距再跳到终态产生「刷新」感
    overlay.alpha = 0;
    self.ytv_inlineFullscreenOverlayView = overlay;
    [stage addSubview:overlay];
    [stage bringSubviewToFront:overlay];
    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    [back setTitle:NSLocalizedString(@"YTV_fullscreen_back", @"") forState:UIControlStateNormal];
    back.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    [back setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    back.tintColor = [UIColor whiteColor];
    back.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.42];
    back.layer.cornerRadius = 8;
    back.clipsToBounds = YES;
    back.contentEdgeInsets = UIEdgeInsetsMake(8, 12, 8, 12);
    [back addTarget:self action:@selector(ytv_onInlineFullscreenBackTap) forControlEvents:UIControlEventTouchUpInside];
    self.ytv_inlineFullscreenBackButton = back;
    [overlay addSubview:back];
    UIButton *centerPlay = [UIButton buttonWithType:UIButtonTypeSystem];
    centerPlay.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.95];
    centerPlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.22];
    centerPlay.layer.cornerRadius = 36;
    centerPlay.clipsToBounds = YES;
    [centerPlay addTarget:self action:@selector(ytv_onInlineFullscreenCenterPlayTap) forControlEvents:UIControlEventTouchUpInside];
    self.ytv_inlineFullscreenCenterPlayButton = centerPlay;
    [overlay addSubview:centerPlay];
    [centerPlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(overlay);
        make.width.height.mas_equalTo(72);
    }];
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = 0;
    slider.maximumValue = 1;
    slider.continuous = YES;
    slider.minimumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
    slider.maximumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.28];
    [slider addTarget:self action:@selector(ytv_onInlineFullscreenSliderTouchDown) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(ytv_onInlineFullscreenSliderRelease) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [slider addTarget:self action:@selector(ytv_inlineFullscreenUpdateTimeLabels) forControlEvents:UIControlEventValueChanged];
    self.ytv_inlineFullscreenProgressSlider = slider;
    [overlay addSubview:slider];
    UILabel *curTL = [[UILabel alloc] init];
    curTL.textColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        curTL.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightMedium];
    } else {
        curTL.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    }
    curTL.text = @"00:00";
    curTL.layer.shadowColor = [UIColor blackColor].CGColor;
    curTL.layer.shadowOffset = CGSizeMake(0, 1);
    curTL.layer.shadowRadius = 2;
    curTL.layer.shadowOpacity = 0.85;
    self.ytv_inlineFullscreenCurrentTimeLabel = curTL;
    [overlay addSubview:curTL];
    UILabel *durTL = [[UILabel alloc] init];
    durTL.textColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        durTL.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightMedium];
    } else {
        durTL.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    }
    durTL.textAlignment = NSTextAlignmentRight;
    durTL.text = @"00:00";
    durTL.layer.shadowColor = [UIColor blackColor].CGColor;
    durTL.layer.shadowOffset = CGSizeMake(0, 1);
    durTL.layer.shadowRadius = 2;
    durTL.layer.shadowOpacity = 0.85;
    self.ytv_inlineFullscreenDurationLabel = durTL;
    [overlay addSubview:durTL];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(overlay);
    }];
    [slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(overlay);
    }];
    [curTL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(overlay);
        make.bottom.equalTo(slider.mas_top).offset(-6);
    }];
    [durTL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(overlay);
        make.bottom.equalTo(curTL);
    }];
    [self ytv_inlineFullscreenUpdateCenterPlayButtonAppearance];
    [self ytv_inlineFullscreenSyncProgressUIFromPlayer];
    [self ytv_inlineFullscreenUpdateTimeLabels];
    [host setNeedsLayout];
    [host layoutIfNeeded];
    self.collectionView.scrollEnabled = NO;
    for (UICollectionViewCell *raw in self.collectionView.visibleCells) {
        if ([raw isKindOfClass:[YTVShortVideoCell class]]) {
            [(YTVShortVideoCell *)raw ytv_setSwipeDimOpacity:0];
        }
    }
    self.nextLoadFailureBar.hidden = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.45
                          delay:0
         usingSpringWithDamping:0.92
          initialSpringVelocity:0.25
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        CGFloat W = CGRectGetWidth(host.bounds);
        CGFloat H = CGRectGetHeight(host.bounds);
        UIView *st = self.ytv_inlineFullscreenStageView;
        st.bounds = CGRectMake(0, 0, H, W);
        st.center = CGPointMake(W * 0.5, H * 0.5);
        st.transform = CGAffineTransformMakeRotation((CGFloat)M_PI_2);
        rv.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    } completion:^(__unused BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.ytv_inlineFullscreenActive) {
            return;
        }
        [self ytv_inlineFullscreenInstallTimeObserver];
        [self ytv_inlineFullscreenSyncProgressUIFromPlayer];
        [self ytv_inlineFullscreenUpdateTimeLabels];
        [self ytv_inlineFullscreenUpdateCenterPlayButtonAppearance];
        self.ytv_inlineFullscreenLastAppliedChromeInsets = (UIEdgeInsets){ -999, -999, -999, -999 };
        [self ytv_updateInlineFullscreenChromeInsetsFromWindowSafeArea];
        self.ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled = YES;
        self.ytv_inlineFullscreenOverlayView.alpha = 1;
    }];
}

- (void)ytv_exitInlineFullscreenAnimated {
    if (!self.ytv_inlineFullscreenActive) {
        return;
    }
    self.ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled = NO;
    [self ytv_inlineFullscreenRemoveTimeObserverIfNeeded];
    YTVVideoRenderView *rv = self.ytv_inlineFullscreenRenderView;
    UIView *host = self.ytv_inlineFullscreenHostView;
    UIView *stage = self.ytv_inlineFullscreenStageView;
    UIView *overlay = self.ytv_inlineFullscreenOverlayView;
    if (!rv || !host || !stage) {
        [self ytv_teardownInlineFullscreenImmediate];
        return;
    }
    CGRect endFrame = self.ytv_inlineFullscreenStartFrameInHost;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.42
                          delay:0
         usingSpringWithDamping:0.94
          initialSpringVelocity:0.2
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        stage.transform = CGAffineTransformIdentity;
        stage.bounds = CGRectMake(0, 0, endFrame.size.width, endFrame.size.height);
        stage.center = CGPointMake(CGRectGetMidX(endFrame), CGRectGetMidY(endFrame));
        rv.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        if (overlay) {
            overlay.alpha = 0;
        }
    } completion:^(__unused BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_teardownInlineFullscreenImmediate];
        if (!self.ytv_userPausedWithPlayHint) {
            [self.playerSession play];
        } else {
            [self.playerSession pause];
        }
        [self ytv_syncPausedPlayHintForCurrentCell];
    }];
}

- (void)ytv_inlineFullscreenRemoveTimeObserverIfNeeded {
    if (!self.ytv_inlineFullscreenTimeObserver) {
        return;
    }
    AVPlayer *p = self.playerSession.player;
    if (p) {
        [p removeTimeObserver:self.ytv_inlineFullscreenTimeObserver];
    }
    self.ytv_inlineFullscreenTimeObserver = nil;
}

- (void)ytv_inlineFullscreenInstallTimeObserver {
    [self ytv_inlineFullscreenRemoveTimeObserverIfNeeded];
    if (!self.ytv_inlineFullscreenActive) {
        return;
    }
    AVPlayer *p = self.playerSession.player;
    if (!p) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    CMTime interval = CMTimeMakeWithSeconds(0.25, NSEC_PER_SEC);
    self.ytv_inlineFullscreenTimeObserver = [p addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock:^(__unused CMTime time) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.ytv_inlineFullscreenActive) {
            return;
        }
        [self ytv_inlineFullscreenSyncProgressUIFromPlayer];
        [self ytv_inlineFullscreenUpdateTimeLabels];
        [self ytv_inlineFullscreenUpdateCenterPlayButtonAppearance];
    }];
}

- (Float64)ytv_inlineFullscreenDurationSeconds {
    AVPlayerItem *pi = self.playerSession.player.currentItem;
    Float64 dur = 0;
    if (pi) {
        dur = CMTimeGetSeconds(pi.duration);
    }
    if (!isfinite(dur) || dur <= 0) {
        YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:self.currentPlayIndex];
        if (item && item.durationMs > 0) {
            dur = item.durationMs / 1000.0;
        }
    }
    return dur;
}

- (void)ytv_inlineFullscreenUpdateTimeLabels {
    if (!self.ytv_inlineFullscreenActive) {
        return;
    }
    UILabel *c = self.ytv_inlineFullscreenCurrentTimeLabel;
    UILabel *d = self.ytv_inlineFullscreenDurationLabel;
    if (!c || !d) {
        return;
    }
    Float64 dur = [self ytv_inlineFullscreenDurationSeconds];
    if (!isfinite(dur) || dur < 0) {
        dur = 0;
    }
    Float64 cur = 0;
    if (self.ytv_inlineFullscreenScrubbing) {
        UISlider *sl = self.ytv_inlineFullscreenProgressSlider;
        if (sl && isfinite(dur) && dur > 0) {
            cur = (Float64)sl.value * dur;
        } else {
            AVPlayer *pl = self.playerSession.player;
            if (pl) {
                cur = CMTimeGetSeconds(pl.currentTime);
            }
        }
    } else {
        AVPlayer *pl = self.playerSession.player;
        if (pl) {
            cur = CMTimeGetSeconds(pl.currentTime);
        }
    }
    if (!isfinite(cur) || cur < 0) {
        cur = 0;
    }
    c.text = YTVInlineFullscreenFormatMinuteSecond(cur);
    d.text = YTVInlineFullscreenFormatMinuteSecond(dur);
}

- (void)ytv_inlineFullscreenSyncProgressUIFromPlayer {
    if (!self.ytv_inlineFullscreenActive || self.ytv_inlineFullscreenScrubbing) {
        return;
    }
    UISlider *sl = self.ytv_inlineFullscreenProgressSlider;
    if (!sl) {
        return;
    }
    Float64 dur = [self ytv_inlineFullscreenDurationSeconds];
    Float64 cur = CMTimeGetSeconds(self.playerSession.player.currentTime);
    if (isfinite(dur) && dur > 0 && isfinite(cur) && cur >= 0) {
        sl.enabled = YES;
        sl.value = (float)fmin(1.0, fmax(0, cur / dur));
    } else {
        sl.enabled = NO;
        sl.value = 0;
    }
}

- (void)ytv_inlineFullscreenSeekToNormalized:(float)n {
    Float64 dur = [self ytv_inlineFullscreenDurationSeconds];
    if (!isfinite(dur) || dur <= 0) {
        return;
    }
    double t = (double)n * dur;
    CMTime ct = CMTimeMakeWithSeconds(t, NSEC_PER_SEC);
    __weak typeof(self) weakSelf = self;
    [self.playerSession.player seekToTime:ct toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(__unused BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_inlineFullscreenSyncProgressUIFromPlayer];
        [self ytv_inlineFullscreenUpdateTimeLabels];
    }];
}

- (void)ytv_onInlineFullscreenSliderTouchDown {
    self.ytv_inlineFullscreenScrubbing = YES;
}

- (void)ytv_onInlineFullscreenSliderRelease {
    self.ytv_inlineFullscreenScrubbing = NO;
    UISlider *sl = self.ytv_inlineFullscreenProgressSlider;
    if (sl) {
        [self ytv_inlineFullscreenSeekToNormalized:sl.value];
    }
}

- (void)ytv_inlineFullscreenUpdateCenterPlayButtonAppearance {
    UIButton *b = self.ytv_inlineFullscreenCenterPlayButton;
    if (!b || !self.ytv_inlineFullscreenActive) {
        return;
    }
    AVPlayer *p = self.playerSession.player;
    BOOL paused = self.ytv_userPausedWithPlayHint || fabs(p.rate) < 0.01;
    UIImage *img = nil;
    if (@available(iOS 13.0, *)) {
        img = [UIImage systemImageNamed:paused ? @"play.circle.fill" : @"pause.circle.fill"];
    }
    if (img) {
        img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [b setImage:img forState:UIControlStateNormal];
        [b setTitle:nil forState:UIControlStateNormal];
    } else {
        [b setImage:nil forState:UIControlStateNormal];
        [b setTitle:NSLocalizedString(paused ? @"YTV_fullscreen_play_hint" : @"YTV_fullscreen_pause_hint", @"") forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
    }
    b.accessibilityLabel = NSLocalizedString(paused ? @"YTV_fullscreen_play_hint" : @"YTV_fullscreen_pause_hint", @"");
}

- (void)ytv_onInlineFullscreenCenterPlayTap {
    if (!self.ytv_categoryFeedActive || self.currentPlayIndex == NSNotFound) {
        return;
    }
    if (self.ytv_userPausedWithPlayHint) {
        [self.playerSession play];
        self.ytv_userPausedWithPlayHint = NO;
    } else {
        [self.playerSession pause];
        self.ytv_userPausedWithPlayHint = YES;
    }
    [self ytv_inlineFullscreenUpdateCenterPlayButtonAppearance];
}

- (void)ytv_onShareChromeTapFromCell:(YTVShortVideoCell *)cell {
    NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
    if (!ip) {
        return;
    }
    NSInteger dataIdx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)ip.item];
    NSInteger idx = [self ytv_resolvedFeedIndexForPresentedDataIndex:dataIdx];
    if (idx < 0 || idx >= (NSInteger)self.feedViewModel.numberOfItems) {
        return;
    }
    if (![self.feedViewModel itemAtIndex:idx]) {
        return;
    }
    [YTVVideoPRDShareHelper ytv_presentSystemShareFromViewController:self
                                                         sourceView:[cell ytv_shareChromePresentationAnchor]];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section != 0) {
        return 0;
    }
    return (NSInteger)[self ytv_collectionDisplayItemCount];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YTVShortVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kYTVShortVideoCellId forIndexPath:indexPath];
    NSInteger dataIdx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)indexPath.item];
    YTVVideoFeedItem *item = [self ytv_displayItemForDataIndex:dataIdx];
    [cell configureWithItem:item];
    BOOL chromeOk = self.ytv_categoryFeedActive && self.feedViewModel.state == YTVShortVideoFeedStateReady && self.feedViewModel.numberOfItems > 0;
    [cell ytv_configureInteractionChromeWithItem:item chromeEnabled:chromeOk];
    __weak typeof(self) weakSelf = self;
    cell.ytv_onFavoriteChromeTap = ^(YTVShortVideoCell *c) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_onFavoriteChromeTapFromCell:c];
    };
    cell.ytv_onShareChromeTap = ^(YTVShortVideoCell *c) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_onShareChromeTapFromCell:c];
    };
    cell.ytv_onFullScreenChromeTap = ^(YTVShortVideoCell *c) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_onFullScreenChromeTapFromCell:c];
    };
    cell.ytv_onChromeSeeAllTap = ^(YTVShortVideoCell *c) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_onChromeSeeAllTapFromCell:c];
    };
    cell.ytv_onVideoAreaTap = ^(YTVShortVideoCell *c) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_handleVideoTapFromCell:c];
    };
    cell.ytv_onPlaybackRetryTap = ^(YTVShortVideoCell *c) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        NSIndexPath *retryIndexPath = [self.collectionView indexPathForCell:c];
        if (!retryIndexPath) {
            return;
        }
        NSInteger retryIdx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)retryIndexPath.item];
        [self ytv_beginPlaybackSwitchToIndex:retryIdx fromOldIndex:self.currentPlayIndex];
    };
    [self ytv_bindPlaybackToCurrentCellIfNeeded:cell dataIndex:dataIdx reason:@"cell_for_item"];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
  willDisplayCell:(UICollectionViewCell *)cell
forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView != self.collectionView) {
        return;
    }
    if (![cell isKindOfClass:[YTVShortVideoCell class]]) {
        return;
    }
    NSInteger dataIdx = [self ytv_dataItemIndexForCollectionItem:(NSInteger)indexPath.item];
    [self ytv_bindPlaybackToCurrentCellIfNeeded:(YTVShortVideoCell *)cell dataIndex:dataIdx reason:@"will_display"];
}

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (collectionView != self.collectionView) {
        return;
    }
    [self ytv_prefetchContentForIndexPaths:indexPaths];
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    (void)collectionView;
    (void)indexPaths;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.bounds.size;
}

#pragma mark - Lazy

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.sectionInset = UIEdgeInsetsZero;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor blackColor];
        _collectionView.pagingEnabled = YES;
        _collectionView.bounces = YES;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        if (@available(iOS 10.0, *)) {
            _collectionView.prefetchDataSource = self;
            _collectionView.prefetchingEnabled = YES;
        }
        [_collectionView registerClass:[YTVShortVideoCell class] forCellWithReuseIdentifier:kYTVShortVideoCellId];
    }
    return _collectionView;
}

- (UIView *)stateOverlay {
    if (!_stateOverlay) {
        _stateOverlay = [[UIView alloc] init];
        _stateOverlay.backgroundColor = [UIColor blackColor];
    }
    return _stateOverlay;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc] init];
        _stateLabel.textAlignment = NSTextAlignmentCenter;
        _stateLabel.numberOfLines = 0;
        _stateLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
        _stateLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
    }
    return _stateLabel;
}

- (UIButton *)retryButton {
    if (!_retryButton) {
        _retryButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_retryButton setTitle:NSLocalizedString(@"YTV_feed_retry", @"") forState:UIControlStateNormal];
        [_retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _retryButton.tintColor = [UIColor whiteColor];
        [_retryButton addTarget:self action:@selector(ytv_onRetryTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _retryButton;
}

- (UIImageView *)stateEmptyImageView {
    if (!_stateEmptyImageView) {
        _stateEmptyImageView = [[UIImageView alloc] init];
        _stateEmptyImageView.contentMode = UIViewContentModeScaleAspectFit;
        _stateEmptyImageView.alpha = 0.45;
        UIImage *img = [UIImage imageNamed:@"YTV_video_empty_state"];
        if (!img) {
            img = [UIImage imageNamed:@"not_logo"];
        }
        _stateEmptyImageView.image = img;
        _stateEmptyImageView.hidden = YES;
    }
    return _stateEmptyImageView;
}

- (UILabel *)nextLoadFailureLabel {
    if (!_nextLoadFailureLabel) {
        _nextLoadFailureLabel = [[UILabel alloc] init];
        _nextLoadFailureLabel.textAlignment = NSTextAlignmentCenter;
        _nextLoadFailureLabel.numberOfLines = 2;
        _nextLoadFailureLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
        _nextLoadFailureLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        _nextLoadFailureLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _nextLoadFailureLabel;
}

- (UIButton *)nextLoadFailureRetryButton {
    if (!_nextLoadFailureRetryButton) {
        _nextLoadFailureRetryButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_nextLoadFailureRetryButton setTitle:NSLocalizedString(@"YTV_feed_next_retry", @"") forState:UIControlStateNormal];
        _nextLoadFailureRetryButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        [_nextLoadFailureRetryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _nextLoadFailureRetryButton.tintColor = [UIColor whiteColor];
        [_nextLoadFailureRetryButton addTarget:self action:@selector(ytv_onNextLoadFailureRetryTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextLoadFailureRetryButton;
}

- (UIView *)nextLoadFailureBar {
    if (!_nextLoadFailureBar) {
        _nextLoadFailureBar = [[UIView alloc] init];
        _nextLoadFailureBar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.82];
        _nextLoadFailureBar.layer.cornerRadius = 10;
        _nextLoadFailureBar.clipsToBounds = YES;
        _nextLoadFailureBar.hidden = YES;
        [_nextLoadFailureBar addSubview:self.nextLoadFailureLabel];
        [_nextLoadFailureBar addSubview:self.nextLoadFailureRetryButton];
        [self.nextLoadFailureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_nextLoadFailureBar).offset(10);
            make.left.equalTo(_nextLoadFailureBar).offset(12);
            make.right.equalTo(_nextLoadFailureBar).offset(-12);
        }];
        [self.nextLoadFailureRetryButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.nextLoadFailureLabel.mas_bottom).offset(8);
            make.centerX.equalTo(_nextLoadFailureBar);
            make.bottom.equalTo(_nextLoadFailureBar).offset(-10);
        }];
    }
    return _nextLoadFailureBar;
}

- (YTVPlayerSessionManager *)playerSession {
    if (!_playerSession) {
        _playerSession = [[YTVPlayerSessionManager alloc] init];
    }
    return _playerSession;
}

- (YTVVideoPreloadManager *)preloadManager {
    if (!_preloadManager) {
        _preloadManager = [[YTVVideoPreloadManager alloc] init];
    }
    return _preloadManager;
}

@end
