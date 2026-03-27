//
//  YTCompleteDialogueUnitView.m
//  YiTongProject
//

#import "YTCompleteDialogueUnitView.h"
#import "YTInternalUnitViewSupport.h"
#import "YTAnswerEvaluating.h"
#import "YTPronounceEvaluating.h"
#import "HeaderConfig.h"
#import <QuartzCore/QuartzCore.h>

@interface YTCompleteDialogueUnitView ()
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
        _questionBubble.backgroundColor = [UIColor colorWithRed:0xF2 / 255.0 green:0xF2 / 255.0 blue:0xF2 / 255.0 alpha:1];
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
        UIImage *voicePlay = [UIImage imageNamed:@"talk_voice_play"];
        if (voicePlay) {
            voicePlay = [voicePlay imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        [_questionPlayButton setImage:voicePlay forState:UIControlStateNormal];
        _questionPlayButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_questionPlayButton addTarget:self action:@selector(onPlayQuestionAudio) forControlEvents:UIControlEventTouchUpInside];
        [_questionBubble addSubview:_questionPlayButton];
        [_questionPlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
            // 问题气泡内边距：上16左16下16右12
            make.right.equalTo(self.questionBubble).offset(-12);
            make.centerY.equalTo(self.questionBubble);
            make.width.height.mas_equalTo(28);
        }];

        _questionLabel = [[UILabel alloc] init];
        _questionLabel.textColor = GARY_COLOR_63;
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
        _answerTextView.textColor = GARY_COLOR_63;
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
    UIColor *color = GARY_COLOR_63;
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

- (void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording pronounceEvaluator:pronounceEvaluator answerEvaluator:answerEvaluator];
    self.questionBubble.backgroundColor = theme.chatPromptBubbleBackgroundColor ?: [UIColor colorWithRed:0xF2 / 255.0 green:0xF2 / 255.0 blue:0xF2 / 255.0 alpha:1];
    self.answerBubble.backgroundColor = theme.chatAnswerBubbleBackgroundColor ?: [UIColor colorWithRed:0xE9/255.0 green:0xF2/255.0 blue:0xFF/255.0 alpha:1.0];
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
            [self onSelectCompleteDialogueOption:btn];
            break;
        }
    }
    [self applySubmitFeedbackCorrect:YES];
    self.completeSignalSatisfied = YES;
    self.primaryState.kind = YTUnitPrimaryKindContinue;
    self.primaryState.title = @"Talk_Continue";
    self.primaryState.enabled = YES;
    [self emitPrimaryState];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self updateAnswerDashIfNeeded];
    });
}

@end

