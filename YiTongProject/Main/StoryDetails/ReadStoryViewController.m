//
//  ReadStoryViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/29.
//

#import "ReadStoryViewController.h"
#import "StoryMenuView.h"
#import "StoryAudioPlayer.h"

#import "StorySectionModel.h"
#import "StoryTextCell.h"
#import "StoryImageCell.h"
#import "VideoPlayerView.h"

#import "AnimatedImageView.h"
#import "ReadHeaderView.h"
#import "ReadFooterView.h"
#import "VideoFullScreenViewController.h"
#import "AudioBarsView.h"
#import "StoryLockCoverView.h"

@interface ReadStoryViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate,StoryMenuViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) StoryMenuView *menuView;
@property (nonatomic, strong) StoryAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSArray<StorySectionModel *> *dataArray;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath; // 当前选中的段落
//yes : 音频读到哪里。对应的cell高亮就跟随，并且居中
@property (nonatomic, assign) BOOL isAudioScrolling;     // 是否跟随音频滚动（默认YES）
//@property (nonatomic, assign) BOOL isPlayAudio_current;   //是否选中播放 后 才能执行
//yes 播放中 no 没有在播放
@property (strong, nonatomic) UIColor *bg_ui_color;
@property (strong, nonatomic) NSString *bg_color1;
@property (strong, nonatomic) UIColor *title_Color;
@property (strong, nonatomic) UIColor *select_Color;
@property (strong, nonatomic) UIColor *bg_bright_color;
@property (nonatomic, strong) AudioBarsView *animatedImage;

@property (strong, nonatomic) NSString *videoUrl;
@property (strong, nonatomic) ReadHeaderView *headerView;
@property (nonatomic, strong) VideoPlayerView *playerViewVideo;
@property (strong, nonatomic) ReadFooterView *footerView;
@property (strong, nonatomic) StoryLockCoverView *cover;
@property (strong, nonatomic) UIView *storyView;
@property (assign, nonatomic) BOOL isTemp;
@property (assign, nonatomic) BOOL isCove;

@property (nonatomic, assign) BOOL hasCompletedStudy;
@end
@implementation ReadStoryViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    
    // iOS18 / iPhone17 退出全屏必触发
    if(self.isCove){
        self.isCove = NO;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self forceFullLayoutRefresh];
        });
    }
    if ([UserStateManager shared].needRefreshVipUI) {
        [self onMembershipUpdated];
        [UserStateManager shared].needRefreshVipUI = NO;
    }
}
- (void)forceFullLayoutRefresh {
    if (@available(iOS 26, *)) {
        if(self.isTemp){
            self.tableView.hidden = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.tableView.hidden = NO;
                //[self.tableView reloadData];
            });
        }
    }
}
- (void)viewDidAppear:(BOOL)animated {//视图---出现v
    [super viewDidAppear:animated];
    //[self forceFullLayoutRefresh];
    [self startStudy];
}

- (void)viewWillDisappear:(BOOL)animated { //视图即将消失v
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
 
    if(self.isCove){
        //[self.menuView menuViewPause];
    } else {
        //[self.menuView menuForceStopAudio];
    }
    
    // ① 真正离开（pop / dismiss）
     if (self.isMovingFromParentViewController ||
         self.isBeingDismissed) {
         [self.menuView menuForceStopAudio];
     }
     else {
         // ② 只是被 present 覆盖（比如进入登录页）
         [self.menuView  menuViewPause];
     }
    
    UIViewController *toVC = self.navigationController.topViewController;
    if ([toVC isKindOfClass:[VideoFullScreenViewController class]]) {
        //NSLog(@"👉 即将进入全屏页面");
        //[self forceFullLayoutRefresh];
    } else if (self.isMovingFromParentViewController) {
        [self.playerViewVideo turnOffVideoPlayback];
        [[MediaPlayManager sharedManager] turnOffVideoPlayback1];
    }
    if (self.studyStartTimeMs > 0) {
        [self endStudyWithCompleted:self.hasCompletedStudy
                          eventType:EventTypeStory
                           eventName:@"故事阅读"
                         contentType:@[@"idiom",@"myth"][self.isFairy]
                           extraParams:nil];
    }
    
    self.hasCompletedStudy = NO;
    /*if (self.studyStartTimeMs > 0) {
        NSDictionary *extra = @{
               @"total": @(10),
               @"correct": @(8),
               @"score": @(80)
        };
        [self endStudyWithCompleted:NO extraParams:extra]; nil
    }*/
}
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if ([viewController isKindOfClass:[ReadStoryViewController class]]) {
        //NSLog(@"用户正在侧滑返回上一页");
    }
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @[@"story_idiom",@"story_myth",@""][self.isFairy]; //1神话 0 成语

    self.isCove = NO;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *storyView = [[UIView alloc] initWithFrame:self.view.bounds];
    storyView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:storyView];
    self.storyView = storyView;
    
    self.animatedImage = [[AudioBarsView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 42, 12, 15, 15)];
    self.currentIndex = -1;
    [self setupTableView];
    [self createCoverView];
    [self.view addSubview:self.menuView];
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"#FFFFFF" alpha:0.5] headerTitleDic:@{}];
    
    self.bg_color1 = [KUSER_DEFAULT objectForKey:[NSString stringWithFormat:@"bg_color_%@_%d",self.storyId,self.isFairy]];
    if(self.bg_color1 == nil){
        self.bg_color1 = @"#FFFFFF";
    }
    self.tableView.backgroundColor = [self.view colorWithHexString:self.bg_color1 alpha:1];
}
- (void)onMembershipUpdated{
    if(self.storyId.intValue > 0){
        [self loadStoryData:self.storyId];
        [self.menuView.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];
    }
}
#pragma mark - TableView Setup
- (void)setupTableView {
      self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT + 20 * IPHONE_X) style:UITableViewStyleGrouped];
      self.tableView.delegate = self;
      self.tableView.dataSource = self;
      self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
      //self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    // 🚫 禁止 iOS 自动调整安全区偏移
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    // 🚫 关闭 iOS15 的默认 section 顶部空隙
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }

    [self.tableView registerClass:[StoryTextCell class] forCellReuseIdentifier:@"StoryTextCell"];
    [self.tableView registerClass:[StoryImageCell class] forCellReuseIdentifier:@"StoryImageCell"];
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.footerView;
    
    [self.storyView addSubview:self.tableView];
    [self loadStoryData:self.storyId];
}
- (ReadHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[ReadHeaderView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 200)];//410
        _headerView.uvc = self;
    }
    return _headerView;
}
- (ReadFooterView *)footerView {
    if (!_footerView) {
        _footerView = [[ReadFooterView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0)];//410
    }
    return _footerView;
}
//=======================================================
- (void)playAudioAtIndexPath:(NSIndexPath *)indexPath1 isStart:(BOOL)isStart {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (self.currentIndex < 0 || self.currentIndex >= self.dataArray.count) return;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    StoryTextCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (!cell || !cell.selectedBgView) return;
    // 移除按钮旧位置
        
    // 放到当前cell上
    self.animatedImage.frame = CGRectMake(SCREEN_WIDTH - 42, 12, 15, 15);
    [cell.selectedBgView addSubview:self.animatedImage];
    BOOL isPlaying = (self.menuView.playerAudio.rate != 0);
    if (isStart) {
            // 如果标记要开始录音，直接启动录音
        [self startRecording];
    } else {
        if (isPlaying) {
            // 播放中 -> 启动动画
            [self startRecording];
        } else {
            // 播放暂停 -> 取消录音
            [self cancelRecording];
        }
    }

    // 保存当前播放索引
    self.selectedIndexPath = indexPath;
    });
}
- (void)startRecording {
    [self.animatedImage startAnimating];
}
- (void)cancelRecording {
    [self.animatedImage stopAnimatingWithHeights:@[@"11",@"15",@"10"]];
}
//- (void)updateAudioSimulation {
//    // 限制在 0.3 ~ 0.8 之间
//    //CGFloat randomValue = (arc4random_uniform(40) + 30) / 100.0;
//    //[self.animatedImage setAudioLevel:randomValue];
//}
//=======================================================
/*- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.selectedIndexPath) {
        NSArray *visible = [self.tableView indexPathsForVisibleRows];
        if (![visible containsObject:self.selectedIndexPath]) {
            //[self.animatedImage removeFromSuperview];
        }
    }
}*/
- (void)stopPlaying {
    [self cancelRecording];
    //[self.animatedImage removeFromSuperview];
}
- (void)setupHeaderVideoIfNeeded {//视频播放相关
    BOOL hasVideo = (self.videoUrl.length > 6);
    self.menuView.audioControlView.hidden = hasVideo;
    self.menuView.unfoldButton.hidden = 1 - hasVideo;
    self.playerViewVideo.hidden = 1 - hasVideo;
    [self.playerViewVideo stopVideo];

    if(hasVideo){
         self.playerViewVideo = [self.headerView setupVideoIfVideoUrl:self.videoUrl];
         // 监听关闭音频的通知
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPauseAudio) name:@"StopAudioPlayerNotification" object:nil];
     }
    if (!self.videoUrl || self.videoUrl.length == 0) {
        //return;
    }
    
}
- (void)playPauseAudio {//点击播放视频
    if (self.menuView.playerAudio.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.menuView pauseAndCloseAudioControls];
        });
        [self.menuView.playerAudio pause];
        [self.menuView.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self cancelRecording];
        });
    }
    
}
//==========================================
#pragma mark - Load Data
- (CGFloat)secondsFromFrameTimeString:(NSString *)timeString frameRate:(CGFloat)fps {
    NSArray<NSString *> *components = [timeString componentsSeparatedByString:@":"];
    if (components.count != 3) return 0;
    NSInteger minutes = [components[0] integerValue];
    NSInteger seconds = [components[1] integerValue];
    NSInteger frames = [components[2] integerValue];
    return minutes * 60 + seconds + (frames / fps);
}
- (void)loadStoryData:(NSString *)storyId { 
    //self.isPlayAudio_current = NO;
    //self.isAudioScrolling = YES;
    self.currentIndex = -1;
    [self.tableView layoutIfNeeded];
    [self.playerViewVideo stopVideo];
    //[self.menuView setResetAudioPlayer];
  
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"tale_id"] = storyId;
    params = [LanguageHelper currentLanguageParams:params];
    self.storyId = storyId;
    NSMutableArray *arr = [NSMutableArray array];//@"/story/getIdiomStoryDetail"
    NSString *strUrl = @[@"/story/taleDetail",@"/story/mythDetail"][self.isFairy];
    [HttpTools postRequest:strUrl parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        if (success) {
            self.isTemp = YES;
            //NSLog(@"------ccdd-------[%@]----------ccdd----------",response.data);
            //NSDictionary *dicData = [NSDictionary dictionaryWithDictionary:response.data];
            NSDictionary *dicData = ([response.data isKindOfClass:[NSDictionary class]]) ? response.data : @{};
            NSDictionary *dicStory = [NSDictionary dictionaryWithDictionary:dicData];
            self.storyId = storyId;
            
            //[NSString stringWithFormat:@"%@",dicStory[@"tale_id"]];
            //audio_main_start      audio_fallback_start
            //audio_main_end        audio_fallback_end
            //NSString *audio_main_end = [NSString stringWithFormat:@"%@",dicStory[@"audio_main_end"]];
            //NSString *audio_fallback_end = [NSString stringWithFormat:@"%@",dicStory[@"audio_fallback_end"]];
            //self.menuView.main_end = [self secondsFromFrameTimeString:audio_main_end frameRate:30] + 0.25;
            //self.menuView.fallback_end = [self secondsFromFrameTimeString:audio_fallback_end frameRate:30]  + 0.25;
            
            self.bg_color1 = [NSString stringWithFormat:@"%@",dicStory[@"bg_color"]];
            self.bg_ui_color = [self.view colorWithHexString:self.bg_color1 alpha:1];
            [KUSER_DEFAULT setObject:self.bg_color1 forKey:[NSString stringWithFormat:@"bg_color_%@_%d",self.storyId,self.isFairy]];
            
            NSString *audioUrl_cn = [NSString stringWithFormat:@"%@",dicStory[@"audio_main"]];
            NSString *audioUrl_en = [NSString stringWithFormat:@"%@",dicStory[@"audio_fallback"]];
            
            NSString *headImage = [NSString stringWithFormat:@"%@",dicStory[@"head_image"]];
            self.title_Color = [self.view colorWithHexString:[NSString stringWithFormat:@"%@",dicStory[@"font_color"]] alpha:1];
            self.select_Color = [self.view colorWithHexString:[NSString stringWithFormat:@"%@",dicStory[@"bright_color"]] alpha:1];
            self.bg_bright_color = [self.view colorWithHexString:[NSString stringWithFormat:@"%@",dicStory[@"bright_bg_color"]] alpha:0.1];
          
            NSString *is_lock = [NSString stringWithFormat:@"%@",dicStory[@"is_lock"]];
            if(!IS_Member){
                is_lock = @"0";
            }
            self.menuView.audioControlView.alpha = 1 - is_lock.boolValue;
            self.menuView.unfoldButton.alpha = 1 - is_lock.boolValue;
            self.cover.hidden = !is_lock.boolValue;
#ifdef DEBUG
            //self.cover.hidden = NO;//测试用
#endif
            //NSDictionary *dicData = [NSDictionary dictionaryWithDictionary:response.data];
            //NSString *key = @[@"lines",@"sections"][self.isFairy];
            NSString *key = self.isFairy ? @"sections" : @"lines";
            NSArray *dataArray = ([dicData[key] isKindOfClass:[NSArray class]]) ? dicData[key] : @[];
                //======
                if(self.isFairy){
                    for (NSDictionary *sectionDict in dataArray) {
                        if (![sectionDict isKindOfClass:[NSDictionary class]]) continue;
                        NSArray *lines = sectionDict[@"lines"];
                        if (![lines isKindOfClass:[NSArray class]]) continue;
                        // 1️⃣ 标题
                        [arr addObject:[self modelFromDict:sectionDict type:StorySectionTypeText isTitle:YES]];
                        // 2️⃣ 每行文本
                        NSDictionary *dicTemp;
                        for (NSDictionary *lineDict in lines) {
                            [arr addObject:[self modelFromDict:lineDict type:StorySectionTypeText isTitle:NO]];
                            dicTemp = lineDict;
                        }
                        // 3️⃣ 底部图片
                        StorySectionModel *imageModel = [[StorySectionModel alloc] init];
                        imageModel.model_id = [NSString stringWithFormat:@"%@", sectionDict[@"section_id"]];
                        imageModel.type = StorySectionTypeImage;
                        imageModel.imageLoaded = NO;
                        imageModel.imageUrl = [NSString stringWithFormat:@"%@", sectionDict[@"bottom_image"]];
                        [arr addObject:imageModel];
                    }
                    self.videoUrl = [NSString stringWithFormat:@"%@",dicStory[@"video_url"]];
                    [self setupHeaderVideoIfNeeded];     //底部播放栏 是否弹出 或隐藏
                    [self.headerView loadTopImageWithURL:headImage hasVideo:self.videoUrl.length > 6];
                    
                } else {
                    
                    for (NSDictionary *dict in dataArray) {
                         [arr addObject:[self modelFromDict:dict type:StorySectionTypeText isTitle:NO]];
                    }
                    NSString *bottom_image = [NSString stringWithFormat:@"%@",dicStory[@"bottom_image"]];
                    [self.footerView loadImageWithURLString:bottom_image];
                    NSString *video_url = [NSString stringWithFormat:@"%@",dicStory[@"video_url"]];
                    self.footerView.gifImageView.hidden = YES;
                    if(video_url.length > 6){
                        [self.footerView loadGIFWithURLString:video_url];
                    }
                    //[self.headerView loadTopImageWithURL:headImage hasVideo:NO];
                    self.videoUrl = [NSString stringWithFormat:@"%@",dicStory[@"head_video"]]; //@"https://testoss.shiyi-yitong.com/story/myth/videos/pangu.mp4";
                    [self setupHeaderVideoIfNeeded];                           //底部播放栏 是否弹出 或隐藏
                    [self.headerView loadTopImageWithURL:headImage hasVideo:self.videoUrl.length > 6];
                }

                self.currentIndex = -1;
                self.dataArray = arr;
                self.menuView.textArray = self.dataArray;
                self.menuView.dicStory = dicStory;
                self.menuView.audio_cn = audioUrl_cn;
                self.menuView.audio_en = audioUrl_en;
                [self.menuView setMainAudioPlayer];
                [self.menuView setLocationInitialization];
            
                [self.animatedImage changeBarColor:self.select_Color];
                self.headerView.backgroundColor = self.bg_ui_color;
                self.tableView.backgroundColor = self.bg_ui_color;
                self.view.backgroundColor = self.bg_ui_color;
            
            //self.dataArray = arr;
            [self.tableView reloadData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView performBatchUpdates:^{
                } completion:^(BOOL finished) {
                    [self.tableView layoutIfNeeded];
                    CGFloat topOffset = -self.tableView.adjustedContentInset.top;
                    [self.tableView setContentOffset:CGPointMake(0, topOffset) animated:NO];
                    // ✅ 延迟 0.6 秒再次检测
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        //self.menuView.progressSlider.value = 0.0;
                        CGFloat currentOffsetY = self.tableView.contentOffset.y;
                        CGFloat expectedOffsetY = -self.tableView.adjustedContentInset.top;
                        // 判断是否已经在顶部（容忍一点浮动误差）
                        if (fabs(currentOffsetY - expectedOffsetY) > 1.0) {
                            [self.tableView setContentOffset:CGPointMake(0, expectedOffsetY) animated:NO];
                        }
                    });
                }];
            });
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (StorySectionModel *)modelFromDict:(NSDictionary *)dict
                                type:(StorySectionType)type
                            isTitle:(BOOL)isTitle {
    StorySectionModel *m = [[StorySectionModel alloc] init];
    m.type = type;
    if (isTitle) {
        m.model_id = [NSString stringWithFormat:@"%@", dict[@"section_id"]];
        m.textCN = [NSString stringWithFormat:@"%@", dict[@"main_title"]];
        m.textEN = [NSString stringWithFormat:@"%@", dict[@"fallback_title"]];
        m.isTitle = isTitle;
    } else {
        m.model_id = [NSString stringWithFormat:@"%@", dict[@"sort"]];
        m.textCN = [NSString stringWithFormat:@"%@", dict[@"main_content"]];
        m.textEN = [NSString stringWithFormat:@"%@", dict[@"fallback_content"]];
    }
    [m setStartTimeCNWithString:dict iskeyTime:NO];
    [m setStartTimeENWithString:dict iskeyTime:NO];
    return m;
}
#pragma mark - TableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= self.dataArray.count) {
        return [[UITableViewCell alloc] init];
    }
    StorySectionModel *model = self.dataArray[indexPath.row];
    if (model.type == StorySectionTypeText) {
        StoryTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StoryTextCell" forIndexPath:indexPath];
        [cell setModel:model selected:(indexPath.row == self.currentIndex)];
        cell.selectedBgView.backgroundColor = self.bg_bright_color;
        cell.contentView.backgroundColor = self.bg_ui_color;
        
        if (indexPath.row == self.currentIndex) {
            cell.lblEnglish.textColor = self.select_Color;
            cell.lblChinese.textColor = self.select_Color;
            cell.selectedBgView.hidden = NO;
        } else {
            cell.selectedBgView.hidden = YES;
            cell.lblEnglish.textColor = self.title_Color;
            cell.lblChinese.textColor = self.title_Color;
        }
        return cell;
    } else {
        //StorySectionModel *model = self.dataArray[indexPath.row];
        StoryImageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StoryImageCell" forIndexPath:indexPath];
        [cell setModel:model];
        cell.contentView.backgroundColor = self.bg_ui_color;
        return cell;
    }
}
#pragma mark - 点击段落（选中）

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger Index = self.currentIndex;
    self.isAudioScrolling = YES;
    //self.isPlayAudio_current = YES;
    
    [self.playerViewVideo stopVideo];
    if (indexPath.row < 0 || indexPath.row >= self.dataArray.count) return;
    StorySectionModel *model = self.dataArray[indexPath.row];
    if (model.type != StorySectionTypeText) return;
    // 避免重复点击同一行
    //if ([indexPath isEqual:self.selectedIndexPath]) return;
    NSIndexPath *previousIndexPath = self.selectedIndexPath;
    self.selectedIndexPath = indexPath;
    self.currentIndex = indexPath.row;
    self.menuView.lastIndex = self.currentIndex;
    //更新音频播放
    float start = [Language_key isEqualToString:@"En"] ? model.startTimeEN : model.startTimeCN;
    [self.menuView clickCellToTime:start];
    [self.menuView.playPauseButton setImage:[UIImage imageNamed:@"pause_black"] forState:UIControlStateNormal];
    if(Index < 0){
        [self.tableView reloadData];
    } else {
        // 只刷新旧选中行 + 当前选中行
        NSMutableArray *reloadArray = [NSMutableArray arrayWithObject:indexPath];
        if (previousIndexPath && ![previousIndexPath isEqual:indexPath]) {
            [reloadArray addObject:previousIndexPath];
        }
        [tableView reloadRowsAtIndexPaths:reloadArray withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadData];
    }
    [self playAudioAtIndexPath:indexPath isStart:YES];
}
#pragma mark - 滚动禁用自动联动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
   //if (self.isPlayAudio_current) {
   if ([self.menuView menuViewIsPlaying]) {
        if (self.isAudioScrolling) {
            self.isAudioScrolling = NO;
            [self.menuView setLocationState:YES];
            // TODO: 通知外部音频模块，关闭文字联动
        }
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"用户滚动结束，tableView 停止了");
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    [self playAudioAtIndexPath:indexPath isStart:NO];
}
// 设置段间距
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { return [UIView new];
}
#pragma mark - 外部音频调用接口
//=========================================================
- (StoryMenuView *)menuView {
    if(!_menuView){
        _menuView = [[StoryMenuView alloc] initWithFrame:self.view.bounds];
        _menuView.story_id = self.storyId;
        _menuView.audioControlView.hidden = NO;
        _menuView.unfoldButton.hidden = YES;
        _menuView.delegate = self;
        [_menuView getMythStory:self.isFairy];
   }
    return _menuView;
}
//===============================================
#pragma mark - StoryMenuViewDelegate
- (void)audioPlayerDidUpdateTime:(NSTimeInterval)currentTime
                         duration:(NSTimeInterval)duration {
}
- (void)storyMenuView:(StoryMenuView *)menuView didSelectStoryAtIndex:(NSInteger)index {
    NSLog(@"选中了第 %ld 个故事", (long)index);
    if (self.menuView.storyListArray && index >= 0 && index < self.menuView.storyListArray.count) {
        NSDictionary *storyDict = self.menuView.storyListArray[(int)index];
        if ([storyDict isKindOfClass:[NSDictionary class]]) {
            self.storyId = [NSString stringWithFormat:@"%@",storyDict[@"tale_id"]];
            [self loadStoryData:self.storyId];
            [self.menuView.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];
        }
    }
}
//播放结束
- (void)setAudioPlayerEnd:(BOOL)isEnd {
    //self.isPlayAudio_current = isEnd;
    self.menuView.btnLocation.hidden = YES;
    [self triggerStudyCompletedIfNeeded];
    //[self.menuView setMainAudioPlayer];
    //[self.menuView setLocationInitialization];
}
- (void)triggerStudyCompletedIfNeeded {
    if (self.hasCompletedStudy) return; // 防止重复
    self.hasCompletedStudy = YES;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.selectedIndexPath) {
        NSArray *visible = [self.tableView indexPathsForVisibleRows];
        if (![visible containsObject:self.selectedIndexPath]) {
            //[self.animatedImage removeFromSuperview];
        }
    }
    
   CGFloat offsetY = scrollView.contentOffset.y;
   CGFloat contentHeight = scrollView.contentSize.height;
   CGFloat viewHeight = scrollView.bounds.size.height;
   CGFloat insetBottom = scrollView.contentInset.bottom;

   if (offsetY + viewHeight + insetBottom >= contentHeight) {
       // 👉 已经滚动到底部
       NSLog(@"滚动到底部了-播放结束");
       [self triggerStudyCompletedIfNeeded];
   }
}
- (void)storyMenuViewDidTogglePlay:(StoryMenuView *)menuView {
    NSLog(@"播放/暂停");
    //[self togglePlayPause:self.playPauseButton];
    if (self.menuView.playerAudio.rate == 0.0) {
        [self cancelRecording];//暂停
    } else {
        //self.isPlayAudio_current = YES;
        self.isAudioScrolling = YES;
        [self.playerViewVideo stopVideo];
        [self startRecording];//播放
    }
}
- (void)storyMenuViewDidSeekToProgress:(CGFloat)progress {
    NSLog(@"拖动进度 %.2f", progress);
    if(!self.menuView.btnLanguage.hidden){
        //self.menuView.btnLocation.hidden = YES;
        //[self.menuView setLocationState:NO];
    }
}
- (void)storyMenuViewDidChangeLanguage:(NSString *)language {
    NSLog(@"切换语言: %@", language);
    self.isAudioScrolling = YES;
    BOOL hasVideo = (self.videoUrl.length > 6);
    if (hasVideo) {
        [self.playerViewVideo videoDidFinish];
    }
}
//当滚动不到当前cell时   根据定位强制跳转当前cell
- (void)scrollToCellAudioAtIndexCurrent:(NSInteger)index {
    
    if (index < 0 || index >= self.dataArray.count){
        if(index == -2){
            [self.tableView setContentOffset:CGPointMake(0, -self.tableView.adjustedContentInset.top) animated:NO];
        }
        //-1 只刷新 不滚动     -2刷新并滚动
        self.currentIndex = index;
        self.menuView.lastIndex = self.currentIndex;
        [self.tableView reloadData];
        [self cancelRecording];
       
    } else {
        //-1 播放结束
        //index = - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        self.currentIndex = index;
        self.menuView.lastIndex = self.currentIndex;
        [self.tableView reloadData];
        [self playAudioAtIndexPath:indexPath isStart:NO];//空
        
    }
} //313_AAA
//文本滚动核心代码
- (void)scrollToCellAtIndex:(NSInteger)index {
    if (self.isAudioScrolling) {
        if (index < 0 || index >= self.dataArray.count) return;
        if (index == self.currentIndex) return; // 避免重复滚动
            self.currentIndex = index;
            self.menuView.lastIndex = self.currentIndex;
            [self.tableView reloadData];
            [self smoothScrollToIndex11:index];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self playAudioAtIndexPath:indexPath isStart:NO];
    } else {
        self.currentIndex = index;
        self.menuView.lastIndex = self.currentIndex;
        [self.tableView reloadData];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self playAudioAtIndexPath:indexPath isStart:NO];//空
    }
}
//===============================================================
- (void)smoothScrollToIndex11:(NSInteger)index {
    if (index < 0 || index >= self.dataArray.count) return;
    
    // 防止频繁触发滚动（节流）
    static NSTimeInterval lastScrollTime = 0;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - lastScrollTime < 0.00003) return; // 300ms 内不重复滚动
    lastScrollTime = now;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.tableView numberOfRowsInSection:0] > indexPath.row) {
            [UIView animateWithDuration:0.15
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                [self.tableView scrollToRowAtIndexPath:indexPath
                                      atScrollPosition:UITableViewScrollPositionMiddle
                                              animated:NO]; // 这里设 NO，自定义动画更顺
            } completion:nil];
        }
    });
}
//更新播放进度
- (void)storyMenuViewAutoSync:(BOOL)autoSync {
    self.isAudioScrolling = autoSync;//启动定位跟踪
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    [self playAudioAtIndexPath:indexPath isStart:NO];
}
//=================xxxx================================
- (void)createCoverView {
  
    StoryLockCoverView *cover = [[StoryLockCoverView alloc] init];
    [self.view addSubview:cover];
    CGFloat topOffset = [PublicTool getStatusBarHeight] + 59;
    [NSLayoutConstraint activateConstraints:@[
        [cover.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:topOffset],
        [cover.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [cover.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [cover.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    self.cover = cover;// 点击回调

    self.cover.hidden = YES;
    cover.subscribeHandler = ^{
        self.isCove = YES;
        if([[UserModel sharedInstance] isLogin]){//需判断登录
            PaymentViewController *payVC = [PaymentViewController new];
            payVC.hidesBottomBarWhenPushed = YES;
           [self.navigationController pushViewController:payVC animated:YES];
            
        } else {
            
            [[LoginManager sharedManager] handleLoginExpiredWithCompletion:^{
                // 登录完成后的逻辑
                NSLog(@"登录完成，回到调用方法");
                [self loadStoryData:self.storyId];
                
                BOOL isLogin = [[UserModel sharedInstance] isLogin];
                NSString *title = @[@"Log in to continue reading",@"Unlock the complete Stories collection"][isLogin];
                NSString *str = @[@"Log In",@"Unlock Now"][isLogin];
                [self.cover.btnLogin setTitle:NSLocalizedString(str, @"") forState:UIControlStateNormal];
                self.cover.titleLabel.text = NSLocalizedString(title, @"");
                
            }];
        }
    };
}

@end



