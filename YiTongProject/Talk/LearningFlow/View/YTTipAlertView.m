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
static CGFloat const kYTTipDualButtonHeight = 44.0;
static CGFloat const kYTTipAlertMinHeight = 220.0;
static CGFloat const kYTTipAlertMaxHeight = 500.0;

@interface YTTipAlertView ()

@property (nonatomic, copy, nullable) dispatch_block_t onCloseBlock;
@property (nonatomic, copy, nullable) dispatch_block_t onConfirmBlock;
@property (nonatomic, copy, nullable) dispatch_block_t onCancelBlock;

@property (nonatomic, assign) BOOL dualButtonMode;

@property (nonatomic, strong) UIView *backdropOverlay;
@property (nonatomic, strong) UIView *cardShadowContainer;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) CAGradientLayer *cardGradientLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UITextView *messageTextView;
@property (nonatomic, strong) YTDepthPrimaryButton *primaryDepthButton;
@property (nonatomic, strong) UIButton *confirmFlatButton;
@property (nonatomic, strong) UIButton *cancelFlatButton;

@end

@implementation YTTipAlertView

+ (instancetype)showInView:(UIView *)parentView
                  topTitle:(nullable NSString *)topTitle
               contentText:(NSString *)contentText
        primaryButtonTitle:(nullable NSString *)primaryButtonTitle
       secondaryButtonTitle:(nullable NSString *)secondaryButtonTitle
                    onClose:(nullable dispatch_block_t)onClose
                 onConfirm:(nullable dispatch_block_t)onConfirm
                  onCancel:(nullable dispatch_block_t)onCancel
{
    if (!parentView || !contentText.length) return nil;

    NSString *resolvedTopTitle =
        (topTitle.length > 0) ? topTitle : NSLocalizedString(@"Talk_Alert_DefaultTopTitle", @"提示");

    BOOL dual = (secondaryButtonTitle.length > 0);
    YTTipAlertView *alert = [[YTTipAlertView alloc] initWithFrame:CGRectZero];
    alert.dualButtonMode = dual;
    alert.onCloseBlock = onClose;
    alert.onConfirmBlock = onConfirm;
    alert.onCancelBlock = onCancel;

    alert.messageTextView.text = contentText;
    alert.titleLabel.hidden = NO;
    alert.titleLabel.text = resolvedTopTitle;

    if (dual) {
        [alert.confirmFlatButton setTitle:(primaryButtonTitle ?: @"") forState:UIControlStateNormal];
        [alert.cancelFlatButton setTitle:(secondaryButtonTitle ?: @"") forState:UIControlStateNormal];
        [alert yt_installDualButtonLayoutHasTitle:YES];
    } else {
        [alert.confirmFlatButton setTitle:(primaryButtonTitle ?: @"") forState:UIControlStateNormal];
        [alert yt_installSingleButtonLayout];
    }

    [parentView addSubview:alert];
    [alert mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(parentView);
    }];
    [alert layoutIfNeeded];

    // 文本很长时，弹窗卡片高度应逐步增加（上限到 500），超过上限后由 UITextView 内部滚动显示
    CGFloat parentW = parentView.bounds.size.width;
    CGFloat cardW = parentW * kYTTipAlertCardWidthFactor;
    CGFloat sideInset = dual ? 28.0 : 22.0;
    CGFloat messageW = MAX(1.0, cardW - sideInset * 2.0);

    UIFont *msgFont = alert.messageTextView.font ?: [UIFont systemFontOfSize:16];
    NSDictionary *msgAttrs = @{ NSFontAttributeName: msgFont };
    CGRect r =
        [contentText boundingRectWithSize:CGSizeMake(messageW, CGFLOAT_MAX)
                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                 attributes:msgAttrs
                                    context:nil];
    CGFloat textH = ceil(MAX(0.0, r.size.height));

    UIFont *titleFont = [UIFont fontWithName:FONT_NAME_Semibold size:18] ?: [UIFont boldSystemFontOfSize:18];
    CGFloat titleH = ceil(MAX(0.0, titleFont.lineHeight));

    CGFloat desiredH = 0;
    if (dual) {
        // dual: titleTop(28) + titleH + titleBottomGap(14) + textToButtonGap(24) + buttonH(44) + bottomGap(24)
        desiredH = 28.0 + titleH + 14.0 + 24.0 + kYTTipDualButtonHeight + 24.0 + textH;
    } else {
        // single：与双按钮同高扁平主按钮（无 Depth 叠层）
        desiredH = 22.0 + titleH + 14.0 + 24.0 + kYTTipDualButtonHeight + 24.0 + textH;
    }
    desiredH = MIN(kYTTipAlertMaxHeight, MAX(kYTTipAlertMinHeight, desiredH));

    [alert.cardShadowContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(@(desiredH));
    }];
    [alert layoutIfNeeded];
    alert.messageTextView.contentOffset = CGPointZero;

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

+ (instancetype)showInView:(UIView *)parentView
                     title:(nullable NSString *)title
                   message:(NSString *)message
               buttonTitle:(nullable NSString *)buttonTitle
                   onClose:(nullable dispatch_block_t)onClose
                 onConfirm:(nullable dispatch_block_t)onConfirm
{
    return [self showInView:parentView
                   topTitle:title
                contentText:message
         primaryButtonTitle:buttonTitle
        secondaryButtonTitle:nil
                    onClose:onClose
                 onConfirm:onConfirm
                  onCancel:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.dualButtonMode = NO;
        self.backgroundColor = [UIColor clearColor];
        [self yt_buildBaseHierarchy];
        [self yt_applyStyles];
    }
    return self;
}

- (void)yt_buildBaseHierarchy {
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
        // 初始给一个最小高度；显示时会再根据文本长度更新到期望高度（上限到 500）
        make.height.mas_equalTo(@(kYTTipAlertMinHeight));
    }];

    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardShadowContainer);
    }];

    [self.cardView addSubview:self.closeButton];
    [self.cardView addSubview:self.titleLabel];
    [self.cardView addSubview:self.messageTextView];
    [self.cardView addSubview:self.primaryDepthButton];
    [self.cardView addSubview:self.confirmFlatButton];
    [self.cardView addSubview:self.cancelFlatButton];

    self.confirmFlatButton.hidden = YES;
    self.cancelFlatButton.hidden = YES;

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

    // 默认先按「单按钮」布局：primaryDepthButton 约束会决定 messageTextView 的高度范围
    [self.messageTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(22);
        make.right.equalTo(self.cardView).offset(-22);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
    }];

    [self.primaryDepthButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(22);
        make.right.equalTo(self.cardView).offset(-22);
        make.top.equalTo(self.messageTextView.mas_bottom).offset(22);
        make.height.mas_equalTo(self.primaryDepthButton.totalHeight);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];

    [self.confirmFlatButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(0);
        make.width.mas_equalTo(0);
    }];

    [self.cancelFlatButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(0);
        make.width.mas_equalTo(0);
    }];
}

- (void)yt_installSingleButtonLayout {
    self.closeButton.hidden = NO;
    self.primaryDepthButton.hidden = YES;
    self.confirmFlatButton.hidden = NO;
    self.cancelFlatButton.hidden = YES;

    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(22);
        make.top.equalTo(self.cardView).offset(22);
        make.right.lessThanOrEqualTo(self.closeButton.mas_left).offset(-10);
    }];

    [self.messageTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(22);
        make.right.equalTo(self.cardView).offset(-22);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
        make.bottom.equalTo(self.confirmFlatButton.mas_top).offset(-24);
    }];

    [self.primaryDepthButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(0);
        make.left.equalTo(self.cardView).offset(22);
        make.right.equalTo(self.cardView).offset(-22);
        make.top.equalTo(self.cardView).offset(0);
    }];

    [self.confirmFlatButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(28);
        make.right.equalTo(self.cardView).offset(-28);
        make.height.mas_equalTo(kYTTipDualButtonHeight);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];

    [self.cancelFlatButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(0);
        make.width.mas_equalTo(0);
    }];

    self.messageTextView.textAlignment = NSTextAlignmentLeft;
}

- (void)yt_installDualButtonLayoutHasTitle:(BOOL)hasTitle {
    self.closeButton.hidden = YES;
    self.primaryDepthButton.hidden = YES;
    self.confirmFlatButton.hidden = NO;
    self.cancelFlatButton.hidden = NO;

    // 标题区域始终展示时，messageTextView 就由「确认按钮顶部 + 顶部间距」来决定可滚动高度
    if (hasTitle) {
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.cardView).offset(28);
            make.right.equalTo(self.cardView).offset(-28);
            make.top.equalTo(self.cardView).offset(28);
        }];
        [self.messageTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.cardView).offset(28);
            make.right.equalTo(self.cardView).offset(-28);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
            make.bottom.equalTo(self.confirmFlatButton.mas_top).offset(-24);
        }];
    } else {
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
            make.left.equalTo(self.cardView).offset(28);
            make.right.equalTo(self.cardView).offset(-28);
            make.top.equalTo(self.cardView).offset(0);
        }];
        [self.messageTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.cardView).offset(28);
            make.right.equalTo(self.cardView).offset(-28);
            make.top.equalTo(self.cardView).offset(28);
            make.bottom.equalTo(self.confirmFlatButton.mas_top).offset(-24);
        }];
    }

    [self.primaryDepthButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(0);
        make.left.equalTo(self.cardView).offset(22);
        make.right.equalTo(self.cardView).offset(-22);
        make.top.equalTo(self.cardView).offset(0);
    }];

    [self.confirmFlatButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(28);
        make.right.equalTo(self.cancelFlatButton.mas_left).offset(-12);
        make.width.equalTo(self.cancelFlatButton);
        make.height.mas_equalTo(kYTTipDualButtonHeight);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];

    [self.cancelFlatButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.cardView).offset(-28);
        make.height.mas_equalTo(kYTTipDualButtonHeight);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];

    self.messageTextView.textAlignment = NSTextAlignmentCenter;
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

    self.messageTextView.font = [UIFont fontWithName:FONT_NAME_Regular size:16] ?: [UIFont systemFontOfSize:16];
    self.messageTextView.textColor = [theAppDelegate.window colorWithHexString:@"#666666" alpha:1];

    UIColor *blue = [theAppDelegate.window colorWithHexString:@"#4A90E2" alpha:1];
    self.primaryDepthButton.depthColor = nil;
    self.primaryDepthButton.faceColor = blue;
    self.primaryDepthButton.actionButton.titleLabel.font =
        [UIFont fontWithName:FONT_NAME_Semibold size:17] ?: [UIFont boldSystemFontOfSize:17];

    UIColor *btnBlue = [theAppDelegate.window colorWithHexString:@"#4C9BEF" alpha:1];
    UIFont *btnFont = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont boldSystemFontOfSize:16];
    CGFloat corner = kYTTipDualButtonHeight / 2.0;

    self.confirmFlatButton.backgroundColor = btnBlue;
    [self.confirmFlatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmFlatButton.titleLabel.font = btnFont;
    self.confirmFlatButton.layer.cornerRadius = corner;
    self.confirmFlatButton.layer.masksToBounds = YES;

    self.cancelFlatButton.backgroundColor = [UIColor whiteColor];
    self.cancelFlatButton.layer.borderWidth = 1.0;
    self.cancelFlatButton.layer.borderColor = btnBlue.CGColor;
    [self.cancelFlatButton setTitleColor:btnBlue forState:UIControlStateNormal];
    self.cancelFlatButton.titleLabel.font = btnFont;
    self.cancelFlatButton.layer.cornerRadius = corner;
    self.cancelFlatButton.layer.masksToBounds = YES;
}

- (void)dismissAnimated:(BOOL)animated {
    [self dismissAnimated:animated completion:nil];
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
        [UIView animateWithDuration:kYTTipAlertAnimationDuration
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

- (void)onCloseTap {
    dispatch_block_t b = self.onCloseBlock;
    [self dismissAnimated:YES completion:^{
        if (b) b();
    }];
}

- (void)onConfirmTap {
    dispatch_block_t b = self.onConfirmBlock;
    [self dismissAnimated:YES completion:^{
        if (b) b();
    }];
}

- (void)onDualCancelTap {
    dispatch_block_t b = self.onCancelBlock;
    [self dismissAnimated:YES completion:^{
        if (b) b();
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

- (UITextView *)messageTextView {
    if (!_messageTextView) {
        _messageTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        _messageTextView.editable = NO;
        _messageTextView.selectable = NO;
        _messageTextView.scrollEnabled = YES;
        _messageTextView.bounces = NO;
        _messageTextView.backgroundColor = [UIColor clearColor];
        _messageTextView.textContainerInset = UIEdgeInsetsZero;
        _messageTextView.textContainer.lineFragmentPadding = 0;
        _messageTextView.contentInset = UIEdgeInsetsZero;
        _messageTextView.textAlignment = NSTextAlignmentCenter;
        _messageTextView.dataDetectorTypes = UIDataDetectorTypeNone;

        // 给 Auto Layout 更高的“可压缩性”，确保超长内容在 maxHeight=500 时会把高度压缩下来而不是撑爆弹窗
        [_messageTextView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [_messageTextView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                             forAxis:UILayoutConstraintAxisVertical];
    }
    return _messageTextView;
}

- (YTDepthPrimaryButton *)primaryDepthButton {
    if (!_primaryDepthButton) {
        _primaryDepthButton = [YTDepthPrimaryButton answerResultSheetPrimaryButton];
        [_primaryDepthButton.actionButton addTarget:self action:@selector(onConfirmTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _primaryDepthButton;
}

- (UIButton *)confirmFlatButton {
    if (!_confirmFlatButton) {
        _confirmFlatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_confirmFlatButton addTarget:self action:@selector(onConfirmTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmFlatButton;
}

- (UIButton *)cancelFlatButton {
    if (!_cancelFlatButton) {
        _cancelFlatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelFlatButton addTarget:self action:@selector(onDualCancelTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelFlatButton;
}

@end
