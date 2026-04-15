//
//  YTFillBlankUnitView.m
//

#import "YTFillBlankUnitView.h"
#import "HeaderConfig.h"
#import "YTInternalUnitViewSupport.h"
#import "YTUnitViewProtocol.h"

/// 接口 `options[].id` 可能为 NSNumber 或 NSString，统一成字符串再比较/存储，避免取消后无法再选同一项
static NSString *YTFillBlankNormalizeOptionId(id raw, NSInteger fallbackIndex) {
    if (raw == nil || raw == [NSNull null]) {
        return [NSString stringWithFormat:@"idx_%ld", (long)fallbackIndex];
    }
    if ([raw isKindOfClass:[NSString class]]) {
        return [(NSString *)raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([raw isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)raw stringValue];
    }
    return [[NSString stringWithFormat:@"%@", raw] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@interface YTFillBlankUnitViewLegacyInternal ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *sentenceRow;
@property (nonatomic, strong) UILabel *prefixLabel;
@property (nonatomic, strong) UILabel *suffixLabel;
@property (nonatomic, strong) UILabel *blankWordLabel;
@property (nonatomic, strong) UIView *blankWrap;
@property (nonatomic, strong) UIView *blankLine;
@property (nonatomic, strong) UIView *optionsRow;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, copy, nullable) NSString *selectedOptionId;

/// 多空：`sentence_template` 中 `__` 的个数
@property (nonatomic, assign) NSInteger fillBlankSlotCount;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedFillOptionIdsOrdered;
@property (nonatomic, assign) NSInteger currentFillSlotIndex;
@property (nonatomic, strong) NSMutableArray<UILabel *> *multiBlankWordLabels;
@property (nonatomic, strong) NSMutableArray<UIView *> *multiBlankWraps;
/// 单空：点击下划线上的占位区可清空已选，便于重选
@property (nonatomic, strong) UITapGestureRecognizer *singleBlankClearTap;
@end

@implementation YTFillBlankUnitViewLegacyInternal

- (instancetype)init {
    self = [super init];
    if (self) {
        _optionButtons = [NSMutableArray array];
        _fillBlankSlotCount = 1;
        _selectedFillOptionIdsOrdered = [NSMutableArray array];
        _multiBlankWordLabels = [NSMutableArray array];
        _multiBlankWraps = [NSMutableArray array];

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
            make.height.mas_greaterThanOrEqualTo(44);
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

- (void)yt_clearSentenceRow {
    for (UIView *v in self.sentenceRow.subviews) {
        [v removeFromSuperview];
    }
    self.prefixLabel = nil;
    self.suffixLabel = nil;
    self.blankWordLabel = nil;
    self.blankLine = nil;
    self.blankWrap = nil;
    [self.multiBlankWordLabels removeAllObjects];
    [self.multiBlankWraps removeAllObjects];
}

- (void)yt_rebuildSingleBlankWithStem:(NSString *)stem {
    [self yt_clearSentenceRow];

    NSRange blankRange = [stem rangeOfString:@"__"];
    if (blankRange.location != NSNotFound) {
        NSString *pre = [stem substringToIndex:blankRange.location];
        NSString *suf = [stem substringFromIndex:blankRange.location + blankRange.length];
        self.prefixLabel = [[UILabel alloc] init];
        self.prefixLabel.textColor = BLACK_COLOR_1F;
        self.prefixLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        self.prefixLabel.text = pre.length ? pre : @"";
        [self.sentenceRow addSubview:self.prefixLabel];

        self.blankWrap = [[UIView alloc] init];
        self.blankWrap.backgroundColor = [UIColor clearColor];
        [self.sentenceRow addSubview:self.blankWrap];

        self.blankWordLabel = [[UILabel alloc] init];
        self.blankWordLabel.textAlignment = NSTextAlignmentCenter;
        self.blankWordLabel.textColor = BLACK_COLOR_1F;
        self.blankWordLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        self.blankWordLabel.text = @"";
        [self.blankWrap addSubview:self.blankWordLabel];

        self.blankLine = [[UIView alloc] init];
        self.blankLine.backgroundColor = [UIColor colorWithWhite:0.78 alpha:1];
        [self.blankWrap addSubview:self.blankLine];

        self.suffixLabel = [[UILabel alloc] init];
        self.suffixLabel.textColor = BLACK_COLOR_1F;
        self.suffixLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        NSString *trim = [suf stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.suffixLabel.text = (trim.length > 0) ? trim : @"？";
        [self.sentenceRow addSubview:self.suffixLabel];

        [self.prefixLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self.sentenceRow);
        }];
        self.blankWrap.userInteractionEnabled = YES;
        if (!self.singleBlankClearTap) {
            self.singleBlankClearTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapSingleBlankWrap:)];
        }
        [self.blankWrap addGestureRecognizer:self.singleBlankClearTap];

        [self.blankWrap mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.prefixLabel.mas_right).offset(6);
            make.top.equalTo(self.sentenceRow);
            make.width.mas_equalTo(54);
            make.height.mas_equalTo(34);
        }];
        [self.suffixLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.blankWrap.mas_right).offset(6);
            make.top.equalTo(self.sentenceRow);
            make.right.lessThanOrEqualTo(self.sentenceRow);
        }];
        [self.blankWordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self.blankWrap);
            make.bottom.equalTo(self.blankLine.mas_top).offset(-3);
        }];
        [self.blankLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.blankWrap);
            // 下划线相对占位区底边上移，与两侧中文基线更齐
            make.bottom.equalTo(self.blankWrap).offset(-10);
            make.height.mas_equalTo(1);
        }];
        [self.sentenceRow mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.blankWrap.mas_bottom);
        }];
    } else {
        self.prefixLabel = [[UILabel alloc] init];
        self.prefixLabel.textColor = BLACK_COLOR_1F;
        self.prefixLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        self.prefixLabel.numberOfLines = 0;
        self.prefixLabel.text = stem.length ? stem : @"";
        [self.sentenceRow addSubview:self.prefixLabel];
        [self.prefixLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.sentenceRow);
        }];
    }
}

- (void)yt_rebuildMultiBlankWithParts:(NSArray<NSString *> *)parts {
    [self yt_clearSentenceRow];
    NSInteger blankCount = (NSInteger)parts.count - 1;
    if (blankCount < 1) {
        [self yt_rebuildSingleBlankWithStem:[parts componentsJoinedByString:@""]];
        return;
    }

    NSInteger blankSlotIndex = 0;
    UIView *prev = nil;
    for (NSInteger i = 0; i < parts.count; i++) {
        NSString *seg = parts[i];
        if (seg.length > 0) {
            UILabel *segLab = [[UILabel alloc] init];
            segLab.textColor = BLACK_COLOR_1F;
            segLab.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
            segLab.numberOfLines = 0;
            segLab.text = seg;
            [self.sentenceRow addSubview:segLab];
            [segLab mas_makeConstraints:^(MASConstraintMaker *make) {
                if (prev) {
                    make.left.equalTo(prev.mas_right).offset(4);
                } else {
                    make.left.equalTo(self.sentenceRow);
                }
                make.top.equalTo(self.sentenceRow);
            }];
            prev = segLab;
        }
        if (i + 1 < parts.count) {
            UIView *wrap = [[UIView alloc] init];
            wrap.backgroundColor = [UIColor clearColor];
            wrap.layer.cornerRadius = 4;
            wrap.tag = blankSlotIndex;
            wrap.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapBlank = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapMultiBlankSlot:)];
            [wrap addGestureRecognizer:tapBlank];
            blankSlotIndex += 1;
            [self.sentenceRow addSubview:wrap];
            [self.multiBlankWraps addObject:wrap];

            UILabel *wlab = [[UILabel alloc] init];
            wlab.textAlignment = NSTextAlignmentCenter;
            wlab.textColor = BLACK_COLOR_1F;
            wlab.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
            wlab.text = @"";
            [wrap addSubview:wlab];
            [self.multiBlankWordLabels addObject:wlab];

            UIView *line = [[UIView alloc] init];
            line.backgroundColor = [UIColor colorWithWhite:0.78 alpha:1];
            [wrap addSubview:line];

            [wlab mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.equalTo(wrap);
                make.bottom.equalTo(line.mas_top).offset(-3);
            }];
            [line mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(wrap);
                make.bottom.equalTo(wrap).offset(-10);
                make.height.mas_equalTo(1);
            }];
            CGFloat w = MAX(54, 44);
            [wrap mas_makeConstraints:^(MASConstraintMaker *make) {
                if (prev) {
                    make.left.equalTo(prev.mas_right).offset(4);
                } else {
                    make.left.equalTo(self.sentenceRow);
                }
                make.top.equalTo(self.sentenceRow);
                make.width.mas_greaterThanOrEqualTo(w);
                make.height.mas_equalTo(34);
            }];
            prev = wrap;
        }
    }
    if (prev) {
        [prev mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.lessThanOrEqualTo(self.sentenceRow);
        }];
        [self.sentenceRow mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(prev.mas_bottom);
        }];
    }
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording pronounceEvaluator:pronounceEvaluator answerEvaluator:answerEvaluator];
    self.selectedOptionId = nil;
    [self.selectedFillOptionIdsOrdered removeAllObjects];
    self.currentFillSlotIndex = 0;

    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    {
        NSString *instr = [unit yt_resolvedStemInstructionText];
        self.titleLabel.text = instr.length ? instr : NSLocalizedString(@"Choose the correct word", @"");
    }

    NSString *stem = unit.titleCN ?: @"";
    NSArray<NSString *> *parts = [stem componentsSeparatedByString:@"__"];
    NSInteger blankSlots = (NSInteger)parts.count - 1;
    if (blankSlots < 1) {
        blankSlots = 1;
    }
    self.fillBlankSlotCount = blankSlots;

    if (self.fillBlankSlotCount <= 1) {
        [self yt_rebuildSingleBlankWithStem:stem];
        self.blankWordLabel.text = @"";
    } else {
        for (NSInteger i = 0; i < self.fillBlankSlotCount; i++) {
            [self.selectedFillOptionIdsOrdered addObject:@""];
        }
        [self yt_rebuildMultiBlankWithParts:parts];
    }

    for (UIView *v in self.optionsRow.subviews) {
        [v removeFromSuperview];
    }
    [self.optionButtons removeAllObjects];

    NSArray<NSDictionary *> *opts = unit.options ?: @[];
    CGFloat gap = 12;
    UIButton *prev = nil;
    for (NSInteger i = 0; i < opts.count; i++) {
        NSDictionary *opt = opts[i];
        NSString *optId = YTFillBlankNormalizeOptionId(opt[@"id"], i);
        if (optId.length == 0) {
            optId = [NSString stringWithFormat:@"idx_%ld", (long)i];
        }
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
    for (UIButton *btn in self.optionButtons) {
        btn.enabled = YES;
    }
    if (self.fillBlankSlotCount > 1) {
        [self yt_syncCurrentFillSlotIndexToFirstEmpty];
        [self yt_restyleMultiBlankOptionButtons];
    }
}

- (BOOL)yt_allFillSlotsSatisfied {
    if (self.fillBlankSlotCount <= 1) {
        return self.selectedOptionId.length > 0;
    }
    if (self.selectedFillOptionIdsOrdered.count != self.fillBlankSlotCount) {
        return NO;
    }
    for (NSString *s in self.selectedFillOptionIdsOrdered) {
        if (s.length == 0) return NO;
    }
    return YES;
}

/// 多空：第一个未填的槽位（用于内部状态）
- (void)yt_syncCurrentFillSlotIndexToFirstEmpty {
    for (NSInteger i = 0; i < self.fillBlankSlotCount; i++) {
        if (i < (NSInteger)self.selectedFillOptionIdsOrdered.count && self.selectedFillOptionIdsOrdered[i].length == 0) {
            self.currentFillSlotIndex = i;
            return;
        }
    }
    self.currentFillSlotIndex = self.fillBlankSlotCount;
}

/// 多空：下方选项是否与上方某一空绑定（提交前样式）
- (void)yt_restyleMultiBlankOptionButtons {
    UIColor *selBorder = [theAppDelegate.window colorWithHexString:@"#D4D4E4" alpha:1];
    UIColor *defBorder = [UIColor colorWithWhite:0.85 alpha:1];
    for (UIButton *btn in self.optionButtons) {
        btn.enabled = YES;
        btn.userInteractionEnabled = YES;
        NSString *bid = YTFillBlankNormalizeOptionId(btn.accessibilityIdentifier, btn.tag);
        BOOL used = NO;
        for (NSInteger s = 0; s < self.fillBlankSlotCount; s++) {
            if (s < (NSInteger)self.selectedFillOptionIdsOrdered.count) {
                NSString *sid = YTFillBlankNormalizeOptionId(self.selectedFillOptionIdsOrdered[s], s);
                if (sid.length > 0 && [sid isEqualToString:bid]) {
                    used = YES;
                    break;
                }
            }
        }
        btn.layer.borderColor = used ? selBorder.CGColor : defBorder.CGColor;
        btn.layer.borderWidth = used ? 3 : 1;
        btn.backgroundColor = [UIColor whiteColor];
    }
}

/// 单空：点击空白占位清空选择，便于换选项
- (void)onTapSingleBlankWrap:(UITapGestureRecognizer *)gr {
    if (self.fillBlankSlotCount > 1) return;
    self.selectedOptionId = nil;
    self.blankWordLabel.text = @"";
    UIColor *defBorder = [UIColor colorWithWhite:0.85 alpha:1];
    for (UIButton *btn in self.optionButtons) {
        btn.enabled = YES;
        btn.userInteractionEnabled = YES;
        btn.layer.borderColor = defBorder.CGColor;
        btn.layer.borderWidth = 1;
        btn.backgroundColor = [UIColor whiteColor];
    }
    self.primaryState.enabled = NO;
    [self emitPrimaryState];
}

/// 多空：只清空被点的这一空，并与下方选项选中态联动
- (void)onTapMultiBlankSlot:(UITapGestureRecognizer *)gr {
    if (self.fillBlankSlotCount <= 1) return;
    NSInteger slot = gr.view.tag;
    if (slot < 0 || slot >= self.fillBlankSlotCount) return;
    if (slot < (NSInteger)self.selectedFillOptionIdsOrdered.count) {
        self.selectedFillOptionIdsOrdered[slot] = @"";
    }
    if ((NSUInteger)slot < self.multiBlankWordLabels.count) {
        self.multiBlankWordLabels[slot].text = @"";
    }
    [self yt_syncCurrentFillSlotIndexToFirstEmpty];
    [self yt_restyleMultiBlankOptionButtons];
    self.primaryState.enabled = [self yt_allFillSlotsSatisfied];
    [self emitPrimaryState];
}

- (void)onSelectFillBlankOption:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= self.unit.options.count) return;
    NSDictionary *opt = self.unit.options[idx];
    NSString *text = opt[@"text"] ?: @"";
    NSString *oidTrim = YTFillBlankNormalizeOptionId(sender.accessibilityIdentifier ?: opt[@"id"], idx);
    if (oidTrim.length == 0) {
        oidTrim = [NSString stringWithFormat:@"idx_%ld", (long)idx];
    }

    if (self.fillBlankSlotCount <= 1) {
        NSString *curSel = (self.selectedOptionId.length > 0) ? YTFillBlankNormalizeOptionId(self.selectedOptionId, idx) : @"";
        // 再点已选项：取消选择，与上方空联动清空
        if (oidTrim.length > 0 && [curSel isEqualToString:oidTrim]) {
            self.selectedOptionId = nil;
            self.blankWordLabel.text = @"";
            UIColor *defBorder = [UIColor colorWithWhite:0.85 alpha:1];
            for (UIButton *btn in self.optionButtons) {
                btn.enabled = YES;
                btn.userInteractionEnabled = YES;
                btn.layer.borderColor = defBorder.CGColor;
                btn.layer.borderWidth = 1;
                btn.backgroundColor = [UIColor whiteColor];
            }
            self.primaryState.enabled = NO;
            [self emitPrimaryState];
            return;
        }
        self.selectedOptionId = oidTrim;
        self.blankWordLabel.text = text;
        UIColor *selBorder = [theAppDelegate.window colorWithHexString:@"#D4D4E4" alpha:1];
        for (UIButton *btn in self.optionButtons) {
            btn.enabled = YES;
            btn.userInteractionEnabled = YES;
            NSString *bid = YTFillBlankNormalizeOptionId(btn.accessibilityIdentifier, btn.tag);
            BOOL sel = [bid isEqualToString:oidTrim];
            btn.layer.borderColor = sel ? selBorder.CGColor : [UIColor colorWithWhite:0.85 alpha:1].CGColor;
            btn.layer.borderWidth = sel ? 3 : 1;
            btn.backgroundColor = [UIColor whiteColor];
        }
        self.primaryState.enabled = (self.selectedOptionId.length > 0);
        [self emitPrimaryState];
        return;
    }

    // 多空：再点已填入的选项 → 只取消该词所在的那一空，并联动上面文案与下面高亮
    for (NSInteger k = 0; k < self.fillBlankSlotCount; k++) {
        if (k >= (NSInteger)self.selectedFillOptionIdsOrdered.count) break;
        NSString *slotId = YTFillBlankNormalizeOptionId(self.selectedFillOptionIdsOrdered[k], k);
        if (oidTrim.length > 0 && [slotId isEqualToString:oidTrim]) {
            self.selectedFillOptionIdsOrdered[k] = @"";
            if ((NSUInteger)k < self.multiBlankWordLabels.count) {
                self.multiBlankWordLabels[k].text = @"";
            }
            [self yt_syncCurrentFillSlotIndexToFirstEmpty];
            [self yt_restyleMultiBlankOptionButtons];
            self.primaryState.enabled = [self yt_allFillSlotsSatisfied];
            [self emitPrimaryState];
            return;
        }
    }

    // 填入第一个空槽
    NSInteger targetSlot = NSNotFound;
    for (NSInteger i = 0; i < self.fillBlankSlotCount; i++) {
        if (i < (NSInteger)self.selectedFillOptionIdsOrdered.count && self.selectedFillOptionIdsOrdered[i].length == 0) {
            targetSlot = i;
            break;
        }
    }
    if (targetSlot == NSNotFound) {
        return;
    }

    self.selectedFillOptionIdsOrdered[targetSlot] = oidTrim;
    if ((NSUInteger)targetSlot < self.multiBlankWordLabels.count) {
        self.multiBlankWordLabels[targetSlot].text = text;
    }
    [self yt_syncCurrentFillSlotIndexToFirstEmpty];
    [self yt_restyleMultiBlankOptionButtons];
    self.primaryState.enabled = [self yt_allFillSlotsSatisfied];
    [self emitPrimaryState];
}

- (void)applySubmitFeedbackCorrect:(BOOL)isCorrect {
    UIColor *correctC = self.theme.primaryColor ?: (self.theme.correctColor ?: [UIColor colorWithRed:0.2 green:0.75 blue:0.4 alpha:1]);
    UIColor *wrongBorderC = [theAppDelegate.window colorWithHexString:@"#FF9593" alpha:1];
    UIColor *wrongFillC = [theAppDelegate.window colorWithHexString:@"#FFF0F1" alpha:1];

    if (self.fillBlankSlotCount <= 1) {
        NSString *selNorm = (self.selectedOptionId.length > 0) ? YTFillBlankNormalizeOptionId(self.selectedOptionId, 0) : @"";
        for (UIButton *btn in self.optionButtons) {
            NSString *bid = YTFillBlankNormalizeOptionId(btn.accessibilityIdentifier, btn.tag);
            BOOL isSel = (selNorm.length > 0 && [bid isEqualToString:selNorm]);
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
        return;
    }

    NSArray<NSString *> *wants = self.unit.correctFillTexts ?: @[];
    for (NSInteger slot = 0; slot < self.fillBlankSlotCount; slot++) {
        if ((NSUInteger)slot >= self.selectedFillOptionIdsOrdered.count) break;
        NSString *oid = YTFillBlankNormalizeOptionId(self.selectedFillOptionIdsOrdered[(NSUInteger)slot], slot);
        UIButton *btn = nil;
        for (UIButton *b in self.optionButtons) {
            if ([YTFillBlankNormalizeOptionId(b.accessibilityIdentifier, b.tag) isEqualToString:oid]) {
                btn = b;
                break;
            }
        }
        if (!btn) continue;
        BOOL slotOk = isCorrect;
        if (!isCorrect && (NSUInteger)slot < wants.count) {
            NSString *want = [wants[(NSUInteger)slot] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *txt = [btn titleForState:UIControlStateNormal] ?: @"";
            slotOk = [txt isEqualToString:want];
        }
        if (slotOk) {
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
    if (self.fillBlankSlotCount <= 1) {
        if (self.selectedOptionId.length == 0) {
            if (completion) completion(nil, [NSError errorWithDomain:@"YTFillBlankUnitView" code:4001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please choose an option", @"")}]);
            return;
        }
        NSDictionary *answerPayload = YTAnswerPayloadForSelectedOptionId(self.selectedOptionId);
        __weak typeof(self) weakSelf = self;
        [self evaluateAnswerPayload:answerPayload completion:^(YTUnitSubmitResult * _Nullable r, NSError * _Nullable error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            BOOL correct = r.isCorrect;
            self.completeSignalSatisfied = correct;
            [self applySubmitFeedbackCorrect:correct];
            if (completion) completion(r, error);
        }];
        return;
    }

    if (![self yt_allFillSlotsSatisfied]) {
        if (completion) completion(nil, [NSError errorWithDomain:@"YTFillBlankUnitView" code:4001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please choose an option", @"")}]);
        return;
    }
    NSDictionary *answerPayload = YTAnswerPayloadForSelectedFillOptionIds([self.selectedFillOptionIdsOrdered copy]);
    __weak typeof(self) weakSelf = self;
    [self evaluateAnswerPayload:answerPayload completion:^(YTUnitSubmitResult * _Nullable r, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        BOOL correct = r.isCorrect;
        self.completeSignalSatisfied = correct;
        [self applySubmitFeedbackCorrect:correct];
        if (completion) completion(r, error);
    }];
}

- (void)applyRestoredAnswerSnapshot:(NSDictionary *)snapshot {
    NSArray<NSString *> *ids = YTSelectedFillOptionIdsFromPayload(snapshot);
    if (ids.count > 1 && self.fillBlankSlotCount > 1) {
        if (ids.count != self.fillBlankSlotCount) return;
        [self.selectedFillOptionIdsOrdered removeAllObjects];
        for (NSString *oid in ids) {
            [self.selectedFillOptionIdsOrdered addObject:oid ?: @""];
        }
        self.currentFillSlotIndex = self.fillBlankSlotCount;
        for (NSInteger s = 0; s < (NSInteger)ids.count; s++) {
            NSString *oid = ids[(NSUInteger)s];
            NSString *txt = @"";
            for (NSDictionary *opt in self.unit.options) {
                id iid = opt[@"id"];
                NSString *os = [iid isKindOfClass:[NSString class]] ? (NSString *)iid : [NSString stringWithFormat:@"%@", iid];
                if ([os isEqualToString:oid]) {
                    txt = opt[@"text"] ?: @"";
                    break;
                }
            }
            if ((NSUInteger)s < self.multiBlankWordLabels.count) {
                self.multiBlankWordLabels[(NSUInteger)s].text = txt;
            }
        }
        // 续学回填后仍需可点选项做反选，不可 enabled = NO
        for (UIButton *btn in self.optionButtons) {
            btn.enabled = YES;
            btn.userInteractionEnabled = YES;
        }
        [self applySubmitFeedbackCorrect:YES];
        self.completeSignalSatisfied = YES;
        self.primaryState.kind = YTUnitPrimaryKindContinue;
        self.primaryState.title = @"Talk_Continue";
        self.primaryState.enabled = YES;
        [self emitPrimaryState];
        return;
    }
    NSString *sid = YTSelectedOptionIdFromPayload(snapshot);
    if (sid.length == 0) return;
    NSString *sidN = YTFillBlankNormalizeOptionId(sid, 0);
    for (UIButton *btn in self.optionButtons) {
        if ([YTFillBlankNormalizeOptionId(btn.accessibilityIdentifier, btn.tag) isEqualToString:sidN]) {
            [self onSelectFillBlankOption:btn];
            break;
        }
    }
    [self applySubmitFeedbackCorrect:YES];
    self.completeSignalSatisfied = YES;
    self.primaryState.kind = YTUnitPrimaryKindContinue;
    self.primaryState.title = @"Talk_Continue";
    self.primaryState.enabled = YES;
    [self emitPrimaryState];
}

@end

@implementation YTFillBlankUnitView
@end
