//
//  TalkViewController.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/26.
//

#import "TalkViewController.h"
#import "TalkCardView.h"
#import "TalkSegmentListViewController.h"
#import "TalkTopicHomeViewController.h"
#import <JXPagingView/JXPagerView.h>
#import <JXPagingView/JXPagerListRefreshView.h>

@interface TalkViewController () <JXPagerViewDelegate, JXPagerMainTableViewGestureDelegate>
@property (nonatomic, strong) JXPagerListRefreshView *pagerView;
@property (nonatomic, strong) NSArray<NSString *> *segmentTitles;
@property (nonatomic, strong) NSArray<NSString *> *segmentTypes;
@property (nonatomic, strong) UIView *segmentBar;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *segButtons;
@property (nonatomic, assign) BOOL isObservingContentOffset;
@end
 
 @implementation TalkViewController
 
 #pragma mark - 生命周期
 
 - (void)viewWillAppear:(BOOL)animated {
     [super viewWillAppear:animated];
     [self.navigationController setNavigationBarHidden:YES animated:animated];
 }
 
 - (void)viewWillDisappear:(BOOL)animated {
     [super viewWillDisappear:animated];
     [self.navigationController setNavigationBarHidden:NO animated:animated];
 }
 
 - (void)viewDidLoad {
     [super viewDidLoad];
     self.view.backgroundColor = [UIColor whiteColor];
     
    // segment 文案暂时前端写死，后续可从接口动态赋值
    self.segmentTitles = @[@"All Scenes", @"Trending", @"New"];
    self.segmentTypes  = @[@"all", @"hot", @"new"];
     self.segButtons = [NSMutableArray array];
     
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

- (void)dealloc {
    [self stopObserveListContainerContentOffsetIfNeeded];
}
 
#pragma mark - JXPagerViewDelegate
 
- (UIView *)tableHeaderViewInPagerView:(JXPagerView *)pagerView {
     CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
     
     UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenW, 73 + 208)];
     header.backgroundColor = [UIColor whiteColor];
     
     UILabel *lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, screenW - 36, 73)];
     lblTitle.text = @"Explore Scenes";
     lblTitle.textColor = BLACK_COLOR;
     lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:26];
     [header addSubview:lblTitle];
     
     UIScrollView *exploreScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 73, screenW, 208)];
     exploreScrollView.showsHorizontalScrollIndicator = NO;
     [header addSubview:exploreScrollView];
     
     CGFloat cardW = 260;
     CGFloat gap = 16;
     for (int i = 0; i < 10; i++) {
         TalkCardView *card = [[TalkCardView alloc] initWithFrame:CGRectMake((cardW + gap) * i + 16, 0, cardW, 208)];
         card.backgroundColor = [UIColor colorWithRed:216.4f/255.0f green:235.1f/255.0f blue:255.0f/255.0f alpha:1.0f];
         card.layer.cornerRadius = 12;
         card.tag = i;
         card.userInteractionEnabled = YES;
         UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cardTap:)];
         [card addGestureRecognizer:tap];
         [exploreScrollView addSubview:card];
     }
     exploreScrollView.contentSize = CGSizeMake((cardW + gap) * 10 + 16, 208);
     
    return header;
}

- (NSUInteger)tableHeaderViewHeightInPagerView:(JXPagerView *)pagerView {
    return 73 + 208;
}

- (NSUInteger)heightForPinSectionHeaderInPagerView:(JXPagerView *)pagerView {
     return 58;
}

- (UIView *)viewForPinSectionHeaderInPagerView:(JXPagerView *)pagerView {
     CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
     UIView *segment = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenW, 58)];
     self.segmentBar = segment;
     
     NSInteger count = self.segmentTitles.count;
     if (count == 0) {
         return segment;
     }
     CGFloat btnW = screenW / count;
     
     [self.segButtons removeAllObjects];
     for (NSInteger i = 0; i < count; i++) {
         UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
         btn.frame = CGRectMake(btnW * i, 0, btnW, 66);
         [btn setTitle:self.segmentTitles[i] forState:UIControlStateNormal];
         [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
         btn.tag = i;
         [btn addTarget:self action:@selector(segTap:) forControlEvents:UIControlEventTouchUpInside];
         [segment addSubview:btn];
         [self.segButtons addObject:btn];
     }
     
     self.indicatorView = [[UIView alloc] initWithFrame:CGRectMake((btnW - 22)/2, 66, 22, 2)];
     self.indicatorView.backgroundColor = [UIColor blackColor];
     [segment addSubview:self.indicatorView];
     
    return segment;
}

- (NSInteger)numberOfListsInPagerView:(JXPagerView *)pagerView {
    return self.segmentTitles.count;
}

- (id)pagerView:(JXPagerView *)pagerView initListAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.segmentTypes.count) {
        return nil;
    }
    NSString *type = self.segmentTypes[index];
    TalkSegmentListViewController *vc = [[TalkSegmentListViewController alloc] initWithType:type];
    return vc;
 }
 
 #pragma mark - 交互
 
 - (void)cardTap:(UITapGestureRecognizer *)tap {
    TalkTopicHomeViewController *vc = [[TalkTopicHomeViewController alloc] init];
     vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
 }
 
 - (void)segTap:(UIButton *)btn {
     NSInteger index = btn.tag;
    UIScrollView *contentScrollView = [self.pagerView.listContainerView contentScrollView];
     CGPoint offset = CGPointMake(index * contentScrollView.bounds.size.width, 0);
     [contentScrollView setContentOffset:offset animated:YES];
    [self.pagerView.listContainerView didClickSelectedItemAtIndex:index];
     [self updateIndicatorForIndex:index];
 }
 
 - (void)updateIndicatorForIndex:(NSInteger)index {
     if (self.segmentTitles.count == 0) return;
     CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
     CGFloat btnW = screenW / self.segmentTitles.count;
     CGRect frame = self.indicatorView.frame;
     frame.origin.x = index * btnW + (btnW - 22) / 2.0;
     self.indicatorView.frame = frame;
 }

#pragma mark - underline 跟随分页滑动

- (void)startObserveListContainerContentOffsetIfNeeded {
    if (self.isObservingContentOffset) return;
    if (!self.pagerView.listContainerView) return;
    UIScrollView *contentScrollView = [self.pagerView.listContainerView contentScrollView];
    if (!contentScrollView) return;
    self.isObservingContentOffset = YES;
    [contentScrollView addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(contentOffset))
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
}

- (void)stopObserveListContainerContentOffsetIfNeeded {
    if (!self.isObservingContentOffset) return;
    UIScrollView *contentScrollView = [self.pagerView.listContainerView contentScrollView];
    @try {
        [contentScrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))];
    } @catch (__unused NSException *e) {
    }
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
    if (self.segmentTitles.count == 0) return;
    if (!self.indicatorView) return;
    
    UIScrollView *scrollView = (UIScrollView *)object;
    CGFloat pageW = scrollView.bounds.size.width;
    if (pageW <= 0) return;
    
    CGFloat progress = scrollView.contentOffset.x / pageW; // 0~(count-1) 连续值
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat btnW = screenW / self.segmentTitles.count;
    
    CGRect frame = self.indicatorView.frame;
    frame.origin.x = progress * btnW + (btnW - frame.size.width) / 2.0;
    self.indicatorView.frame = frame;
}

#pragma mark - JXPagerMainTableViewGestureDelegate

- (BOOL)mainTableViewGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
 
 @end
