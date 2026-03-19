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
#import "YTMockUnitFactory.h"

/**
 话题主页（静态 UI + 难度入口）
 
 作用：
 - 承接 Talk 首页/列表的点击进入
 - 展示三档难度卡片（Beginner/Intermediate/Advanced）
 - 点击卡片直接进入学习流容器 `TalkLearningFlowViewController`
 
 约束：
 - 该页为 UI 静态稿优先，无接口；后续可接“锁定状态/进度/权益”接口
 - 统一使用工程内返回按钮（`UIViewController+BackButton`），并隐藏系统导航栏保证视觉一致
 */
@interface TalkTopicHomeViewController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *backgroundDimView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *lockStackView;

@property (nonatomic, strong) UIStackView *cardsStackView;

@property (nonatomic, strong) UIView *beginnerCard;
@property (nonatomic, strong) UIView *intermediateCard;
@property (nonatomic, strong) UIView *advancedCard;

@property (nonatomic, strong) UIView *beginnerProgressContainer;
@property (nonatomic, strong) UILabel *beginnerProgressLabel;
@property (nonatomic, assign) BOOL didSetupProgressLayers;

@property (nonatomic, assign) BOOL isRequestingUnits;

@end

@implementation TalkTopicHomeViewController

#pragma mark - 生命周期

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 使用工程统一的全局返回按钮（同首页 push 后页面一致），因此隐藏系统导航栏避免重叠
    [self.navigationController setNavigationBarHidden:YES animated:animated];
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 圆形进度条用 CAShapeLayer，依赖最终 frame；因此放在 layout 后做一次性初始化
    [self setupProgressLayersIfNeeded];
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

- (UIView *)buildProgressRingWithPercent:(NSInteger)percent {
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [UIColor clearColor];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(44);
    }];

    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"%ld%%", (long)percent];
    label.textColor = [UIColor colorWithRed:0.15 green:0.65 blue:0.35 alpha:1.0];
    label.font = [UIFont fontWithName:FONT_NAME_Semibold size:12];
    label.textAlignment = NSTextAlignmentCenter;
    [container addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(container);
    }];

    self.beginnerProgressContainer = container;
    self.beginnerProgressLabel = label;
    return container;
}

- (UIView *)buildArrowCircle {
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"button_arrow"]];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [iv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(38);
    }];
    return iv;
}

- (void)setupProgressLayersIfNeeded {
    if (self.didSetupProgressLayers) return;
    if (!self.beginnerProgressContainer) return;
    if (CGRectIsEmpty(self.beginnerProgressContainer.bounds)) return;

    CGFloat percent = 0.66;
    CGFloat lineWidth = 4.0;
    CGFloat radius = MIN(self.beginnerProgressContainer.bounds.size.width,
                         self.beginnerProgressContainer.bounds.size.height) / 2.0 - lineWidth / 2.0;
    CGPoint center = CGPointMake(CGRectGetMidX(self.beginnerProgressContainer.bounds),
                                 CGRectGetMidY(self.beginnerProgressContainer.bounds));

    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center
                                                        radius:radius
                                                    startAngle:-M_PI_2
                                                      endAngle:(-M_PI_2 + 2 * M_PI)
                                                     clockwise:YES];

    CAShapeLayer *bgLayer = [CAShapeLayer layer];
    bgLayer.path = path.CGPath;
    bgLayer.strokeColor = [UIColor colorWithWhite:0.90 alpha:1.0].CGColor;
    bgLayer.fillColor = [UIColor clearColor].CGColor;
    bgLayer.lineWidth = lineWidth;
    bgLayer.lineCap = kCALineCapRound;
    [self.beginnerProgressContainer.layer insertSublayer:bgLayer atIndex:0];

    CAShapeLayer *fgLayer = [CAShapeLayer layer];
    fgLayer.path = path.CGPath;
    fgLayer.strokeColor = [UIColor colorWithRed:0.20 green:0.78 blue:0.45 alpha:1.0].CGColor;
    fgLayer.fillColor = [UIColor clearColor].CGColor;
    fgLayer.lineWidth = lineWidth;
    fgLayer.lineCap = kCALineCapRound;
    fgLayer.strokeStart = 0;
    fgLayer.strokeEnd = percent;
    [self.beginnerProgressContainer.layer insertSublayer:fgLayer above:bgLayer];

    self.didSetupProgressLayers = YES;
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
        _titleLabel.text = NSLocalizedString(@"Navigate Campus", @"");
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
        _subtitleLabel.text = NSLocalizedString(@"Real-life school situations", @"");
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

        for (NSInteger i = 0; i < 3; i++) {
            UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"talk_lock"]];
            iv.contentMode = UIViewContentModeScaleAspectFit;
            [iv mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.mas_equalTo(42);
            }];
            [_lockStackView addArrangedSubview:iv];
        }
    }
    return _lockStackView;
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
        UIView *progress = [self buildProgressRingWithPercent:66];
        _beginnerCard = [self buildCardWithTitle:NSLocalizedString(@"Beginner", @"")
                                        subtitle:NSLocalizedString(@"Key Vocabulary", @"")
                                  trailingWidget:progress];
        _beginnerCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBeginner)];
        [_beginnerCard addGestureRecognizer:tap];
    }
    return _beginnerCard;
}

- (UIView *)intermediateCard {
    if (!_intermediateCard) {
        UIView *arrow = [self buildArrowCircle];
        _intermediateCard = [self buildCardWithTitle:NSLocalizedString(@"Intermediate", @"")
                                            subtitle:NSLocalizedString(@"Basic Dialogue & Grammar", @"")
                                      trailingWidget:arrow];
        _intermediateCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapIntermediate)];
        [_intermediateCard addGestureRecognizer:tap];
    }
    return _intermediateCard;
}

- (UIView *)advancedCard {
    if (!_advancedCard) {
        UIView *arrow = [self buildArrowCircle];
        _advancedCard = [self buildCardWithTitle:NSLocalizedString(@"Advanced", @"")
                                        subtitle:NSLocalizedString(@"Politeness, Nuance & Real-life Logic", @"")
                                  trailingWidget:arrow];
        _advancedCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAdvanced)];
        [_advancedCard addGestureRecognizer:tap];
    }
    return _advancedCard;
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
    self.isRequestingUnits = YES;

    [[GlobalHUDManager shared] showOrUpdateMessage:NSLocalizedString(@"Processing...", @"")];

    __weak typeof(self) weakSelf = self;
    [YTMockUnitFactory fetchUnitsForSceneId:@"scene_school" levelId:levelId completion:^(NSArray<YTUnit *> * _Nonnull units) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isRequestingUnits = NO;
        [[GlobalHUDManager shared] hide];

        TalkLearningFlowViewController *vc = [[TalkLearningFlowViewController alloc] initWithSceneId:@"scene_school" levelId:levelId preloadedUnits:units];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

@end

