//
//  YTListenResponseUnitView.m
//  YiTongProject
//

#import "YTListenResponseUnitView.h"
#import "HeaderConfig.h"

@interface YTListenResponseUnitViewLegacyInternal ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *bubbleLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIView *optionsContainer;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, copy, nullable) NSString *selectedOptionId;
@end

@implementation YTListenResponseUnitViewLegacyInternal

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
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"";
        [_cardView addSubview:_titleLabel];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(16);
            make.left.right.equalTo(self.cardView).inset(16);
        }];

        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithRed:0xF2 / 255.0 green:0xF2 / 255.0 blue:0xF2 / 255.0 alpha:1];
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
        UIImage *voicePlay = [UIImage imageNamed:@"talk_voice_play"];
        if (voicePlay) {
            voicePlay = [voicePlay imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        [_playButton setImage:voicePlay forState:UIControlStateNormal];
        _playButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_playButton addTarget:self action:@selector(onPlayAudio) forControlEvents:UIControlEventTouchUpInside];
        [_bubbleView addSubview:_playButton];
        [_playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.bubbleView).offset(-10);
            make.centerY.equalTo(self.bubbleView);
            make.width.height.mas_equalTo(28);
        }];

        _bubbleLabel = [[UILabel alloc] init];
        _bubbleLabel.textColor = GARY_COLOR_63;
        _bubbleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:15];
        _bubbleLabel.numberOfLines = 0;
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
            make.top.equalTo(self.bubbleView.mas_bottom).offset(60);
            make.bottom.lessThanOrEqualTo(self.cardView).offset(-20);
        }];
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording pronounceEvaluator:pronounceEvaluator answerEvaluator:answerEvaluator];
    self.bubbleView.backgroundColor = theme.chatPromptBubbleBackgroundColor ?: [UIColor colorWithRed:0xF2 / 255.0 green:0xF2 / 255.0 blue:0xF2 / 255.0 alpha:1];
    self.selectedOptionId = nil;

    // 接口：`content.stem_text`→stemText（左上角说明），`content.stem_pinyin`→titlePinyin（灰气泡题干，喇叭在气泡内）
    NSString *stemText = [unit yt_resolvedStemInstructionText] ?: @"";
    NSString *stemPinyinField = unit.titlePinyin ?: @"";
    stemPinyinField = [stemPinyinField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.titleLabel.text = stemText.length ? stemText : NSLocalizedString(@"Choose the correct response", @"");
    self.bubbleLabel.text = stemPinyinField;

    UIFont *bubbleFont = self.bubbleLabel.font ?: [UIFont systemFontOfSize:15];
    CGFloat maxBubbleTextW = [UIScreen mainScreen].bounds.size.width * 0.78f - 16.f - 28.f - 10.f - 16.f;
    if (maxBubbleTextW < 60.f) {
        maxBubbleTextW = 200.f;
    }
    CGSize textSize = [stemPinyinField boundingRectWithSize:CGSizeMake(maxBubbleTextW, CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{ NSFontAttributeName: bubbleFont }
                                                     context:nil].size;
    CGFloat bubbleH = MAX(44.f, ceil(textSize.height) + 20.f);
    [self.bubbleView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(bubbleH);
    }];

    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    for (UIView *v in self.optionsContainer.subviews) {
        [v removeFromSuperview];
    }
    [self.optionButtons removeAllObjects];

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

- (void)yt_autoPlayStemAudioIfNeededWhenUnitIncomplete:(BOOL)isIncomplete {
    [super yt_autoPlayStemAudioIfNeededWhenUnitIncomplete:isIncomplete];
    if (!isIncomplete) {
        return;
    }
    if (self.unit.audioURLString.length == 0) {
        return;
    }
    [self onPlayAudio];
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
            [self onSelectListenResponseOption:btn];
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

@implementation YTListenResponseUnitView
@end
