//
//  YTFillBlankUnitView.m
//  YiTongProject
//

#import "YTFillBlankUnitView.h"
#import "HeaderConfig.h"

@interface YTFillBlankUnitViewLegacyInternal ()
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

@implementation YTFillBlankUnitViewLegacyInternal

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
            make.left.equalTo(self.prefixLabel.mas_right).offset(6);
            make.centerY.equalTo(self.sentenceRow);
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

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording pronounceEvaluator:pronounceEvaluator answerEvaluator:answerEvaluator];
    self.selectedOptionId = nil;
    self.blankWordLabel.text = @"";

    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    NSString *stem = unit.titleCN ?: @"";
    NSRange blankRange = [stem rangeOfString:@"__"];
    if (blankRange.location != NSNotFound) {
        NSString *pre = [stem substringToIndex:blankRange.location];
        NSString *suf = [stem substringFromIndex:blankRange.location + blankRange.length];
        self.prefixLabel.text = pre.length ? pre : @"";
        NSString *trim = [suf stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.suffixLabel.text = (trim.length > 0) ? trim : @"？";
    } else {
        self.prefixLabel.text = stem.length ? stem : @"";
        self.suffixLabel.text = @"";
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
}

- (void)applyRestoredAnswerSnapshot:(NSDictionary *)snapshot {
    NSString *sid = YTSelectedOptionIdFromPayload(snapshot);
    if (sid.length == 0) return;
    for (UIButton *btn in self.optionButtons) {
        if ([(btn.accessibilityIdentifier ?: @"") isEqualToString:sid]) {
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
