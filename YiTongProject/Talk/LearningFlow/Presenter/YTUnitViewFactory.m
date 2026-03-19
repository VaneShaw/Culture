//
//  YTUnitViewFactory.m
//  YiTongProject
//

#import "YTUnitViewFactory.h"
#import "HeaderConfig.h"

@implementation YTUnitPrimaryState
@end

@implementation YTUnitSubmitResult
@end

#pragma mark - Base View

/**
 Presenter 基类（非 UIViewController）
 
 设计取舍：
 - 这里用“对象 + rootView”的方式实现 Presenter，避免每个题型都做一套 VC 生命周期
 - 学习流容器只负责 mount/unmount `rootView`，Presenter 自己管理子视图与状态
 
 约定：
 - `primaryState` 是底部主按钮的“唯一真相”，通过 `emitPrimaryState` 回调给容器
 - `completeSignalSatisfied` 表示“该 unit 已达成完成条件”（是否计入进度由 `YTUnit` 决定）
 */
@interface YTBaseUnitView : NSObject <YTUnitViewProtocol>
@property (nonatomic, strong) UIView *rootView;
@property (nonatomic, strong) YTUnit *unit;
@property (nonatomic, strong) YTDifficultyTheme *theme;
@property (nonatomic, strong) YTAudioMuxService *audio;
@property (nonatomic, strong) YTRecordingService *recording;
@property (nonatomic, strong) YTScoringService *scoring;
@property (nonatomic, copy) YTUnitPrimaryStateChanged onPrimaryStateChanged;
@property (nonatomic, strong) YTUnitPrimaryState *primaryState;
@property (nonatomic, assign) BOOL completeSignalSatisfied;
@end

@implementation YTBaseUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        _rootView = [[UIView alloc] init];
        _rootView.backgroundColor = [UIColor clearColor];
        _primaryState = [[YTUnitPrimaryState alloc] init];
        _primaryState.kind = YTUnitPrimaryKindContinue;
        _primaryState.title = @"Talk_Continue";
        _primaryState.enabled = YES;
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit
                    theme:(YTDifficultyTheme *)theme
                    audio:(YTAudioMuxService *)audio
                recording:(YTRecordingService *)recording
                  scoring:(YTScoringService *)scoring
{
    // 统一注入：避免 Presenter 自己去拿单例，便于未来替换实现/做测试
    self.unit = unit;
    self.theme = theme;
    self.audio = audio;
    self.recording = recording;
    self.scoring = scoring;
    // 每次装载新 unit 都重置完成信号，避免“上一题完成态”污染下一题
    self.completeSignalSatisfied = NO;
}

- (void)emitPrimaryState {
    if (self.onPrimaryStateChanged) {
        self.onPrimaryStateChanged(self.primaryState);
    }
}

- (BOOL)isUnitCompleteSignalSatisfied {
    return self.completeSignalSatisfied;
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    if (completion) completion(nil, nil);
}

@end

#pragma mark - Vocab / Dialogue line (recording)

/**
 跟读/对话逐句 Presenter（vocab + dialogue_line）
 
 UI/交互（MVP）：
 - 展示：图片 + 中/拼音/英
 - 播放：点击喇叭播放标准音；播放完成后将该 unit 视为“完成”（满足 progress 条件）
 - 录音：底部主按钮驱动录音状态机：Start -> Recording -> Stop -> Scoring -> (Correct/Try again)
 
 说明：
 - “完成条件”是：播放过一次标准音 或 拿到一次评分结果（PRD MVP）
 - 评分失败/无音频时做兜底提示，不阻断用户继续流程
 */
@interface YTPronounceUnitView : YTBaseUnitView
<UITextViewDelegate>
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UITextView *cnTextView;
@property (nonatomic, strong) UILabel *pinyinLabel;
@property (nonatomic, strong) UILabel *enLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UILabel *recordHintLabel;
@property (nonatomic, assign) BOOL hasPlayedOnce;
@property (nonatomic, assign) BOOL isScoring;
@property (nonatomic, assign) BOOL shouldOpenMicSettings;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *frontContentView;
@property (nonatomic, strong) UIView *grammarContentView;
@property (nonatomic, assign) BOOL showingGrammar;
@end

@implementation YTPronounceUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 18;
        _cardView.layer.masksToBounds = YES;
        [self.rootView addSubview:_cardView];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.rootView);
        }];

        _frontContentView = [[UIView alloc] init];
        _frontContentView.backgroundColor = [UIColor clearColor];
        [_cardView addSubview:_frontContentView];
        [_frontContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.cardView);
        }];

        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.frontContentView addSubview:_imageView];

        _cnTextView = [[UITextView alloc] init];
        _cnTextView.backgroundColor = [UIColor clearColor];
        _cnTextView.scrollEnabled = NO;
        _cnTextView.editable = NO;
        _cnTextView.selectable = YES;
        _cnTextView.dataDetectorTypes = UIDataDetectorTypeNone;
        _cnTextView.textContainerInset = UIEdgeInsetsZero;
        _cnTextView.textContainer.lineFragmentPadding = 0;
        _cnTextView.textAlignment = NSTextAlignmentCenter;
        _cnTextView.delegate = self;
        [self.frontContentView addSubview:_cnTextView];

        UIColor *textColor63637D = [UIColor colorWithRed:0x63 / 255.0
                                                   green:0x63 / 255.0
                                                    blue:0x7D / 255.0
                                                   alpha:1.0];

        _pinyinLabel = [[UILabel alloc] init];
        _pinyinLabel.textAlignment = NSTextAlignmentCenter;
        _pinyinLabel.textColor = textColor63637D;
        _pinyinLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        [self.frontContentView addSubview:_pinyinLabel];

        _enLabel = [[UILabel alloc] init];
        _enLabel.textAlignment = NSTextAlignmentCenter;
        _enLabel.textColor = textColor63637D;
        // 英文（Student/Teacher）字号调小一点，避免过大
        _enLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        [self.frontContentView addSubview:_enLabel];

        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        _playButton.layer.cornerRadius = 14;
        _playButton.layer.masksToBounds = YES;
        [_playButton setTitle:@"🔈" forState:UIControlStateNormal];
        [_playButton setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(onPlay) forControlEvents:UIControlEventTouchUpInside];
        [self.frontContentView addSubview:_playButton];

        _recordHintLabel = [[UILabel alloc] init];
        _recordHintLabel.textAlignment = NSTextAlignmentCenter;
        _recordHintLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        _recordHintLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _recordHintLabel.numberOfLines = 2;
        [self.frontContentView addSubview:_recordHintLabel];

        UIView *dashedLine = [[UIView alloc] init];
        dashedLine.backgroundColor = [UIColor clearColor];
        [self.frontContentView addSubview:dashedLine];

        [_cnTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.frontContentView);
            make.left.right.equalTo(self.frontContentView).inset(16);
            // 学生（中文）label 与图片之间 60
            make.top.equalTo(self.imageView.mas_bottom).offset(60);
        }];
        [_pinyinLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            // 拼音紧跟学生 label，间距 6
            make.top.equalTo(self.cnTextView.mas_bottom).offset(6);
            make.centerX.equalTo(self.frontContentView);
        }];
        [_playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.pinyinLabel.mas_right).offset(8);
            make.centerY.equalTo(self.pinyinLabel);
            make.width.height.mas_equalTo(28);
        }];
        [_recordHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.pinyinLabel.mas_bottom).offset(8);
            make.left.right.equalTo(self.frontContentView).inset(16);
        }];

        [dashedLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.recordHintLabel.mas_bottom).offset(18);
            make.left.right.equalTo(self.frontContentView).inset(32);
            make.height.mas_equalTo(1);
        }];

        [_enLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(dashedLine.mas_bottom).offset(20);
            make.left.right.equalTo(self.frontContentView).inset(16);
            make.bottom.equalTo(self.frontContentView).offset(-53);
        }];

        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            // 图片固定在卡片上方区域：上左右各 60，中间高度由图片比例自适应
            make.top.equalTo(self.frontContentView).offset(40);
            make.left.right.equalTo(self.frontContentView).inset(60);
        }];

        CAShapeLayer *dashLayer = [CAShapeLayer layer];
        dashLayer.strokeColor = [UIColor colorWithRed:0xE2 / 255.0
                                                green:0xE2 / 255.0
                                                 blue:0xE2 / 255.0
                                                alpha:1.0].CGColor;
        dashLayer.fillColor = [UIColor clearColor].CGColor;
        dashLayer.lineWidth = 1.0;
        dashLayer.lineDashPattern = @[@4, @2];
        [dashedLine.layer addSublayer:dashLayer];

        // 等自动布局计算出 dashedLine 的真实宽度后，再根据 bounds 画满整条虚线，
        // 这样左右与 card 的间距一致。
        __weak UIView *weakLine = dashedLine;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *strongLine = weakLine;
            if (!strongLine) return;
            [strongLine layoutIfNeeded];
            CGFloat lineWidth = CGRectGetWidth(strongLine.bounds);
            dashLayer.frame = CGRectMake(0, 0, lineWidth, 1.0);
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(0, 0.5)];
            [path addLineToPoint:CGPointMake(lineWidth, 0.5)];
            dashLayer.path = path.CGPath;
        });
    }
    return self;
}

-(void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording scoring:(YTScoringService *)scoring {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording scoring:scoring];

    // 状态复位：避免跨题残留
    self.hasPlayedOnce = NO;
    self.isScoring = NO;
    self.shouldOpenMicSettings = NO;
    self.showingGrammar = NO;
    if (self.grammarContentView.superview) {
        [self.grammarContentView removeFromSuperview];
    }
    self.grammarContentView = nil;
    if (self.frontContentView.superview == nil) {
        [self.cardView addSubview:self.frontContentView];
        [self.frontContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.cardView);
        }];
    }

    // 数据驱动：优先使用 unit.imageName；若为空则 fallback 到本地占位图
    UIImage *img = nil;
    if (unit.imageName.length > 0) {
        img = [UIImage imageNamed:unit.imageName];
    }
    if (!img) {
        img = [UIImage imageNamed:@"take_img1"];
    }
    self.imageView.image = img;
    [self applyCNAttributedTextForUnit:unit];
    self.pinyinLabel.text = unit.titlePinyin ?: @"";
    self.enLabel.text = unit.titleEN ?: @"";

    self.recordHintLabel.text = @"";

    // 默认主按钮为录音入口（由容器统一渲染按钮样式）
    self.primaryState.kind = YTUnitPrimaryKindRecord;
    self.primaryState.title = @"Start recording";
    self.primaryState.enabled = YES;
    [self emitPrimaryState];
}

- (void)applyCNAttributedTextForUnit:(YTUnit *)unit {
    NSString *text = unit.titleCN ?: @"";
    UIFont *font = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.alignment = NSTextAlignmentCenter;
    ps.lineBreakMode = NSLineBreakByWordWrapping;
    UIColor *baseColor = BLACK_COLOR_1F;
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: baseColor,
        NSParagraphStyleAttributeName: ps
    }];

    BOOL enableHighlight = (unit.highlightTexts.count > 0);
    if (enableHighlight) {
        UIColor *hlColor = self.theme.primaryColor ?: [UIColor colorWithRed:0x11/255.0 green:0x7F/255.0 blue:0xEC/255.0 alpha:1.0];
        self.cnTextView.linkTextAttributes = @{
            NSForegroundColorAttributeName: hlColor,
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
        };
        for (NSString *token in unit.highlightTexts) {
            if (![token isKindOfClass:[NSString class]] || token.length == 0) continue;
            NSRange search = NSMakeRange(0, text.length);
            while (search.location < text.length) {
                NSRange r = [text rangeOfString:token options:0 range:search];
                if (r.location == NSNotFound) break;
                NSString *encoded = [token stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @"";
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"ytvocab://highlight?text=%@", encoded]];
                if (url) {
                    [att addAttribute:NSLinkAttributeName value:url range:r];
                }
                // 防止死循环：从当前匹配末尾继续
                NSUInteger next = r.location + r.length;
                if (next >= text.length) break;
                search = NSMakeRange(next, text.length - next);
            }
        }
    } else {
        self.cnTextView.linkTextAttributes = @{};
    }

    self.cnTextView.attributedText = att;
    self.cnTextView.accessibilityLabel = text;
}

#pragma mark - 高亮点击 & 翻转

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if (!URL) return YES;
    if ([[URL.scheme lowercaseString] isEqualToString:@"ytvocab"]) {
        [self flipToGrammar:!self.showingGrammar];
        return NO;
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (!URL) return YES;
    if ([[URL.scheme lowercaseString] isEqualToString:@"ytvocab"]) {
        [self flipToGrammar:!self.showingGrammar];
        return NO;
    }
    return YES;
}

- (void)flipToGrammar:(BOOL)show {
    if (show == self.showingGrammar) return;

    if (show) {
        if (!self.grammarContentView) {
            self.grammarContentView = [self buildGrammarPlaceholderView];
        }
        UIView *from = self.frontContentView;
        UIView *to = self.grammarContentView;
        [self.cardView addSubview:to];
        [to mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.cardView);
        }];
        [UIView transitionFromView:from
                            toView:to
                          duration:0.45
                           options:UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionShowHideTransitionViews
                        completion:^(__unused BOOL finished) {
            self.showingGrammar = YES;
        }];
    } else {
        if (!self.grammarContentView) return;
        UIView *from = self.grammarContentView;
        UIView *to = self.frontContentView;
        [UIView transitionFromView:from
                            toView:to
                          duration:0.45
                           options:UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionShowHideTransitionViews
                        completion:^(__unused BOOL finished) {
            self.showingGrammar = NO;
        }];
    }
}

- (UIView *)buildGrammarPlaceholderView {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];

    // 顶部导航栏
    UIView *nav = [[UIView alloc] init];
    nav.backgroundColor = [UIColor clearColor];
    [v addSubview:nav];
    [nav mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(v);
        make.height.mas_equalTo(52);
    }];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage systemImageNamed:@"chevron.left"];
        [back setImage:img forState:UIControlStateNormal];
        back.tintColor = self.theme.primaryColor ?: [UIColor colorWithRed:0x11/255.0 green:0x7F/255.0 blue:0xEC/255.0 alpha:1.0];
    } else {
        [back setTitle:@"<" forState:UIControlStateNormal];
        [back setTitleColor:self.theme.primaryColor ?: [UIColor colorWithRed:0x11/255.0 green:0x7F/255.0 blue:0xEC/255.0 alpha:1.0] forState:UIControlStateNormal];
    }
    [back addTarget:self action:@selector(onTapGrammarHighlight) forControlEvents:UIControlEventTouchUpInside];
    [nav addSubview:back];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(nav).offset(6);
        make.centerY.equalTo(nav);
        make.width.height.mas_equalTo(40);
    }];

    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.textColor = BLACK_COLOR_1F;
    navTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    navTitle.text = self.unit.grammarPageNavTitle ?: NSLocalizedString(@"Grammar Rule", @"");
    [nav addSubview:navTitle];
    [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(back.mas_right).offset(2);
        make.centerY.equalTo(nav);
    }];

    UIButton *expand = [UIButton buttonWithType:UIButtonTypeCustom];
    expand.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"];
        [expand setImage:img forState:UIControlStateNormal];
        expand.tintColor = [UIColor colorWithWhite:0.35 alpha:1];
    }
    // 右侧按钮先做占位，不做逻辑
    [nav addSubview:expand];
    [expand mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(nav).offset(-6);
        make.centerY.equalTo(nav);
        make.width.height.mas_equalTo(40);
    }];

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    [v addSubview:divider];
    [divider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(v).inset(16);
        make.top.equalTo(nav.mas_bottom);
        make.height.mas_equalTo(1);
    }];

    // 内容可滚动
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.showsVerticalScrollIndicator = NO;
    [v addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(v);
        make.top.equalTo(divider.mas_bottom);
    }];

    UIView *content = [[UIView alloc] init];
    [scroll addSubview:content];
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scroll);
        make.width.equalTo(scroll);
    }];

    NSString *token = self.unit.grammarPagePromptToken;
    if (token.length == 0) {
        NSString *first = (self.unit.highlightTexts.count > 0) ? self.unit.highlightTexts.firstObject : nil;
        token = (first.length > 0) ? first : @"";
    }
    NSString *pinyin = self.unit.grammarPagePromptPinyin ?: @"";
    UIColor *hl = self.theme.primaryColor ?: [UIColor colorWithRed:0x11/255.0 green:0x7F/255.0 blue:0xEC/255.0 alpha:1.0];

    // “... 吗? (ma)” 可点击高亮：点击翻回正面
    UIButton *hlTitle = [UIButton buttonWithType:UIButtonTypeCustom];
    hlTitle.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [hlTitle addTarget:self action:@selector(onTapGrammarHighlight) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:hlTitle];
    [hlTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(18);
        make.left.right.equalTo(content).inset(16);
        make.height.mas_greaterThanOrEqualTo(32);
    }];
    UIFont *hlFont = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];
    NSString *titleText = self.unit.grammarPagePromptText;
    if (titleText.length == 0) {
        titleText = (token.length > 0 && pinyin.length > 0) ? [NSString stringWithFormat:@"… %@?  (%@)", token, pinyin] : (token.length > 0 ? [NSString stringWithFormat:@"… %@?", token] : @"");
    }
    NSMutableAttributedString *hlAtt = [[NSMutableAttributedString alloc] initWithString:titleText attributes:@{
        NSFontAttributeName: hlFont,
        NSForegroundColorAttributeName: hl
    }];
    [hlTitle setAttributedTitle:hlAtt forState:UIControlStateNormal];

    UILabel *desc = [[UILabel alloc] init];
    desc.numberOfLines = 0;
    desc.textColor = [UIColor colorWithWhite:0.35 alpha:1];
    desc.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    desc.text = self.unit.grammarPageDescription ?: NSLocalizedString(@"Used at the end of a sentence to ask a yes/no question.", @"");
    [content addSubview:desc];
    [desc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(hlTitle.mas_bottom).offset(10);
        make.left.right.equalTo(content).inset(16);
    }];

    UIView *formulaCard = [[UIView alloc] init];
    formulaCard.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    formulaCard.layer.cornerRadius = 14;
    formulaCard.layer.masksToBounds = YES;
    [content addSubview:formulaCard];
    [formulaCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(desc.mas_bottom).offset(14);
        make.left.right.equalTo(content).inset(16);
        make.height.mas_equalTo(82);
    }];

    UILabel *formula = [[UILabel alloc] init];
    formula.textAlignment = NSTextAlignmentCenter;
    formula.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    formula.textColor = [UIColor colorWithWhite:0.22 alpha:1];
    NSString *formulaText = self.unit.grammarPageFormulaText ?: NSLocalizedString(@"Statement +  吗?  = Question", @"");
    NSString *formulaHighlightText = self.unit.grammarPageFormulaHighlightText ?: token;
    NSMutableAttributedString *fAtt = [[NSMutableAttributedString alloc] initWithString:formulaText attributes:@{
        NSFontAttributeName: formula.font,
        NSForegroundColorAttributeName: formula.textColor
    }];
    if (formulaHighlightText.length > 0) {
        NSRange search = NSMakeRange(0, formulaText.length);
        while (search.location < formulaText.length) {
            NSRange r = [formulaText rangeOfString:formulaHighlightText options:0 range:search];
            if (r.location == NSNotFound) break;
            [fAtt addAttribute:NSForegroundColorAttributeName value:hl range:r];
            NSUInteger next = r.location + r.length;
            if (next >= formulaText.length) break;
            search = NSMakeRange(next, formulaText.length - next);
        }
    }
    formula.attributedText = fAtt;
    [formulaCard addSubview:formula];
    [formula mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(formulaCard);
        make.left.right.equalTo(formulaCard).inset(12);
    }];

    UILabel *exampleLabel = [[UILabel alloc] init];
    exampleLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1];
    exampleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:12];
    exampleLabel.text = self.unit.grammarPageExampleLabel ?: NSLocalizedString(@"EXAMPLE", @"");
    [content addSubview:exampleLabel];
    [exampleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(formulaCard.mas_bottom).offset(16);
        make.left.right.equalTo(content).inset(16);
    }];

    // Examples（支持 N 句：数组驱动渲染；UI 仍使用原有 dot + cn/en 两行结构）
    NSArray<NSDictionary *> *examples = self.unit.grammarPageExamples;
    if (![examples isKindOfClass:[NSArray class]] || examples.count == 0) {
        NSMutableArray<NSDictionary *> *fallback = [NSMutableArray array];
        if (self.unit.grammarPageExample1CN || self.unit.grammarPageExample1EN) {
            [fallback addObject:@{
                @"cn": self.unit.grammarPageExample1CN ?: @"",
                @"en": self.unit.grammarPageExample1EN ?: @"",
                @"highlightText": @""
            }];
        }
        if (self.unit.grammarPageExample2CN || self.unit.grammarPageExample2EN) {
            NSString *ex2HighlightText = self.unit.grammarPageExample2HighlightText ?: (self.unit.grammarPageFormulaHighlightText ?: token);
            [fallback addObject:@{
                @"cn": self.unit.grammarPageExample2CN ?: @"",
                @"en": self.unit.grammarPageExample2EN ?: @"",
                @"highlightText": ex2HighlightText ?: @""
            }];
        }
        examples = fallback;
    }

    // 过滤掉非字典项，避免因跳过导致的约束缺失
    NSMutableArray<NSDictionary *> *filteredExamples = [NSMutableArray array];
    for (id v in examples) {
        if ([v isKindOfClass:[NSDictionary class]]) {
            [filteredExamples addObject:v];
        }
    }
    examples = filteredExamples;

    UIView *lastExampleView = nil;
    for (NSInteger i = 0; i < examples.count; i++) {
        NSDictionary *ex = examples[i];

        NSString *cnText = ex[@"cn"] ?: @"";
        NSString *enText = ex[@"en"] ?: @"";
        NSString *highlightText = ex[@"highlightText"] ?: @"";

        // 例句之间的箭头（i>0）
        UILabel *arrow = nil;
        if (i > 0 && lastExampleView) {
            arrow = [[UILabel alloc] init];
            arrow.textAlignment = NSTextAlignmentCenter;
            arrow.textColor = hl;
            arrow.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
            arrow.text = self.unit.grammarPageArrowText ?: @"↓";
            [content addSubview:arrow];
            [arrow mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(lastExampleView.mas_bottom).offset(10);
                make.centerX.equalTo(content);
                make.height.mas_equalTo(20);
            }];
        }

        UIView *exView = [[UIView alloc] init];
        [content addSubview:exView];
        [exView mas_makeConstraints:^(MASConstraintMaker *make) {
            if (!lastExampleView) {
                make.top.equalTo(exampleLabel.mas_bottom).offset(10);
            } else if (arrow) {
                make.top.equalTo(arrow.mas_bottom).offset(10);
            }
            make.left.right.equalTo(content).inset(16);
            if (i == examples.count - 1) {
                make.bottom.equalTo(content).offset(-18);
            }
        }];

        // 左侧 dot
        UIView *dot = [[UIView alloc] init];
        dot.layer.masksToBounds = YES;
        dot.layer.cornerRadius = 3;
        UIColor *dotColor = (i == 0) ? [UIColor colorWithWhite:0.78 alpha:1] : hl;
        dot.backgroundColor = dotColor;
        [exView addSubview:dot];
        [dot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(exView);
            make.top.equalTo(exView).offset(6);
            make.width.height.mas_equalTo(6);
        }];

        UILabel *cnLabel = [[UILabel alloc] init];
        cnLabel.textColor = BLACK_COLOR_1F;
        cnLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        NSMutableAttributedString *cnAtt = [[NSMutableAttributedString alloc] initWithString:cnText attributes:@{
            NSFontAttributeName: cnLabel.font,
            NSForegroundColorAttributeName: BLACK_COLOR_1F
        }];
        if (highlightText.length > 0) {
            NSRange search = NSMakeRange(0, cnText.length);
            while (search.location < cnText.length) {
                NSRange rr = [cnText rangeOfString:highlightText options:0 range:search];
                if (rr.location == NSNotFound) break;
                [cnAtt addAttribute:NSForegroundColorAttributeName value:hl range:rr];
                NSUInteger next = rr.location + rr.length;
                if (next >= cnText.length) break;
                search = NSMakeRange(next, cnText.length - next);
            }
        }
        cnLabel.attributedText = cnAtt;
        [exView addSubview:cnLabel];
        [cnLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(dot.mas_right).offset(10);
            make.top.equalTo(exView);
            make.right.equalTo(exView);
        }];

        UILabel *enLabel = [[UILabel alloc] init];
        enLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        enLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
        enLabel.text = enText;
        [exView addSubview:enLabel];
        [enLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(cnLabel);
            make.top.equalTo(cnLabel.mas_bottom).offset(4);
            make.right.equalTo(exView);
            make.bottom.equalTo(exView);
        }];

        // 竖线：从 dot 下沿开始，覆盖当前例句的中英文高度
        UIView *vertLine = [[UIView alloc] init];
        vertLine.backgroundColor = dotColor;
        vertLine.layer.cornerRadius = 1;
        vertLine.layer.masksToBounds = YES;
        [exView addSubview:vertLine];
        [vertLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(dot);
            make.top.equalTo(dot.mas_bottom);
            make.bottom.equalTo(enLabel.mas_bottom);
            make.width.mas_equalTo(2);
        }];

        lastExampleView = exView;
    }

    return v;
}

- (void)onTapGrammarHighlight {
    [self flipToGrammar:NO];
}

- (void)onPlay {
    if (self.unit.audioURLString.length == 0) {
        // 无音频：按“已播放”兜底，保证链路可跑通（后续接接口再严格化）
        self.hasPlayedOnce = YES;
        self.completeSignalSatisfied = YES;
        self.recordHintLabel.text = NSLocalizedString(@"Playback complete (standard pronunciation)", @"");
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.audio playURLString:self.unit.audioURLString completion:^(__unused BOOL success, __unused NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        self.hasPlayedOnce = YES;
        self.completeSignalSatisfied = YES;
        self.recordHintLabel.text = NSLocalizedString(@"Playback complete (standard pronunciation)", @"");
    }];
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    // 录音按钮状态机（PRD 6.2）
    // - Start recording：开始录音
    // - Recording…：再次点击停止录音
    // - Scoring…：评分中（禁用按钮，避免重复 stop）
    // - Correct/Try again：展示结果，可继续或重录
    if (self.isScoring) {
        if (completion) completion(nil, nil);
        return;
    }

    // 若上一轮因权限被拒绝而进入“去设置”状态：
    // - 不要自动跳设置（避免出现“明明已允许却仍被误判然后强跳”的体验）
    // - 用户再次点击时再跳转设置；如果此时权限已恢复，会在 startRecording 成功后自然回到正常流程
    if (self.shouldOpenMicSettings) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
        if (completion) completion(nil, nil);
        return;
    }

    // 不缓存/不依赖“预判断”结论：用户可能刚从系统设置回来，
    // 不同系统/SDK 下 permission 枚举口径也可能导致误判。
    // 这里以“能否成功开始录音”作为最终事实来源：失败时再引导去设置。
    self.shouldOpenMicSettings = NO;

    if (![self.recording isRecording]) {
        self.primaryState.kind = YTUnitPrimaryKindRecord;
        self.primaryState.title = @"Recording… (tap to stop)";
        self.primaryState.enabled = YES;
        [self emitPrimaryState];

        __weak typeof(self) weakSelf = self;
        [self.recording startRecordingWithIdentifier:self.unit.unitId completion:^(BOOL success, NSError * _Nullable error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!success || error) {
                // 录音启动失败：恢复到可录状态，并提示可用“播放标准音”完成
                // 如果是“权限被拒绝”，把按钮切到“去设置”
                if ([error.domain isEqualToString:@"YTRecordingService"] && error.code == 2002) {
                    self.shouldOpenMicSettings = YES;
                    self.primaryState.title = @"Go to Settings to enable microphone";
                    self.recordHintLabel.text = NSLocalizedString(@"Microphone permission denied, please enable it in system settings before recording.", @"");
                } else {
                    self.primaryState.title = @"Start recording";
                    self.recordHintLabel.text = NSLocalizedString(@"Recording failed; you can complete by playing the standard pronunciation.", @"");
                }
                [self emitPrimaryState];
                if (completion) completion(nil, error);
                return;
            }
            if (completion) completion(nil, nil);
        }];
        return;
    }

    // stop recording
    self.isScoring = YES;
    self.primaryState.title = @"Scoring…";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    __weak typeof(self) weakSelf = self;
    [self.recording stopRecordingWithCompletion:^(NSURL * _Nullable fileURL, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (error || !fileURL) {
            self.isScoring = NO;
            self.primaryState.title = @"Start recording";
            self.primaryState.enabled = YES;
            [self emitPrimaryState];
            self.recordHintLabel.text = NSLocalizedString(@"Scoring failed; please try again later.", @"");
            if (completion) completion(nil, error);
            return;
        }

        NSString *expected = self.unit.titleCN.length ? self.unit.titleCN : (self.unit.titlePinyin ?: @"");
        [self.scoring scoreRecordingAtURL:fileURL expectedText:expected completion:^(YTScoreResult * _Nullable result, NSError * _Nullable error2) {
            self.isScoring = NO;
            if (error2 || !result) {
                self.primaryState.title = @"Start recording";
                self.primaryState.enabled = YES;
                [self emitPrimaryState];
                self.recordHintLabel.text = NSLocalizedString(@"Scoring failed; please try again later.", @"");
                if (completion) completion(nil, error2);
                return;
            }

            self.completeSignalSatisfied = YES; // PRD：拿到评分结果即可完成
            if (result.verdict == YTScoreVerdictCorrect) {
                self.primaryState.title = @"Correct";
                self.primaryState.enabled = YES;
                NSString *fmt = NSLocalizedString(@"Score %ld (completed)", @"");
                self.recordHintLabel.text = [NSString stringWithFormat:fmt, (long)result.score];
            } else {
                self.primaryState.title = @"Try again";
                self.primaryState.enabled = YES;
                NSString *fmt = NSLocalizedString(@"Score %ld (retry)", @"");
                self.recordHintLabel.text = [NSString stringWithFormat:fmt, (long)result.score];
            }
            [self emitPrimaryState];
            if (completion) completion(nil, nil);
        }];
    }];
}

@end

#pragma mark - Exercise: Choose Image / Choose Word

/**
 选择题 Presenter（听词选图 / 看图选词 / 听音回应 / 选词填空 / 完成对话的基类）
 
 通用交互（MVP）：
 - 选择某个 option 后：高亮选中态，主按钮变为可点（Submit）
 - 点击 Submit：一次提交即完成；不阻断流程（对错反馈由容器底部 toast 展示）
 - Submit 后：选错红框、正确答案绿框（选对仅绿框选中项）
 
 听力自动播（PRD）：
 - 仅“听词选图/听音回应”进入题目时自动播放一次题干音频（`hasAutoPlayed` 防重复）
 - 音频为空时静默跳过，保证无接口也能跑通
 */
@interface YTChoiceExerciseUnitView : YTBaseUnitView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, strong) UILabel *pinyinLabel;
@property (nonatomic, strong) UIView *dividerLine;
@property (nonatomic, strong) UIView *optionsContainer;
@property (nonatomic, copy, nullable) NSString *selectedOptionId;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, assign) BOOL hasAutoPlayed;
@end

@implementation YTChoiceExerciseUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        _optionButtons = [NSMutableArray array];
        _hasAutoPlayed = NO;
        UIColor *titleColor63637D = [UIColor colorWithRed:0x63 / 255.0
                                                    green:0x63 / 255.0
                                                     blue:0x7D / 255.0
                                                    alpha:1.0];
        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [UIColor whiteColor];
        card.layer.cornerRadius = 18;
        card.layer.masksToBounds = YES;
        [self.rootView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.rootView);
        }];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = titleColor63637D;
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        // 标题统一固定为单行，避免被自适应拉高影响整体布局
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [card addSubview:_titleLabel];

        _audioButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _audioButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        _audioButton.layer.cornerRadius = 18;
        _audioButton.layer.masksToBounds = YES;
        UIImage *spk = nil;
        if (@available(iOS 13.0, *)) {
            spk = [UIImage systemImageNamed:@"speaker.wave.2.fill"];
        }
        [_audioButton setImage:spk forState:UIControlStateNormal];
        _audioButton.tintColor = BLACK_COLOR_1F;
        [_audioButton addTarget:self action:@selector(onPlayAudio) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:_audioButton];

        _pinyinLabel = [[UILabel alloc] init];
        _pinyinLabel.textColor = BLACK_COLOR_1F;
        _pinyinLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _pinyinLabel.numberOfLines = 1;
        [card addSubview:_pinyinLabel];

        _dividerLine = [[UIView alloc] init];
        _dividerLine.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
        [card addSubview:_dividerLine];

        _optionsContainer = [[UIView alloc] init];
        _optionsContainer.backgroundColor = [UIColor clearColor];
        [card addSubview:_optionsContainer];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(card).offset(16);
            make.left.equalTo(card).offset(16);
            make.right.equalTo(card).offset(-16);
            // 固定标题高度（约 25）
            make.height.mas_equalTo(25);
        }];
        [_audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(card).offset(16);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
            make.width.height.mas_equalTo(36);
        }];
        [_pinyinLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.audioButton.mas_right).offset(10);
            make.centerY.equalTo(self.audioButton);
            make.right.equalTo(card).offset(-16);
        }];
        [_dividerLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(card).inset(16);
            make.top.equalTo(self.audioButton.mas_bottom).offset(12);
            make.height.mas_equalTo(1);
        }];
        [_optionsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(card).inset(16);
            make.top.equalTo(self.dividerLine.mas_bottom).offset(40);
            make.bottom.equalTo(card).offset(-16);
        }];
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording scoring:(YTScoringService *)scoring {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording scoring:scoring];
    // 状态复位：避免跨题残留（选中项/自动播状态/按钮列表）
    self.selectedOptionId = nil;
    self.hasAutoPlayed = NO;
    [self.optionButtons removeAllObjects];

    // 默认：未选择时不允许提交
    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    // 清理旧按钮
    for (UIView *v in self.optionsContainer.subviews) {
        [v removeFromSuperview];
    }

    if (unit.exerciseType == YTExerciseTypeListenChooseImage) {
        // 听词选图：展示“音频按钮 + 拼音提示 + 2x2 图格”
        self.titleLabel.text = NSLocalizedString(@"Choose the matching image", @"");
        self.audioButton.hidden = NO;
        self.pinyinLabel.hidden = NO;
        self.pinyinLabel.text = unit.titlePinyin ?: @"";
        self.dividerLine.hidden = NO;
        // 保持原有：题干区域 + 分割线 + 选项容器
        [self.optionsContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.rootView).inset(16);
            make.top.equalTo(self.dividerLine.mas_bottom).offset(40);
            make.bottom.equalTo(self.rootView).offset(-16);
        }];
        [self buildImageGridOptions];
        [self autoPlayIfNeeded];
    } else {
        // 标题已在 init 固定为单行 + 高度 25，这里仅保证截断策略一致
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor = 0.85;

        self.titleLabel.text = (unit.exerciseType == YTExerciseTypeListenChooseResponse)
            ? NSLocalizedString(@"Choose the correct response", @"")
            : NSLocalizedString(@"Choose the matching word", @"");
        // 看图选词/纯选择题一般不强制音频
        self.audioButton.hidden = (unit.exerciseType != YTExerciseTypeListenChooseResponse);
        self.pinyinLabel.hidden = YES;
        self.pinyinLabel.text = @"";

        if (unit.exerciseType == YTExerciseTypeLookChooseWord) {
            // 看图选词：去掉标题下横线，整体按新规范排版
            self.dividerLine.hidden = YES;
            [self.optionsContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.rootView).inset(16);
                // 图片顶部距离标题 40（这里控制 optionsContainer 顶部）
                make.top.equalTo(self.titleLabel.mas_bottom).offset(40);
                // 最后一个选项距离底部 30
                make.bottom.equalTo(self.rootView).offset(-30);
            }];
        } else {
            // 其它选择题型保留原布局和分割线
            self.dividerLine.hidden = NO;
            [self.optionsContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.rootView).inset(16);
                make.top.equalTo(self.dividerLine.mas_bottom).offset(40);
                make.bottom.equalTo(self.rootView).offset(-16);
            }];
        }

        [self buildWordOptionsWithHeaderImage];
        if (unit.exerciseType == YTExerciseTypeListenChooseResponse) {
            [self autoPlayIfNeeded];
        }
    }
}

- (void)autoPlayIfNeeded {
    if (self.hasAutoPlayed) return;
    self.hasAutoPlayed = YES;
    // PRD：仅听力题自动播一次（听词选图/听音回应）
    if (self.unit.audioURLString.length == 0) return;
    [self.audio playURLString:self.unit.audioURLString completion:nil];
}

- (void)onPlayAudio {
    if (self.unit.audioURLString.length == 0) return;
    [self.audio playURLString:self.unit.audioURLString completion:nil];
}

- (void)buildImageGridOptions {
    // 2x2：适配当前卡片宽度（MVP 按屏宽估算；后续可改为读容器约束宽度）
    CGFloat gap = 13;
    CGFloat w = (SCREEN_WIDTH - 32 /*outer*/ - 32 /*card inset*/ - gap) / 2.0;
    CGFloat h = w * 166.0 / 145.0;
    UIColor *borderColorD4 = [UIColor colorWithRed:0xD4 / 255.0
                                             green:0xD4 / 255.0
                                              blue:0xE4 / 255.0
                                             alpha:1.0];

    for (NSInteger i = 0; i < self.unit.options.count; i++) {
        NSDictionary *opt = self.unit.options[i];
        NSString *optId = opt[@"id"];
        NSString *imgName = opt[@"imageName"];
        NSString *text = opt[@"text"];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.accessibilityIdentifier = optId;
        btn.layer.cornerRadius = 14;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = borderColorD4.CGColor;
        btn.backgroundColor = [UIColor whiteColor];
        btn.clipsToBounds = YES;
        [btn addTarget:self action:@selector(onSelectOption:) forControlEvents:UIControlEventTouchUpInside];
        [self.optionsContainer addSubview:btn];
        [self.optionButtons addObject:btn];

        NSInteger row = i / 2;
        NSInteger col = i % 2;
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.optionsContainer).offset(col * (w + gap));
            make.top.equalTo(self.optionsContainer).offset(row * (h + gap));
            make.width.mas_equalTo(w);
            make.height.mas_equalTo(h);
        }];

        NSString *iconName = imgName.length > 0 ? imgName : @"take_img1";
        UIImage *iconImg = [UIImage imageNamed:iconName] ?: [UIImage imageNamed:@"take_img1"];
        UIImageView *iv = [[UIImageView alloc] initWithImage:iconImg];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        [btn addSubview:iv];

        UILabel *lbl = [[UILabel alloc] init];
        lbl.text = text;
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [UIColor colorWithWhite:0.35 alpha:1];
        lbl.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        [btn addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(btn).inset(6);
            make.bottom.equalTo(btn).offset(-10);
        }];

        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(btn).inset(7);
            make.top.equalTo(btn).offset(7);
            make.bottom.equalTo(lbl.mas_top).offset(-7);
        }];
    }
}

- (void)buildWordOptionsWithHeaderImage {
    UIImageView *header = nil;
    BOOL isLookChooseWord = (self.unit.exerciseType == YTExerciseTypeLookChooseWord);
    if (isLookChooseWord) {
            // 看图选词：使用后端下发题干大图（unit.imageName），为空则 fallback 到占位图
        UIImage *img = nil;
        if (self.unit.imageName.length > 0) {
            img = [UIImage imageNamed:self.unit.imageName];
        }
        if (!img) {
            img = [UIImage imageNamed:@"take_img1"];
        }
        header = [[UIImageView alloc] initWithImage:img];
        header.contentMode = UIViewContentModeScaleAspectFit;
        [self.optionsContainer addSubview:header];
    } else if (self.unit.imageName.length > 0) {
        header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.unit.imageName]];
        header.contentMode = UIViewContentModeScaleAspectFit;
        [self.optionsContainer addSubview:header];
    }

    UIView *list = [[UIView alloc] init];
    [self.optionsContainer addSubview:list];
    [list mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.optionsContainer);
        make.bottom.equalTo(self.optionsContainer);
        if (header) {
            // 选项区域贴底，图片与选项固定间距（看图选词 40，其它 12）
            CGFloat offset = isLookChooseWord ? 40.0 : 12.0;
            make.top.equalTo(header.mas_bottom).offset(offset);
        } else {
            make.top.equalTo(self.optionsContainer);
        }
    }];

    if (header) {
        if (isLookChooseWord) {
            // 图片顶部距标题 40 由 optionsContainer.top 控制；
            // 这里让“图片底部 == 选项顶部 - 40”，多余高度只会撑大图片，不会拉伸选项列表。
            [header mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.optionsContainer);
                make.left.right.equalTo(self.optionsContainer).inset(60);
                make.bottom.equalTo(list.mas_top).offset(-40);
            }];
        } else {
            [header mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.optionsContainer);
                make.centerX.equalTo(self.optionsContainer);
                make.width.height.mas_equalTo(140);
            }];
        }
    }

    CGFloat btnH = 44;
    // 看图选词：选项上下间距 16，其它题型保持 10
    CGFloat gap = (self.unit.exerciseType == YTExerciseTypeLookChooseWord) ? 16.0 : 10.0;
    for (NSInteger i = 0; i < self.unit.options.count; i++) {
        NSDictionary *opt = self.unit.options[i];
        NSString *optId = opt[@"id"];
        NSString *text = opt[@"text"];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.accessibilityIdentifier = optId;
        btn.layer.cornerRadius = 12;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
        [btn setTitle:text forState:UIControlStateNormal];
        [btn setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        [btn addTarget:self action:@selector(onSelectOption:) forControlEvents:UIControlEventTouchUpInside];
        [list addSubview:btn];
        [self.optionButtons addObject:btn];

        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(list);
            make.top.equalTo(list).offset(i * (btnH + gap));
            make.height.mas_equalTo(btnH);
            // 看图选词：最后一个选项紧贴 list 底部，从而保证距离卡片底部 30
            if (i == self.unit.options.count - 1 && isLookChooseWord) {
                make.bottom.equalTo(list);
            }
        }];
    }
}

- (void)onSelectOption:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= self.unit.options.count) return;
    NSDictionary *opt = self.unit.options[idx];
    self.selectedOptionId = opt[@"id"];

    // 更新样式：提交前选中态统一为灰色描边（#D4D4E4，宽度 3），其他为默认灰边
    for (UIButton *btn in self.optionButtons) {
        BOOL sel = [btn.accessibilityIdentifier isEqualToString:self.selectedOptionId];
        btn.layer.borderColor = sel ? [theAppDelegate.window colorWithHexString:@"#D4D4E4" alpha:1].CGColor : [UIColor colorWithWhite:0.85 alpha:1].CGColor;
        btn.layer.borderWidth = sel ? 3 : 1;
        // 若上一轮提交答错给了红色背景，这里在“重新选择”时必须清掉
        btn.backgroundColor = [UIColor whiteColor];
    }

    self.primaryState.enabled = (self.selectedOptionId.length > 0);
    [self emitPrimaryState];
}

- (void)applySubmitFeedbackCorrect:(BOOL)isCorrect {
    // 提交后的视觉反馈（不改变业务判定）：
    // - 答对：仅高亮用户选择（绿色描边）
    // - 答错：仅高亮用户选择（红色描边），不自动高亮正确选项（避免“系统替用户勾选”）
    UIColor *correctC = self.theme.primaryColor ?: (self.theme.correctColor ?: [UIColor colorWithRed:0.2 green:0.75 blue:0.4 alpha:1]);
    UIColor *wrongBorderC = [theAppDelegate.window colorWithHexString:@"#FF9593" alpha:1];
    UIColor *wrongFillC = [theAppDelegate.window colorWithHexString:@"#FFF0F1" alpha:1];
    for (UIButton *btn in self.optionButtons) {
        NSString *bid = btn.accessibilityIdentifier ?: @"";
        BOOL isSel = [bid isEqualToString:self.selectedOptionId ?: @""];
        if (isCorrect) {
            if (isSel) {
                // 答对：边框为主题色，背景为主题色 20% 透明度
                btn.layer.borderColor = correctC.CGColor;
                btn.layer.borderWidth = 3;
                btn.backgroundColor = [correctC colorWithAlphaComponent:0.2];
            } else {
                btn.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
                btn.layer.borderWidth = 1;
                btn.backgroundColor = [UIColor whiteColor];
            }
        } else {
            if (isSel) {
                btn.layer.borderColor = wrongBorderC.CGColor;
                btn.layer.borderWidth = 3;
                btn.backgroundColor = wrongFillC;
            } else {
                btn.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
                btn.layer.borderWidth = 1;
                btn.backgroundColor = [UIColor whiteColor];
            }
        }
    }
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    if (self.selectedOptionId.length == 0) {
        // 交互兜底：理论上按钮不可点；这里仍保留防御性检查
        if (completion) completion(nil, [NSError errorWithDomain:@"YTChoiceExerciseUnitView" code:4001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please choose an option", @"")}]);
        return;
    }
    BOOL correct = [self.selectedOptionId isEqualToString:self.unit.correctOptionId ?: @""];
    YTUnitSubmitResult *r = [[YTUnitSubmitResult alloc] init];
    r.isCorrect = correct;
    if (!correct) {
        // 找到正确答案文字
        NSString *answer = nil;
        for (NSDictionary *opt in self.unit.options) {
            if ([opt[@"id"] isEqual:self.unit.correctOptionId]) {
                answer = opt[@"text"];
                break;
            }
        }
        r.correctAnswerText = answer ?: @"";
    }
    self.completeSignalSatisfied = YES; // PRD：提交一次即完成
    [self applySubmitFeedbackCorrect:correct];
    if (completion) completion(r, nil);
}

@end

#pragma mark - Grammar

/**
 Grammar/Usage Presenter（引导页）
 
 设计意图（MVP）：
 - 语法页更多承担“解释/示例”，不做严格测验，因此默认主按钮为 Got it
 - 用气泡列表展示多行文本，便于未来扩展“示例/高亮/点击展开”
 
 注意：
 - 当前 `ruleButton` 仅做 UI 占位（后续可弹出更详细规则/跳转详情页）
 */
@interface YTGrammarUnitView : YTBaseUnitView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) UIButton *ruleButton;
@end

@implementation YTGrammarUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [UIColor whiteColor];
        card.layer.cornerRadius = 18;
        card.layer.masksToBounds = YES;
        [self.rootView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.rootView);
        }];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = BLACK_COLOR_1F;
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _titleLabel.text = NSLocalizedString(@"Usage:", @"");
        [card addSubview:_titleLabel];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(card).offset(16);
            make.left.right.equalTo(card).inset(16);
        }];

        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = NO;
        [card addSubview:_scrollView];
        [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(card);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
            make.bottom.equalTo(card).offset(-72);
        }];

        UIView *content = [[UIView alloc] init];
        [_scrollView addSubview:content];
        [content mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.scrollView);
            make.width.equalTo(self.scrollView);
        }];

        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisVertical;
        _stack.alignment = UIStackViewAlignmentFill;
        _stack.distribution = UIStackViewDistributionFill;
        _stack.spacing = 12;
        [content addSubview:_stack];
        [_stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(content).offset(6);
            make.left.right.equalTo(content).inset(16);
            make.bottom.equalTo(content).offset(-10);
        }];

        _ruleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _ruleButton.layer.cornerRadius = 14;
        _ruleButton.layer.masksToBounds = YES;
        _ruleButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        [_ruleButton setTitle:NSLocalizedString(@"Grammar Rule", @"") forState:UIControlStateNormal];
        [_ruleButton setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        _ruleButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        [card addSubview:_ruleButton];
        [_ruleButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(card).inset(16);
            make.bottom.equalTo(card).offset(-16);
            make.height.mas_equalTo(44);
        }];
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording scoring:(YTScoringService *)scoring {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording scoring:scoring];
    // 复用同一个 view，切题时先清空旧的 bubble
    for (UIView *v in self.stack.arrangedSubviews) {
        [self.stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSString *txt = unit.grammarText ?: @"";
    // 简单按换行切分为多条 bubble（后续可替换为富文本/结构化数据）
    NSArray<NSString *> *lines = [txt componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        NSString *s = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) continue;

        UILabel *bubble = [[UILabel alloc] init];
        bubble.text = s;
        bubble.numberOfLines = 0;
        bubble.textColor = BLACK_COLOR_1F;
        bubble.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        bubble.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
        bubble.layer.cornerRadius = 14;
        bubble.layer.masksToBounds = YES;
        bubble.layer.borderWidth = 1;
        bubble.layer.borderColor = [UIColor colorWithWhite:0.90 alpha:1].CGColor;
        bubble.textAlignment = NSTextAlignmentLeft;
        bubble.layoutMargins = UIEdgeInsetsMake(12, 12, 12, 12);
        bubble.translatesAutoresizingMaskIntoConstraints = NO;

        UIView *wrap = [[UIView alloc] init];
        [wrap addSubview:bubble];
        [bubble mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(wrap);
            make.left.equalTo(wrap);
            make.right.lessThanOrEqualTo(wrap);
        }];
        [self.stack addArrangedSubview:wrap];
    }

    self.primaryState.kind = YTUnitPrimaryKindGotIt;
    self.primaryState.title = @"Got it";
    self.primaryState.enabled = YES;
    [self emitPrimaryState];
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    self.completeSignalSatisfied = YES;
    if (completion) completion(nil, nil);
}

@end

#pragma mark - Exercise: Fill blank / Listen response / Build sentence / Complete dialogue

@interface YTFillBlankUnitView : YTBaseUnitView
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *sentenceRow;
@property (nonatomic, strong) UILabel *prefixLabel;
@property (nonatomic, strong) UILabel *suffixLabel;
@property (nonatomic, strong) UILabel *blankWordLabel;
@property (nonatomic, strong) UIView *blankLine;
@property (nonatomic, strong) UIView *optionsRow;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, copy, nullable) NSString *selectedOptionId;
@end

@implementation YTFillBlankUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        _optionButtons = [NSMutableArray array];

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 18;
        _cardView.layer.masksToBounds = YES;
        [self.rootView addSubview:_cardView];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.rootView);
        }];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        _titleLabel.text = NSLocalizedString(@"Choose the correct word", @"");
        [_cardView addSubview:_titleLabel];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(16);
            make.left.right.equalTo(self.cardView).inset(16);
        }];

        _sentenceRow = [[UIView alloc] init];
        _sentenceRow.backgroundColor = [UIColor clearColor];
        [_cardView addSubview:_sentenceRow];
        [_sentenceRow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(26);
            make.left.right.equalTo(self.cardView).inset(16);
            make.height.mas_equalTo(44);
        }];

        _prefixLabel = [[UILabel alloc] init];
        _prefixLabel.textColor = BLACK_COLOR_1F;
        _prefixLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _prefixLabel.text = @"";
        [_sentenceRow addSubview:_prefixLabel];

        _suffixLabel = [[UILabel alloc] init];
        _suffixLabel.textColor = BLACK_COLOR_1F;
        _suffixLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _suffixLabel.text = @"?";
        [_sentenceRow addSubview:_suffixLabel];

        UIView *blankWrap = [[UIView alloc] init];
        blankWrap.backgroundColor = [UIColor clearColor];
        [_sentenceRow addSubview:blankWrap];

        _blankWordLabel = [[UILabel alloc] init];
        _blankWordLabel.textAlignment = NSTextAlignmentCenter;
        _blankWordLabel.textColor = BLACK_COLOR_1F;
        _blankWordLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _blankWordLabel.text = @"";
        [blankWrap addSubview:_blankWordLabel];

        _blankLine = [[UIView alloc] init];
        _blankLine.backgroundColor = [UIColor colorWithWhite:0.78 alpha:1];
        [blankWrap addSubview:_blankLine];

        [_prefixLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.sentenceRow);
            make.centerY.equalTo(self.sentenceRow);
        }];
        [blankWrap mas_makeConstraints:^(MASConstraintMaker *make) {
            // 题干三段紧挨着：prefix - blank - suffix
            make.left.equalTo(self.prefixLabel.mas_right).offset(6);
            make.centerY.equalTo(self.sentenceRow);
            // 下划线宽度先按截图给一个较短默认值，后续再按字数动态调整
            make.width.mas_equalTo(54);
            make.height.mas_equalTo(34);
        }];
        [_suffixLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(blankWrap.mas_right).offset(6);
            make.centerY.equalTo(self.sentenceRow);
            make.right.lessThanOrEqualTo(self.sentenceRow);
        }];
        [_blankWordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(blankWrap);
            make.bottom.equalTo(self.blankLine.mas_top).offset(-3);
        }];
        [_blankLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(blankWrap);
            make.bottom.equalTo(blankWrap);
            make.height.mas_equalTo(1);
        }];

        _optionsRow = [[UIView alloc] init];
        _optionsRow.backgroundColor = [UIColor clearColor];
        [_cardView addSubview:_optionsRow];
        [_optionsRow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.cardView);
            make.centerY.equalTo(self.cardView).offset(110);
            make.height.mas_equalTo(44);
            make.left.greaterThanOrEqualTo(self.cardView).offset(16);
            make.right.lessThanOrEqualTo(self.cardView).offset(-16);
        }];
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording scoring:(YTScoringService *)scoring {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording scoring:scoring];
    self.selectedOptionId = nil;
    self.blankWordLabel.text = @"";

    // 主按钮：未选时不可提交
    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    // 题干：默认从 titleCN 里找 "__"（若没有就整句放左边）
    NSString *stem = unit.titleCN ?: @"";
    NSRange blankRange = [stem rangeOfString:@"__"];
    if (blankRange.location != NSNotFound) {
        NSString *pre = [stem substringToIndex:blankRange.location];
        NSString *suf = [stem substringFromIndex:blankRange.location + blankRange.length];
        self.prefixLabel.text = pre.length ? pre : @"";
        // 右侧 suffix 里如果带中文问号/英文问号，统一显示 “？”
        NSString *trim = [suf stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.suffixLabel.text = (trim.length > 0) ? trim : @"？";
    } else {
        self.prefixLabel.text = stem.length ? stem : @"";
        self.suffixLabel.text = @"";
    }

    // 重建选项按钮
    for (UIView *v in self.optionsRow.subviews) {
        [v removeFromSuperview];
    }
    [self.optionButtons removeAllObjects];

    NSArray<NSDictionary *> *opts = unit.options ?: @[];
    CGFloat gap = 12;
    UIButton *prev = nil;
    for (NSInteger i = 0; i < opts.count; i++) {
        NSDictionary *opt = opts[i];
        NSString *optId = opt[@"id"] ?: [NSString stringWithFormat:@"%ld", (long)i];
        NSString *text = opt[@"text"] ?: @"";

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.accessibilityIdentifier = optId;
        btn.layer.cornerRadius = 10;
        btn.layer.masksToBounds = YES;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
        btn.backgroundColor = [UIColor whiteColor];
        [btn setTitle:text forState:UIControlStateNormal];
        [btn setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        btn.contentEdgeInsets = UIEdgeInsetsMake(10, 14, 10, 14);
        [btn addTarget:self action:@selector(onSelectFillBlankOption:) forControlEvents:UIControlEventTouchUpInside];
        [self.optionsRow addSubview:btn];
        [self.optionButtons addObject:btn];

        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.optionsRow);
            if (prev) {
                make.left.equalTo(prev.mas_right).offset(gap);
            } else {
                make.left.equalTo(self.optionsRow);
            }
        }];
        prev = btn;
    }
    if (prev) {
        [prev mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.optionsRow);
        }];
    }
}

- (void)onSelectFillBlankOption:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= self.unit.options.count) return;
    NSDictionary *opt = self.unit.options[idx];
    self.selectedOptionId = sender.accessibilityIdentifier ?: opt[@"id"];
    self.blankWordLabel.text = opt[@"text"] ?: @"";

    UIColor *selBorder = [theAppDelegate.window colorWithHexString:@"#D4D4E4" alpha:1];
    for (UIButton *btn in self.optionButtons) {
        BOOL sel = [btn.accessibilityIdentifier isEqualToString:self.selectedOptionId ?: @""];
        btn.layer.borderColor = sel ? selBorder.CGColor : [UIColor colorWithWhite:0.85 alpha:1].CGColor;
        btn.layer.borderWidth = sel ? 3 : 1;
        btn.backgroundColor = [UIColor whiteColor];
    }
    self.primaryState.enabled = (self.selectedOptionId.length > 0);
    [self emitPrimaryState];
}

- (void)applySubmitFeedbackCorrect:(BOOL)isCorrect {
    UIColor *correctC = self.theme.primaryColor ?: (self.theme.correctColor ?: [UIColor colorWithRed:0.2 green:0.75 blue:0.4 alpha:1]);
    UIColor *wrongBorderC = [theAppDelegate.window colorWithHexString:@"#FF9593" alpha:1];
    UIColor *wrongFillC = [theAppDelegate.window colorWithHexString:@"#FFF0F1" alpha:1];
    for (UIButton *btn in self.optionButtons) {
        BOOL isSel = [btn.accessibilityIdentifier isEqualToString:self.selectedOptionId ?: @""];
        if (!isSel) {
            btn.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
            btn.layer.borderWidth = 1;
            btn.backgroundColor = [UIColor whiteColor];
            continue;
        }
        if (isCorrect) {
            btn.layer.borderColor = correctC.CGColor;
            btn.layer.borderWidth = 3;
            btn.backgroundColor = [correctC colorWithAlphaComponent:0.2];
        } else {
            btn.layer.borderColor = wrongBorderC.CGColor;
            btn.layer.borderWidth = 3;
            btn.backgroundColor = wrongFillC;
        }
    }
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    if (self.selectedOptionId.length == 0) {
        if (completion) completion(nil, [NSError errorWithDomain:@"YTFillBlankUnitView" code:4001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please choose an option", @"")}]);
        return;
    }
    BOOL correct = [self.selectedOptionId isEqualToString:self.unit.correctOptionId ?: @""];
    YTUnitSubmitResult *r = [[YTUnitSubmitResult alloc] init];
    r.isCorrect = correct;
    if (!correct) {
        NSString *answer = nil;
        for (NSDictionary *opt in self.unit.options) {
            NSString *oid = opt[@"id"];
            if ([oid isEqual:self.unit.correctOptionId]) {
                answer = opt[@"text"];
                break;
            }
        }
        r.correctAnswerText = answer ?: @"";
    }
    self.completeSignalSatisfied = YES;
    [self applySubmitFeedbackCorrect:correct];
    if (completion) completion(r, nil);
}

@end

@interface YTListenResponseUnitView : YTBaseUnitView
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *bubbleLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIView *optionsContainer;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, copy, nullable) NSString *selectedOptionId;
@end

@implementation YTListenResponseUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        _optionButtons = [NSMutableArray array];

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 18;
        _cardView.layer.masksToBounds = YES;
        [self.rootView addSubview:_cardView];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.rootView);
        }];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        _titleLabel.text = NSLocalizedString(@"Choose the correct response", @"");
        [_cardView addSubview:_titleLabel];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(16);
            make.left.right.equalTo(self.cardView).inset(16);
        }];

        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
        _bubbleView.layer.cornerRadius = 18;
        _bubbleView.layer.masksToBounds = YES;
        [_cardView addSubview:_bubbleView];
        [_bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
            make.left.equalTo(self.cardView).offset(16);
            make.height.mas_equalTo(44);
            make.width.lessThanOrEqualTo(self.cardView).multipliedBy(0.78);
        }];

        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];
        _playButton.layer.cornerRadius = 14;
        _playButton.layer.masksToBounds = YES;
        UIImage *spk = nil;
        if (@available(iOS 13.0, *)) {
            spk = [UIImage systemImageNamed:@"speaker.wave.2.fill"];
        }
        [_playButton setImage:spk forState:UIControlStateNormal];
        _playButton.tintColor = [UIColor colorWithWhite:0.25 alpha:1];
        [_playButton addTarget:self action:@selector(onPlayAudio) forControlEvents:UIControlEventTouchUpInside];
        [_bubbleView addSubview:_playButton];
        [_playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.bubbleView).offset(-10);
            make.centerY.equalTo(self.bubbleView);
            make.width.height.mas_equalTo(28);
        }];

        _bubbleLabel = [[UILabel alloc] init];
        _bubbleLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1];
        _bubbleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:15];
        _bubbleLabel.numberOfLines = 1;
        _bubbleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_bubbleView addSubview:_bubbleLabel];
        [_bubbleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.bubbleView).offset(16);
            make.right.equalTo(self.playButton.mas_left).offset(-10);
            make.centerY.equalTo(self.bubbleView);
        }];

        _optionsContainer = [[UIView alloc] init];
        _optionsContainer.backgroundColor = [UIColor clearColor];
        [_cardView addSubview:_optionsContainer];
        [_optionsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.cardView).inset(16);
            // 规范：答案选项顶部距离语音气泡底部 60
            make.top.equalTo(self.bubbleView.mas_bottom).offset(60);
            make.bottom.lessThanOrEqualTo(self.cardView).offset(-20);
        }];
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording scoring:(YTScoringService *)scoring {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording scoring:scoring];
    self.selectedOptionId = nil;

    self.titleLabel.text = NSLocalizedString(@"Choose the correct response", @"");
    self.bubbleLabel.text = unit.titleCN.length ? unit.titleCN : (unit.titlePinyin ?: @"");

    // 主按钮：未选时不可提交
    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    // 清理旧选项
    for (UIView *v in self.optionsContainer.subviews) {
        [v removeFromSuperview];
    }
    [self.optionButtons removeAllObjects];

    // 选项：竖向列表（3条）
    NSArray<NSDictionary *> *opts = unit.options ?: @[];
    CGFloat btnH = 44;
    CGFloat gap = 14;
    UIView *prev = nil;
    for (NSInteger i = 0; i < opts.count; i++) {
        NSDictionary *opt = opts[i];
        NSString *optId = opt[@"id"] ?: [NSString stringWithFormat:@"%ld", (long)i];
        NSString *text = opt[@"text"] ?: @"";

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.accessibilityIdentifier = optId;
        btn.layer.cornerRadius = 12;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;
        btn.backgroundColor = [UIColor whiteColor];
        [btn setTitle:text forState:UIControlStateNormal];
        [btn setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        [btn addTarget:self action:@selector(onSelectListenResponseOption:) forControlEvents:UIControlEventTouchUpInside];
        [self.optionsContainer addSubview:btn];
        [self.optionButtons addObject:btn];

        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.optionsContainer);
            make.height.mas_equalTo(btnH);
            if (prev) {
                make.top.equalTo(prev.mas_bottom).offset(gap);
            } else {
                make.top.equalTo(self.optionsContainer);
            }
            if (i == opts.count - 1) {
                make.bottom.lessThanOrEqualTo(self.optionsContainer);
            }
        }];
        prev = btn;
    }
}

- (void)onPlayAudio {
    if (self.unit.audioURLString.length == 0) return;
    [self.audio playURLString:self.unit.audioURLString completion:nil];
}

- (void)onSelectListenResponseOption:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= self.unit.options.count) return;
    NSDictionary *opt = self.unit.options[idx];
    self.selectedOptionId = sender.accessibilityIdentifier ?: opt[@"id"];

    UIColor *selBorder = [theAppDelegate.window colorWithHexString:@"#D4D4E4" alpha:1];
    for (UIButton *btn in self.optionButtons) {
        BOOL sel = [btn.accessibilityIdentifier isEqualToString:self.selectedOptionId ?: @""];
        btn.layer.borderColor = sel ? selBorder.CGColor : [UIColor colorWithWhite:0.88 alpha:1].CGColor;
        btn.layer.borderWidth = sel ? 3 : 1;
        btn.backgroundColor = [UIColor whiteColor];
    }
    self.primaryState.enabled = (self.selectedOptionId.length > 0);
    [self emitPrimaryState];
}

- (void)applySubmitFeedbackCorrect:(BOOL)isCorrect {
    UIColor *correctC = self.theme.primaryColor ?: (self.theme.correctColor ?: [UIColor colorWithRed:0.2 green:0.75 blue:0.4 alpha:1]);
    UIColor *wrongBorderC = [theAppDelegate.window colorWithHexString:@"#FF9593" alpha:1];
    UIColor *wrongFillC = [theAppDelegate.window colorWithHexString:@"#FFF0F1" alpha:1];
    for (UIButton *btn in self.optionButtons) {
        BOOL isSel = [btn.accessibilityIdentifier isEqualToString:self.selectedOptionId ?: @""];
        if (!isSel) {
            btn.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;
            btn.layer.borderWidth = 1;
            btn.backgroundColor = [UIColor whiteColor];
            continue;
        }
        if (isCorrect) {
            btn.layer.borderColor = correctC.CGColor;
            btn.layer.borderWidth = 3;
            btn.backgroundColor = [correctC colorWithAlphaComponent:0.2];
        } else {
            btn.layer.borderColor = wrongBorderC.CGColor;
            btn.layer.borderWidth = 3;
            btn.backgroundColor = wrongFillC;
        }
    }
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    if (self.selectedOptionId.length == 0) {
        if (completion) completion(nil, [NSError errorWithDomain:@"YTListenResponseUnitView" code:4001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please choose an option", @"")}]);
        return;
    }
    BOOL correct = [self.selectedOptionId isEqualToString:self.unit.correctOptionId ?: @""];
    YTUnitSubmitResult *r = [[YTUnitSubmitResult alloc] init];
    r.isCorrect = correct;
    if (!correct) {
        NSString *answer = nil;
        for (NSDictionary *opt in self.unit.options) {
            NSString *oid = opt[@"id"];
            if ([oid isEqual:self.unit.correctOptionId]) {
                answer = opt[@"text"];
                break;
            }
        }
        r.correctAnswerText = answer ?: @"";
    }
    self.completeSignalSatisfied = YES;
    [self applySubmitFeedbackCorrect:correct];
    if (completion) completion(r, nil);
}

@end

@interface YTBuildSentenceUnitView : YTBaseUnitView
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *selectedRowContainer;
@property (nonatomic, strong) UIStackView *selectedStack;
@property (nonatomic, strong) UIView *dividerLine;
@property (nonatomic, strong) UIView *tokensRowContainer;
@property (nonatomic, strong) UIStackView *tokensStack;
@property (nonatomic, strong) NSMutableArray<UIButton *> *tokenButtons;
@property (nonatomic, strong) NSMutableArray<UIView *> *tokenSlots;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *tokenWidths;
@property (nonatomic, strong) NSMutableArray<UIView *> *tokenPlaceholders;
@property (nonatomic, strong) NSMutableArray<UIButton *> *selectedChipButtons;
@property (nonatomic, assign) BOOL hasSubmitted;
@end

@implementation YTBuildSentenceUnitView

/**
 句子组装 Presenter（MVP 交互版本）
 
 交互规则（当前实现）：
 - 下方词块池：点击某个词块后，该词块置灰不可再点，并把对应“已选 chip”追加到上方答案区
 - 上方答案区：点击 chip 可移除，词块池对应词块恢复可点；右侧撤回按钮移除最后一个 chip
 - 提交：将 chip 文本顺序拼接为答案，与 `unit.correctOptionId`（MVP 复用字段）对比得到对错
 
 说明：
 - 当前不做拖拽排序，先用“点选+撤回”跑通链路；后续可替换为可拖拽的 collection view
 - `tokensContainer` 做简单流式布局（超出自动换行），避免词块过长挤压
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        _tokenButtons = [NSMutableArray array];
        _tokenSlots = [NSMutableArray array];
        _tokenWidths = [NSMutableArray array];
        _tokenPlaceholders = [NSMutableArray array];
        _selectedChipButtons = [NSMutableArray array];

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 18;
        _cardView.layer.masksToBounds = YES;
        [self.rootView addSubview:_cardView];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.rootView);
        }];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = NSLocalizedString(@"Build the sentence", @"");
        _titleLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        [_cardView addSubview:_titleLabel];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(16);
            make.left.right.equalTo(self.cardView).inset(16);
        }];

        _selectedRowContainer = [[UIView alloc] init];
        _selectedRowContainer.backgroundColor = [UIColor clearColor];
        [_cardView addSubview:_selectedRowContainer];
        [_selectedRowContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(110);
            make.left.right.equalTo(self.cardView).inset(16);
            make.height.mas_equalTo(44);
        }];

        _selectedStack = [[UIStackView alloc] init];
        _selectedStack.axis = UILayoutConstraintAxisHorizontal;
        _selectedStack.alignment = UIStackViewAlignmentFill;
        _selectedStack.distribution = UIStackViewDistributionFill;
        _selectedStack.spacing = 10;
        [_selectedRowContainer addSubview:_selectedStack];
        [_selectedStack mas_makeConstraints:^(MASConstraintMaker *make) {
            // 让已选行内容“紧凑居中”，避免 stack 拉伸导致子视图宽度被撑开
            make.center.equalTo(self.selectedRowContainer);
            make.top.bottom.equalTo(self.selectedRowContainer);
            make.left.greaterThanOrEqualTo(self.selectedRowContainer);
            make.right.lessThanOrEqualTo(self.selectedRowContainer);
        }];

        _dividerLine = [[UIView alloc] init];
        _dividerLine.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];
        [_cardView addSubview:_dividerLine];
        [_dividerLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.cardView).inset(16);
            make.top.equalTo(self.selectedRowContainer.mas_bottom).offset(10);
            make.height.mas_equalTo(1);
        }];

        _tokensRowContainer = [[UIView alloc] init];
        _tokensRowContainer.backgroundColor = [UIColor clearColor];
        [_cardView addSubview:_tokensRowContainer];
        [_tokensRowContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.cardView).inset(16);
            make.top.greaterThanOrEqualTo(self.dividerLine.mas_bottom).offset(20);
            make.bottom.equalTo(self.cardView).offset(-34);
            make.height.mas_equalTo(44);
        }];

        _tokensStack = [[UIStackView alloc] init];
        _tokensStack.axis = UILayoutConstraintAxisHorizontal;
        _tokensStack.alignment = UIStackViewAlignmentFill;
        _tokensStack.distribution = UIStackViewDistributionFill;
        _tokensStack.spacing = 12;
        [_tokensRowContainer addSubview:_tokensStack];
        [_tokensStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.tokensRowContainer);
            make.top.bottom.equalTo(self.tokensRowContainer);
            make.left.greaterThanOrEqualTo(self.tokensRowContainer);
            make.right.lessThanOrEqualTo(self.tokensRowContainer);
        }];
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording scoring:(YTScoringService *)scoring {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording scoring:scoring];
    self.hasSubmitted = NO;
    [self.tokenButtons removeAllObjects];
    [self.tokenSlots removeAllObjects];
    [self.tokenWidths removeAllObjects];
    [self.tokenPlaceholders removeAllObjects];
    [self.selectedChipButtons removeAllObjects];

    for (UIView *v in self.selectedStack.arrangedSubviews) {
        [self.selectedStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    for (UIView *v in self.tokensStack.arrangedSubviews) {
        [self.tokensStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSArray<NSDictionary *> *tokens = unit.options ?: @[];
    UIFont *font = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    CGFloat minW = 44;
    CGFloat h = 44;

    for (NSInteger i = 0; i < tokens.count; i++) {
        NSDictionary *opt = tokens[i];
        NSString *text = opt[@"text"] ?: @"";
        if (text.length == 0) continue;

        UIView *slot = [[UIView alloc] init];
        slot.backgroundColor = [UIColor clearColor];
        [self.tokensStack addArrangedSubview:slot];
        [self.tokenSlots addObject:slot];

        CGSize sz = [text sizeWithAttributes:@{NSFontAttributeName: font}];
        CGFloat w = MAX(minW, sz.width + 28);
        [self.tokenWidths addObject:@(w)];
        [slot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(h);
            make.width.mas_equalTo(w);
        }];

        UIView *placeholder = [[UIView alloc] init];
        placeholder.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
        placeholder.layer.cornerRadius = 12;
        placeholder.layer.masksToBounds = YES;
        placeholder.hidden = YES;
        [slot addSubview:placeholder];
        [placeholder mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(slot);
        }];
        [self.tokenPlaceholders addObject:placeholder];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.layer.cornerRadius = 12;
        btn.layer.masksToBounds = YES;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
        btn.backgroundColor = [UIColor whiteColor];
        [btn setTitle:text forState:UIControlStateNormal];
        [btn setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        btn.titleLabel.font = font;
        [btn addTarget:self action:@selector(onTapTokenSlotButton:) forControlEvents:UIControlEventTouchUpInside];
        [slot addSubview:btn];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(slot);
        }];
        [self.tokenButtons addObject:btn];
    }

    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];
}

- (void)onTapTokenSlotButton:(UIButton *)btn {
    if (self.hasSubmitted) return;
    NSInteger idx = btn.tag;
    if (idx < 0 || idx >= self.tokenButtons.count) return;
    if (btn.hidden) return;

    // 底部 token 变占位块
    btn.hidden = YES;
    UIView *ph = (idx < self.tokenPlaceholders.count) ? self.tokenPlaceholders[idx] : nil;
    ph.hidden = NO;

    // 顶部加入 chip
    UIButton *chip = [UIButton buttonWithType:UIButtonTypeCustom];
    chip.tag = idx;
    chip.layer.cornerRadius = 12;
    chip.layer.masksToBounds = YES;
    chip.layer.borderWidth = 1;
    chip.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
    chip.backgroundColor = [UIColor whiteColor];
    [chip setTitle:btn.currentTitle ?: @"" forState:UIControlStateNormal];
    [chip setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
    chip.titleLabel.font = btn.titleLabel.font;
    [chip addTarget:self action:@selector(onTapSelectedChipButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.selectedStack addArrangedSubview:chip];
    [self.selectedChipButtons addObject:chip];
    // 要求：上方已选词块宽度与底部对应词块一致
    if (idx >= 0 && idx < self.tokenWidths.count) {
        CGFloat w = [self.tokenWidths[idx] doubleValue];
        [chip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(44);
            make.width.mas_equalTo(w);
        }];
    }

    [self updatePrimaryEnabled];
}

- (void)onTapSelectedChipButton:(UIButton *)chip {
    NSInteger idx = chip.tag;
    // 点击已选：放回到底部原位置（并做一个轻量动画）
    UIView *ph = (idx >= 0 && idx < self.tokenPlaceholders.count) ? self.tokenPlaceholders[idx] : nil;
    UIButton *token = nil;
    for (UIButton *t in self.tokenButtons) {
        if (t.tag == idx) { token = t; break; }
    }

    [UIView animateWithDuration:0.18 animations:^{
        chip.transform = CGAffineTransformMakeScale(0.92, 0.92);
        chip.alpha = 0.0;
    } completion:^(__unused BOOL finished) {
        [self.selectedStack removeArrangedSubview:chip];
        [chip removeFromSuperview];
        [self.selectedChipButtons removeObject:chip];

        if (ph) ph.hidden = YES;
        if (token) {
            token.hidden = NO;
            token.alpha = 0.0;
            [UIView animateWithDuration:0.18 animations:^{
                token.alpha = 1.0;
            }];
        }

        [self updatePrimaryEnabled];
    }];
}

- (void)updatePrimaryEnabled {
    NSInteger total = self.tokenButtons.count;
    NSInteger selected = self.selectedStack.arrangedSubviews.count;
    self.primaryState.enabled = (total > 0 && selected == total);
    [self emitPrimaryState];
}

- (void)resetBuildSentenceSelectionAnimated:(BOOL)animated {
    void (^apply)(void) = ^{
        // 清空顶部
        for (UIView *v in self.selectedStack.arrangedSubviews.copy) {
            [self.selectedStack removeArrangedSubview:v];
            [v removeFromSuperview];
        }
        [self.selectedChipButtons removeAllObjects];

        // 还原底部：显示 token，隐藏占位
        for (UIButton *t in self.tokenButtons) {
            t.hidden = NO;
            t.alpha = 1.0;
        }
        for (UIView *ph in self.tokenPlaceholders) {
            ph.hidden = YES;
        }

        self.hasSubmitted = NO;
        [self updatePrimaryEnabled];
    };

    if (!animated) {
        apply();
        return;
    }
    [UIView animateWithDuration:0.18 animations:^{
        self.selectedRowContainer.alpha = 0.0;
    } completion:^(__unused BOOL finished) {
        apply();
        self.selectedRowContainer.alpha = 1.0;
    }];
}

- (NSArray<NSString *> *)correctTokenTextsInOrder {
    // 目标：把 correctOptionId 的字符串拆成 token 序列（按 options 中的 token 做贪心匹配）
    NSString *correct = self.unit.correctOptionId ?: @"";
    if (correct.length == 0) return @[];
    NSMutableArray<NSString *> *tokenTexts = [NSMutableArray array];
    for (NSDictionary *d in (self.unit.options ?: @[])) {
        NSString *t = d[@"text"];
        if ([t isKindOfClass:[NSString class]] && t.length > 0) {
            [tokenTexts addObject:t];
        }
    }
    if (tokenTexts.count == 0) return @[];

    NSMutableArray<NSString *> *result = [NSMutableArray array];
    NSString *remain = correct;
    NSInteger safety = 0;
    while (remain.length > 0 && safety < 200) {
        safety += 1;
        NSString *best = nil;
        for (NSString *t in tokenTexts) {
            if ([remain hasPrefix:t]) {
                if (!best || t.length > best.length) best = t;
            }
        }
        if (!best) break;
        [result addObject:best];
        remain = [remain substringFromIndex:best.length];
    }
    return result;
}

- (void)applyResultStyleCorrect:(BOOL)ok {
    UIColor *blue = self.theme.primaryColor ?: [UIColor colorWithRed:0x11/255.0 green:0x7F/255.0 blue:0xEC/255.0 alpha:1.0];
    UIColor *redBorder = [theAppDelegate.window colorWithHexString:@"#FF9593" alpha:1];
    UIColor *redFill = [theAppDelegate.window colorWithHexString:@"#FFF0F1" alpha:1];
    UIColor *blueFill = [blue colorWithAlphaComponent:0.15];
    NSArray<NSString *> *correctTokens = ok ? @[] : [self correctTokenTextsInOrder];
    NSInteger i = 0;
    for (UIView *v in self.selectedStack.arrangedSubviews) {
        if (![v isKindOfClass:[UIButton class]]) continue;
        UIButton *b = (UIButton *)v;
        NSString *t = [b currentTitle] ?: @"";
        if (ok) {
            b.layer.borderWidth = 2;
            b.layer.borderColor = blue.CGColor;
            b.backgroundColor = blueFill;
        } else {
            BOOL positionCorrect = (i < correctTokens.count) ? [t isEqualToString:correctTokens[i]] : NO;
            if (positionCorrect) {
                // 选对的位置不标红：恢复默认描边
                b.layer.borderWidth = 1;
                b.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
                b.backgroundColor = [UIColor whiteColor];
            } else {
                b.layer.borderWidth = 2;
                b.layer.borderColor = redBorder.CGColor;
                b.backgroundColor = redFill;
            }
        }
        i += 1;
    }
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    if (self.selectedStack.arrangedSubviews.count != self.tokenButtons.count) {
        if (completion) completion(nil, [NSError errorWithDomain:@"YTBuildSentenceUnitView" code:5001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please complete the sentence", @"")}]);
        return;
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (UIView *v in self.selectedStack.arrangedSubviews) {
        if (![v isKindOfClass:[UIButton class]]) continue;
        NSString *t = [(UIButton *)v currentTitle] ?: @"";
        if (t.length) [parts addObject:t];
    }
    NSString *answer = [parts componentsJoinedByString:@""];
    // MVP：复用 correctOptionId 存“正确句子字符串”（接口化后建议改为结构化字段）
    NSString *correct = self.unit.correctOptionId ?: @"";
    BOOL ok = (correct.length > 0) ? [answer isEqualToString:correct] : YES;
    YTUnitSubmitResult *r = [[YTUnitSubmitResult alloc] init];
    r.isCorrect = ok;
    if (!ok) r.correctAnswerText = correct;
    self.completeSignalSatisfied = YES;
    self.hasSubmitted = YES;
    [self applyResultStyleCorrect:ok];
    if (completion) completion(r, nil);
}

- (void)resetAfterWrongAnswerIfNeeded {
    // 由容器在“答错弹窗”按钮点击后触发
    if (!self.hasSubmitted) return;
    [self resetBuildSentenceSelectionAnimated:YES];
}

@end

@interface YTCompleteDialogueUnitView : YTBaseUnitView
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *questionBubble;
@property (nonatomic, strong) UILabel *questionLabel;
@property (nonatomic, strong) UIButton *questionPlayButton;

@property (nonatomic, strong) UIView *answerBubble;
@property (nonatomic, strong) UIView *answerContentView;
@property (nonatomic, strong) UITextView *answerTextView; // 整句排版（含空缺占位）
@property (nonatomic, strong, nullable) CAShapeLayer *answerDashLayer;
@property (nonatomic, assign) NSRange answerBlankRange;
@property (nonatomic, copy, nullable) NSString *selectedTokenText;
@property (nonatomic, assign) NSInteger answerChipStyle; // 0: preSubmit 1: correct 2: wrong

@property (nonatomic, strong) UIView *optionsRow;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, strong) NSMutableArray<UIView *> *optionPlaceholders;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *optionWidths;
@property (nonatomic, copy, nullable) NSString *selectedOptionId;
@end

@implementation YTCompleteDialogueUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        _optionButtons = [NSMutableArray array];
        _optionPlaceholders = [NSMutableArray array];
        _optionWidths = [NSMutableArray array];

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 18;
        _cardView.layer.masksToBounds = YES;
        [self.rootView addSubview:_cardView];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.rootView);
        }];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        _titleLabel.text = NSLocalizedString(@"Complete the dialogue", @"");
        [_cardView addSubview:_titleLabel];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(16);
            make.left.right.equalTo(self.cardView).inset(16);
        }];

        // Question bubble (left)
        _questionBubble = [[UIView alloc] init];
        _questionBubble.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
        _questionBubble.layer.cornerRadius = 18;
        _questionBubble.layer.masksToBounds = YES;
        [_cardView addSubview:_questionBubble];
        [_questionBubble mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
            make.left.equalTo(self.cardView).offset(16);
            make.width.lessThanOrEqualTo(self.cardView).multipliedBy(0.78);
            // 高度由内容+内边距撑开
        }];

        _questionPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _questionPlayButton.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];
        _questionPlayButton.layer.cornerRadius = 14;
        _questionPlayButton.layer.masksToBounds = YES;
        UIImage *spk = nil;
        if (@available(iOS 13.0, *)) {
            spk = [UIImage systemImageNamed:@"speaker.wave.2.fill"];
        }
        [_questionPlayButton setImage:spk forState:UIControlStateNormal];
        _questionPlayButton.tintColor = [UIColor colorWithWhite:0.25 alpha:1];
        [_questionPlayButton addTarget:self action:@selector(onPlayQuestionAudio) forControlEvents:UIControlEventTouchUpInside];
        [_questionBubble addSubview:_questionPlayButton];
        [_questionPlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
            // 问题气泡内边距：上16左16下16右12
            make.right.equalTo(self.questionBubble).offset(-12);
            make.centerY.equalTo(self.questionBubble);
            make.width.height.mas_equalTo(28);
        }];

        _questionLabel = [[UILabel alloc] init];
        _questionLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1];
        _questionLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:15];
        _questionLabel.numberOfLines = 0;
        _questionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_questionBubble addSubview:_questionLabel];
        [_questionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.questionBubble).offset(16);
            make.right.equalTo(self.questionPlayButton.mas_left).offset(-12);
            make.top.equalTo(self.questionBubble).offset(16);
            make.bottom.equalTo(self.questionBubble).offset(-16);
        }];

        // Answer bubble (right)
        _answerBubble = [[UIView alloc] init];
        _answerBubble.backgroundColor = [UIColor colorWithRed:0xE9/255.0 green:0xF2/255.0 blue:0xFF/255.0 alpha:1.0];
        _answerBubble.layer.cornerRadius = 18;
        _answerBubble.layer.masksToBounds = YES;
        [_cardView addSubview:_answerBubble];
        [_answerBubble mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.questionBubble.mas_bottom).offset(26);
            make.right.equalTo(self.cardView).offset(-16);
            // 最大宽度限制仍保留；未到上限时由内容决定宽度
            make.width.lessThanOrEqualTo(self.cardView).multipliedBy(0.78);
            make.left.greaterThanOrEqualTo(self.cardView).offset(16);
            // 高度由内容+内边距撑开
        }];

        _answerContentView = [[UIView alloc] init];
        _answerContentView.backgroundColor = [UIColor clearColor];
        [_answerBubble addSubview:_answerContentView];
        // 回答气泡内边距：上16下16左8右16（高度由内容区撑开，避免拉伸 label 造成“看起来没留白”）
        [_answerContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.answerBubble).offset(16);
            make.bottom.equalTo(self.answerBubble).offset(-16);
            make.left.equalTo(self.answerBubble).offset(8);
            make.right.equalTo(self.answerBubble).offset(-16);
        }];

        _answerTextView = [[UITextView alloc] init];
        _answerTextView.backgroundColor = [UIColor clearColor];
        _answerTextView.scrollEnabled = NO;
        _answerTextView.editable = NO;
        _answerTextView.selectable = NO;
        _answerTextView.dataDetectorTypes = UIDataDetectorTypeNone;
        _answerTextView.textContainerInset = UIEdgeInsetsZero;
        _answerTextView.textContainer.lineFragmentPadding = 0;
        _answerTextView.textColor = [UIColor colorWithWhite:0.25 alpha:1];
        _answerTextView.font = [UIFont fontWithName:FONT_NAME_Semibold size:15];
        [_answerContentView addSubview:_answerTextView];
        [_answerTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.answerContentView);
        }];
        _answerBlankRange = NSMakeRange(NSNotFound, 0);
        _answerChipStyle = 0;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAnswerTextView:)];
        [_answerTextView addGestureRecognizer:tap];

        // Options row (bottom center)
        _optionsRow = [[UIView alloc] init];
        _optionsRow.backgroundColor = [UIColor clearColor];
        [_cardView addSubview:_optionsRow];
        [_optionsRow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.cardView);
            make.centerY.equalTo(self.cardView).offset(130);
            make.height.mas_equalTo(38);
            make.left.greaterThanOrEqualTo(self.cardView).offset(16);
            make.right.lessThanOrEqualTo(self.cardView).offset(-16);
        }];

        // 虚线会在 configure 时按实际布局计算绘制
    }
    return self;
}

- (UIImage *)chipImageWithText:(NSString *)text style:(NSInteger)style {
    UIFont *font = [UIFont fontWithName:FONT_NAME_Semibold size:15] ?: [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    CGSize tSize = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    CGFloat h = 38.0;
    CGFloat padX = 14.0;
    CGFloat w = MAX(44.0, tSize.width + padX * 2);

    UIColor *border = [theAppDelegate.window colorWithHexString:@"#D4D4E4" alpha:1];
    UIColor *fill = [UIColor whiteColor];
    if (style == 1) {
        border = self.theme.primaryColor ?: border;
        fill = [border colorWithAlphaComponent:0.18];
    } else if (style == 2) {
        border = [theAppDelegate.window colorWithHexString:@"#FF9593" alpha:1];
        fill = [theAppDelegate.window colorWithHexString:@"#FFF0F1" alpha:1];
    }

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, w, h) cornerRadius:10];
    [fill setFill];
    [path fill];
    [border setStroke];
    path.lineWidth = 2;
    [path stroke];
    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: BLACK_COLOR_1F};
    CGFloat textY = (h - tSize.height) / 2.0;
    [text drawInRect:CGRectMake(padX, textY, w - padX * 2, tSize.height) withAttributes:attrs];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img ?: [[UIImage alloc] init];
}

- (NSAttributedString *)answerAttributedStringForTemplate:(NSString *)tpl {
    UIFont *font = [UIFont fontWithName:FONT_NAME_Semibold size:15] ?: [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    UIColor *color = [UIColor colorWithWhite:0.25 alpha:1];
    NSDictionary *baseAttr = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};

    NSRange br = [tpl rangeOfString:@"__"];
    if (br.location == NSNotFound) {
        self.answerBlankRange = NSMakeRange(NSNotFound, 0);
        return [[NSAttributedString alloc] initWithString:tpl attributes:baseAttr];
    }

    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] init];
    NSString *pre = [tpl substringToIndex:br.location] ?: @"";
    NSString *suf = [tpl substringFromIndex:br.location + br.length] ?: @"";
    [att appendAttributedString:[[NSAttributedString alloc] initWithString:pre attributes:baseAttr]];

    if (self.selectedTokenText.length > 0) {
        NSTextAttachment *ta = [[NSTextAttachment alloc] init];
        UIImage *img = [self chipImageWithText:self.selectedTokenText style:self.answerChipStyle];
        ta.image = img;
        ta.bounds = CGRectMake(0, -3, img.size.width, 38);
        NSUInteger loc = att.length;
        [att appendAttributedString:[NSAttributedString attributedStringWithAttachment:ta]];
        self.answerBlankRange = NSMakeRange(loc, 1);
    } else {
        NSString *spaces = @"      ";
        NSUInteger loc = att.length;
        [att appendAttributedString:[[NSAttributedString alloc] initWithString:spaces attributes:baseAttr]];
        self.answerBlankRange = NSMakeRange(loc, spaces.length);
    }

    [att appendAttributedString:[[NSAttributedString alloc] initWithString:suf attributes:baseAttr]];
    return att;
}

- (void)onTapAnswerTextView:(UITapGestureRecognizer *)tap {
    if (self.selectedTokenText.length == 0) return;
    if (self.answerBlankRange.location == NSNotFound) return;
    CGPoint pt = [tap locationInView:self.answerTextView];
    UITextView *tv = self.answerTextView;
    NSLayoutManager *lm = tv.layoutManager;
    NSTextContainer *tc = tv.textContainer;
    CGPoint textPoint = CGPointMake(pt.x - tv.textContainerInset.left, pt.y - tv.textContainerInset.top);
    NSUInteger glyphIndex = [lm glyphIndexForPoint:textPoint inTextContainer:tc];
    NSUInteger charIndex = [lm characterIndexForGlyphAtIndex:glyphIndex];
    if (NSLocationInRange(charIndex, self.answerBlankRange)) {
        [self onTapAnswerChip];
    }
}

- (void)updateAnswerDashIfNeeded {
    if (self.answerBlankRange.location == NSNotFound) {
        [self.answerDashLayer removeFromSuperlayer];
        self.answerDashLayer = nil;
        return;
    }
    UITextView *tv = self.answerTextView;
    [tv layoutIfNeeded];
    NSLayoutManager *lm = tv.layoutManager;
    NSTextContainer *tc = tv.textContainer;
    if (!lm || !tc) return;
    
    NSRange glyphRange = [lm glyphRangeForCharacterRange:self.answerBlankRange actualCharacterRange:NULL];
    if (glyphRange.location == NSNotFound || glyphRange.length == 0) return;
    
    CGRect rect = [lm boundingRectForGlyphRange:glyphRange inTextContainer:tc];
    CGFloat x1 = CGRectGetMinX(rect);
    CGFloat x2 = CGRectGetMaxX(rect);
    
    // y 取“所在行的底部”，不要用 attachment 自己的 rect（首帧容易落到行中间）
    NSRange lineGlyphRange = NSMakeRange(0, 0);
    CGRect lineUsedRect = [lm lineFragmentUsedRectForGlyphAtIndex:glyphRange.location effectiveRange:&lineGlyphRange];
    CGFloat y = CGRectGetMaxY(lineUsedRect);
    if (x2 - x1 < 20) x2 = x1 + 44;
    
    if (!self.answerDashLayer) {
        self.answerDashLayer = [CAShapeLayer layer];
        self.answerDashLayer.strokeColor = [UIColor colorWithWhite:0.75 alpha:1].CGColor;
        self.answerDashLayer.fillColor = [UIColor clearColor].CGColor;
        self.answerDashLayer.lineWidth = 1.0;
        self.answerDashLayer.lineDashPattern = @[@3, @3];
        [tv.layer addSublayer:self.answerDashLayer];
    }
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(x1, y)];
    [p addLineToPoint:CGPointMake(x2, y)];
    self.answerDashLayer.path = p.CGPath;
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording scoring:(YTScoringService *)scoring {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording scoring:scoring];
    self.selectedOptionId = nil;
    self.selectedTokenText = nil;
    self.answerChipStyle = 0;
    self.answerBlankRange = NSMakeRange(NSNotFound, 0);

    self.titleLabel.text = NSLocalizedString(@"Complete the dialogue", @"");
    self.questionLabel.text = unit.titleCN ?: @"";

    // 解析回答模板：默认用 "__" 占位（避免依赖特定中文模板）
    NSString *tpl = unit.answerTemplateCN ?: @"__";
    self.answerTextView.attributedText = [self answerAttributedStringForTemplate:tpl];

    // 自适应布局后更新虚线（确保换行正确）
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self updateAnswerDashIfNeeded];
    });

    // 主按钮：未选时不可提交
    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    // 重建选项
    for (UIView *v in self.optionsRow.subviews) {
        [v removeFromSuperview];
    }
    [self.optionButtons removeAllObjects];
    [self.optionPlaceholders removeAllObjects];
    [self.optionWidths removeAllObjects];

    NSArray<NSDictionary *> *opts = unit.options ?: @[];
    CGFloat gap = 12;
    UIView *prev = nil;
    for (NSInteger i = 0; i < opts.count; i++) {
        NSDictionary *opt = opts[i];
        NSString *optId = opt[@"id"] ?: [NSString stringWithFormat:@"%ld", (long)i];
        NSString *text = opt[@"text"] ?: @"";

        UIView *slot = [[UIView alloc] init];
        slot.backgroundColor = [UIColor clearColor];
        [self.optionsRow addSubview:slot];

        UIFont *f = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        CGSize sz = [text sizeWithAttributes:@{NSFontAttributeName: f}];
        CGFloat w = MAX(44, sz.width + 28);
        [self.optionWidths addObject:@(w)];

        UIView *ph = [[UIView alloc] init];
        ph.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        ph.layer.cornerRadius = 10;
        ph.layer.masksToBounds = YES;
        ph.hidden = YES;
        [slot addSubview:ph];
        [ph mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(slot);
        }];
        [self.optionPlaceholders addObject:ph];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.accessibilityIdentifier = optId;
        btn.layer.cornerRadius = 10;
        btn.layer.masksToBounds = YES;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
        btn.backgroundColor = [UIColor whiteColor];
        [btn setTitle:text forState:UIControlStateNormal];
        [btn setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        btn.titleLabel.font = f;
        [btn addTarget:self action:@selector(onSelectCompleteDialogueOption:) forControlEvents:UIControlEventTouchUpInside];
        [slot addSubview:btn];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(slot);
        }];
        [self.optionButtons addObject:btn];

        [slot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.optionsRow);
            make.width.mas_equalTo(w);
            make.height.mas_equalTo(38);
            if (prev) {
                make.left.equalTo(prev.mas_right).offset(gap);
            } else {
                make.left.equalTo(self.optionsRow);
            }
        }];
        prev = slot;
    }
    if (prev) {
        [prev mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.optionsRow);
        }];
    }
}

- (void)onPlayQuestionAudio {
    if (self.unit.audioURLString.length == 0) return;
    [self.audio playURLString:self.unit.audioURLString completion:nil];
}

- (void)onSelectCompleteDialogueOption:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= self.unit.options.count) return;
    NSDictionary *opt = self.unit.options[idx];
    self.selectedOptionId = sender.accessibilityIdentifier ?: opt[@"id"];
    NSString *txt = opt[@"text"] ?: @"";
    NSString *tpl = self.unit.answerTemplateCN ?: @"__";
    self.selectedTokenText = txt;
    self.answerChipStyle = 0;
    self.answerTextView.attributedText = [self answerAttributedStringForTemplate:tpl];
    // 选择后虚线仍需存在
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self updateAnswerDashIfNeeded];
    });

    // 底部：被选中的那个位置变灰占位，其它保持可选
    for (NSInteger i = 0; i < self.optionButtons.count; i++) {
        UIButton *btn = self.optionButtons[i];
        BOOL sel = [btn.accessibilityIdentifier isEqualToString:self.selectedOptionId ?: @""];
        btn.hidden = sel;
        if (i < self.optionPlaceholders.count) {
            self.optionPlaceholders[i].hidden = !sel;
        }
    }
    self.primaryState.enabled = (self.selectedOptionId.length > 0);
    [self emitPrimaryState];
}

- (void)onTapAnswerChip {
    // 退回到底部（恢复空缺虚线）
    self.selectedOptionId = nil;
    NSString *tpl = self.unit.answerTemplateCN ?: @"__";
    self.selectedTokenText = nil;
    self.answerChipStyle = 0;
    self.answerTextView.attributedText = [self answerAttributedStringForTemplate:tpl];
    [self updateAnswerDashIfNeeded];
    for (NSInteger i = 0; i < self.optionButtons.count; i++) {
        self.optionButtons[i].hidden = NO;
        if (i < self.optionPlaceholders.count) self.optionPlaceholders[i].hidden = YES;
    }
    self.primaryState.enabled = NO;
    [self emitPrimaryState];
}

- (void)applySubmitFeedbackCorrect:(BOOL)isCorrect {
    UIColor *correctC = self.theme.primaryColor ?: (self.theme.correctColor ?: [UIColor colorWithRed:0.2 green:0.75 blue:0.4 alpha:1]);
    UIColor *wrongBorderC = [theAppDelegate.window colorWithHexString:@"#FF9593" alpha:1];
    UIColor *wrongFillC = [theAppDelegate.window colorWithHexString:@"#FFF0F1" alpha:1];
    (void)correctC; (void)wrongBorderC; (void)wrongFillC;
    if (self.selectedTokenText.length == 0) return;
    self.answerChipStyle = isCorrect ? 1 : 2;
    NSString *tpl = self.unit.answerTemplateCN ?: @"__";
    self.answerTextView.attributedText = [self answerAttributedStringForTemplate:tpl];
    // 选择后虚线仍需存在
    [self updateAnswerDashIfNeeded];
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    if (self.selectedOptionId.length == 0) {
        if (completion) completion(nil, [NSError errorWithDomain:@"YTCompleteDialogueUnitView" code:4001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please choose an option", @"")}]);
        return;
    }
    BOOL correct = [self.selectedOptionId isEqualToString:self.unit.correctOptionId ?: @""];
    YTUnitSubmitResult *r = [[YTUnitSubmitResult alloc] init];
    r.isCorrect = correct;
    if (!correct) {
        NSString *answer = nil;
        for (NSDictionary *opt in self.unit.options) {
            NSString *oid = opt[@"id"];
            if ([oid isEqual:self.unit.correctOptionId]) {
                answer = opt[@"text"];
                break;
            }
        }
        r.correctAnswerText = answer ?: @"";
    }
    self.completeSignalSatisfied = YES;
    [self applySubmitFeedbackCorrect:correct];
    if (completion) completion(r, nil);
}

@end

#pragma mark - Factory

@implementation YTUnitViewFactory

+ (id<YTUnitViewProtocol>)buildViewForUnit:(YTUnit *)unit {
    /**
     映射规则（MVP）：
     - vocab/dialogue_line：同为“跟读/录音评分”交互，复用 `YTPronounceUnitView`
     - grammar：Usage/Grammar 引导页
     - exercise：按 exerciseType 分发到不同 Presenter
     *
     扩展方式：
     - 新增题型时：新增 Presenter 类，并在此处补一条分支
     */
    if (unit.unitType == YTUnitTypeVocab || unit.unitType == YTUnitTypeDialogueLine) {
        return [[YTPronounceUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypeGrammar) {
        return [[YTGrammarUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypeExercise) {
        if (unit.exerciseType == YTExerciseTypeListenChooseImage || unit.exerciseType == YTExerciseTypeLookChooseWord) {
            return [[YTChoiceExerciseUnitView alloc] init];
        }
        if (unit.exerciseType == YTExerciseTypeChooseWordFillBlank) {
            return [[YTFillBlankUnitView alloc] init];
        }
        if (unit.exerciseType == YTExerciseTypeListenChooseResponse) {
            return [[YTListenResponseUnitView alloc] init];
        }
        if (unit.exerciseType == YTExerciseTypeBuildSentence) {
            return [[YTBuildSentenceUnitView alloc] init];
        }
        if (unit.exerciseType == YTExerciseTypeCompleteDialogue) {
            return [[YTCompleteDialogueUnitView alloc] init];
        }
        return [[YTChoiceExerciseUnitView alloc] init];
    }
    return [[YTBaseUnitView alloc] init];
}

@end

