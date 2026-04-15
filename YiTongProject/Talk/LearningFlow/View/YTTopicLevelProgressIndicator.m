//
//  YTTopicLevelProgressIndicator.m
//  YiTongProject
//

#import "YTTopicLevelProgressIndicator.h"
#import "YTDifficultyTheme.h"
#import "HeaderConfig.h"
#import <Masonry/Masonry.h>
#import <QuartzCore/QuartzCore.h>

static CGFloat const kYTTopicLevelIndicatorSize = 38.0;
static CGFloat const kYTTopicLevelRingLineWidth = 1.0;

@interface YTTopicLevelProgressIndicator ()

@property (nonatomic, strong, nullable) YTDifficultyTheme *theme;

@property (nonatomic, strong) UIView *arrowContainer;
@property (nonatomic, strong) UIImageView *arrowImageView;

@property (nonatomic, strong) UIView *ringContainer;
@property (nonatomic, strong) UIView *ringBackdropView;
@property (nonatomic, strong) CAShapeLayer *trackLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *percentLabel;

@property (nonatomic, strong) UIView *doneContainer;
@property (nonatomic, strong) UIImageView *doneCheckImageView;

@end

@implementation YTTopicLevelProgressIndicator

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.arrowContainer];
        [self addSubview:self.ringContainer];
        [self.ringContainer addSubview:self.ringBackdropView];
        [self.ringBackdropView.layer addSublayer:self.trackLayer];
        [self.ringBackdropView.layer addSublayer:self.progressLayer];
        [self.ringContainer addSubview:self.percentLabel];
        [self addSubview:self.doneContainer];
        [self.doneContainer addSubview:self.doneCheckImageView];

        [self.arrowContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [self.ringContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [self.ringBackdropView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.ringContainer);
        }];
        [self.percentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.ringContainer);
        }];
        [self.doneContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.height.mas_equalTo(kYTTopicLevelIndicatorSize);
        }];
        [self.doneCheckImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.doneContainer);
            make.width.height.mas_equalTo(18);
        }];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kYTTopicLevelIndicatorSize, kYTTopicLevelIndicatorSize);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self yt_updateRingPathsInBounds:self.ringBackdropView.bounds];
    // 首帧常在 viewWillAppear 里 configure，此时子视图 bounds 仍为 0，path 未生成；布局完成后再刷一次色，避免「进出页才正常」
    if (!self.ringContainer.hidden) {
        CGFloat w = CGRectGetWidth(self.ringBackdropView.bounds);
        if (w > 0.5) {
            [self yt_applyThemeColors];
        }
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) {
        [self setNeedsLayout];
    }
}

- (void)configureWithProgressRatio:(CGFloat)progressRatio theme:(YTDifficultyTheme *)theme {
    self.theme = theme;
    CGFloat r = progressRatio;
    if (isnan(r) || isinf(r)) r = 0;
    r = MAX(0.0, MIN(1.0, r));

    BOOL completed = (r >= 1.0 - 1e-5);
    BOOL notStarted = (r <= 1e-5);

    self.arrowContainer.hidden = !notStarted;
    self.ringContainer.hidden = notStarted || completed;
    self.ringBackdropView.hidden = self.ringContainer.hidden;
    self.percentLabel.hidden = self.ringContainer.hidden;
    self.trackLayer.hidden = self.ringContainer.hidden;
    self.progressLayer.hidden = self.ringContainer.hidden;
    self.doneContainer.hidden = !completed;

    if (!notStarted && !completed) {
        NSInteger pct = (NSInteger)llround(r * 100.0);
        self.percentLabel.text = [NSString stringWithFormat:@"%ld%%", (long)pct];
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.progressLayer.strokeEnd = r;
        [CATransaction commit];
    }

    [self yt_applyThemeColors];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    if (!self.ringContainer.hidden) {
        CGRect b = self.ringBackdropView.bounds;
        if (CGRectGetWidth(b) > 0.5 && CGRectGetHeight(b) > 0.5) {
            [self yt_updateRingPathsInBounds:b];
            [self yt_applyThemeColors];
        }
    }
}

- (void)yt_applyThemeColors {
    YTDifficultyTheme *t = self.theme;
    UIColor *primary = t.primaryColor ?: Main_COLOR;

    UIImage *customArrow = [UIImage imageNamed:@"talk_topic_level_not_started"];
    if (customArrow) {
        self.arrowImageView.image = customArrow;
        self.arrowImageView.tintColor = nil;
        self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg =
            [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightSemibold];
        UIImage *sys = [UIImage systemImageNamed:@"arrow.up.right" withConfiguration:cfg];
        self.arrowImageView.image = [sys imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.arrowImageView.tintColor = [theAppDelegate.window colorWithHexString:@"#63637D" alpha:1];
    } else {
        self.arrowImageView.image = nil;
    }

    UIColor *ringFill = [self yt_lightFillColorForPrimary:primary];
    self.ringBackdropView.backgroundColor = ringFill;
    self.trackLayer.strokeColor = [self yt_ringTrackColorForFill:ringFill primary:primary].CGColor;
    self.progressLayer.strokeColor = primary.CGColor;
    self.percentLabel.textColor = primary;

    self.doneContainer.backgroundColor = t.backgroundColor ?: [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    self.doneContainer.layer.borderColor = primary.CGColor;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg =
            [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold];
        UIImage *chk = [UIImage systemImageNamed:@"checkmark" withConfiguration:cfg];
        self.doneCheckImageView.image = [chk imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.doneCheckImageView.tintColor = primary;
    }
}

- (void)yt_updateRingPathsInBounds:(CGRect)b {
    if (CGRectGetWidth(b) <= 0 || CGRectGetHeight(b) <= 0) return;
    CGPoint c = CGPointMake(CGRectGetMidX(b), CGRectGetMidY(b));
    // 圆角+masksToBounds 裁成圆，路径半径需留出整根线宽，否则贴边描边（尤其进度弧）易被裁没
    CGFloat radius = MIN(CGRectGetWidth(b), CGRectGetHeight(b)) / 2.0 - kYTTopicLevelRingLineWidth;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:c
                                                          radius:radius
                                                      startAngle:(CGFloat)(-M_PI_2)
                                                        endAngle:(CGFloat)(-M_PI_2 + M_PI * 2)
                                                       clockwise:YES];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.trackLayer.path = path.CGPath;
    self.progressLayer.path = path.CGPath;
    self.trackLayer.frame = b;
    self.progressLayer.frame = b;
    [CATransaction commit];
}

/// 比主题主色更浅的圆形底（白底上叠一层低透明主色）
- (UIColor *)yt_lightFillColorForPrimary:(UIColor *)primary {
    if (!primary) return [[UIColor whiteColor] colorWithAlphaComponent:0.92];
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if ([primary getRed:&r green:&g blue:&b alpha:&a]) {
        CGFloat t = 0.14;
        return [UIColor colorWithRed:(1.0 - t) + t * r green:(1.0 - t) + t * g blue:(1.0 - t) + t * b alpha:1.0];
    }
    return [primary colorWithAlphaComponent:0.12];
}

/// 轨道：比圆底略深，同色相（在底色与主题色之间插值）
- (UIColor *)yt_ringTrackColorForFill:(UIColor *)fill primary:(UIColor *)primary {
    if (!fill) return primary ?: [UIColor grayColor];
    if (!primary) return fill;
    CGFloat fr = 0, fg = 0, fb = 0, fa = 0, pr = 0, pg = 0, pb = 0, pa = 0;
    if ([fill getRed:&fr green:&fg blue:&fb alpha:&fa] && [primary getRed:&pr green:&pg blue:&pb alpha:&pa]) {
        CGFloat k = 0.26;
        return [UIColor colorWithRed:fr * (1.0 - k) + pr * k
                               green:fg * (1.0 - k) + pg * k
                                blue:fb * (1.0 - k) + pb * k
                               alpha:1.0];
    }
    return primary;
}

#pragma mark - Lazy

- (UIView *)arrowContainer {
    if (!_arrowContainer) {
        _arrowContainer = [[UIView alloc] init];
        _arrowContainer.backgroundColor = [UIColor clearColor];
        [_arrowContainer addSubview:self.arrowImageView];
        [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_arrowContainer);
            make.width.height.mas_equalTo(kYTTopicLevelIndicatorSize);
        }];
    }
    return _arrowContainer;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] init];
        _arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _arrowImageView;
}

- (UIView *)ringContainer {
    if (!_ringContainer) {
        _ringContainer = [[UIView alloc] init];
        _ringContainer.backgroundColor = [UIColor clearColor];
        _ringContainer.userInteractionEnabled = NO;
    }
    return _ringContainer;
}

- (UIView *)ringBackdropView {
    if (!_ringBackdropView) {
        _ringBackdropView = [[UIView alloc] init];
        _ringBackdropView.userInteractionEnabled = NO;
        _ringBackdropView.layer.cornerRadius = kYTTopicLevelIndicatorSize / 2.0;
        _ringBackdropView.layer.masksToBounds = YES;
    }
    return _ringBackdropView;
}

- (CAShapeLayer *)trackLayer {
    if (!_trackLayer) {
        _trackLayer = [CAShapeLayer layer];
        _trackLayer.fillColor = [UIColor clearColor].CGColor;
        _trackLayer.lineWidth = kYTTopicLevelRingLineWidth;
    }
    return _trackLayer;
}

- (CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.lineWidth = kYTTopicLevelRingLineWidth;
        _progressLayer.lineCap = kCALineCapRound;
        _progressLayer.strokeStart = 0;
        _progressLayer.strokeEnd = 0;
    }
    return _progressLayer;
}

- (UILabel *)percentLabel {
    if (!_percentLabel) {
        _percentLabel = [[UILabel alloc] init];
        _percentLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:13] ?: [UIFont boldSystemFontOfSize:13];
        _percentLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _percentLabel;
}

- (UIView *)doneContainer {
    if (!_doneContainer) {
        _doneContainer = [[UIView alloc] init];
        _doneContainer.layer.cornerRadius = kYTTopicLevelIndicatorSize / 2.0;
        _doneContainer.layer.masksToBounds = YES;
        _doneContainer.layer.borderWidth = 1.0;
    }
    return _doneContainer;
}

- (UIImageView *)doneCheckImageView {
    if (!_doneCheckImageView) {
        _doneCheckImageView = [[UIImageView alloc] init];
        _doneCheckImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _doneCheckImageView;
}

@end
