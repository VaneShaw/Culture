//
//  YTLevelCompletionUnitView.m
//  YiTongProject
//

#import "YTLevelCompletionUnitView.h"
#import "YTInternalUnitViewSupport.h"
#import "YTAnswerEvaluating.h"
#import "YTPronounceEvaluating.h"
#import "HeaderConfig.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kYTBadgeAreaSize = 214.0;
static const CGFloat kYTBadgeForegroundW = 120.0;
static const CGFloat kYTBadgeForegroundH = 135.0;

static UIColor *YTLevelCompleteCardFill(YTDifficultyTheme *theme) {
    UIColor *pc = theme.primaryColor;
    CGFloat r, g, b, a;
    if (![pc getRed:&r green:&g blue:&b alpha:&a]) {
        return pc;
    }
    const CGFloat k = 0.88f;
    return [UIColor colorWithRed:MIN(1.f, r * k) green:MIN(1.f, g * k) blue:MIN(1.f, b * k) alpha:a];
}

@interface YTLevelCompletionUnitView ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
/// 徽章区域：与原先单张背景图同尺寸，内叠放光晕 + 徽章
@property (nonatomic, strong) UIView *badgeContainerView;
@property (nonatomic, strong) UIImageView *badgeGlowImageView;
@property (nonatomic, strong) UIImageView *badgeImageView;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *headlineLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@end


@implementation YTLevelCompletionUnitView

- (BOOL)yt_shouldUseChineseBadge {
    NSString *lang = [NSLocale preferredLanguages].firstObject ?: @"";
    return [lang hasPrefix:@"zh"];
}

- (NSString *)yt_badgeImageNameForLevel:(YTLevelId)levelId {
    NSString *levelToken = @"advanced";
    if (levelId == YTLevelIdBeginner) {
        levelToken = @"beginner";
    } else if (levelId == YTLevelIdIntermediate) {
        levelToken = @"intermediate";
    }
    NSString *langToken = [self yt_shouldUseChineseBadge] ? @"zh" : @"en";
    return [NSString stringWithFormat:@"talk_level_complete_badge_%@_%@", levelToken, langToken];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cardView = [[UIView alloc] init];
        _cardView.layer.cornerRadius = 18;
        _cardView.layer.masksToBounds = YES;
        [self.rootView addSubview:_cardView];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.rootView);
        }];

        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = NO;
        [_cardView addSubview:_scrollView];
        [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.cardView);
        }];

        _scrollContentView = [[UIView alloc] init];
        [_scrollView addSubview:_scrollContentView];
        [_scrollContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.scrollView);
            make.width.equalTo(self.scrollView);
        }];

        _badgeContainerView = [[UIView alloc] init];
        _badgeContainerView.backgroundColor = [UIColor clearColor];
        [_scrollContentView addSubview:_badgeContainerView];
        [_badgeContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.scrollContentView).offset(35);
            make.centerX.equalTo(self.scrollContentView);
            make.width.height.mas_equalTo(kYTBadgeAreaSize);
        }];

        _badgeGlowImageView = [[UIImageView alloc] init];
        _badgeGlowImageView.contentMode = UIViewContentModeScaleAspectFit;
        _badgeGlowImageView.image = [UIImage imageNamed:@"talk_animated_light"];
        [_badgeContainerView addSubview:_badgeGlowImageView];
        [_badgeGlowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.badgeContainerView);
            make.width.height.mas_equalTo(kYTBadgeAreaSize);
        }];

        _badgeImageView = [[UIImageView alloc] init];
        _badgeImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_badgeContainerView addSubview:_badgeImageView];
        [_badgeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.badgeContainerView);
            make.width.mas_equalTo(kYTBadgeForegroundW);
            make.height.mas_equalTo(kYTBadgeForegroundH);
        }];

        _scoreLabel = [[UILabel alloc] init];
        _scoreLabel.textAlignment = NSTextAlignmentCenter;
        _scoreLabel.textColor = [UIColor whiteColor];
        _scoreLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:90] ?: [UIFont systemFontOfSize:90 weight:UIFontWeightBold];
        [_scrollContentView addSubview:_scoreLabel];
        [_scoreLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeContainerView.mas_bottom).offset(20);
            make.centerX.equalTo(self.scrollContentView);
        }];

        _headlineLabel = [[UILabel alloc] init];
        _headlineLabel.textAlignment = NSTextAlignmentCenter;
        _headlineLabel.textColor = [UIColor whiteColor];
        _headlineLabel.numberOfLines = 0;
        _headlineLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];
        [_scrollContentView addSubview:_headlineLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        _subtitleLabel.numberOfLines = 0;
        _subtitleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15] ?: [UIFont systemFontOfSize:15];
        [_scrollContentView addSubview:_subtitleLabel];

        [_headlineLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.scoreLabel.mas_bottom).offset(8);
            make.left.right.equalTo(self.scrollContentView).inset(16);
        }];
        [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.headlineLabel.mas_bottom).offset(10);
            make.left.right.equalTo(self.scrollContentView).inset(16);
            make.bottom.equalTo(self.scrollContentView).offset(-28);
        }];
    }
    return self;
}

- (void)yt_startBadgeGlowRotationIfNeeded {
    UIImage *glow = self.badgeGlowImageView.image;
    if (!glow) {
        return;
    }
    CALayer *layer = self.badgeGlowImageView.layer;
    [layer removeAnimationForKey:@"yt_badge_glow_rotation"];
    CABasicAnimation *rot = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rot.fromValue = @(0);
    rot.toValue = @(M_PI * 2.0);
    rot.duration = 18.0;
    rot.repeatCount = HUGE_VALF;
    rot.removedOnCompletion = NO;
    [layer addAnimation:rot forKey:@"yt_badge_glow_rotation"];
}

- (void)configureWithUnit:(YTUnit *)unit
                    theme:(YTDifficultyTheme *)theme
                    audio:(YTAudioMuxService *)audio
                recording:(YTRecordingService *)recording
       pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator
          answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator
{
    [super configureWithUnit:unit theme:theme audio:audio recording:recording pronounceEvaluator:pronounceEvaluator answerEvaluator:answerEvaluator];
    self.completeSignalSatisfied = YES;

    self.cardView.backgroundColor = YTLevelCompleteCardFill(theme);

    BOOL isBeginner = (unit.levelId == YTLevelIdBeginner);
    self.scoreLabel.hidden = !isBeginner;
    if (isBeginner) {
        self.scoreLabel.text = unit.completionScoreText ?: @"";
        [self.scoreLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeContainerView.mas_bottom).offset(20);
            make.centerX.equalTo(self.scrollContentView);
        }];
        [self.headlineLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.scoreLabel.mas_bottom).offset(8);
            make.left.right.equalTo(self.scrollContentView).inset(16);
        }];
    } else {
        [self.scoreLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeContainerView.mas_bottom).offset(0);
            make.centerX.equalTo(self.scrollContentView);
            make.height.mas_equalTo(0);
        }];
        [self.headlineLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeContainerView.mas_bottom).offset(24);
            make.left.right.equalTo(self.scrollContentView).inset(16);
        }];
    }

    {
        NSString *instr = [unit yt_resolvedStemInstructionText];
        self.headlineLabel.text = instr.length ? instr : [unit yt_resolvedTitleDisplayText];
    }
    self.subtitleLabel.text = unit.completionSubtitle ?: @"";

    UIImage *img = [UIImage imageNamed:[self yt_badgeImageNameForLevel:unit.levelId]];
    if (!img) {
        img = [UIImage imageNamed:@"talk_level_complete_badge"];
    }
    if (!img && @available(iOS 13.0, *)) {
        if (unit.levelId == YTLevelIdBeginner) {
            img = [UIImage systemImageNamed:@"leaf.fill"];
        } else if (unit.levelId == YTLevelIdIntermediate) {
            img = [UIImage systemImageNamed:@"location.north.circle.fill"];
        } else {
            img = [UIImage systemImageNamed:@"mountain.2.fill"];
        }
        self.badgeImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.badgeImageView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.95];
    } else {
        self.badgeImageView.image = img;
        self.badgeImageView.tintColor = img ? nil : [UIColor whiteColor];
    }

    self.primaryState.kind = YTUnitPrimaryKindContinue;
    self.primaryState.title = (unit.levelId == YTLevelIdAdvanced) ? @"Talk_LevelComplete_Primary_Explore" : @"Talk_LevelComplete_Primary_MoveNext";
    self.primaryState.enabled = YES;
    [self emitPrimaryState];

    // Presenter 是 NSObject：`configure` 早于容器把 `rootView` 挂上，下一 runloop 再启动画
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self yt_startBadgeGlowRotationIfNeeded];
    });
}

@end

