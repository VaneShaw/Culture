//
//  StoryGodsViewController.m
//  YiTongProject
//
//  Created by ios01 on 2026/1/5.
//

#import "StoryGodsViewController.h"
#import "StoryMenuView.h"
#import "StoryAudioPlayer.h"
#import "StorySectionModel.h"
#import "StoryTextCell.h"
#import "StoryImageCell.h"
#import "VideoPlayerView.h"
#import "VideoFullScreenViewController.h"
#import "StorySectionModel.h"

NSInteger kRoundsWithoutCover = 0; // 可配置前 N 回合无封面
//static const CGFloat kBottomThreshold = 200.0;

@interface StoryGodsViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate,StoryMenuViewDelegate,UIScrollViewDelegate,StoryRoundPageViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AVPlayer *player;
//@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSArray<StorySectionModel *> *dataArray_current;
//@property (nonatomic, strong) NSIndexPath *selectedIndexPath; // 当前选中的段落
//@property (nonatomic, assign) BOOL isAudioScrolling;     // 是否跟随音频滚动（默认YES）
//@property (nonatomic, assign) BOOL isPlayAudio_current;          //是否选中播放 后 才能执行
@property (strong, nonatomic) NSString *videoUrl;

@property (strong, nonatomic) UIView *storyView;
@property (assign, nonatomic) BOOL isTemp;
@property (assign, nonatomic) BOOL isCove;
@property (nonatomic, strong) NSArray *storyArray;
@property (nonatomic, strong) NSMutableArray *chaptersArrays;
@property (nonatomic, assign) NSInteger totalPageCount;
@property (nonatomic, assign) NSInteger lastPageIndex; // 上一页
@property (nonatomic, copy) NSString *currentAudioUrl;
@property (nonatomic, strong) StoryMenuView *menuView_1;
@property (nonatomic, strong) StoryRoundPageView *storyPageView;

@property (nonatomic, assign) BOOL isAutoJump;          //yes 系统切换回合  no,其他
@property (nonatomic, assign) BOOL isUserDragging;      //yes 人为滚动 no 系统滚动
@property (nonatomic, assign) BOOL allowAudioSwitch;    //是否允许切音频
@property (nonatomic, assign) NSInteger currentRoundIndex;        // 当前可视回合
@property (nonatomic, assign) NSInteger currentAudioRoundIndex;   // 当前音频所属回合
@property (nonatomic, strong) NSString *currentAudioRoundId;
@property (nonatomic, assign) NSInteger lastHandledRoundIndex; //记录目录已处理回合
@property (nonatomic, assign) BOOL isChangingLanguage;
@property (nonatomic, assign) BOOL hasMaxRound; //是否已有最大回合
@property (nonatomic, strong) dispatch_source_t languageDebounceTimer;
@property (nonatomic, assign) NSInteger minRound;   // 当前数组中最小回合id
@property (nonatomic, assign) NSInteger maxRound;   // 当前数组中最大回合id
@property (nonatomic, assign) NSInteger maxPublished;//接口返回的最大发布回合数
@property (nonatomic, assign) NSInteger currentRound; // 用户当前所在回合
@property (nonatomic, assign) BOOL isLoading; // 防止重复请求
@property (nonatomic, assign) BOOL hasCompletedStudy;
@end

@implementation StoryGodsViewController

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

- (void)viewWillDisappear:(BOOL)animated {//视图即将消失v
    [super viewWillDisappear:animated];
    [[AudioScrollManager shared] reset];
    //[self.storyPageView.playerViewVideo turnOffVideoPlayback];
    [[MediaPlayManager sharedManager] turnOffVideoPlayback1];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.menuView_1.playerAudio pause];
    [self.menuView_1.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];
    UIViewController *toVC = self.navigationController.topViewController;
    if ([toVC isKindOfClass:[VideoFullScreenViewController class]]) {
        NSLog(@"👉 即将进入全屏页面");
        //[self forceFullLayoutRefresh];
    } else if (self.isMovingFromParentViewController) {
        //[self.storyPageView.playerViewVideo stopVideo];
    }
    
    // ① 真正离开（pop / dismiss）
     if (self.isMovingFromParentViewController ||
         self.isBeingDismissed) {
         [self.menuView_1 menuForceStopAudio];
     } else {
         // ② 只是被 present 覆盖（比如进入登录页）
         [self.menuView_1 menuViewPause];
     }
    
    if (self.studyStartTimeMs > 0) {
        [self endStudyWithCompleted:self.hasCompletedStudy
                          eventType:EventTypeStory
                           eventName:@"故事阅读"
                         contentType:@"fengshen"
                           extraParams:nil];
    }
    self.hasCompletedStudy = NO;
}
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if ([viewController isKindOfClass:[StoryGodsViewController class]]) {
        //NSLog(@"用户正在侧滑返回上一页");
    }
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"story_fengshen";
    self.rounds = [NSMutableArray new];
    self.chaptersArrays = [NSMutableArray new];
    self.isLoading = NO;
    self.isCove = NO;
    self.hasMaxRound = NO;
    [AudioScrollManager shared].isAudioScrolling_2 = YES;
    NSInteger value = [KUSER_DEFAULT integerForKey:@"test_key1"];
    if (value > 0) {
        //kRoundsWithoutCover = value; // 运行时赋值
    }
    //self.storyViewArrays = [NSMutableArray new];
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
    [self setupScrollView];
    self.storyPageView.currentIndex_1 = -1;

    [self.view addSubview:self.menuView_1];
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"#FFFFFF" alpha:0.5] headerTitleDic:@{}];
    [self loadStoryDataFromStoryId:self.storyId isNewEpisode:NO];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}
- (void)onMembershipUpdated{
    if(self.storyId.intValue > 0){
        [self loadStoryDataFromStoryId:self.storyId isNewEpisode:NO];
        [self.menuView_1.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];
    }
}
#pragma mark - TableView Setup

//=======================================================
//=======================================================
#pragma mark - Load Data
- (CGFloat)secondsFromFrameTimeString:(NSString *)timeString frameRate:(CGFloat)fps {
    NSArray<NSString *> *components = [timeString componentsSeparatedByString:@":"];
    if (components.count != 3) return 0;
    NSInteger minutes = [components[0] integerValue];
    NSInteger seconds = [components[1] integerValue];
    NSInteger frames = [components[2] integerValue];
    return minutes * 60 + seconds + (frames / fps);
}
- (void)loadStoryDataFromStoryId:(NSString *)storyId isNewEpisode:(BOOL)isEpisode{

    self.storyPageView.currentIndex_1 = -1;
    [self.tableView layoutIfNeeded];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    self.storyId = storyId;
    NSString *strUrl = @"/classic/chapterContinuous";
    params[@"chapter_id"] = storyId;
    params[@"mode"] = @[@"backward",@"forward",@"window"][self.modeType];//+前。+后  中
    [HttpTools postRequest:strUrl parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        if (success) {
            self.isLoading = NO;
            self.isTemp = YES;
            if(self.modeType == 2){
                self.rounds = [NSMutableArray new];
                self.chaptersArrays = [NSMutableArray new];
            }
            //========================================================================
            self.storyArray = response.data[@"chapters"];
            [self.chaptersArrays addObjectsFromArray:self.storyArray];
            NSDictionary *work_status = [NSDictionary dictionaryWithDictionary:response.data[@"work_status"]];
            NSString *published_chapters = [NSString stringWithFormat:@"%@",work_status[@"published_chapters"]];
            self.maxPublished = published_chapters.integerValue ;
            
           //========================================================================
            NSMutableArray *arrDataArrays = [NSMutableArray array];
            for (int i = 0 ; i < self.storyArray.count  ; i++) {//===============222======
                self.isTemp = YES;
                NSDictionary *dicData = ([self.storyArray[i] isKindOfClass:[NSDictionary class]]) ? self.storyArray[i] : @{};
                NSDictionary *dicStory = [NSDictionary dictionaryWithDictionary:dicData];
                NSArray *dataArray = ([dicData[@"sections"] isKindOfClass:[NSArray class]]) ? dicData[@"sections"] : @[];
                StorySectionModel *m = [StorySectionModel new];
                NSString *cover_image = [NSString stringWithFormat:@"%@",dicStory[@"cover_image"]];
                
                //cover_image = @"https://testoss.shiyi-yitong.com/story/fengshen/images/ch1_cover.png";
                m.coverImageName = cover_image;
                m.model_id = [NSString stringWithFormat:@"%@",dicStory[@"chapter_id"]];
                m.chapter_no = [NSString stringWithFormat:@"%@",dicStory[@"chapter_no"]];
                m.main_end_time = [NSString stringWithFormat:@"%@",dicStory[@"main_end_time"]];
                m.fallback_end_time = [NSString stringWithFormat:@"%@",dicStory[@"fallback_end_time"]];
                m.type = StorySectionTypeText;
                m.bg_color = [NSString stringWithFormat:@"%@",dicStory[@"bg_color"]];
                m.main_audio_url = [NSString stringWithFormat:@"%@",dicStory[@"main_audio_url"]];
                m.fallback_audio_url = [NSString stringWithFormat:@"%@",dicStory[@"fallback_audio_url"]];
 
                m.video_url = [NSString stringWithFormat:@"%@",dicStory[@"video_url"]];
                NSString *str = [NSString stringWithFormat:@"%@", dicStory[@"head_image"]];
                m.head_image = [str isEqualToString:@"(null)"] ? @"" : str;
                
                //m.video_url = @"https://testoss.shiyi-yitong.com/story/myth/videos/pangu.mp4";
                //m.head_image = @"https://pics0.baidu.com/feed/279759ee3d6d55fb4f9085e0db6af34521a4dd7f.jpeg?token=b5f47419eae5468d89279056bb1773fa";
                
                m.font_color = [NSString stringWithFormat:@"%@",dicStory[@"font_color"]];
                m.bright_color = [NSString stringWithFormat:@"%@",dicStory[@"bright_color"]];
                m.bright_bg_color = [NSString stringWithFormat:@"%@",dicStory[@"bright_bg_color"]];
                id lockValue = dicStory[@"is_lock"];
                m.is_lock = (lockValue && lockValue != [NSNull null])
                            ? [NSString stringWithFormat:@"%@", lockValue]
                            : @"0";
        
                //m.is_lock = arc4random_uniform(2) == 1 ? @"1" : @"0";
                //m.title = [NSString stringWithFormat:@"第 %@ 回合", m.chapter_no];
                //====================================================
                NSMutableArray *conts = [NSMutableArray new];
                for (NSDictionary *sectionDict in dataArray) {//============111=========
                    if (![sectionDict isKindOfClass:[NSDictionary class]]) continue;
                    NSArray *lines = sectionDict[@"lines"];
                    if (![lines isKindOfClass:[NSArray class]]) continue;
                    // 1️⃣ 标题
                    NSString *main_title = [NSString stringWithFormat:@"%@",sectionDict[@"main_title"]];
                    if(main_title.length > 0){
                        [conts addObject:[self modelFromDict:sectionDict type:StorySectionTypeText isTitle:YES]];
                    }
                    // 2️⃣ 每行文本
                    for (NSDictionary *lineDict in lines) {
                        [conts addObject:[self modelFromDict:lineDict type:StorySectionTypeText isTitle:NO]];
                    }
                    NSString *bottom_image = [NSString stringWithFormat:@"%@", sectionDict[@"bottom_image"]];
                    // 3️⃣ 底部图片
                    if(bottom_image.length > 6){
                        StorySectionModel *imageModel = [[StorySectionModel alloc] init];
                        imageModel.model_id = [NSString stringWithFormat:@"%@", sectionDict[@"section_id"]];
                        imageModel.type = StorySectionTypeImage;
                        imageModel.imageLoaded = NO;
                        imageModel.imageUrl = bottom_image;
                        [conts addObject:imageModel];
                    }
                }//===========================================111================
                m.contents = conts;
                [arrDataArrays addObject:m];
            }//===============222===================================
            if (arrDataArrays.count == 0) {
                   return;
               }
            switch (self.modeType) {
                case 0:
                {
                    NSMutableArray *temp2 = [NSMutableArray arrayWithArray:self.storyArray];
                    [temp2 addObjectsFromArray:self.chaptersArrays];
                    self.chaptersArrays = temp2;
                    [self prependRounds:arrDataArrays];
                }
                    break;
                case 1:
                {
                   
                    [self.chaptersArrays addObjectsFromArray:self.storyArray];
                    [self appendRounds:arrDataArrays];
                }
                    break;
                case 2:
                {
                    [self.rounds addObjectsFromArray:arrDataArrays];
                    [self buildPagesisNewEpisode:isEpisode];
                }
                    break;
                default:
                    break;
            }
            //==========================================================================
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
            //=========================================================================
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
    [m setStartTimeCNWithString:dict iskeyTime:YES];
    [m setStartTimeENWithString:dict iskeyTime:YES];
    return m;
}
#pragma mark - 外部音频调用接口
//=========================================================
- (StoryMenuView *)menuView_1 {
    if(!_menuView_1){
        _menuView_1 = [[StoryMenuView alloc] initWithFrame:self.view.bounds];
        _menuView_1.audioControlView.hidden = NO;
        _menuView_1.unfoldButton.hidden = YES;
        _menuView_1.delegate = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _menuView_1.story_id = self.storyId;
            [_menuView_1 getMythStory:self.isFairy];
        });
   }
    return _menuView_1;
}
//===============================================
//===============================================
#pragma mark - StoryMenuViewDelegate
- (void)audioPlayerDidUpdateTime:(NSTimeInterval)currentTime
                         duration:(NSTimeInterval)duration {
    
    if (self.currentRoundIndex != self.currentAudioRoundIndex) return;
    // 2️⃣ 防止重复触发
    NSInteger roundIndex = [self currentRoundIndex];
    if (roundIndex < 0 || roundIndex >= self.rounds.count) return;
    static NSInteger lastJumpedRoundIndex = -1;
    if (lastJumpedRoundIndex == roundIndex) return;
    // 3️⃣ 取当前回合
    StorySectionModel *model = self.rounds[roundIndex];
    NSString *timeString = [Language_key isEqualToString:@"En"]
        ? model.fallback_end_time
        : model.main_end_time;
    NSTimeInterval coverDuration = [PublicTool secondsFromFrameTimeString:timeString frameRate:30];

    if (coverDuration <= 0) return;
    NSTimeInterval timeWindow = 0.5; // 前后0.5秒窗口
    if (currentTime <= 0) return;
    //点击播放
    // =====================================================
    // 🔴【新增逻辑 A】
    // 音频仍在封面时间内，但页面已经不在封面
    // 且 model_id > 2，则向前回跳一页
    if (model.model_id.intValue > 2&&
        ![self currentPageIsCover]) {
        //if (fabs(currentTime - coverDuration) <= timeWindow) {
        NSTimeInterval epsilon = 0.1;
        NSTimeInterval minTime = 0.001;
        if (currentTime >= minTime &&
            currentTime < coverDuration - epsilon) {
            NSInteger prevPage = self.lastPageIndex - 1;
            if (prevPage >= 0) {
                NSInteger visibleIndex = self.currentRoundIndex;
                //NSLog(@"--bool--------------------[%d]--------00-------",[AudioScrollManager shared].isAudioScrolling_2);
                if (visibleIndex == self.currentAudioRoundIndex && !self.isChangingLanguage &&[AudioScrollManager shared].isAudioScrolling_2) {
                    [self scrollToPage:prevPage animated:YES];    //切换语言的情况下 并且 row > 0 的情况下3秒内不会触发这个代码 怎么处理
                }
            }
            return; // ⚠️ 非常重要，防止继续往下执行
        }
    }
    //NSLog(@"内容-----跳封面-------------------xxxx--------------------------------------------------------------------------------xxxx-------------------------------[%ld]=[%ld]--------------", (long)prevPage,visibleIndex,self.currentAudioRoundIndex);
    // =====================================================
    // 1️⃣ 必须在封面页
    if (![self currentPageIsCover]) return; //不在就不执行。还有必须在当前音频对应回合
    // ⚠️ 回合级 once 标记
    if (fabs(currentTime - coverDuration) <= timeWindow) {
        NSInteger nextPage = self.lastPageIndex + 1;
        if (nextPage < self.totalPageCount) {
            
            NSInteger visibleIndex = self.currentRoundIndex;
            if (visibleIndex == self.currentAudioRoundIndex  &&[AudioScrollManager shared].isAudioScrolling_2) {
                [self scrollToPage:nextPage animated:YES];
            }
            //NSLog(@"封面-----跳内容-------------[%ld]---------------------------------------vvvv------------------------------------------------------------------------------------vvvv-----------------------------------------------------------------------------------vvvv---------------------[%ld]=[%ld]--------------", (long)nextPage,visibleIndex,self.currentAudioRoundIndex);
        }
    }
    //===========================================
}
- (void)storyMenuView:(StoryMenuView *)menuView didSelectStoryAtIndex:(NSInteger)index {
    //点击播放
    NSLog(@"选中了第 %ld 个故事------------", (long)index);
    [[MediaPlayManager sharedManager] stopCurrentVideo];
    NSString *storyId = [NSString stringWithFormat:@"%@",self.menuView_1.storyListArray[(int)index][@"chapter_id"]];
    NSInteger storyIndex = [self.chaptersArrays indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        id str = @"chapter_id";
        return [[NSString stringWithFormat:@"%@", [obj objectForKey:str]] isEqualToString:storyId];
    }];
    
    if(self.currentRoundIndex == storyIndex)return;
        
    self.storyId = storyId;
    [KUSER_DEFAULT setObject:self.storyId forKey:Story_Scroll_Index];
    [KUSER_DEFAULT setInteger:0 forKey:Story_Scroll_Row];
    [AudioScrollManager shared].isAudioScrolling_2 = YES;
    //这里需要再换算下，因为前面两个回合 不算回合，是简介跟序言
    if([self chaptersArrayContainsStoryId]){
        [self loadStoryDataArray:YES isNewEpisode:YES];
    } else {
        self.modeType = 2;//有问题111v
        [self loadStoryDataFromStoryId:self.storyId isNewEpisode:YES];
    }
    
    [self.menuView_1 setMenuViewIndex:self.storyId];
    [self updatePlayPauseButton];
    /*
     StorySectionModel *model = self.rounds[roundIndex];
     // 3️⃣ 更新全局音频回合标记
     self.currentAudioRoundIndex = roundIndex;
     //
     */
    StoryRoundPageView *tempView = [self.scrollView viewWithTag:300 + self.currentRoundIndex];
    if (tempView ) {
        // 停止视频
        //if ([tempView respondsToSelector:@selector(playerViewVideo)] &&
            //[tempView.playerViewVideo respondsToSelector:@selector(stopVideo)]) {
            //[tempView.playerViewVideo stopVideo];
        //}

        // 滚动 tableView 到顶部
        UITableView *tableView = tempView.tableView;
        if ([tableView isKindOfClass:[UITableView class]]) {
            // 防止 contentInset / safeArea 异常
            CGFloat topOffset = -tableView.adjustedContentInset.top;
            if (tableView.contentSize.height > 0) { // 防止 contentSize 为 0
                [tableView setContentOffset:CGPointMake(0, topOffset) animated:NO];
            }
        }
    }
}
//---------------------------------
- (BOOL)chaptersArrayContainsStoryId {
    //判断所选id是否有在当前数组里面，有的话直接跳转，没有就重新加载
    if (self.storyId.length == 0) return NO;
    NSUInteger index = [self.chaptersArrays indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:[NSDictionary class]]) return NO;
        id chapterId = obj[@"chapter_id"];
        if (!chapterId) return NO;
        // 统一转成字符串比较（兼容 NSNumber / NSString）
        NSString *chapterIdStr = [NSString stringWithFormat:@"%@", chapterId];
        return [chapterIdStr isEqualToString:self.storyId];
    }];
    return index != NSNotFound;
}
//---------------------------------
- (void)storyMenuViewDidTogglePlay:(StoryMenuView *)menuView {
    NSLog(@"==播放/暂停==");//点击播放
    //[self togglePlayPause:self.playPauseButton];
    //[self.storyPageView.menuView togglePlayPause:self.storyPageView.menuView.playPauseButton];
    if (self.menuView_1.playerAudio.rate == 0.0) {
        [self.storyPageView cancelRecording];//暂停
        [AudioScrollManager shared].isAudio_Playing = NO;
    } else {
        if (self.menuView_1.progressSlider.value > 0.001f){
        } else {
            self.allowAudioSwitch = YES;
            NSInteger roundIndex = [self currentRoundIndex];
            [self switchAudioForRoundIndex:roundIndex];
        }
        //[self.storyPageView.playerViewVideo stopVideo];
        if ([self.menuView_1 menuViewIsPlaying]) {
            [AudioScrollManager shared].isAudioScrolling_2 = YES;
        }
        [self.storyPageView startRecording];//播放
        [AudioScrollManager shared].isAudio_Playing = YES;
    }
}
- (void)storyMenuViewDidSeekToProgress:(CGFloat)progress {
    NSLog(@"拖动进度 %.2f", progress);
    if(!self.menuView_1.btnLanguage.hidden){
        //self.menuView.btnLocation.hidden = YES;
        //[self.menuView setLocationState:NO];
    }
}
- (void)storyMenuViewDidChangeLanguage:(NSString *)language {
    NSLog(@"切换语言: [%@]----------------------", language);
    self.isChangingLanguage = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //self.isChangingLanguage = NO;
        });
    //-------------------------------------
    // 🔴 取消上一次计时
       if (self.languageDebounceTimer) {
           dispatch_source_cancel(self.languageDebounceTimer);
           self.languageDebounceTimer = nil;
       }
       // 🔵 创建新的 3 秒防抖定时
       dispatch_queue_t queue = dispatch_get_main_queue();
       self.languageDebounceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
       dispatch_source_set_timer(
           self.languageDebounceTimer,
           dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
           DISPATCH_TIME_FOREVER,0
       );
       __weak typeof(self) weakSelf = self;
       dispatch_source_set_event_handler(self.languageDebounceTimer, ^{
           __strong typeof(weakSelf) self = weakSelf;
           self.isChangingLanguage = NO;
           self.languageDebounceTimer = nil;
           NSLog(@"语言切换稳定，解锁滚动");
       });

       dispatch_resume(self.languageDebounceTimer);
    //-------------------------------------
    if ([self.menuView_1 menuViewIsPlaying]) {
        //self.storyPageView.isAudioScrolling = YES;
        [AudioScrollManager shared].isAudioScrolling_2 = YES;
    }
    BOOL hasVideo = (self.videoUrl.length > 6);
    if (hasVideo) {
        [self.storyPageView.playerViewVideo videoDidFinish];
    }
}
- (void)triggerStudyCompletedIfNeeded {
    if (self.hasCompletedStudy) return; // 防止重复
    self.hasCompletedStudy = YES;
}
//播放结束
- (void)setAudioPlayerEnd:(BOOL)isEnd {
    //self.storyPageView.isPlayAudio_current = isEnd;
    self.menuView_1.btnLocation.hidden = YES;
    [self triggerStudyCompletedIfNeeded];
    
    //------------播放结束--------------------------
    //---------------------------------------------
    if (self.currentAudioRoundIndex < 0 ||
        self.currentAudioRoundIndex >= self.rounds.count) {
        return;
    }
    StorySectionModel *currentModel = self.rounds[self.currentAudioRoundIndex];
    if (currentModel.chapter_no.integerValue == self.maxPublished) {
        // 当前就是最大回合，不再加载
        return;
    }
    //NSLog(@"-AAA------测试00----------------------111-------11------");
    [self.storyPageView scrollTableViewToBottomIfNeeded];
    [self switchToNextRoundWithDelay:1.35];
}
/*- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat viewHeight = scrollView.bounds.size.height;
    CGFloat insetBottom = scrollView.contentInset.bottom;

    if (offsetY + viewHeight + insetBottom >= contentHeight) {
        // 👉 已经滚动到底部
        NSLog(@"滚动到底部了");
    }
}*/
//点击跳转到下一回合 进入下一回合
- (void)switchToNextRound{
    NSInteger nextPage = self.lastPageIndex + 1;
    if (nextPage >= self.totalPageCount) {
        return; // 已经是最后一回合
    }
    [self scrollToPage:nextPage animated:YES];
}
- (void)switchToNextRoundWithDelay:(NSTimeInterval)delay {
 
    NSInteger nextPage = self.lastPageIndex + 1;
    //NSLog(@"---[%ld]--AAA------测试11--------------------[%ld]-----[%ld]",self.lastPageIndex,nextPage,self.totalPageCount);
    if (nextPage >= self.totalPageCount) {
        return; // 已经是最后一回合
    }
    //4-2
    if (nextPage == self.totalPageCount-2 && !self.hasMaxRound){
        //NSLog(@"-------加载更多数据-----------");
        //[self checkNeedLoadMore];
        [self needLoadNext];
    }
    //NSLog(@"--22----total-------------cc---22-[%ld]",self.totalPageCount);
    // 1️⃣ 切换到下一个回合
    self.isAutoJump = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        self.isAutoJump = YES;
       [self scrollToPage:nextPage animated:YES];
       //[self switchToNextRound];
    });
    // 2️⃣ 页面滚动完成后，切音频并播放
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((delay + 1.0) * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        self.isAutoJump = YES;
      
        NSInteger nextIndex = self.currentAudioRoundIndex + 1;
        //===============
        if (nextIndex < 0 || nextIndex >= self.rounds.count) {
            return; // 已是最后一回合 or 数据异常
        }
        //StorySectionModel *model = self.rounds[nextIndex];
     
        //===================
        [self switchAudioForRoundIndex:nextIndex];
        [self.menuView_1 menuViewPlay];
    });
}

- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated {
    if (page < 0) return;
    CGFloat pageHeight = self.scrollView.bounds.size.height;
    CGFloat maxOffsetY = self.scrollView.contentSize.height - pageHeight;
    CGFloat offsetY = page * pageHeight;
    offsetY = MAX(0, MIN(offsetY, maxOffsetY));
    //NSLog(@"测试0----------------------222-------------");
    if([AudioScrollManager shared].isAudioScrolling_2){
        //NSLog(@"测试0----------------------333-------------");
        [self.scrollView setContentOffset:CGPointMake(0, offsetY)
                                 animated:animated];
    }
    [KUSER_DEFAULT setInteger:0 forKey:Story_Scroll_Row];
}
//===============================================
- (void)switchToPreviousRound {
    NSInteger prevPage = self.lastPageIndex - 1;
    if (prevPage < 0) {
        return; // 已经是第一回合
    }
    [self scrollToPage:prevPage animated:YES];
}
//=================xxxx==========================

//====================================================================
//- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//}
//====================================================================
//====================================================================

- (void)jumpToRound:(NSInteger)roundIndex preferCover:(BOOL)preferCover chapter_id:(NSString *)chapter_id {
    
    if (roundIndex < 0 || roundIndex >= self.rounds.count) return;
    self.currentRoundIndex = roundIndex;
    NSInteger targetPage = 0;
    NSInteger pageCounter = 0;
    for (NSInteger i = 0; i < self.rounds.count; i++) {
        StorySectionModel *model = self.rounds[i];
        BOOL hasCover = model.coverImageName.length > 0;
        NSInteger pagesInRound = hasCover ? 2 : 1;
        if (i == roundIndex) {
            // 默认跳到该回合的“第一页”
            targetPage = pageCounter;
            // 有封面，但不跳封面 → 跳内容页
            //if (hasCover && !preferCover) {
                //targetPage += 1;
            //}
            if (hasCover && !preferCover) {
                    targetPage += 1; // 有封面 → 跳内容页
                }
            // 无封面 → 只能是内容页（第一页就是内容）
            break;
        }
        pageCounter += pagesInRound;
    }
    // ⚠️ 确保布局完成
    [self.scrollView layoutIfNeeded];
    CGFloat pageHeight = self.scrollView.bounds.size.height;
    CGFloat offsetY = targetPage * pageHeight;
    [self.scrollView setContentOffset:CGPointMake(0, offsetY) animated:NO];
    [self updateCurrentRoundIndex:roundIndex];
    [self switchAudioForRoundIndex:roundIndex];
   
    //========================================================================
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger storyRoundIndex = [[KUSER_DEFAULT objectForKey:Story_Scroll_Index] integerValue];
        if (storyRoundIndex != chapter_id.integerValue) return;
            // tableView 选中行 有问题111vvv
            NSInteger row = [KUSER_DEFAULT integerForKey:Story_Scroll_Row];
            NSInteger section = 0;
            if (row > 0 && row < [self.storyPageView.tableView numberOfRowsInSection:section]) {
                //========================================================================
                [self.storyPageView.tableView layoutIfNeeded];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                    [self.storyPageView.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                    if ([self.storyPageView.tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                        [self.storyPageView.tableView.delegate tableView:self.storyPageView.tableView didSelectRowAtIndexPath:indexPath];
                    }
                });
            }
    });
    //========================================================================
}
//====================================================================
- (NSInteger)currentRoundIndex {

    CGFloat pageHeight = self.scrollView.bounds.size.height;
    CGFloat offsetY = self.scrollView.contentOffset.y;
    NSInteger pageIndex = (NSInteger)round(offsetY / pageHeight);
    NSInteger currentRound = 0;
    NSInteger pageCounter = 0;
    for (StorySectionModel *model in self.rounds) {
        NSInteger pagesInRound = model.coverImageName.length > 0 ? 2 : 1;
        if (pageIndex < pageCounter + pagesInRound) {
            // 当前页属于这一回合
            return currentRound;
        }
        pageCounter += pagesInRound;
        currentRound++;
    }
    return self.rounds.count - 1; // 超出范围返回最后一回合
}
- (BOOL)currentPageIsCover {
 
    CGFloat pageHeight = self.scrollView.bounds.size.height;
    if (pageHeight <= 0) return NO;
    NSInteger pageIndex =
        (NSInteger)floor(self.scrollView.contentOffset.y / pageHeight);
    NSInteger pageCounter = 0;
    for (StorySectionModel *model in self.rounds) {
        BOOL hasCover = model.coverImageName.length > 0;
        NSInteger pagesInRound = hasCover ? 2 : 1;
        if (pageIndex < pageCounter + pagesInRound) {
            if (hasCover) {
                // 有封面：该回合第一页才是封面
                return pageIndex == pageCounter;
            } else {
                // 无封面：永远不是封面页
                return NO;
            }
        }
        pageCounter += pagesInRound;
    }
    //NSLog(@"------ddd---------------------====----------333--");
    return NO;
}
//====================================================================
- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = NO;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    for (UIGestureRecognizer *gesture in self.scrollView.gestureRecognizers) {
          if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
              // tableView 滚动时，外层 scrollView 的 pan 等 tableView 失败后再识别
              //[gesture requireGestureRecognizerToFail:self.storyPageView.tableView.panGestureRecognizer];
          }
      }
  
}
//首次进入
- (void)buildPagesisNewEpisode:(BOOL)isEpisode {
    // 清除旧视图
        for (UIView *subview in self.scrollView.subviews) {
            [subview removeFromSuperview];
        }
    //self.totalPageCount = 0;
    CGFloat h = self.view.bounds.size.height;
    CGFloat w = self.view.bounds.size.width;
    
    NSInteger page = 0;
    NSInteger pageContent = 0;
    self.minRound = self.rounds.firstObject.model_id.integerValue;
    self.maxRound = self.rounds.lastObject.model_id.integerValue;
    for (StorySectionModel *model in self.rounds) {
        //model.title = [NSString stringWithFormat:@"第 %d 回合", (int)pageContent + 1];
        StoryCoverPageView *cover = [[StoryCoverPageView alloc] initWithFrame:CGRectMake(0, page * h, w, h)  title:model.title imageName:model.coverImageName];
        if(model.coverImageName.length > 0){
            [self.scrollView addSubview:cover];
            page++;
        }
        StoryRoundPageView *content = [[StoryRoundPageView alloc] initWithFrame:CGRectMake(0, page * h, w, h) model:model];
        if(model.is_lock.boolValue){
            [self setPageCover:content.cover model:model];
        }
        [content setDidSelectRowBlock:^(int index) {
            [self switchToNextRound];
            //[self checkNeedLoadMore];
        }];
        content.headerView.uvc = self;
        content.delegate = self;
        content.tag = 300 + pageContent;
        content.roundIndex = pageContent;
        if(model.model_id.intValue == 1){
            [content.footerView setFooterArrowState:0];
        } else if(model.model_id.intValue == self.maxPublished+2){
            [content.footerView setFooterArrowState:2];
        } else {
            [content.footerView setFooterArrowState:1];
        }
        pageContent++;
        [self.scrollView addSubview:content];
        page++;
    }
    self.totalPageCount = page;
    self.scrollView.contentSize = CGSizeMake(w, page * h);
    // ===== 恢复上次阅读进度 =====
    //NSInteger cellOffset = roundContentTableView.contentOffset.y;
    if(self.modeType==2){
        [KUSER_DEFAULT setObject:self.storyId forKey:Story_Scroll_Index];
    }
    
    NSInteger row = [KUSER_DEFAULT integerForKey:Story_Scroll_Row];
    BOOL isFirstLoad = (row < 1);
    [self loadStoryDataArray:isFirstLoad isNewEpisode:isEpisode];
    StorySectionModel *model1 = self.rounds.firstObject;
    self.view.backgroundColor = [self.view colorWithHexString:model1.bright_bg_color alpha:0.1];
    self.scrollView.backgroundColor = [self.view colorWithHexString:model1.bright_bg_color alpha:0.1];
    //有问题111v
    /*if(row==-1){
        [self.storyPageView.tableView layoutIfNeeded];
        NSInteger row1 = 0;
        NSInteger section1 = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row1 inSection:section1];
            [self.storyPageView.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            if ([self.storyPageView.tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                [self.storyPageView.tableView.delegate tableView:self.storyPageView.tableView didSelectRowAtIndexPath:indexPath];
            }
        });
    }*/
}
- (void)prependRounds:(NSArray<StorySectionModel *> *)newRounds {
    // 1. 记录当前可见页（scrollView 偏移量换算）
    CGFloat pageHeight = self.view.bounds.size.height;
    NSInteger visiblePage = round(self.scrollView.contentOffset.y / pageHeight);
    // 2. 前插数组
    NSMutableArray *temp = [NSMutableArray arrayWithArray:newRounds];
    [temp addObjectsFromArray:self.rounds];
    self.rounds = temp;
    // 3. 清空 scrollView 旧视图
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    // 4. rebuild 页面
    NSInteger page = 0;
    NSInteger pageContent = 0;
    CGFloat w = self.view.bounds.size.width;
    for (StorySectionModel *model in self.rounds) {       // 封面
        if (model.coverImageName.length > 0) {
            StoryCoverPageView *cover = [[StoryCoverPageView alloc] initWithFrame:CGRectMake(0, page * pageHeight, w, pageHeight) title:model.title imageName:model.coverImageName];
            [self.scrollView addSubview:cover];
            page++;
        }
        // 内容页
        StoryRoundPageView *content = [[StoryRoundPageView alloc] initWithFrame:CGRectMake(0, page * pageHeight, w, pageHeight) model:model];
        if(model.is_lock.boolValue){
            [self setPageCover:content.cover model:model];
        }
        [content setDidSelectRowBlock:^(int index) {
            [self switchToNextRound];
        }];
        content.headerView.uvc = self;
        content.delegate = self;
        content.tag = 300 + pageContent;
        content.roundIndex = pageContent;
        if(model.model_id.intValue == 1){
            [content.footerView setFooterArrowState:0];
        } else if(model.model_id.intValue == self.maxPublished+2){
            [content.footerView setFooterArrowState:2];
        } else {
            [content.footerView setFooterArrowState:1];
        }
        pageContent++;
        [self.scrollView addSubview:content];
        page++;
    }
    self.totalPageCount = page;
    self.scrollView.contentSize = CGSizeMake(w, page * pageHeight);
    // 5. 修正 contentOffset，保证用户看到的页不变
    NSInteger newIndex = visiblePage + newRounds.count;
    CGFloat newOffsetY = newIndex * pageHeight;
    [self.scrollView setContentOffset:CGPointMake(0, newOffsetY) animated:NO];
    self.lastPageIndex = -1;
    // 6. 更新 min/max
    self.minRound = self.rounds.firstObject.model_id.integerValue;
    self.maxRound = self.rounds.lastObject.model_id.integerValue;
    //NSLog(@"------00------------[%ld]-----------音频所属回合----------------",self.currentAudioRoundIndex);
    self.currentAudioRoundIndex = [self currentAudioRoundIndexWithAudioId:self.currentAudioRoundId];
    self.storyPageView = [self.scrollView viewWithTag:300 + self.currentAudioRoundIndex];
    [AudioScrollManager shared].hasPrependedData = YES;
    // 前插 2 条数据
    [self adjustLastPageIndexForInsertAtIndex:0 count:page];
    
    //NSLog(@"----------------------------前插--数据--------- count=[%d]-------------------totalPageCount-------------[%ld]",newRounds.count,self.totalPageCount);
}
- (NSInteger)currentAudioRoundIndexWithAudioId:(NSString *)audioId {
    if (!audioId || self.rounds.count == 0) return NSNotFound;
    for (NSInteger i = 0; i < self.rounds.count; i++) {
        StorySectionModel *model = self.rounds[i];
        if ([model.model_id isEqualToString:audioId]) {
            return i;
        }
    }
    return NSNotFound;
}
//self.currentAudioRoundIndex = roundIndex;
- (void)appendRounds:(NSArray<StorySectionModel *> *)newRounds {
    //往后加数据
    if (newRounds.count == 0) return;
    NSInteger startRoundIndex = self.rounds.count;
    NSInteger page = self.totalPageCount;
    [self.rounds addObjectsFromArray:newRounds];
    CGFloat pageHeight = self.view.bounds.size.height;
    CGFloat w = self.view.bounds.size.width;
    
    for (NSInteger i = 0; i < newRounds.count; i++) {
        StorySectionModel *model = newRounds[i];
        if (model.coverImageName.length > 0) {
            StoryCoverPageView *cover =
            [[StoryCoverPageView alloc] initWithFrame:CGRectMake(0, page * pageHeight, w, pageHeight) title:model.title imageName:model.coverImageName];
            [self.scrollView addSubview:cover];
            page++;
        }
        StoryRoundPageView *content = [[StoryRoundPageView alloc] initWithFrame:CGRectMake(0, page * pageHeight, w, pageHeight) model:model];
        content.headerView.uvc = self;
        content.delegate = self;
        if(model.is_lock.boolValue){
            [self setPageCover:content.cover model:model];
        }
        [content setDidSelectRowBlock:^(int index) {
            [self switchToNextRound];
            //[self checkNeedLoadMore];
        }];
        content.roundIndex = startRoundIndex + i;
        content.tag = 300 + content.roundIndex;
        if(model.model_id.intValue == 1){
            [content.footerView setFooterArrowState:0];
        } else if(model.model_id.intValue == self.maxPublished+2){
            [content.footerView setFooterArrowState:2];
        } else {
            [content.footerView setFooterArrowState:1];
        }
        [self.scrollView addSubview:content];
        page++;
    }
    self.totalPageCount = page;

    self.scrollView.contentSize = CGSizeMake(w, page * pageHeight);
    self.lastPageIndex = -1;
    [self recalculateCurrentPage];
    self.minRound = self.rounds.firstObject.model_id.integerValue;
    self.maxRound = self.rounds.lastObject.model_id.integerValue;
}
- (void)setPageCover:(StoryLockCoverView *)cover model:(StorySectionModel *)model  {
    // 👆 向上滑 → 下一页
    /*cover.swipeUpBlock = ^{
         //[self switchToNextRound];
    };
    // 👇 向下滑 → 上一页
    cover.swipeDownBlock = ^{
        //[self switchToPreviousRound];
    };*/
 
    cover.subscribeHandler = ^{
        self.isCove = YES;
        [self.menuView_1 menuViewPause];
        //self.menuView_1.progressSlider.value = 0.0;
        if([[UserModel sharedInstance] isLogin]){//需判断登录
            //PaymentViewController *payVC = [PaymentViewController new];
            //payVC.hidesBottomBarWhenPushed = YES;
           //[self.navigationController pushViewController:payVC animated:YES];
        } else {
            [[LoginManager sharedManager] handleLoginExpiredWithCompletion:^{
                //有问题111vvvxxx self.menuView_1.progressSlider.value = 0.0;
                //NSString *is_lock = model.is_lock;  BOOL isLogin =[[UserModel sharedInstance] isLogin];
                //if(!IS_Member){
                    //is_lock = @"0";
                //}
                // 登录完成后的逻辑
                [KUSER_DEFAULT setBool:YES forKey:Story_Scroll_IsVC];
                self.menuView_1.audioControlView.alpha = 1 ;
                self.menuView_1.unfoldButton.alpha = 1 ;
                cover.hidden = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UserLoginSuccessNotification" object:nil];
        
                BOOL isLogin = [[UserModel sharedInstance] isLogin];
                NSString *title = @[@"Log in to continue reading",@"Unlock the complete Stories collection"][isLogin];
                NSString *str = @[@"Log In",@"Unlock Now"][isLogin];
                [cover.btnLogin setTitle:NSLocalizedString(str, @"") forState:UIControlStateNormal];
                cover.titleLabel.text = NSLocalizedString(title, @"");
                
            }];
        }
    };
}
- (void)recalculateCurrentPage {
    CGFloat pageHeight = self.scrollView.bounds.size.height;
    NSInteger pageIndex =
        floor(self.scrollView.contentOffset.y / pageHeight);
    self.lastPageIndex = pageIndex;
    //BOOL isCover = [self currentPageIsCover];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}
- (void)loadStoryDataArray:(BOOL)isCover isNewEpisode:(BOOL)isEpisode {
    NSString *targetId = [KUSER_DEFAULT objectForKey:Story_Scroll_Index];
    if (targetId.integerValue > 0) {
        NSInteger roundIndex = [self.chaptersArrays indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            // 安全检查
            if (![obj isKindOfClass:[NSDictionary class]]) return NO;
            id chapterId = obj[@"chapter_id"];
            if (!chapterId) return NO;
            // 转成字符串再比较，保证 NSNumber 也能比较
            NSString *chapterIdStr = [NSString stringWithFormat:@"%@", chapterId];
            return [chapterIdStr isEqualToString:targetId];
        }];
        
        StorySectionModel *model = self.rounds[roundIndex];
        BOOL hasCover = model.coverImageName.length > 0;
        if(!isCover){
            hasCover = NO;
        }
        if (roundIndex == NSNotFound || roundIndex >= self.rounds.count) {    // 找不到就回到第一页，避免异常 滚动到顶
            [self.scrollView setContentOffset:CGPointZero animated:NO];
            return;
        }
    
        //========
        BOOL isFirstEnterVC = [KUSER_DEFAULT boolForKey:Story_Scroll_IsVC];
        NSTimeInterval delay = isFirstEnterVC ? 1.5 : 0.05;
        delay = 0.05;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            self.allowAudioSwitch = YES; //有问题111
            [self jumpToRound:roundIndex preferCover:hasCover chapter_id:targetId];
        });
        //=========================================================================
        if ([self.menuView_1 menuViewIsPlaying] && isEpisode) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [self.menuView_1 menuViewPlay];
                    [AudioScrollManager shared].isAudioScrolling_2 = YES;
            });
        } else {
            NSLog(@"-----------------------没触发-------------------000---------");
        }
    //===========================================================================
    } else {
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
    }
}
- (void)updateCurrentRoundIndex:(NSInteger)roundIndex {
    if (roundIndex < 0 || roundIndex >= self.rounds.count) {
        return;
    }
    //BOOL isCover = [self currentPageIsCover];
    //NSDictionary *dicStory = self.chaptersArray[roundIndex];
    //StorySectionModel *model = self.rounds[roundIndex];
}
//===================================================================
//高亮随着音频的秒数跳动
- (void)scrollToCellAudioAtIndexCurrent:(NSInteger)index {//问题--123 点击定位
    NSInteger visibleIndex = self.currentRoundIndex;

    
    if (visibleIndex == self.currentAudioRoundIndex) {
        NSInteger row = [KUSER_DEFAULT integerForKey:Story_Scroll_Row];
        NSInteger nextPage = self.lastPageIndex + 1;
        //NSLog(@"-AAA--------------22-----------[%d]-[%ld]-[%d]",[self currentPageIsCover],row,(nextPage < self.totalPageCount));
        if([self currentPageIsCover] && row > 0 && (nextPage < self.totalPageCount)){
            [self scrollToPage:nextPage animated:YES];
            //NSLog(@"--------22----------");
        }
        [self.storyPageView scrollToCellAudioAtIndexCurrent:index];
    } else {
        [self scrollToCurrentAudioRoundIfNeeded];
        //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.storyPageView scrollToCellAudioAtIndexCurrent:index];
        //});
    }

} //313_AAA
//文本滚动核心代码  updateAudioAndContentForRoundIndex
- (void)scrollToCellAtIndex:(NSInteger)index {//定位中
    // 1️⃣ index 合法性检查
    //if (index < 0 || index >= self.chaptersArray.count) return;
    [self.storyPageView scrollToCellAtIndex:index];
}
- (void)smoothScrollToIndex11:(NSInteger)index {
    [self.storyPageView smoothScrollToIndex11:index];
}
- (void)scrollToCurrentAudioRoundIfNeeded {//问题--123 //self.currentAudioRoundIndex = roundIndex;
    //NSLog(@"------22------------[%ld]-----------音频所属回合----------------",self.currentAudioRoundIndex);
    if (self.currentAudioRoundIndex < 0 || self.currentAudioRoundIndex >= self.rounds.count) return;
    NSInteger targetPageIndex = 0;
    // 1️⃣ 计算目标回合之前的总页数
    for (NSInteger i = 0; i < self.currentAudioRoundIndex; i++) {
           StorySectionModel *model = self.rounds[i];
           targetPageIndex += (model.coverImageName.length > 0) ? 2 : 1;
    }
    // 2️⃣ 如果目标回合有封面，并且你希望「音频播放时直接显示内容」
    StorySectionModel *currentModel = self.rounds[self.currentAudioRoundIndex];
    if (currentModel.coverImageName.length > 0) {
        targetPageIndex += 1;
    }
 
    // 3️⃣ 判断当前页面是否已经是目标页
     CGFloat pageHeight = self.scrollView.bounds.size.height;
     NSInteger currentPageIndex =
         (NSInteger)round(self.scrollView.contentOffset.y / pageHeight);
     if (currentPageIndex == targetPageIndex) {
         // 页面已经对齐，无需滚动
         self.currentRoundIndex = self.currentAudioRoundIndex;
         return;
     }
    self.currentRoundIndex = self.currentAudioRoundIndex;
    if([AudioScrollManager shared].isAudioScrolling_2){
        CGFloat targetOffsetY = pageHeight * targetPageIndex;
        [self.scrollView setContentOffset:CGPointMake(0, targetOffsetY) animated:YES];
    }
}
- (void)scrollToCurrentAudioRoundIfNeeded222 {
    if (self.currentAudioRoundIndex < 0 ||
        self.currentAudioRoundIndex >= self.rounds.count) return;
    // 1️⃣ 计算目标页
    NSInteger targetPageIndex = 0;
    for (NSInteger i = 0; i < self.currentAudioRoundIndex; i++) {
        StorySectionModel *model = self.rounds[i];
        targetPageIndex += (model.coverImageName.length > 0) ? 2 : 1;
    }

    StorySectionModel *currentModel = self.rounds[self.currentAudioRoundIndex];
    if (currentModel.coverImageName.length > 0) {
        targetPageIndex += 1; // 跳到内容页
    }
    CGFloat pageHeight = self.scrollView.bounds.size.height;
    CGFloat targetOffsetY = pageHeight * targetPageIndex;

    // 2️⃣ 当前页判断（不用 round）
    NSInteger currentPageIndex =
        (NSInteger)(self.scrollView.contentOffset.y / pageHeight);
    if (currentPageIndex == targetPageIndex) {
        self.currentRoundIndex = self.currentAudioRoundIndex;
        return;
    }
    // 3️⃣ 防止滚动中重复触发
    if ([AudioScrollManager shared].isAudioScrolling_2) {
        return;
    }
    [AudioScrollManager shared].isAudioScrolling_2 = YES;
    self.currentRoundIndex = self.currentAudioRoundIndex;
    [self.scrollView setContentOffset:CGPointMake(0, targetOffsetY) animated:YES];
}
//------------cx-xc-----------------------
- (void)storyMenuViewAutoSync:(BOOL)autoSync {
    [self.storyPageView storyMenuViewAutoSync:autoSync];
}
- (void)updatePlayPauseButton {
    NSString *imageName = [self.menuView_1 menuViewIsPlaying]
        ? @"pause_black"
        : @"play_black";
    [self.menuView_1.playPauseButton setImage:[UIImage imageNamed:imageName]
                                   forState:UIControlStateNormal];
}
- (void)switchAudioForRoundIndex:(NSInteger)roundIndex {
    if (roundIndex < 0 || roundIndex >= self.rounds.count) {
        return;
    }
    [self updatePlayPauseButton];
    if (!self.allowAudioSwitch) {
          return;
    }
    StorySectionModel *model = self.rounds[roundIndex];
    if (!model) return;
    NSString *main_audio_url = model.main_audio_url;
    NSString *fallback_audio_url = model.fallback_audio_url;
    NSString *audio_url = [Language_key isEqualToString:@"En"] ? fallback_audio_url:main_audio_url;
    if (main_audio_url.length == 0 || fallback_audio_url.length == 0) return;
    // ✅ 核心：音频没变，就不切
    if ([audio_url isEqualToString:self.currentAudioUrl]) {
        return;
    }
    self.currentAudioUrl = audio_url;
    [self updateAudioAndContentForRoundIndex:roundIndex];
    [self updatePlayPauseButton];
}
- (void)updateAudioAndContentForRoundIndex:(NSInteger)roundIndex {
    // 1️⃣ 安全检查
    if (roundIndex < 0 || roundIndex >= self.rounds.count) return;
    // 2️⃣ 获取当前回合数据模型
    StorySectionModel *model = self.rounds[roundIndex];
    // 3️⃣ 更新全局音频回合标记
    self.currentAudioRoundIndex = roundIndex;
    self.currentAudioRoundId = model.model_id;
 
    [[AudioScrollManager shared] beginAudioScrollWithRound:roundIndex];
    [KUSER_DEFAULT setObject:model.model_id forKey:Story_Scroll_Index];
    // 4️⃣ 获取对应回合的 StoryPageView
    //=====================================
    StoryRoundPageView *tempView = [self.scrollView viewWithTag:300 + self.currentAudioRoundIndex];
    // 防止 tempView 为空
    if (tempView) {
        // 停止视频
        //if ([tempView respondsToSelector:@selector(playerViewVideo)] &&
            //[tempView.playerViewVideo respondsToSelector:@selector(stopVideo)]) {
            //[tempView.playerViewVideo stopVideo];
        //}
    }
    //=====================================
    //-------------------------------------
    self.storyPageView = [self.scrollView viewWithTag:300 + roundIndex];
    if (!self.storyPageView) return;
    // 5️⃣ 重置当前页索引（用于 tableView / menuView 内部状态）
    if (tempView == self.storyPageView) {
    } else {
        self.storyPageView.currentIndex_1 = -1;//===vvv333
    }
    // 6️⃣ 更新 menuView 的数据
    self.menuView_1.textArray = model.contents;                        // 文本内容
    self.menuView_1.dicStory = self.chaptersArrays[roundIndex];      // 章节信息
    self.menuView_1.audio_cn = model.main_audio_url;                // 中文音频
    self.menuView_1.audio_en = model.fallback_audio_url;           // 英文音频
    // 7️⃣ 设置主音频播放器
    [self.menuView_1 setMainAudioPlayer];
    // 8️⃣ 初始化播放位置 / UI 状态
    [self.menuView_1 setLocationInitialization];
    // 9️⃣ 关联 menuView 到 pageView
    self.storyPageView.menuView_1 = self.menuView_1;
    [self.storyPageView.tableView reloadData];
    // 🔟 更新背景颜色
    UIColor *bgColor = [self.view colorWithHexString:model.bg_color alpha:1];
    self.scrollView.backgroundColor = bgColor;
    self.view.backgroundColor = bgColor;
    // 11️⃣ 这里可以加实际播放逻辑，比如：
    // if (self.menuView.isPlaying) [self.menuView menuViewResume];

    /*NSString *is_lock = model.is_lock;
    if(!IS_Member){
        is_lock = @"0";
    }
    self.menuView_1.audioControlView.alpha = 1 - is_lock.boolValue;
    self.menuView_1.unfoldButton.alpha = 1 - is_lock.boolValue;
    if(is_lock){
        [self.menuView_1 menuViewPause];
    }*/
    
    //有问题111
}
//人为滚动
- (void)handleUserScrollEndRoundIndex:(NSInteger)roundIndex {
//    if (![self currentPageIsCover]){
//        StorySectionModel *model = self.rounds[roundIndex];
//        NSString *is_lock = model.is_lock;
//        if(!IS_Member){
//            is_lock = @"0";
//        }
//        if(is_lock){
//            [self.menuView_1 menuViewPause];
//        }
//    }

    BOOL isPlaying = [self.menuView_1 menuViewIsPlaying];
    if (isPlaying) {
        // 第三种情况：
        // 播放中 → 用户滚动 → 不切音频
        return;
    }
    // 第二种情况：
    // 未播放 / 暂停 → 用户滚动 → 切到当前回合音频
    self.allowAudioSwitch = YES;
    [self switchAudioForRoundIndex:roundIndex];
}
//切换    人为滚动
//1 切换回合后，如果当前播放中，就不切换音频      但如果用户点击段落 就切换 所有音频相关
//2 切换回合后，如果当前暂停中，就切换音频

//非人为滚动
//3 不切换回合 自动播放结束 自动跳到下个回合 自动继续播放
//BOOL isUserDragging;      //yes 人为滚动 no 系统滚动
//BOOL allowAudioSwitch;    //是否允许切音频
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isUserDragging = YES; // 用户手动滚动 → 允许切音频
    if ([self.menuView_1 menuViewIsPlaying]) {
        //[[AudioScrollManager shared] endAudioScroll];
    }
} //机：用户手指刚开始拖动 scrollView 的瞬间
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
    if (!decelerate && self.isUserDragging) {
        // 人为滚动结束（无惯性）
        NSInteger roundIndex = [self currentRoundIndex];
        [self handleUserScrollEndRoundIndex:roundIndex];
        self.isUserDragging = NO;
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self handleScrollViewDidStop:scrollView];
}
- (void)handleScrollViewDidStop:(UIScrollView *)scrollView {
    
    CGFloat pageHeight = scrollView.bounds.size.height;
    NSInteger pageIndex =
        (NSInteger)round(scrollView.contentOffset.y / pageHeight);
    // 1️⃣ pageIndex 合法（注意是 totalPageCount）
    if (pageIndex < 0 || pageIndex >= self.totalPageCount) return;

    // 2️⃣ 防止同一页重复处理（可选）
    //if (self.lastHandledRoundIndex == pageIndex) return;
    //self.lastHandledRoundIndex = pageIndex;
    // 3️⃣ ❌ 不再根据 pageIndex 设置 currentRoundIndex
    //    currentRoundIndex 已由别处维护（音频 / 跳转逻辑）

    NSInteger roundIndex = [self currentRoundIndex];
    if (roundIndex < 0 || roundIndex >= self.rounds.count) return;

    // 4️⃣ 执行一次性的回合 UI 同步逻辑
    StorySectionModel *model = self.rounds[roundIndex];
    self.currentRound = model.model_id.integerValue;
    [self.menuView_1 setMenuViewIndex:model.model_id];
}

//当前可视回合不属于音频回合 就传-1 不高亮
- (void)resetVisibleRoundIfAudioRoundChanged {
    
    // 1️⃣ 两个回合一致，不处理
    if (self.currentRoundIndex == self.currentAudioRoundIndex) return;
    if ([self.menuView_1 menuViewIsPlaying]) {
        [self.menuView_1 setLocationState:YES];
    }
    // 2️⃣ 当前可视回合合法
    NSInteger visibleIndex = self.currentRoundIndex;
    if (visibleIndex < 0 || visibleIndex >= self.rounds.count) return;
    // 3️⃣ 取当前可视回合的 view
    StoryRoundPageView *storyCurrentView =
        [self.scrollView viewWithTag:300 + visibleIndex];
    if (![storyCurrentView isKindOfClass:[StoryRoundPageView class]]) return;
    // 4️⃣ 重置状态（非常关键）
    if (visibleIndex != self.currentAudioRoundIndex) {
           storyCurrentView.currentIndex_1 = -1;    //===vvv333
       }
    // 5️⃣ 刷新 tableView
    UITableView *tableView = storyCurrentView.tableView;
    if (!tableView) return;
    // ⚠️ 如果正在滚动，避免 reloadData 抖动
    if (!tableView.isDragging && !tableView.isDecelerating) {
        [tableView reloadData];
    } else {
        // 延迟到滚动结束再刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            [tableView reloadData];
        });
    }
    [self updatePlayPauseButton];
}
- (void)adjustLastPageIndexForInsertAtIndex:(NSInteger)insertIndex count:(NSInteger)count {
    if (insertIndex <= self.lastPageIndex) {
        self.lastPageIndex += count;
    }
}
- (NSInteger)roundIndexForPageIndex:(NSInteger)pageIndex {
    NSInteger currentRound = 0;
    NSInteger pageCounter = 0;
    for (StorySectionModel *model in self.rounds) {
        NSInteger pagesInRound = model.coverImageName.length > 0 ? 2 : 1;
        if (pageIndex < pageCounter + pagesInRound) {
            return currentRound;
        }
        pageCounter += pagesInRound;
        currentRound++;
    }
    return MAX(self.rounds.count - 1, 0);
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageHeight = scrollView.bounds.size.height;
    if (pageHeight <= 0) return;
    NSInteger pageIndex =
        (NSInteger)floor(scrollView.contentOffset.y / pageHeight);
    if (pageIndex == self.lastPageIndex) return;
    self.lastPageIndex = pageIndex;
    
    //-------------------------------------------------------------
    NSInteger roundIndex = [self roundIndexForPageIndex:pageIndex];
    //NSInteger roundIndex = self.currentRoundIndex;//[self currentRound];
    if (roundIndex < 0 || roundIndex >= self.rounds.count) {
        return;
    }
    if (roundIndex != self.currentRoundIndex) {
        self.currentRoundIndex = roundIndex;
    }
    StorySectionModel *model = self.rounds[roundIndex];
    NSString *is_lock = model.is_lock;

    BOOL isLogin = [[UserModel sharedInstance] isLogin];
    //self.cover.hidden = isLogin || !is_lock.boolValue;

    if (!IS_Member || isLogin) {
        is_lock = @"0";
    }
    self.menuView_1.audioControlView.alpha = 1 - is_lock.boolValue;
    self.menuView_1.unfoldButton.alpha = 1 - is_lock.boolValue;

    if(is_lock.boolValue && !isLogin){
        [self.menuView_1 menuViewPause];
       
        //self.menuView_1.progressSlider.value = 0.0;
        //[self.menuView_1.playerAudio seekToTime:kCMTimeZero];
        //self.menuView_1.progressSlider.value = 0;
    }
    //---------------------------------------
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
//滚动结束
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //====================================
    // 先获取 pageView
    //====================================
    //如果
    NSInteger roundIndex = [self currentRoundIndex];
    self.currentRoundIndex = roundIndex;//123
    [self updateCurrentRoundIndex:roundIndex];
    StorySectionModel *model = self.rounds[roundIndex];
    if(self.maxPublished + 2 == self.currentRoundIndex)return;;
    if (self.isUserDragging) {
         // 人为滚动结束（有惯性）
         [self handleUserScrollEndRoundIndex:roundIndex];
     } else {
         // 系统滚动（自动播放 / 程序滚动）
         self.allowAudioSwitch = YES;
         [self switchAudioForRoundIndex:roundIndex];
    }
    self.isUserDragging = NO;
    self.currentRound = model.model_id.integerValue;
    [self resetVisibleRoundIfAudioRoundChanged];
    [self checkNeedLoadMore];
    [self handleScrollViewDidStop:scrollView];
    
    if (self.currentRoundIndex == self.currentAudioRoundIndex) return;
    if ([self.menuView_1 menuViewIsPlaying]) {
        [self.menuView_1 setLocationState:YES];
    }
}
#pragma mark - StoryRoundPageViewDelegate

- (BOOL)storyPageViewSwitchAudio:(StoryRoundPageView *)pageView
       didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger clickedRoundIndex = pageView.roundIndex;
    BOOL needSwitchAudio = NO;
    // 情况 1：发生过前插数据（一次性事件）
    if ([AudioScrollManager shared].hasPrependedData) {
        needSwitchAudio = YES;
    }
    // 情况 2：点击的回合不是当前音频回合
    else if (self.currentAudioRoundIndex != clickedRoundIndex) {
        needSwitchAudio = YES;
    }
    if (!needSwitchAudio) return NO;
    self.allowAudioSwitch = YES;
    [self switchAudioForRoundIndex:clickedRoundIndex];
    [self updateAudioAndContentForRoundIndex:clickedRoundIndex];
    return YES;
}
- (void)checkNeedLoadMore {
    //if (self.isLoading) return;
  
    BOOL didLoad = NO;
    if (self.currentRound == self.minRound) {
        didLoad = YES;
        [self needLoadPrev];// 👉 到最小回合
    } else if (self.currentRound == self.maxRound) {
        didLoad = NO;
        [self needLoadNext];// 👉 到最大回合
    }
    // ✅ 在“最终回合稳定”后再更新 footer
     if (!didLoad) {
         [self updateFooterForCurrentRound];
     }
}
- (void)updateFooterForCurrentRound {
    BOOL isLast;
    if (self.currentRoundIndex == self.maxPublished ) {
        isLast = YES;
    }
    //[content.footerView :model.model_id];
}
- (void)needLoadPrev {
    self.modeType = 0;
    self.isLoading = YES;
    self.storyId = self.rounds.firstObject.model_id;
    if(self.storyId.intValue == 1)return;
    [self loadStoryDataFromStoryId:self.storyId isNewEpisode:YES];
}
- (void)needLoadNext {
    self.modeType = 1;
    self.isLoading = YES; // 🚨 请求锁
    self.storyId = self.rounds.lastObject.model_id;
 
    self.hasMaxRound = NO;
    for (StorySectionModel *model in self.rounds) {
        if (model.chapter_no.integerValue == self.maxPublished) {
            self.hasMaxRound = YES;
            break;
        }
    }
    if (self.hasMaxRound) {
        // 已经有最大回合，不需要再加载
        return;
    }
    [self loadStoryDataFromStoryId:self.storyId isNewEpisode:YES];

}
@end

/*
 用户滚动结束，tableView 停止了--------roundIndex=[5]-------------------count=[9]-----
 *** Terminating app due to uncaught exception 'NSRangeException', reason: '*** -[__NSArrayI objectAtIndexedSubscript:]: index 5 beyond bounds [0 .. 3]'
 *** First throw call stack:
 
 */
