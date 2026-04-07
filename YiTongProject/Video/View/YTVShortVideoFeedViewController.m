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
#import "VideoTextWebViewController.h"
#import "YTVVideoPRDShareHelper.h"
#import "HeaderConfig.h"
#import <AVFoundation/AVFoundation.h>
#import <math.h>

static NSString * const kYTVShortVideoCellId = @"YTVShortVideoCell";
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
@property (nonatomic, strong) UIStackView *chromeRightStack;
@property (nonatomic, strong) UIButton *favoriteChromeButton;
@property (nonatomic, strong) UIButton *shareChromeButton;
@property (nonatomic, strong) UIButton *copyDownloadChromeButton;
@property (nonatomic, strong) UIButton *fullScreenChromeButton;
@property (nonatomic, strong) UIStackView *chromeLeftStack;
@property (nonatomic, strong) UILabel *chromeTitleLabel;
@property (nonatomic, strong) UILabel *chromeSummaryLabel;
@property (nonatomic, strong) UIButton *fullTextButton;
@property (nonatomic, copy, nullable) NSString *pendingDeepLinkVideoId;
@property (nonatomic, strong) UIImageView *stateEmptyImageView;
@property (nonatomic, strong) UIView *nextLoadFailureBar;
@property (nonatomic, strong) UILabel *nextLoadFailureLabel;
@property (nonatomic, strong) UIButton *nextLoadFailureRetryButton;
/// 用户点击画面暂停后为 YES，中央显示播放图标；切条或代码里 `play` 后清 NO
@property (nonatomic, assign) BOOL ytv_userPausedWithPlayHint;
/// 跟手滚动时上次已预热的「预计落屏」索引，避免 `scrollViewDidScroll` 重复刷池
@property (nonatomic, assign) NSInteger ytv_lastProvisionalWarmIndex;
/// 当前待完成播放绑定的索引；切换中用于过滤旧回调。
@property (nonatomic, assign) NSInteger ytv_pendingBindIndex;
/// 切源中为 YES，首帧/失败后复位。
@property (nonatomic, assign) BOOL ytv_isSwitchingPlayback;
/// 当前索引已拿到首帧，用于同 URL 复绑时立即揭封面。
@property (nonatomic, assign) BOOL ytv_currentPlaybackFirstFrameReady;
/// 当前绑定对应的播放器 requestId；只响应同一次切源回调。
@property (nonatomic, assign) NSUInteger ytv_pendingPlaybackRequestId;
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
@property (nonatomic, strong, nullable) id ytv_inlineFullscreenTimeObserver;
@property (nonatomic, assign) BOOL ytv_inlineFullscreenScrubbing;
@property (nonatomic, assign) UIEdgeInsets ytv_inlineFullscreenLastAppliedChromeInsets;
/// 为 NO 时不在 layout 回调里改 chrome 边距，避免旋转动画中间帧算错并产生终态跳动
@property (nonatomic, assign) BOOL ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled;
- (void)ytv_updateInlineFullscreenChromeInsetsFromWindowSafeArea;
- (void)ytv_probeNaturalVideoSizeIfNeededForItem:(YTVVideoFeedItem *)item;
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
@end

@implementation YTVShortVideoFeedViewController

- (instancetype)initWithCategoryKey:(NSString *)categoryKey {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _categoryKey = [categoryKey copy] ?: @"";
        _ytv_isFavoritesFeed = NO;
        _currentPlayIndex = NSNotFound;
        _ytv_pendingBindIndex = NSNotFound;
        _ytv_inlineFullscreenLastAppliedChromeInsets = (UIEdgeInsets){ -999, -999, -999, -999 };
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
        _ytv_pendingBindIndex = NSNotFound;
        _ytv_inlineFullscreenLastAppliedChromeInsets = (UIEdgeInsets){ -999, -999, -999, -999 };
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
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
    self.ytv_pendingBindIndex = NSNotFound;
    __weak typeof(self) weakSelf = self;
    self.playerSession.eventHandler = ^(YTVPlayerSessionEventType eventType, NSUInteger requestId, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_handlePlayerSessionEvent:eventType requestId:requestId error:error];
    };
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.chromeRightStack];
    [self.view addSubview:self.chromeLeftStack];
    [self.view addSubview:self.stateOverlay];
    [self.stateOverlay addSubview:self.stateEmptyImageView];
    [self.stateOverlay addSubview:self.stateLabel];
    [self.stateOverlay addSubview:self.retryButton];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    // 安全区左右：系统 UILayoutGuide 无 mas_* 时用 Anchor，与 Masonry 混用即可。
    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    [self.chromeRightStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view).offset(-24);
    }];
    [self.chromeRightStack.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor constant:-10].active = YES;

    [self.chromeLeftStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
    }];
    [self.chromeLeftStack.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor constant:14].active = YES;
    [self.chromeLeftStack.trailingAnchor constraintLessThanOrEqualToAnchor:safeGuide.trailingAnchor constant:-72].active = YES;
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
    [self.view bringSubviewToFront:self.chromeRightStack];
    [self.view bringSubviewToFront:self.chromeLeftStack];
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
    self.ytv_categoryFeedActive = NO;
    self.ytv_userPausedWithPlayHint = NO;
    [self ytv_detachPlayerFromVisibleCells];
    [self.playerSession pause];
    [self ytv_reduceInactiveCategoryResources];
    self.ytv_lastProvisionalWarmIndex = NSNotFound;
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
    self.ytv_categoryFeedActive = NO;
    self.ytv_userPausedWithPlayHint = NO;
    [self ytv_detachPlayerFromVisibleCells];
    [self.playerSession pause];
    [self.playerSession clearPlayback];
    [self.preloadManager invalidateAllWarmItems];
    self.ytv_lastProvisionalWarmIndex = NSNotFound;
    [self ytv_resetPlaybackBindingStateToIdle];
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.ytv_inlineFullscreenActive && self.ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled) {
        [self ytv_updateInlineFullscreenChromeInsetsFromWindowSafeArea];
    }
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
    switch (self.feedViewModel.state) {
        case YTVShortVideoFeedStateLoading: {
            self.stateOverlay.hidden = YES;
            self.collectionView.hidden = YES;
            self.stateEmptyImageView.hidden = YES;
            break;
        }
        case YTVShortVideoFeedStateError: {
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
            [self.collectionView reloadData];
            [self.collectionView layoutIfNeeded];
            NSInteger startIdx = [self.feedViewModel ytv_initialDisplayIndex];
            if (self.feedViewModel.numberOfItems > 0) {
                NSInteger maxIdx = (NSInteger)self.feedViewModel.numberOfItems - 1;
                startIdx = MAX(0, MIN(startIdx, maxIdx));
            } else {
                startIdx = 0;
            }
            self.ytv_userPausedWithPlayHint = NO;
            self.ytv_lastProvisionalWarmIndex = NSNotFound;
            [self ytv_resetPlaybackBindingStateToIdle];
            self.currentPlayIndex = startIdx;
            if (self.feedViewModel.numberOfItems > 0) {
                NSIndexPath *ip = [NSIndexPath indexPathForItem:startIdx inSection:0];
                [self.collectionView scrollToItemAtIndexPath:ip
                                            atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                                    animated:NO];
            }
            if (self.ytv_categoryFeedActive) {
                [self.preloadManager warmAroundDisplayIndex:startIdx items:self.feedViewModel.items];
                [self ytv_applyPlaybackForCurrentIndexIfPossible];
                [self ytv_maybePrefetchNextForDisplayIndex:startIdx];
            }
            break;
        }
        default:
            break;
    }
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
    self.stateOverlay.hidden = YES;
    self.collectionView.hidden = NO;
    self.ytv_userPausedWithPlayHint = NO;
    self.ytv_lastProvisionalWarmIndex = NSNotFound;
    [self ytv_resetPlaybackBindingStateToIdle];
    self.currentPlayIndex = idx;
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    CGFloat pageH = self.collectionView.bounds.size.height;
    if (pageH > 0) {
        [self.collectionView setContentOffset:CGPointMake(0, idx * pageH) animated:NO];
    } else {
        NSIndexPath *ip = [NSIndexPath indexPathForItem:idx inSection:0];
        [self.collectionView scrollToItemAtIndexPath:ip
                                    atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                            animated:NO];
    }
    if (self.ytv_categoryFeedActive) {
        [self ytv_applyPlaybackForCurrentIndexIfPossible];
        [self ytv_maybePrefetchNextForDisplayIndex:idx];
        [self.preloadManager warmAroundDisplayIndex:idx items:self.feedViewModel.items];
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

- (void)ytv_warmAroundProvisionalDisplayIndex:(NSInteger)idx {
    if (!self.ytv_categoryFeedActive) {
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
    if (clamped == self.ytv_lastProvisionalWarmIndex) {
        return;
    }
    self.ytv_lastProvisionalWarmIndex = clamped;
    [self.preloadManager warmAroundDisplayIndex:clamped items:self.feedViewModel.items];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.collectionView) {
        return;
    }
    CGFloat pageH = self.collectionView.bounds.size.height;
    if (pageH < 1) {
        return;
    }
    NSInteger idx = (NSInteger)llround(scrollView.contentOffset.y / pageH);
    [self ytv_warmAroundProvisionalDisplayIndex:idx];
}

/// 流边界：首条下拉不跳末条；**仅**在「已无更多可拉取」时末条上滑回第一条（否则与静默补货冲突：第 10 条会被误判为全列表末尾而跳回首条）。
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView != self.collectionView) {
        return;
    }
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    NSInteger n = (NSInteger)self.feedViewModel.numberOfItems;
    if (n < 2) {
        return;
    }
    CGFloat h = scrollView.bounds.size.height;
    if (h < 1) {
        return;
    }
    NSInteger maxIdx = n - 1;
    NSInteger idxPage = (NSInteger)llround(scrollView.contentOffset.y / h);
    idxPage = MAX(0, MIN(idxPage, maxIdx));
    BOOL allowWrapToHead = !self.feedViewModel.hasMore && !self.feedViewModel.ytv_isLoadingNext;
    if (idxPage >= maxIdx && velocity.y > 0.2 && allowWrapToHead) {
        *targetContentOffset = CGPointMake(0, 0);
    }
    NSInteger targetIdx = (NSInteger)llround(targetContentOffset->y / h);
    targetIdx = MAX(0, MIN(targetIdx, maxIdx));
    [self ytv_warmAroundProvisionalDisplayIndex:targetIdx];
    // 只有当前条已稳定出首帧时，才前移候场到目标页，避免首播阶段被后台候场抢资源。
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.collectionView) {
        return;
    }
    [self ytv_syncVisibleCellsForActivePlaybackIndex:self.currentPlayIndex];
    [self ytv_syncPlayIndexFromContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView != self.collectionView) {
        return;
    }
    [self ytv_syncVisibleCellsForActivePlaybackIndex:self.currentPlayIndex];
    if (!decelerate) {
        [self ytv_syncPlayIndexFromContentOffset];
    }
}

- (void)ytv_syncPlayIndexFromContentOffset {
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    CGFloat pageH = self.collectionView.bounds.size.height;
    if (pageH < 1 || self.feedViewModel.numberOfItems == 0) {
        return;
    }
    NSInteger idx = (NSInteger)llround(self.collectionView.contentOffset.y / pageH);
    NSInteger maxIdx = (NSInteger)self.feedViewModel.numberOfItems - 1;
    idx = MAX(0, MIN(idx, maxIdx));
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
    __weak typeof(self) weakSelf = self;
    NSInteger keepIndex = self.currentPlayIndex;
    [self.feedViewModel loadNextPageIfNeededForDisplayIndex:idx completion:^(BOOL appendedAny, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (error != nil && !appendedAny) {
            NSString *msg = [YTVShortVideoFeedViewModel ytv_userFacingMessageForFeedError:error];
            [self ytv_showNextLoadFailureWithMessage:msg];
        }
        if (!appendedAny) {
            return;
        }
        [self ytv_hideNextLoadFailureBar];
        NSUInteger oldCount = [self.collectionView numberOfItemsInSection:0];
        NSUInteger newCount = self.feedViewModel.numberOfItems;
        if (newCount <= oldCount) {
            return;
        }
        [self.collectionView reloadData];
        [self.collectionView layoutIfNeeded];
        CGFloat h = self.collectionView.bounds.size.height;
        if (h > 0 && keepIndex != NSNotFound && keepIndex < (NSInteger)newCount) {
            [self.collectionView setContentOffset:CGPointMake(0, keepIndex * h) animated:NO];
        }
        [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
    }];
}

/// 预取即将出现的页内容：提前 warm 媒体并把封面压入图片缓存，减少首次展示页的卡顿感。
- (void)ytv_prefetchContentForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (!self.ytv_categoryFeedActive || self.feedViewModel.state != YTVShortVideoFeedStateReady) {
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
        NSInteger idx = MAX(0, MIN((NSInteger)indexPath.item, maxIndex));
        furthestIndex = (furthestIndex == NSNotFound) ? idx : MAX(furthestIndex, idx);
        YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:idx];
        if (item.coverURL.length > 0) {
            NSURL *url = [NSURL URLWithString:item.coverURL];
            if (url && ![url.pathExtension.lowercaseString isEqualToString:@"gif"]) {
                [coverURLs addObject:url];
            }
        }
    }
    if (coverURLs.count > 0) {
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:coverURLs];
    }
    if (furthestIndex != NSNotFound) {
        [self.preloadManager warmAroundDisplayIndex:furthestIndex items:self.feedViewModel.items];
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
    [self ytv_hideNextLoadFailureBar];
    self.ytv_userPausedWithPlayHint = NO;
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
    self.ytv_pendingBindIndex = newIndex;
    self.ytv_currentPlaybackFirstFrameReady = NO;
    [self ytv_applyPlaybackForCurrentIndexIfPossible];
    [self ytv_resyncPlaybackAroundCurrentIndex];
}

/// 当前播放稳定后，继续向下 3 条做保温，减少用户继续下滑时的冷切概率。
- (void)ytv_primeUpcomingWarmItemsForCurrentPlayback {
    if (!self.ytv_categoryFeedActive || self.feedViewModel.state != YTVShortVideoFeedStateReady) {
        return;
    }
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    [self.preloadManager warmAroundDisplayIndex:self.currentPlayIndex items:self.feedViewModel.items];
}

/// 切源 token 与切换标记回到空闲，用于列表重置、失败或当前条不可播。
- (void)ytv_resetPlaybackBindingStateToIdle {
    self.ytv_isSwitchingPlayback = NO;
    self.ytv_pendingPlaybackRequestId = 0;
    self.ytv_pendingBindIndex = NSNotFound;
    self.ytv_currentPlaybackFirstFrameReady = NO;
}

/// 首帧已上屏：结束切换态，并把 `pendingPlaybackRequestId` 与当前会话对齐，避免后续杂散事件误匹配。
- (void)ytv_commitPlaybackBindingAfterFirstFrame {
    self.ytv_isSwitchingPlayback = NO;
    self.ytv_pendingBindIndex = NSNotFound;
    self.ytv_currentPlaybackFirstFrameReady = YES;
    self.ytv_pendingPlaybackRequestId = self.playerSession.currentRequestId;
}

/// 当前条无有效网络播放地址时：暂停、解除保护位并清空绑定状态。
- (void)ytv_resetPlaybackSessionForInvalidCurrentItem {
    [self.preloadManager markPlaybackProtectedVideoId:nil];
    [self.playerSession pause];
    [self ytv_resetPlaybackBindingStateToIdle];
    self.ytv_userPausedWithPlayHint = NO;
    [self ytv_syncPausedPlayHintForCurrentCell];
}

/// 当前 item URL 已经命中时，直接复用现有播放会话并恢复当前 cell 的展示状态。
- (void)ytv_resumePlaybackForCurrentItemAtIndex:(NSInteger)bindIdx cell:(YTVShortVideoCell * _Nullable)cell {
    YTVVideoFeedItem *resumeItem = [self.feedViewModel itemAtIndex:bindIdx];
    if (resumeItem) {
        [self ytv_probeNaturalVideoSizeIfNeededForItem:resumeItem];
    }
    self.ytv_isSwitchingPlayback = NO;
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
    if (targetIdx < 0 || targetIdx >= (NSInteger)self.feedViewModel.numberOfItems) {
        return;
    }
    if (targetIdx == self.currentPlayIndex) {
        return;
    }
    YTVVideoFeedItem *target = [self.feedViewModel itemAtIndex:targetIdx];
    NSURL *url = [NSURL URLWithString:target.playURL];
    NSString *scheme = url.scheme.lowercaseString;
    if (!target || target.videoId.length == 0 || !url || (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"])) {
        return;
    }
    self.ytv_standbyTargetIndex = targetIdx;
    [self.preloadManager setDeepPrewarmTargetVideoId:target.videoId];
    [self.preloadManager warmAroundDisplayIndex:MAX(self.currentPlayIndex, 0) items:self.feedViewModel.items];
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
        if (ready) {
        } else if (error) {
            NSLog(@"[YTVFeed] standby failed idx=%ld videoId=%@ error=%@", (long)targetIdx, target.videoId ?: @"<nil>", error.localizedDescription ?: @"<nil>");
        }
    }];
}

/// 进入真正的切源流程：准备当前 cell、消费预热 item，并在回调里二次校验 pendingBindIndex。
- (void)ytv_replacePlaybackForItem:(YTVVideoFeedItem *)item
                               url:(NSURL *)url
                           bindIdx:(NSInteger)bindIdx
                              cell:(YTVShortVideoCell * _Nullable)cell {
    self.ytv_isSwitchingPlayback = YES;
    self.ytv_currentPlaybackFirstFrameReady = NO;
    AVPlayerItem *prewarmed = [self.preloadManager preparedPlayerItemForVideoId:item.videoId playURL:item.playURL];
    NSUInteger expectedRequestId = self.playerSession.currentRequestId + 1;
    self.ytv_pendingPlaybackRequestId = expectedRequestId;
    __weak typeof(self) weakSelf = self;
    AVPlayerLayer *playerLayer = cell ? cell.renderView.playerLayer : nil;
    __block NSUInteger requestId = 0;
    requestId = [self.playerSession replacePlaybackWithURL:url
                                   preferredPrewarmedPlayerItem:prewarmed
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
    if (requestId != expectedRequestId && requestId != 0) {
        self.ytv_pendingPlaybackRequestId = requestId;
    }
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
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:bindIdx];
    NSURL *url = [NSURL URLWithString:item.playURL];
    if (!url || (![url.scheme.lowercaseString isEqualToString:@"http"] && ![url.scheme.lowercaseString isEqualToString:@"https"])) {
        [self ytv_resetPlaybackSessionForInvalidCurrentItem];
        return;
    }
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
        if (currentURL && [currentURL.absoluteString isEqualToString:url.absoluteString]) {
            [self ytv_resumePlaybackForCurrentItemAtIndex:bindIdx cell:cell];
            return;
        }
    }
    [self ytv_replacePlaybackForItem:item url:url bindIdx:bindIdx cell:cell];
}

/// 点击整页任意区域统一切换暂停/继续播放。
- (void)ytv_handleVideoTapFromCell:(YTVShortVideoCell *)cell {
    if (!self.ytv_categoryFeedActive) {
        return;
    }
    NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
    if (!ip || ip.item != self.currentPlayIndex) {
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
        if (indexPath && indexPath.item == index) {
            return (YTVShortVideoCell *)rawCell;
        }
    }
    return nil;
}

- (YTVShortVideoCell *)ytv_currentCellForPlaybackIndex:(NSInteger)index {
    if (index == NSNotFound || index < 0 || index >= (NSInteger)self.feedViewModel.numberOfItems) {
        return nil;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
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
        BOOL isActive = (indexPath != nil && indexPath.item == activeIndex);
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

/// 首帧真正到达后再揭封面，并结束本次切换态。
- (void)ytv_finishFirstFrameAtIndex:(NSInteger)index {
    YTVShortVideoCell *cell = [self ytv_visibleCellForPlaybackIndexIfAvailable:index];
    [cell ytv_clearPlaybackFailureState];
    [cell ytv_hideCoverAfterFirstFrameAnimated:YES];
    [self ytv_commitPlaybackBindingAfterFirstFrame];
}

/// 播放失败时保留封面，避免露出黑底或旧帧。
- (void)ytv_failPlaybackAtIndex:(NSInteger)index error:(NSError *)error {
    [self ytv_resetPlaybackBindingStateToIdle];
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
            break;
        case YTVPlayerSessionEventTypeFirstFrameRendered:
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
        BOOL isCurrent = rip && rip.item == self.currentPlayIndex;
        [c ytv_setPausedPlayHintVisible:isCurrent && self.ytv_userPausedWithPlayHint];
    }
}

#pragma mark - 浮层互动（技术设计 §7 / 阶段 6）

- (void)ytv_refreshInteractionChrome {
    BOOL show = self.ytv_categoryFeedActive
        && self.feedViewModel.state == YTVShortVideoFeedStateReady
        && self.currentPlayIndex != NSNotFound
        && self.feedViewModel.numberOfItems > 0;
    self.chromeRightStack.hidden = !show;
    self.chromeLeftStack.hidden = !show;
    if (show) {
        YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:self.currentPlayIndex];
        if (item) {
            self.chromeTitleLabel.text = item.title.length ? item.title : @"";
            self.chromeSummaryLabel.text = item.summary.length ? item.summary : @"";
            self.chromeSummaryLabel.hidden = (item.summary.length == 0);
            [self ytv_applyFavoriteChromeTitle:item.isFavorite];
            self.fullTextButton.hidden = (item.fullTextURL.length == 0);
            BOOL canFullScreenChrome = NO;
            if (item.playURL.length > 0) {
                NSURL *pu = [NSURL URLWithString:item.playURL];
                NSString *ps = pu.scheme.lowercaseString;
                BOOL urlOk = pu != nil && ([ps isEqualToString:@"http"] || [ps isEqualToString:@"https"]);
                canFullScreenChrome = urlOk && item.ytv_hasNaturalVideoSize && [item ytv_isLandscapeNaturalVideo];
            }
            self.fullScreenChromeButton.hidden = !canFullScreenChrome;
        } else {
            self.chromeRightStack.hidden = YES;
            self.chromeLeftStack.hidden = YES;
        }
    }
    [self ytv_syncPausedPlayHintForCurrentCell];
}

/// 无接口宽高时异步读 tracks，避免竖滑首帧前无法区分横竖；失败则按竖版默认（全屏条）
- (void)ytv_probeNaturalVideoSizeIfNeededForItem:(YTVVideoFeedItem *)item {
    if (!item || item.ytv_hasNaturalVideoSize || item.playURL.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:item.playURL];
    NSString *sc = url.scheme.lowercaseString;
    if (!url || (![sc isEqualToString:@"http"] && ![sc isEqualToString:@"https"])) {
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
    NSIndexPath *ip = [NSIndexPath indexPathForItem:idx inSection:0];
    UICollectionViewCell *raw = [self.collectionView cellForItemAtIndexPath:ip];
    if ([raw isKindOfClass:[YTVShortVideoCell class]]) {
        YTVVideoFeedItem *it = [self.feedViewModel itemAtIndex:idx];
        [(YTVShortVideoCell *)raw ytv_applyVideoLayoutFromFeedItem:it];
    }
    if (idx == self.currentPlayIndex) {
        [self ytv_refreshInteractionChrome];
    }
}

- (void)ytv_applyFavoriteChromeTitle:(BOOL)favorited {
    NSString *t = NSLocalizedString(favorited ? @"YTV_favorited" : @"YTV_favorite", @"");
    [self.favoriteChromeButton setTitle:t forState:UIControlStateNormal];
}

- (void)ytv_showNextLoadFailureWithMessage:(NSString *)msg {
    if (!self.ytv_categoryFeedActive || self.feedViewModel.state != YTVShortVideoFeedStateReady) {
        return;
    }
    self.nextLoadFailureLabel.text = msg.length ? msg : NSLocalizedString(@"YTV_feed_next_failed_hint", @"");
    self.nextLoadFailureBar.hidden = NO;
    [self.view bringSubviewToFront:self.nextLoadFailureBar];
    [self.view bringSubviewToFront:self.chromeRightStack];
    [self.view bringSubviewToFront:self.chromeLeftStack];
}

- (void)ytv_hideNextLoadFailureBar {
    self.nextLoadFailureBar.hidden = YES;
}

- (void)ytv_onNextLoadFailureRetryTap {
    [self ytv_hideNextLoadFailureBar];
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    [self ytv_maybePrefetchNextForDisplayIndex:self.currentPlayIndex];
}

- (void)ytv_onFavoriteChromeTap {
    if (![LoginManager checkLoginAndPresentIfNeededFrom:self]) {
        return;
    }
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    NSInteger idxBefore = self.currentPlayIndex;
    __weak typeof(self) weakSelf = self;
    [self.feedViewModel toggleFavoriteAtDisplayIndex:self.currentPlayIndex completion:^(BOOL success, NSString *message) {
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
            self.currentPlayIndex = newIdx;
            [self.collectionView reloadData];
            [self.collectionView layoutIfNeeded];
            CGFloat h = self.collectionView.bounds.size.height;
            if (h > 0) {
                [self.collectionView setContentOffset:CGPointMake(0, newIdx * h) animated:NO];
            }
            [self ytv_applyPlaybackForCurrentIndexIfPossible];
            [self ytv_maybePrefetchNextForDisplayIndex:newIdx];
            [self ytv_primeUpcomingWarmItemsForCurrentPlayback];
        }
    }];
    [self ytv_refreshInteractionChrome];
}

- (void)ytv_onFullScreenChromeTap {
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:self.currentPlayIndex];
    if (!item || item.playURL.length == 0) {
        return;
    }
    if (!item.ytv_hasNaturalVideoSize || ![item ytv_isLandscapeNaturalVideo]) {
        return;
    }
    NSURL *u = [NSURL URLWithString:item.playURL];
    NSString *s = u.scheme.lowercaseString;
    if (!u || (![s isEqualToString:@"http"] && ![s isEqualToString:@"https"])) {
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
    self.ytv_inlineFullscreenScrubbing = NO;
    if (host) {
        [host removeFromSuperview];
    }
    self.ytv_inlineFullscreenHostView = nil;
    self.ytv_inlineFullscreenActive = NO;
    self.ytv_inlineFullscreenChromeSafeInsetsUpdatesEnabled = NO;
    self.ytv_inlineFullscreenLastAppliedChromeInsets = (UIEdgeInsets){ -999, -999, -999, -999 };
    self.ytv_inlineFullscreenSourceCell = nil;
    self.ytv_inlineFullscreenRenderView = nil;
    self.collectionView.scrollEnabled = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    [self ytv_refreshInteractionChrome];
    [self ytv_syncPausedPlayHintForCurrentCell];
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
    if (!overlay || !host || !back || !slider) {
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
    self.ytv_inlineFullscreenProgressSlider = slider;
    [overlay addSubview:slider];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(overlay);
    }];
    [slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(overlay);
    }];
    [self ytv_inlineFullscreenUpdateCenterPlayButtonAppearance];
    [self ytv_inlineFullscreenSyncProgressUIFromPlayer];
    [host setNeedsLayout];
    [host layoutIfNeeded];
    self.collectionView.scrollEnabled = NO;
    self.chromeRightStack.hidden = YES;
    self.chromeLeftStack.hidden = YES;
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

- (void)ytv_onShareChromeTap {
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    if (![self.feedViewModel itemAtIndex:self.currentPlayIndex]) {
        return;
    }
    [YTVVideoPRDShareHelper ytv_presentSystemShareFromViewController:self
                                                          sourceView:self.shareChromeButton];
}

- (void)ytv_onCopyDownloadLinkChromeTap {
    [YTVVideoPRDShareHelper ytv_copyDownloadLinkAndShowToast];
}

- (void)ytv_onFullTextTap {
    if (self.currentPlayIndex == NSNotFound) {
        return;
    }
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:self.currentPlayIndex];
    if (item.fullTextURL.length == 0) {
        return;
    }
    NSURL *u = [NSURL URLWithString:item.fullTextURL];
    NSString *scheme = u.scheme.lowercaseString;
    if (!u || (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"])) {
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_full_text_invalid", @"")];
        return;
    }
    VideoTextWebViewController *web = [[VideoTextWebViewController alloc] initWithPageURL:u];
    [self.navigationController pushViewController:web animated:YES];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section != 0) {
        return 0;
    }
    return (NSInteger)self.feedViewModel.numberOfItems;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YTVShortVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kYTVShortVideoCellId forIndexPath:indexPath];
    YTVVideoFeedItem *item = [self.feedViewModel itemAtIndex:indexPath.item];
    [cell configureWithItem:item];
    __weak typeof(self) weakSelf = self;
    cell.ytv_onVideoAreaTap = ^(YTVShortVideoCell *c) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_handleVideoTapFromCell:c];
    };
    BOOL current = (indexPath.item == self.currentPlayIndex);
    if (current) {
        [cell.renderView attachPlayer:self.playerSession.player];
        [self.playerSession bindPlayerLayerForFirstFrameObservation:cell.renderView.playerLayer];
        if (self.ytv_currentPlaybackFirstFrameReady) {
            [cell ytv_hideCoverAfterFirstFrameAnimated:NO];
        } else {
            [cell ytv_showCoverImmediately];
        }
    } else {
        [cell.renderView attachPlayer:nil];
        [cell ytv_showCoverImmediately];
        [cell ytv_clearPlaybackFailureState];
    }
    [cell ytv_setPausedPlayHintVisible:current && self.ytv_userPausedWithPlayHint];
    return cell;
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

- (UIStackView *)chromeRightStack {
    if (!_chromeRightStack) {
        _chromeRightStack = [[UIStackView alloc] initWithArrangedSubviews:@[
            self.favoriteChromeButton,
            self.shareChromeButton,
            self.copyDownloadChromeButton,
            self.fullScreenChromeButton,
        ]];
        _chromeRightStack.axis = UILayoutConstraintAxisVertical;
        _chromeRightStack.spacing = 18;
        _chromeRightStack.alignment = UIStackViewAlignmentCenter;
    }
    return _chromeRightStack;
}

- (UIButton *)favoriteChromeButton {
    if (!_favoriteChromeButton) {
        _favoriteChromeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _favoriteChromeButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _favoriteChromeButton.titleLabel.numberOfLines = 0;
        _favoriteChromeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_favoriteChromeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _favoriteChromeButton.tintColor = [UIColor whiteColor];
        [_favoriteChromeButton addTarget:self action:@selector(ytv_onFavoriteChromeTap) forControlEvents:UIControlEventTouchUpInside];
        [self ytv_applyFavoriteChromeTitle:NO];
    }
    return _favoriteChromeButton;
}

- (UIButton *)shareChromeButton {
    if (!_shareChromeButton) {
        _shareChromeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_shareChromeButton setTitle:NSLocalizedString(@"YTV_share", @"") forState:UIControlStateNormal];
        _shareChromeButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _shareChromeButton.titleLabel.numberOfLines = 0;
        _shareChromeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_shareChromeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _shareChromeButton.tintColor = [UIColor whiteColor];
        [_shareChromeButton addTarget:self action:@selector(ytv_onShareChromeTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareChromeButton;
}

- (UIButton *)copyDownloadChromeButton {
    if (!_copyDownloadChromeButton) {
        _copyDownloadChromeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_copyDownloadChromeButton setTitle:NSLocalizedString(@"YTV_PRD_copy_link_button", @"") forState:UIControlStateNormal];
        _copyDownloadChromeButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _copyDownloadChromeButton.titleLabel.numberOfLines = 0;
        _copyDownloadChromeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_copyDownloadChromeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _copyDownloadChromeButton.tintColor = [UIColor whiteColor];
        [_copyDownloadChromeButton addTarget:self action:@selector(ytv_onCopyDownloadLinkChromeTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _copyDownloadChromeButton;
}

- (UIButton *)fullScreenChromeButton {
    if (!_fullScreenChromeButton) {
        _fullScreenChromeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _fullScreenChromeButton.tintColor = [UIColor whiteColor];
        UIImage *icon = [UIImage imageNamed:@"frame_white"];
        if (icon) {
            [_fullScreenChromeButton setImage:icon forState:UIControlStateNormal];
            _fullScreenChromeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            _fullScreenChromeButton.accessibilityLabel = NSLocalizedString(@"YTV_fullscreen", @"");
        } else {
            [_fullScreenChromeButton setTitle:NSLocalizedString(@"YTV_fullscreen", @"") forState:UIControlStateNormal];
            _fullScreenChromeButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
            _fullScreenChromeButton.titleLabel.numberOfLines = 0;
            _fullScreenChromeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            [_fullScreenChromeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        [_fullScreenChromeButton addTarget:self action:@selector(ytv_onFullScreenChromeTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenChromeButton;
}

- (UILabel *)chromeTitleLabel {
    if (!_chromeTitleLabel) {
        _chromeTitleLabel = [[UILabel alloc] init];
        _chromeTitleLabel.textColor = [UIColor whiteColor];
        _chromeTitleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        _chromeTitleLabel.numberOfLines = 2;
        _chromeTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _chromeTitleLabel;
}

- (UILabel *)chromeSummaryLabel {
    if (!_chromeSummaryLabel) {
        _chromeSummaryLabel = [[UILabel alloc] init];
        _chromeSummaryLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.78];
        _chromeSummaryLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _chromeSummaryLabel.numberOfLines = 3;
        _chromeSummaryLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _chromeSummaryLabel;
}

- (UIButton *)fullTextButton {
    if (!_fullTextButton) {
        _fullTextButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_fullTextButton setTitle:NSLocalizedString(@"YTV_full_text_entry", @"") forState:UIControlStateNormal];
        _fullTextButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        [_fullTextButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.95] forState:UIControlStateNormal];
        _fullTextButton.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.95];
        [_fullTextButton addTarget:self action:@selector(ytv_onFullTextTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullTextButton;
}

- (UIStackView *)chromeLeftStack {
    if (!_chromeLeftStack) {
        _chromeLeftStack = [[UIStackView alloc] initWithArrangedSubviews:@[ self.chromeTitleLabel, self.chromeSummaryLabel, self.fullTextButton ]];
        _chromeLeftStack.axis = UILayoutConstraintAxisVertical;
        _chromeLeftStack.spacing = 8;
        _chromeLeftStack.alignment = UIStackViewAlignmentLeading;
    }
    return _chromeLeftStack;
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
