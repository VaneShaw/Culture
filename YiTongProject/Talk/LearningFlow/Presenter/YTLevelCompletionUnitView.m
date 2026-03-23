//
//  YTLevelCompletionUnitView.m
//  YiTongProject
//

#import "YTLevelCompletionUnitView.h"
#import "YTInternalUnitViewSupport.h"
#import "YTAnswerEvaluating.h"
#import "YTPronounceEvaluating.h"
#import "HeaderConfig.h"

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

        _badgeImageView = [[UIImageView alloc] init];
        _badgeImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_scrollContentView addSubview:_badgeImageView];
        [_badgeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.scrollContentView).offset(35);
            make.centerX.equalTo(self.scrollContentView);
            make.width.height.mas_equalTo(214);
        }];

        _scoreLabel = [[UILabel alloc] init];
        _scoreLabel.textAlignment = NSTextAlignmentCenter;
        _scoreLabel.textColor = [UIColor whiteColor];
        _scoreLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:90] ?: [UIFont systemFontOfSize:90 weight:UIFontWeightBold];
        [_scrollContentView addSubview:_scoreLabel];
        [_scoreLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeImageView.mas_bottom).offset(20);
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
        self.scoreLabel.text = NSLocalizedString(@"Talk_LevelComplete_Beginner_Score", @"");
        [self.scoreLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeImageView.mas_bottom).offset(20);
            make.centerX.equalTo(self.scrollContentView);
        }];
        [self.headlineLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.scoreLabel.mas_bottom).offset(8);
            make.left.right.equalTo(self.scrollContentView).inset(16);
        }];
    } else {
        [self.scoreLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeImageView.mas_bottom).offset(0);
            make.centerX.equalTo(self.scrollContentView);
            make.height.mas_equalTo(0);
        }];
        [self.headlineLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeImageView.mas_bottom).offset(24);
            make.left.right.equalTo(self.scrollContentView).inset(16);
        }];
    }

    if (unit.levelId == YTLevelIdBeginner) {
        self.headlineLabel.text = NSLocalizedString(@"Talk_LevelComplete_Beginner_Headline", @"");
        self.subtitleLabel.text = NSLocalizedString(@"Talk_LevelComplete_Beginner_Subtitle", @"");
    } else if (unit.levelId == YTLevelIdIntermediate) {
        self.headlineLabel.text = NSLocalizedString(@"Talk_LevelComplete_Intermediate_Headline", @"");
        self.subtitleLabel.text = NSLocalizedString(@"Talk_LevelComplete_Intermediate_Subtitle", @"");
    } else {
        self.headlineLabel.text = NSLocalizedString(@"Talk_LevelComplete_Advanced_Headline", @"");
        self.subtitleLabel.text = NSLocalizedString(@"Talk_LevelComplete_Advanced_Subtitle", @"");
    }

    UIImage *img = [UIImage imageNamed:[self yt_badgeImageNameForLevel:unit.levelId]];
    if (!img) {
        // 兼容旧资源名，避免素材未同步时出现空白
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
    if (unit.levelId == YTLevelIdAdvanced) {
        self.primaryState.title = @"Talk_LevelComplete_Primary_Explore";
    } else {
        self.primaryState.title = @"Talk_LevelComplete_Primary_MoveNext";
    }
    self.primaryState.enabled = YES;
    [self emitPrimaryState];
}

@end

