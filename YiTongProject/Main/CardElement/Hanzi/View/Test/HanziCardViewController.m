//
//  HanziCardViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/17.
//


#import "HanziCardViewController.h"
#import "BottomSwitchBar.h"
#import "TitleSubtitleView.h"

#import "CardFlowLayout.h"
#import "CardCell.h"
@interface HanziCardViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<CardModel *> *cards;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) CGFloat mainWidth;
@property (nonatomic, assign) CGFloat totalHeight;
@end

@implementation HanziCardViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self addGlobalBackButtonColor:[UIColor whiteColor] headerTitleDic:@{}];
    self.view.backgroundColor = [self.view colorWithHexString:@"#F5F9FF" alpha:1];
    NSError *sessionError = nil;
    // 设置音频会话类别为播放
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];

    NSString *title = @"Single Stroke";
    NSString *subtitle = @"Simple structure, easy to write & recognize";
    CGFloat viewHeight = [TitleSubtitleView heightForWidth:SCREEN_WIDTH title:title subtitle:subtitle];
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    TitleSubtitleView *tsView = [[TitleSubtitleView alloc] initWithFrame:CGRectMake(0, 45 + statusBarH + 28, SCREEN_WIDTH, viewHeight)];
    [tsView setTitle:title subtitle:subtitle];
    [self.view addSubview:tsView];
    
    self.totalHeight = 438;
    CGFloat smallWidth = 27 + 12 ;  // 左右露出的宽度  27为待展示图的宽
    CGFloat spacing = 12;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    self.mainWidth = screenWidth - 2*smallWidth - 2*spacing;
    int y = statusBarH + 25 + 45 + viewHeight + 30;
    
    [self setupCards];
    [self setupCollectionView];
    self.collectionView.frame = CGRectMake(0, y, SCREEN_WIDTH, self.totalHeight);
    
    NSArray *titleArray = @[@"Listen", @"Speak", @"Write",@"Video"];
    BottomSwitchBar *bar = [[BottomSwitchBar alloc] init];
    [self.view addSubview:bar];
    //self.barSwitch = bar;
    [bar configureWithY:self.collectionView.frame.origin.y + self.collectionView.frame.size.height + 30
                  titles:titleArray
                  action:^(NSInteger index) {
        NSLog(@"点击了第 %ld 个按钮", (long)index);
        //NSLog(@"点击了第 %ld 个按钮", (long)index);
    }];
    
//    BottomSwitchBar *bar = [[BottomSwitchBar alloc] initWithY:(self.collectionView.frame.origin.y + self.collectionView.frame.size.height + 30) titles:@[@"Listen", @"Speak", @"Write",@"Video"] action:^(NSInteger index) {
//        //NSLog(@"点击了第 %ld 个按钮", (long)index);
//    }];
  
}
- (void)setupCards {
    NSMutableArray *array = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        CardModel *card = [CardModel new];
        card.image = [UIImage imageNamed:@"story_detail_2"]; // 替换成实际图片
        [array addObject:card];
    }
    self.cards = array;
    self.currentIndex = 0;
}

#pragma mark - UICollectionView DataSource
- (void)setupCollectionView {
    CardFlowLayout *layout = [[CardFlowLayout alloc] init];
    layout.itemSize = CGSizeMake([UIScreen mainScreen].bounds.size.width - 2*27 - 2*12, 438);
    layout.sideVisibleWidth = 27 + 12 ;  // 左右露出的宽度  27为待展示图的宽
    layout.spacing = 12;           // 主图和侧图间距
    layout.mainHeight = 438;
    layout.sideShrink = 70;        // 侧图比主图矮70
    // 主图尺寸

    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, statusBarH + 25 + 45 + 50 + 30, SCREEN_WIDTH, self.totalHeight) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;

    [self.collectionView registerClass:[CardCell class] forCellWithReuseIdentifier:@"CardCell"];
    [self.view addSubview:self.collectionView];

    //dispatch_async(dispatch_get_main_queue(), ^{
    //NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    //if (itemCount > 0) {
    NSIndexPath *firstIndex = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView scrollToItemAtIndexPath:firstIndex
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
    //});
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cards.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CardCell" forIndexPath:indexPath];
    [cell configureWithCard:self.cards[indexPath.item]
                    atIndex:indexPath.item
                currentIndex:self.currentIndex
                   mainWidth:self.mainWidth
                 totalHeight:self.totalHeight];
    
    cell.backgroundColor = [UIColor orangeColor];
    // 点击切换
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCell:)];
    [cell addGestureRecognizer:tap];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat spacing = 12;
    self.currentIndex = round(scrollView.contentOffset.x / (self.mainWidth + spacing));
    [self.collectionView reloadData];
    [self reportCurrentIndex];
}

- (void)didTapCell:(UITapGestureRecognizer *)tap {
    CardCell *cell = (CardCell *)tap.view;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (!indexPath) return;
    
    NSInteger index = indexPath.item;
    if (index != self.currentIndex) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:YES];
        self.currentIndex = index;
        [self.collectionView reloadData];
    }
}

#pragma mark - 当前显示哪张卡片

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self reportCurrentIndex];
    }
}
- (void)reportCurrentIndex {
    CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.bounds.size.width * 0.5;
    NSArray *attrs = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:self.collectionView.bounds];
    NSInteger currentIndex = 0;
    CGFloat minDelta = MAXFLOAT;
    for (UICollectionViewLayoutAttributes *attr in attrs) {
        CGFloat delta = ABS(attr.center.x - centerX);
        if (delta < minDelta) {
            minDelta = delta;
            currentIndex = attr.indexPath.item;
        }
    }
    NSLog(@"当前在第 %ld 张卡片", (long)currentIndex);
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
