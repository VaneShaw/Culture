//
//  StoryMenuView.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/23.
//

#import "StoryMenuView.h"

#import "PublicTool.h"
#import <Masonry/Masonry.h>
#import "StoryCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AudioRemoteControlManager.h"
#import "StoryPlayerUtil.h"
#define is_Diameter 48  //底部 进度条的高度 底部 定位
static void *kPlayerItemStatusContext = &kPlayerItemStatusContext;

@interface StoryMenuView ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIButton *closeButton;
@property (strong, nonatomic) id timeObserver; // AVPlayer 的时间观察者
@property (strong, nonatomic) NSURL *audioURL;
@property (strong, nonatomic) NSString *strTotalHours;
@property (strong, nonatomic) NSString *strCurrentsHours;

@property (nonatomic, assign) CMTime lastPlaybackTime;
@property (assign, nonatomic) int currentSeconds;
@property (assign, nonatomic) int totalSeconds;

@property (nonatomic, assign) BOOL isUserDraggingSlider;// ，用户开始拖动进度条
@property (nonatomic, assign) BOOL isClickCell;// ，如果是用户点击对应cell的防止突然跳动;
@property (nonatomic, assign) BOOL didClickLanguage; //是否点击了切换语言

@property (nonatomic, strong) dispatch_block_t resetBlock;
@property (strong, nonatomic) NSArray *languageArray;
@property (nonatomic, assign) BOOL hasStartedPlaying; //为了让进度条为0 时 可以滚动到 顶部  当进度条value=0 为No  //暂无用
@property (nonatomic, assign) BOOL isWaitingForPlaySuccess; //点击播放 判断 播放成功 才能 执行 对应方法
@property (nonatomic, assign) NSInteger scrollBlockState;//点击暂停 → 切换语言 → 再点击播放的时候，不允许走这段代码；其他所有情况都要执行。
//点击 切换语言+1 点击播放+1 点击暂停 = 0；
@property (nonatomic, assign) int isFairy;//0 成语 1 神话  2封神榜
@property (nonatomic, strong) dispatch_block_t languageUpdateBlock;
@property (nonatomic, strong) AudioRemoteControlManager *remoteManager;

@property (nonatomic, assign) NSInteger page;        // 当前页
@property (nonatomic, assign) NSInteger pageSize;    // 每页数量（如 5）
@property (nonatomic, assign) NSInteger total_page;       // 后端返回的总页吗
@property (nonatomic, assign) NSInteger total;       // 后端返回的总数量
@property (nonatomic, strong) NSMutableArray *dataArrays;

@property (strong, nonatomic) UIView *footerView;
@end
@implementation StoryMenuView {
    UITapGestureRecognizer *_backgroundTap;
    CGPoint _touchBeginPoint;
    BOOL _isDragging;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.page = 1;
        //self.pageSize = 5;
        self.dataArrays = [NSMutableArray new];
        
        [self setResetAudioPlayer];
        self.languageArray = @[@"中文",@"EN"];
        self.isLanguageCn = [Language_key isEqualToString:@"En"]?0:1;
        [self setupTopButtons];
        [self setupMenuList];
        [self setupAudioControls];
        
        // 添加点击手势
        _backgroundTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        _backgroundTap.cancelsTouchesInView = NO;
        _backgroundTap.delegate = self;
        [self addGestureRecognizer:_backgroundTap];
        //[self setupRemoteControls];
        [self setupMJRefresh];
    }
    return self;
}
- (void)setupMJRefresh {
    //self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewTopics)];
    //允许自动改变透明度
    self.tableView.mj_header.automaticallyChangeAlpha = YES;//header开始刷新
    
    //设置footer，用户滑到最下边就会自动启用footer刷新，故不用写开始刷新的代码
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreTopics)];
    //[self.tableView.mj_header beginRefreshing];
}
//下拉刷新
- (void)loadNewTopics {
    self.page = 1;
    [self getMythStory:self.isFairy];
    [self.tableView.mj_header endRefreshing];
}
- (void)loadMoreTopics {//上
    if (self.dataArrays.count >= self.total) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
        return;
    }
    self.page += 1;
    [self getMythStory:self.isFairy];
}
#pragma mark - 触摸事件（判断是否滑动）
- (void)getMythStory:(int)isFairy{
    self.isFairy = isFairy;
    if(isFairy<2){
        self.tableView.mj_header.hidden = YES;  // 隐藏
        self.tableView.mj_footer.hidden = YES;  // 隐藏
    }
    
    NSString *strUrl = @[@"/story/taleList",@"/story/mythList",@"/classic/chapters"][isFairy];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    params[@"page"] = @(self.page);
    [HttpTools postRequest:strUrl parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        if (success) {
            id rawData = (self.isFairy == 2) ? response.data[@"list"] : response.data;
            NSArray *dataArray = [rawData isKindOfClass:[NSArray class]] ? rawData : @[];
            if(self.isFairy == 2){
                NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
                NSString *page_size = [NSString stringWithFormat:@"%@",dic[@"page_size"]];
                NSString *total_page = [NSString stringWithFormat:@"%@",dic[@"total_page"]];
                NSString *total = [NSString stringWithFormat:@"%@",dic[@"total"]];
                self.total = total.integerValue;
                self.total_page = [total_page integerValue];
                self.pageSize = [page_size integerValue];
                if (self.page == 1) {
                    // 下拉刷新
                    [self.dataArrays removeAllObjects];
                    [self.tableView.mj_footer resetNoMoreData];
                }
                // 追加数据
                [self.dataArrays addObjectsFromArray:dataArray];
                //[self.tableView reloadData];
                // 结束刷新状态
                [self.tableView.mj_header endRefreshing];
                [self.tableView.mj_footer endRefreshing];
                // 判断是否还有更多
                if (self.dataArrays.count >= self.total) {
                    [self.tableView.mj_footer endRefreshingWithNoMoreData];
                }
                dataArray = [NSArray arrayWithArray:self.dataArrays];
            }
            
            if(dataArray.count > 0){
                self.storyListArray = dataArray;
                self.storyIndex = [dataArray indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                    id str = (self.isFairy == 2) ? @"chapter_id" : @"tale_id";
                    return [[NSString stringWithFormat:@"%@", [obj objectForKey:str]] isEqualToString:self.story_id];
                }];
                [self.tableView reloadData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.storyIndex != NSNotFound && self.storyIndex < self.storyListArray.count) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.storyIndex inSection:0];
                        [self.tableView scrollToRowAtIndexPath:indexPath
                                              atScrollPosition:UITableViewScrollPositionMiddle
                                                      animated:NO];
                    }
                });
                [self reloadStories];
            }
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self];
    // 如果点击在 menuContainer 内部，忽略
    if (CGRectContainsPoint(self.menuContainer.frame, location)) {
        return;
    }

    if(!self.menuContainer.hidden){
        self.menuContainer.hidden = YES;
    }
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldReceiveTouch:(UITouch *)touch {
    // 点在菜单按钮上 → 不算背景点击
    if ([touch.view isDescendantOfView:self.btnMenu]) {
        return NO;
    }
    return YES;
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    //如果点击的是 menuContainer 以外的地方，让事件传递给下面的视图
    if (hitView == self) {
        if(self.menuContainer.hidden){
            return nil;
        } else {
            return self;
        }
    }
    return hitView;
}
#pragma mark - 顶部按钮
- (void)setupTopButtons {
    CGFloat width = 42 ;
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    NSArray *images = @[@"", @"menu_black"];
    NSArray *colors = @[
        [self colorWithHex:@"#FFFFFF" alpha:0.8],
        [self colorWithHex:@"#FFFFFF" alpha:0.5]
    ];
    
    UIView *view11 = [[UIView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 4 * width + 20 , statusBarH + 5 - width, width * 4 , width*2 + width/2)];
    view11.backgroundColor = [self colorWithHex:@"#FFFFFF" alpha:0];
    [self addSubview:view11];//测试122
    
    for (int i = 0; i < 2; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 30 - 2 * width + (10 + width) * i, statusBarH + 5, width, width);
        btn.layer.cornerRadius = width / 2;
        btn.layer.masksToBounds = YES;
        btn.backgroundColor = colors[i];
        btn.tag = 300 + i;
        if (i == 0) {
            self.btnLanguage = btn;
            [self.btnLanguage setTitle:self.languageArray[self.isLanguageCn] forState:UIControlStateNormal];
            self.btnLanguage.titleLabel.font = [UIFont boldSystemFontOfSize:14];
            [self.btnLanguage setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.btnLanguage addTarget:self action:@selector(setMainLanguage) forControlEvents:UIControlEventTouchUpInside];
        } else {
            self.btnMenu = btn;
            [btn setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
            [self.btnMenu addTarget:self action:@selector(btnMenuAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:btn];
    }
}
- (void)btnMenuAction:(UIButton *)sender { // 点击菜单显示/隐藏
    //NSLog(@"--------------[toggleMenuAction tapped]--------------------mm---");
    //NSLog(@"------btnMenuAction called, before = [%d]-----",self.menuContainer.hidden);
    //self.menuContainer.hidden = !self.menuContainer.hidden;
   self.menuContainer.hidden = !self.menuContainer.hidden;
   
}
#pragma mark - 菜单栏
- (void)setupMenuList {
    self.menuContainer = [[UIView alloc] init];
    self.menuContainer.backgroundColor = [UIColor whiteColor];
    self.menuContainer.layer.cornerRadius = 12;
    self.menuContainer.hidden = YES;
    //self.menuContainer.userInteractionEnabled = NO;
    [self addSubview:self.menuContainer];
    
    [self.menuContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.btnMenu.mas_bottom).offset(10);
        make.right.equalTo(self).inset(15);
        make.width.equalTo(@217);
        make.height.mas_lessThanOrEqualTo(500); // 最大 500
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.estimatedRowHeight = 60;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.dataSource = (id<UITableViewDataSource>)self;
    self.tableView.delegate = (id<UITableViewDelegate>)self;
    [self.tableView registerClass:[StoryCell class] forCellReuseIdentifier:@"StoryCell"];
    self.tableView.tableFooterView = self.footerView;
    
    [self.menuContainer addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.menuContainer).inset(10);
    }];
}
- (UIView *)footerView {
    if (!_footerView) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 217, 31)];//410
        UIImageView *line = [[UIImageView alloc]initWithFrame:CGRectMake((197-100)/2 , 20, 100, 1)];
        line.image = [UIImage imageNamed:@"line_gray"];
        [_footerView addSubview:line];
    }
    return _footerView;
}
- (void)reloadStories {
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded]; // 强制布局，拿到 contentSize
    CGFloat tableH = self.tableView.contentSize.height + 20; // 上下 inset
    self.tableView.showsVerticalScrollIndicator = self.storyListArray.count > 8 ? YES : NO;
    [self.menuContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(MIN(tableH, 500));
    }];
    [self layoutIfNeeded]; // 立即刷新
}
#pragma mark - UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.storyListArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StoryCell" forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor whiteColor];
    NSDictionary *story = self.storyListArray[indexPath.row];
    BOOL selected = (indexPath.row == self.storyIndex);
    [cell configureWithCN:story[@"main_title"] en:story[@"fallback_title"] selected:selected];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.menuContainer.hidden = !self.menuContainer.hidden;
    self.storyIndex = indexPath.row;
    [self.tableView reloadData];
    if ([self.delegate respondsToSelector:@selector(storyMenuView:didSelectStoryAtIndex:)]) {
        [self.delegate storyMenuView:self didSelectStoryAtIndex:indexPath.row];
    }
    // TODO: 通知 VC 切换故事
}
- (UIButton *)btnLocation {
    if(!_btnLocation){
        _btnLocation = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnLocation.layer.cornerRadius = is_Diameter/2;//圆角
        _btnLocation.layer.masksToBounds = YES;
        _btnLocation.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        [_btnLocation setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        [_btnLocation setTitle:NSLocalizedString(@"Go to playback position",@"") forState:UIControlStateNormal];
        [_btnLocation addTarget:self action:@selector(btnLocationAction:) forControlEvents:UIControlEventTouchUpInside];
        _btnLocation.backgroundColor = [self colorWithHex:@"#FFFFFF" alpha:0.8];
        _btnLocation.titleEdgeInsets = UIEdgeInsetsMake(0,30, 0, 0);
        UIImageView *img = [[UIImageView alloc]initWithFrame:CGRectMake((is_Diameter-17)/2, (is_Diameter-21)/2, 17, 21)];
        img.image = [UIImage imageNamed:@"location_black"];
        [_btnLocation addSubview:img];
        [_btnLocation sizeToFit];
        _btnLocation.hidden = YES;
    }
    return _btnLocation;
}
- (void)setLocationInitialization {
    [self.btnLocation setTitle:NSLocalizedString(@"Go to playback position",@"") forState:UIControlStateNormal];
    [self.btnLocation sizeToFit];
    self.btnLocation.hidden = YES;
    CGFloat btnWidth = _btnLocation.bounds.size.width + is_Diameter;
    [self.btnLocation mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(btnWidth);
    }];
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutIfNeeded];
    }   ];
}
- (void)setLocationState:(BOOL)isShow {
    if(isShow){
        self.btnLocation.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setLocationState:NO];
        });
    } else {
        [self.btnLocation setTitle:@"" forState:UIControlStateNormal];
        [self.btnLocation sizeToFit];
        CGFloat btnWidth = is_Diameter;
        [self.btnLocation mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(btnWidth);
        }];
        [UIView animateWithDuration:0.25 animations:^{
            //[self layoutIfNeeded];
        }];
    }
}
#pragma mark - 音频控制器
- (void)setupAudioControls {
    //self.currentsHours = @"00:00";
    self.audioControlView = [[UIView alloc] init];
    self.audioControlView.backgroundColor = [self colorWithHex:@"#FFFFFF" alpha:0.8];
    self.audioControlView.layer.cornerRadius = 24;
    self.audioControlView.layer.masksToBounds = YES;
    self.audioControlView.hidden = YES;
    self.audioControlView.clipsToBounds = YES;
    [self addSubview:self.audioControlView];
    [self addSubview:self.btnLocation];
    
    [self.audioControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self).inset(12);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-10);
        make.height.equalTo(@is_Diameter);
    }];
    
    CGFloat btnWidth = _btnLocation.bounds.size.width + is_Diameter;
    [self.btnLocation mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-12);
        make.height.mas_equalTo(is_Diameter);
        make.width.mas_equalTo(btnWidth);
        make.bottom.equalTo(self.audioControlView.mas_top).offset(-4);
    }];
    
    // 播放按钮
    self.playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];
    [self.playPauseButton addTarget:self action:@selector(togglePlayPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.audioControlView addSubview:self.playPauseButton];
    [self.playPauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.audioControlView);
        make.left.equalTo(self.audioControlView).offset(10);
        make.width.height.equalTo(@32);
    }];
    
    // 进度条
    self.progressSlider = [[UISlider alloc] init];
    [self.progressSlider addTarget:self action:@selector(handleSlider:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    self.progressSlider.tintColor = [UIColor blackColor];
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"slider_black"] forState:UIControlStateNormal];
    [self.audioControlView addSubview:self.progressSlider];
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.audioControlView);
        make.left.equalTo(self.playPauseButton.mas_right).offset(10);
        make.right.equalTo(self.audioControlView).inset(125);
    }];
    
    // 时长
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.font = [UIFont boldSystemFontOfSize:12];
    self.durationLabel.textAlignment = NSTextAlignmentLeft;
    self.durationLabel.textColor = [UIColor blackColor];
    [self.audioControlView addSubview:self.durationLabel];
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.audioControlView);
        make.right.equalTo(self.audioControlView).inset(38);
        make.width.equalTo(@80);
    }];
    //durationLabel  右边再加一个 button 高50 宽25 厘米有一个图标 居中 宽高各 20 imageclose_black
    // 关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.audioControlView addSubview:closeButton];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.audioControlView);
        make.left.equalTo(self.durationLabel.mas_right).offset(0);
        make.width.equalTo(@30);
        make.height.equalTo(@50);
    }];
    self.closeButton = closeButton;
    int width = 15;
    UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake((20-width)/2, (50-width)/2,width,width)];
    imgView.image = [UIImage imageNamed:@"vector_black"];
    [closeButton addSubview:imgView];
    // 图标居中
    [closeButton.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(closeButton);
        make.width.height.equalTo(@20);
    }];
    // 2️⃣ 圆形按钮（默认显示）
    self.unfoldButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.unfoldButton.layer.cornerRadius = 25;
    self.unfoldButton.layer.masksToBounds = YES;
    [self.unfoldButton setImage:[UIImage imageNamed:@"group_black"] forState:UIControlStateNormal];
    [self.unfoldButton addTarget:self action:@selector(toggleAudioView:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.unfoldButton];
    [self.unfoldButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.audioControlView);
        make.right.equalTo(self).offset(-12);
        make.width.height.equalTo(@50);
    }];
}
#pragma mark - 展开动画
- (void)toggleAudioView:(UIButton *)sender {
    self.unfoldButton.hidden = YES;
    self.audioControlView.hidden = NO;
    
    // 获取 toggleButton 的起始位置
    CGRect startFrame = [self.unfoldButton convertRect:self.unfoldButton.bounds toView:self];
    CGFloat translationX = startFrame.origin.x - self.audioControlView.frame.origin.x;
    // 重置 transform，确保每次都是相同初始状态
    self.audioControlView.transform = CGAffineTransformMakeTranslation(translationX, 0);
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.audioControlView.transform = CGAffineTransformIdentity;
    } completion:nil];
}


#pragma mark - 收回动画（画卷效果）
- (void)closeButtonTapped:(UIButton *)sender {
    self.audioControlView.hidden = NO;
    // 获取右边固定位置
    CGFloat rightX = CGRectGetMaxX(self.audioControlView.frame);
    // 在修改 frame 前强制布局，避免闪烁
    [self.audioControlView.superview layoutIfNeeded];
    [UIView animateWithDuration:0.15
                          delay:0
         usingSpringWithDamping:0.65
          initialSpringVelocity:0.3
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        // 动画开始前保持 frame 原样，动画过程中左边慢慢卷起
        CGRect frame = self.audioControlView.frame;
        frame.origin.x = rightX - 12;  // 右边固定 12
        frame.size.width = 12;         // 左边慢慢收回
        self.audioControlView.frame = frame;
        // 如果用了 AutoLayout，需要调用 layoutIfNeeded
        [self.audioControlView.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.audioControlView.hidden = YES;
        self.unfoldButton.hidden = NO;
        // 重置 frame，保证下一次展开正常
        CGRect originalFrame = self.audioControlView.frame;
        originalFrame.origin.x = rightX - self.audioControlView.bounds.size.width;
        originalFrame.size.width = self.audioControlView.bounds.size.width;
        self.audioControlView.frame = originalFrame;
    }];
}
//--------------------------------------------------------------
- (void)removePlayerItemStatusObserver {
    @try {
        if (self.playerItem) {
            [self.playerItem removeObserver:self forKeyPath:@"status" context:kPlayerItemStatusContext];
        }
    } @catch (NSException *exception) {
        // already removed or never added — 忽略
    }
}
// 在 dealloc 中确保移除 observer
- (void)dealloc {
    [self removePlayerItemStatusObserver];
}
//--------------------------------------------------------------
//===================播放命令 开始 暂停==========================================

//==============================================================
//更新锁屏信息
//锁屏音频3
- (void)updateNowPlayingInfo {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [StoryPlayerUtil updateNowPlayingWithStoryInfo:self.dicStory
                                               isFairy:self.isFairy
                                           languageKey:Language_key
                                                player:self.playerAudio
                                            playerItem:self.playerItem];
    });
}
//========================更新时长===================================
- (NSString *)timeStringFromSeconds:(Float64)seconds {
    if (seconds <= 0 || isnan(seconds) || isinf(seconds)) {
        return @"00:00";
    }
    int totalSeconds = (int)seconds;
    int minutes = totalSeconds / 60;
    int secondsPart = totalSeconds % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, secondsPart];
}

#pragma mark - 播放控制方法
//===================单击播放=========================================
//==================快退15s===========================================
- (void)clickCellToTime:(NSTimeInterval)start {
    NSLog(@"--=--------------start-----[%lf]",start);
    [self delayStartRollingAnimation];
    AVPlayerItem *item = self.playerAudio.currentItem;
    if (!item) return;
    // 如果播放器已经 ready，就直接 seek
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        CMTime seekTime = [PublicTool cmTimeFromSecondsMillisecondPrecision:start];
        [self.playerAudio seekToTime:seekTime
                     toleranceBefore:kCMTimeZero
                      toleranceAfter:kCMTimeZero
                   completionHandler:^(BOOL finished) {
            if (!finished) return;
          
            float seconds = CMTimeGetSeconds(seekTime);
            [self updateProgressUI:seconds];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateNowPlayingInfo];
            });
            BOOL isFirstEnterVC = [KUSER_DEFAULT boolForKey:Story_Scroll_IsVC];
            if (isFirstEnterVC) {
                [KUSER_DEFAULT removeObjectForKey:Story_Scroll_IsVC];
            }  else {
                [self.playerAudio play];
            }
            //}
        }];
    } else {
        // 播放器未 ready → 等待 status ready 再 seek
        //__weak typeof(self) weakSelf = self;
        [item addObserver:self
               forKeyPath:@"status"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
        // 保存要 seek 的时间到属性，KVO 回调里再使用
        //self.pendingSeekTime = start;
        //self.isObservingPlayerStatus = YES;
    }
}


- (void)updateProgressUI:(float)currentSeconds {
    // 1️⃣ 当前播放时间（秒）
    self.currentSeconds = currentSeconds;
    
    AVPlayerItem *item = self.playerAudio.currentItem;
      if (!item) return;
    // 2️⃣ 取总时长
      CMTime duration = item.duration;
      if (!CMTIME_IS_NUMERIC(duration)) return;
      float totalSeconds = CMTimeGetSeconds(duration);
    // 2️⃣ 当前音频总时长（防止除零）
    //float totalSeconds = CMTimeGetSeconds(self.playerAudio.currentItem.duration);
    if (isnan(totalSeconds) || totalSeconds <= 0) return;
    // 3️⃣ 一次性初始化 slider（只在必要时）
       if (self.progressSlider.maximumValue != totalSeconds) {
           self.progressSlider.minimumValue = 0;
           self.progressSlider.maximumValue = totalSeconds;
       }
    
    // 3️⃣ 计算进度比例
    //float progress = currentSeconds / totalSeconds;
    //progress = MAX(0, MIN(progress, 1)); // 限制在 0～1 之间

    // 4️⃣ clamp 秒数
     float value = MIN(MAX(currentSeconds, 0), totalSeconds);
     // 5️⃣ 用“秒数”直接推动 slider（关键）
     [self.progressSlider setValue:value animated:NO];
    
    // 4️⃣ 更新 UI（比如进度条、时间标签）
    //self.progressSlider.value = progress; // 如果你是 UISlider
    // （可选）更新时间显示标签
    self.strCurrentsHours = [self timeStringFromSeconds:currentSeconds];
    self.durationLabel.text = [NSString stringWithFormat:@"%@/%@",self.strCurrentsHours,self.strTotalHours];
 
}
//快进 快退 更新进度
- (void)seekToTime:(Float64)time { //拖动进度条走的方法
    CMTime seekTime = [PublicTool cmTimeFromSecondsMillisecondPrecision:time];
    [self.playerAudio seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];

    //更新进度条
    self.progressSlider.value = time;
    Float64 currentTime = CMTimeGetSeconds(self.playerAudio.currentItem.currentTime);
    self.strCurrentsHours = [self timeStringFromSeconds:currentTime];
    self.durationLabel.text = [NSString stringWithFormat:@"%@/%@",self.strCurrentsHours,self.strTotalHours];
    self.currentSeconds = time;
    
    if(self.progressSlider.value==0){
        self.hasStartedPlaying = NO;
    }
    
    //不拖进度条 不走
    if(!self.isClickCell){
        [self loadChapterView]; //313_AAA
    }
    // 2️⃣ 播放器 seek（异步）
    __weak typeof(self) weakSelf = self;
    [self.playerAudio seekToTime:seekTime
                 toleranceBefore:kCMTimeZero
                  toleranceAfter:kCMTimeZero
               completionHandler:^(BOOL finished) {
        if (!finished) return;
        // 3️⃣ 只在 seek 完成后，更新锁屏信息
        dispatch_async(dispatch_get_main_queue(), ^{
                 [weakSelf updateNowPlayingInfo];
             });
    }];
}
- (void)progressSliderTouchDown:(UISlider *)sender {
    self.isUserDraggingSlider = YES;
}
//进度条停止后 更新播放进度    进度条
- (void)progressSliderTouchEnded:(UISlider *)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isUserDraggingSlider = NO;
        });
    [self.delegate storyMenuViewAutoSync:YES];
    [self seekToTime:sender.value];
    if ([self.delegate respondsToSelector:@selector(storyMenuViewDidSeekToProgress:)]) {
        [self.delegate storyMenuViewDidSeekToProgress:sender.value];
    }
}
#pragma mark - Actions
- (void)handleSlider:(UISlider *)slider {//进度条控制
}
- (void)pauseAndCloseAudioControls { //点击回收 音频控制view
    [self closeButtonTapped:self.closeButton];
}
#pragma mark - 工具方法
- (UIColor *)colorWithHex:(NSString *)hex alpha:(CGFloat)alpha {
    unsigned int rgb = 0;
    [[NSScanner scannerWithString:[hex stringByReplacingOccurrencesOfString:@"#" withString:@""]] scanHexInt:&rgb];
    return [UIColor colorWithRed:((rgb>>16)&0xFF)/255.0
                           green:((rgb>>8)&0xFF)/255.0
                            blue:(rgb&0xFF)/255.0
                           alpha:alpha];
}
//==============================1创建播放器===============================
- (void)setResetAudioPlayer {

    self.lastIndex = - 1;

    if (self.playerAudio) {
        [self.playerAudio pause];
        [self.playerAudio seekToTime:kCMTimeZero
                     toleranceBefore:kCMTimeZero
                      toleranceAfter:kCMTimeZero];
    }
    self.progressSlider.value = 0;
    // 1. 停止播放
    self.lastPlaybackTime = kCMTimeZero;
    // 2. 移除观察者
    if (self.playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
              name:AVPlayerItemDidPlayToEndTimeNotification
              object:self.playerItem];
        @try {
            [self.playerItem removeObserver:self forKeyPath:@"status"];
            [self.playerItem removeObserver:self forKeyPath:@"duration"];
            [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        } @catch (__unused NSException *exception) {}
    }

    // 移除进度监听
    if (self.timeObserver) {
        [self.playerAudio removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    //self.playerItem = nil;
    //self.playerAudio = nil;
    // 3. 替换为空
    //[self.playerAudio replaceCurrentItemWithPlayerItem:nil];
    // 将 playerItem 置 nil
    //self.playerItem = nil;
  
    // 4. 重置 UI 状态
    self.strTotalHours = @"00:00";
    self.strCurrentsHours = @"00:00";
    self.durationLabel.text = [NSString stringWithFormat:@"%@/%@", self.strCurrentsHours, self.strTotalHours];
    self.currentSeconds = 0;
    self.totalSeconds = 0;

    self.hasStartedPlaying = NO;//?
    self.isUserDraggingSlider = NO;
    self.scrollBlockState = 0;
    self.isClickCell = NO;
    self.didClickLanguage = NO;
}
- (void)setupAudioSessionIfNeeded {
    static BOOL audioSessionConfigured = NO;
    if (audioSessionConfigured) return;

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;

    AVAudioSessionCategoryOptions options =
        AVAudioSessionCategoryOptionMixWithOthers |
        AVAudioSessionCategoryOptionAllowAirPlay;

    BOOL success =
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions:options
                   error:&error];

    if (!success || error) {
        NSLog(@"❌ setCategory error: [%@]--------------0", error);
        return;
    }

    success = [session setActive:YES error:&error];
    if (!success || error) {
        NSLog(@"❌ setActive error: [%@]-------------1", error);
        return;
    }

    audioSessionConfigured = YES;
}
- (void)safeSetupAudioSession {
    static BOOL isSettingSession = NO;
    static BOOL hasConfigured = NO;

    if (hasConfigured || isSettingSession) return;

    isSettingSession = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;

        AVAudioSessionCategoryOptions options =
            AVAudioSessionCategoryOptionMixWithOthers |
            AVAudioSessionCategoryOptionAllowAirPlay;

        BOOL success =
        [session setCategory:AVAudioSessionCategoryPlayback
                 withOptions:options
                       error:&error];

        if (!success || error) {
            //NSLog(@"❌ setCategory error: [%@]-------------22", error);
            isSettingSession = NO;
            return;
        }

        success = [session setActive:YES error:&error];
        if (!success || error) {
            //NSLog(@"❌ setActive error: [%@]-------------33", error);
            isSettingSession = NO;
            return;
        }

        hasConfigured = YES;
        isSettingSession = NO;
    });
}
- (void)setMainAudioPlayer {//首次点击播放音频
    [self setResetAudioPlayer];
    [self removePlayerItemStatusObserver];
    
    [self safeSetupAudioSession];
    //[self setupAudioSessionIfNeeded];
    /*NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    //[session setActive:NO error:nil];
    AVAudioSessionCategoryOptions options =
           AVAudioSessionCategoryOptionMixWithOthers |
           AVAudioSessionCategoryOptionAllowAirPlay;
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions:options
                   error:&error];
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"音频会话激活错误: %@", error.localizedDescription);
    }*/

    // 创建播放器项
    NSString *strUrl = [Language_key isEqualToString:@"En"] ? self.audio_en:self.audio_cn;
    AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:strUrl]];
    self.playerAudio = [AVPlayer playerWithPlayerItem:newItem];
    // 添加播放完成观察者
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:newItem]; //    //nil 改 self.playerItem
    // 添加KVO观察者
    [newItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [newItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    self.playerItem = newItem;
    // 添加进度观察者
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.playerAudio addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf updateProgress];
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        NSTimeInterval duration = CMTimeGetSeconds(weakSelf.playerItem.duration);
        if ([weakSelf.delegate respondsToSelector:
             @selector(audioPlayerDidUpdateTime:duration:)]) {
            [weakSelf.delegate audioPlayerDidUpdateTime:currentTime
                                                    duration:duration];
        }
    }];
    
    //[self setupRemoteControls];
    self.remoteManager =
        [[AudioRemoteControlManager alloc] initWithPlayer:self.playerAudio];
    
    //__weak typeof(self) weakSelf = self;
    self.remoteManager.playStateChanged = ^(BOOL isPlaying) {
        UIImage *img = [UIImage imageNamed:isPlaying ? @"pause_black" : @"play_black"];
        [weakSelf.playPauseButton setImage:img forState:UIControlStateNormal];
    };
    [self.remoteManager setupRemoteControls];
}
- (NSInteger)indexForCurrentTime:(CGFloat)currentSeconds {
    BOOL isEnglish = [Language_key isEqualToString:@"En"];
    for (NSInteger i = 0; i < self.textArray.count; i++) {
        StorySectionModel *model = self.textArray[i];
        CGFloat start = isEnglish ? model.startTimeEN : model.startTimeCN;
        CGFloat end   = isEnglish ? model.endTimeEN   : model.endTimeCN;
        // 当前时间在这个区间内
        if (currentSeconds >= start && currentSeconds < end) {
            return i;
        }
    }
   return NSNotFound; // 没找到时返回 NSNotFound
   // 没找到时处理：
}

- (void)updateLanguageButtonByCurrentURL {
    AVURLAsset *asset = (AVURLAsset *)self.playerItem.asset;
    NSString *urlString = asset.URL.absoluteString;
    NSInteger languageIndex = NSNotFound;
    if ([urlString isEqualToString:self.audio_en]) {
        languageIndex = 0; // 英文
    } else if ([urlString isEqualToString:self.audio_cn]) {
        languageIndex = 1; // 中文
    }

    if (languageIndex == NSNotFound) return; // 不是已知音频，不处理
    // 判断按钮是否显示正确
    if (self.isLanguageCn != languageIndex) {
        // 更新按钮
        self.isLanguageCn = languageIndex;
        [self.btnLanguage setTitle:self.languageArray[self.isLanguageCn] forState:UIControlStateNormal];
        [KUSER_DEFAULT setObject:@[@"En",@"Cn"][self.isLanguageCn] forKey:@"Language_key"];
    }
}
//=================================================

//=================================================
//NSKeyValueObservingOptionNew
static inline BOOL YTIsValidDuration(CMTime time, Float64 *outSeconds) {
    if (!CMTIME_IS_VALID(time)) return NO;
    if (CMTIME_IS_INDEFINITE(time)) return NO;
    if (time.timescale == 0) return NO;

    Float64 seconds = CMTimeGetSeconds(time);
    if (!isfinite(seconds) || seconds <= 0) return NO;

    if (outSeconds) *outSeconds = seconds;
    return YES;
}
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if (object != self.playerItem) return;
    if ([keyPath isEqualToString:@"status"]) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
           
            if (self.isWaitingForPlaySuccess) {
                    self.isWaitingForPlaySuccess = NO;
                    //[self btnLocationActionState]; // 在这里执行
                }
            // ======================
            // ✅ 确保只在 ReadyToPlay 后处理
            // ======================
            // 更新总时长
            //Float64 duration = CMTimeGetSeconds(self.playerItem.duration);
            //if (isfinite(duration)) {
            Float64 duration = 0;
            if (YTIsValidDuration(self.playerItem.duration, &duration)) {
                self.strTotalHours = [self timeStringFromSeconds:duration];
                self.durationLabel.text = [NSString stringWithFormat:@"%@/%@", self.strCurrentsHours, self.strTotalHours];
                self.progressSlider.maximumValue = duration;
            }

            // 更新锁屏信息
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateNowPlayingInfo];
            });
            // ======================
            // ✅ 切换语言后安全 seek
            // ======================
            if (CMTIME_IS_VALID(self.lastPlaybackTime) &&
                CMTimeGetSeconds(self.lastPlaybackTime) >= 0.0) {
                __weak typeof(self) weakSelf = self;
                // ⚠️ 关键：先暂停并静音，防止闪音或跳头
                BOOL wasPlaying = (self.playerAudio.rate != 0.0);
                //[self.playerAudio pause]; ///001 改动temp
                self.playerAudio.muted = YES;
                [self.playerAudio seekToTime:self.lastPlaybackTime
                             toleranceBefore:kCMTimeZero
                              toleranceAfter:kCMTimeZero
                           completionHandler:^(BOOL finished) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (!strongSelf) return;
                    
                    // 取消静音
                    strongSelf.playerAudio.muted = NO;
                    if (finished) {//成功
                        if (wasPlaying) {
                            [strongSelf.playerAudio play];
                            [strongSelf.playPauseButton setImage:[UIImage imageNamed:@"pause_black"]
                                                         forState:UIControlStateNormal];
                        } else {
                            [strongSelf.playerAudio pause];
                            [strongSelf.playPauseButton setImage:[UIImage imageNamed:@"play_black"]
                                                         forState:UIControlStateNormal];
                        }
                    } else {
                        //[self updateLanguageButtonByCurrentURL]
                    }
                }];
            }
        } else if (self.playerItem.status == AVPlayerItemStatusFailed) {
            NSLog(@"播放器错误: [%@]--------------------", self.playerItem.error.localizedDescription);//失败
            self.isWaitingForPlaySuccess = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLanguageButtonByCurrentURL];
            });
        }
    } else if ([keyPath isEqualToString:@"duration"]) {
        // 更新总时长（有些音频 ReadyToPlay 前会先触发 duration）
        //Float64 duration = CMTimeGetSeconds(self.playerItem.duration);
        //if (isfinite(duration)) {
           Float64 duration = 0;
           if (!YTIsValidDuration(self.playerItem.duration, &duration)) {
               return;
           }
            self.strTotalHours = [self timeStringFromSeconds:duration];
            self.durationLabel.text = [NSString stringWithFormat:@"%@/%@", self.strCurrentsHours, self.strTotalHours];
            self.progressSlider.maximumValue = duration;
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                [self updateNowPlayingInfo];
            }
        //}
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        if (self.playerItem.playbackLikelyToKeepUp) {
            [self performSafeSeekAfterReady];
            dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateLanguageButtonByCurrentURL];
            });
        }
    }
}
- (void)performSafeSeekAfterReady {
    if (!CMTIME_IS_VALID(self.lastPlaybackTime)) return;

    __weak typeof(self) weakSelf = self;
    BOOL wasPlaying = (self.playerAudio.rate != 0.0);
    [self.playerAudio seekToTime:self.lastPlaybackTime
                 toleranceBefore:kCMTimeZero
                  toleranceAfter:kCMTimeZero
               completionHandler:^(BOOL finished) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (finished && wasPlaying) {
            [strongSelf.playerAudio play];
        }
    }];
}
//===========================================
//===========================================
- (void)setMainLanguage { //点击切换语言。中文 外文
    // 取消之前未执行的 block
     if (self.languageUpdateBlock) {
         dispatch_block_cancel(self.languageUpdateBlock);
         self.languageUpdateBlock = nil;
     }
     // 创建新的延迟 block
     __weak typeof(self) weakSelf = self;
     dispatch_block_t block = dispatch_block_create(0, ^{
         __strong typeof(weakSelf) strongSelf = weakSelf;
         [strongSelf updateLanguageButtonByCurrentURL];
     });
     self.languageUpdateBlock = block;
     // 延迟 3 秒执行           这个3秒不能动 不然高亮会闪一下
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
    if(!self.menuContainer.hidden){
        self.menuContainer.hidden = YES;
    }
    //self.menuContainer.hidden = NO;
    self.btnLanguage.enabled = NO;
    self.btnLanguage.backgroundColor = [self colorWithHex:@"#FFFFFF" alpha:0.7];
      // 2. 延迟 1 秒恢复
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          self.btnLanguage.enabled = YES;
          self.btnLanguage.backgroundColor = [self colorWithHex:@"#FFFFFF" alpha:0.8];
      });

    if (@available(iOS 17, *)) {                   // iOS17 或以上
        //[self switchLanguageAudioStartWithIndex:self.lastIndex];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self switchLanguageAudioStartWithIndex:self.lastIndex];
        });
    //001 改动3
    self.scrollBlockState = 1;
    self.didClickLanguage = YES;
    if ([self.delegate respondsToSelector:@selector(storyMenuViewDidChangeLanguage:)]) {
          [self.delegate storyMenuViewDidChangeLanguage:self.btnLanguage.titleLabel.text];//
    }
    self.isLanguageCn = (self.isLanguageCn == 0 ? 1 : 0);
    [self.btnLanguage setTitle:self.languageArray[self.isLanguageCn] forState:UIControlStateNormal];
    [KUSER_DEFAULT setObject:@[@"En",@"Cn"][self.isLanguageCn] forKey:@"Language_key"];
}
- (void)switchLanguageAudioStartWithIndex:(NSInteger)index {
    [self delayStartRollingAnimation];
    
    // 判断数据范围
    BOOL isOutOfRange = (index < 0 || index >= self.textArray.count);
    BOOL toEnglish = [Language_key isEqualToString:@"En"];
    NSString *urlString = toEnglish ? self.audio_en : self.audio_cn;
    if (!urlString || urlString.length == 0) {
        return;
    }
    
    // -------------------------
    // 计算跳转的目标时间
    // -------------------------
    CGFloat targetStartSeconds = 0;
    if (!isOutOfRange) {
        StorySectionModel *model = self.textArray[index];
        targetStartSeconds = toEnglish ? model.startTimeEN : model.startTimeCN;
    }
    if (targetStartSeconds < 0) targetStartSeconds = 0;
    
    // -------------------------
    // 设置播放器
    // -------------------------
    [self removePlayerItemStatusObserver];
    
    //001 改动
    //[self.playerAudio pause];
    // 清空当前 item（非常关键）
    //001 改动
    NSURL *url = [NSURL URLWithString:urlString];
    AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:url];
    self.playerItem = newItem;
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:kPlayerItemStatusContext];
    // 播放结束通知（⚠️ 一定要绑 newItem） //=================xxxxxx========
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:newItem];
    //=====================================================================
    //001 改动
    // 替换 / 初始化 Player
    //锁屏音频2
    if (!self.playerAudio) {
        self.playerAudio = [AVPlayer playerWithPlayerItem:newItem];
    } else {
        [self.playerAudio replaceCurrentItemWithPlayerItem:newItem];
    }
    //self.playerAudio = [AVPlayer playerWithPlayerItem:newItem];
    //newItem.preferredForwardBufferDuration = 0.1;    //001 改动
    // 存起来，等 KVO 回调 seek
    self.lastPlaybackTime = [PublicTool cmTimeFromSecondsMillisecondPrecision:targetStartSeconds];
}

- (void)btnLocationActionState {
    [self delayStartRollingAnimation];
    [self.delegate storyMenuViewAutoSync:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(!self.btnLocation.hidden){
            self.btnLocation.hidden = YES;
            [self setLocationState:NO];
        }
    });

    NSInteger index = (int)[self indexForCurrentTime:self.currentSeconds];
    BOOL isOutOfRange = (index < 0 || index >= self.textArray.count);
    BOOL toEnglish = [Language_key isEqualToString:@"En"];
    // -------------------------
    // 计算跳转的目标时间
    // -------------------------
    CGFloat targetStartSeconds = 0;
    if (!isOutOfRange) {
        StorySectionModel *model = self.textArray[index];
        targetStartSeconds = toEnglish ? model.startTimeEN : model.startTimeCN;
    }
    if (targetStartSeconds < 0) targetStartSeconds = 0;

    // ✅ 新增逻辑：进度刚从0启动时执行   //001 改动2
     if (targetStartSeconds == 0 && self.progressSlider.value < 1.01 ) {     // &&!self.hasStartedPlaying
         self.isClickCell = NO;
         [self.delegate scrollToCellAudioAtIndexCurrent:-2];
     } else {
         self.hasStartedPlaying = YES;// 只触发一次
         if(!self.isClickCell ){
             if ([self.delegate respondsToSelector:@selector(scrollToCellAudioAtIndexCurrent:)]) {
                 [self.delegate scrollToCellAudioAtIndexCurrent:index];
             }
         } else {
             //点击暂停 切换语言 点击播放的时候 不走这里 其他 情况下 需要走这个方法
             if (self.scrollBlockState != 2) {
                 if ([self.delegate respondsToSelector:@selector(scrollToCellAudioAtIndexCurrent:)]) {
                     [self.delegate scrollToCellAudioAtIndexCurrent:index];
                 }
                 self.scrollBlockState = 0;
             }
         }
     }
}
- (void)btnLocationAction:(UIButton *)sender {//点击定位
    [self btnLocationActionState];
    NSInteger index = (int)[self indexForCurrentTime:self.currentSeconds];
    //NSLog(@"------[%ld]------xxccc------",index);
    if ([self.delegate respondsToSelector:@selector(scrollToCellAudioAtIndexCurrent:)]) {
        [self.delegate scrollToCellAudioAtIndexCurrent:index];
    }
}
// 点击播放/暂停
- (void)togglePlayPause:(UIButton *)sender {//313_AAA_点击播放 点击暂停
    if (self.didClickLanguage) {
            [self delayStartRollingAnimation];
            self.didClickLanguage = NO; // 用完重置，避免下次误触发
    }
    BOOL isPlaying = [sender.currentImage isEqual:[UIImage imageNamed:@"pause_black"]];
    [sender setImage:[UIImage imageNamed:(isPlaying ? @"play_black" : @"pause_black")] forState:UIControlStateNormal];
 
    // TODO: 通知控制器播放/暂停
    if (self.playerAudio.rate == 0.0) {
        self.isWaitingForPlaySuccess = YES;
        [self.playerAudio play];
        if (self.scrollBlockState == 1) {
            self.scrollBlockState = 2;   // 切换语言后立即播放
        } else {
            self.scrollBlockState = 0;   // 正常播放
        }
        //001 改动1  问题1等待处理
        //[self btnLocationActionState]; //点击播放音频   并且回到 追踪状态
        if (self.isFairy < 2){
            [self btnLocationActionState];
        }
        
    } else {
        self.scrollBlockState = 0;
        [self.playerAudio pause]; //点击暂停
    }

    [self updateNowPlayingInfo];
    if ([self.delegate respondsToSelector:@selector(storyMenuViewDidTogglePlay:)]) {
         [self.delegate storyMenuViewDidTogglePlay:self];
     }
}

//==================更新播放进度======================================
#pragma mark - 播放完成处理
//播放结束
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.playerAudio seekToTime:kCMTimeZero];
    self.progressSlider.value = 0;
    [self.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];
    
    [self.delegate scrollToCellAudioAtIndexCurrent:-1];//-1 只刷新 不滚动
    [self.delegate setAudioPlayerEnd:NO];
    self.hasStartedPlaying = NO;//?
    [self setMainAudioPlayer];
}
- (void)updateProgress {//313_AAA_进度条
    // 安全取值
    CMTime currentCMTime = self.playerAudio.currentItem.currentTime;
    CMTime durationCMTime = self.playerItem.duration;
    Float64 currentTime = CMTimeGetSeconds(currentCMTime);
    Float64 duration = CMTimeGetSeconds(durationCMTime);
    if (!isfinite(currentTime) || currentTime < 0) return;

    // 更新进度显示
    self.strCurrentsHours = [self timeStringFromSeconds:currentTime];
    self.currentSeconds = (int)currentTime;
    self.durationLabel.text = [NSString stringWithFormat:@"%@/%@", self.strCurrentsHours, self.strTotalHours ?: @"00:00"];
    
    // 更新 slider
    if (!self.progressSlider.highlighted) {
        self.progressSlider.value = currentTime;
    }
    // 更新锁屏播放信息
    NSDictionary *info = [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo;
    if (info) {
        NSMutableDictionary *nowPlayingInfo = [info mutableCopy];
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(currentTime);
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(self.playerAudio.rate);
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
    }
    // 初始化 duration（仅在未就绪时）
    if (isfinite(duration) && duration > 0 && self.progressSlider.maximumValue == 0) {
        self.strTotalHours = [self timeStringFromSeconds:duration];
        self.progressSlider.maximumValue = duration;
        self.durationLabel.text = [NSString stringWithFormat:@"%@/%@", self.strCurrentsHours, self.strTotalHours];
    }
    //    ✅ 新增逻辑：进度刚从0启动时执行
    
    // 章节滚动更新 /////
    if (self.textArray.count > 0 && !self.isClickCell && duration > 0) {
        NSInteger index = [self indexForCurrentTime:self.currentSeconds];
        if (index != self.lastIndex) {
            //if (!self.isClickCell){
                [self scrollToChapter:index];
                self.lastIndex = index;
            //}
        }
    }
}
- (BOOL)menuViewIsPlaying {
    return self.playerAudio.rate > 0.0;
}
- (void)menuViewPlay {
    [self.playerAudio play];
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause_black"] forState:UIControlStateNormal];
}
- (void)menuViewPause {
    [self.playerAudio pause];
    [self.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];

}
- (void)menuForceStopAudio {
    if (self.playerAudio) {
          [self.playerAudio pause];
          [self.playerAudio replaceCurrentItemWithPlayerItem:nil];
          self.playerAudio = nil;
      }
    [self.playPauseButton setImage:[UIImage imageNamed:@"play_black"]
                          forState:UIControlStateNormal];
}
- (void)menuViewResume {
    if (self.playerAudio.rate == 0.0) {
         [self.playerAudio pause];
     }
}
#pragma mark - 进度条事件处理
//进度快进后时间
- (void)sliderValueChanged:(UISlider *)slider {
    Float64 currentTime = slider.value;  // 滚动到对应章节
    CGFloat progress = slider.value;  //比例 时间
    NSInteger chapterIndex = progress * self.textArray.count;
    if(chapterIndex < self.textArray.count){
        self.currentSeconds = (int)currentTime;
        [self loadChapterView]; //没有快进键不会触发
    }
}
- (void)loadChapterView { //313_AAA
    NSInteger index = (int)[self indexForCurrentTime:self.currentSeconds];
    if (self.isUserDraggingSlider || index != self.lastIndex) {
            [self scrollToChapter:index];
            //self.lastIndex = index;
    }
}
// 安全滚动到章节
- (void)scrollToChapter:(NSInteger)index {
    
    if ([self.delegate respondsToSelector:@selector(scrollToCellAtIndex:)]) {
        if (!self.isClickCell){
            self.lastIndex = index;
            [self.delegate scrollToCellAtIndex:index];
        }
     }
    
}
- (void)delayStartRollingAnimation {
    self.isClickCell = YES;
    // 取消上一次的延迟任务
    if (self.resetBlock) {
        dispatch_block_cancel(self.resetBlock);
        self.resetBlock = nil;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_block_t block = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isClickCell = NO;
        strongSelf.resetBlock = nil;//测试122
    });
    self.resetBlock = block;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), block);
}
- (void)setMenuViewIndex:(NSString *)strId {
    
    self.storyIndex = [self.storyListArray indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        id str = (self.isFairy == 2) ? @"chapter_id" : @"tale_id";
        return [[NSString stringWithFormat:@"%@", [obj objectForKey:str]] isEqualToString:strId];
    }];
    [self.tableView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.storyIndex != NSNotFound && self.storyIndex < self.storyListArray.count) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.storyIndex inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:NO];
        }
    });
    [self reloadStories];
    
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if(!self.tableView.mj_header.hidden){
        if(self.isFairy<2){
            self.tableView.mj_header.hidden = YES;  // 隐藏
            self.tableView.mj_footer.hidden = YES;  // 隐藏
        }
    }
   
}

@end
