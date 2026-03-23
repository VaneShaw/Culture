//
//  YTTipAlertView.m
//  YiTongProject
//

#import "YTTipAlertView.h"
#import "YTDepthPrimaryButton.h"
#import "HeaderConfig.h"
#import <Masonry/Masonry.h>

static NSTimeInterval const kYTTipAlertAnimationDuration = 0.25;
static CGFloat const kYTTipAlertCardCornerRadius = 26.0;
static CGFloat const kYTTipAlertCardWidthFactor = 0.82;

@interface YTTipAlertView ()

@property (nonatomic, copy, nullable) dispatch_block_t onCloseBlock;
@property (nonatomic, copy, nullable) dispatch_block_t onConfirmBlock;

@property (nonatomic, strong) UIView *backdropOverlay;
@property (nonatomic, strong) UIView *cardShadowContainer;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) CAGradientLayer *cardGradientLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) YTDepthPrimaryButton *primaryDepthButton;

@end

@implementation YTTipAlertView

+ (instancetype)showInView:(UIView *)parentView
                     title:(nullable NSString *)title
                   message:(NSString *)message
               buttonTitle:(nullable NSString *)buttonTitle
                   onClose:(nullable dispatch_block_t)onClose
                 onConfirm:(nullable dispatch_block_t)onConfirm
{
    if (!parentView || !message.length) return nil;

    YTTipAlertView *alert = [[YTTipAlertView alloc] initWithFrame:CGRectZero];
    alert.onCloseBlock = onClose;
    alert.onConfirmBlock = onConfirm;

    NSString *t = title.length ? title : NSLocalizedString(@"提示", @"");
    NSString *btn = buttonTitle.length ? buttonTitle : NSLocalizedString(@"知道了", @"");

    alert.titleLabel.text = t;
    alert.messageLabel.text = message;
    [alert.primaryDepthButton.actionButton setTitle:btn forState:UIControlStateNormal];

    [parentView addSubview:alert];
    [alert mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(parentView);
    }];
    [alert layoutIfNeeded];

    alert.backdropOverlay.alpha = 0;
    alert.cardShadowContainer.transform = CGAffineTransformMakeScale(0.94, 0.94);
    alert.cardShadowContainer.alpha = 0;

    [UIView animateWithDuration:kYTTipAlertAnimationDuration
                          delay:0
         usingSpringWithDamping:0.88
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        alert.backdropOverlay.alpha = 1;
        alert.cardShadowContainer.alpha = 1;
        alert.cardShadowContainer.transform = CGAffineTransformIdentity;
    } completion:nil];

    return alert;
}

+ (instancetype)showInView:(UIView *)parentView message:(NSString *)message {
    return [self showInView:parentView title:nil message:message buttonTitle:nil onClose:nil onConfirm:nil];
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
        make.width.equalTo(self).multipliedBy(kYTTipAlertCardWidthFactor);
    }];

    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardShadowContainer);
    }];

    [self.cardView addSubview:self.closeButton];
    [self.cardView addSubview:self.titleLabel];
    [self.cardView addSubview:self.messageLabel];
    [self.cardView addSubview:self.primaryDepthButton];

    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(18);
        make.right.equalTo(self.cardView).offset(-18);
        make.width.height.mas_equalTo(28);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(22);
        make.top.equalTo(self.cardView).offset(22);
        make.right.lessThanOrEqualTo(self.closeButton.mas_left).offset(-10);
    }];

    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(22);
        make.right.equalTo(self.cardView).offset(-22);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
    }];

    [self.primaryDepthButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(22);
        make.right.equalTo(self.cardView).offset(-22);
        make.top.equalTo(self.messageLabel.mas_bottom).offset(22);
        make.height.mas_equalTo(self.primaryDepthButton.totalHeight);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect b = self.cardView.bounds;
    if (CGRectGetWidth(b) > 0 && CGRectGetHeight(b) > 0) {
        self.cardShadowContainer.layer.shadowPath =
            [UIBezierPath bezierPathWithRoundedRect:b cornerRadius:kYTTipAlertCardCornerRadius].CGPath;
        self.cardGradientLayer.frame = b;
    }
}

- (void)yt_applyStyles {
    self.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18] ?: [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textColor = BLACK_COLOR_1F;

    self.messageLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16] ?: [UIFont systemFontOfSize:16];
    self.messageLabel.textColor = [theAppDelegate.window colorWithHexString:@"#666666" alpha:1];

    UIColor *blue = [theAppDelegate.window colorWithHexString:@"#4A90E2" alpha:1];
    self.primaryDepthButton.depthColor = nil;
    self.primaryDepthButton.faceColor = blue;
    self.primaryDepthButton.actionButton.titleLabel.font =
        [UIFont fontWithName:FONT_NAME_Semibold size:17] ?: [UIFont boldSystemFontOfSize:17];
}

- (void)dismissAnimated:(BOOL)animated {
    __weak typeof(self) weakSelf = self;
    void (^animations)(void) = ^{
        weakSelf.backdropOverlay.alpha = 0;
        weakSelf.cardShadowContainer.alpha = 0;
        weakSelf.cardShadowContainer.transform = CGAffineTransformMakeScale(0.94, 0.94);
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        [weakSelf removeFromSuperview];
    };
    if (animated) {
        [UIView animateWithDuration:kYTTipAlertAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:animations
                         completion:completion];
    } else {
        animations();
        completion(YES);
    }
}

#pragma mark - Actions

- (void)onCloseTap {
    if (self.onCloseBlock) {
        self.onCloseBlock();
    }
    [self dismissAnimated:YES];
}

- (void)onConfirmTap {
    if (self.onConfirmBlock) {
        self.onConfirmBlock();
    }
    [self dismissAnimated:YES];
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
        _cardView.layer.cornerRadius = kYTTipAlertCardCornerRadius;
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

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _closeButton.tintColor = [theAppDelegate.window colorWithHexString:@"#8E9AAF" alpha:1];
        _closeButton.layer.cornerRadius = 14;
        _closeButton.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _closeButton.layer.borderColor = _closeButton.tintColor.CGColor;
        UIImage *x = nil;
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg =
                [UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightSemibold];
            x = [UIImage systemImageNamed:@"xmark" withConfiguration:cfg];
        }
        if (!x) {
            x = [UIImage systemImageNamed:@"xmark"];
        }
        [_closeButton setImage:x forState:UIControlStateNormal];
        _closeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _closeButton.contentEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6);
        [_closeButton addTarget:self action:@selector(onCloseTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.numberOfLines = 0;
    }
    return _messageLabel;
}

- (YTDepthPrimaryButton *)primaryDepthButton {
    if (!_primaryDepthButton) {
        _primaryDepthButton = [YTDepthPrimaryButton answerResultSheetPrimaryButton];
        [_primaryDepthButton.actionButton addTarget:self action:@selector(onConfirmTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _primaryDepthButton;
}

@end
