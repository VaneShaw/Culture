//
//  YTBuildSentenceUnitView.m
//  YiTongProject
//

#import "YTBuildSentenceUnitView.h"
#import "YTInternalUnitViewSupport.h"
#import "YTAnswerEvaluating.h"
#import "YTPronounceEvaluating.h"
#import "HeaderConfig.h"

@interface YTBuildSentenceUnitView ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *selectedRowContainer;
@property (nonatomic, strong) UIView *selectedFlowView;
@property (nonatomic, strong) UIView *dividerLine;
@property (nonatomic, strong) UIView *tokensRowContainer;
@property (nonatomic, strong) UIView *tokensFlowView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *tokenButtons;
@property (nonatomic, strong) NSMutableArray<UIView *> *tokenSlots;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *tokenWidths;
@property (nonatomic, strong) NSMutableArray<UIView *> *tokenPlaceholders;
@property (nonatomic, strong) NSMutableArray<UIButton *> *selectedChipButtons;
@property (nonatomic, assign) BOOL hasSubmitted;
@property (nonatomic, assign) CGFloat lastTokensRowHeight;
@property (nonatomic, assign) CGFloat lastSelectedRowHeight;

- (void)requestBuildSentenceFlowLayout;
- (void)layoutBuildSentenceFlow;
@end


@implementation YTBuildSentenceUnitView

/**
 句子组装 Presenter（MVP 交互版本）
 
 交互规则（当前实现）：
 - 下方词块池：点击某个词块后，该词块置灰不可再点，并把对应“已选 chip”追加到上方答案区
 - 上方答案区：点击 chip 可移除，词块池对应词块恢复可点；右侧撤回按钮移除最后一个 chip
 - 提交：将 chip 文本顺序拼接为答案，与 `unit.correctSentenceText` 对比得到对错
 
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
            // 容器高度会根据 flow 布局自动调整
            make.height.mas_equalTo(44);
        }];

        _selectedFlowView = [[UIView alloc] init];
        _selectedFlowView.backgroundColor = [UIColor clearColor];
        [_selectedRowContainer addSubview:_selectedFlowView];
        [_selectedFlowView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.selectedRowContainer);
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
            // 容器高度会根据 flow 布局自动调整
            make.height.mas_equalTo(44);
        }];

        _tokensFlowView = [[UIView alloc] init];
        _tokensFlowView.backgroundColor = [UIColor clearColor];
        [_tokensRowContainer addSubview:_tokensFlowView];
        [_tokensFlowView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.tokensRowContainer);
        }];

        // flow 高度缓存：避免 layoutSubviews 里频繁 mas_updateConstraints 触发布局抖动
        self.lastTokensRowHeight = 44.0;
        self.lastSelectedRowHeight = 44.0;
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording pronounceEvaluator:pronounceEvaluator answerEvaluator:answerEvaluator];
    self.hasSubmitted = NO;
    [self.tokenButtons removeAllObjects];
    [self.tokenSlots removeAllObjects];
    [self.tokenWidths removeAllObjects];
    [self.tokenPlaceholders removeAllObjects];
    [self.selectedChipButtons removeAllObjects];

    for (UIView *v in self.selectedFlowView.subviews) {
        [v removeFromSuperview];
    }
    for (UIView *v in self.tokensFlowView.subviews) {
        [v removeFromSuperview];
    }

    NSArray<NSDictionary *> *tokens = unit.options ?: @[];
    UIFont *font = [UIFont fontWithName:FONT_NAME_Semibold size:16] ?: [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    CGFloat minW = 44;

    for (NSInteger i = 0; i < tokens.count; i++) {
        NSDictionary *opt = tokens[i];
        NSString *text = opt[@"text"] ?: @"";
        if (text.length == 0) continue;

        UIView *slot = [[UIView alloc] init];
        slot.backgroundColor = [UIColor clearColor];
        slot.translatesAutoresizingMaskIntoConstraints = YES; // 使用 frame flow 布局
        [self.tokensFlowView addSubview:slot];
        [self.tokenSlots addObject:slot];

        CGSize sz = [text sizeWithAttributes:@{NSFontAttributeName: font}];
        CGFloat w = MAX(minW, sz.width + 28);
        [self.tokenWidths addObject:@(w)];

        UIView *placeholder = [[UIView alloc] init];
        // 选项被点到上方作答区后，原位置留下的占位块
        placeholder.backgroundColor = [UIColor colorWithRed:0xF5 / 255.0 green:0xF5 / 255.0 blue:0xF5 / 255.0 alpha:1];
        placeholder.layer.cornerRadius = 12;
        placeholder.layer.masksToBounds = YES;
        placeholder.hidden = YES;
        [slot addSubview:placeholder];
        placeholder.translatesAutoresizingMaskIntoConstraints = YES;
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
        btn.translatesAutoresizingMaskIntoConstraints = YES;
        [self.tokenButtons addObject:btn];
    }

    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    {
        NSString *instr = [unit yt_resolvedStemInstructionText];
        self.titleLabel.text = instr.length ? instr : NSLocalizedString(@"Build the sentence", @"");
    }

    [self requestBuildSentenceFlowLayout];
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
    chip.translatesAutoresizingMaskIntoConstraints = YES;
    [self.selectedFlowView addSubview:chip];
    [self.selectedChipButtons addObject:chip];

    [self updatePrimaryEnabled];
    [self requestBuildSentenceFlowLayout];
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
        [self requestBuildSentenceFlowLayout];
    }];
}

- (void)updatePrimaryEnabled {
    NSInteger total = self.tokenButtons.count;
    NSInteger selected = self.selectedChipButtons.count;
    self.primaryState.enabled = (total > 0 && selected == total);
    [self emitPrimaryState];
}

- (void)resetBuildSentenceSelectionAnimated:(BOOL)animated {
    void (^apply)(void) = ^{
        // 清空顶部
        for (UIView *v in self.selectedFlowView.subviews.copy) {
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
        [self requestBuildSentenceFlowLayout];
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
    // 目标：把正确句子拆成 token 序列（按 options 中的 token 做贪心匹配）
    NSString *correct = self.unit.correctSentenceText ?: @"";
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
    for (UIButton *b in self.selectedChipButtons) {
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
    if (self.selectedChipButtons.count != self.tokenButtons.count) {
        if (completion) completion(nil, [NSError errorWithDomain:@"YTBuildSentenceUnitView" code:5001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please complete the sentence", @"")}]);
        return;
    }
    NSMutableArray<NSString *> *ordered = [NSMutableArray array];
    for (UIButton *b in self.selectedChipButtons) {
        [ordered addObject:[b currentTitle] ?: @""];
    }
    NSDictionary *answerPayload = YTAnswerPayloadForOrderedTokenTexts([ordered copy]);
    __weak typeof(self) weakSelf = self;
    [self evaluateAnswerPayload:answerPayload completion:^(YTUnitSubmitResult * _Nullable r, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        BOOL ok = r.isCorrect;
        self.completeSignalSatisfied = ok;
        self.hasSubmitted = YES;
        [self applyResultStyleCorrect:ok];
        if (completion) completion(r, error);
    }];
}

- (void)applyRestoredAnswerSnapshot:(NSDictionary *)snapshot {
    NSArray *texts = YTOrderedTokenTextsFromPayload(snapshot);
    if (![texts isKindOfClass:[NSArray class]] || texts.count == 0) return;
    for (id t in texts) {
        if (![t isKindOfClass:[NSString class]]) continue;
        NSString *txt = (NSString *)t;
        for (UIButton *btn in self.tokenButtons) {
            if (btn.hidden) continue;
            if ([[btn currentTitle] isEqualToString:txt]) {
                [self onTapTokenSlotButton:btn];
                break;
            }
        }
    }
    if (self.selectedChipButtons.count != self.tokenButtons.count) return;
    self.hasSubmitted = YES;
    [self applyResultStyleCorrect:YES];
    self.completeSignalSatisfied = YES;
    self.primaryState.kind = YTUnitPrimaryKindContinue;
    self.primaryState.title = @"Talk_Continue";
    self.primaryState.enabled = YES;
    [self emitPrimaryState];
    [self requestBuildSentenceFlowLayout];
}

- (void)resetAfterWrongAnswerIfNeeded {
    // 由容器在“答错弹窗”按钮点击后触发
    if (!self.hasSubmitted) return;
    [self resetBuildSentenceSelectionAnimated:YES];
}

- (void)requestBuildSentenceFlowLayout {
    // YTBuildSentenceUnitView 不是 UIView（继承 NSObject），需要对 rootView 触发布局并在下一轮计算 flow 坐标
    [self.rootView setNeedsLayout];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self layoutBuildSentenceFlow];
    });
}

- (void)layoutBuildSentenceFlow {
    // 注意：selectedFlowView/tokensFlowView 内子视图使用 frame 布局，避免 UIStackView 不支持换行导致的挤压。
    const CGFloat chipH = 44.0;
    const CGFloat tokenH = 44.0;
    const CGFloat tokenSpacingX = 12.0;
    const CGFloat tokenRowSpacingY = 12.0;
    const CGFloat chipSpacingX = 10.0;
    const CGFloat chipRowSpacingY = 10.0;

    // 1) tokensFlowView：底部词块池（含占位块）
    CGFloat tokensW = CGRectGetWidth(self.tokensFlowView.bounds);
    if (tokensW > 0 && self.tokenSlots.count == self.tokenWidths.count &&
        self.tokenButtons.count == self.tokenWidths.count &&
        self.tokenPlaceholders.count == self.tokenWidths.count) {
        CGFloat x = 0;
        CGFloat y = 0;
        CGFloat rowMaxH = 0;
        for (NSInteger i = 0; i < self.tokenSlots.count; i++) {
            UIView *slot = self.tokenSlots[i];
            CGFloat w = [self.tokenWidths[i] doubleValue];
            if (w <= 0) w = 44;

            if (x > 0 && (x + w) > tokensW) {
                x = 0;
                y += rowMaxH + tokenRowSpacingY;
                rowMaxH = 0;
            }
            rowMaxH = MAX(rowMaxH, tokenH);

            slot.frame = CGRectMake(x, y, w, tokenH);

            UIView *ph = self.tokenPlaceholders[i];
            UIButton *btn = self.tokenButtons[i];
            ph.frame = slot.bounds;
            btn.frame = slot.bounds;

            x += w + tokenSpacingX;
        }
        CGFloat requiredH = y + tokenH;
        requiredH = MAX(44.0, requiredH);
        if (fabs(requiredH - self.lastTokensRowHeight) > 0.5) {
            self.lastTokensRowHeight = requiredH;
            [self.tokensRowContainer mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(requiredH);
            }];
        }
    }

    // 2) selectedFlowView：上方已选 chip
    CGFloat selectedW = CGRectGetWidth(self.selectedFlowView.bounds);
    if (selectedW > 0) {
        CGFloat x = 0;
        CGFloat y = 0;
        CGFloat rowMaxH = 0;
        for (UIButton *chip in self.selectedChipButtons) {
            NSInteger idx = chip.tag;
            CGFloat w = (idx >= 0 && idx < self.tokenWidths.count) ? [self.tokenWidths[idx] doubleValue] : 44.0;
            if (w <= 0) w = 44.0;

            if (x > 0 && (x + w) > selectedW) {
                x = 0;
                y += rowMaxH + chipRowSpacingY;
                rowMaxH = 0;
            }
            rowMaxH = MAX(rowMaxH, chipH);

            chip.frame = CGRectMake(x, y, w, chipH);
            x += w + chipSpacingX;
        }
        CGFloat requiredH = y + chipH;
        requiredH = MAX(44.0, requiredH);
        if (fabs(requiredH - self.lastSelectedRowHeight) > 0.5) {
            self.lastSelectedRowHeight = requiredH;
            [self.selectedRowContainer mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(requiredH);
            }];
        }
    }
}

@end

