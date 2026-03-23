//
//  YTPracticeTransitionUnitView.m
//  YiTongProject
//

#import "YTPracticeTransitionUnitView.h"
#import "YTInternalUnitViewSupport.h"
#import "YTAnswerEvaluating.h"
#import "YTPronounceEvaluating.h"
#import "HeaderConfig.h"

/// 卡片底：比难度页背景色略深一点（与主色 token 区分，避免过重）
static UIColor *YTPracticeTransitionCardBackground(YTDifficultyTheme *theme) {
    UIColor *base = theme.backgroundColor ?: theme.primaryColor;
    CGFloat r = 0, g = 0, b = 0, a = 1;
    if (![base getRed:&r green:&g blue:&b alpha:&a]) {
        return base;
    }
    const CGFloat k = 0.94;
    return [UIColor colorWithRed:MIN(1.f, r * k) green:MIN(1.f, g * k) blue:MIN(1.f, b * k) alpha:a];
}

@interface YTPracticeTransitionUnitView ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) UIImageView *badgeImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *advancedStack;
@property (nonatomic, strong) UILabel *advSection1Caption;
@property (nonatomic, strong) UILabel *advSection1Body;
@property (nonatomic, strong) UILabel *advSection2Caption;
@property (nonatomic, strong) UILabel *advSection2Body;
@property (nonatomic, strong) UIStackView *tailStack;
@end


@implementation YTPracticeTransitionUnitView

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
        _scrollView.alwaysBounceVertical = YES;
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
            make.top.equalTo(self.scrollContentView).offset(56);
            make.centerX.equalTo(self.scrollContentView);
            make.width.mas_equalTo(162);
            make.height.mas_equalTo(172);
        }];

        UIColor *titleInk = [theAppDelegate.window colorWithHexString:@"#1F2540" alpha:1];
        UIColor *subInk = [UIColor colorWithRed:0x63 / 255.0 green:0x63 / 255.0 blue:0x7D / 255.0 alpha:1];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = titleInk;
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22];
        [_scrollContentView addSubview:_titleLabel];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeImageView.mas_bottom).offset(66);
            make.left.right.equalTo(self.scrollContentView).inset(16);
        }];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 0;
        _subtitleLabel.textColor = subInk;
        _subtitleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15] ?: [UIFont systemFontOfSize:15];
        [_scrollContentView addSubview:_subtitleLabel];

        _advSection1Caption = [[UILabel alloc] init];
        _advSection1Caption.numberOfLines = 0;
        _advSection1Caption.textAlignment = NSTextAlignmentLeft;
        _advSection1Caption.font = [UIFont fontWithName:FONT_NAME_Semibold size:13] ?: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];

        _advSection1Body = [[UILabel alloc] init];
        _advSection1Body.numberOfLines = 0;
        _advSection1Body.textAlignment = NSTextAlignmentLeft;
        _advSection1Body.textColor = titleInk;
        _advSection1Body.font = [UIFont fontWithName:FONT_NAME_Regular size:15] ?: [UIFont systemFontOfSize:15];

        _advSection2Caption = [[UILabel alloc] init];
        _advSection2Caption.numberOfLines = 0;
        _advSection2Caption.textAlignment = NSTextAlignmentLeft;
        _advSection2Caption.font = _advSection1Caption.font;

        _advSection2Body = [[UILabel alloc] init];
        _advSection2Body.numberOfLines = 0;
        _advSection2Body.textAlignment = NSTextAlignmentLeft;
        _advSection2Body.textColor = titleInk;
        _advSection2Body.font = _advSection1Body.font;

        _advancedStack = [[UIStackView alloc] initWithArrangedSubviews:@[
            _advSection1Caption, _advSection1Body, _advSection2Caption, _advSection2Body
        ]];
        _advancedStack.axis = UILayoutConstraintAxisVertical;
        _advancedStack.alignment = UIStackViewAlignmentFill;
        _advancedStack.spacing = 6;
        _advancedStack.hidden = YES;
        [_advancedStack setCustomSpacing:14 afterView:_advSection1Body];

        _tailStack = [[UIStackView alloc] initWithArrangedSubviews:@[ _subtitleLabel, _advancedStack ]];
        _tailStack.axis = UILayoutConstraintAxisVertical;
        _tailStack.alignment = UIStackViewAlignmentFill;
        _tailStack.spacing = 0;
        [_scrollContentView addSubview:_tailStack];
        [_tailStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
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

    self.cardView.backgroundColor = YTPracticeTransitionCardBackground(theme);

    NSString *title = NSLocalizedString(@"Talk_PracticeTransition_Title_Beginner", @"");
    if (unit.levelId == YTLevelIdIntermediate) {
        title = NSLocalizedString(@"Talk_PracticeTransition_Title_Intermediate", @"");
    } else if (unit.levelId == YTLevelIdAdvanced) {
        title = NSLocalizedString(@"Talk_PracticeTransition_Title_Advanced", @"");
    }
    self.titleLabel.text = title;

    UIColor *captionTint = theme.primaryColor;
    CGFloat cr = 0, cg = 0, cb = 0, ca = 1;
    if ([captionTint getRed:&cr green:&cg blue:&cb alpha:&ca]) {
        self.advSection1Caption.textColor = [UIColor colorWithRed:cr green:cg blue:cb alpha:0.68];
        self.advSection2Caption.textColor = self.advSection1Caption.textColor;
    } else {
        self.advSection1Caption.textColor = [captionTint colorWithAlphaComponent:0.68f];
        self.advSection2Caption.textColor = self.advSection1Caption.textColor;
    }

    CGFloat tailGap = (unit.levelId == YTLevelIdAdvanced) ? 18 : 10;
    [self.tailStack mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(tailGap);
    }];

    if (unit.levelId == YTLevelIdAdvanced) {
        self.subtitleLabel.hidden = YES;
        self.advancedStack.hidden = NO;
        self.advSection1Caption.text = NSLocalizedString(@"Talk_PracticeTransition_AdvSec1_Label", @"");
        self.advSection1Body.text = NSLocalizedString(@"Talk_PracticeTransition_AdvSec1_Body", @"");
        self.advSection2Caption.text = NSLocalizedString(@"Talk_PracticeTransition_AdvSec2_Label", @"");
        self.advSection2Body.text = NSLocalizedString(@"Talk_PracticeTransition_AdvSec2_Body", @"");

        UIImage *img = nil;
        if (@available(iOS 13.0, *)) {
            img = [UIImage systemImageNamed:@"star.circle.fill"];
            self.badgeImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.badgeImageView.tintColor = theme.primaryColor;
        }
        if (!self.badgeImageView.image) {
            img = [UIImage imageNamed:@"talk_practice_transition_badge"];
            self.badgeImageView.image = img;
            self.badgeImageView.tintColor = nil;
        }
    } else {
        self.subtitleLabel.hidden = NO;
        self.advancedStack.hidden = YES;
        if (unit.levelId == YTLevelIdIntermediate) {
            self.subtitleLabel.text = NSLocalizedString(@"Talk_PracticeTransition_Subtitle_Intermediate", @"");
            UIImage *img = nil;
            if (@available(iOS 13.0, *)) {
                UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:96 weight:UIImageSymbolWeightRegular];
                img = [UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:cfg];
                self.badgeImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.badgeImageView.tintColor = theme.primaryColor;
            }
            if (!self.badgeImageView.image) {
                img = [UIImage imageNamed:@"talk_practice_transition_badge"];
                self.badgeImageView.image = img;
                self.badgeImageView.tintColor = nil;
            }
        } else {
            self.subtitleLabel.text = NSLocalizedString(@"Talk_PracticeTransition_Subtitle", @"");
            UIImage *badge = [UIImage imageNamed:@"talk_practice_transition_badge"];
            if (!badge && @available(iOS 13.0, *)) {
                badge = [UIImage systemImageNamed:@"checkmark.seal.fill"];
                self.badgeImageView.image = [badge imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.badgeImageView.tintColor = theme.primaryColor;
            } else {
                self.badgeImageView.image = badge;
                self.badgeImageView.tintColor = nil;
            }
        }
    }

    self.primaryState.kind = YTUnitPrimaryKindContinue;
    self.primaryState.title = @"Talk_Continue";
    self.primaryState.enabled = YES;
    [self emitPrimaryState];
}

@end

