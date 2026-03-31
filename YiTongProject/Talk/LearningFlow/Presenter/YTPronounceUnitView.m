//
//  YTPronounceUnitView.m
//  YiTongProject
//

#import "YTPronounceUnitView.h"
#import "HeaderConfig.h"
#import "VideoPlayerView.h"
#import "VideoFullScreenViewController.h"

#pragma mark - 语法页：点状虚线竖线

@interface YTGrammarDottedVerticalLineView : UIView
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) UIColor *lineColor;
@end

@implementation YTGrammarDottedVerticalLineView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.fillColor = nil;
        _shapeLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:_shapeLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat mid = CGRectGetMidX(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(mid, 0)];
    [path addLineToPoint:CGPointMake(mid, MAX(0, h))];
    self.shapeLayer.path = path.CGPath;
    self.shapeLayer.frame = self.bounds;
    self.shapeLayer.strokeColor = self.lineColor.CGColor;
    self.shapeLayer.lineWidth = 2.0;
    // 圆点状虚线：更细、点距更密（短划 + 间隔，圆头）
    self.shapeLayer.lineDashPattern = @[@1.5, @3.5];
}

@end

#pragma mark - 语法页：向下箭头（自下而上渐变，底端尾色白 60%）

@interface YTGrammarGradientArrowDownView : UIView
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation YTGrammarGradientArrowDownView

/// 自下而上渐变（沿 y 轴从下往上）：底端为主题色，上端为尾端浅色（白 60%）。与 ↓ 字形一致：尖端在下、尾在上。
- (instancetype)initWithTopColor:(UIColor *)topColor bottomTailColor:(UIColor *)tailColor arrowText:(NSString *)arrowText {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _gradientLayer = [CAGradientLayer layer];
        // startPoint 在下、endPoint 在上：颜色沿从下到上插值（勿用 0→1 否则会成「上到下」）
        _gradientLayer.startPoint = CGPointMake(0.5, 1.0);
        _gradientLayer.endPoint = CGPointMake(0.5, 0.0);
        _gradientLayer.colors = @[(id)topColor.CGColor, (id)tailColor.CGColor];
        [self.layer addSublayer:_gradientLayer];

        UILabel *maskLabel = [[UILabel alloc] init];
        maskLabel.text = (arrowText.length > 0) ? arrowText : @"↓";
        maskLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        maskLabel.textAlignment = NSTextAlignmentCenter;
        maskLabel.textColor = [UIColor whiteColor];
        self.maskView = maskLabel;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
    self.maskView.frame = self.bounds;
}

@end

#pragma mark - 拼音行：喇叭紧跟最后一个字（含换行后末行）

/// 在 `layoutSubviews` 里按与 `UILabel` 相同的绘制区域（`textRectForBounds`）排版，将喇叭放在最后一个字形右侧。
@interface YTPinyinLabel : UILabel
@property (nonatomic, weak) UIButton *playButton;
@property (nonatomic, assign) CGFloat playSpacing;
@end

@implementation YTPinyinLabel

- (void)layoutSubviews {
    CGFloat w = CGRectGetWidth(self.bounds);
    if (w > 0) {
        self.preferredMaxLayoutWidth = w;
    }
    [super layoutSubviews];
    [self yt_positionPlayButtonIfNeeded];
}

- (NSAttributedString *)yt_attributedStringForLayout {
    if (self.attributedText.length > 0) {
        return self.attributedText;
    }
    NSString *plain = self.text ?: @"";
    if (plain.length == 0) {
        return nil;
    }
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = self.textAlignment;
    paragraph.lineBreakMode = self.lineBreakMode;
    return [[NSAttributedString alloc] initWithString:plain
                                         attributes:@{
                                             NSFontAttributeName: self.font,
                                             NSForegroundColorAttributeName: self.textColor ?: [UIColor blackColor],
                                             NSParagraphStyleAttributeName: paragraph
                                         }];
}

- (void)yt_positionPlayButtonIfNeeded {
    UIButton *btn = self.playButton;
    UIView *superv = self.superview;
    if (!btn || !superv) {
        return;
    }

    static CGFloat const kBtnSize = 28.0;
    CGFloat spacing = (self.playSpacing > 0) ? self.playSpacing : 8.0;

    CGRect bounds = self.bounds;
    if (CGRectGetWidth(bounds) <= 0) {
        return;
    }

    CGRect textRect = [self textRectForBounds:bounds limitedToNumberOfLines:self.numberOfLines];
    CGFloat containerW = CGRectGetWidth(textRect);
    if (containerW <= 0) {
        return;
    }

    NSAttributedString *attr = [self yt_attributedStringForLayout];
    if (!attr || attr.length == 0) {
        CGFloat y = CGRectGetMinY(self.frame) + (CGRectGetHeight(self.frame) - kBtnSize) / 2.0;
        btn.frame = CGRectMake(CGRectGetMinX(self.frame), y, kBtnSize, kBtnSize);
        [superv bringSubviewToFront:btn];
        return;
    }

    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:attr];
    NSLayoutManager *lm = [[NSLayoutManager alloc] init];
    [storage addLayoutManager:lm];
    NSTextContainer *tc = [[NSTextContainer alloc] initWithSize:CGSizeMake(containerW, CGFLOAT_MAX)];
    tc.lineFragmentPadding = 0;
    tc.maximumNumberOfLines = self.numberOfLines;
    tc.lineBreakMode = self.lineBreakMode;
    [lm addTextContainer:tc];

    NSRange glyphRange = [lm glyphRangeForTextContainer:tc];
    if (glyphRange.length == 0) {
        CGFloat y = CGRectGetMinY(self.frame) + (CGRectGetHeight(self.frame) - kBtnSize) / 2.0;
        btn.frame = CGRectMake(CGRectGetMinX(self.frame), y, kBtnSize, kBtnSize);
        [superv bringSubviewToFront:btn];
        return;
    }

    NSUInteger lastGlyph = NSMaxRange(glyphRange) - 1;
    CGRect lastGlyphRect = [lm boundingRectForGlyphRange:NSMakeRange(lastGlyph, 1) inTextContainer:tc];

    CGFloat x = CGRectGetMinX(self.frame) + CGRectGetMinX(textRect) + CGRectGetMaxX(lastGlyphRect) + spacing;
    CGFloat y = CGRectGetMinY(self.frame) + CGRectGetMinY(textRect) + lastGlyphRect.origin.y + (lastGlyphRect.size.height - kBtnSize) / 2.0;

    btn.frame = CGRectMake(x, y, kBtnSize, kBtnSize);
    [superv bringSubviewToFront:btn];
}

@end

#pragma mark - Pronounce (recording)

/**
 发音练习 Presenter
 
 UI/交互（MVP）：
 - 展示：图片 + 中/拼音/英
 - 播放：点击喇叭仅辅助听标准音，不单独算作完成
 - 录音：底部主按钮驱动录音状态机：Start -> Recording -> Stop -> Scoring -> (Correct/Try again)
 
 说明：
 - 「完成/解锁下一题/进度」条件：模拟评分 verdict 为 Correct（达标）
 - 未达标可重录；仅播放不视为完成
 */
@interface YTPronounceUnitViewLegacyInternal () 
<UITextViewDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) UIView *mediaContainerView;
@property (nonatomic, strong) UIScrollView *mediaScrollView;
@property (nonatomic, strong) UIView *mediaIndicatorContainerView;
@property (nonatomic, strong) NSMutableArray<UIView *> *mediaIndicatorViews;
@property (nonatomic, assign) NSInteger currentMediaPage;
@property (nonatomic, strong) NSMutableArray<UIView *> *mediaPageViews;
@property (nonatomic, strong) NSArray<NSDictionary *> *currentMediaItems;
@property (nonatomic, strong, nullable) VideoPlayerView *activeVideoPlayerView;
@property (nonatomic, assign) NSInteger activeVideoIndex;
@property (nonatomic, copy, nullable) NSString *activeVideoURLString;
@property (nonatomic, strong) UIView *dashedLineView;
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
/// 最近一次成功 `stopRecording` 得到的本地文件 URL 字符串（`fileURL.absoluteString`），供调试回放
@property (nonatomic, copy, nullable) NSString *lastRecordingFileURLString;
/// 题型页：可进入语法页时，底部与语法页同位的翻转按钮
@property (nonatomic, strong) UIButton *grammarFlipToGrammarButton;
#if DEBUG
@property (nonatomic, strong) UIButton *debugPlayMyRecordingButton;
#endif
@end

@implementation YTPronounceUnitViewLegacyInternal

static NSInteger const kMediaVideoPosterTag = 9101;
static NSInteger const kMediaVideoHostTag = 9102;
/// 视频展示区比例（与设计稿 302×170 一致）
static CGFloat const kYTTalkVideoPlayerAspectRatio = 170.0 / 302.0;
/// 媒体区底边到中文标题顶：原设计 60，整体上移 20 后为 40
static CGFloat const kYTPronounceMediaToTitleGap = 40.0;
/// 拼音行左右边距（大于标题区 20，避免长拼音顶边）
static CGFloat const kYTPronouncePinyinHorizontalInset = 40.0;

- (UIViewController *)yt_hostViewController {
    UIResponder *responder = self;
    while (responder) {
        responder = responder.nextResponder;
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mediaPageViews = [NSMutableArray array];
        _mediaIndicatorViews = [NSMutableArray array];
        _activeVideoIndex = NSNotFound;

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

        _mediaContainerView = [[UIView alloc] init];
        _mediaContainerView.backgroundColor = [UIColor clearColor];
        _mediaContainerView.clipsToBounds = YES;
        [self.frontContentView addSubview:_mediaContainerView];

        _mediaScrollView = [[UIScrollView alloc] init];
        _mediaScrollView.pagingEnabled = YES;
        _mediaScrollView.showsHorizontalScrollIndicator = NO;
        _mediaScrollView.showsVerticalScrollIndicator = NO;
        _mediaScrollView.alwaysBounceHorizontal = YES;
        _mediaScrollView.alwaysBounceVertical = NO;
        _mediaScrollView.delegate = self;
        [_mediaContainerView addSubview:_mediaScrollView];

        _mediaIndicatorContainerView = [[UIView alloc] init];
        _mediaIndicatorContainerView.backgroundColor = [UIColor clearColor];
        [self.frontContentView addSubview:_mediaIndicatorContainerView];

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

        YTPinyinLabel *pinyin = [[YTPinyinLabel alloc] init];
        _pinyinLabel = pinyin;
        _pinyinLabel.textAlignment = NSTextAlignmentLeft;
        _pinyinLabel.numberOfLines = 2;
        // 按字符换行：一行放不下时排到第二行（勿用 TruncatingTail，否则易与单行混淆）
        _pinyinLabel.lineBreakMode = NSLineBreakByCharWrapping;
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
        _playButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *voicePlay = [UIImage imageNamed:@"talk_voice_play"];
        if (voicePlay) {
            voicePlay = [voicePlay imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        [_playButton setImage:voicePlay forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(onPlay) forControlEvents:UIControlEventTouchUpInside];
        [self.frontContentView addSubview:_playButton];
        pinyin.playButton = _playButton;
        pinyin.playSpacing = 8.0;
        _playButton.translatesAutoresizingMaskIntoConstraints = YES;

        _recordHintLabel = [[UILabel alloc] init];
        _recordHintLabel.textAlignment = NSTextAlignmentCenter;
        _recordHintLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        _recordHintLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _recordHintLabel.numberOfLines = 2;
        [self.frontContentView addSubview:_recordHintLabel];

        _dashedLineView = [[UIView alloc] init];
        _dashedLineView.backgroundColor = [self dashedPatternColor];
        [self.frontContentView addSubview:_dashedLineView];

        // 中文（学生）：与拼音固定 6pt；与媒体区间距 kYTPronounceMediaToTitleGap（原 60 → 40，整体上移 20）
        [_cnTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.frontContentView);
            make.left.right.equalTo(self.frontContentView).inset(20);
            make.top.equalTo(self.mediaContainerView.mas_bottom).offset(kYTPronounceMediaToTitleGap);
            make.bottom.equalTo(self.pinyinLabel.mas_top).offset(-6);
        }];
        [_pinyinLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.frontContentView).offset(kYTPronouncePinyinHorizontalInset);
            make.right.equalTo(self.frontContentView).offset(-kYTPronouncePinyinHorizontalInset);
            make.top.equalTo(self.cnTextView.mas_bottom).offset(6);
        }];
        [_recordHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.pinyinLabel.mas_bottom).offset(8);
            make.left.right.equalTo(self.frontContentView).inset(20);
        }];

        [self.dashedLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            // 虚线固定放在拼音下方（不依赖 recordHint，避免空文案时链路不稳定）
            make.top.equalTo(self.pinyinLabel.mas_bottom).offset(22);
            make.left.right.equalTo(self.frontContentView).inset(20);
            make.height.mas_equalTo(1);
        }];

        [_enLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.dashedLineView.mas_bottom).offset(20);
            make.left.right.equalTo(self.frontContentView).inset(20);
            make.bottom.equalTo(self.frontContentView).offset(-53);
        }];

        [_mediaContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            // 中间媒体区域：可承载图片/视频，支持左右滑动
            make.top.equalTo(self.frontContentView).offset(40);
            make.left.right.equalTo(self.frontContentView).inset(20);
            make.height.greaterThanOrEqualTo(@160);
            // 由下方中文顶边反推高度；与 cnTextView 顶间距 kYTPronounceMediaToTitleGap
            make.bottom.equalTo(self.cnTextView.mas_top).offset(-kYTPronounceMediaToTitleGap);
        }];
        [_mediaScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.mediaContainerView);
        }];
        // 分页指示器放在媒体区域下方
        [_mediaIndicatorContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mediaContainerView.mas_bottom).offset(10);
            make.centerX.equalTo(self.mediaContainerView);
            make.height.mas_equalTo(4);
        }];

    }
    return self;
}

- (UIButton *)grammarFlipToGrammarButton {
    if (!_grammarFlipToGrammarButton) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *img = [UIImage imageNamed:@"talk_grammar_change"];
        if (img) {
            img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        [b setImage:img forState:UIControlStateNormal];
        [b addTarget:self action:@selector(onTapGrammarFlipToGrammar) forControlEvents:UIControlEventTouchUpInside];
        [self.frontContentView addSubview:b];
        [b mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.frontContentView);
            make.bottom.equalTo(self.frontContentView).offset(-18);
            make.width.height.mas_equalTo(23);
        }];
        [self.frontContentView bringSubviewToFront:b];
        _grammarFlipToGrammarButton = b;
    }
    return _grammarFlipToGrammarButton;
}

#if DEBUG

- (UIButton *)debugPlayMyRecordingButton {
    if (!_debugPlayMyRecordingButton) {
        _debugPlayMyRecordingButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_debugPlayMyRecordingButton setTitle:NSLocalizedString(@"Play my recording (debug)", @"") forState:UIControlStateNormal];
        _debugPlayMyRecordingButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _debugPlayMyRecordingButton.tintColor = BLACK_COLOR_1F;
        _debugPlayMyRecordingButton.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        _debugPlayMyRecordingButton.layer.cornerRadius = 8;
        _debugPlayMyRecordingButton.contentEdgeInsets = UIEdgeInsetsMake(6, 10, 6, 10);
        [_debugPlayMyRecordingButton addTarget:self action:@selector(onDebugPlayMyRecording) forControlEvents:UIControlEventTouchUpInside];
        _debugPlayMyRecordingButton.hidden = YES;
        [self.frontContentView addSubview:_debugPlayMyRecordingButton];
        [_debugPlayMyRecordingButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.frontContentView).offset(8);
            make.right.equalTo(self.frontContentView).offset(-12);
        }];
    }
    return _debugPlayMyRecordingButton;
}

- (void)debugUpdatePlayMyRecordingButtonVisibility {
    BOOL show = (self.lastRecordingFileURLString.length > 0);
    self.debugPlayMyRecordingButton.hidden = !show;
}

- (void)onDebugPlayMyRecording {
    if (self.lastRecordingFileURLString.length == 0) {
        return;
    }
    [self.audio stop];
    [self.audio playURLString:self.lastRecordingFileURLString completion:^(__unused BOOL success, __unused NSError *_Nullable error) {
    }];
}

#endif

-(void)configureWithUnit:(YTUnit *)unit theme:(YTDifficultyTheme *)theme audio:(YTAudioMuxService *)audio recording:(YTRecordingService *)recording pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator {
    [super configureWithUnit:unit theme:theme audio:audio recording:recording pronounceEvaluator:pronounceEvaluator answerEvaluator:answerEvaluator];

    // 状态复位：避免跨题残留
    self.hasPlayedOnce = NO;
    self.isScoring = NO;
    self.shouldOpenMicSettings = NO;
    self.showingGrammar = NO;
    self.lastRecordingFileURLString = nil;
#if DEBUG
    if (self.debugPlayMyRecordingButton) {
        self.debugPlayMyRecordingButton.hidden = YES;
    }
#endif
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

    [self rebuildMediaWithUnit:unit];
    // 约束布局完成后再计算分页 frame，避免初次 bounds=0 导致“看不到媒体”
    dispatch_async(dispatch_get_main_queue(), ^{
        [self layoutMediaIfNeeded];
    });
    [self applyCNAttributedTextForUnit:unit];
    BOOL canOpenGrammar = (unit.highlightTexts.count > 0);
    if (canOpenGrammar) {
        self.grammarFlipToGrammarButton.hidden = NO;
    } else if (_grammarFlipToGrammarButton) {
        _grammarFlipToGrammarButton.hidden = YES;
    }
    self.pinyinLabel.text = unit.titlePinyin ?: @"";
    [self.pinyinLabel setNeedsLayout];
    self.enLabel.text = unit.titleEN ?: @"";

    self.recordHintLabel.text = @"";

    // 默认主按钮为录音入口（由容器统一渲染按钮样式）
    self.primaryState.kind = YTUnitPrimaryKindRecord;
    self.primaryState.title = @"Start recording";
    self.primaryState.enabled = YES;
    [self emitPrimaryState];
}

#pragma mark - Media (image / video pager)

- (NSArray<NSDictionary *> *)mediaItemsForUnit:(YTUnit *)unit {
    NSArray *items = unit.mediaItems;
    if ([items isKindOfClass:[NSArray class]] && items.count > 0) return items;

    // 兜底：兼容旧字段 imageURLString/imageName
    NSMutableArray<NSDictionary *> *fallback = [NSMutableArray array];
    if (unit.imageURLString.length > 0) {
        [fallback addObject:@{@"type": @"image", @"url": unit.imageURLString ?: @""}];
    } else if (unit.imageName.length > 0) {
        [fallback addObject:@{@"type": @"image", @"name": unit.imageName ?: @""}];
    } else {
        [fallback addObject:@{@"type": @"image", @"name": @"take_img1"}];
    }
    return fallback;
}

- (UIColor *)mediaIndicatorSelectedColor {
    return self.theme.primaryColor ?: [UIColor colorWithWhite:0.20 alpha:1.0];
}

- (UIColor *)mediaIndicatorNormalColor {
    return [[self mediaIndicatorSelectedColor] colorWithAlphaComponent:0.25];
}

- (void)rebuildMediaIndicatorsWithCount:(NSInteger)count {
    for (UIView *v in self.mediaIndicatorViews.copy) {
        [v removeFromSuperview];
    }
    [self.mediaIndicatorViews removeAllObjects];

    self.mediaIndicatorContainerView.hidden = (count <= 1);
    if (count <= 0) {
        [self.mediaIndicatorContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(0);
        }];
        self.currentMediaPage = 0;
        return;
    }

    UIView *prev = nil;
    CGFloat itemWidth = 26.0;
    CGFloat gap = 4.0;
    for (NSInteger i = 0; i < count; i++) {
        UIView *dot = [[UIView alloc] init];
        dot.backgroundColor = [self mediaIndicatorNormalColor];
        dot.layer.cornerRadius = 2.0;
        dot.layer.masksToBounds = YES;
        [self.mediaIndicatorContainerView addSubview:dot];
        [self.mediaIndicatorViews addObject:dot];

        [dot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.mediaIndicatorContainerView);
            make.width.mas_equalTo(itemWidth);
            if (prev) {
                make.left.equalTo(prev.mas_right).offset(gap);
            } else {
                make.left.equalTo(self.mediaIndicatorContainerView);
            }
        }];
        prev = dot;
    }
    [prev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.mediaIndicatorContainerView);
    }];
    CGFloat totalWidth = count * itemWidth + MAX(0, count - 1) * gap;
    [self.mediaIndicatorContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(totalWidth);
    }];
    [self updateMediaIndicatorSelection:0];
}

- (void)updateMediaIndicatorSelection:(NSInteger)index {
    if (self.mediaIndicatorViews.count == 0) {
        self.currentMediaPage = 0;
        return;
    }
    index = MAX(0, MIN(index, (NSInteger)self.mediaIndicatorViews.count - 1));
    self.currentMediaPage = index;
    UIColor *selected = [self mediaIndicatorSelectedColor];
    UIColor *normal = [self mediaIndicatorNormalColor];
    for (NSInteger i = 0; i < self.mediaIndicatorViews.count; i++) {
        UIView *dot = self.mediaIndicatorViews[i];
        dot.backgroundColor = (i == index) ? selected : normal;
    }
}

- (void)stopActiveVideoIfNeeded {
    if (self.activeVideoPlayerView) {
        [self.activeVideoPlayerView turnOffVideoPlayback];
        [self.activeVideoPlayerView removeFromSuperview];
    }
    self.activeVideoPlayerView = nil;
    self.activeVideoIndex = NSNotFound;
    self.activeVideoURLString = nil;
}

- (void)rebuildMediaWithUnit:(YTUnit *)unit {
    [self stopActiveVideoIfNeeded];

    for (UIView *v in self.mediaScrollView.subviews.copy) {
        [v removeFromSuperview];
    }
    [self.mediaPageViews removeAllObjects];

    self.currentMediaItems = [self mediaItemsForUnit:unit];
    [self rebuildMediaIndicatorsWithCount:self.currentMediaItems.count];
    self.currentMediaPage = 0;

    for (NSInteger i = 0; i < self.currentMediaItems.count; i++) {
        NSDictionary *it = self.currentMediaItems[i];
        NSString *type = [it isKindOfClass:[NSDictionary class]] ? (it[@"type"] ?: @"") : @"";

        UIView *page = [[UIView alloc] init];
        page.backgroundColor = [UIColor clearColor];
        page.clipsToBounds = YES;
        [self.mediaScrollView addSubview:page];
        [self.mediaPageViews addObject:page];

        if ([type isEqualToString:@"video"]) {
            // 视频页：302:170 比例容器，去掉底层淡灰底；播放器在 videoHost 内再挂载
            UIView *videoShell = [[UIView alloc] init];
            videoShell.backgroundColor = [UIColor clearColor];
            videoShell.clipsToBounds = YES;
            [page addSubview:videoShell];
            [videoShell mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(page);
                make.centerY.equalTo(page);
                make.height.equalTo(videoShell.mas_width).multipliedBy(kYTTalkVideoPlayerAspectRatio);
            }];

            UIImageView *poster = [[UIImageView alloc] init];
            poster.contentMode = UIViewContentModeScaleAspectFit;
            poster.clipsToBounds = YES;
            poster.backgroundColor = [UIColor clearColor];
            poster.image = [UIImage imageNamed:@"take_img1"];
            poster.tag = kMediaVideoPosterTag;
            [videoShell addSubview:poster];
            [poster mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(videoShell);
            }];

            UIView *videoHost = [[UIView alloc] init];
            videoHost.backgroundColor = [UIColor clearColor];
            videoHost.userInteractionEnabled = YES;
            videoHost.tag = kMediaVideoHostTag;
            [videoShell addSubview:videoHost];
            [videoHost mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(videoShell);
            }];
        } else {
            UIImageView *iv = [[UIImageView alloc] init];
            iv.contentMode = UIViewContentModeScaleAspectFit;
            iv.clipsToBounds = YES;
            [page addSubview:iv];
            iv.frame = page.bounds;
            iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

            UIImage *ph = nil;
            NSString *name = it[@"name"];
            if ([name isKindOfClass:[NSString class]] && name.length > 0) {
                ph = [UIImage imageNamed:name];
            }
            if (!ph) ph = [UIImage imageNamed:@"take_img1"];

            NSString *urlStr = it[@"url"];
            if ([urlStr isKindOfClass:[NSString class]] && urlStr.length > 0) {
                NSURL *url = [NSURL URLWithString:urlStr];
                [iv sd_setImageWithURL:url placeholderImage:ph];
            } else {
                iv.image = ph;
            }
        }
    }

    [self requestMediaLayoutAndPlayAtIndex:0];
}

- (void)requestMediaLayoutAndPlayAtIndex:(NSInteger)index {
    [self.rootView layoutIfNeeded];
    [self layoutMediaPages];
    [self scrollToMediaIndex:index animated:NO];
    [self playVideoIfNeededAtIndex:index];
}

- (void)layoutMediaIfNeeded {
    // 容器尺寸变化（如旋转/外层重布局）后重新计算分页 frame，避免分页错位
    [self.rootView layoutIfNeeded];
    [self layoutMediaPages];
    [self scrollToMediaIndex:self.currentMediaPage animated:NO];
}

- (UIColor *)dashedPatternColor {
    static UIColor *cachedColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGSize size = CGSizeMake(7, 1); // 4px 实线 + 3px 空白
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        if (ctx) {
            UIColor *stroke = [theAppDelegate.window colorWithHexString:@"#E2E2E2" alpha:1.0];
            CGContextSetFillColorWithColor(ctx, stroke.CGColor);
            CGContextFillRect(ctx, CGRectMake(0, 0, 4, 1));
        }
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        cachedColor = [UIColor colorWithPatternImage:img ?: [UIImage new]];
    });
    return cachedColor;
}

- (void)layoutMediaPages {
    CGFloat w = CGRectGetWidth(self.mediaContainerView.bounds);
    CGFloat h = CGRectGetHeight(self.mediaContainerView.bounds);
    if (w <= 0 || h <= 0) return;

    for (NSInteger i = 0; i < self.mediaPageViews.count; i++) {
        UIView *page = self.mediaPageViews[i];
        page.frame = CGRectMake(w * i, 0, w, h);
        [page layoutIfNeeded];
    }
    self.mediaScrollView.contentSize = CGSizeMake(w * self.mediaPageViews.count, h);
    // 约束变化后确保滚动位置仍对齐页边界
    [self scrollToMediaIndex:self.currentMediaPage animated:NO];

    // 首次布局或旋转后，保持视频 layer 与按钮都跟随 page 尺寸
    if (self.activeVideoIndex != NSNotFound &&
        self.activeVideoIndex < self.mediaPageViews.count) {
        UIView *page = self.mediaPageViews[self.activeVideoIndex];
        if (self.activeVideoPlayerView && self.activeVideoPlayerView.superview) {
            UIView *videoHost = [page viewWithTag:kMediaVideoHostTag];
            CGRect r = videoHost ? videoHost.bounds : page.bounds;
            self.activeVideoPlayerView.frame = r;
        }
    }

}

- (void)scrollToMediaIndex:(NSInteger)index animated:(BOOL)animated {
    CGFloat w = CGRectGetWidth(self.mediaContainerView.bounds);
    if (w <= 0) return;
    index = MAX(0, MIN(index, (NSInteger)self.mediaPageViews.count - 1));
    [self.mediaScrollView setContentOffset:CGPointMake(w * index, 0) animated:animated];
    [self updateMediaIndicatorSelection:index];
}

- (void)playVideoIfNeededAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.currentMediaItems.count) return;

    NSDictionary *it = self.currentMediaItems[index];
    NSString *type = [it isKindOfClass:[NSDictionary class]] ? (it[@"type"] ?: @"") : @"";
    if (![type isEqualToString:@"video"]) {
        // 切到图片页：仅暂停，不销毁视频实例（回到视频页可继续）
        if (self.activeVideoPlayerView) {
            [self.activeVideoPlayerView pauseVideo];
        }
        return;
    }

    NSString *urlStr = [it isKindOfClass:[NSDictionary class]] ? it[@"url"] : @"";
    if (![urlStr isKindOfClass:[NSString class]] || urlStr.length == 0) return;
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) return;

    UIView *page = (index < self.mediaPageViews.count) ? self.mediaPageViews[index] : nil;
    if (!page) return;
    if (CGRectGetWidth(page.bounds) <= 0 || CGRectGetHeight(page.bounds) <= 0) {
        // 首次进入时 page 可能尚未完成布局，延迟到下一帧重试
        dispatch_async(dispatch_get_main_queue(), ^{
            [self layoutMediaIfNeeded];
            [self playVideoIfNeededAtIndex:index];
        });
        return;
    }
    BOOL shouldRecreatePlayer = (self.activeVideoPlayerView == nil ||
                                 self.activeVideoURLString.length == 0 ||
                                 ![self.activeVideoURLString isEqualToString:urlStr]);
    self.activeVideoIndex = index;

    UIView *videoHost = [page viewWithTag:kMediaVideoHostTag];
    if (!videoHost) {
        videoHost = page;
    }
    if (shouldRecreatePlayer) {
        [self stopActiveVideoIfNeeded];
        self.activeVideoIndex = index;
        self.activeVideoURLString = urlStr;

        VideoPlayerView *pv = [[VideoPlayerView alloc] initWithFrame:videoHost.bounds];
        pv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        pv.clipsToBounds = YES;
        [pv setVideoURL:url];
        if (pv.player) {
            pv.player.muted = YES;
        }
        __weak typeof(self) weakSelf = self;
        pv.enterFullScreenBlock = ^(AVPlayer *player) {
            __strong typeof(weakSelf) selfStrong = weakSelf;
            if (!selfStrong || !player) return;
            UIViewController *host = [selfStrong yt_hostViewController];
            if (!host) return;
            [KUSER_DEFAULT setObject:@"Video" forKey:Card_Type];
            VideoFullScreenViewController *vc = [[VideoFullScreenViewController alloc] init];
            vc.player = player;
            vc.modalPresentationStyle = UIModalPresentationFullScreen;
            [host presentViewController:vc animated:YES completion:nil];
        };
        [videoHost addSubview:pv];
        self.activeVideoPlayerView = pv;
    } else {
        // 复用已有播放器：重挂到当前页，避免切页时出现“重新加载闪烁”
        if (self.activeVideoPlayerView.superview != videoHost) {
            [self.activeVideoPlayerView removeFromSuperview];
            [videoHost addSubview:self.activeVideoPlayerView];
        }
        self.activeVideoPlayerView.frame = videoHost.bounds;
    }

    UIView *poster = [page viewWithTag:kMediaVideoPosterTag];
    if (poster) {
        poster.hidden = YES;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.mediaScrollView) return;
    CGFloat w = CGRectGetWidth(self.mediaContainerView.bounds);
    if (w <= 0) return;
    NSInteger idx = (NSInteger)llround(scrollView.contentOffset.x / w);
    idx = MAX(0, MIN(idx, (NSInteger)self.mediaPageViews.count - 1));
    [self updateMediaIndicatorSelection:idx];
    [self playVideoIfNeededAtIndex:idx];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView != self.mediaScrollView) return;
    CGFloat w = CGRectGetWidth(self.mediaContainerView.bounds);
    if (w <= 0) return;
    NSInteger idx = (NSInteger)llround(scrollView.contentOffset.x / w);
    idx = MAX(0, MIN(idx, (NSInteger)self.mediaPageViews.count - 1));
    [self updateMediaIndicatorSelection:idx];
    [self playVideoIfNeededAtIndex:idx];
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
    back.imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *starImg = [UIImage imageNamed:@"talk_grammar_star"];
    if (starImg) {
        starImg = [starImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    [back setImage:starImg forState:UIControlStateNormal];
    [back addTarget:self action:@selector(onTapGrammarHighlight) forControlEvents:UIControlEventTouchUpInside];
    [nav addSubview:back];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(nav).offset(16);
        make.centerY.equalTo(nav);
        make.width.height.mas_equalTo(14);
    }];

    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.textColor = BLACK_COLOR_1F;
    navTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    navTitle.text = self.unit.grammarPageNavTitle ?: NSLocalizedString(@"Grammar Rule", @"");
    [nav addSubview:navTitle];
    [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(back.mas_right).offset(3);
        make.centerY.equalTo(nav);
    }];

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    [v addSubview:divider];
    [divider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(v).inset(16);
        make.top.equalTo(nav.mas_bottom);
        make.height.mas_equalTo(1);
    }];

    UIButton *grammarFlipBackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    grammarFlipBackBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *flipImg = [UIImage imageNamed:@"talk_grammar_change"];
    if (flipImg) {
        flipImg = [flipImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    [grammarFlipBackBtn setImage:flipImg forState:UIControlStateNormal];
    [grammarFlipBackBtn addTarget:self action:@selector(onTapGrammarHighlight) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:grammarFlipBackBtn];
    [grammarFlipBackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(v);
        make.bottom.equalTo(v).offset(-18);
        make.width.height.mas_equalTo(23);
    }];

    // 内容可滚动（底部为翻转按钮留出空间，与题型页同位）
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.showsVerticalScrollIndicator = NO;
    [v addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(v);
        make.top.equalTo(divider.mas_bottom);
        make.bottom.equalTo(grammarFlipBackBtn.mas_top).offset(-8);
    }];
    [v bringSubviewToFront:grammarFlipBackBtn];

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

        // 例句之间的箭头（i>0）：自下而上渐变，底端尾色白 60%，顶端主题高亮色
        YTGrammarGradientArrowDownView *arrowView = nil;
        if (i > 0 && lastExampleView) {
            NSString *arrowStr = self.unit.grammarPageArrowText ?: @"↓";
            UIColor *tailWhite = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
            arrowView = [[YTGrammarGradientArrowDownView alloc] initWithTopColor:hl bottomTailColor:tailWhite arrowText:arrowStr];
            [content addSubview:arrowView];
            [arrowView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(lastExampleView.mas_bottom).offset(10);
                make.centerX.equalTo(content);
                make.width.mas_equalTo(28);
                make.height.mas_equalTo(22);
            }];
        }

        UIView *exView = [[UIView alloc] init];
        [content addSubview:exView];
        [exView mas_makeConstraints:^(MASConstraintMaker *make) {
            if (!lastExampleView) {
                make.top.equalTo(exampleLabel.mas_bottom).offset(10);
            } else if (arrowView) {
                make.top.equalTo(arrowView.mas_bottom).offset(10);
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

        // 竖线：从 dot 下沿开始，点状虚线（与圆点同色）
        YTGrammarDottedVerticalLineView *vertLine = [[YTGrammarDottedVerticalLineView alloc] initWithFrame:CGRectZero];
        vertLine.lineColor = dotColor;
        [exView addSubview:vertLine];
        [vertLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(dot);
            make.top.equalTo(dot.mas_bottom);
            make.bottom.equalTo(enLabel.mas_bottom);
            make.width.mas_equalTo(6);
        }];

        lastExampleView = exView;
    }

    return v;
}

- (void)onTapGrammarHighlight {
    [self flipToGrammar:NO];
}

- (void)onTapGrammarFlipToGrammar {
    if (self.unit.highlightTexts.count == 0) return;
    [self flipToGrammar:YES];
}

- (void)onPlay {
    if (self.unit.audioURLString.length == 0) {
        self.hasPlayedOnce = YES;
        self.recordHintLabel.text = NSLocalizedString(@"No reference audio; please use recording to practice.", @"");
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.audio playURLString:self.unit.audioURLString completion:^(__unused BOOL success, __unused NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.hasPlayedOnce = YES;
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
    // 已达标且主按钮已切 Continue：点击应交给容器 goNext，勿再进入开始录音分支
    if (self.completeSignalSatisfied && ![self.recording isRecording]) {
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
            if (!self) return;
            if (!success || error) {
                // 录音启动失败：恢复到可录状态，并提示可用“播放标准音”完成
                // 如果是“权限被拒绝”，把按钮切到“去设置”
                if ([error.domain isEqualToString:@"YTRecordingService"] && error.code == 2002) {
                    self.shouldOpenMicSettings = YES;
                    self.primaryState.title = @"Go to Settings to enable microphone";
                    self.recordHintLabel.text = NSLocalizedString(@"Microphone permission denied, please enable it in system settings before recording.", @"");
                } else {
                    self.primaryState.title = @"Start recording";
                    self.recordHintLabel.text = NSLocalizedString(@"Recording failed; please try again.", @"");
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

        self.lastRecordingFileURLString = fileURL.absoluteString;
#if DEBUG
        [self debugUpdatePlayMyRecordingButtonVisibility];
#endif

        NSString *expected = self.unit.titleCN.length ? self.unit.titleCN : (self.unit.titlePinyin ?: @"");
        __weak typeof(self) weakEval = self;
        [self.pronounceEvaluator evaluateRecordingAtURL:fileURL expectedText:expected completion:^(YTScoreResult * _Nullable result, NSError * _Nullable error2) {
            __strong typeof(weakEval) self = weakEval;
            if (!self) return;
            self.isScoring = NO;
            if (error2 || !result) {
                self.primaryState.title = @"Start recording";
                self.primaryState.enabled = YES;
                [self emitPrimaryState];
                self.recordHintLabel.text = NSLocalizedString(@"Scoring failed; please try again later.", @"");
                if (completion) completion(nil, error2);
                return;
            }

            if (result.verdict == YTScoreVerdictCorrect) {
                self.completeSignalSatisfied = YES;
                // 达标后主按钮走 Continue：容器才会 goNext；保留 Record 会导致 tag 仍为 Record、点击只会再进录音态
                self.primaryState.kind = YTUnitPrimaryKindContinue;
                self.primaryState.title = @"Correct";
                self.primaryState.enabled = YES;
                NSString *fmt = NSLocalizedString(@"Score %ld (completed)", @"");
                self.recordHintLabel.text = [NSString stringWithFormat:fmt, (long)result.score];
            } else {
                self.completeSignalSatisfied = NO;
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


@implementation YTPronounceUnitView
@end
