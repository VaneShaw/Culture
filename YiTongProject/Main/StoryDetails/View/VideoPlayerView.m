//
//  VideoPlayerView.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/11.
//

#import "VideoPlayerView.h"
@interface VideoPlayerView()<UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIScrollView *cachedOuterScrollView;
@property (nonatomic, strong) dispatch_block_t restoreScrollBlock;

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIButton *fullScreenBtn;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, assign) BOOL isUserDraggingSlider;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) AVPlayerItem *currentItem; // 保存当前播放的 item
@property (nonatomic, strong) UIView *placeholderView;

@property (nonatomic, assign) BOOL userDidTapPlay;
@end

@implementation VideoPlayerView
#pragma mark - 初始化
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

#pragma mark - UI布局
- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    
    self.overlayView = [[UIView alloc] initWithFrame:self.bounds];
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [self addSubview:self.overlayView];
    
    self.centerPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.centerPlayBtn.frame = CGRectMake(0, 0, 60, 60);
    self.centerPlayBtn.center = self.overlayView.center;
    self.centerPlayBtn.layer.cornerRadius = 30;
    [self.centerPlayBtn setImage:[UIImage imageNamed:@"play_white"] forState:UIControlStateNormal];
    //[self.centerPlayBtn addTarget:self action:@selector(playVideoAndStopAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.centerPlayBtn addTarget:self
                           action:@selector(playButtonTapped)
                 forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.centerPlayBtn];
 
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullScreenBtn.frame = CGRectMake(self.bounds.size.width - 30 - 5, self.bounds.size.height - 30 - 5, 30, 30);
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"frame_white"] forState:UIControlStateNormal];
    [self.fullScreenBtn addTarget:self action:@selector(enterFullScreen) forControlEvents:UIControlEventTouchUpInside];
    self.fullScreenBtn.hidden = YES;
    [self addSubview:self.fullScreenBtn];
    self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, self.bounds.size.height - 30, self.bounds.size.width - 20 - 20, 20)];
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"slider_black_2"] forState:UIControlStateNormal];
    self.progressSlider.minimumTrackTintColor = [self colorWithHexString:@"#1F1F39" alpha:1];//选中的颜色
    
    [self.progressSlider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.progressSlider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.progressSlider.hidden = YES;
    [self addSubview:self.progressSlider];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sliderPanGesture:)];
    [self.progressSlider addGestureRecognizer:pan];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    self.timeLabel.text = @"00:00/00:00";
    self.timeLabel.hidden = YES;
    [self addSubview:self.timeLabel];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayPause)];
    [self addGestureRecognizer:tap];
    
    // 加载指示器
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor whiteColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    self.loadingIndicator.center = self.center;
    self.loadingIndicator.alpha = 0.05;
    [self addSubview:self.loadingIndicator];
}
- (void)playButtonTapped {
    self.userDidTapPlay = YES; // 用户触发播放
    [[MediaPlayManager sharedManager] playVideoAndStopAudio:self];
}
#pragma mark - 播放/暂停
//- (void)playVideoAndStopAudio {  //视频播放的同时   关闭音频播放
    // 这里可调用外部通知或回调，关闭其他音频播放器
    //if (!self.player) return;
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"StopAudioPlayerNotification" object:nil];
    //[self startPlayVideo];
    
    // 这里预留调用关闭全局故事音频
    // [[AudioManager sharedManager] stopStoryAudio];
//}
- (void)playVideoAndStopAudio {
    if (!self.player) return;

    [self startPlayVideo];
    // UI 状态更新
    //self.centerPlayBtn.selected = YES;
    //[self.loadingIndicator stopAnimating];
}

#pragma mark - 设置视频
- (void)removeObserverFromItem:(AVPlayerItem *)item {
    if (!item) return;
    @try {
        [item removeObserver:self forKeyPath:@"status"];
        [item removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    } @catch (NSException *exception) {
        // 防止重复移除导致崩溃
    }
}
- (void)observePlayerItem:(AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setVideoURL:(NSURL *)url {
    self.playerLayer.player = nil;
    if (self.currentItem) {
        [self removeObserverFromItem:self.currentItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.currentItem];
    }

    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
     // 1. 保存强引用
    self.currentItem = item;
    // 2. 先绑定 KVO
    // 切换视频前显示遮罩
    //self.placeholderView.hidden = NO;
    [self observePlayerItem:item]; // 绑定 KVO
    if (!_player) {
    _player = [AVPlayer playerWithPlayerItem:item];
        // 🔥 新增这一行（非常关键） 改动了_1
        _player.automaticallyWaitsToMinimizeStalling = NO;
        [self.player addObserver:self
                         forKeyPath:@"timeControlStatus"
                            options:NSKeyValueObservingOptionNew
                            context:nil];

        if (!self.playerLayer) {
            self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
            self.playerLayer.frame = self.bounds;
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            [self.layer insertSublayer:self.playerLayer atIndex:0];
            self.playerLayer.backgroundColor = [UIColor clearColor].CGColor; // 防止残影
        } else {
            self.playerLayer.player = _player;
        }
    } else {
        [_player replaceCurrentItemWithPlayerItem:item];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidFinish) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    // 监听缓冲是否可播（与 observePlayerItem 中其它 KVO 分开写历史原因，避免重复注册）
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)clearPlayerLayer {
    // 1. 先断开 player（关键）
    self.playerLayer.player = nil;
    // 2. 可选：盖一层占位图 / loading
    [self showLoadingView];
}

- (void)startPlayVideo { //视频播放开始
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StopAudioPlayerNotification" object:nil];
    
    [self.player play];
    self.overlayView.hidden = YES;
    self.centerPlayBtn.hidden = YES;
    self.fullScreenBtn.hidden = NO;
    self.progressSlider.hidden = NO;
    self.timeLabel.hidden = NO;
    [self bringSubviewToFront:self.progressSlider];
    if (!self.timeObserver) {
        __weak typeof(self) weakSelf = self;
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            if (!weakSelf.isUserDraggingSlider) {
                float current = CMTimeGetSeconds(time);
                float total = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
                if (total > 0) {
                    weakSelf.progressSlider.value = current / total;
                }
                // 更新 timeLabel
                NSString *currentStr = [weakSelf formatTimeFromSeconds:current];
                NSString *totalStr = [weakSelf formatTimeFromSeconds:total];
                weakSelf.timeLabel.text = [NSString stringWithFormat:@"%@/%@", currentStr, totalStr];
            }
        }];
    }
    // 已准备好
    if (!self.player.currentItem.playbackLikelyToKeepUp) {
        // 缓冲不足，显示 loading
        [self showLoadingView];
        self.loadingIndicator.alpha = 0.8;
    } else {
        self.loadingIndicator.alpha = 1;
        // 缓冲充足，不显示 loading
        [self hideLoadingView];
    }   //改动了_2 替换成下面
    
    /*
    if (!self.player.currentItem.playbackLikelyToKeepUp) {
        [self showLoadingView];
        self.loadingIndicator.alpha = 1.0;
        __weak typeof(self) weakSelf = self;
        // 等待缓冲足够再开始播放
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakSelf.player.currentItem.playbackLikelyToKeepUp) {
                [weakSelf.player play];
                [weakSelf hideLoadingView];
            }
        });
    } else {
        [self.player play];
        [self hideLoadingView];
    }*/
}
- (void)togglePlayPause {//如果暂停就播放，
    if (self.player.rate == 0) {
        [self startPlayVideo];
    } else {
        [self pauseVideo];
    }
}
- (void)pauseVideo {//暂停
    [self hideLoadingView];
    [self.player pause];
    self.centerPlayBtn.hidden = NO;
    self.fullScreenBtn.hidden = YES;
    self.progressSlider.hidden = YES;
    self.timeLabel.hidden = YES;
    self.overlayView.hidden = NO;
    
    // ⚡️ 用户暂停，把标志重置
    self.userDidTapPlay = NO;
}
- (void)turnOffVideoPlayback {
    self.userDidTapPlay = NO;
    if (!self.player) return;
    // 停止播放
    [self.player pause];
    // 移除 timeObserver
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    // 移除 KVO 和通知
    if (self.currentItem) {
        @try {
            [self.currentItem removeObserver:self forKeyPath:@"status"];
            [self.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
            [self.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
            [self.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [self.player removeObserver:self forKeyPath:@"timeControlStatus"];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
        } @catch (NSException *exception) {}
        self.currentItem = nil;
    }
    // 释放 player
    self.playerLayer.player = nil;
    self.player = nil;
    self.centerPlayBtn.hidden = NO;
    self.fullScreenBtn.hidden = YES;
    self.progressSlider.hidden = YES;
    self.timeLabel.hidden = YES;
    self.overlayView.hidden = NO;//[self isVideoPlaying];
}
#pragma mark - 停止视频播放
- (void)stopVideo {//333v    // ⚡️ 用户点击播放状态重置
    self.userDidTapPlay = NO;
    if (!self.player) return;

    //if (!self.player) return;
    self.centerPlayBtn.hidden = NO;
    self.fullScreenBtn.hidden = YES;
    self.progressSlider.hidden = YES;
    self.timeLabel.hidden = YES;
    self.overlayView.hidden = NO;//[self isVideoPlaying];
}
- (BOOL)isVideoPlaying {
    // rate：播放速率，1.0 表示正常播放，0.0 表示暂停
    // error：是否有错误
    return (self.player && self.player.rate != 0 && self.player.error == nil);
}
#pragma mark - 播放完成
- (void)videoDidFinish {
    [self stopVideo];
    [self.player seekToTime:kCMTimeZero];
    self.progressSlider.value = 0;
    // ⚡️ 播放完成，重置用户点击播放标志
    self.userDidTapPlay = NO;
}
- (void)dealloc {
    if (self.timeObserver && self.player) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    AVPlayerItem *item = self.currentItem ?: self.player.currentItem;
    @try {
        if (item) {
            [item removeObserver:self forKeyPath:@"status"];
            [item removeObserver:self forKeyPath:@"loadedTimeRanges"];
            [item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
            [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        }
        if (self.player) {
            [self.player removeObserver:self forKeyPath:@"timeControlStatus"];
        }
    } @catch (NSException *exception) { }
}
#pragma mark - 全屏
- (void)enterFullScreen {
    if (self.enterFullScreenBlock) {
        self.enterFullScreenBlock(self.player);
    }
}
#pragma mark - 进度条操作
- (void)sliderTouchDown:(UISlider *)slider {
    self.isUserDraggingSlider = YES;
    UIScrollView *outerScroll = [self outerScrollView];
    outerScroll.scrollEnabled = NO;
    UITableView *tableView = [self parentTableView];
    tableView.scrollEnabled = NO;
    [self bringSubviewToFront:self.progressSlider];
}
#pragma mark - 进度条操作
- (void)sliderTouchUp:(UISlider *)slider {
     self.isUserDraggingSlider = NO;
     // 恢复滚动
     UIScrollView *outerScroll = [self outerScrollView];
     outerScroll.scrollEnabled = YES;
     UITableView *tableView = [self parentTableView];
     tableView.scrollEnabled = YES;
}
/*- (void)sliderValueChanged111:(UISlider *)slider {
    // 实时显示滑块预览时间（不立即 seek）
    float total = CMTimeGetSeconds(self.player.currentItem.duration);
    if (total > 0) {
        float preview = slider.value * total;
        NSString *previewStr = [self formatTimeFromSeconds:preview];
        NSString *totalStr = [self formatTimeFromSeconds:total];
        self.timeLabel.text = [NSString stringWithFormat:@"%@/%@", previewStr, totalStr];
    }
}*/
/*- (void)sliderValueChanged1112:(UISlider *)slider {
    NSLog(@"------22-----------slider-[%lf]----------------xxx-",slider.value);
    float total = CMTimeGetSeconds(self.player.currentItem.duration);
    if (total <= 0) return;
    Float64 target = slider.value * total;
    self.timeLabel.text = [NSString stringWithFormat:@"%@/%@",
                           [self formatTimeFromSeconds:target],
                           [self formatTimeFromSeconds:total]];
    // 判断方向
    float current = CMTimeGetSeconds(self.player.currentTime);
    CMTime tolerance = kCMTimeZero;
    if (target < current) {
        // 向左拖动 → 增大 tolerance，避免卡住
        tolerance = CMTimeMakeWithSeconds(1, NSEC_PER_SEC); // 允许 ±1秒的容差
    }
    [self.player seekToTime:CMTimeMakeWithSeconds(target, NSEC_PER_SEC)
            toleranceBefore:tolerance
             toleranceAfter:tolerance];
}*/
- (void)sliderPanGesture:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.progressSlider];
    CGFloat width = self.progressSlider.bounds.size.width;
    CGFloat deltaValue = translation.x / width;
    self.progressSlider.value = MIN(MAX(self.progressSlider.value + deltaValue, 0), 1);
    [pan setTranslation:CGPointZero inView:self.progressSlider];
    [self sliderValueChanged:self.progressSlider]; // 手动调用
}
- (void)sliderValueChanged:(UISlider *)slider {
 
    float total = CMTimeGetSeconds(self.player.currentItem.duration);
    if (total <= 0) return;
    Float64 target = slider.value * total;
      // 只更新时间 label，不 seek
    self.timeLabel.text = [NSString stringWithFormat:@"%@/%@",
                             [self formatTimeFromSeconds:target],
                             [self formatTimeFromSeconds:total]];
    [self.player seekToTime:CMTimeMakeWithSeconds(target, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    //   [self.player seekToTime:CMTimeMakeWithSeconds(target, NSEC_PER_SEC)]; //改动了_1
}
#pragma mark - Layout 更新
- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    self.overlayView.frame = self.bounds;
    self.centerPlayBtn.center = self.overlayView.center;
    self.fullScreenBtn.frame = CGRectMake(self.bounds.size.width - 30 - 5,self.bounds.size.height - 35, 30, 30);

    CGFloat padding = 10;
    CGFloat labelWidth = 80; // 给 timeLabel 留宽（你可以调整）
    CGFloat sliderHeight = 20;
    CGFloat sliderX = padding;
    CGFloat sliderY = self.bounds.size.height - sliderHeight - 1; // 底部间距8
    CGFloat sliderWidth = self.bounds.size.width - padding*2 - labelWidth - 4 - 30; // 留出 label 和小间距

      self.progressSlider.frame = CGRectMake(sliderX, sliderY, sliderWidth, sliderHeight);
      self.timeLabel.frame = CGRectMake(CGRectGetMaxX(self.progressSlider.frame) + 2, sliderY, labelWidth, sliderHeight);
    if(self.bounds.size.width < SCREEN_WIDTH-10){
        [self.progressSlider setThumbImage:[UIImage imageNamed:@"slider_blue"] forState:UIControlStateNormal];
        self.progressSlider.minimumTrackTintColor = [self colorWithHexString:@"#63A8F5" alpha:1];//选中的颜色
    }
    self.loadingIndicator.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}
- (NSString *)formatTimeFromSeconds:(NSTimeInterval)seconds {
    if (!isfinite(seconds) || seconds <= 0) return @"00:00";
    NSInteger sec = (NSInteger)round(seconds);
    NSInteger h = sec / 3600;
    NSInteger m = (sec % 3600) / 60;
    NSInteger s = sec % 60;
    if (h > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)h, (long)m, (long)s];
    } else {
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)m, (long)s];
    }
}


#pragma mark - Loading 控制
- (void)showLoadingView {
    [self.loadingIndicator startAnimating];
}
- (void)hideLoadingView {
    [self.loadingIndicator stopAnimating];
}
#pragma mark - 监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object; // ✅ 获取触发 KVO 的 item
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            //[self hideLoadingView];
        } else if (status == AVPlayerItemStatusFailed) {
            [self hideLoadingView];
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        [self showLoadingView]; // 缓冲空了，显示loading
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        // 缓冲充足，隐藏loading
        if (playerItem.playbackLikelyToKeepUp) {
            [self hideLoadingView];
            if (self.userDidTapPlay && !self.isVideoPlaying) {  // 如果之前暂停了，继续播放
                [self.player play];
                 //NSLog(@"⚡️ 缓冲充足，继续播放");
            }
        } else {
            [self showLoadingView];
        }
    } else if ([keyPath isEqualToString:@"timeControlStatus"]) {
        if (self.player.timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate) {
            // ❗真正因为缓冲暂停
            [self showLoadingView];
        } else if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
            [self hideLoadingView];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        NSArray *ranges = playerItem.loadedTimeRanges;
        if (ranges.count > 0) {

            CMTimeRange range = [ranges.firstObject CMTimeRangeValue];

            float bufferStart = CMTimeGetSeconds(range.start);
            float bufferDuration = CMTimeGetSeconds(range.duration);
            float bufferEnd = bufferStart + bufferDuration;

            float total = CMTimeGetSeconds(playerItem.duration);
            float current = CMTimeGetSeconds(self.player.currentTime);

            NSLog(@"------------------🎬 当前播放: [%.2f] / [%.2f]  |  已缓冲到: [%.2f]-------------------",current, total, bufferEnd);
            
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    // 让 slider 优先响应手势
    UIPanGestureRecognizer *sliderPan = nil;
    for (UIGestureRecognizer *gr in self.progressSlider.gestureRecognizers) {
        if ([gr isKindOfClass:[UIPanGestureRecognizer class]]) {
            sliderPan = (UIPanGestureRecognizer *)gr;
            break;
        }
    }
    UITableView *tableView = [self parentTableView];
    if (!sliderPan || !tableView) return;
    
    for (UIGestureRecognizer *gesture in tableView.gestureRecognizers) {
        // tableView 的滚动手势必须等待 slider 手势失败
        [gesture requireGestureRecognizerToFail:sliderPan];
    }
}
- (void)didMoveToSuperviewxxx {
    [super didMoveToSuperview];

    // ========= 1️⃣ slider 优先于 tableView（你原来的逻辑，保留） =========
    UIPanGestureRecognizer *sliderPan = nil;
    for (UIGestureRecognizer *gr in self.progressSlider.gestureRecognizers) {
        if ([gr isKindOfClass:[UIPanGestureRecognizer class]]) {
            sliderPan = (UIPanGestureRecognizer *)gr;
            break;
        }
    }

    UITableView *tableView = [self parentTableView];
    if (sliderPan && tableView) {
        for (UIGestureRecognizer *gesture in tableView.gestureRecognizers) {
            [gesture requireGestureRecognizerToFail:sliderPan];
        }
    }
    // ========= 2️⃣ 新增：视频区域 pan，用来控制外层翻页 =========
    self.cachedOuterScrollView = [self outerScrollView];
    UIPanGestureRecognizer *videoPan =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                 action:@selector(videoPan:)];
    videoPan.delegate = self;
    [self addGestureRecognizer:videoPan];
}
- (void)videoPan:(UIPanGestureRecognizer *)pan {
    if (!self.cachedOuterScrollView) return;

    if (pan.state == UIGestureRecognizerStateBegan) {
        self.cachedOuterScrollView.scrollEnabled = NO;
    }
    else if (pan.state == UIGestureRecognizerStateEnded ||
             pan.state == UIGestureRecognizerStateCancelled ||
             pan.state == UIGestureRecognizerStateFailed) {
        self.cachedOuterScrollView.scrollEnabled = YES;
    }
}
//----------------视频播放区域禁止UIScrollerView 左右滚动
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];

    if (hitView == self) {
        // 当触摸点在播放器上时，禁用父 scrollView 滚动
        UIScrollView *scrollView = [self outerScrollView];//[self parentScrollView];
        if (scrollView) {
            scrollView.scrollEnabled = NO;
            
            //=========================
            
            // ❌ 如果之前有延迟恢复 block，先取消
                        if (self.restoreScrollBlock) {
                            dispatch_block_cancel(self.restoreScrollBlock);
                        }

                        // ✅ 创建新的延迟恢复 block
                        __weak typeof(self) weakSelf = self;
                        dispatch_block_t block = dispatch_block_create(0, ^{
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            UIScrollView *sv = [strongSelf outerScrollView];
                            if (sv) {
                                sv.scrollEnabled = YES;
                            }
                            strongSelf.restoreScrollBlock = nil;
                        });

                        self.restoreScrollBlock = block;
                        // 延迟 3 秒执行
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
                 
            
            //=========================
        }
    }
    return hitView;
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    // 恢复 scrollView 滚动
    UIScrollView *scrollView = [self parentScrollView];
    if (scrollView) {
        scrollView.scrollEnabled = YES;
    }
}
- (UIScrollView *)outerScrollView {
    UIView *view = self.superview;
    while (view) {
        if ([view isKindOfClass:[UIScrollView class]] &&
            ![view isKindOfClass:[UITableView class]]) {
            return (UIScrollView *)view;
        }
        view = view.superview;
    }
    return nil;
}
- (UIScrollView *)parentScrollView {
    UIView *v = self.superview;
    while (v) {
        if ([v isKindOfClass:[UIScrollView class]]) {
            return (UIScrollView *)v;
        }
        v = v.superview;
    }
    return nil;
}
- (UITableView *)parentTableView {
    UIView *view = self.superview;
    while (view) {
        if ([view isKindOfClass:[UITableView class]]) {
            return (UITableView *)view;
        }
        view = view.superview;
    }
    return nil;
}
@end
