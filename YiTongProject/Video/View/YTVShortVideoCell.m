//
//  YTVShortVideoCell.m
//  YiTongProject
//

#import "YTVShortVideoCell.h"
#import "YTVVideoFeedItem.h"
#import "YTVVideoRenderView.h"
#import "HeaderConfig.h"
#import <AVFoundation/AVFoundation.h>

@interface YTVShortVideoCell ()
@property (nonatomic, strong, readwrite) YTVVideoRenderView *renderView;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *fullScreenTapView;
@property (nonatomic, strong) UIImageView *pausedPlayHintView;
@property (nonatomic, strong) UIView *playbackFailureOverlayView;
@property (nonatomic, strong) UILabel *playbackFailureLabel;
@property (nonatomic, strong) UIButton *playbackRetryButton;
/// 自 `YTVVideoFeedItem` 同步的自然像素尺寸；均为 0 表示尚未从接口或 AVAsset 探测到，布局退化为整页 `ResizeAspect`。
@property (nonatomic, assign) CGFloat ytv_naturalVideoWidth;
@property (nonatomic, assign) CGFloat ytv_naturalVideoHeight;
@property (nonatomic, assign) BOOL ytv_playbackFailureVisible;
@end

@implementation YTVShortVideoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:self.renderView];
        [self.contentView addSubview:self.coverImageView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.fullScreenTapView];
        [self.fullScreenTapView addSubview:self.pausedPlayHintView];
        [self.contentView addSubview:self.playbackFailureOverlayView];
        [self.playbackFailureOverlayView addSubview:self.playbackFailureLabel];
        [self.playbackFailureOverlayView addSubview:self.playbackRetryButton];
        self.titleLabel.userInteractionEnabled = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ytv_onFullScreenTap:)];
        [self.fullScreenTapView addGestureRecognizer:tap];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    /// 全屏时 `renderView` 可能挂在 Feed 遮罩上，不能在这里 `attachPlayer:nil`，否则会停播。
    if (self.renderView.superview == self.contentView) {
        [self.renderView attachPlayer:nil];
    }
    [self.coverImageView sd_cancelCurrentImageLoad];
    self.coverImageView.image = nil;
    [self ytv_showCoverImmediately];
    [self ytv_clearPlaybackFailureState];
    self.titleLabel.text = @"";
    self.pausedPlayHintView.hidden = YES;
    self.ytv_onVideoAreaTap = nil;
    self.ytv_onPlaybackRetryTap = nil;
    self.ytv_naturalVideoWidth = 0;
    self.ytv_naturalVideoHeight = 0;
    self.ytv_playbackFailureVisible = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.contentView.bounds);
    CGFloat h = CGRectGetHeight(self.contentView.bounds);
    self.fullScreenTapView.frame = self.contentView.bounds;
    self.playbackFailureOverlayView.frame = self.contentView.bounds;
    CGRect videoFrame = [self ytv_videoContentFrameInContentBounds:self.contentView.bounds];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    /// 抖音式全屏会把 `renderView` 临时挂到遮罩上，仍在 cell 上时不要改其 frame。
    if (self.renderView.superview == self.contentView) {
        self.renderView.frame = videoFrame;
        self.coverImageView.frame = videoFrame;
        self.renderView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    } else {
        self.coverImageView.frame = videoFrame;
    }
    CGFloat hintSide = MIN(88, MIN(CGRectGetWidth(self.fullScreenTapView.bounds), CGRectGetHeight(self.fullScreenTapView.bounds)) * 0.28);
    hintSide = MAX(hintSide, 56);
    self.pausedPlayHintView.bounds = CGRectMake(0, 0, hintSide, hintSide);
    self.pausedPlayHintView.center = CGPointMake(CGRectGetMidX(self.fullScreenTapView.bounds), CGRectGetMidY(self.fullScreenTapView.bounds));
    UIEdgeInsets sa = self.contentView.safeAreaInsets;
    CGFloat overlayWidth = MIN(MAX(w - 56.0, 220.0), 320.0);
    CGSize failureLabelSize = [self.playbackFailureLabel sizeThatFits:CGSizeMake(overlayWidth, CGFLOAT_MAX)];
    self.playbackFailureLabel.frame = CGRectMake((w - overlayWidth) * 0.5, MAX(CGRectGetMidY(self.contentView.bounds) - 34.0, sa.top + 60.0), overlayWidth, ceil(failureLabelSize.height));
    CGSize retrySize = [self.playbackRetryButton sizeThatFits:CGSizeMake(140.0, 44.0)];
    CGFloat retryWidth = MAX(110.0, ceil(retrySize.width) + 28.0);
    self.playbackRetryButton.frame = CGRectMake((w - retryWidth) * 0.5, CGRectGetMaxY(self.playbackFailureLabel.frame) + 14.0, retryWidth, 40.0);
    CGFloat titleH = 40.0;
    CGFloat titleY = h - sa.bottom - titleH - 10.0;
    titleY = MAX(0, titleY);
    self.titleLabel.frame = CGRectMake(16.0 + sa.left, titleY, w - 32.0 - sa.left - sa.right, titleH);
}

/// 短视频首显只读取已预取到缓存里的封面，不在 cell 露出瞬间再发起网络请求，避免拖慢滑动手势。
- (void)configureWithItem:(YTVVideoFeedItem *)item {
    if (!item) {
        self.titleLabel.text = @"";
        [self.coverImageView sd_cancelCurrentImageLoad];
        self.coverImageView.image = nil;
        [self ytv_showCoverImmediately];
        [self ytv_applyVideoLayoutFromFeedItem:nil];
        return;
    }
    [self ytv_applyVideoLayoutFromFeedItem:item];
    self.titleLabel.text = item.title.length ? item.title : @"";
    [self ytv_showCoverImmediately];
    [self ytv_clearPlaybackFailureState];
    [self.coverImageView sd_cancelCurrentImageLoad];
    self.coverImageView.image = nil;
    if (item.coverURL.length == 0) {
        return;
    }
    NSURL *coverURL = [NSURL URLWithString:item.coverURL];
    if (!coverURL) {
        return;
    }
    NSString *coverPathExtension = coverURL.pathExtension.lowercaseString;
    if ([coverPathExtension isEqualToString:@"gif"]) {
        return;
    }
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:coverURL];
    SDImageCache *cache = [SDImageCache sharedImageCache];
    UIImage *cachedImage = [cache imageFromMemoryCacheForKey:cacheKey];
    if (!cachedImage) {
        cachedImage = [cache imageFromDiskCacheForKey:cacheKey];
    }
    if (cachedImage) {
        self.coverImageView.image = cachedImage;
    }
}

- (void)ytv_applyVideoLayoutFromFeedItem:(YTVVideoFeedItem *)item {
    if (item && item.ytv_hasNaturalVideoSize && item.ytv_naturalVideoWidth > 0.5 && item.ytv_naturalVideoHeight > 0.5) {
        self.ytv_naturalVideoWidth = item.ytv_naturalVideoWidth;
        self.ytv_naturalVideoHeight = item.ytv_naturalVideoHeight;
    } else {
        self.ytv_naturalVideoWidth = 0;
        self.ytv_naturalVideoHeight = 0;
    }
    [self setNeedsLayout];
}

/// 宽度取满 contentView，高度为 `width * 自然高/宽` 并垂直居中；超高时在 cell 内上下裁切。无自然尺寸时为整页 bounds。
- (CGRect)ytv_videoContentFrameInContentBounds:(CGRect)contentBounds {
    CGFloat w = CGRectGetWidth(contentBounds);
    CGFloat h = CGRectGetHeight(contentBounds);
    if (w < 1.0 || h < 1.0) {
        return CGRectZero;
    }
    CGFloat nw = self.ytv_naturalVideoWidth;
    CGFloat nh = self.ytv_naturalVideoHeight;
    if (nw < 0.5 || nh < 0.5) {
        return contentBounds;
    }
    CGFloat videoH = w * (nh / nw);
    CGFloat y = (h - videoH) * 0.5;
    return CGRectMake(0, y, w, videoH);
}

- (CGRect)ytv_landscapeVideoContentFrameConvertedToView:(UIView *)view {
    if (!view) {
        return CGRectZero;
    }
    CGFloat nw = self.ytv_naturalVideoWidth;
    CGFloat nh = self.ytv_naturalVideoHeight;
    if (nw < 0.5 || nh < 0.5 || nw <= nh + 0.5) {
        return CGRectZero;
    }
    CGRect videoFrame = [self ytv_videoContentFrameInContentBounds:self.contentView.bounds];
    return [self.contentView convertRect:videoFrame toView:view];
}

- (void)ytv_setCoverHidden:(BOOL)hidden animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.18 animations:^{
            self.coverImageView.alpha = hidden ? 0 : 1;
        } completion:^(BOOL finished) {
            if (finished) {
                self.coverImageView.hidden = hidden;
                if (!hidden) {
                    self.coverImageView.alpha = 1;
                }
            }
        }];
    } else {
        self.coverImageView.hidden = hidden;
        self.coverImageView.alpha = hidden ? 0 : 1;
    }
}

- (void)ytv_showCoverImmediately {
    [self ytv_setCoverHidden:NO animated:NO];
}

- (void)ytv_hideCoverAfterFirstFrameAnimated:(BOOL)animated {
    [self ytv_setCoverHidden:YES animated:animated];
}

- (void)ytv_showPlaybackFailureState {
    [self ytv_showCoverImmediately];
    [self ytv_setPausedPlayHintVisible:NO];
    self.ytv_playbackFailureVisible = YES;
    self.playbackFailureOverlayView.hidden = NO;
    [self.contentView bringSubviewToFront:self.playbackFailureOverlayView];
}

- (void)ytv_clearPlaybackFailureState {
    self.ytv_playbackFailureVisible = NO;
    self.playbackFailureOverlayView.hidden = YES;
}

- (void)ytv_setPausedPlayHintVisible:(BOOL)visible {
    self.pausedPlayHintView.hidden = !visible;
    self.pausedPlayHintView.alpha = visible ? 1 : 0;
}


- (void)ytv_onPlaybackRetryButtonTap {
    if (self.ytv_onPlaybackRetryTap) {
        self.ytv_onPlaybackRetryTap(self);
    }
}

- (void)ytv_onFullScreenTap:(UITapGestureRecognizer *)gr {
    if (gr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if (self.ytv_onVideoAreaTap) {
        self.ytv_onVideoAreaTap(self);
    }
}


- (UIView *)fullScreenTapView {
    if (!_fullScreenTapView) {
        _fullScreenTapView = [[UIView alloc] init];
        _fullScreenTapView.backgroundColor = [UIColor clearColor];
        _fullScreenTapView.userInteractionEnabled = YES;
    }
    return _fullScreenTapView;
}



- (UIView *)playbackFailureOverlayView {
    if (!_playbackFailureOverlayView) {
        _playbackFailureOverlayView = [[UIView alloc] init];
        _playbackFailureOverlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.32];
        _playbackFailureOverlayView.hidden = YES;
    }
    return _playbackFailureOverlayView;
}

- (UILabel *)playbackFailureLabel {
    if (!_playbackFailureLabel) {
        _playbackFailureLabel = [[UILabel alloc] init];
        _playbackFailureLabel.textAlignment = NSTextAlignmentCenter;
        _playbackFailureLabel.numberOfLines = 0;
        _playbackFailureLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        _playbackFailureLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.95];
        _playbackFailureLabel.text = NSLocalizedString(@"YTV_playback_load_failed", @"");
    }
    return _playbackFailureLabel;
}

- (UIButton *)playbackRetryButton {
    if (!_playbackRetryButton) {
        _playbackRetryButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _playbackRetryButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
        _playbackRetryButton.layer.cornerRadius = 20.0;
        _playbackRetryButton.clipsToBounds = YES;
        _playbackRetryButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        [_playbackRetryButton setTitle:NSLocalizedString(@"YTV_feed_retry", @"") forState:UIControlStateNormal];
        [_playbackRetryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_playbackRetryButton addTarget:self action:@selector(ytv_onPlaybackRetryButtonTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playbackRetryButton;
}

- (UIImageView *)pausedPlayHintView {
    if (!_pausedPlayHintView) {
        _pausedPlayHintView = [[UIImageView alloc] init];
        _pausedPlayHintView.contentMode = UIViewContentModeScaleAspectFit;
        _pausedPlayHintView.userInteractionEnabled = NO;
        UIImage *img = nil;
        if (@available(iOS 13.0, *)) {
            img = [UIImage systemImageNamed:@"play.circle.fill"];
        }
        if (img == nil) {
            img = [UIImage imageNamed:@"play_black"];
        }
        _pausedPlayHintView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _pausedPlayHintView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        _pausedPlayHintView.hidden = YES;
    }
    return _pausedPlayHintView;
}

- (YTVVideoRenderView *)renderView {
    if (!_renderView) {
        _renderView = [[YTVVideoRenderView alloc] initWithFrame:CGRectZero];
    }
    return _renderView;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
        _coverImageView.backgroundColor = [UIColor blackColor];
    }
    return _coverImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

@end
