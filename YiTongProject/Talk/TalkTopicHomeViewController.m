//
//  TalkTopicHomeViewController.m
//  YiTongProject
//
//  Created by ios01 on 2026/3/17.
//

#import "TalkTopicHomeViewController.h"
#import "HeaderConfig.h"
#import "UIViewController+BackButton.h"
#import "TalkLearningFlowViewController.h"
#import "YTLearningFlowBootstrap.h"
#import "YTMockLearningFlowBootstrapService.h"
#import "YTMockUnitFactory.h"
#import "YTUnit.h"
#import "YTTalkLearningDataService.h"
#import "YTTipAlertView.h"
#import "YTTopicLevelProgressIndicator.h"
#import "YTDifficultyTheme.h"

/**
 话题主页（静态 UI + 难度入口）
 
 作用：
 - 承接 Talk 首页/列表的点击进入
 - 展示三档难度卡片（Beginner/Intermediate/Advanced）
 - 点击卡片直接进入学习流容器 `TalkLearningFlowViewController`
 - 进阶/困难：上一难度本地进度 ≥60% 才可进入，否则弹出 `YTTipAlertView`
 - 卡片右侧：`YTTopicLevelProgressIndicator`（未开始箭头 / 进行中圆环 / 完成圆+勾），数据来自本地进度
 
 约束：
 - 该页为 UI 静态稿优先，无接口；后续可接“锁定状态/进度/权益”接口
 - 统一使用工程内返回按钮（`UIViewController+BackButton`），并隐藏系统导航栏保证视觉一致
 */
static NSString *const kTalkTopicSceneId = @"scene_school";

@interface TalkTopicHomeViewController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *backgroundDimView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *lockStackView;
@property (nonatomic, strong) UIImageView *beginnerLockImageView;
@property (nonatomic, strong) UIImageView *intermediateLockImageView;
@property (nonatomic, strong) UIImageView *advancedLockImageView;

@property (nonatomic, strong) UIStackView *cardsStackView;

@property (nonatomic, strong) UIView *beginnerCard;
@property (nonatomic, strong) UIView *intermediateCard;
@property (nonatomic, strong) UIView *advancedCard;

@property (nonatomic, strong) YTTopicLevelProgressIndicator *beginnerProgressIndicator;
@property (nonatomic, strong) YTTopicLevelProgressIndicator *intermediateProgressIndicator;
@property (nonatomic, strong) YTTopicLevelProgressIndicator *advancedProgressIndicator;

@property (nonatomic, assign) BOOL isRequestingUnits;

@end

@implementation TalkTopicHomeViewController

#pragma mark - 生命周期

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 使用工程统一的全局返回按钮（同首页 push 后页面一致），因此隐藏系统导航栏避免重叠
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self refreshTopicLevelProgressIndicators];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // viewWillAppear 往往早于卡片/指示器首帧布局，圆环 path 未建立时描边不画；布局完成后再刷一次进度与主题色
    [self refreshTopicLevelProgressIndicators];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 离开后恢复，避免影响其它页面
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"talk_topic_home";
    self.view.backgroundColor = [theAppDelegate.window colorWithHexString:@"#F6F8FF" alpha:1];

    [self setupUI];
    // 返回按钮统一走工程封装（图标/点击区域等）
    [self addGlobalBackButtonColor:[UIColor colorWithWhite:1.0 alpha:0.85] headerTitleDic:@{}];
}

#pragma mark - UI

- (void)setupUI {
    [self.view addSubview:self.backgroundImageView];
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        UIImage *img = self.backgroundImageView.image;
        if (img && img.size.width > 0 && img.size.height > 0) {
            // 顶部背景图：宽度100%，高度按原图比例自适应
            CGFloat ratio = img.size.height / img.size.width;
            make.height.equalTo(self.view.mas_width).multipliedBy(ratio);
        } else {
            // 无图时兜底高度，避免布局崩
            make.height.mas_equalTo(260);
        }
    }];

    [self.view addSubview:self.backgroundDimView];
    [self.backgroundDimView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.backgroundImageView);
    }];

    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        make.top.mas_equalTo(statusBarH + 45 + 13);
        make.left.greaterThanOrEqualTo(self.view).offset(16);
        make.right.lessThanOrEqualTo(self.view).offset(-16);
    }];

    [self.view addSubview:self.subtitleLabel];
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.greaterThanOrEqualTo(self.view).offset(16);
        make.right.lessThanOrEqualTo(self.view).offset(-16);
    }];

    [self.view addSubview:self.lockStackView];
    [self.lockStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(18);
        make.height.mas_equalTo(42);
    }];

    [self.view addSubview:self.cardsStackView];
    [self.cardsStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(self.lockStackView.mas_bottom).offset(80);
    }];

    [self.cardsStackView addArrangedSubview:self.beginnerCard];
    [self.cardsStackView addArrangedSubview:self.intermediateCard];
    [self.cardsStackView addArrangedSubview:self.advancedCard];

    [self.beginnerCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(86);
    }];
    [self.intermediateCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(86);
    }];
    [self.advancedCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(86);
    }];
}

- (UIView *)buildCardWithTitle:(NSString *)title
                      subtitle:(NSString *)subtitle
                trailingWidget:(UIView *)trailingWidget
{
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 16;
    card.layer.masksToBounds = YES;

    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowRadius = 10;
    card.layer.shadowOffset = CGSizeMake(0, 6);
    card.layer.masksToBounds = NO;

    UIView *content = [[UIView alloc] init];
    content.backgroundColor = [UIColor whiteColor];
    content.layer.cornerRadius = 16;
    content.layer.masksToBounds = YES;
    [card addSubview:content];
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card);
    }];

    UILabel *lblTitle = [[UILabel alloc] init];
    lblTitle.text = title;
    lblTitle.textColor = BLACK_COLOR_1F;
    lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
    [content addSubview:lblTitle];

    UILabel *lblSubtitle = [[UILabel alloc] init];
    lblSubtitle.text = subtitle;
    lblSubtitle.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
    [content addSubview:lblSubtitle];

    [content addSubview:trailingWidget];

    [lblTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(content).offset(18);
        make.top.equalTo(content).offset(18);
        make.right.lessThanOrEqualTo(trailingWidget.mas_left).offset(-12);
    }];

    [lblSubtitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(lblTitle);
        make.top.equalTo(lblTitle.mas_bottom).offset(6);
        make.right.lessThanOrEqualTo(trailingWidget.mas_left).offset(-12);
    }];

    [trailingWidget mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(content);
        make.right.equalTo(content).offset(-16);
    }];

    return card;
}

#pragma mark - 进度展示

- (CGFloat)yt_talkProgressRatioForLevel:(YTLevelId)levelId {
    NSArray<YTUnit *> *units = [YTMockUnitFactory learningFlowUnitsForSceneId:kTalkTopicSceneId levelId:levelId];
    __block NSSet<NSString *> *completedIds = [NSSet set];
    [[YTTalkLearningDataService shared] fetchLearningProgressForSceneId:kTalkTopicSceneId
                                                                levelId:levelId
                                                             completion:^(YTLastPosition * _Nullable lastPosition, NSArray<NSString *> *completedUnitIds, NSError * _Nullable error) {
        completedIds = [NSSet setWithArray:completedUnitIds ?: @[]];
    }];
    return [YTMockUnitFactory progressRatioForUnits:units completedUnitIdentifiers:completedIds];
}

- (void)refreshTopicLevelProgressIndicators {
    CGFloat beginnerRatio = [self yt_talkProgressRatioForLevel:YTLevelIdBeginner];
    CGFloat intermediateRatio = [self yt_talkProgressRatioForLevel:YTLevelIdIntermediate];
    CGFloat advancedRatio = [self yt_talkProgressRatioForLevel:YTLevelIdAdvanced];

    [self.beginnerProgressIndicator configureWithProgressRatio:beginnerRatio
                                                         theme:[YTDifficultyTheme themeForLevel:YTLevelIdBeginner]];
    [self.intermediateProgressIndicator configureWithProgressRatio:intermediateRatio
                                                             theme:[YTDifficultyTheme themeForLevel:YTLevelIdIntermediate]];
    [self.advancedProgressIndicator configureWithProgressRatio:advancedRatio
                                                         theme:[YTDifficultyTheme themeForLevel:YTLevelIdAdvanced]];

    [self yt_updateLockBadgesWithBeginner:beginnerRatio intermediate:intermediateRatio advanced:advancedRatio];
}

- (BOOL)yt_useChineseLockBadge {
    NSString *lang = [NSLocale preferredLanguages].firstObject ?: @"";
    return [lang hasPrefix:@"zh"];
}

- (NSString *)yt_unlockBadgeImageNameForLevel:(YTLevelId)levelId {
    NSString *difficulty = @"advanced";
    if (levelId == YTLevelIdBeginner) {
        difficulty = @"beginner";
    } else if (levelId == YTLevelIdIntermediate) {
        difficulty = @"intermediate";
    }
    NSString *langToken = [self yt_useChineseLockBadge] ? @"zh" : @"en";
    return [NSString stringWithFormat:@"talk_level_badge_unlock_%@_%@", difficulty, langToken];
}

- (void)yt_updateLockImageView:(UIImageView *)imageView levelId:(YTLevelId)levelId unlocked:(BOOL)unlocked {
    UIImage *img = nil;
    if (unlocked) {
        NSString *name = [self yt_unlockBadgeImageNameForLevel:levelId];
        img = [UIImage imageNamed:name];
        // 兼容历史错误资源名：beginner_zh imageset 目录尾部误带了换行符
        if (!img && levelId == YTLevelIdBeginner && [self yt_useChineseLockBadge]) {
            img = [UIImage imageNamed:@"talk_level_badge_unlock_beginner_zh\n"];
        }
    }
    if (!img) {
        img = [UIImage imageNamed:@"talk_lock"];
    }
    imageView.image = img;
}

- (void)yt_updateLockBadgesWithBeginner:(CGFloat)beginnerRatio
                           intermediate:(CGFloat)intermediateRatio
                                advanced:(CGFloat)advancedRatio {
    [self yt_updateLockImageView:self.beginnerLockImageView levelId:YTLevelIdBeginner unlocked:(beginnerRatio >= 1.0 - 1e-5)];
    [self yt_updateLockImageView:self.intermediateLockImageView levelId:YTLevelIdIntermediate unlocked:(intermediateRatio >= 1.0 - 1e-5)];
    [self yt_updateLockImageView:self.advancedLockImageView levelId:YTLevelIdAdvanced unlocked:(advancedRatio >= 1.0 - 1e-5)];
}

#pragma mark - 懒加载

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.clipsToBounds = YES;
        _backgroundImageView.image = [UIImage imageNamed:@"talk_topic_bg"];
        if (!_backgroundImageView.image) {
            _backgroundImageView.backgroundColor = [theAppDelegate.window colorWithHexString:@"#F6F8FF" alpha:1];
        }
    }
    return _backgroundImageView;
}

- (UIView *)backgroundDimView {
    if (!_backgroundDimView) {
        _backgroundDimView = [[UIView alloc] init];
        _backgroundDimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.18];
    }
    return _backgroundDimView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = NSLocalizedString(@"Talk_TopicHome_Title", @"");
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:26];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.text = NSLocalizedString(@"Talk_TopicHome_Subtitle", @"");
        _subtitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.85];
        _subtitleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 2;
    }
    return _subtitleLabel;
}

- (UIStackView *)lockStackView {
    if (!_lockStackView) {
        _lockStackView = [[UIStackView alloc] init];
        _lockStackView.axis = UILayoutConstraintAxisHorizontal;
        _lockStackView.alignment = UIStackViewAlignmentCenter;
        _lockStackView.distribution = UIStackViewDistributionEqualSpacing;
        _lockStackView.spacing = 10;
        [_lockStackView addArrangedSubview:self.beginnerLockImageView];
        [_lockStackView addArrangedSubview:self.intermediateLockImageView];
        [_lockStackView addArrangedSubview:self.advancedLockImageView];
    }
    return _lockStackView;
}

- (UIImageView *)beginnerLockImageView {
    if (!_beginnerLockImageView) {
        _beginnerLockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"talk_lock"]];
        _beginnerLockImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_beginnerLockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(42);
        }];
    }
    return _beginnerLockImageView;
}

- (UIImageView *)intermediateLockImageView {
    if (!_intermediateLockImageView) {
        _intermediateLockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"talk_lock"]];
        _intermediateLockImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_intermediateLockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(42);
        }];
    }
    return _intermediateLockImageView;
}

- (UIImageView *)advancedLockImageView {
    if (!_advancedLockImageView) {
        _advancedLockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"talk_lock"]];
        _advancedLockImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_advancedLockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(42);
        }];
    }
    return _advancedLockImageView;
}

- (UIStackView *)cardsStackView {
    if (!_cardsStackView) {
        _cardsStackView = [[UIStackView alloc] init];
        _cardsStackView.axis = UILayoutConstraintAxisVertical;
        _cardsStackView.alignment = UIStackViewAlignmentFill;
        _cardsStackView.distribution = UIStackViewDistributionFill;
        _cardsStackView.spacing = 20;
    }
    return _cardsStackView;
}

- (UIView *)beginnerCard {
    if (!_beginnerCard) {
        _beginnerCard = [self buildCardWithTitle:NSLocalizedString(@"Beginner", @"")
                                        subtitle:NSLocalizedString(@"Key Vocabulary", @"")
                                  trailingWidget:self.beginnerProgressIndicator];
        _beginnerCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBeginner)];
        [_beginnerCard addGestureRecognizer:tap];
    }
    return _beginnerCard;
}

- (UIView *)intermediateCard {
    if (!_intermediateCard) {
        _intermediateCard = [self buildCardWithTitle:NSLocalizedString(@"Simple", @"")
                                            subtitle:NSLocalizedString(@"Basic Dialogue & Grammar", @"")
                                      trailingWidget:self.intermediateProgressIndicator];
        _intermediateCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapIntermediate)];
        [_intermediateCard addGestureRecognizer:tap];
    }
    return _intermediateCard;
}

- (UIView *)advancedCard {
    if (!_advancedCard) {
        _advancedCard = [self buildCardWithTitle:NSLocalizedString(@"Difficult", @"")
                                        subtitle:NSLocalizedString(@"Politeness, Nuance & Real-life Logic", @"")
                                  trailingWidget:self.advancedProgressIndicator];
        _advancedCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAdvanced)];
        [_advancedCard addGestureRecognizer:tap];
    }
    return _advancedCard;
}

- (YTTopicLevelProgressIndicator *)beginnerProgressIndicator {
    if (!_beginnerProgressIndicator) {
        _beginnerProgressIndicator = [[YTTopicLevelProgressIndicator alloc] init];
    }
    return _beginnerProgressIndicator;
}

- (YTTopicLevelProgressIndicator *)intermediateProgressIndicator {
    if (!_intermediateProgressIndicator) {
        _intermediateProgressIndicator = [[YTTopicLevelProgressIndicator alloc] init];
    }
    return _intermediateProgressIndicator;
}

- (YTTopicLevelProgressIndicator *)advancedProgressIndicator {
    if (!_advancedProgressIndicator) {
        _advancedProgressIndicator = [[YTTopicLevelProgressIndicator alloc] init];
    }
    return _advancedProgressIndicator;
}

#pragma mark - 交互

- (void)onTapBeginner {
    [self pushLearningFlowWithLevel:YTLevelIdBeginner];
}

- (void)onTapIntermediate {
    [self pushLearningFlowWithLevel:YTLevelIdIntermediate];
}

- (void)onTapAdvanced {
    [self pushLearningFlowWithLevel:YTLevelIdAdvanced];
}

- (void)pushLearningFlowWithLevel:(YTLevelId)levelId {
    if (self.isRequestingUnits) return;

    static const CGFloat kPreviousLevelUnlockProgress = 0.6;

    if (levelId == YTLevelIdIntermediate || levelId == YTLevelIdAdvanced) {
        YTLevelId previousLevel = (YTLevelId)(levelId - 1);
        NSArray<YTUnit *> *prevUnits = [YTMockUnitFactory learningFlowUnitsForSceneId:kTalkTopicSceneId levelId:previousLevel];
        __block NSSet<NSString *> *completedIds = [NSSet set];
        [[YTTalkLearningDataService shared] fetchLearningProgressForSceneId:kTalkTopicSceneId
                                                                    levelId:previousLevel
                                                                 completion:^(YTLastPosition * _Nullable lastPosition, NSArray<NSString *> *completedUnitIds, NSError * _Nullable error) {
            completedIds = [NSSet setWithArray:completedUnitIds ?: @[]];
        }];
        CGFloat progress = [YTMockUnitFactory progressRatioForUnits:prevUnits completedUnitIdentifiers:completedIds];
        if (progress < kPreviousLevelUnlockProgress) {
            NSString *msg = (levelId == YTLevelIdIntermediate)
                ? NSLocalizedString(@"您需要入门级学习进度完成度为60%才能进入进阶难度", @"")
                : NSLocalizedString(@"您需要进阶难度学习进度完成度为60%才能进入困难难度", @"");
            [YTTipAlertView showInView:self.view message:msg];
            return;
        }
    }

    self.isRequestingUnits = YES;

    [[GlobalHUDManager shared] showOrUpdateMessage:NSLocalizedString(@"Processing...", @"")];

    __weak typeof(self) weakSelf = self;
    [[YTMockLearningFlowBootstrapService shared] fetchBootstrapForSceneId:kTalkTopicSceneId levelId:levelId completion:^(YTLearningFlowBootstrap * _Nullable bootstrap, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isRequestingUnits = NO;
        [[GlobalHUDManager shared] hide];
        if (!bootstrap || error) return;

        TalkLearningFlowViewController *vc = [[TalkLearningFlowViewController alloc] initWithSceneId:kTalkTopicSceneId
                                                                                              levelId:levelId
                                                                                   preloadedBootstrap:bootstrap];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

@end
