//
//  YTChoiceExerciseUnitView.m
//  YiTongProject
//

#import "YTChoiceExerciseUnitView.h"
#import "HeaderConfig.h"

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
@interface YTChoiceExerciseUnitViewLegacyInternal ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, strong) UILabel *pinyinLabel;
@property (nonatomic, strong) UIView *dividerLine;
@property (nonatomic, strong) UIView *optionsContainer;
@property (nonatomic, copy, nullable) NSString *selectedOptionId;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, assign) BOOL hasAutoPlayed;
@end

@implementation YTChoiceExerciseUnitViewLegacyInternal

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
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [card addSubview:_titleLabel];

        _audioButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _audioButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        _audioButton.layer.cornerRadius = 18;
        _audioButton.layer.masksToBounds = YES;
        UIImage *voicePlay = [UIImage imageNamed:@"talk_voice_play"];
        if (voicePlay) {
            voicePlay = [voicePlay imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        [_audioButton setImage:voicePlay forState:UIControlStateNormal];
        _audioButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
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

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording pronounceEvaluator:pronounceEvaluator answerEvaluator:answerEvaluator];
    self.selectedOptionId = nil;
    self.hasAutoPlayed = NO;
    [self.optionButtons removeAllObjects];

    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    for (UIView *v in self.optionsContainer.subviews) {
        [v removeFromSuperview];
    }

    if (unit.unitType == YTUnitTypeExerciseListenChooseImage) {
        self.titleLabel.text = NSLocalizedString(@"Choose the matching image", @"");
        self.audioButton.hidden = NO;
        self.pinyinLabel.hidden = NO;
        self.pinyinLabel.text = unit.titlePinyin ?: @"";
        self.dividerLine.hidden = NO;
        [self.optionsContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.rootView).inset(16);
            make.top.equalTo(self.dividerLine.mas_bottom).offset(40);
            make.bottom.equalTo(self.rootView).offset(-16);
        }];
        [self buildImageGridOptions];
        [self autoPlayIfNeeded];
    } else {
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor = 0.85;

        self.titleLabel.text = (unit.unitType == YTUnitTypeExerciseListenChooseResponse)
            ? NSLocalizedString(@"Choose the correct response", @"")
            : NSLocalizedString(@"Choose the matching word", @"");
        self.audioButton.hidden = (unit.unitType != YTUnitTypeExerciseListenChooseResponse);
        self.pinyinLabel.hidden = YES;
        self.pinyinLabel.text = @"";

        if (unit.unitType == YTUnitTypeExerciseLookChooseWord) {
            self.dividerLine.hidden = YES;
            [self.optionsContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.rootView).inset(16);
                make.top.equalTo(self.titleLabel.mas_bottom).offset(40);
                make.bottom.equalTo(self.rootView).offset(-30);
            }];
        } else {
            self.dividerLine.hidden = NO;
            [self.optionsContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.rootView).inset(16);
                make.top.equalTo(self.dividerLine.mas_bottom).offset(40);
                make.bottom.equalTo(self.rootView).offset(-16);
            }];
        }

        [self buildWordOptionsWithHeaderImage];
        if (unit.unitType == YTUnitTypeExerciseListenChooseResponse) {
            [self autoPlayIfNeeded];
        }
    }
}

- (void)autoPlayIfNeeded {
    if (self.hasAutoPlayed) return;
    self.hasAutoPlayed = YES;
    if (self.unit.audioURLString.length == 0) return;
    [self.audio playURLString:self.unit.audioURLString completion:nil];
}

- (void)onPlayAudio {
    if (self.unit.audioURLString.length == 0) return;
    [self.audio playURLString:self.unit.audioURLString completion:nil];
}

- (void)buildImageGridOptions {
    CGFloat gap = 13;
    CGFloat w = (SCREEN_WIDTH - 32 - 32 - gap) / 2.0;
    CGFloat h = w * 166.0 / 145.0;
    UIColor *borderColorD4 = [UIColor colorWithRed:0xD4 / 255.0
                                             green:0xD4 / 255.0
                                              blue:0xE4 / 255.0
                                             alpha:1.0];

    for (NSInteger i = 0; i < self.unit.options.count; i++) {
        NSDictionary *opt = self.unit.options[i];
        NSString *optId = opt[@"id"];
        NSString *imgName = opt[@"imageName"];
        NSString *imgURLString = opt[@"imageURL"];
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
        if (imgURLString.length > 0) {
            NSURL *url = [NSURL URLWithString:imgURLString];
            [iv sd_setImageWithURL:url placeholderImage:iconImg];
        }

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
    BOOL isLookChooseWord = (self.unit.unitType == YTUnitTypeExerciseLookChooseWord);
    if (isLookChooseWord) {
        UIImage *ph = nil;
        if (self.unit.imageName.length > 0) {
            ph = [UIImage imageNamed:self.unit.imageName];
        }
        if (!ph) {
            ph = [UIImage imageNamed:@"take_img1"];
        }
        header = [[UIImageView alloc] initWithImage:ph];
        header.contentMode = UIViewContentModeScaleAspectFit;
        [self.optionsContainer addSubview:header];
        if (self.unit.imageURLString.length > 0) {
            NSURL *url = [NSURL URLWithString:self.unit.imageURLString];
            [header sd_setImageWithURL:url placeholderImage:ph];
        }
    } else if (self.unit.imageName.length > 0) {
        UIImage *ph = [UIImage imageNamed:self.unit.imageName];
        header = [[UIImageView alloc] initWithImage:ph];
        header.contentMode = UIViewContentModeScaleAspectFit;
        [self.optionsContainer addSubview:header];
        if (self.unit.imageURLString.length > 0) {
            NSURL *url = [NSURL URLWithString:self.unit.imageURLString];
            [header sd_setImageWithURL:url placeholderImage:ph ?: [UIImage imageNamed:@"take_img1"]];
        }
    } else if (self.unit.imageURLString.length > 0) {
        UIImage *ph = [UIImage imageNamed:@"take_img1"];
        header = [[UIImageView alloc] initWithImage:ph];
        header.contentMode = UIViewContentModeScaleAspectFit;
        [self.optionsContainer addSubview:header];
        NSURL *url = [NSURL URLWithString:self.unit.imageURLString];
        [header sd_setImageWithURL:url placeholderImage:ph];
    }

    UIView *list = [[UIView alloc] init];
    [self.optionsContainer addSubview:list];
    [list mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.optionsContainer);
        make.bottom.equalTo(self.optionsContainer);
        if (header) {
            CGFloat offset = isLookChooseWord ? 40.0 : 12.0;
            make.top.equalTo(header.mas_bottom).offset(offset);
        } else {
            make.top.equalTo(self.optionsContainer);
        }
    }];

    if (header) {
        if (isLookChooseWord) {
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
    CGFloat gap = (self.unit.unitType == YTUnitTypeExerciseLookChooseWord) ? 16.0 : 10.0;
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

    for (UIButton *btn in self.optionButtons) {
        BOOL sel = [btn.accessibilityIdentifier isEqualToString:self.selectedOptionId];
        btn.layer.borderColor = sel ? [theAppDelegate.window colorWithHexString:@"#D4D4E4" alpha:1].CGColor : [UIColor colorWithWhite:0.85 alpha:1].CGColor;
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
        NSString *bid = btn.accessibilityIdentifier ?: @"";
        BOOL isSel = [bid isEqualToString:self.selectedOptionId ?: @""];
        if (isCorrect) {
            if (isSel) {
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
        if (completion) completion(nil, [NSError errorWithDomain:@"YTChoiceExerciseUnitView" code:4001 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Please choose an option", @"")}]);
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
    self.hasAutoPlayed = YES;
    for (UIButton *btn in self.optionButtons) {
        if ([(btn.accessibilityIdentifier ?: @"") isEqualToString:sid]) {
            [self onSelectOption:btn];
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

@implementation YTChoiceExerciseUnitView
@end
