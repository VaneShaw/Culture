//
//  YTAnswerResultBottomSheet.m
//  YiTongProject
//

#import "YTAnswerResultBottomSheet.h"
#import "HeaderConfig.h"
#import <Masonry/Masonry.h>

static NSTimeInterval const kYTAnswerResultBottomSheetAnimationDuration = 0.22;

@interface YTAnswerResultBottomSheet ()

@property (nonatomic, copy) dispatch_block_t onPrimary;

@property (nonatomic, strong) UIControl *dimmingView;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UIView *grabber;

@property (nonatomic, strong) UIView *statusIconContainer;
@property (nonatomic, strong) UILabel *statusIconLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UILabel *highlightLabel;
@property (nonatomic, strong) UIButton *primaryButton;

@property (nonatomic, assign) YTAnswerResultBottomSheetStyle style;
@property (nonatomic, strong, nullable) UIColor *customAccentColor;

@end

@implementation YTAnswerResultBottomSheet

+ (instancetype)showInView:(UIView *)view
                     style:(YTAnswerResultBottomSheetStyle)style
                     title:(NSString *)title
                   message:(nullable NSString *)message
                 highlight:(nullable NSAttributedString *)highlight
               buttonTitle:(NSString *)buttonTitle
                 onPrimary:(dispatch_block_t)onPrimary
{
    if (!view) return nil;
    YTAnswerResultBottomSheet *sheet = [[YTAnswerResultBottomSheet alloc] initWithStyle:style];
    sheet.onPrimary = onPrimary;
    [sheet applyTitle:title message:message highlight:highlight buttonTitle:buttonTitle];
    [sheet presentInView:view];
    return sheet;
}

+ (instancetype)showInView:(UIView *)view
                     style:(YTAnswerResultBottomSheetStyle)style
                accentColor:(nullable UIColor *)accentColor
                     title:(NSString *)title
                   message:(nullable NSString *)message
                 highlight:(nullable NSAttributedString *)highlight
               buttonTitle:(NSString *)buttonTitle
                 onPrimary:(dispatch_block_t)onPrimary
{
    if (!view) return nil;
    YTAnswerResultBottomSheet *sheet = [[YTAnswerResultBottomSheet alloc] initWithStyle:style];
    sheet.customAccentColor = accentColor;
    sheet.onPrimary = onPrimary;
    [sheet applyStyle];
    [sheet applyTitle:title message:message highlight:highlight buttonTitle:buttonTitle];
    [sheet presentInView:view];
    return sheet;
}

- (instancetype)initWithStyle:(YTAnswerResultBottomSheetStyle)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _style = style;
        self.backgroundColor = [UIColor clearColor];
        [self buildUI];
        [self applyStyle];
    }
    return self;
}

- (void)buildUI {
    [self addSubview:self.dimmingView];
    [self addSubview:self.sheetView];

    [self.dimmingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self.sheetView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        // 贴到屏幕最底部，覆盖 home indicator 区域，避免底部漏出内容
        make.bottom.equalTo(self);
    }];

    [self.sheetView addSubview:self.grabber];
    [self.grabber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sheetView).offset(8);
        make.centerX.equalTo(self.sheetView);
        make.width.mas_equalTo(44);
        make.height.mas_equalTo(5);
    }];

    [self.sheetView addSubview:self.statusIconContainer];
    [self.statusIconContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.grabber.mas_bottom).offset(14);
        make.left.equalTo(self.sheetView).offset(16);
        make.width.height.mas_equalTo(36);
    }];

    [self.statusIconContainer addSubview:self.statusIconLabel];
    [self.statusIconLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.statusIconContainer);
    }];

    [self.sheetView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.statusIconContainer.mas_right).offset(10);
        make.centerY.equalTo(self.statusIconContainer);
        make.right.equalTo(self.sheetView).offset(-16);
    }];

    [self.sheetView addSubview:self.messageLabel];
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sheetView).offset(16);
        make.right.equalTo(self.sheetView).offset(-16);
        make.top.equalTo(self.statusIconContainer.mas_bottom).offset(10);
    }];

    [self.sheetView addSubview:self.highlightLabel];
    [self.highlightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.messageLabel);
        make.top.equalTo(self.messageLabel.mas_bottom).offset(8);
    }];

    [self.sheetView addSubview:self.primaryButton];
    [self.primaryButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.sheetView).inset(16);
        make.top.equalTo(self.highlightLabel.mas_bottom).offset(14);
        make.height.mas_equalTo(52);
        // 按钮底部按 safeArea 处理，保证不被 home indicator 挡住
        make.bottom.equalTo(self.sheetView.mas_safeAreaLayoutGuideBottom).offset(-16);
    }];
}

- (void)applyStyle {
    UIColor *accent = [self accentColor];
    UIColor *tintBg = [self tintBackgroundColor];

    self.sheetView.backgroundColor = tintBg;
    self.statusIconContainer.backgroundColor = accent;
    self.primaryButton.backgroundColor = accent;

    self.statusIconLabel.text = (self.style == YTAnswerResultBottomSheetStyleCorrect) ? @"✓" : @"✕";
    if (self.style == YTAnswerResultBottomSheetStyleWrong) {
        // 错误态 UI 规格（按截图）
        // - 左上红 icon：28*28
        // - Wrong Answer：#F5585B 字号 22
        // - answer is：#F5585B 字号 16
        // - 正确答案：#F5585B 字号 22
        CGFloat iconSize = 28;
        [self.statusIconContainer mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(iconSize);
        }];
        self.statusIconContainer.layer.cornerRadius = iconSize / 2.0;
        self.statusIconLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont boldSystemFontOfSize:16];

        self.titleLabel.textColor = accent;
        self.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];

        self.messageLabel.textColor = accent;
        self.messageLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16] ?: [UIFont systemFontOfSize:16];

        self.highlightLabel.textColor = accent;
        self.highlightLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];

        self.primaryButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];
    } else {
        // 正确态 UI 规格（按截图）
        // - 左上绿 icon：28*28
        // - Correct Answer!：#079669 字号 22
        CGFloat iconSize = 28;
        [self.statusIconContainer mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(iconSize);
        }];
        self.statusIconContainer.layer.cornerRadius = iconSize / 2.0;
        self.statusIconLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont boldSystemFontOfSize:16];

        self.titleLabel.textColor = accent;
        self.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];

        self.messageLabel.textColor = [UIColor colorWithRed:0x63 / 255.0 green:0x63 / 255.0 blue:0x7D / 255.0 alpha:1.0];
        self.messageLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:13] ?: [UIFont systemFontOfSize:13];

        self.highlightLabel.textColor = accent;
        self.highlightLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont boldSystemFontOfSize:16];

        self.primaryButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];
    }
}

- (UIColor *)accentColor {
    if (self.style == YTAnswerResultBottomSheetStyleCorrect) {
        if (self.customAccentColor) return self.customAccentColor;
        return [theAppDelegate.window colorWithHexString:@"#079669" alpha:1];
    }
    return [theAppDelegate.window colorWithHexString:@"#F5585B" alpha:1];
}

- (UIColor *)tintBackgroundColor {
    if (self.style == YTAnswerResultBottomSheetStyleCorrect) {
        UIColor *accent = [self accentColor];
        // 正确态背景色：不使用透明度，使用“主题色在白底上 18% 混合”的不透明浅色
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if (![accent getRed:&r green:&g blue:&b alpha:&a]) {
            return [theAppDelegate.window colorWithHexString:@"#DFF7EE" alpha:1];
        }
        CGFloat t = 0.18;
        return [UIColor colorWithRed:(1 - t) + t * r
                               green:(1 - t) + t * g
                                blue:(1 - t) + t * b
                               alpha:1.0];
    }
    return [theAppDelegate.window colorWithHexString:@"#FFE3E3" alpha:1];
}

- (void)applyTitle:(NSString *)title
           message:(nullable NSString *)message
         highlight:(nullable NSAttributedString *)highlight
       buttonTitle:(NSString *)buttonTitle
{
    self.titleLabel.text = title ?: @"";

    BOOL hasMessage = (message.length > 0);
    self.messageLabel.text = hasMessage ? message : @"";
    self.messageLabel.hidden = !hasMessage;

    BOOL hasHighlight = (highlight.length > 0);
    self.highlightLabel.attributedText = hasHighlight ? highlight : [[NSAttributedString alloc] initWithString:@""];
    self.highlightLabel.hidden = !hasHighlight;

    [self.primaryButton setTitle:buttonTitle ?: @"" forState:UIControlStateNormal];

    // 当没有 message 时，让 highlight 紧贴标题区域；当没有 highlight 时，让按钮紧贴 message
    [self.messageLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sheetView).offset(16);
        make.right.equalTo(self.sheetView).offset(-16);
        make.top.equalTo(self.statusIconContainer.mas_bottom).offset(hasMessage ? 10 : 0);
        if (!hasMessage) {
            make.height.mas_equalTo(0);
        }
    }];

    [self.highlightLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.messageLabel);
        make.top.equalTo(self.messageLabel.mas_bottom).offset(hasHighlight ? 8 : 0);
        if (!hasHighlight) {
            make.height.mas_equalTo(0);
        }
    }];

    [self.primaryButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.sheetView).inset(16);
        make.top.equalTo(self.highlightLabel.mas_bottom).offset(14);
        make.height.mas_equalTo(52);
        make.bottom.equalTo(self.sheetView.mas_safeAreaLayoutGuideBottom).offset(-16);
    }];
}

- (void)presentInView:(UIView *)view {
    self.alpha = 1.0;
    [view addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(view);
    }];
    [self layoutIfNeeded];

    CGFloat h = CGRectGetHeight(self.sheetView.bounds);
    if (h <= 0) {
        // 兜底：给一个默认高度，避免初次布局时拿不到
        h = 220;
    }
    self.sheetView.transform = CGAffineTransformMakeTranslation(0, h + 40);
    self.dimmingView.alpha = 0;

    [UIView animateWithDuration:kYTAnswerResultBottomSheetAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.dimmingView.alpha = 1.0;
        self.sheetView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismiss {
    CGFloat h = CGRectGetHeight(self.sheetView.bounds);
    if (h <= 0) h = 220;
    [UIView animateWithDuration:kYTAnswerResultBottomSheetAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.dimmingView.alpha = 0;
        self.sheetView.transform = CGAffineTransformMakeTranslation(0, h + 40);
    } completion:^(__unused BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - Actions

- (void)onPrimaryTap {
    if (self.onPrimary) self.onPrimary();
    [self dismiss];
}

#pragma mark - Lazy

- (UIControl *)dimmingView {
    if (!_dimmingView) {
        _dimmingView = [[UIControl alloc] init];
        _dimmingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
        // 截图里没有“点空白关闭”的交互：这里仅拦截触摸，避免穿透到题目区
        _dimmingView.userInteractionEnabled = YES;
    }
    return _dimmingView;
}

- (UIView *)sheetView {
    if (!_sheetView) {
        _sheetView = [[UIView alloc] init];
        _sheetView.layer.cornerRadius = 24;
        _sheetView.layer.masksToBounds = YES;
    }
    return _sheetView;
}

- (UIView *)grabber {
    if (!_grabber) {
        _grabber = [[UIView alloc] init];
        _grabber.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.12];
        _grabber.layer.cornerRadius = 2.5;
        _grabber.layer.masksToBounds = YES;
    }
    return _grabber;
}

- (UIView *)statusIconContainer {
    if (!_statusIconContainer) {
        _statusIconContainer = [[UIView alloc] init];
        _statusIconContainer.layer.cornerRadius = 18;
        _statusIconContainer.layer.masksToBounds = YES;
    }
    return _statusIconContainer;
}

- (UILabel *)statusIconLabel {
    if (!_statusIconLabel) {
        _statusIconLabel = [[UILabel alloc] init];
        _statusIconLabel.textColor = [UIColor whiteColor];
        _statusIconLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _statusIconLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _statusIconLabel;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _titleLabel.numberOfLines = 1;
    }
    return _titleLabel;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
        _messageLabel.numberOfLines = 2;
    }
    return _messageLabel;
}

- (UILabel *)highlightLabel {
    if (!_highlightLabel) {
        _highlightLabel = [[UILabel alloc] init];
        _highlightLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        _highlightLabel.numberOfLines = 2;
    }
    return _highlightLabel;
}

- (UIButton *)primaryButton {
    if (!_primaryButton) {
        _primaryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _primaryButton.layer.cornerRadius = 18;
        _primaryButton.layer.masksToBounds = YES;
        _primaryButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        [_primaryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_primaryButton addTarget:self action:@selector(onPrimaryTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return _primaryButton;
}

@end

