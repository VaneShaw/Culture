//
//  VideoTabViewController.m
//  YiTongProject
//

#import "VideoTabViewController.h"
#import "HeaderConfig.h"
#import "YTVShortVideoFeedViewController.h"
#import "YTVVideoCategoryTabsView.h"
#import "YTVVideoCategoryKeys.h"
#import "YTVVideoTabApi.h"
#import "AppDelegate.h"

const NSInteger kYTVVideoTabBarIndex = 1;

@interface VideoTabViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property (nonatomic, strong) YTVVideoCategoryTabsView *tabsView;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, strong) NSMutableArray *feedSlots;
@property (nonatomic, assign) NSInteger currentCategoryIndex;
@end

@implementation VideoTabViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self ytv_applyVideoTabBarAppearanceIfNeeded];
    id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
    if (coordinator != nil) {
        __weak typeof(self) weakSelf = self;
        [coordinator animateAlongsideTransition:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            [self ytv_applyVideoTabBarAppearanceIfNeeded];
        } completion:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            [self ytv_applyVideoTabBarAppearanceIfNeeded];
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBarHidden = YES;
    self.currentCategoryIndex = 0;
    self.feedSlots = [NSMutableArray array];
    [self.view addSubview:self.tabsView];
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    [self.tabsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
    [self.pageViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.tabsView];
    UIViewController *placeholder = [[UIViewController alloc] init];
    placeholder.view.backgroundColor = [UIColor blackColor];
    [self.pageViewController setViewControllers:@[placeholder]
                                       direction:UIPageViewControllerNavigationDirectionForward
                                        animated:NO
                                      completion:nil];
    [self.tabsView ytv_applyTabTitles:nil];
    [self.tabsView ytv_setSelectionUnderlineHidden:YES];
    [self.tabsView ytv_setSearchButtonHidden:YES];
    __weak typeof(self) weakSelf = self;
    self.tabsView.onSearchTap = ^{
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_video_search_coming_soon", @"")];
    };
    self.tabsView.onSelectIndex = ^(NSInteger idx) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || idx < 0 || idx >= (NSInteger)YTVVideoCategoryCount()) {
            return;
        }
        if (idx == self.currentCategoryIndex) {
            return;
        }
        YTVShortVideoFeedViewController *target = [self ytv_feedViewControllerAtIndex:idx];
        UIPageViewControllerNavigationDirection dir = idx > self.currentCategoryIndex ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
        [self.pageViewController setViewControllers:@[target] direction:dir animated:YES completion:^(__unused BOOL finished) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            UIViewController *cur = self.pageViewController.viewControllers.firstObject;
            if ([cur isKindOfClass:[YTVShortVideoFeedViewController class]]) {
                [self ytv_commitActiveFeed:(YTVShortVideoFeedViewController *)cur updateTabSelection:YES];
            }
        }];
    };
    [self ytv_fetchVideoTabConfigurationIfNeeded];
}

/// GET /video/tab：刷新 segment 文案；若分类 key 集合变化则重建各分类 Feed 槽位与 PageVC。
- (void)ytv_fetchVideoTabConfigurationIfNeeded {
    __weak typeof(self) weakSelf = self;
    [YTVVideoTabApi ytv_fetchVideoTabsWithCompletion:^(NSArray<NSString *> *keys, NSArray<NSString *> *titles, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return;
                }
                NSArray<NSString *> *fallbackKeys = @[ @"tz" ];
                NSArray<NSString *> *fallbackTitles = @[ NSLocalizedString(@"YTV_category_recommend", @"") ];
                [self ytv_applyRemoteVideoTabKeys:fallbackKeys titles:fallbackTitles];
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            [self ytv_applyRemoteVideoTabKeys:keys titles:titles];
        });
    }];
}

- (void)ytv_applyRemoteVideoTabKeys:(NSArray<NSString *> *)keys titles:(NSArray<NSString *> *)titles {
    if (keys.count == 0) {
        return;
    }
    BOOL sameKeyLayout = YTVVideoCategoryConfigurationMatchesKeys(keys);
    if (sameKeyLayout) {
        YTVVideoCategorySetFeedTabConfiguration(keys, titles);
        [self.tabsView ytv_applyTabTitles:titles];
        [self.tabsView ytv_setSelectionUnderlineHidden:NO];
        return;
    }
    for (UIViewController *child in [self.pageViewController.childViewControllers copy]) {
        [child willMoveToParentViewController:nil];
        [child.view removeFromSuperview];
        [child removeFromParentViewController];
    }
    self.feedSlots = [NSMutableArray array];
    YTVVideoCategorySetFeedTabConfiguration(keys, titles);
    NSUInteger n = YTVVideoCategoryCount();
    for (NSUInteger i = 0; i < n; i++) {
        [self.feedSlots addObject:[NSNull null]];
    }
    self.currentCategoryIndex = 0;
    [self.tabsView ytv_applyTabTitles:titles];
    [self.tabsView ytv_setSelectedIndex:0 animated:NO];
    [self.tabsView ytv_setSelectionUnderlineHidden:NO];
    YTVShortVideoFeedViewController *first = [self ytv_feedViewControllerAtIndex:0];
    __weak typeof(self) weakSelf = self;
    [self.pageViewController setViewControllers:@[first]
                                       direction:UIPageViewControllerNavigationDirectionForward
                                        animated:NO
                                      completion:^(__unused BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_commitActiveFeed:first updateTabSelection:NO];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    for (id o in self.feedSlots) {
        if (o != [NSNull null]) {
            [(YTVShortVideoFeedViewController *)o ytv_deactivateCategoryFeedReleasingPlayback];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self ytv_applyVideoTabBarAppearanceIfNeeded];
    UIViewController *cur = self.pageViewController.viewControllers.firstObject;
    if (![cur isKindOfClass:[YTVShortVideoFeedViewController class]]) {
        return;
    }
    [self ytv_commitActiveFeed:(YTVShortVideoFeedViewController *)cur updateTabSelection:NO];
}

- (void)ytv_applyVideoTabBarAppearanceIfNeeded {
    id appDelegate = UIApplication.sharedApplication.delegate;
    if ([appDelegate isKindOfClass:[AppDelegate class]] && self.tabBarController != nil) {
        [(AppDelegate *)appDelegate ytb_applyTabBarAppearanceForTabBarController:self.tabBarController];
    }
}

#pragma mark - 分类实例与激活（每分类独立 VC，非当前降载）

- (YTVShortVideoFeedViewController *)ytv_feedViewControllerAtIndex:(NSInteger)idx {
    if (idx < 0 || idx >= (NSInteger)YTVVideoCategoryCount()) {
        return nil;
    }
    id slot = self.feedSlots[(NSUInteger)idx];
    if (slot != [NSNull null]) {
        return slot;
    }
    NSString *key = YTVVideoCategoryKeyAtIndex((NSUInteger)idx);
    YTVShortVideoFeedViewController *vc = [[YTVShortVideoFeedViewController alloc] initWithCategoryKey:key];
    [self.feedSlots replaceObjectAtIndex:(NSUInteger)idx withObject:vc];
    return vc;
}

- (NSInteger)ytv_feedIndexForViewController:(YTVShortVideoFeedViewController *)feed {
    NSUInteger n = YTVVideoCategoryCount();
    for (NSUInteger i = 0; i < n; i++) {
        id o = self.feedSlots[i];
        if (o != [NSNull null] && o == feed) {
            return (NSInteger)i;
        }
    }
    NSString *key = feed.categoryKey;
    for (NSUInteger i = 0; i < n; i++) {
        if ([YTVVideoCategoryKeyAtIndex(i) isEqualToString:key]) {
            return (NSInteger)i;
        }
    }
    return NSNotFound;
}

- (void)ytv_commitActiveFeed:(YTVShortVideoFeedViewController *)active updateTabSelection:(BOOL)updateTabs {
    NSInteger idx = [self ytv_feedIndexForViewController:active];
    if (idx == NSNotFound) {
        return;
    }
    NSUInteger n = YTVVideoCategoryCount();
    for (NSUInteger i = 0; i < n; i++) {
        id o = self.feedSlots[i];
        if (o == [NSNull null]) {
            continue;
        }
        YTVShortVideoFeedViewController *f = o;
        if (f == active) {
            [f ytv_activateCategoryFeed];
        } else {
            [f ytv_deactivateCategoryFeed];
        }
    }
    self.currentCategoryIndex = idx;
    if (updateTabs) {
        [self.tabsView ytv_setSelectedIndex:idx animated:YES];
    }
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if (![viewController isKindOfClass:[YTVShortVideoFeedViewController class]]) {
        return nil;
    }
    NSInteger i = [self ytv_feedIndexForViewController:(YTVShortVideoFeedViewController *)viewController];
    if (i <= 0) {
        return nil;
    }
    return [self ytv_feedViewControllerAtIndex:i - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if (![viewController isKindOfClass:[YTVShortVideoFeedViewController class]]) {
        return nil;
    }
    NSInteger i = [self ytv_feedIndexForViewController:(YTVShortVideoFeedViewController *)viewController];
    if (i == NSNotFound || i >= (NSInteger)YTVVideoCategoryCount() - 1) {
        return nil;
    }
    return [self ytv_feedViewControllerAtIndex:i + 1];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController
         didFinishAnimating:(BOOL)finished
    previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
        transitionCompleted:(BOOL)completed {
    if (!completed) {
        return;
    }
    UIViewController *cur = pageViewController.viewControllers.firstObject;
    if (![cur isKindOfClass:[YTVShortVideoFeedViewController class]]) {
        return;
    }
    [self ytv_commitActiveFeed:(YTVShortVideoFeedViewController *)cur updateTabSelection:YES];
}

- (void)ytv_openDeepLinkWithVideoId:(NSString *)videoId categoryKey:(NSString *)categoryKey {
    if (videoId.length == 0) {
        return;
    }
    if (YTVVideoCategoryCount() == 0) {
        return;
    }
    NSInteger catIdx = 0;
    if (categoryKey.length > 0) {
        NSInteger i = YTVVideoCategoryIndexForKey(categoryKey);
        if (i != NSNotFound) {
            catIdx = i;
        }
    }
    YTVShortVideoFeedViewController *target = [self ytv_feedViewControllerAtIndex:catIdx];
    __weak typeof(self) weakSelf = self;
    void (^afterSwitch)(void) = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_commitActiveFeed:target updateTabSelection:YES];
        [target ytv_handleDeepLinkWithEntryVideoId:videoId];
    };
    UIPageViewControllerNavigationDirection dir = catIdx >= self.currentCategoryIndex ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    [self.pageViewController setViewControllers:@[target]
                                      direction:dir
                                       animated:NO
                                     completion:^(__unused BOOL finished) {
        afterSwitch();
    }];
}

#pragma mark - Lazy

- (YTVVideoCategoryTabsView *)tabsView {
    if (!_tabsView) {
        _tabsView = [[YTVVideoCategoryTabsView alloc] init];
    }
    return _tabsView;
}

- (UIPageViewController *)pageViewController {
    if (!_pageViewController) {
        NSDictionary *opts = @{ UIPageViewControllerOptionInterPageSpacingKey: @0 };
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:opts];
        _pageViewController.dataSource = self;
        _pageViewController.delegate = self;
    }
    return _pageViewController;
}

@end
