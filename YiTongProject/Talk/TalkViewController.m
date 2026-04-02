//
//  TalkViewController.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/26.
//

#import "TalkViewController.h"
#import "TalkSegmentListViewController.h"
#import "TalkTopicHomeViewController.h"
#import "YTTalkHomeBannerData.h"
#import "YTTalkHomeBannerImageItem.h"
#import "YTTalkHomeSceneTabItem.h"
#import "HeaderConfig.h"
#import <JXPagingView/JXPagerView.h>
#import <JXPagingView/JXPagerListRefreshView.h>

@interface TalkViewController () <JXPagerViewDelegate, JXPagerMainTableViewGestureDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) JXPagerListRefreshView *pagerView;
@property (nonatomic, copy) NSArray<YTTalkHomeSceneTabItem *> *sceneTabItems;
@property (nonatomic, copy) NSArray<YTTalkHomeBannerImageItem *> *bannerImageItems;
@property (nonatomic, strong) UIView *segmentBar;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *segButtons;
@property (nonatomic, strong) UIView *headerContainerView;
@property (nonatomic, strong) UIScrollView *bannerScrollView;
@property (nonatomic, strong) UIView *bannerIndicatorContainerView;
@property (nonatomic, strong) NSMutableArray<UIView *> *bannerIndicatorViews;
@property (nonatomic, assign) NSInteger currentBannerIndex;
@property (nonatomic, strong) NSTimer *bannerAutoScrollTimer;
@property (nonatomic, assign) BOOL isObservingContentOffset;
@property (nonatomic, assign) NSInteger currentSegmentIndex;
@property (nonatomic, assign) NSInteger lastAppliedSegmentIndex;

@property (nonatomic, strong) UIScrollView *segmentScrollView;
@property (nonatomic, strong) UIView *segmentContentView;
@property (nonatomic, assign) BOOL isPagerSetup;
@property (nonatomic, weak, nullable) UIScrollView *observedListContentScrollView;
@end
 
 @implementation TalkViewController
 
 #pragma mark - 生命周期
 
 - (void)viewWillAppear:(BOOL)animated {
     [super viewWillAppear:animated];
     [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self yt_startBannerAutoScrollIfNeeded];
 }
 
 - (void)viewWillDisappear:(BOOL)animated {
     [super viewWillDisappear:animated];
    [self yt_stopBannerAutoScroll];
     [self.navigationController setNavigationBarHidden:NO animated:animated];
 }
 
 - (void)viewDidLoad {
     [super viewDidLoad];
     self.view.backgroundColor = [UIColor whiteColor];

    self.sceneTabItems = @[];
    self.bannerImageItems = @[];
    self.segButtons = [NSMutableArray array];
    self.currentSegmentIndex = 0;
    self.lastAppliedSegmentIndex = NSNotFound;

    [self yt_fetchTalkHomeBanner];
 }

- (void)dealloc {
    [self yt_stopBannerAutoScroll];
    [self stopObserveListContainerContentOffsetIfNeeded];
}
 
#pragma mark - /talk/banner

- (void)yt_applyHomeBannerData:(YTTalkHomeBannerData *)data {
    if (!data) {
        data = [YTTalkHomeBannerData emptyDefaultAllTabOnly];
    }
    self.sceneTabItems = data.sceneTabs ?: @[];
    self.bannerImageItems = data.bannerImages ?: @[];
}

- (void)yt_fetchTalkHomeBanner {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    [[GlobalHUDManager shared] showSpinnerOnly];
    __weak typeof(self) weakSelf = self;
    [HttpTools postRequest:@"/talk/banner" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        [[GlobalHUDManager shared] hide];
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        YTTalkHomeBannerData *model = nil;
        if (success) {
            model = [YTTalkHomeBannerData dataByParsingAPIDictionary:response.data];
        } else {
            model = [YTTalkHomeBannerData emptyDefaultAllTabOnly];
        }
        [self yt_applyHomeBannerData:model];
        [self yt_setupPagerViewIfNeeded];
    } failure:^(NSError * _Nonnull error) {
        [[GlobalHUDManager shared] hide];
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self yt_applyHomeBannerData:[YTTalkHomeBannerData emptyDefaultAllTabOnly]];
        [self yt_setupPagerViewIfNeeded];
    }];
}

- (void)yt_setupPagerViewIfNeeded {
    if (self.isPagerSetup) return;
    self.isPagerSetup = YES;

    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
    CGFloat screenH = UIScreen.mainScreen.bounds.size.height;

    self.pagerView = [[JXPagerListRefreshView alloc] initWithDelegate:self];
    self.pagerView.frame = CGRectMake(0, statusBarH, SCREEN_WIDTH, screenH - statusBarH - tabBarHeight);
    self.pagerView.mainTableView.gestureDelegate = self;
    if (@available(iOS 11.0, *)) {
        self.pagerView.mainTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.pagerView];

    [self startObserveListContainerContentOffsetIfNeeded];
}

#pragma mark - JXPagerViewDelegate
 
- (UIView *)tableHeaderViewInPagerView:(JXPagerView *)pagerView {
    if (!self.headerContainerView) {
        self.headerContainerView = [self buildHeaderView];
    }
    return self.headerContainerView;
}

- (NSUInteger)tableHeaderViewHeightInPagerView:(JXPagerView *)pagerView {
    NSUInteger titleH = 73;
    NSUInteger bannerBlock = (self.bannerImageItems.count > 0) ? (7 + 220) : 0;
    return titleH + bannerBlock;
}

- (NSUInteger)heightForPinSectionHeaderInPagerView:(JXPagerView *)pagerView {
     return 58;
}

- (UIView *)viewForPinSectionHeaderInPagerView:(JXPagerView *)pagerView {
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat headerH = 58;
    UIView *segment = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenW, headerH)];
    self.segmentBar = segment;

    // 可横向滑动的 tab
    self.segmentScrollView = [[UIScrollView alloc] initWithFrame:segment.bounds];
    self.segmentScrollView.showsHorizontalScrollIndicator = NO;
    self.segmentScrollView.bounces = NO;
    self.segmentScrollView.scrollEnabled = YES;
    [segment addSubview:self.segmentScrollView];

    self.segmentContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenW, headerH)];
    [self.segmentScrollView addSubview:self.segmentContentView];

    NSInteger count = self.sceneTabItems.count;
    if (count == 0) return segment;

    CGFloat btnH = 30;
    CGFloat btnTop = (headerH - btnH) / 2.0;
    CGFloat x = 0;

    [self.segButtons removeAllObjects];
    UIFont *btnFont = [UIFont fontWithName:FONT_NAME_Regular size:16];

    for (NSInteger i = 0; i < count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *title = [self.sceneTabItems[i] displayTitle] ?: @"";
        CGSize textSize = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, btnH)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName: btnFont}
                                              context:nil].size;

        CGFloat textW = ceil(textSize.width);
        // 左右 padding 24（原本 16），扩大按钮之间的留白
        CGFloat btnW = MAX(80, textW + 48);

        btn.frame = CGRectMake(x, btnTop, btnW, btnH);
        x += btnW;

        [btn setTitle:title forState:UIControlStateNormal];
        btn.tag = i;
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(segTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.segmentContentView addSubview:btn];
        [self.segButtons addObject:btn];
    }

    // 内容宽度跟随按钮总宽度变化，超过页面宽度时可滑动
    self.segmentContentView.frame = CGRectMake(0, 0, x, headerH);
    self.segmentScrollView.contentSize = CGSizeMake(x, headerH);

    // 指示器（跟随按钮中心）
    CGFloat indicatorW = 22;
    CGFloat indicatorH = 2;
    CGFloat indicatorTop = headerH - 6;
    self.indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, indicatorTop, indicatorW, indicatorH)];
    self.indicatorView.backgroundColor = [UIColor blackColor];
    [self.segmentContentView addSubview:self.indicatorView];

    self.currentSegmentIndex = 0;
    self.lastAppliedSegmentIndex = NSNotFound;
    [self yt_updateSegmentButtonsForIndex:self.currentSegmentIndex];
    [self updateIndicatorForIndex:self.currentSegmentIndex];

    return segment;
}

- (NSInteger)numberOfListsInPagerView:(JXPagerView *)pagerView {
    return self.sceneTabItems.count;
}

- (id)pagerView:(JXPagerView *)pagerView initListAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.sceneTabItems.count) {
        return nil;
    }
    NSString *type = self.sceneTabItems[index].typeIdentifier;
    TalkSegmentListViewController *vc = [[TalkSegmentListViewController alloc] initWithType:type];
    return vc;
 }
 
 #pragma mark - 交互
 
- (void)onTapBanner:(UIButton *)sender {
    TalkTopicHomeViewController *vc = [[TalkTopicHomeViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (UIView *)buildHeaderView {
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    NSInteger n = self.bannerImageItems.count;
    BOOL hasBanner = (n > 0);
    CGFloat bannerH = hasBanner ? 220.0 : 0.0;
    CGFloat headerTotalH = 73.0 + (hasBanner ? (7.0 + bannerH) : 0.0);
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenW, headerTotalH)];
    header.backgroundColor = [UIColor whiteColor];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = NSLocalizedString(@"Talk_Home_Title", @"");
    titleLabel.textColor = BLACK_COLOR_1F;
    titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:32];
    [header addSubview:titleLabel];

    [header addSubview:self.bannerScrollView];
    [header addSubview:self.bannerIndicatorContainerView];

    CGFloat bannerX = 12.0;
    CGFloat bannerW = screenW - 24.0;
    BOOL shouldEnableBannerPaging = (n > 1);
    self.bannerScrollView.scrollEnabled = shouldEnableBannerPaging;
    self.bannerScrollView.pagingEnabled = shouldEnableBannerPaging;
    self.bannerScrollView.hidden = !hasBanner;
    self.bannerIndicatorContainerView.hidden = !shouldEnableBannerPaging;

    for (NSInteger i = 0; i < n; i++) {
        YTTalkHomeBannerImageItem *item = self.bannerImageItems[i];
        UIView *bannerItemView = [self buildBannerItemViewWithItem:item index:i frame:CGRectMake((bannerW * i), 0, bannerW, bannerH)];
        [self.bannerScrollView addSubview:bannerItemView];

        if (shouldEnableBannerPaging) {
            UIView *indicatorView = [[UIView alloc] init];
            indicatorView.layer.cornerRadius = 2;
            indicatorView.backgroundColor = [theAppDelegate.window colorWithHexString:@"#BFDBFF" alpha:1];
            [self.bannerIndicatorContainerView addSubview:indicatorView];
            [self.bannerIndicatorViews addObject:indicatorView];
        }
    }
    self.bannerScrollView.contentSize = CGSizeMake(bannerW * MAX(n, 1), bannerH);
    self.currentBannerIndex = 0;
    [self yt_updateBannerIndicatorForIndex:0];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(header).offset(18);
        make.right.equalTo(header).offset(-18);
        make.top.equalTo(header);
        make.height.mas_equalTo(73);
    }];

    [self.bannerScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(header).offset(bannerX);
        make.right.equalTo(header).offset(-bannerX);
        make.top.equalTo(titleLabel.mas_bottom).offset(hasBanner ? 7 : 0);
        make.height.mas_equalTo(bannerH);
    }];

    NSUInteger indicatorSlotCount = (NSUInteger)MAX(n, 0);
    CGFloat indicatorTotalW = (n > 1) ? ((CGFloat)((16 * indicatorSlotCount) + (4 * (indicatorSlotCount - 1)))) : 0;
    [self.bannerIndicatorContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bannerScrollView);
        make.bottom.equalTo(self.bannerScrollView.mas_bottom).offset(-10);
        make.height.mas_equalTo(4);
        make.width.mas_equalTo(indicatorTotalW);
    }];

    if (shouldEnableBannerPaging) {
        UIView *lastIndicatorView = nil;
        for (UIView *indicatorView in self.bannerIndicatorViews) {
            [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(16);
                make.height.mas_equalTo(4);
                make.centerY.equalTo(self.bannerIndicatorContainerView);
                if (lastIndicatorView) {
                    make.left.equalTo(lastIndicatorView.mas_right).offset(4);
                } else {
                    make.left.equalTo(self.bannerIndicatorContainerView);
                }
            }];
            lastIndicatorView = indicatorView;
        }
        [lastIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.bannerIndicatorContainerView);
        }];
    }

    return header;
}

- (UIView *)buildBannerItemViewWithItem:(YTTalkHomeBannerImageItem *)item
                                  index:(NSInteger)index
                                  frame:(CGRect)frame {
    UIView *itemView = [[UIView alloc] initWithFrame:frame];
    if (!item) return itemView;

    UIButton *bannerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    bannerButton.frame = itemView.bounds;
    bannerButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bannerButton.backgroundColor = [theAppDelegate.window colorWithHexString:@"#43A5FF" alpha:1];
    bannerButton.layer.cornerRadius = 12;
    bannerButton.layer.masksToBounds = YES;
    bannerButton.tag = index;
    [bannerButton addTarget:self action:@selector(onTapBanner:) forControlEvents:UIControlEventTouchUpInside];
    [itemView addSubview:bannerButton];

    UIImageView *bgImageView = [[UIImageView alloc] init];
    UIImage *placeholder = [UIImage imageNamed:@"talk_topic_bg"];
    NSString *imageUrlStr = item.imageURLString;
    if (imageUrlStr.length > 0) {
        [bgImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr] placeholderImage:placeholder];
    } else {
        bgImageView.image = placeholder;
    }
    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    bgImageView.clipsToBounds = YES;
    [bannerButton addSubview:bgImageView];

    UIView *maskView = [[UIView alloc] init];
    maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08];
    [bannerButton addSubview:maskView];

    UILabel *bannerTitleLabel = [[UILabel alloc] init];
    bannerTitleLabel.text = item.title ?: @"";
    bannerTitleLabel.textColor = [UIColor whiteColor];
    bannerTitleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:30];
    bannerTitleLabel.numberOfLines = 2;
    bannerTitleLabel.hidden = (bannerTitleLabel.text.length == 0);
    [bannerButton addSubview:bannerTitleLabel];

    UILabel *bannerSubtitleLabel = [[UILabel alloc] init];
    bannerSubtitleLabel.text = item.subtitle ?: @"";
    bannerSubtitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.88];
    bannerSubtitleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    bannerSubtitleLabel.hidden = (bannerSubtitleLabel.text.length == 0);
    [bannerButton addSubview:bannerSubtitleLabel];

    UIView *tagContainer = [[UIView alloc] init];
    tagContainer.layer.cornerRadius = 11;
    tagContainer.layer.borderWidth = 1;
    tagContainer.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.45].CGColor;
    tagContainer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    [bannerButton addSubview:tagContainer];

    UILabel *tagLabel = [[UILabel alloc] init];
    tagLabel.text = item.tagText ?: @"";
    tagLabel.textColor = [UIColor whiteColor];
    tagLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:11];
    [tagContainer addSubview:tagLabel];
    tagContainer.hidden = (tagLabel.text.length == 0);

    [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(bannerButton);
    }];
    [maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(bannerButton);
    }];
    [bannerTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bannerButton).offset(16);
        make.right.equalTo(bannerButton).offset(-16);
        make.top.equalTo(bannerButton).offset(16);
    }];
    [bannerSubtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bannerTitleLabel);
        if (bannerTitleLabel.hidden) {
            make.top.equalTo(bannerButton).offset(16);
        } else {
            make.top.equalTo(bannerTitleLabel.mas_bottom).offset(4);
        }
        make.right.lessThanOrEqualTo(bannerButton).offset(-16);
    }];
    [tagContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bannerButton).offset(16);
        make.bottom.equalTo(bannerButton).offset(-12);
        make.height.mas_equalTo(22);
    }];
    [tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tagContainer).offset(10);
        make.right.equalTo(tagContainer).offset(-10);
        make.centerY.equalTo(tagContainer);
    }];
    return itemView;
}

- (void)yt_updateBannerIndicatorForIndex:(NSInteger)index {
    if (self.bannerIndicatorViews.count == 0) return;
    NSString *selectedHex = @"#4C9BEF";
    NSString *normalHex = @"#BFDBFF";
    for (NSInteger i = 0; i < self.bannerIndicatorViews.count; i++) {
        UIView *indicator = self.bannerIndicatorViews[i];
        NSString *hex = (i == index) ? selectedHex : normalHex;
        indicator.backgroundColor = [theAppDelegate.window colorWithHexString:hex alpha:1];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.bannerScrollView) return;
    [self yt_updateBannerCurrentIndexWithScrollView:scrollView];
    [self yt_startBannerAutoScrollIfNeeded];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView != self.bannerScrollView) return;
    [self yt_stopBannerAutoScroll];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView != self.bannerScrollView) return;
    [self yt_updateBannerCurrentIndexWithScrollView:scrollView];
}

- (void)yt_updateBannerCurrentIndexWithScrollView:(UIScrollView *)scrollView {
    CGFloat pageWidth = CGRectGetWidth(scrollView.bounds);
    if (pageWidth <= 0 || self.bannerImageItems.count == 0) return;
    NSInteger index = (NSInteger)llround(scrollView.contentOffset.x / pageWidth);
    index = MAX(0, MIN(index, self.bannerImageItems.count - 1));
    self.currentBannerIndex = index;
    [self yt_updateBannerIndicatorForIndex:index];
}

- (void)yt_startBannerAutoScrollIfNeeded {
    if (self.bannerImageItems.count <= 1) return;
    if (self.bannerAutoScrollTimer) return;
    __weak typeof(self) weakSelf = self;
    self.bannerAutoScrollTimer = [NSTimer timerWithTimeInterval:3.0
                                                        repeats:YES
                                                          block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            [timer invalidate];
            return;
        }
        [self yt_autoScrollBanner];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.bannerAutoScrollTimer forMode:NSRunLoopCommonModes];
}

- (void)yt_stopBannerAutoScroll {
    if (!self.bannerAutoScrollTimer) return;
    [self.bannerAutoScrollTimer invalidate];
    self.bannerAutoScrollTimer = nil;
}

- (void)yt_autoScrollBanner {
    if (self.bannerImageItems.count <= 1) return;
    CGFloat pageWidth = CGRectGetWidth(self.bannerScrollView.bounds);
    if (pageWidth <= 0) return;

    NSInteger nextIndex = self.currentBannerIndex + 1;
    if (nextIndex >= self.bannerImageItems.count) {
        nextIndex = 0;
    }
    CGPoint offset = CGPointMake(nextIndex * pageWidth, 0);
    [self.bannerScrollView setContentOffset:offset animated:YES];
}

- (UIScrollView *)bannerScrollView {
    if (!_bannerScrollView) {
        _bannerScrollView = [[UIScrollView alloc] init];
        _bannerScrollView.pagingEnabled = YES;
        _bannerScrollView.showsHorizontalScrollIndicator = NO;
        _bannerScrollView.delegate = self;
        _bannerScrollView.bounces = YES;
    }
    return _bannerScrollView;
}

- (UIView *)bannerIndicatorContainerView {
    if (!_bannerIndicatorContainerView) {
        _bannerIndicatorContainerView = [[UIView alloc] init];
        _bannerIndicatorContainerView.backgroundColor = [UIColor clearColor];
    }
    return _bannerIndicatorContainerView;
}

- (NSMutableArray<UIView *> *)bannerIndicatorViews {
    if (!_bannerIndicatorViews) {
        _bannerIndicatorViews = [NSMutableArray array];
    }
    return _bannerIndicatorViews;
}
 
- (void)segTap:(UIButton *)btn {
     NSInteger index = btn.tag;
    if (index < 0 || index >= self.segButtons.count) return;
    if (!self.pagerView.listContainerView) return;
    UIScrollView *contentScrollView = [self.pagerView.listContainerView contentScrollView];
    if (!contentScrollView) return;
     CGPoint offset = CGPointMake(index * contentScrollView.bounds.size.width, 0);
     [contentScrollView setContentOffset:offset animated:YES];
    [self.pagerView.listContainerView didClickSelectedItemAtIndex:index];
     [self updateIndicatorForIndex:index];
    self.currentSegmentIndex = index;
    [self yt_updateSegmentButtonsForIndex:index];
 }
 
 - (void)updateIndicatorForIndex:(NSInteger)index {
    if (self.segButtons.count == 0) return;
    if (index < 0 || index >= self.segButtons.count) return;
    UIButton *btn = self.segButtons[index];
    CGFloat indicatorW = self.indicatorView.frame.size.width;
    CGFloat centerX = CGRectGetMidX(btn.frame);
    CGRect frame = self.indicatorView.frame;
    frame.origin.x = centerX - indicatorW / 2.0;
    self.indicatorView.frame = frame;
    [self yt_scrollSegmentToSelectedIndex:index];
 }

- (void)yt_scrollSegmentToSelectedIndex:(NSInteger)index {
    if (!self.segmentScrollView) return;
    if (!self.segmentContentView) return;
    if (index < 0 || index >= self.segButtons.count) return;
    if (self.segmentContentView.bounds.size.width <= CGRectGetWidth(self.segmentScrollView.bounds)) {
        return; // 无需滚动
    }
    UIButton *btn = self.segButtons[index];
    CGFloat desiredX = CGRectGetMidX(btn.frame) - CGRectGetWidth(self.segmentScrollView.bounds) / 2.0;
    CGFloat maxX = MAX(0, self.segmentContentView.bounds.size.width - CGRectGetWidth(self.segmentScrollView.bounds));
    desiredX = MAX(0, MIN(desiredX, maxX));
    [self.segmentScrollView setContentOffset:CGPointMake(desiredX, 0) animated:YES];
}

#pragma mark - underline 跟随分页滑动

- (void)startObserveListContainerContentOffsetIfNeeded {
    if (self.isObservingContentOffset) return;
    if (!self.pagerView.listContainerView) return;
    UIScrollView *contentScrollView = [self.pagerView.listContainerView contentScrollView];
    if (!contentScrollView) return;
    self.observedListContentScrollView = contentScrollView;
    self.isObservingContentOffset = YES;
    [contentScrollView addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(contentOffset))
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
}

- (void)stopObserveListContainerContentOffsetIfNeeded {
    if (!self.isObservingContentOffset) return;
    UIScrollView *contentScrollView = self.observedListContentScrollView;
    @try {
        if (contentScrollView) {
            [contentScrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))];
        }
    } @catch (__unused NSException *e) {
    }
    self.observedListContentScrollView = nil;
    self.isObservingContentOffset = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (![keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if (object != self.observedListContentScrollView) return;
    if (self.sceneTabItems.count == 0) return;
    if (!self.indicatorView) return;
    
    UIScrollView *scrollView = (UIScrollView *)object;
    CGFloat pageW = scrollView.bounds.size.width;
    if (pageW <= 0) return;
    
    CGFloat progress = scrollView.contentOffset.x / pageW; // 连续值 0~(count-1)
    if (self.segButtons.count == 0) return;
    CGFloat maxProgress = (CGFloat)self.segButtons.count - 1.0;
    // 容器左右回弹时 contentOffset 可能 <0 或 >最后一页，先夹紧避免数组越界
    progress = MAX(0.0, MIN(progress, maxProgress));

    NSInteger leftIndex = (NSInteger)floor(progress);
    NSInteger rightIndex = MIN(leftIndex + 1, self.segButtons.count - 1);
    CGFloat t = progress - leftIndex;
    t = MAX(0, MIN(1, t));

    CGFloat indicatorW = self.indicatorView.frame.size.width;
    CGFloat leftCenterX = CGRectGetMidX(self.segButtons[leftIndex].frame);
    CGFloat rightCenterX = CGRectGetMidX(self.segButtons[rightIndex].frame);
    CGFloat indicatorCenterX = leftCenterX + (rightCenterX - leftCenterX) * t;

    CGRect frame = self.indicatorView.frame;
    frame.origin.x = indicatorCenterX - indicatorW / 2.0;
    self.indicatorView.frame = frame;

    // 根据滚动位置应用“当前页”文字颜色
    NSInteger appliedIndex = (NSInteger)llround(progress);
    appliedIndex = MAX(0, MIN(appliedIndex, self.segButtons.count - 1));
    if (appliedIndex != self.lastAppliedSegmentIndex) {
        self.lastAppliedSegmentIndex = appliedIndex;
        [self yt_updateSegmentButtonsForIndex:appliedIndex];
    }
}

- (void)yt_updateSegmentButtonsForIndex:(NSInteger)selectedIndex {
    if (self.segButtons.count == 0) return;
    NSString *normalHex = @"#63637D";
    UIColor *normalColor = [theAppDelegate.window colorWithHexString:normalHex alpha:1];
    UIColor *selectedColor = [UIColor blackColor];

    for (UIButton *btn in self.segButtons) {
        NSInteger idx = btn.tag;
        UIColor *c = (idx == selectedIndex) ? selectedColor : normalColor;
        [btn setTitleColor:c forState:UIControlStateNormal];
    }
}

#pragma mark - JXPagerMainTableViewGestureDelegate

- (BOOL)mainTableViewGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
 
 @end
