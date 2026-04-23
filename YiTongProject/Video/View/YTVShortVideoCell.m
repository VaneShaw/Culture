//
//  YTVShortVideoCell.m
//  YiTongProject
//

#import "YTVShortVideoCell.h"
#import "YTVVideoFeedItem.h"
#import "YTVVideoRenderView.h"
#import "HeaderConfig.h"
#import "Masonry.h"
#import <AVFoundation/AVFoundation.h>

static NSString * const kYTVChromeSeeAllURLHost = @"see-all";

@interface YTVShortVideoCell () <UITextViewDelegate>
@property (nonatomic, strong, readwrite) YTVVideoRenderView *renderView;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIView *fullScreenTapView;
@property (nonatomic, strong) UIImageView *pausedPlayHintView;
@property (nonatomic, strong) UIView *playbackFailureOverlayView;
@property (nonatomic, strong) UILabel *playbackFailureLabel;
@property (nonatomic, strong) UIButton *playbackRetryButton;
@property (nonatomic, strong) UIView *swipeDimOverlayView;
@property (nonatomic, strong) UIStackView *chromeRightStack;
@property (nonatomic, strong) UIStackView *favoriteChromeStack;
@property (nonatomic, strong) UIButton *favoriteChromeButton;
@property (nonatomic, strong) UILabel *favoriteChromeCountLabel;
@property (nonatomic, strong) UIStackView *shareChromeStack;
@property (nonatomic, strong) UIButton *shareChromeButton;
@property (nonatomic, strong) UILabel *shareChromeCountLabel;
@property (nonatomic, strong) UIStackView *chromeLeftStack;
@property (nonatomic, strong) UILabel *chromeTitleLabel;
@property (nonatomic, strong) UITextView *chromeSummaryTextView;
@property (nonatomic, strong) NSLayoutConstraint *chromeSummaryHeightConstraint;
@property (nonatomic, assign) CGFloat ytv_chromeSummaryLastLayoutWidth;
@property (nonatomic, strong) UIButton *fullScreenChromeButton;
@property (nonatomic, assign) BOOL ytv_chromeConstraintsInstalled;
@property (nonatomic, assign) BOOL ytv_interactionChromeSuppressed;
@property (nonatomic, assign) BOOL ytv_interactionChromeEnabled;
@property (nonatomic, strong, nullable) YTVVideoFeedItem *ytv_boundChromeItem;
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
        [self.contentView addSubview:self.fullScreenTapView];
        [self.fullScreenTapView addSubview:self.pausedPlayHintView];
        [self.contentView addSubview:self.chromeLeftStack];
        [self.contentView addSubview:self.chromeRightStack];
        [self.contentView addSubview:self.fullScreenChromeButton];
        [self.contentView addSubview:self.swipeDimOverlayView];
        [self.contentView addSubview:self.playbackFailureOverlayView];
        [self.playbackFailureOverlayView addSubview:self.playbackFailureLabel];
        [self.playbackFailureOverlayView addSubview:self.playbackRetryButton];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ytv_onFullScreenTap:)];
        [self.fullScreenTapView addGestureRecognizer:tap];
        [self ytv_installChromeConstraintsIfNeeded];
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
    [self ytv_hideCoverAfterFirstFrameAnimated:NO];
    [self ytv_clearPlaybackFailureState];
    self.pausedPlayHintView.hidden = YES;
    self.ytv_onVideoAreaTap = nil;
    self.ytv_onPlaybackRetryTap = nil;
    self.ytv_onFavoriteChromeTap = nil;
    self.ytv_onShareChromeTap = nil;
    self.ytv_onFullScreenChromeTap = nil;
    self.ytv_onChromeSeeAllTap = nil;
    self.ytv_naturalVideoWidth = 0;
    self.ytv_naturalVideoHeight = 0;
    self.ytv_playbackFailureVisible = NO;
    self.ytv_interactionChromeSuppressed = NO;
    self.ytv_interactionChromeEnabled = NO;
    self.ytv_boundChromeItem = nil;
    [self ytv_setSwipeDimOpacity:0];
    self.chromeLeftStack.hidden = YES;
    self.chromeRightStack.hidden = YES;
    self.fullScreenChromeButton.hidden = YES;
}

- (void)ytv_installChromeConstraintsIfNeeded {
    if (self.ytv_chromeConstraintsInstalled) {
        return;
    }
    self.ytv_chromeConstraintsInstalled = YES;
    /// trailing/leading 不能与 mas_safeAreaLayoutGuideRight/Left（对应 right/left）混用，需同为 LTR 边或同为 leading/trailing。
    [self.chromeRightStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView.mas_safeAreaLayoutGuideRight).offset(-14);
        make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(-40);
    }];
    [self.chromeLeftStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_safeAreaLayoutGuideLeft).offset(14);
        make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(-40);
        make.right.equalTo(self.contentView.mas_safeAreaLayoutGuideRight).offset(-128);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.contentView.bounds);
    self.playbackFailureOverlayView.frame = self.contentView.bounds;
    self.swipeDimOverlayView.frame = self.contentView.bounds;
    CGRect videoFrame = [self ytv_videoContentFrameInContentBounds:self.contentView.bounds];
    self.fullScreenTapView.frame = CGRectIsEmpty(videoFrame) ? self.contentView.bounds : videoFrame;
    /// 抖音式全屏会把 `renderView` 临时挂到遮罩上，仍在 cell 上时不要改其 frame。
    if (self.renderView.superview == self.contentView) {
        self.renderView.frame = videoFrame;
        self.renderView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
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
    [self ytv_rebuildChromeSummaryIfWidthChanged];
    [self ytv_layoutFullScreenChromeButtonForVideoFrame:videoFrame];
}

/// 短视频 cell 只负责视频画面与互动层，不再显示封面图。
- (void)configureWithItem:(YTVVideoFeedItem *)item {
    [self.coverImageView sd_cancelCurrentImageLoad];
    self.coverImageView.image = nil;
    [self ytv_applyVideoLayoutFromFeedItem:item];
    [self ytv_hideCoverAfterFirstFrameAnimated:NO];
    [self ytv_clearPlaybackFailureState];
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

- (void)ytv_configureInteractionChromeWithItem:(YTVVideoFeedItem *)item chromeEnabled:(BOOL)chromeEnabled {
    self.ytv_interactionChromeEnabled = chromeEnabled;
    self.ytv_boundChromeItem = item;
    BOOL show = chromeEnabled && item != nil && !self.ytv_interactionChromeSuppressed;
    self.chromeLeftStack.hidden = !show;
    self.chromeRightStack.hidden = !show;
    self.fullScreenChromeButton.hidden = YES;
    if (!show) {
        return;
    }
    NSString *titleText = item.title.length ? item.title : NSLocalizedString(@"YTV_feed_demo_title", @"");
    self.chromeTitleLabel.text = titleText;
    self.ytv_chromeSummaryLastLayoutWidth = 0;
    [self ytv_rebuildChromeSummaryIfWidthChanged];
    [self ytv_applyFavoriteChromeForItem:item];
    [self ytv_applyShareChromeForItem:item];
    [self setNeedsLayout];
}

- (void)ytv_setSwipeDimOpacity:(CGFloat)opacity {
    if (opacity < 0) {
        opacity = 0;
    } else if (opacity > 1) {
        opacity = 1;
    }
    self.swipeDimOverlayView.alpha = opacity;
}

- (UIView *)ytv_shareChromePresentationAnchor {
    return self.shareChromeButton;
}

- (void)ytv_setInteractionChromeSuppressed:(BOOL)suppressed {
    self.ytv_interactionChromeSuppressed = suppressed;
    if (suppressed) {
        self.chromeLeftStack.hidden = YES;
        self.chromeRightStack.hidden = YES;
        self.fullScreenChromeButton.hidden = YES;
    } else {
        [self ytv_configureInteractionChromeWithItem:self.ytv_boundChromeItem chromeEnabled:self.ytv_interactionChromeEnabled];
    }
}

- (CGFloat)ytv_chromeLeftTextMaxWidth {
    CGFloat W = CGRectGetWidth(self.contentView.bounds);
    UIEdgeInsets sa = self.contentView.safeAreaInsets;
    if (W < 1) {
        return 0;
    }
    return MAX(0, W - sa.left - sa.right - 14.0 - 128.0);
}

- (void)ytv_rebuildChromeSummaryIfWidthChanged {
    if (self.chromeLeftStack.hidden) {
        return;
    }
    CGFloat w = [self ytv_chromeLeftTextMaxWidth];
    if (w < 1) {
        return;
    }
    if (fabs(w - self.ytv_chromeSummaryLastLayoutWidth) < 0.5 && self.chromeSummaryTextView.attributedText.length > 0) {
        return;
    }
    self.ytv_chromeSummaryLastLayoutWidth = w;
    NSAttributedString *attr = [self ytv_summaryAttributedFittingWidth:w item:self.ytv_boundChromeItem];
    self.chromeSummaryTextView.attributedText = attr;
    CGFloat h = [self ytv_boundingHeightForAttributedString:attr width:w];
    self.chromeSummaryHeightConstraint.constant = MAX(36, ceil(h));
}

- (CGFloat)ytv_boundingHeightForAttributedString:(NSAttributedString *)as width:(CGFloat)w {
    if (!as || w < 1) {
        return 0;
    }
    CGRect r = [as boundingRectWithSize:CGSizeMake(w, CGFLOAT_MAX)
                                  options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                  context:nil];
    return CGRectGetHeight(r);
}

- (NSAttributedString *)ytv_summaryAttributedFittingWidth:(CGFloat)maxW item:(YTVVideoFeedItem *)item {
    if (maxW < 1) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    NSString *full = item.summary.length ? item.summary : NSLocalizedString(@"YTV_feed_demo_summary_long", @"");
    NSString *seeAll = NSLocalizedString(@"YTV_feed_demo_see_all", @"");
    NSString *ellipsis = @"... ";
    UIFont *font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    if (!font) {
        font = [UIFont systemFontOfSize:14];
    }
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineBreakMode = NSLineBreakByWordWrapping;
    UIColor *bodyColor = [[UIColor whiteColor] colorWithAlphaComponent:0.78];
    NSDictionary *bodyAttrs = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : bodyColor, NSParagraphStyleAttributeName : para };
    NSURL *seeAllURL = [NSURL URLWithString:[NSString stringWithFormat:@"ytv-chrome://%@", kYTVChromeSeeAllURLHost]];
    NSDictionary *linkAttrs = @{
        NSFontAttributeName : font,
        NSForegroundColorAttributeName : [[UIColor whiteColor] colorWithAlphaComponent:0.95],
        NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
        NSLinkAttributeName : seeAllURL,
        NSParagraphStyleAttributeName : para,
    };
    CGFloat maxLinesH = ceil(font.lineHeight) * 2 + 3;

    NSInteger low = 0;
    NSInteger high = (NSInteger)full.length;
    while (low < high) {
        NSInteger mid = (low + high + 1) / 2;
        NSString *pre = [full substringToIndex:(NSUInteger)mid];
        NSMutableAttributedString *trial = [[NSMutableAttributedString alloc] initWithString:pre attributes:bodyAttrs];
        [trial appendAttributedString:[[NSAttributedString alloc] initWithString:ellipsis attributes:bodyAttrs]];
        [trial appendAttributedString:[[NSAttributedString alloc] initWithString:seeAll attributes:linkAttrs]];
        CGFloat th = [self ytv_boundingHeightForAttributedString:trial width:maxW];
        if (th <= maxLinesH) {
            low = mid;
        } else {
            high = mid - 1;
        }
    }

    NSString *pre = low > 0 ? [full substringToIndex:(NSUInteger)low] : @"";
    NSMutableAttributedString *out = [[NSMutableAttributedString alloc] initWithString:pre attributes:bodyAttrs];
    [out appendAttributedString:[[NSAttributedString alloc] initWithString:ellipsis attributes:bodyAttrs]];
    [out appendAttributedString:[[NSAttributedString alloc] initWithString:seeAll attributes:linkAttrs]];
    return [out copy];
}

- (void)ytv_applyFavoriteChromeForItem:(YTVVideoFeedItem *)item {
    BOOL favorited = item.isFavorite;
    UIColor *tint = favorited ? [UIColor colorWithRed:1.0 green:0.82 blue:0.2 alpha:1.0] : [UIColor whiteColor];
    self.favoriteChromeButton.tintColor = tint;
    self.favoriteChromeButton.accessibilityLabel = NSLocalizedString(favorited ? @"YTV_favorited" : @"YTV_favorite", @"");
    self.favoriteChromeCountLabel.hidden = NO;
    self.favoriteChromeCountLabel.text = [self ytv_stringForInteractionCountNonNegative:item ? item.favoritesCount : 0];
}

- (void)ytv_applyShareChromeForItem:(YTVVideoFeedItem *)item {
    self.shareChromeCountLabel.hidden = NO;
    self.shareChromeCountLabel.text = [self ytv_stringForInteractionCountNonNegative:item ? item.shareCount : 0];
}

- (NSString *)ytv_stringForInteractionCountNonNegative:(NSInteger)n {
    if (n < 0) {
        n = 0;
    }
    return [NSString stringWithFormat:@"%ld", (long)n];
}

- (void)ytv_layoutFullScreenChromeButtonForVideoFrame:(CGRect)videoFrame {
    if (self.chromeLeftStack.hidden || self.ytv_interactionChromeSuppressed || !self.ytv_boundChromeItem) {
        self.fullScreenChromeButton.hidden = YES;
        return;
    }
    YTVVideoFeedItem *item = self.ytv_boundChromeItem;
    BOOL can = NO;
    if (item.playURL.length > 0) {
        NSURL *pu = [NSURL URLWithString:item.playURL];
        if (!pu && [item.playURL hasPrefix:@"/"]) {
            pu = [NSURL fileURLWithPath:item.playURL];
        }
        NSString *ps = pu.scheme.lowercaseString;
        BOOL urlOk = pu != nil && ([ps isEqualToString:@"http"] || [ps isEqualToString:@"https"] || [ps isEqualToString:@"file"]);
        can = urlOk && item.ytv_hasNaturalVideoSize && [item ytv_isLandscapeNaturalVideo];
    }
    if (!can || CGRectIsEmpty(videoFrame)) {
        self.fullScreenChromeButton.hidden = YES;
        return;
    }
    static const CGFloat side = 40;
    CGFloat minY = CGRectGetMaxY(videoFrame) + 12.0;
    CGFloat maxY = CGRectGetHeight(self.contentView.bounds) - self.contentView.safeAreaInsets.bottom - side - 12.0;
    if (minY > maxY) {
        self.fullScreenChromeButton.hidden = YES;
        return;
    }
    CGFloat x = CGRectGetMidX(videoFrame) - side * 0.5;
    CGFloat y = MIN(minY, maxY);
    self.fullScreenChromeButton.frame = CGRectMake(x, y, side, side);
    [self.contentView bringSubviewToFront:self.fullScreenChromeButton];
    self.fullScreenChromeButton.hidden = NO;
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
    (void)hidden;
    (void)animated;
    self.coverImageView.hidden = YES;
    self.coverImageView.alpha = 0;
}

- (void)ytv_showCoverImmediately {
    [self ytv_setCoverHidden:YES animated:NO];
}

- (void)ytv_hideCoverAfterFirstFrameAnimated:(BOOL)animated {
    [self ytv_setCoverHidden:YES animated:animated];
}

- (void)ytv_showPlaybackFailureState {
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

- (void)ytv_onFavoriteChromeButtonTap {
    if (self.ytv_onFavoriteChromeTap) {
        self.ytv_onFavoriteChromeTap(self);
    }
}

- (void)ytv_onShareChromeButtonTap {
    if (self.ytv_onShareChromeTap) {
        self.ytv_onShareChromeTap(self);
    }
}

- (void)ytv_onFullScreenChromeButtonTap {
    if (self.ytv_onFullScreenChromeTap) {
        self.ytv_onFullScreenChromeTap(self);
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if (textView != self.chromeSummaryTextView) {
        return NO;
    }
    if ([URL.scheme isEqualToString:@"ytv-chrome"] && [URL.host isEqualToString:kYTVChromeSeeAllURLHost]) {
        if (self.ytv_onChromeSeeAllTap) {
            self.ytv_onChromeSeeAllTap(self);
        }
        return NO;
    }
    return NO;
}

#pragma mark - Lazy

- (UIView *)swipeDimOverlayView {
    if (!_swipeDimOverlayView) {
        _swipeDimOverlayView = [[UIView alloc] init];
        _swipeDimOverlayView.backgroundColor = [UIColor blackColor];
        _swipeDimOverlayView.userInteractionEnabled = NO;
        _swipeDimOverlayView.alpha = 0;
    }
    return _swipeDimOverlayView;
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
        _coverImageView.hidden = YES;
        _coverImageView.alpha = 0;
    }
    return _coverImageView;
}

- (UIStackView *)chromeRightStack {
    if (!_chromeRightStack) {
        _chromeRightStack = [[UIStackView alloc] initWithArrangedSubviews:@[
            self.favoriteChromeStack,
            self.shareChromeStack,
        ]];
        _chromeRightStack.axis = UILayoutConstraintAxisVertical;
        _chromeRightStack.spacing = 20;
        _chromeRightStack.alignment = UIStackViewAlignmentCenter;
        _chromeRightStack.hidden = YES;
    }
    return _chromeRightStack;
}

- (UIStackView *)favoriteChromeStack {
    if (!_favoriteChromeStack) {
        _favoriteChromeStack = [[UIStackView alloc] initWithArrangedSubviews:@[
            self.favoriteChromeButton,
            self.favoriteChromeCountLabel,
        ]];
        _favoriteChromeStack.axis = UILayoutConstraintAxisVertical;
        _favoriteChromeStack.spacing = 4;
        _favoriteChromeStack.alignment = UIStackViewAlignmentCenter;
    }
    return _favoriteChromeStack;
}

- (UILabel *)favoriteChromeCountLabel {
    if (!_favoriteChromeCountLabel) {
        _favoriteChromeCountLabel = [[UILabel alloc] init];
        _favoriteChromeCountLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _favoriteChromeCountLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        _favoriteChromeCountLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _favoriteChromeCountLabel;
}

- (UIButton *)favoriteChromeButton {
    if (!_favoriteChromeButton) {
        _favoriteChromeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        UIImage *ic = [UIImage imageNamed:@"video_home_collection"];
        if (ic) {
            ic = [ic imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_favoriteChromeButton setImage:ic forState:UIControlStateNormal];
        }
        _favoriteChromeButton.tintColor = [UIColor whiteColor];
        _favoriteChromeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_favoriteChromeButton addTarget:self action:@selector(ytv_onFavoriteChromeButtonTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _favoriteChromeButton;
}

- (UIButton *)shareChromeButton {
    if (!_shareChromeButton) {
        _shareChromeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        UIImage *ic = [UIImage imageNamed:@"video_home_share"];
        if (ic) {
            ic = [ic imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_shareChromeButton setImage:ic forState:UIControlStateNormal];
        }
        _shareChromeButton.tintColor = [UIColor whiteColor];
        _shareChromeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _shareChromeButton.accessibilityLabel = NSLocalizedString(@"YTV_share", @"");
        [_shareChromeButton addTarget:self action:@selector(ytv_onShareChromeButtonTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareChromeButton;
}

- (UIStackView *)shareChromeStack {
    if (!_shareChromeStack) {
        _shareChromeStack = [[UIStackView alloc] initWithArrangedSubviews:@[
            self.shareChromeButton,
            self.shareChromeCountLabel,
        ]];
        _shareChromeStack.axis = UILayoutConstraintAxisVertical;
        _shareChromeStack.spacing = 4;
        _shareChromeStack.alignment = UIStackViewAlignmentCenter;
    }
    return _shareChromeStack;
}

- (UILabel *)shareChromeCountLabel {
    if (!_shareChromeCountLabel) {
        _shareChromeCountLabel = [[UILabel alloc] init];
        _shareChromeCountLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _shareChromeCountLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        _shareChromeCountLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _shareChromeCountLabel;
}

- (UIButton *)fullScreenChromeButton {
    if (!_fullScreenChromeButton) {
        _fullScreenChromeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _fullScreenChromeButton.translatesAutoresizingMaskIntoConstraints = YES;
        _fullScreenChromeButton.tintColor = [UIColor whiteColor];
        UIImage *icon = [UIImage imageNamed:@"video_home_screen"];
        if (!icon) {
            icon = [UIImage imageNamed:@"frame_white"];
        }
        if (icon) {
            icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_fullScreenChromeButton setImage:icon forState:UIControlStateNormal];
            _fullScreenChromeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        _fullScreenChromeButton.accessibilityLabel = NSLocalizedString(@"YTV_fullscreen", @"");
        [_fullScreenChromeButton addTarget:self action:@selector(ytv_onFullScreenChromeButtonTap) forControlEvents:UIControlEventTouchUpInside];
        _fullScreenChromeButton.hidden = YES;
    }
    return _fullScreenChromeButton;
}

- (UILabel *)chromeTitleLabel {
    if (!_chromeTitleLabel) {
        _chromeTitleLabel = [[UILabel alloc] init];
        _chromeTitleLabel.textColor = [UIColor whiteColor];
        _chromeTitleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        _chromeTitleLabel.numberOfLines = 2;
        _chromeTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _chromeTitleLabel;
}

- (UITextView *)chromeSummaryTextView {
    if (!_chromeSummaryTextView) {
        _chromeSummaryTextView = [[UITextView alloc] init];
        _chromeSummaryTextView.translatesAutoresizingMaskIntoConstraints = NO;
        _chromeSummaryTextView.backgroundColor = [UIColor clearColor];
        _chromeSummaryTextView.scrollEnabled = NO;
        _chromeSummaryTextView.editable = NO;
        _chromeSummaryTextView.selectable = YES;
        _chromeSummaryTextView.delegate = self;
        _chromeSummaryTextView.textContainerInset = UIEdgeInsetsZero;
        _chromeSummaryTextView.textContainer.lineFragmentPadding = 0;
        _chromeSummaryTextView.linkTextAttributes = @{
            NSForegroundColorAttributeName : [[UIColor whiteColor] colorWithAlphaComponent:0.95],
            NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
        };
        _chromeSummaryHeightConstraint = [_chromeSummaryTextView.heightAnchor constraintEqualToConstant:1];
        _chromeSummaryHeightConstraint.active = YES;
    }
    return _chromeSummaryTextView;
}

- (UIStackView *)chromeLeftStack {
    if (!_chromeLeftStack) {
        _chromeLeftStack = [[UIStackView alloc] initWithArrangedSubviews:@[ self.chromeTitleLabel, self.chromeSummaryTextView ]];
        _chromeLeftStack.axis = UILayoutConstraintAxisVertical;
        _chromeLeftStack.spacing = 6;
        _chromeLeftStack.alignment = UIStackViewAlignmentFill;
        _chromeLeftStack.hidden = YES;
    }
    return _chromeLeftStack;
}

@end
