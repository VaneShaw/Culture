//
//  YTChoiceExerciseUnitView.m
//  YiTongProject
//

#import "YTChoiceExerciseUnitView.h"
#import "HeaderConfig.h"
#import "YTInternalUnitViewSupport.h"

#pragma mark - Exercise: Choose Image / Choose Word

/**
 选择题 Presenter（听词选图 / 看图选词 / 听音回应 / 选词填空 / 完成对话的基类）
 听音回应：`stem_text`→左上角说明（stemText）；`stem_pinyin`→题目气泡文案（titlePinyin）；喇叭仅播放 stem_audio
 
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
/// 听音回应：`stem_pinyin` 题目气泡（非喇叭旁）
@property (nonatomic, strong) UIView *listenRespondBubbleView;
@property (nonatomic, strong) UILabel *listenRespondBubbleLabel;
@property (nonatomic, strong) UIView *dividerLine;
@property (nonatomic, strong) UIView *optionsContainer;
@property (nonatomic, copy, nullable) NSString *selectedOptionId;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, assign) BOOL hasAutoPlayed;
@property (nonatomic, assign) BOOL isAudioPlaying;
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

        _listenRespondBubbleView = [[UIView alloc] init];
        _listenRespondBubbleView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
        _listenRespondBubbleView.layer.cornerRadius = 14;
        _listenRespondBubbleView.layer.masksToBounds = YES;
        _listenRespondBubbleView.hidden = YES;
        [card addSubview:_listenRespondBubbleView];

        _listenRespondBubbleLabel = [[UILabel alloc] init];
        _listenRespondBubbleLabel.numberOfLines = 0;
        _listenRespondBubbleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _listenRespondBubbleLabel.textColor = BLACK_COLOR_1F;
        [_listenRespondBubbleView addSubview:_listenRespondBubbleLabel];
        [_listenRespondBubbleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.listenRespondBubbleView).insets(UIEdgeInsetsMake(12, 14, 12, 14));
        }];
        [_listenRespondBubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(card).inset(16);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
            make.height.mas_equalTo(0);
        }];

        [_audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(card).offset(16);
            make.top.equalTo(self.listenRespondBubbleView.mas_bottom).offset(12);
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
    self.isAudioPlaying = NO;
    [self.optionButtons removeAllObjects];

    self.primaryState.kind = YTUnitPrimaryKindSubmit;
    self.primaryState.title = @"Submit";
    self.primaryState.enabled = NO;
    [self emitPrimaryState];

    for (UIView *v in self.optionsContainer.subviews) {
        [v removeFromSuperview];
    }

    if (unit.unitType == YTUnitTypeExerciseListenChooseImage) {
        self.listenRespondBubbleView.hidden = YES;
        self.listenRespondBubbleLabel.text = @"";
        [self.listenRespondBubbleView mas_remakeConstraints:^(MASConstraintMaker *make) {
            UIView *card = self.titleLabel.superview;
            make.left.right.equalTo(card).inset(16);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(0);
            make.height.mas_equalTo(0);
        }];
        [self updateAudioButtonStyleForListenChooseImage:YES];
        {
            NSString *instr = [unit yt_resolvedStemInstructionText];
            self.titleLabel.text = instr.length ? instr : NSLocalizedString(@"Choose the matching image", @"");
        }
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
        [self updateAudioButtonStyleForListenChooseImage:NO];
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor = 0.85;

        if (unit.unitType == YTUnitTypeExerciseListenChooseResponse) {
            // stem_text：左上角说明；stem_pinyin：题目气泡（听音题题干）
            NSString *instruction = [unit yt_resolvedStemInstructionText] ?: @"";
            self.titleLabel.text = instruction.length > 0 ? instruction : NSLocalizedString(@"Choose the correct response", @"");
            self.audioButton.hidden = NO;
            self.pinyinLabel.hidden = YES;
            self.pinyinLabel.text = @"";

            NSString *question = unit.titlePinyin ?: @"";
            question = [question stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            self.listenRespondBubbleLabel.text = question;
            UIView *card = self.titleLabel.superview;
            if (question.length > 0) {
                self.listenRespondBubbleView.hidden = NO;
                CGFloat maxW = CGRectGetWidth(card.bounds);
                if (maxW < 1) {
                    maxW = [UIScreen mainScreen].bounds.size.width - 32;
                }
                maxW -= 32 + 28;
                CGSize sz = [question boundingRectWithSize:CGSizeMake(maxW, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{ NSFontAttributeName: self.listenRespondBubbleLabel.font ?: [UIFont systemFontOfSize:18] }
                                                    context:nil].size;
                CGFloat bubbleH = ceil(sz.height) + 12 + 12;
                [self.listenRespondBubbleView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.equalTo(card).inset(16);
                    make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
                    make.height.mas_equalTo(bubbleH);
                }];
            } else {
                self.listenRespondBubbleView.hidden = YES;
                [self.listenRespondBubbleView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.equalTo(card).inset(16);
                    make.top.equalTo(self.titleLabel.mas_bottom).offset(0);
                    make.height.mas_equalTo(0);
                }];
            }
        } else {
            self.listenRespondBubbleView.hidden = YES;
            self.listenRespondBubbleLabel.text = @"";
            [self.listenRespondBubbleView mas_remakeConstraints:^(MASConstraintMaker *make) {
                UIView *card = self.titleLabel.superview;
                make.left.right.equalTo(card).inset(16);
                make.top.equalTo(self.titleLabel.mas_bottom).offset(0);
                make.height.mas_equalTo(0);
            }];
            self.audioButton.hidden = YES;
            self.pinyinLabel.hidden = YES;
            self.pinyinLabel.text = @"";
            {
                NSString *instr = [unit yt_resolvedStemInstructionText];
                self.titleLabel.text = instr.length ? instr : NSLocalizedString(@"Choose the matching word", @"");
            }
        }

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
    NSString *audioURLString = [self audioURLStringForPlayButton];
    if (audioURLString.length == 0) return;
    [self updateAudioButtonPlaying:YES];
    __weak typeof(self) weakSelf = self;
    [self.audio playURLString:audioURLString completion:^(__unused BOOL success, __unused NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self updateAudioButtonPlaying:NO];
    }];
}

- (void)onPlayAudio {
    NSString *audioURLString = [self audioURLStringForPlayButton];
    if (audioURLString.length == 0) return;
    [self updateAudioButtonPlaying:YES];
    __weak typeof(self) weakSelf = self;
    [self.audio playURLString:audioURLString completion:^(__unused BOOL success, __unused NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self updateAudioButtonPlaying:NO];
    }];
}

- (NSString *)audioURLStringForPlayButton {
    // 临时联调：听音选图固定播放本地录音文件 a2_LetterRecording.m4a
    if (self.unit.unitType == YTUnitTypeExerciseListenChooseImage) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"a2_LetterRecording" ofType:@"m4a"];
        if (path.length > 0) {
            return [NSURL fileURLWithPath:path].absoluteString ?: @"";
        }
    }
    return self.unit.audioURLString ?: @"";
}

- (void)updateAudioButtonStyleForListenChooseImage:(BOOL)isListenChooseImage {
    if (isListenChooseImage) {
        self.audioButton.backgroundColor = [theAppDelegate.window colorWithHexString:@"#1F1F39" alpha:1];
        self.audioButton.layer.cornerRadius = 23.0;
        [self.audioButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(46);
        }];
        self.audioButton.imageEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12); // 46-22
        [self updateAudioButtonPlaying:self.isAudioPlaying];
        return;
    }

    self.audioButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.audioButton.layer.cornerRadius = 18.0;
    [self.audioButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(36);
    }];
    self.audioButton.imageEdgeInsets = UIEdgeInsetsZero;

    UIImage *voicePlay = [UIImage imageNamed:@"talk_voice_play"];
    if (voicePlay) {
        voicePlay = [voicePlay imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    [self.audioButton setImage:voicePlay forState:UIControlStateNormal];
}

- (void)updateAudioButtonPlaying:(BOOL)isPlaying {
    self.isAudioPlaying = isPlaying;
    NSString *iconName = isPlaying ? @"talk_vioce_other_playing" : @"talk_vioce_other_start";
    UIImage *icon = [UIImage imageNamed:iconName];
    if (icon) {
        icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    [self.audioButton setImage:icon forState:UIControlStateNormal];
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

        NSString *iconName = imgName.length > 0 ? imgName : @"talk_default";
        UIImage *rawDef = [UIImage imageNamed:@"talk_default"];
        CGSize optCanvas = CGSizeMake(MAX(32, w - 14), MAX(32, h - 55));
        UIImage *iconImg = [UIImage imageNamed:iconName] ?: rawDef;
        if (iconImg == rawDef) {
            iconImg = YTTalkImageAspectFitInBounds(rawDef, optCanvas, 0, 0.5) ?: rawDef;
        }
        UIImageView *iv = [[UIImageView alloc] initWithImage:iconImg];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        [btn addSubview:iv];
        if (imgURLString.length > 0) {
            NSURL *url = [NSURL URLWithString:imgURLString];
            UIImage *ph = YTTalkImageAspectFitInBounds(rawDef, optCanvas, 0, 0.5) ?: rawDef;
            [iv sd_setImageWithURL:url placeholderImage:ph];
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
    UIImage *rawDef = [UIImage imageNamed:@"talk_default"];
    if (isLookChooseWord) {
        CGSize headerCanvas = CGSizeMake(MAX(60, SCREEN_WIDTH - 120), 200);
        UIImage *ph = nil;
        if (self.unit.imageName.length > 0) {
            ph = [UIImage imageNamed:self.unit.imageName];
        }
        if (!ph) {
            ph = rawDef;
        }
        if (ph == rawDef) {
            ph = YTTalkImageAspectFitInBounds(rawDef, headerCanvas, 0, 0.5) ?: rawDef;
        }
        header = [[UIImageView alloc] initWithImage:ph];
        header.contentMode = UIViewContentModeScaleAspectFit;
        [self.optionsContainer addSubview:header];
        if (self.unit.imageURLString.length > 0) {
            NSURL *url = [NSURL URLWithString:self.unit.imageURLString];
            UIImage *place = YTTalkImageAspectFitInBounds(rawDef, headerCanvas, 0, 0.5) ?: rawDef;
            [header sd_setImageWithURL:url placeholderImage:place];
        }
    } else if (self.unit.imageName.length > 0) {
        CGSize boxCanvas = CGSizeMake(140, 140);
        UIImage *ph = [UIImage imageNamed:self.unit.imageName];
        UIImage *displayPh = ph;
        if (!displayPh) {
            displayPh = rawDef;
        }
        if (displayPh == rawDef) {
            displayPh = YTTalkImageAspectFitInBounds(rawDef, boxCanvas, 0, 0.5) ?: rawDef;
        }
        header = [[UIImageView alloc] initWithImage:displayPh];
        header.contentMode = UIViewContentModeScaleAspectFit;
        [self.optionsContainer addSubview:header];
        if (self.unit.imageURLString.length > 0) {
            NSURL *url = [NSURL URLWithString:self.unit.imageURLString];
            UIImage *place = YTTalkImageAspectFitInBounds(rawDef, boxCanvas, 0, 0.5) ?: rawDef;
            [header sd_setImageWithURL:url placeholderImage:place];
        }
    } else if (self.unit.imageURLString.length > 0) {
        CGSize boxCanvas = CGSizeMake(140, 140);
        UIImage *ph = YTTalkImageAspectFitInBounds(rawDef, boxCanvas, 0, 0.5) ?: rawDef;
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
