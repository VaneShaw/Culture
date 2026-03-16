//
//  StoryRoundPageView.m
//  YiTongProject
//
//  Created by ios01 on 2026/1/5.
//


#import "StoryRoundPageView.h"
#import "StoryRoundModel.h"
#import "StoryTextCell.h"
#import "StoryImageCell.h"
#import "StorySectionModel.h"
#import "AudioBarsView.h"

@interface StoryRoundPageView () <UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate>
@property (nonatomic, strong) AudioBarsView *animatedImage;
@property (nonatomic, strong) NSString *videoUrl;             //vc - 1个
@property (nonatomic, strong) NSIndexPath *selectedIndexPath; // 当前选中的段落 v

@property (nonatomic, strong) NSString *chapter_id;
@property (nonatomic, assign) NSInteger scrollCount;

@end
@implementation StoryRoundPageView

- (instancetype)initWithFrame:(CGRect)frame
                         model:(StorySectionModel *)model {
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        //[self createCoverView];
        self.currentIndex_1 = -1;
        self.dataArray = model.contents;
        self.chapter_id = model.model_id;

        self.select_Color = [self colorWithHexString:model.bright_color alpha:1];
        self.bg_ui_color = [self colorWithHexString:model.bg_color alpha:1];
        self.title_Color = [self colorWithHexString:model.font_color alpha:1];
        self.bg_bright_color = [self colorWithHexString:model.bright_bg_color alpha:0.1];
        self.videoUrl = model.video_url;
        
        self.animatedImage =  [[AudioBarsView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 42, 12, 15, 15)];
        [self setupTableView];
        [self setupHeaderVideoIfNeeded];     //底部播放栏 是否弹出 或隐藏
        [self.headerView loadTopImageWithURL:model.head_image hasVideo:model.video_url.length > 6];
        
        [self.animatedImage changeBarColor:self.select_Color];
        self.headerView.backgroundColor = self.bg_ui_color;
        self.tableView.backgroundColor = self.bg_ui_color;
        self.footerView.backgroundColor = self.bg_ui_color;
        [self.tableView reloadData];
        self.tableView.scrollEnabled = !model.is_lock.boolValue;
        
        self.cover = [[StoryLockCoverView alloc] init];
        self.cover.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.cover];
        // 四边贴父 view
        [NSLayoutConstraint activateConstraints:@[
            [self.cover.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.cover.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:30],
            [self.cover.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.cover.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
        ]];
        NSString *is_lock = model.is_lock;
        if(!IS_Member){
            is_lock = @"0";
        }
       
        BOOL isLogin =[[UserModel sharedInstance] isLogin];
        self.cover.hidden = isLogin || !is_lock.boolValue;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(handleLoginSuccess)
                                                          name:@"UserLoginSuccessNotification"
                                                        object:nil];
    }
    return self;
}
- (void)handleLoginSuccess {
    // 登录成功后，统一隐藏
    self.cover.hidden = YES;
}

- (void)setupHeaderVideoIfNeeded {//视频播放相关
    BOOL hasVideo = (self.videoUrl.length > 6);
    self.menuView_1.audioControlView.hidden = hasVideo;
    self.menuView_1.unfoldButton.hidden = 1 - hasVideo;
    self.playerViewVideo.hidden = 1 - hasVideo;
    //[self.playerViewVideo stopVideo];
    if(hasVideo){
         self.playerViewVideo = [self.headerView setupVideoIfVideoUrl:self.videoUrl];
         // 监听关闭音频的通知
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPauseAudio) name:@"StopAudioPlayerNotification" object:nil];
     }
}
- (void)playPauseAudio {//点击播放视频
    if (self.menuView_1.playerAudio.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
        //dispatch_async(dispatch_get_main_queue(), ^{
            [self.menuView_1 pauseAndCloseAudioControls];
        //});
        [self.menuView_1.playerAudio pause];
        [self.menuView_1.playPauseButton setImage:[UIImage imageNamed:@"play_black"] forState:UIControlStateNormal];
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self cancelRecording];
        //});
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self cancelRecording];
          });
    }
}
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
    //self.tableView.panGestureRecognizer.delegate = self;
    [self.tableView registerClass:[StoryTextCell class] forCellReuseIdentifier:@"StoryTextCell"];
    [self.tableView registerClass:[StoryImageCell class] forCellReuseIdentifier:@"StoryImageCell"];
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.footerView;
    [self addSubview:self.tableView];
    //[self loadStoryData:self.storyId];
}

#pragma mark - Table
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= self.dataArray.count) {
        return [[UITableViewCell alloc] init];
    }
    StorySectionModel *model = self.dataArray[indexPath.row];
    if (model.type == StorySectionTypeText) {
        StoryTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StoryTextCell" forIndexPath:indexPath];
        [cell setModel:model selected:(indexPath.row == self.currentIndex_1)];
        cell.selectedBgView.backgroundColor = self.bg_bright_color;
        cell.contentView.backgroundColor = self.bg_ui_color;
        if (indexPath.row == self.currentIndex_1) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger temp = self.currentIndex_1;
    //self.isAudioScrolling = YES;
    [[MediaPlayManager sharedManager] stopCurrentVideo];
    //[self.playerViewVideo stopVideo];
    [AudioScrollManager shared].isAudio_Playing = YES;
    [AudioScrollManager shared].isAudioScrolling_2 = YES;
    
    //======================================================
    BOOL didSwitchMainAudio = NO;
    if ([self.delegate respondsToSelector:@selector(storyPageViewSwitchAudio:didSelectRowAtIndexPath:)]) {
        didSwitchMainAudio = [self.delegate storyPageViewSwitchAudio:self didSelectRowAtIndexPath:indexPath];
    }
    
    BOOL isFirstEnterVC = [KUSER_DEFAULT boolForKey:Story_Scroll_IsVC];
    if (isFirstEnterVC) {
        didSwitchMainAudio = YES;
    }
    //上面那个执行完
    if (indexPath.row < 0 || indexPath.row >= self.dataArray.count) return;
    StorySectionModel *model = self.dataArray[indexPath.row];
    if (model.type != StorySectionTypeText) return;
    // 避免重复点击同一行
    //if ([indexPath isEqual:self.selectedIndexPath]) return;
    NSIndexPath *previousIndexPath = self.selectedIndexPath;
    self.selectedIndexPath = indexPath;
    self.currentIndex_1 = indexPath.row;
    self.menuView_1.lastIndex = self.currentIndex_1;
 
    //更新音频播放
    float start = [Language_key isEqualToString:@"En"] ? model.startTimeEN : model.startTimeCN;
    NSTimeInterval delay = didSwitchMainAudio ? 1.2 : 0;
    if (isFirstEnterVC) {
        [self cancelRecording];
    }
    
    //================================ //================================
    void (^seekAndUpdateUI)(void) = ^{
        [self.menuView_1 clickCellToTime:start];
        NSString *imageName = isFirstEnterVC ? @"play_black" : @"pause_black";
        if (isFirstEnterVC) { [self cancelRecording]; }
        [self.menuView_1.playPauseButton setImage:[UIImage imageNamed:imageName]
                                       forState:UIControlStateNormal];
    };
    if (didSwitchMainAudio) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            seekAndUpdateUI();
        });
    } else {
        seekAndUpdateUI();
    }
    //===============================//================================
    
    //===========================================
    if(temp < 0){
        [self.tableView reloadData];
    } else {                        // 只刷新旧选中行 + 当前选中行
        NSMutableArray *reloadArray = [NSMutableArray arrayWithObject:indexPath];
        if (previousIndexPath && ![previousIndexPath isEqual:indexPath]) {
            [reloadArray addObject:previousIndexPath];
        }
        [tableView reloadRowsAtIndexPaths:reloadArray withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadData];
    }
    [self playAudioAtIndexPath:indexPath isStart:YES];
    //self.isAudioScrolling = YES;
    [KUSER_DEFAULT setInteger:self.currentIndex_1 forKey:Story_Scroll_Row];
    //======================================================
}
//剩下一个问题，就说获取标题的时间，时间到就从封面跳转到内容
- (NSTimeInterval)coverTitleAudioStartTime{
    if (self.dataArray.count<2) return 0;
    // 根据语言选择封面标题音频起始时间
    StorySectionModel *model = self.dataArray[1];
    NSTimeInterval startTime = [Language_key isEqualToString:@"En"] ? model.startTimeEN : model.startTimeCN;
    startTime -= 0.5;
    // 避免负值或异常
    if (startTime < 0) startTime = 0;
    return startTime;
}
//============================================
#pragma mark - 滚动禁用自动联动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
   //if (self.isPlayAudio_current) {
    if ([self.menuView_1 menuViewIsPlaying]) {
        if ([AudioScrollManager shared].isAudioScrolling_2) { // yes 跟着cell 跟着 音频滚动
            [[AudioScrollManager shared] endAudioScroll];
            [self.menuView_1 setLocationState:YES]; //暂时定位图标
        }
        // TODO: 通知外部音频模块，关闭文字联动
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"用户滚动结束，tableView 停止了--------11--------------");
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex_1 inSection:0];
    [self playAudioAtIndexPath:indexPath isStart:NO];
}
//------------cx-xc-----------------------
- (void)scrollToCellAudioAtIndexCurrent:(NSInteger)index {
    if (index < 0 || index >= self.dataArray.count){
        if(index == -2){
            [self.tableView setContentOffset:CGPointMake(0, -self.tableView.adjustedContentInset.top) animated:NO];
        }
        //-1 只刷新 不滚动     -2刷新并滚动
        self.currentIndex_1 = index;
        self.menuView_1.lastIndex = self.currentIndex_1;
        [self.tableView reloadData];
        [self cancelRecording];
    } else {
        //-1 播放结束
        //index = - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        self.currentIndex_1 = index;
        self.menuView_1.lastIndex = self.currentIndex_1;
        [self.tableView reloadData];
        [self playAudioAtIndexPath:indexPath isStart:NO];//空
    }
    [KUSER_DEFAULT setInteger:self.currentIndex_1 forKey:Story_Scroll_Row];
} //313_AAA
//文本滚动核心代码
- (void)scrollToCellAtIndex:(NSInteger)index {
    if ([AudioScrollManager shared].isAudioScrolling_2) {
        if (index < 0 || index >= self.dataArray.count) return;
        if (index == self.currentIndex_1) return; // 避免重复滚动
            self.currentIndex_1 = index;
            self.menuView_1.lastIndex = self.currentIndex_1;
            [self.tableView reloadData];
            [self smoothScrollToIndex11:index];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self playAudioAtIndexPath:indexPath isStart:NO];
    } else {
        self.currentIndex_1 = index;
        self.menuView_1.lastIndex = self.currentIndex_1;
        [self.tableView reloadData];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self playAudioAtIndexPath:indexPath isStart:NO];//空
    }
    [KUSER_DEFAULT setInteger:self.currentIndex_1 forKey:Story_Scroll_Row];
}
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
- (void)storyMenuViewAutoSync:(BOOL)autoSync { //更新播放进度
    [AudioScrollManager shared].isAudioScrolling_2 = autoSync;//启动定位跟踪
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex_1 inSection:0];
    [self playAudioAtIndexPath:indexPath isStart:NO];
}
//===============================================================
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    /*self.scrollCount += 1;
     if (self.scrollCount >= 200) {
         self.scrollCount = 0; // 重置计数
         if([self.menuView_1 menuViewIsPlaying]){
             [self updatePlayPauseButton];
             //NSLog(@"---------用户滚动累计到150次，音频正在播放，可以执行逻辑------------------------------");
         }
     }*/
}
- (void)updatePlayPauseButton {
    NSString *imageName = [self.menuView_1 menuViewIsPlaying]
        ? @"pause_black"
        : @"play_black";
    [self.menuView_1.playPauseButton setImage:[UIImage imageNamed:imageName]
                                   forState:UIControlStateNormal];
}
//============================================
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
- (ReadHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[ReadHeaderView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 108)];//410
        //_headerView.uvc = self;
    }
    return _headerView;
}
- (ReadFooterView *)footerView {
    if (!_footerView) {
        //BOOL isValue = self.chapter_id.intValue == 1;
        _footerView = [[ReadFooterView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 251  )];//410
        [_footerView startArrowAnimation];
        [_footerView.nextButton addTarget:self action:@selector(btnNextButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        NSString *startReading = NSLocalizedString(@"NEXT CHAPTER COMING UP", @"");
        if(self.chapter_id.intValue == 1){
            startReading = NSLocalizedString(@"Start reading", @"");
        }
        [self.footerView.nextButton setTitle:startReading forState:UIControlStateNormal];
    }
    return _footerView;
}
- (void)btnNextButtonAction:(UIButton *)sender {
    if(self.didSelectRowBlock){
        self.didSelectRowBlock(1);
    }
    //Story_Scroll_Index
}
- (void)scrollTableViewToBottomIfNeeded {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollTableViewToRealBottom:self.tableView animated:YES];
    });
}
- (void)scrollTableViewToRealBottom:(UITableView *)tableView animated:(BOOL)animated {
    [tableView layoutIfNeeded];
    CGFloat maxOffsetY =
    tableView.contentSize.height
    - tableView.bounds.size.height
    + tableView.adjustedContentInset.bottom;
    if (maxOffsetY < 0) return;
    [tableView setContentOffset:CGPointMake(0, maxOffsetY) animated:animated];
}
- (void)playAudioAtIndexPath:(NSIndexPath *)indexPath1 isStart:(BOOL)isStart {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (self.currentIndex_1 < 0 || self.currentIndex_1 >= self.dataArray.count) return;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex_1 inSection:0];
    StoryTextCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (!cell || !cell.selectedBgView) return;
    // 移除按钮旧位置
    // 放到当前cell上
    self.animatedImage.frame = CGRectMake(SCREEN_WIDTH - 42, 12, 15, 15);
    [cell.selectedBgView addSubview:self.animatedImage];
    BOOL isPlaying = (self.menuView_1.playerAudio.rate != 0);
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


@end
