//
//  TalkViewController.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/26.
//

#import "TalkViewController.h"
#import "ProgressContainerView.h"
#import "EllipseGradientView.h"
#import "TalkCardView.h"
#import "TalkTableViewCell.h"

@interface TalkViewController () <UIScrollViewDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UIScrollView *exploreScrollView;
@property (nonatomic, strong) UIView *segmentBar;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) UIScrollView *pagingScrollView;
@property (nonatomic, strong) NSMutableArray <UITableView *> *tables;
@property (nonatomic, strong) NSMutableArray <UIButton *> *segButtons;
@property (nonatomic, assign) CGFloat tableContentMaxH; // ⭐关键
@property (nonatomic, strong) UIImageView *borderImageView;

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
    self.view.backgroundColor = UIColor.whiteColor;
    self.tables = NSMutableArray.new;
    self.segButtons = NSMutableArray.new;
    [self buildUI];
    
    //ProgressContainerView *progressView = [[ProgressContainerView alloc] initWithFrame:CGRectMake(120, 200, 144, 38)];
    //progressView.leftLabel.text = @"任务进度";
    //progressView.gradientColors = @[[UIColor greenColor], [UIColor blueColor]];
    //progressView.progress = 0.5;
    //[self.view addSubview:progressView];
    //动态更新进度
    //[progressView setProgress:0.75 animated:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐
    // 关键：读取table真实高度
    // ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐
    CGFloat maxH = 0;
    for (UITableView *table in self.tables) {
        [table layoutIfNeeded];
        maxH = MAX(maxH, table.contentSize.height);
    }
    if (maxH == 0) return;
    if (fabs(maxH - self.tableContentMaxH) < 1) return;
    self.tableContentMaxH = maxH;
    [self updateLayoutWithTableHeight:maxH];
}

#pragma mark - UI

- (void)buildUI {
    
    //CGFloat statusBarH = UIApplication.sharedApplication.statusBarFrame.size.height;
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
    CGFloat screenH = UIScreen.mainScreen.bounds.size.height - tabBarHeight ;
    // ================= 主滚动 =================
    
    self.mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, statusBarH, screenW, screenH - statusBarH)];
    self.mainScrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.mainScrollView];
    CGFloat y = 0;
    // ================= header =================
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, y, screenW, 73)];
    header.backgroundColor = UIColor.whiteColor;
    [self.mainScrollView addSubview:header];
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(18, 0, SCREEN_WIDTH, header.frame.size.height)];
    lblTitle.text = @"Explore Scenes";
    lblTitle.textColor = BLACK_COLOR;
    lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:26];
    [header addSubview:lblTitle];
    y += 73;
    // ================= 横卡 =================
    
    self.exploreScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, screenW, 208)];
    self.exploreScrollView.showsHorizontalScrollIndicator = NO;
    [self.mainScrollView addSubview:self.exploreScrollView];
    
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
        [self.exploreScrollView addSubview:card];
    }
    self.exploreScrollView.contentSize = CGSizeMake((cardW + gap) * 10 + 16, 208);
    y += 208;
    // ================= segment =================
    
    self.segmentBar = [[UIView alloc] initWithFrame:CGRectMake(0, y, screenW, 68)];
    [self.mainScrollView addSubview:self.segmentBar];
    y += 68;
    
    NSArray *titles = @[@"All Scenes", @"Trending", @"New"];
    CGFloat btnW = screenW / titles.count;
    
    for (int i = 0; i < titles.count; i++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(btnW * i, 0, btnW, 66);
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        btn.tag = i;
        [btn addTarget:self action:@selector(segTap:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.segmentBar addSubview:btn];
        [self.segButtons addObject:btn];
    }
    
    self.indicatorView = [[UIView alloc] initWithFrame:CGRectMake((btnW - 22)/2, 66, 22, 2)];
    self.indicatorView.backgroundColor = UIColor.blackColor;
    [self.segmentBar addSubview:self.indicatorView];
    // ================= 横向分页 =================
    
    self.pagingScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, screenW, screenH)];
    self.pagingScrollView.pagingEnabled = YES;
    self.pagingScrollView.delegate = self;
    self.pagingScrollView.scrollEnabled = YES;
    self.pagingScrollView.showsHorizontalScrollIndicator = NO;
    [self.mainScrollView addSubview:self.pagingScrollView];
    
    for (int i = 0; i < 3; i++) {
        UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(screenW * i, 0, screenW, 0) style:UITableViewStylePlain];
        table.delegate = self;
        table.dataSource = self;
        table.scrollEnabled = NO; // ⭐仍然禁止
        table.tag = i;
        table.backgroundColor = [UIColor whiteColor];
        table.separatorStyle = UITableViewCellSeparatorStyleNone;
        table.estimatedRowHeight = 0;
        table.estimatedSectionHeaderHeight = 0;
        table.estimatedSectionFooterHeight = 0;
        [self.pagingScrollView addSubview:table];
        [self.tables addObject:table];
    }
    
    self.pagingScrollView.contentSize = CGSizeMake(screenW * 3, 0);
}

#pragma mark - ⭐根据table高度重排（核心）

- (void)updateLayoutWithTableHeight:(CGFloat)tableH {
    
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    
    // 更新 paging 高度
    CGRect pageFrame = self.pagingScrollView.frame;
    pageFrame.size.height = tableH;
    self.pagingScrollView.frame = pageFrame;
    
    self.pagingScrollView.contentSize = CGSizeMake(screenW * 3, tableH);
    
    // 更新每个 table 高度
    for (int i = 0; i < self.tables.count; i++) {
        UITableView *table = self.tables[i];
        table.frame = CGRectMake(screenW * i, 0, screenW, tableH);
    }
    
    // ⭐⭐⭐⭐ 最关键：更新主滚动
    CGFloat bottom = CGRectGetMaxY(self.pagingScrollView.frame);
    self.mainScrollView.contentSize = CGSizeMake(screenW, bottom + 1);
}

#pragma mark - 交互

- (void)cardTap:(UITapGestureRecognizer *)tap {
    NSLog(@"点击卡片 %ld", (long)tap.view.tag);
}

- (void)segTap:(UIButton *)btn {
    CGFloat w = UIScreen.mainScreen.bounds.size.width;
    [self.pagingScrollView setContentOffset:CGPointMake(w * btn.tag, 0) animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView == self.pagingScrollView) {
        CGFloat progress = scrollView.contentOffset.x / scrollView.bounds.size.width;
        CGFloat btnW = self.segmentBar.bounds.size.width / 3.0;
        CGRect f = self.indicatorView.frame;
        f.origin.x = progress * btnW + (btnW - 22)/2;
        self.indicatorView.frame = f;
    }
    
}
#pragma mark - table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 196;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TalkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[TalkTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    //cell.textLabel.text = [NSString stringWithFormat:@"第%ld行 - 页%ld",
      //                     (long)indexPath.row,
        //                   (long)tableView.tag];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}
@end
