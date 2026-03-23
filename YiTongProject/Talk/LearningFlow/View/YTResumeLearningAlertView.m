//
//  YTResumeLearningAlertView.m
//  YiTongProject
//

#import "YTResumeLearningAlertView.h"
#import "HeaderConfig.h"
#import <Masonry/Masonry.h>
#import <QuartzCore/QuartzCore.h>

static NSTimeInterval const kYTResumeAlertAnimationDuration = 0.25;
static CGFloat const kYTResumeAlertCardCornerRadius = 26.0;
static CGFloat const kYTResumeAlertCardWidthFactor = 0.82;
static CGFloat const kYTResumeRingLineWidth = 4.0;
static CGFloat const kYTResumeRingSize = 66.0;
static CGFloat const kYTResumeSolidButtonHeight = 44.0;

#pragma mark - Ring

@interface YTResumeLearningRingView : UIView <CAAnimationDelegate>

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL didScheduleRingIntro;
@property (nonatomic, strong) CAShapeLayer *trackLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *percentLabel;

@end

@implementation YTResumeLearningRingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self.layer addSublayer:self.trackLayer];
        [self.layer addSublayer:self.progressLayer];
        [self addSubview:self.percentLabel];
        [self.percentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    _progress = MAX(0.0, MIN(1.0, progress));
    self.didScheduleRingIntro = NO;
    [self.progressLayer removeAnimationForKey:@"strokeEnd"];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.progressLayer.strokeEnd = 0;
    [CATransaction commit];
    NSInteger pct = (NSInteger)llround(_progress * 100.0);
    self.percentLabel.text = [NSString stringWithFormat:@"%ld%%", (long)pct];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    CGPoint c = CGPointMake(w / 2.0, h / 2.0);
    CGFloat r = (MIN(w, h) - kYTResumeRingLineWidth) / 2.0;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:c
                                                          radius:r
                                                      startAngle:(CGFloat)(-M_PI_2)
                                                        endAngle:(CGFloat)(-M_PI_2 + M_PI * 2)
                                                       clockwise:YES];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.trackLayer.path = path.CGPath;
    self.progressLayer.path = path.CGPath;
    self.trackLayer.frame = self.bounds;
    self.progressLayer.frame = self.bounds;
    [CATransaction commit];
}

- (void)playProgressAppearAnimation {
    if (self.didScheduleRingIntro) return;
    self.didScheduleRingIntro = YES;

    CGFloat target = self.progress;
    [self.progressLayer removeAnimationForKey:@"strokeEnd"];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.progressLayer.strokeEnd = 0;
    [CATransaction commit];

    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    a.duration = 0.45;
    a.fromValue = @(0);
    a.toValue = @(target);
    a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    a.removedOnCompletion = YES;
    a.delegate = self;
    [self.progressLayer addAnimation:a forKey:@"strokeEnd"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    (void)anim;
    (void)flag;
    // 同步 model 时必须关隐式动画，否则会再跑一遍 strokeEnd 动画，看起来像「走了两遍」
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.progressLayer.strokeEnd = self.progress;
    [CATransaction commit];
}

- (CAShapeLayer *)trackLayer {
    if (!_trackLayer) {
        _trackLayer = [CAShapeLayer layer];
        _trackLayer.fillColor = [UIColor clearColor].CGColor;
        _trackLayer.strokeColor = [theAppDelegate.window colorWithHexString:@"#C5DDF5" alpha:1].CGColor;
        _trackLayer.lineWidth = kYTResumeRingLineWidth;
    }
    return _trackLayer;
}

- (CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.strokeColor = [theAppDelegate.window colorWithHexString:@"#4C9BEF" alpha:1].CGColor;
        _progressLayer.lineWidth = kYTResumeRingLineWidth;
        _progressLayer.lineCap = kCALineCapRound;
        _progressLayer.strokeStart = 0;
        _progressLayer.strokeEnd = 0;
    }
    return _progressLayer;
}

- (UILabel *)percentLabel {
    if (!_percentLabel) {
        _percentLabel = [[UILabel alloc] init];
        _percentLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18] ?: [UIFont boldSystemFontOfSize:18];
        _percentLabel.textColor = [theAppDelegate.window colorWithHexString:@"#000000" alpha:1];
        _percentLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _percentLabel;
}

@end

#pragma mark - Alert

@interface YTResumeLearningAlertView ()

@property (nonatomic, copy) dispatch_block_t onContinueBlock;
@property (nonatomic, copy) dispatch_block_t onRestartBlock;

@property (nonatomic, strong) UIView *backdropOverlay;
@property (nonatomic, strong) UIView *cardShadowContainer;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) CAGradientLayer *cardGradientLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) YTResumeLearningRingView *ringView;
@property (nonatomic, strong) UILabel *progressCaptionLabel;
@property (nonatomic, strong) UIButton *continueButton;
@property (nonatomic, strong) UIButton *restartButton;

@end

@implementation YTResumeLearningAlertView

+ (instancetype)showInView:(UIView *)parentView
               progressRatio:(CGFloat)progressRatio
                       title:(nullable NSString *)title
                  onContinue:(dispatch_block_t)onContinue
                   onRestart:(dispatch_block_t)onRestart
{
    if (!parentView || !onContinue || !onRestart) return nil;

    YTResumeLearningAlertView *alert = [[YTResumeLearningAlertView alloc] initWithFrame:CGRectZero];
    alert.onContinueBlock = onContinue;
    alert.onRestartBlock = onRestart;

    CGFloat p = progressRatio;
    if (isnan(p) || isinf(p)) p = 0;
    p = MAX(0.0, MIN(1.0, p));

    alert.titleLabel.text = title.length ? title : NSLocalizedString(@"提示", @"");
    [alert.continueButton setTitle:NSLocalizedString(@"继续学习", @"") forState:UIControlStateNormal];
    [alert.restartButton setTitle:NSLocalizedString(@"重新开始", @"") forState:UIControlStateNormal];
    alert.progressCaptionLabel.text = NSLocalizedString(@"当前学习进度", @"");
    alert.ringView.progress = p;

    [parentView addSubview:alert];
    [alert mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(parentView);
    }];
    [parentView layoutIfNeeded];
    [alert layoutIfNeeded];

    alert.backdropOverlay.alpha = 0;
    alert.cardShadowContainer.transform = CGAffineTransformMakeScale(0.94, 0.94);
    alert.cardShadowContainer.alpha = 0;

    [UIView animateWithDuration:kYTResumeAlertAnimationDuration
                          delay:0
         usingSpringWithDamping:0.88
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        alert.backdropOverlay.alpha = 1;
        alert.cardShadowContainer.alpha = 1;
        alert.cardShadowContainer.transform = CGAffineTransformIdentity;
    } completion:^(__unused BOOL finished) {
        [alert.ringView playProgressAppearAnimation];
    }];

    return alert;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self yt_buildHierarchy];
        [self yt_applyStyles];
    }
    return self;
}

- (void)yt_buildHierarchy {
    [self addSubview:self.backdropOverlay];
    [self addSubview:self.cardShadowContainer];
    [self.cardShadowContainer addSubview:self.cardView];

    [self.backdropOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self.cardShadowContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self);
        make.width.equalTo(self).multipliedBy(kYTResumeAlertCardWidthFactor);
    }];

    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardShadowContainer);
    }];

    [self.cardView addSubview:self.titleLabel];
    [self.cardView addSubview:self.ringView];
    [self.cardView addSubview:self.progressCaptionLabel];
    [self.cardView addSubview:self.continueButton];
    [self.cardView addSubview:self.restartButton];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(28);
        make.top.equalTo(self.cardView).offset(28);
        make.right.equalTo(self.cardView).offset(-28);
    }];

    [self.ringView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
        make.centerX.equalTo(self.cardView);
        make.width.height.mas_equalTo(kYTResumeRingSize);
    }];

    [self.progressCaptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.ringView.mas_bottom).offset(10);
        make.left.equalTo(self.cardView).offset(28);
        make.right.equalTo(self.cardView).offset(-28);
    }];

    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressCaptionLabel.mas_bottom).offset(22);
        make.left.equalTo(self.cardView).offset(28);
        make.right.equalTo(self.restartButton.mas_left).offset(-12);
        make.width.equalTo(self.restartButton);
        make.height.mas_equalTo(kYTResumeSolidButtonHeight);
    }];

    [self.restartButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.continueButton);
        make.right.equalTo(self.cardView).offset(-28);
        make.height.mas_equalTo(kYTResumeSolidButtonHeight);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect b = self.cardView.bounds;
    if (CGRectGetWidth(b) > 0 && CGRectGetHeight(b) > 0) {
        self.cardShadowContainer.layer.shadowPath =
            [UIBezierPath bezierPathWithRoundedRect:b cornerRadius:kYTResumeAlertCardCornerRadius].CGPath;
        self.cardGradientLayer.frame = b;
    }
}

- (void)yt_applyStyles {
    self.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:20] ?: [UIFont boldSystemFontOfSize:20];
    self.titleLabel.textColor = BLACK_COLOR_1F;

    self.progressCaptionLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont boldSystemFontOfSize:16];
    self.progressCaptionLabel.textColor = [theAppDelegate.window colorWithHexString:@"#1F1F39" alpha:1];
    self.progressCaptionLabel.textAlignment = NSTextAlignmentCenter;

    UIColor *btnBlue = [theAppDelegate.window colorWithHexString:@"#4C9BEF" alpha:1];
    UIFont *btnFont = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont boldSystemFontOfSize:16];
    CGFloat corner = kYTResumeSolidButtonHeight / 2.0;
    for (UIButton *btn in @[ self.continueButton, self.restartButton ]) {
        btn.backgroundColor = btnBlue;
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = btnFont;
        btn.layer.cornerRadius = corner;
        btn.layer.masksToBounds = YES;
    }
}

- (void)dismissAnimated:(BOOL)animated completion:(nullable void (^)(void))completion {
    __weak typeof(self) weakSelf = self;
    void (^animations)(void) = ^{
        weakSelf.backdropOverlay.alpha = 0;
        weakSelf.cardShadowContainer.alpha = 0;
        weakSelf.cardShadowContainer.transform = CGAffineTransformMakeScale(0.94, 0.94);
    };
    void (^done)(BOOL) = ^(BOOL finished) {
        [weakSelf removeFromSuperview];
        if (completion) completion();
    };
    if (animated) {
        [UIView animateWithDuration:kYTResumeAlertAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:animations
                         completion:done];
    } else {
        animations();
        done(YES);
    }
}

#pragma mark - Actions

- (void)onContinueTap {
    dispatch_block_t cont = self.onContinueBlock;
    [self dismissAnimated:YES completion:^{
        if (cont) cont();
    }];
}

- (void)onRestartTap {
    dispatch_block_t rest = self.onRestartBlock;
    [self dismissAnimated:YES completion:^{
        if (rest) rest();
    }];
}

#pragma mark - Lazy

- (UIView *)backdropOverlay {
    if (!_backdropOverlay) {
        _backdropOverlay = [[UIView alloc] init];
        _backdropOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        _backdropOverlay.userInteractionEnabled = YES;
    }
    return _backdropOverlay;
}

- (UIView *)cardShadowContainer {
    if (!_cardShadowContainer) {
        _cardShadowContainer = [[UIView alloc] init];
        _cardShadowContainer.backgroundColor = [UIColor clearColor];
        _cardShadowContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        _cardShadowContainer.layer.shadowOpacity = 0.12;
        _cardShadowContainer.layer.shadowRadius = 20;
        _cardShadowContainer.layer.shadowOffset = CGSizeMake(0, 10);
    }
    return _cardShadowContainer;
}

- (UIView *)cardView {
    if (!_cardView) {
        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor clearColor];
        _cardView.layer.cornerRadius = kYTResumeAlertCardCornerRadius;
        _cardView.layer.masksToBounds = YES;
        UIColor *top = [theAppDelegate.window colorWithHexString:@"#D0E6FF" alpha:1];
        UIColor *bottom = [UIColor whiteColor];
        self.cardGradientLayer.colors = @[(id)top.CGColor, (id)bottom.CGColor];
        self.cardGradientLayer.startPoint = CGPointMake(0.5, 0);
        self.cardGradientLayer.endPoint = CGPointMake(0.5, 1);
        [_cardView.layer insertSublayer:self.cardGradientLayer atIndex:0];
    }
    return _cardView;
}

- (CAGradientLayer *)cardGradientLayer {
    if (!_cardGradientLayer) {
        _cardGradientLayer = [CAGradientLayer layer];
    }
    return _cardGradientLayer;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.numberOfLines = 1;
    }
    return _titleLabel;
}

- (YTResumeLearningRingView *)ringView {
    if (!_ringView) {
        _ringView = [[YTResumeLearningRingView alloc] initWithFrame:CGRectZero];
    }
    return _ringView;
}

- (UILabel *)progressCaptionLabel {
    if (!_progressCaptionLabel) {
        _progressCaptionLabel = [[UILabel alloc] init];
    }
    return _progressCaptionLabel;
}

- (UIButton *)continueButton {
    if (!_continueButton) {
        _continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_continueButton addTarget:self action:@selector(onContinueTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _continueButton;
}

- (UIButton *)restartButton {
    if (!_restartButton) {
        _restartButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_restartButton addTarget:self action:@selector(onRestartTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _restartButton;
}

@end
