//
//  YTVFeedFullscreenViewController.m
//  YiTongProject
//

#import "YTVFeedFullscreenViewController.h"
#import "HeaderConfig.h"
#import <AVFoundation/AVFoundation.h>

static void *kYTVFullscreenItemStatusContext = &kYTVFullscreenItemStatusContext;
static void *kYTVFullscreenPlayerCurrentItemContext = &kYTVFullscreenPlayerCurrentItemContext;

@interface YTVFeedFullscreenViewController ()
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, weak) AVPlayerItem *observedItem;
@property (nonatomic, assign) BOOL ytv_observingPlayerCurrentItem;
@end

@implementation YTVFeedFullscreenViewController

- (void)dealloc {
    [self ytv_removePlayerCurrentItemObserverIfNeeded];
    [self ytv_removeItemObserverIfNeeded];
    [KUSER_DEFAULT setBool:NO forKey:@"isFullScreen"];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [KUSER_DEFAULT setBool:YES forKey:@"isFullScreen"];

    AVPlayer *plRef = self.player;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:plRef];
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];

    [self.view addSubview:self.closeButton];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(12);
        make.width.height.mas_equalTo(44);
    }];

    AVPlayer *pl = self.player;
    if (pl) {
        [pl addObserver:self
             forKeyPath:@"currentItem"
                options:NSKeyValueObservingOptionNew
                context:kYTVFullscreenPlayerCurrentItemContext];
        self.ytv_observingPlayerCurrentItem = YES;
    }
    [self ytv_syncObservedItem:self.player.currentItem];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.playerLayer.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /// Feed 进入全屏时未暂停 `AVPlayer` 时此处 `play` 多为 no-op；仅在未在播时补上，避免依赖列表页误暂停。
    AVPlayer *pl = self.player;
    if (pl && pl.rate < 0.01f && pl.rate > -0.01f) {
        [pl play];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed || self.isMovingFromParentViewController) {
        [KUSER_DEFAULT setBool:NO forKey:@"isFullScreen"];
    }
}

- (void)ytv_onCloseTap {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)ytv_syncObservedItem:(AVPlayerItem *)item {
    [self ytv_removeItemObserverIfNeeded];
    self.observedItem = item;
    if (!item) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        return;
    }
    [item addObserver:self
           forKeyPath:@"status"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:kYTVFullscreenItemStatusContext];
}

- (void)ytv_removeItemObserverIfNeeded {
    if (self.observedItem) {
        @try {
            [self.observedItem removeObserver:self forKeyPath:@"status" context:kYTVFullscreenItemStatusContext];
        } @catch (__unused NSException *e) {
        }
        self.observedItem = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context == kYTVFullscreenPlayerCurrentItemContext) {
        [self ytv_syncObservedItem:self.player.currentItem];
        return;
    }
    if (context != kYTVFullscreenItemStatusContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    AVPlayerItem *item = (AVPlayerItem *)object;
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        [self ytv_applyVideoGravityForItem:item];
    }
}

- (void)ytv_removePlayerCurrentItemObserverIfNeeded {
    if (!self.ytv_observingPlayerCurrentItem) {
        return;
    }
    AVPlayer *pl = self.player;
    if (pl) {
        @try {
            [pl removeObserver:self forKeyPath:@"currentItem" context:kYTVFullscreenPlayerCurrentItemContext];
        } @catch (__unused NSException *e) {
        }
    }
    self.ytv_observingPlayerCurrentItem = NO;
}

/// 竖版（高≥宽）：铺满屏幕；横版：按比例居中，上下留黑
- (void)ytv_applyVideoGravityForItem:(AVPlayerItem *)item {
    if (!item || item != self.player.currentItem) {
        return;
    }
    AVAsset *asset = item.asset;
    __weak typeof(self) weakSelf = self;
    [asset loadValuesAsynchronouslyForKeys:@[ @"tracks" ] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || item != self.player.currentItem) {
                return;
            }
            NSArray<AVAssetTrack *> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if (tracks.count == 0) {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                return;
            }
            AVAssetTrack *t = tracks.firstObject;
            CGSize sz = CGSizeApplyAffineTransform(t.naturalSize, t.preferredTransform);
            CGFloat vw = fabs(sz.width);
            CGFloat vh = fabs(sz.height);
            if (vw < 1.0 || vh < 1.0) {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                return;
            }
            if (vh >= vw) {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            } else {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            }
        });
    }];
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_closeButton setTitle:NSLocalizedString(@"YTV_fullscreen_close", @"") forState:UIControlStateNormal];
        _closeButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        [_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _closeButton.tintColor = [UIColor whiteColor];
        [_closeButton addTarget:self action:@selector(ytv_onCloseTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

@end
