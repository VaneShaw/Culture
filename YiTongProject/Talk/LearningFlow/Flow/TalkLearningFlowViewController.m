//
//  TalkLearningFlowViewController.m
//  YiTongProject
//

#import "TalkLearningFlowViewController.h"
#import "HeaderConfig.h"
#import "UserModel.h"
#import "LoginViewController.h"
#import "UIViewController+BackButton.h"

#import "YTLearningFlowBootstrap.h"
#import "YTLearningFlowBootstrapService.h"
#import "YTDifficultyTheme.h"
#import "YTMockLearningFlowBootstrapService.h"
#import "YTLocalAnswerEvaluator.h"
#import "YTServerPronounceEvaluator.h"
#import "YTLearningProgressStoring.h"
#import "YTUnitViewFactory.h"
#import "YTAnswerResultBottomSheet.h"
#import "YTResumeLearningAlertView.h"
#import "YTTipAlertView.h"
#import "YTTalkLearningDataService.h"
#import "YTTalkCompleteSubmit.h"
#import "YTDepthPrimaryButton.h"
#import "YTRecordingService.h"
#import "YTAudioMuxService.h"
#import "YTRecordingMeterBarsView.h"
#import "YTUnit.h"
#import "TalkTopicHomeViewController.h"
#import "TalkViewController.h"
#import "GlobalHUDManager.h"
#import <QuartzCore/QuartzCore.h>

/// 学习流底栏左右切图资源前缀：`talk_nav_{simple|medium|hard}_*`
static NSString *YTTalkNavAssetPrefix(YTLevelId levelId) {
    switch (levelId) {
        case YTLevelIdBeginner:
            return @"talk_nav_simple";
        case YTLevelIdIntermediate:
            return @"talk_nav_medium";
        case YTLevelIdAdvanced:
            return @"talk_nav_hard";
        default:
            return @"talk_nav_simple";
    }
}

/// 主按钮不可点（如未选题）：面片与底层叠色同步变浅
static UIColor *YTBlendColorTowardWhite(UIColor *color, CGFloat amount) {
    if (!color) return color;
    CGFloat r = 0, g = 0, b = 0, a = 1;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) {
        return color;
    }
    CGFloat t = MIN(MAX(amount, 0), 1);
    return [UIColor colorWithRed:r + (1.0 - r) * t
                           green:g + (1.0 - g) * t
                            blue:b + (1.0 - b) * t
                           alpha:a];
}

/// 学习流底部主按钮（过渡页与其它题型共用）：标题过长时缩小字号，左右内边距 6pt
static void YTLearningFlowApplyAdaptivePrimaryButton(UIButton *button, CGFloat maxPointSize) {
    if (!button) return;
    UIFont *font = [UIFont fontWithName:FONT_NAME_Semibold size:maxPointSize] ?: [UIFont boldSystemFontOfSize:maxPointSize];
    UILabel *tl = button.titleLabel;
    tl.font = font;
    tl.adjustsFontSizeToFitWidth = YES;
    tl.minimumScaleFactor = 0.58f;
    tl.numberOfLines = 1;
    tl.lineBreakMode = NSLineBreakByTruncatingTail;
    tl.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 6);
}

/**
 场景对话 - 学习流容器（核心页）
 
 设计意图：
 - 入口直接进入学习流（用户选难度后直接开始做题）
 - 容器只负责：导航/进度/续学/底部主按钮驱动
 - 具体题型 UI/交互由 Presenter（`YTUnitViewProtocol`）承载，通过协议回调把“主按钮状态”回传给容器
 
 PRD MVP 约束（当前版本）：
 - 练习题：须答对才计入进度；未答对时底部右箭头置灰，答对后才可进入下一题
 - 部分 unit 不计进度（见 `-[YTUnit countsTowardProgress]`）
 - 续学位置与已完成集合以 `/talk/unit` 等接口为准，顶部进度仅认服务端 `progress_percent`
 */

@interface TalkLearningFlowViewController ()

@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, assign) YTLevelId levelId;
@property (nonatomic, strong) YTDifficultyTheme *theme;

@property (nonatomic, strong) NSArray<YTUnit *> *units;
@property (nonatomic, strong, nullable) YTLearningFlowBootstrap *preloadedBootstrap;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableSet<NSString *> *completedUnitIds;
/// 与 `units` 下标对齐：已完成步骤（同一 `unit_id` 多步互不合并）
@property (nonatomic, strong) NSMutableSet<NSNumber *> *completedStepIndices;
/// 续学弹窗选「继续上次学习」时为 YES，才从本地/后台恢复已答对题目的答案；选「从头开始」为 NO
@property (nonatomic, assign) BOOL resumePrefillCorrectAnswers;
@property (nonatomic, strong) UIView *progressBackgroundView;
/// 进度条左侧：宽度 = 总宽 × 进度，内铺「主题色 → 轨道色」渐变，与右侧纯色无缝衔接
@property (nonatomic, strong) UIView *progressLeftGradientHost;
/// 进度条右侧：纯色轨道；与左侧相加为整条，进度 0 时仅占满、进度 1 时宽度为 0
@property (nonatomic, strong) UIView *progressRightTrackView;
@property (nonatomic, strong) UILabel *progressPillLabel;
@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, strong) id<YTUnitViewProtocol> unitView;
@property (nonatomic, strong) YTDepthPrimaryButton *primaryDepthButton;
/// 等价于 `primaryDepthButton.actionButton`，便于沿用原有主按钮逻辑
@property (nonatomic, readonly) UIButton *primaryButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) CAGradientLayer *progressGradientLayer;

@property (nonatomic, strong) UIView *bottomToast;
@property (nonatomic, strong) UILabel *bottomToastLabel;
@property (nonatomic, strong) UIButton *bottomToastButton;

@property (nonatomic, strong) YTAnswerResultBottomSheet *answerResultSheet;
@property (nonatomic, strong) id<YTLearningFlowBootstrapService> bootstrapService;
@property (nonatomic, strong) id<YTPronounceEvaluating> pronounceEvaluator;
@property (nonatomic, strong) id<YTAnswerEvaluating> answerEvaluator;
@property (nonatomic, strong) id<YTLearningProgressStoring> progressStore;

@property (nonatomic, strong, nullable) CADisplayLink *recordingMeterDisplayLink;
@property (nonatomic, strong) YTRecordingMeterBarsView *recordingMeterBarsView;
/// 波形水平流动累加相位（静音时不再增长，见 `yt_onRecordingMeterTick:`）
@property (nonatomic, assign) CGFloat recordingMeterWavePhaseAccum;
/// 顶部进度条仅使用服务端 `progress_percent`（话题页注入、`/talk/complete`、发音评估等）；无效区间按 0% 展示
@property (nonatomic, assign) NSInteger serverProgressPercent;
/// 话题页带入的初始进度 0～100；`-1` 表示未注入（下一难度无缝切换等）
@property (nonatomic, assign) NSInteger initialProgressPercent;

@end

@implementation TalkLearningFlowViewController

- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    return [self initWithSceneId:sceneId levelId:levelId initialProgressPercent:-1];
}

- (instancetype)initWithSceneId:(NSString *)sceneId
                        levelId:(YTLevelId)levelId
             preloadedBootstrap:(YTLearningFlowBootstrap *)preloadedBootstrap {
    return [self initWithSceneId:sceneId levelId:levelId preloadedBootstrap:preloadedBootstrap initialProgressPercent:-1];
}

- (instancetype)initWithSceneId:(NSString *)sceneId
                        levelId:(YTLevelId)levelId
             preloadedBootstrap:(YTLearningFlowBootstrap *)preloadedBootstrap
        initialProgressPercent:(NSInteger)initialProgressPercent {
    self = [self initWithSceneId:sceneId levelId:levelId initialProgressPercent:initialProgressPercent];
    if (self) {
        _preloadedBootstrap = preloadedBootstrap;
        _units = preloadedBootstrap.units ?: @[];
    }
    return self;
}

- (instancetype)initWithSceneId:(NSString *)sceneId
                        levelId:(YTLevelId)levelId
           initialProgressPercent:(NSInteger)initialProgressPercent {
    self = [super init];
    if (self) {
        _sceneId = [sceneId copy];
        _levelId = levelId;
        _currentIndex = 0;
        _completedUnitIds = [NSMutableSet set];
        _completedStepIndices = [NSMutableSet set];
        _units = @[];
        _bootstrapService = [YTMockLearningFlowBootstrapService shared];
        _answerEvaluator = [YTLocalAnswerEvaluator shared];
        _progressStore = [YTTalkLearningDataService shared];
        _initialProgressPercent = initialProgressPercent;
        _serverProgressPercent = -1;
        _talkSceneNumericId = 0;
        _talkDidApplyLevelAPI = NO;
        _talkBeginnerLevelRecordId = 1;
        _talkIntermediateLevelRecordId = 2;
        _talkAdvancedLevelRecordId = 3;
        [self yt_seedServerProgressPercentFromEntryIfNeeded];
    }
    return self;
}

/// 进入页与话题卡一致：有注入时用该百分比驱动顶部条，直到 `/talk/complete` 带回新 `progress_percent`
- (void)yt_seedServerProgressPercentFromEntryIfNeeded {
    if (self.initialProgressPercent >= 0 && self.initialProgressPercent <= 100) {
        self.serverProgressPercent = self.initialProgressPercent;
    } else {
        self.serverProgressPercent = -1;
    }
}

#pragma mark - 生命周期

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.progressGradientLayer && self.progressLeftGradientHost) {
        self.progressGradientLayer.frame = self.progressLeftGradientHost.bounds;
    }
    if (self.currentIndex >= 0 && self.currentIndex < self.units.count &&
        self.units[self.currentIndex].unitType == YTUnitTypeLevelCompletion) {
        [self yt_applyLevelCompletionNextNavAppearance];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 使用工程统一返回按钮：强制隐藏系统导航栏，避免系统返回按钮露出/重叠
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    // 从其它页返回或续学弹窗关闭后，再同步一次进度与右箭头（避免与内存/持久化不一致）
    if (self.units.count > 0) {
        [self updateProgressUI];
        [self updateBottomBarLayoutForCurrentUnit];
        [self updateNavButtons];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak typeof(self) weakSelf = self;
    self.pronounceEvaluator = [[YTServerPronounceEvaluator alloc] initWithProgressPercentHandler:^(NSInteger pct) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (pct >= 0 && pct <= 100) {
            self.serverProgressPercent = pct;
            [self updateProgressUI];
        }
    }];
    self.pageId = @"talk_learning_flow";
    self.theme = [YTDifficultyTheme themeForLevel:self.levelId];
    self.view.backgroundColor = self.theme.backgroundColor;

    // 使用工程统一的全局返回按钮（同首页 push 后页面一致），因此隐藏系统导航栏避免重叠
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self addGlobalBackButtonColor:[UIColor colorWithWhite:1.0 alpha:0.85] headerTitleDic:@{}];

    [self setupUI];

    // MVP：学习流进入前统一做登录兜底（避免把登录判断散落到各题型里）
    [self ensureLoginThenStart];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self yt_stopRecordingMeterDisplayLink];
    // 离开学习流即停播：避免 pop 后题干/选项音频仍在后台播放，并尽快释放单例内 AVAudioPlayer/队列占用的内存
    [[YTAudioMuxService shared] stop];
    // 离开学习流后恢复导航栏，避免影响其它页面
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self saveLastPositionIfPossible];
}

#pragma mark - 启动/登录

- (void)ensureLoginThenStart {
    // 你已要求先做静态页面：此处先不做登录拦截，直接进入学习流。
    // 后续要恢复登录时，再把这里改回 “未登录 -> push LoginVC” 即可。
    [self startFlow];
}

- (void)startFlow {
    if (self.preloadedBootstrap) {
        [self applyBootstrapAndStart:self.preloadedBootstrap];
        return;
    }
    YTMockLearningFlowBootstrapService *svc = [YTMockLearningFlowBootstrapService shared];
    NSInteger sceneNumeric = [self yt_effectiveTalkSceneNumericId];
    svc.talkSceneNumericId = sceneNumeric;
    NSInteger requestLevelId = [self yt_requestLevelIdForTalkAPIForDisplayLevel:self.levelId];
    __weak typeof(self) weakSelf = self;
    [[GlobalHUDManager shared] showSpinnerOnly];
    [svc fetchBootstrapForSceneId:self.sceneId levelId:requestLevelId completion:^(YTLearningFlowBootstrap * _Nullable bootstrap, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        [[GlobalHUDManager shared] hide];
        if (!self) return;
        if (!bootstrap || error) {
            NSString *msg = error.localizedDescription.length > 0 ? error.localizedDescription : NSLocalizedString(@"Talk_LearningFlow_LoadFailed", @"");
            [YTTipAlertView showInView:self.view
                              topTitle:nil
                           contentText:msg
                    primaryButtonTitle:NSLocalizedString(@"OK", @"")
                   secondaryButtonTitle:nil
                                onClose:nil
                             onConfirm:^{
                [self.navigationController popViewControllerAnimated:YES];
            }
                              onCancel:nil];
            return;
        }
        [self applyBootstrapAndStart:bootstrap];
    }];
}

- (void)applyBootstrapAndStart:(YTLearningFlowBootstrap *)bootstrap {
    [self applyBootstrap:bootstrap];
    [self routeEntryFromBootstrap:bootstrap];
}

- (void)applyBootstrap:(YTLearningFlowBootstrap *)bootstrap {
    [self yt_seedServerProgressPercentFromEntryIfNeeded];
    self.units = bootstrap.units ?: @[];
    [self.completedUnitIds removeAllObjects];
    [self.completedStepIndices removeAllObjects];
    if (bootstrap.completedStepIndices.count > 0) {
        [self.completedStepIndices addObjectsFromArray:bootstrap.completedStepIndices];
    }
    if (bootstrap.completedUnitIds.count > 0) {
        [self.completedUnitIds addObjectsFromArray:bootstrap.completedUnitIds];
    }

#if DEBUG
    [self yt_debugLogNextUnlockBootstrapSnapshot];
#endif

    // 拉取到已完成列表后刷新顶部条（百分比仍以服务端为准；无有效服务端值时显示 0%）
    [self updateProgressUI];
}

/// 过场页 / 完成页主按钮：`/talk/unit` 列表**最后一格**若为 `ref_table=cross`，Mapper 会映射为 `YTUnitTypeLevelCompletion`（收尾），
/// 困难在该步主按钮为「探索」并由 `finishLevelFlow` 回根；**中间**的 `cross` 均为 `PracticeTransition`，主按钮统一「下一步」并 `goNext`。
/// 勿再用「第一个 LevelCompletion 前的最后一个 PracticeTransition」推断收尾——该启发式会把「中间过场」误判成收尾（最后一格 cross 已是完成页类型）。
- (void)yt_applyTalkFlowPrimaryTitleForTransitionOrCompletionWithUnit:(nullable YTUnit *)cu
                                                               state:(YTUnitPrimaryState *)state
                                                    isRecordingState:(BOOL)isRecordingState {
    if (isRecordingState || !cu || !state) return;
    if (state.kind != YTUnitPrimaryKindContinue && state.kind != YTUnitPrimaryKindGotIt) return;
    if (cu.unitType == YTUnitTypePracticeTransition) {
        NSString *title = NSLocalizedString(@"Talk_PracticeTransition_NextStep", @"");
        [self.primaryButton setTitle:title forState:UIControlStateNormal];
        [self.primaryButton setTitle:title forState:UIControlStateDisabled];
        return;
    }
    if (cu.unitType == YTUnitTypeLevelCompletion) {
        BOOL explore = (self.levelId == YTLevelIdAdvanced);
        NSString *key = explore ? @"Talk_LevelComplete_Primary_Explore" : @"Talk_PracticeTransition_NextLevel";
        [self.primaryButton setTitle:NSLocalizedString(key, @"") forState:UIControlStateNormal];
    }
}

- (void)routeEntryFromBootstrap:(YTLearningFlowBootstrap *)bootstrap {
    (void)bootstrap;
    // 统一入口规则见 `routeEntryAfterUnitsReady`（0% 不弹续学、100% 进完成页、中间进度弹续学）
    [self routeEntryAfterUnitsReady];
}

- (BOOL)isCurrentProgressFullyCompleted {
    CGFloat p = [self yt_displayProgressRatio];
    return (p >= 1.0 - 1e-5);
}

/// 找到“本难度完成页（unitType=level_complete）”所在下标；找不到则兜底最后一个 unit
- (NSInteger)indexOfLevelCompletionPage {
    if (self.units.count <= 0) return 0;
    for (NSInteger i = 0; i < self.units.count; i++) {
        YTUnit *u = self.units[i];
        if (u.unitType == YTUnitTypeLevelCompletion) {
            return i;
        }
    }
    return self.units.count - 1;
}

/// 进入学习流后的统一路由入口（不关心来自哪里：选难度 / 续学 / 上难度继续）
- (void)routeEntryAfterUnitsReady {
    if ([self isCurrentProgressFullyCompleted]) {
        // 全完成：不弹进度弹窗，直接显示完成页。
        // 同时把 prefill 开到 YES：方便用户点“上一步”查看已完成题型时能正确展示状态。
        self.resumePrefillCorrectAnswers = YES;
        NSInteger idx = [self indexOfLevelCompletionPage];
        [self showUnitAtIndex:MAX(0, idx)];
        return;
    }

    CGFloat p = [self yt_displayProgressRatio];
    // 顶部条无有效 `progress_percent` 时显示 0%，续学与否以接口每步 `is_unit_completed` / `is_line_completed` 汇总的 completedStepIndices 为准
    if (p <= 1e-5 && self.completedStepIndices.count == 0) {
        self.resumePrefillCorrectAnswers = NO;
        [self showUnitAtIndex:0];
        return;
    }

    // 未完成且已有进度：弹续学弹窗，让用户在「继续上次学习 / 从头开始」间选择
    [self showResumePrompt];
}

- (NSInteger)indexForResumeFromCompletedUnits {
    if (self.units.count <= 0) return 0;

    NSInteger lastCompletedIndex = -1;
    for (NSNumber *n in self.completedStepIndices) {
        lastCompletedIndex = MAX(lastCompletedIndex, n.integerValue);
    }

    if (lastCompletedIndex < 0) return 0;

    // 继续学习：跳到“最后一个已完成单元”的下一题
    NSInteger nextIndex = lastCompletedIndex + 1;
    if (nextIndex < 0) nextIndex = 0;
    if (nextIndex >= self.units.count) nextIndex = self.units.count - 1; // 全完成则停在最后一个单元
    return nextIndex;
}

- (void)startFreshFromBeginning {
    self.resumePrefillCorrectAnswers = NO;
    [self updateProgressUI];
    [self showUnitAtIndex:0];
}

#pragma mark - UI

- (void)setupUI {
    // UI 结构（自上而下）：
    // 1) 进度胶囊：progressBackgroundView 内左（渐变）+ 右（纯色轨道）+ 上层 progressPillLabel
    // 2) 内容容器 contentContainer：所有题型共用同一容器；各题 Presenter 的 rootView 铺满此区域（edges = contentContainer）
    // 3) 底部导航：左/主/右（三按钮）；过渡页仅主按钮；主按钮由 Presenter 驱动文案/可用态
    // 4) 底部反馈条 bottomToast（Submit 对错/错误提示）
    UIView *backContainer = [self.view viewWithTag:kGlobalBackButtonContainerTag];
    [self.view addSubview:self.progressBackgroundView];
    [self.progressBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        if (backContainer) {
            make.centerY.equalTo(backContainer);
        } else {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(5);
        }
        make.left.equalTo(self.view).offset(Distance＿M + 40 + 6);
        make.right.equalTo(self.view).offset(-20);
    }];
    [self.view addSubview:self.progressPillLabel];
    [self.progressPillLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.progressBackgroundView);
    }];
    if (backContainer) {
        [self.view bringSubviewToFront:backContainer];
    }

    [self.view addSubview:self.prevButton];
    [self.view addSubview:self.nextButton];
    [self.view addSubview:self.primaryDepthButton];

    // 中间主按钮：深色 depthView（「底色」层）的底与整个控件底一致；左右箭头底与该底齐平，高度与主按钮整高一致
    [self.primaryDepthButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.prevButton.mas_right).offset(12);
        make.right.equalTo(self.nextButton.mas_left).offset(-12);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-18);
        make.height.mas_equalTo(self.primaryDepthButton.totalHeight);
    }];
    [self.prevButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.bottom.equalTo(self.primaryDepthButton.mas_bottom);
        make.width.mas_equalTo(82);
        make.height.mas_equalTo(self.primaryDepthButton.totalHeight);
    }];
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.primaryDepthButton.mas_bottom);
        make.width.mas_equalTo(82);
        make.height.mas_equalTo(self.primaryDepthButton.totalHeight);
    }];
    CGFloat sideH = self.primaryDepthButton.totalHeight;
    self.prevButton.layer.cornerRadius = sideH / 2.0;
    self.nextButton.layer.cornerRadius = sideH / 2.0;

    [self.view addSubview:self.bottomToast];
    [self.bottomToast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(20);
        make.bottom.equalTo(self.primaryDepthButton.mas_top).offset(-12);
        make.height.mas_equalTo(56);
    }];
    self.bottomToast.hidden = YES;

    // 内容容器：夹在进度条与主按钮之间（间距 16）；335:546 为设计宽高比，优先级低于上下锚点——
    // 矮屏时中间区域会变短，底部主按钮仍贴在安全区，避免与固定比例冲突导致约束异常。
    [self.view addSubview:self.contentContainer];
    [self.contentContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(20);
        make.top.equalTo(self.progressPillLabel.mas_bottom).offset(16);
        make.bottom.equalTo(self.primaryDepthButton.mas_top).offset(-16);
        make.height.equalTo(self.contentContainer.mas_width).multipliedBy(546.0 / 335.0).priority(999);
    }];

    // 注意：label 的约束引用了 button（right <= button.left），因此必须先把两者都 add 到同一个 superview
    [self.bottomToast addSubview:self.bottomToastLabel];
    [self.bottomToast addSubview:self.bottomToastButton];

    [self.bottomToastButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomToast).offset(-12);
        make.centerY.equalTo(self.bottomToast);
        make.height.mas_equalTo(36);
        make.width.mas_greaterThanOrEqualTo(88);
    }];
    [self.bottomToastLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomToast).offset(16);
        make.centerY.equalTo(self.bottomToast);
        make.right.lessThanOrEqualTo(self.bottomToastButton.mas_left).offset(-12);
    }];

    [self yt_refreshNavButtonImages];
}

#pragma mark - Flow

/// 清除各题上的续学/后台预填标记，避免「从头开始」后仍视为已答对、右箭头仍解锁
- (void)resetLearnStateFlagsOnAllUnits {
    for (YTUnit *u in self.units) {
        u.answeredCorrectFromServer = NO;
        u.serverAnswerPayload = nil;
    }
}

- (void)restartLearningFromBeginning {
    self.resumePrefillCorrectAnswers = NO;
    [self.progressStore clearAnswerSnapshotsForSceneId:self.sceneId levelId:self.levelId];
    [self.progressStore clearLastPositionForSceneId:self.sceneId levelId:self.levelId];
    [self.completedUnitIds removeAllObjects];
    [self.completedStepIndices removeAllObjects];
    [self resetLearnStateFlagsOnAllUnits];
    [self showUnitAtIndex:0];
}

/// 先请求 `POST /talk/relearnLevel`（scene_id、level_id），成功后再本地清空并从第一题开始
- (void)requestRelearnLevelThenRestartFromBeginning {
    NSInteger sceneNumeric = [self yt_effectiveTalkSceneNumericId];
    if (sceneNumeric <= 0) {
        [YTTipAlertView showInView:self.view
                          topTitle:nil
                       contentText:NSLocalizedString(@"Talk_LearningFlow_InvalidScene_Restart", @"")
                primaryButtonTitle:NSLocalizedString(@"OK", @"")
               secondaryButtonTitle:nil
                            onClose:nil
                         onConfirm:nil
                          onCancel:nil];
        return;
    }
    NSInteger requestLevelId = [self yt_requestLevelIdForTalkAPIForDisplayLevel:self.levelId];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    params[@"scene_id"] = @(sceneNumeric);
    params[@"level_id"] = @(requestLevelId);

    [[GlobalHUDManager shared] showSpinnerOnly];
    __weak typeof(self) weakSelf = self;
    [HttpTools postRequest:@"/talk/relearnLevel" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        [[GlobalHUDManager shared] hide];
        if (!self) {
            return;
        }
        if (!success || response.code != 0) {
            NSString *msg = (response.msg.length > 0) ? response.msg : NSLocalizedString(@"Talk_LearningFlow_RestartFailed", @"");
            [YTTipAlertView showInView:self.view
                              topTitle:nil
                           contentText:msg
                    primaryButtonTitle:NSLocalizedString(@"OK", @"")
                   secondaryButtonTitle:nil
                                onClose:nil
                             onConfirm:nil
                              onCancel:nil];
            return;
        }
        NSInteger pct = -1;
        if ([response.data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *data = (NSDictionary *)response.data;
            id pp = data[@"progress_percent"];
            if ([pp respondsToSelector:@selector(integerValue)]) {
                pct = [pp integerValue];
            }
        }
        if (pct >= 0 && pct <= 100) {
            self.serverProgressPercent = pct;
        } else {
            self.serverProgressPercent = 0;
        }
        [self restartLearningFromBeginning];
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        [[GlobalHUDManager shared] hide];
        if (!self) {
            return;
        }
        NSString *msg = error.localizedDescription.length > 0 ? error.localizedDescription : NSLocalizedString(@"Talk_LearningFlow_NetworkError", @"");
        [YTTipAlertView showInView:self.view
                          topTitle:nil
                       contentText:msg
                primaryButtonTitle:NSLocalizedString(@"OK", @"")
               secondaryButtonTitle:nil
                            onClose:nil
                         onConfirm:nil
                          onCancel:nil];
    }];
}

- (void)showRestartLearningConfirmAlert {
    __weak typeof(self) weakSelf = self;
    NSString *msg = NSLocalizedString(@"Talk_ConfirmRestartLearning", @"");
    [YTTipAlertView showInView:self.view
                      topTitle:nil
                   contentText:msg
            primaryButtonTitle:NSLocalizedString(@"Talk_RestartLearning_Restart", @"")
           secondaryButtonTitle:NSLocalizedString(@"Cancel", @"")
                        onClose:nil
                     onConfirm:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self requestRelearnLevelThenRestartFromBeginning];
    }
                      onCancel:nil];
}

- (void)showResumePrompt {
    // 续学弹窗：与 YTTipAlertView 同风格的卡片 + 圆环进度 + 继续/重新开始（无关闭按钮时仅能通过两按钮选择）
    CGFloat progressRatio = [self yt_displayProgressRatio];
    __weak typeof(self) weakSelf = self;
    [YTResumeLearningAlertView showInView:self.view
                            progressRatio:progressRatio
                                    title:nil
                               onContinue:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.resumePrefillCorrectAnswers = YES;
        NSInteger idx = [self indexForResumeFromCompletedUnits];
        [self showUnitAtIndex:MAX(0, idx)];
    }
                                onRestart:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self requestRelearnLevelThenRestartFromBeginning];
    }];
}

- (void)showUnitAtIndex:(NSInteger)index {
    if (self.units.count == 0) return;
    if (index < 0) index = 0;
    if (index >= self.units.count) index = self.units.count - 1;
    self.currentIndex = index;

    YTUnit *u = self.units[self.currentIndex];
    // 词汇/发音题需录音：进入该步即触发麦克风授权（已允许/已拒绝时系统不再弹窗，仅回调结果）
    if (u.unitType == YTUnitTypePronounce) {
        [[YTRecordingService shared] requestMicPermission:^(__unused YTMicPermissionState state) {
        }];
    }
    [self updateProgressUI];
    [self mountUnitViewForUnit:u];
    [self updateBottomBarLayoutForCurrentUnit];
    [self updateNavButtons];
}

- (BOOL)isCurrentStepUnlockedForNext {
    if (self.units.count == 0) return NO;
    if (self.currentIndex < 0 || self.currentIndex >= self.units.count) return NO;
    YTUnit *u = self.units[self.currentIndex];
    if (u.answeredCorrectFromServer) {
#if DEBUG
        [self yt_debugLogNextUnlockReason:@"answeredCorrectFromServer==YES" unit:u];
#endif
        return YES;
    }
    if ([self.completedStepIndices containsObject:@(self.currentIndex)]) {
#if DEBUG
        [self yt_debugLogNextUnlockReason:@"stepIndex in completedStepIndices" unit:u];
#endif
        return YES;
    }
    BOOL signal = (self.unitView && [self.unitView isUnitCompleteSignalSatisfied]);
    if (signal) {
#if DEBUG
        [self yt_debugLogNextUnlockReason:@"isUnitCompleteSignalSatisfied==YES" unit:u];
#endif
        return YES;
    }
    return NO;
}

#if DEBUG
/// 调试用：右侧「下一题」为何可点 / 不可点（过滤日志：`TalkFlow][NextUnlock`）
- (void)yt_debugLogNextUnlockBootstrapSnapshot {
    NSMutableDictionary<NSString *, NSNumber *> *idCounts = [NSMutableDictionary dictionary];
    for (YTUnit *x in self.units) {
        if (x.unitId.length == 0) continue;
        NSNumber *n = idCounts[x.unitId];
        idCounts[x.unitId] = @(n.integerValue + 1);
    }
    NSMutableArray<NSString *> *dupes = [NSMutableArray array];
    for (NSString *k in idCounts) {
        if ([idCounts[k] integerValue] > 1) {
            [dupes addObject:[NSString stringWithFormat:@"%@ x%@", k, idCounts[k]]];
        }
    }
    NSLog(@"[TalkFlow][NextUnlock] applyBootstrap level=%ld scene=%@ units=%lu completedSteps=%lu steps=%@ unitIds(legacy)=%@",
          (long)self.levelId,
          self.sceneId ?: @"-",
          (unsigned long)self.units.count,
          (unsigned long)self.completedStepIndices.count,
          self.completedStepIndices.allObjects,
          self.completedUnitIds.allObjects);
    if (dupes.count > 0) {
        NSLog(@"[TalkFlow][NextUnlock] WARNING duplicate unit_id in flow: %@", [dupes componentsJoinedByString:@", "]);
    }
}

- (void)yt_debugLogNextUnlockReason:(NSString *)reason unit:(YTUnit *)u {
    BOOL sig = self.unitView ? [self.unitView isUnitCompleteSignalSatisfied] : NO;
    NSLog(@"[TalkFlow][NextUnlock] idx=%ld/%lu type=%ld unitId=%@ answeredCorrectFromServer=%d inCompletedSet=%d signal=%d reason=%@",
          (long)self.currentIndex,
          (unsigned long)self.units.count,
          (long)u.unitType,
          u.unitId ?: @"(empty)",
          u.answeredCorrectFromServer ? 1 : 0,
          [self.completedStepIndices containsObject:@(self.currentIndex)] ? 1 : 0,
          sig ? 1 : 0,
          reason);
}
#endif

/// 第一道「过渡页」或「练习题」的下标：从该步起不可再回到前面的词汇/句子（发音）；均无则为 NSNotFound
- (NSInteger)indexOfFirstUnitBlockingReturnToPronounce {
    for (NSInteger i = 0; i < self.units.count; i++) {
        YTUnitType t = self.units[i].unitType;
        if (t == YTUnitTypePracticeTransition || [YTUnit yt_isExerciseQuestionType:t]) {
            return i;
        }
    }
    return NSNotFound;
}

/// 过渡页：隐藏左右箭头，主按钮与内容区等宽（左右 inset 20）；完成页与其它题型为三按钮布局（左/主/右）
- (void)updateBottomBarLayoutForCurrentUnit {
    BOOL hideSides = NO;
    if (self.currentIndex >= 0 && self.currentIndex < self.units.count) {
        YTUnitType t = self.units[self.currentIndex].unitType;
        hideSides = (t == YTUnitTypePracticeTransition);
    }
    self.prevButton.hidden = hideSides;
    self.nextButton.hidden = hideSides;
    if (hideSides) {
        [self.primaryDepthButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view).inset(20);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-18);
            make.height.mas_equalTo(self.primaryDepthButton.totalHeight);
        }];
    } else {
        [self.primaryDepthButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.prevButton.mas_right).offset(12);
            make.right.equalTo(self.nextButton.mas_left).offset(-12);
            make.top.equalTo(self.prevButton.mas_top);
            make.height.mas_equalTo(self.primaryDepthButton.totalHeight);
        }];
    }
}

- (void)updateNavButtons {
    [self yt_refreshNavButtonImages];
    // 过渡页不展示左右箭头（由 updateBottomBarLayoutForCurrentUnit 控制 hidden）
    if (self.currentIndex >= 0 && self.currentIndex < self.units.count) {
        YTUnitType t = self.units[self.currentIndex].unitType;
        if (t == YTUnitTypePracticeTransition) {
            YTUnit *cu = self.units[self.currentIndex];
            YTUnitPrimaryState *st = [[YTUnitPrimaryState alloc] init];
            st.kind = YTUnitPrimaryKindContinue;
            st.enabled = self.primaryButton.isEnabled;
            [self yt_applyTalkFlowPrimaryTitleForTransitionOrCompletionWithUnit:cu state:st isRecordingState:NO];
            return;
        }
        if (t == YTUnitTypeLevelCompletion) {
            BOOL hasPrev = (self.currentIndex > 0);
            NSInteger lockIdx = [self indexOfFirstUnitBlockingReturnToPronounce];
            if (lockIdx != NSNotFound && self.currentIndex >= lockIdx) {
                hasPrev = (self.currentIndex > lockIdx);
            }
            self.prevButton.enabled = hasPrev;
            self.nextButton.enabled = YES;
            [self yt_applyLevelCompletionNextNavAppearance];
            return;
        }
    }
   // 左箭头：从「第一道过渡页/习题」起不可再回到前面的发音区；习题可左滑回到过渡页（lockIdx 为过渡页或首题中较早者）
    BOOL hasPrev = (self.currentIndex > 0);
    NSInteger lockIdx = [self indexOfFirstUnitBlockingReturnToPronounce];
    if (lockIdx != NSNotFound && self.currentIndex >= lockIdx) {
        hasPrev = (self.currentIndex > lockIdx);
    }
    // 右箭头：须本题已达成完成条件（练习题为答对等）才解锁下一题
    BOOL hasNext = (self.currentIndex + 1 < self.units.count);
    BOOL nextUnlocked = [self isCurrentStepUnlockedForNext];
    self.prevButton.enabled = hasPrev;
    self.nextButton.enabled = (hasNext && nextUnlocked);
}

- (void)mountUnitViewForUnit:(YTUnit *)u {
    [self yt_stopRecordingMeterDisplayLink];
    // 先断开旧 Presenter 的主按钮回调，避免跟读评分等异步晚到后改写过载后的主按钮（如过渡页被盖成「正确」）
    if (self.unitView) {
        self.unitView.onPrimaryStateChanged = nil;
    }
    // 清理旧内容
    for (UIView *v in self.contentContainer.subviews) {
        [v removeFromSuperview];
    }

    // 工厂根据 unitType 返回对应 Presenter（题型扩展点）
    self.unitView = [YTUnitViewFactory buildViewForUnit:u];
    __weak typeof(self) weakSelf = self;
    self.unitView.onPrimaryStateChanged = ^(YTUnitPrimaryState *state) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        // 容器只消费“主按钮状态”：文案/可用/类型（Submit/Continue/GotIt/Record）
        NSString *rawTitle = state.title ?: @"";
        BOOL isRecordingState = NO;
        if (state.kind == YTUnitPrimaryKindRecord) {
            NSRange recordingRange = [rawTitle rangeOfString:@"Recording" options:NSCaseInsensitiveSearch];
            NSRange stopHintRange = [rawTitle rangeOfString:@"tap to stop" options:NSCaseInsensitiveSearch];
            isRecordingState = (recordingRange.location != NSNotFound && stopHintRange.location != NSNotFound);
        }
        if (isRecordingState) {
            [self.primaryButton setImage:nil forState:UIControlStateNormal];
            [self.primaryButton setTitle:@"" forState:UIControlStateNormal];
            [self yt_startRecordingMeterDisplayLinkIfNeeded];
        } else {
            [self yt_stopRecordingMeterDisplayLink];
            [self.primaryButton setImage:nil forState:UIControlStateNormal];
            [self.primaryButton setTitle:NSLocalizedString(rawTitle, @"") forState:UIControlStateNormal];
        }
        self.primaryButton.enabled = state.enabled;
        self.primaryButton.tag = state.kind;
        // 过渡页：深色主按钮；完成页与练习题等统一用难度主题色（录音态见上）
        YTUnit *cu = (self.currentIndex >= 0 && self.currentIndex < self.units.count) ? self.units[self.currentIndex] : nil;
        // 主按钮文案以学习流入口难度为准（勿仅用 unit.levelId，避免接口与入口不一致误显示「探索其他场景」）
        [self yt_applyTalkFlowPrimaryTitleForTransitionOrCompletionWithUnit:cu state:state isRecordingState:isRecordingState];
        UIColor *faceColor;
        if (cu && cu.unitType == YTUnitTypePracticeTransition) {
            faceColor = [theAppDelegate.window colorWithHexString:@"#1F2540" alpha:1];
        } else {
            faceColor = self.theme.primaryColor;
        }
        BOOL dimDisabledChrome = (!state.enabled && !isRecordingState && state.kind == YTUnitPrimaryKindSubmit);
        if (dimDisabledChrome) {
            faceColor = YTBlendColorTowardWhite(faceColor, 0.52);
            self.primaryDepthButton.depthColor =
                [YTDepthPrimaryButton autoDepthColorForFaceColor:faceColor
                                                  darkeningFactor:self.primaryDepthButton.depthDarkeningFactor];
        } else {
            self.primaryDepthButton.depthColor = nil;
        }
        self.primaryDepthButton.faceColor = faceColor;
        [self.primaryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.primaryButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.78] forState:UIControlStateDisabled];
        [self updateNavButtons];
    };

    [self.unitView configureWithUnit:u
                               theme:self.theme
                               audio:[YTAudioMuxService shared]
                           recording:[YTRecordingService shared]
                  pronounceEvaluator:self.pronounceEvaluator
                     answerEvaluator:self.answerEvaluator];

    // 答案回填：仅用 `/talk/unit` 映射到 `serverAnswerPayload`（含 `progress.answerPayload` 或由题干 correct_answer 推导），不读本地快照推导
    NSDictionary *restorePayload = nil;
    BOOL completed = [self.completedStepIndices containsObject:@(self.currentIndex)];
    if (u.serverAnswerPayload.count > 0 && (u.answeredCorrectFromServer || (self.resumePrefillCorrectAnswers && completed))) {
        restorePayload = u.serverAnswerPayload;
    }
    if (restorePayload.count > 0) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || !self.unitView) return;
            [self.unitView applyRestoredAnswerSnapshot:restorePayload];
            [self updateNavButtons];
        });
    }

    UIView *rv = self.unitView.rootView;
    [self.contentContainer addSubview:rv];
    // 与所有题型一致：唯一内容容器，白卡片在 Presenter 内铺满 rootView
    [rv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentContainer);
    }];

    /// 未完成且有题干主音频时自动播一次（已完成则跳过）
    BOOL unitCompleted = [self.completedStepIndices containsObject:@(self.currentIndex)];
    NSString *mountedUnitId = u.unitId ?: @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.unitView) {
            return;
        }
        if (self.currentIndex < 0 || self.currentIndex >= self.units.count) {
            return;
        }
        YTUnit *cur = self.units[self.currentIndex];
        if (mountedUnitId.length > 0 && cur.unitId.length > 0 && ![cur.unitId isEqualToString:mountedUnitId]) {
            return;
        }
        [self.unitView yt_autoPlayStemAudioIfNeededWhenUnitIncomplete:!unitCompleted];
    });
}

- (void)onPrimaryButton {
    if (self.units.count == 0) return;
    YTUnit *u = self.units[self.currentIndex];
    if (u.unitType == YTUnitTypeLevelCompletion) {
        [self finishLevelFlow];
        return;
    }
    YTUnitPrimaryKind kind = (YTUnitPrimaryKind)self.primaryButton.tag;

    // 主按钮分发逻辑：
    // - Submit：由 Presenter 返回 submitResult，容器负责统一展示反馈条并计入完成
    // - Continue/GotIt：容器直接切下一题；是否计入完成取决于 Presenter 的完成信号
    // - Record：录音按钮状态机主要在 Presenter 内部推进；容器只在“已满足完成信号”时计入完成
    __weak typeof(self) weakSelf = self;
    [self.unitView handlePrimaryActionWithCompletion:^(YTUnitSubmitResult * _Nullable submitResult, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (error) {
            // MVP：错误统一走底部 Toast（避免各题型自己弹 Alert）
            self.bottomToast.hidden = NO;
            self.bottomToastLabel.text = error.localizedDescription ?: NSLocalizedString(@"Error", @"");
            [self.bottomToastButton setTitle:NSLocalizedString(@"OK", @"") forState:UIControlStateNormal];
            [self.bottomToastButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.bottomToastButton addTarget:self action:@selector(onBottomToastContinue) forControlEvents:UIControlEventTouchUpInside];
            return;
        }

        if (kind == YTUnitPrimaryKindSubmit) {
            // 先本地判题：错则直接弹错，不调接口
            BOOL localCorrect = submitResult ? submitResult.isCorrect : YES;
            if (!localCorrect) {
                [self showAnswerResultSheetCorrect:NO submitResult:submitResult];
                [self updateNavButtons];
                return;
            }
            // 非练习题提交（不应出现）或无需远程校验：保持原逻辑
            if (![u countsTowardProgress] || ![YTUnit yt_isExerciseQuestionType:u.unitType]) {
                if (localCorrect) [self markUnitCompletedIfNeeded:u];
                [self showAnswerResultSheetCorrect:localCorrect submitResult:submitResult];
                [self updateNavButtons];
                return;
            }
            // 无 ref_table / unitId 时无法调 `/talk/complete`，回退为仅本地
            if (u.refTable.length == 0 || u.unitId.length == 0) {
                [self markUnitCompletedIfNeeded:u];
                [self showAnswerResultSheetCorrect:YES submitResult:submitResult];
                [self updateNavButtons];
                return;
            }
            NSString *answerJSON = [YTTalkCompleteSubmit answerJSONStringFromAnswerPayload:submitResult.answerPayload unit:u];
            NSInteger apiLevelId = (NSInteger)self.levelId + 1;
            __weak typeof(self) weakSelf = self;
            [YTTalkCompleteSubmit submitWithSceneId:self.sceneId
                                            levelId:apiLevelId
                                               unit:u
                                   answerJSONString:answerJSON
                                   readAudioFileURL:nil
                                         completion:^(BOOL httpSuccess, BOOL serverCorrect, NSInteger progressPercent, NSInteger rawScore, NSError *error) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                (void)rawScore;
                if (!httpSuccess || error) {
                    NSString *base = error.localizedDescription ?: NSLocalizedString(@"Request failed", @"");
                    NSString *correct = [u yt_displayCorrectAnswerText];
                    NSString *msg = base;
                    if (correct.length > 0) {
                        msg = [NSString stringWithFormat:@"%@\n\n%@ %@", base, NSLocalizedString(@"Correct answer:", @"After API error, label before reference answer"), correct];
                    }
                    __weak typeof(self) weakTip = self;
                    [YTTipAlertView showInView:self.view
                                      topTitle:nil
                                   contentText:msg
                            primaryButtonTitle:NSLocalizedString(@"OK", @"")
                           secondaryButtonTitle:nil
                                        onClose:^{
                        __strong typeof(weakTip) s = weakTip;
                        if (s) {
                            [s updateNavButtons];
                        }
                                    }
                                 onConfirm:^{
                        __strong typeof(weakTip) s = weakTip;
                        if (s) {
                            [s updateNavButtons];
                        }
                                    }
                                  onCancel:nil];
                    [self updateNavButtons];
                    return;
                }
                if (progressPercent >= 0 && progressPercent <= 100) {
                    self.serverProgressPercent = progressPercent;
                    [self updateProgressUI];
                }
                if (serverCorrect) {
                    [self markUnitCompletedIfNeeded:u];
                    [self showAnswerResultSheetCorrect:YES submitResult:submitResult];
                } else {
                    [self showAnswerResultSheetCorrect:NO submitResult:submitResult];
                }
                [self updateNavButtons];
            }];
            return;
        }

        if (kind == YTUnitPrimaryKindGotIt || kind == YTUnitPrimaryKindContinue) {
            // Continue/GotIt：仅当题型自身“达成完成条件”时才计入完成
            if ([u countsTowardProgress] && [self.unitView isUnitCompleteSignalSatisfied]) {
                [self markUnitCompletedIfNeeded:u];
            }
            [self goNext];
            return;
        }

        if (kind == YTUnitPrimaryKindRecord) {
            // 录音页：当满足完成信号时计入完成（PRD 5.3）
            if ([u countsTowardProgress] && [self.unitView isUnitCompleteSignalSatisfied]) {
                [self markUnitCompletedIfNeeded:u];
            }
        }
    }];
}

- (void)onBottomToastContinue {
    // 反馈条的 Continue：统一收起并进入下一题
    self.bottomToast.hidden = YES;
    [self goNext];
}

#pragma mark - Answer Result Sheet（通用底部弹窗）

- (void)showAnswerResultSheetCorrect:(BOOL)correct submitResult:(YTUnitSubmitResult * _Nullable)submitResult {
    // 收起旧的 toast（避免同时出现）
    self.bottomToast.hidden = YES;
    [self.answerResultSheet dismiss];
    self.answerResultSheet = nil;

    __weak typeof(self) weakSelf = self;
    if (correct) {
        self.answerResultSheet =
        [YTAnswerResultBottomSheet showInView:self.view
                                       style:YTAnswerResultBottomSheetStyleCorrect
                                  accentColor:self.theme.primaryColor
                                       title:NSLocalizedString(@"Correct Answer!", @"")
                                     message:nil
                                   highlight:nil
                                 buttonTitle:NSLocalizedString(@"Talk_Continue", @"")
                                   onPrimary:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self goNext];
        }];
        return;
    }

    NSString *correctText = submitResult.correctAnswerText ?: @"";
    // 听音类题型：如果有拼音提示，则把拼音放在前面一起展示（由调用方拼好传入弹窗）
    YTUnit *u = (self.currentIndex >= 0 && self.currentIndex < self.units.count) ? self.units[self.currentIndex] : nil;
    if (correctText.length == 0 && u) {
        correctText = [u yt_displayCorrectAnswerText];
    }
    if (u) {
        BOOL isListening = [u yt_isListeningExercise];
        if (isListening && (u.titlePinyin.length > 0)) {
            // 例：图书馆（tú shū guǎn）
            if (correctText.length > 0) {
                correctText = [NSString stringWithFormat:@"%@（%@）", correctText, u.titlePinyin];
            } else {
                correctText = u.titlePinyin;
            }
        }
    }
    NSString *msg = NSLocalizedString(@"The correct answer is :", @"");
    UIColor *hlColor = [theAppDelegate.window colorWithHexString:@"#F5585B" alpha:1];
    NSAttributedString *highlight = [[NSAttributedString alloc] initWithString:correctText attributes:@{
        NSForegroundColorAttributeName: hlColor,
        NSFontAttributeName: [UIFont fontWithName:FONT_NAME_Semibold size:22] ?: [UIFont boldSystemFontOfSize:22]
    }];

    self.answerResultSheet =
    [YTAnswerResultBottomSheet showInView:self.view
                                   style:YTAnswerResultBottomSheetStyleWrong
                                   title:NSLocalizedString(@"Wrong Answer", @"")
                                 message:msg
                               highlight:highlight
                             buttonTitle:NSLocalizedString(@"Got it", @"")
                               onPrimary:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        // 答错：点击按钮后允许题面重置（仅对需要重做的题型生效）
        if ([self.unitView respondsToSelector:@selector(resetAfterWrongAnswerIfNeeded)]) {
            [self.unitView resetAfterWrongAnswerIfNeeded];
        }
        [self updateNavButtons];
    }];
}

- (void)goPrev {
    NSInteger prev = self.currentIndex - 1;
    if (prev < 0) return;
    NSInteger lockIdx = [self indexOfFirstUnitBlockingReturnToPronounce];
    if (lockIdx != NSNotFound && self.currentIndex >= lockIdx && prev < lockIdx) {
        return;
    }
    self.bottomToast.hidden = YES;
    [self showUnitAtIndex:prev];
}

- (void)goNext {
    if (![self isCurrentStepUnlockedForNext]) return;
    NSInteger next = self.currentIndex + 1;
    if (next >= self.units.count) {
        // 无「完成页」unit 时的兜底（旧数据或未插入完成页）
        [self finishLevelFlow];
        return;
    }
    [self showUnitAtIndex:next];
}

/// 困难难度：完成页 / 最后一页过场页「探索其他场景」统一回根栈并切到场景 Tab
- (void)yt_popToTalkSceneRootAfterAdvancedFinish {
    if (theAppDelegate.tabBarController_startApp) {
        theAppDelegate.tabBarController_startApp.selectedIndex = 1;
    }
    UINavigationController *nav = self.navigationController;
    [nav popToRootViewControllerAnimated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *root = nav.viewControllers.firstObject;
        if ([root isKindOfClass:[TalkViewController class]]) {
            [(TalkViewController *)root yt_reloadCurrentSegmentList];
        }
    });
}

/// 本关学习流结束：完成页「进入下一等级」无缝进下一难度；最高难度或兜底则 pop 回话题页
- (void)finishLevelFlow {
    YTUnit *u = (self.currentIndex >= 0 && self.currentIndex < self.units.count) ? self.units[self.currentIndex] : nil;
    BOOL onLevelCompletePage = (u && u.unitType == YTUnitTypeLevelCompletion);
    if (onLevelCompletePage && self.levelId != YTLevelIdAdvanced) {
        [self transitionToNextDifficultyLevelSeamlessly];
        return;
    }
    // 困难难度完成后回到 Tab 的场景对话首页（而非仅退一层到上级页）
    if (onLevelCompletePage && self.levelId == YTLevelIdAdvanced) {
        [self yt_popToTalkSceneRootAfterAdvancedFinish];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

/// 栈仍为 [话题首页, 学习流]，仅替换顶层学习流为下一难度，动画上像从当前页直接进入下一难度
- (NSInteger)yt_effectiveTalkSceneNumericId {
    if (self.talkSceneNumericId > 0) {
        return self.talkSceneNumericId;
    }
    if (self.sceneId.length > 0) {
        NSInteger n = [self.sceneId integerValue];
        if (n > 0) {
            return n;
        }
    }
    return 0;
}

/// 与 `TalkTopicHomeViewController` 中 `pushLearningFlowWithLevel:` 的 `requestLevelId` 规则一致
- (NSInteger)yt_requestLevelIdForTalkAPIForDisplayLevel:(YTLevelId)displayLevel {
    NSInteger requestLevelId = (NSInteger)displayLevel + 1;
    if (self.talkDidApplyLevelAPI) {
        if (displayLevel == YTLevelIdBeginner) {
            requestLevelId = self.talkBeginnerLevelRecordId > 0 ? self.talkBeginnerLevelRecordId : 1;
        } else if (displayLevel == YTLevelIdIntermediate) {
            requestLevelId = self.talkIntermediateLevelRecordId > 0 ? self.talkIntermediateLevelRecordId : 2;
        } else {
            requestLevelId = self.talkAdvancedLevelRecordId > 0 ? self.talkAdvancedLevelRecordId : 3;
        }
    }
    return requestLevelId;
}

- (void)yt_copyTalkLevelContextToLearningFlowVC:(TalkLearningFlowViewController *)vc {
    vc.talkSceneNumericId = self.talkSceneNumericId;
    vc.talkDidApplyLevelAPI = self.talkDidApplyLevelAPI;
    vc.talkBeginnerLevelRecordId = self.talkBeginnerLevelRecordId;
    vc.talkIntermediateLevelRecordId = self.talkIntermediateLevelRecordId;
    vc.talkAdvancedLevelRecordId = self.talkAdvancedLevelRecordId;
}

- (void)yt_replaceTopWithLearningFlowVC:(TalkLearningFlowViewController *)nextVC {
    nextVC.hidesBottomBarWhenPushed = YES;
    UINavigationController *nav = self.navigationController;
    if (!nav) {
        return;
    }
    NSMutableArray<UIViewController *> *stack = [nav.viewControllers mutableCopy];
    if (stack.count == 0) {
        return;
    }
    [stack removeLastObject];
    [stack addObject:nextVC];
    [nav setViewControllers:stack animated:YES];
}

- (void)transitionToNextDifficultyLevelSeamlessly {
    YTLevelId next = (YTLevelId)(self.levelId + 1);
    if (next > YTLevelIdAdvanced) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    NSInteger sceneNumeric = [self yt_effectiveTalkSceneNumericId];
    if (sceneNumeric <= 0) {
        [YTTipAlertView showInView:self.view
                          topTitle:nil
                       contentText:NSLocalizedString(@"Talk_LearningFlow_InvalidScene_NextLevel", @"")
                primaryButtonTitle:NSLocalizedString(@"OK", @"")
               secondaryButtonTitle:nil
                            onClose:nil
                         onConfirm:nil
                          onCancel:nil];
        return;
    }
    NSInteger requestLevelId = [self yt_requestLevelIdForTalkAPIForDisplayLevel:next];
    YTMockLearningFlowBootstrapService *svc = [YTMockLearningFlowBootstrapService shared];
    svc.talkSceneNumericId = sceneNumeric;
    [[GlobalHUDManager shared] showSpinnerOnly];
    __weak typeof(self) weakSelf = self;
    [svc fetchBootstrapForSceneId:self.sceneId levelId:requestLevelId completion:^(YTLearningFlowBootstrap * _Nullable bootstrap, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        [[GlobalHUDManager shared] hide];
        if (!self) {
            return;
        }
        if (!bootstrap || error) {
            [YTTipAlertView showInView:self.view
                              topTitle:nil
                           contentText:NSLocalizedString(@"Talk_LearningFlow_LoadNextLevelFailed", @"")
                    primaryButtonTitle:NSLocalizedString(@"OK", @"")
                   secondaryButtonTitle:nil
                                onClose:nil
                             onConfirm:nil
                              onCancel:nil];
            return;
        }
        // 与话题卡 `/talk/level` 的 `progress_percent` 一致；栈中无话题页或未知时按 0% 注入
        CGFloat entryRatio = -1.0;
        for (UIViewController *vc in self.navigationController.viewControllers) {
            if ([vc isKindOfClass:[TalkTopicHomeViewController class]]) {
                entryRatio = [(TalkTopicHomeViewController *)vc progressRatioForDisplayLevel:next];
                break;
            }
        }
        NSInteger entryPct = 0;
        if (entryRatio >= 0.0) {
            entryPct = (NSInteger)llround(MAX(0.0, MIN(1.0, entryRatio)) * 100.0);
        }
        TalkLearningFlowViewController *nextVC = [[TalkLearningFlowViewController alloc] initWithSceneId:self.sceneId
                                                                                                  levelId:next
                                                                                       preloadedBootstrap:bootstrap
                                                                                   initialProgressPercent:entryPct];
        [self yt_copyTalkLevelContextToLearningFlowVC:nextVC];
        nextVC.talkSceneNumericId = sceneNumeric;
        [self yt_replaceTopWithLearningFlowVC:nextVC];
    }];
}

#pragma mark - 进度/解锁

/// 顶部条、续学弹窗圆环：仅使用 `serverProgressPercent`；无有效服务端百分比时按 0（不用本地 completed 估算）
- (CGFloat)yt_displayProgressRatio {
    if (self.serverProgressPercent >= 0 && self.serverProgressPercent <= 100) {
        return MIN(MAX((CGFloat)self.serverProgressPercent / 100.0, 0.0), 1.0);
    }
    return 0.0;
}

- (void)updateProgressUI {
    (void)self.progressBackgroundView;
    CGFloat p = [self yt_displayProgressRatio];
    NSInteger percent = (NSInteger)round(p * 100.0);
    NSString *progressPrefix = NSLocalizedString(@"Progress", @"");
    // 进度胶囊文案：所有难度统一展示“Progress”，避免 Intermediate/Advanced 被误显示为“Vocabulary”
    NSString *prefix = progressPrefix;
    self.progressPillLabel.text = [NSString stringWithFormat:@"%@  %ld%%", prefix, (long)percent];

    // 左：渐变块（宽 = p × 总长）；右：纯色轨道（宽 = (1-p) × 总长）。渐变末端 = 轨道色，避免与底色叠加产生白条/切割感
    [self.progressLeftGradientHost mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.progressBackgroundView);
        make.width.equalTo(self.progressBackgroundView).multipliedBy(p);
    }];
    [self.progressRightTrackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(self.progressBackgroundView);
        make.left.equalTo(self.progressLeftGradientHost.mas_right);
    }];
    [self.progressBackgroundView layoutIfNeeded];

    if (self.progressGradientLayer) {
        [self.progressGradientLayer removeFromSuperlayer];
        self.progressGradientLayer = nil;
    }
    if (p > 1e-6) {
        UIColor *startColor = nil;
        if (self.levelId == YTLevelIdBeginner) {
            startColor = [theAppDelegate.window colorWithHexString:@"#079669" alpha:0.5];
        } else if (self.levelId == YTLevelIdIntermediate) {
            startColor = [theAppDelegate.window colorWithHexString:@"#117FEC" alpha:0.5];
        } else {
            startColor = [theAppDelegate.window colorWithHexString:@"#2711EC" alpha:0.5];
        }
        UIColor *trackColor = self.progressRightTrackView.backgroundColor ?: [UIColor colorWithWhite:1.0 alpha:0.6];
        CAGradientLayer *grad = [CAGradientLayer layer];
        grad.frame = self.progressLeftGradientHost.bounds;
        grad.colors = @[(id)startColor.CGColor, (id)trackColor.CGColor];
        grad.startPoint = CGPointMake(0, 0.5);
        grad.endPoint = CGPointMake(1, 0.5);
        [self.progressLeftGradientHost.layer insertSublayer:grad atIndex:0];
        self.progressGradientLayer = grad;
    }

}

#pragma mark - LastPosition

- (void)saveLastPositionIfPossible {
    // 统一续学定位规则：
    // 不记录“从哪道题退出去”（不落库 lastPosition），继续学习直接依据 completedStepIndices 跳转。
    return;
}

- (void)markUnitCompletedIfNeeded:(YTUnit *)u {
    // 进度：仅对 countsTowardProgress == YES 的 unit 生效；按「当前步下标」记录，避免同 unit_id 多步被合并
    if (![u countsTowardProgress]) return;
    NSNumber *stepIdx = @(self.currentIndex);
    if ([self.completedStepIndices containsObject:stepIdx]) return;

    [self.completedStepIndices addObject:stepIdx];
    if (u.unitId.length > 0) {
        [self.completedUnitIds addObject:u.unitId];
    }
#if DEBUG
    NSLog(@"[TalkFlow][NextUnlock] markUnitCompletedIfNeeded ADD unitId=%@ type=%ld idx=%@",
          u.unitId ?: @"-",
          (long)u.unitType,
          stepIdx);
#endif
    [self updateNavButtons];
}

#pragma mark - Helpers

#pragma mark - 懒加载

- (UILabel *)progressPillLabel {
    if (!_progressPillLabel) {
        _progressPillLabel = [[UILabel alloc] init];
        _progressPillLabel.textAlignment = NSTextAlignmentCenter;
        // 进度文字：#1F1F39，字号 16，加粗，显示在渐变之上
        _progressPillLabel.textColor = [theAppDelegate.window colorWithHexString:@"#1F1F39" alpha:1];
        _progressPillLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        // 渐变承载视图本身透明，底色由 progressBackgroundView 提供
        _progressPillLabel.backgroundColor = [UIColor clearColor];
        _progressPillLabel.layer.cornerRadius = 20;
        _progressPillLabel.layer.masksToBounds = YES;
        NSString *progressPrefix = NSLocalizedString(@"Progress", @"");
        _progressPillLabel.text = [NSString stringWithFormat:@"%@ 0%%", progressPrefix];
        _progressPillLabel.numberOfLines = 1;
        _progressPillLabel.clipsToBounds = YES;
    }
    return _progressPillLabel;
}

- (UIView *)progressBackgroundView {
    if (!_progressBackgroundView) {
        _progressBackgroundView = [[UIView alloc] init];
        _progressBackgroundView.backgroundColor = [UIColor clearColor];
        _progressBackgroundView.layer.cornerRadius = 20;
        _progressBackgroundView.layer.masksToBounds = YES;

        _progressRightTrackView = [[UIView alloc] init];
        _progressRightTrackView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        [_progressBackgroundView addSubview:_progressRightTrackView];

        _progressLeftGradientHost = [[UIView alloc] init];
        _progressLeftGradientHost.backgroundColor = [UIColor clearColor];
        _progressLeftGradientHost.clipsToBounds = YES;
        [_progressBackgroundView addSubview:_progressLeftGradientHost];

        [_progressLeftGradientHost mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.equalTo(_progressBackgroundView);
            make.width.equalTo(_progressBackgroundView).multipliedBy(0);
        }];
        [_progressRightTrackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.top.bottom.equalTo(_progressBackgroundView);
            make.left.equalTo(_progressLeftGradientHost.mas_right);
        }];
    }
    return _progressBackgroundView;
}

- (UIView *)contentContainer {
    if (!_contentContainer) {
        // 容器背景透明：每个题型 Presenter 自己画卡片背景（便于不同题型不同布局）
        _contentContainer = [[UIView alloc] init];
        _contentContainer.backgroundColor = [UIColor clearColor];
    }
    return _contentContainer;
}

- (void)yt_startRecordingMeterDisplayLinkIfNeeded {
    if (self.recordingMeterDisplayLink) {
        return;
    }
    YTRecordingMeterBarsView *v = self.recordingMeterBarsView;
    if (!v.superview) {
        [self.primaryButton addSubview:v];
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.primaryButton);
            // 20×2 + 19×3 = 97pt
            make.width.mas_equalTo(97);
            make.height.mas_equalTo(22);
        }];
    }
    v.meterLevel = 0;
    self.recordingMeterWavePhaseAccum = 0;
    v.wavePhase = 0;
    self.recordingMeterDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(yt_onRecordingMeterTick:)];
    [self.recordingMeterDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)yt_stopRecordingMeterDisplayLink {
    [self.recordingMeterDisplayLink invalidate];
    self.recordingMeterDisplayLink = nil;
    self.recordingMeterWavePhaseAccum = 0;
    [self.recordingMeterBarsView removeFromSuperview];
}

- (void)yt_onRecordingMeterTick:(CADisplayLink *)link {
    if (![[YTRecordingService shared] isRecording]) {
        // 录音已停但主按钮状态可能尚未切到「评分中」：只停表，避免主按钮出现一帧空白；视图由 `onPrimaryStateChanged` 统一移除
        [self.recordingMeterDisplayLink invalidate];
        self.recordingMeterDisplayLink = nil;
        return;
    }
    CGFloat level = [[YTRecordingService shared] currentMeterNormalizedLevel];
    YTRecordingMeterBarsView *meter = self.recordingMeterBarsView;
    meter.meterLevel = level;
    // 静音时几乎不流动；有音量时按电平比例累加相位（与帧率无关）
    CGFloat dt = (CGFloat)link.duration;
    if (dt <= 0) {
        dt = 1.0f / 60.0f;
    }
    static const CGFloat kWaveFlowSpeed = 2.8f;
    CGFloat flow = (level < 0.035f) ? 0.f : (0.12f + 0.88f * level);
    self.recordingMeterWavePhaseAccum += dt * kWaveFlowSpeed * flow;
    meter.wavePhase = self.recordingMeterWavePhaseAccum;
}

- (YTRecordingMeterBarsView *)recordingMeterBarsView {
    if (!_recordingMeterBarsView) {
        _recordingMeterBarsView = [[YTRecordingMeterBarsView alloc] init];
    }
    return _recordingMeterBarsView;
}

- (YTDepthPrimaryButton *)primaryDepthButton {
    if (!_primaryDepthButton) {
        _primaryDepthButton = [YTDepthPrimaryButton learningFlowPrimaryButton];
        UIColor *initialFace = self.theme.primaryColor ?: [UIColor clearColor];
        _primaryDepthButton.faceColor = initialFace;
        UIButton *b = _primaryDepthButton.actionButton;
        YTLearningFlowApplyAdaptivePrimaryButton(b, 16);
        [b addTarget:self action:@selector(onPrimaryButton) forControlEvents:UIControlEventTouchUpInside];
        [b setTitle:NSLocalizedString(@"Talk_Continue", @"") forState:UIControlStateNormal];
    }
    return _primaryDepthButton;
}

- (UIButton *)primaryButton {
    return self.primaryDepthButton.actionButton;
}

- (UIButton *)prevButton {
    if (!_prevButton) {
        _prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _prevButton.layer.masksToBounds = YES;
        [_prevButton addTarget:self action:@selector(goPrev) forControlEvents:UIControlEventTouchUpInside];
    }
    return _prevButton;
}

- (UIButton *)nextButton {
    if (!_nextButton) {
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _nextButton.layer.masksToBounds = YES;
        [_nextButton addTarget:self action:@selector(onNextNavButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextButton;
}

/// 新切图：左/右常规态用 `left_*`、`right_enabled` / `right_disabled`；`right_empty` 仅完成页使用（见 `yt_applyLevelCompletionNextNavAppearance`）
- (void)yt_refreshNavButtonImages {
    NSString *prefix = YTTalkNavAssetPrefix(self.levelId);
    NSString *probeName = [NSString stringWithFormat:@"%@_left_enabled", prefix];
    UIImage *probe = [UIImage imageNamed:probeName];
    if (!probe) {
        [self yt_applyLegacyNavButtonImages];
        return;
    }

    UIImage *leftOn = [UIImage imageNamed:[NSString stringWithFormat:@"%@_left_enabled", prefix]];
    UIImage *leftOff = [UIImage imageNamed:[NSString stringWithFormat:@"%@_left_disabled", prefix]];
    UIImage *rightOn = [UIImage imageNamed:[NSString stringWithFormat:@"%@_right_enabled", prefix]];
    UIImage *rightDis = [UIImage imageNamed:[NSString stringWithFormat:@"%@_right_disabled", prefix]];

    UIButton *prev = self.prevButton;
    UIButton *next = self.nextButton;
    prev.backgroundColor = [UIColor clearColor];
    prev.layer.borderWidth = 0;
    next.backgroundColor = [UIColor clearColor];
    next.layer.borderWidth = 0;
    [prev setTitle:nil forState:UIControlStateNormal];
    [prev setTitle:nil forState:UIControlStateDisabled];
    [next setTitle:nil forState:UIControlStateNormal];
    [next setTitle:nil forState:UIControlStateDisabled];
    [next setBackgroundImage:nil forState:UIControlStateNormal];
    [next setBackgroundImage:nil forState:UIControlStateDisabled];
    next.titleLabel.adjustsFontSizeToFitWidth = NO;
    next.titleLabel.minimumScaleFactor = 1.0;

    UIImage *(^asOrig)(UIImage *) = ^UIImage *(UIImage *im) {
        return [im imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    };
    [prev setImage:asOrig(leftOn) forState:UIControlStateNormal];
    [prev setImage:asOrig(leftOff ?: leftOn) forState:UIControlStateDisabled];
    [next setImage:asOrig(rightOn) forState:UIControlStateNormal];
    [next setImage:asOrig(rightDis ?: rightOn) forState:UIControlStateDisabled];

    CGFloat sideH = self.primaryDepthButton.totalHeight;
    if (sideH > 0) {
        prev.layer.cornerRadius = sideH / 2.0;
        next.layer.cornerRadius = sideH / 2.0;
    }
}

- (void)yt_applyLegacyNavButtonImages {
    UIButton *prev = self.prevButton;
    UIButton *next = self.nextButton;
    prev.backgroundColor = [UIColor whiteColor];
    prev.layer.masksToBounds = YES;
    prev.layer.borderWidth = 1;
    prev.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;
    next.backgroundColor = [UIColor whiteColor];
    next.layer.masksToBounds = YES;
    next.layer.borderWidth = 1;
    next.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;

    UIImage *selL = [UIImage imageNamed:@"talk_arrow_left_sel"];
    UIImage *unL = [UIImage imageNamed:@"talk_arrow_left_unSel"];
    if (selL) {
        [prev setImage:[selL imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    if (unL) {
        [prev setImage:[unL imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateDisabled];
    }
    if (!selL || !unL) {
        if (@available(iOS 13.0, *)) {
            [prev setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
        } else {
            [prev setTitle:@"<" forState:UIControlStateNormal];
            [prev setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        }
        prev.tintColor = BLACK_COLOR_1F;
    }

    UIImage *selR = [UIImage imageNamed:@"talk_arrow_right_sel"];
    UIImage *unR = [UIImage imageNamed:@"talk_arrow_right_unSel"];
    if (selR) {
        [next setImage:[selR imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    if (unR) {
        [next setImage:[unR imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateDisabled];
    }
    if (!selR || !unR) {
        if (@available(iOS 13.0, *)) {
            [next setImage:[UIImage systemImageNamed:@"chevron.right"] forState:UIControlStateNormal];
        } else {
            [next setTitle:@">" forState:UIControlStateNormal];
            [next setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        }
        next.tintColor = BLACK_COLOR_1F;
    }
    [next setBackgroundImage:nil forState:UIControlStateNormal];
    [next setBackgroundImage:nil forState:UIControlStateDisabled];

    CGFloat sideH = self.primaryDepthButton.totalHeight;
    if (sideH > 0) {
        prev.layer.cornerRadius = sideH / 2.0;
        next.layer.cornerRadius = sideH / 2.0;
    }
}

/// 完成页：右侧使用 `right_empty` 底图 + 文案（Again / 重来），颜色为主题色，字号在底图内自适应缩小
- (void)yt_applyLevelCompletionNextNavAppearance {
    UIButton *next = self.nextButton;
    NSString *prefix = YTTalkNavAssetPrefix(self.levelId);
    UIImage *empty = [UIImage imageNamed:[NSString stringWithFormat:@"%@_right_empty", prefix]];
    UIImage *bg = empty ? [empty imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] : nil;

    [next setImage:nil forState:UIControlStateNormal];
    [next setImage:nil forState:UIControlStateDisabled];
    [next setBackgroundImage:bg forState:UIControlStateNormal];
    [next setBackgroundImage:bg forState:UIControlStateDisabled];
    next.backgroundColor = bg ? [UIColor clearColor] : [UIColor whiteColor];
    next.layer.borderWidth = 0;

    NSString *title = NSLocalizedString(@"Talk_LevelComplete_Nav_Again", @"");
    UIColor *tc = self.theme.primaryColor ?: [UIColor colorWithRed:0.22 green:0.48 blue:0.95 alpha:1];
    [next setTitle:title forState:UIControlStateNormal];
    [next setTitle:title forState:UIControlStateDisabled];
    [next setTitleColor:tc forState:UIControlStateNormal];
    [next setTitleColor:tc forState:UIControlStateDisabled];

    next.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    next.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    CGFloat inset = 6.0;
    next.contentEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    next.titleLabel.lineBreakMode = NSLineBreakByClipping;
    next.titleLabel.numberOfLines = 1;
    next.titleLabel.textAlignment = NSTextAlignmentCenter;
    next.titleLabel.adjustsFontSizeToFitWidth = YES;
    next.titleLabel.minimumScaleFactor = 0.45;
    UIFont *base = [UIFont fontWithName:FONT_NAME_Semibold size:18] ?: [UIFont boldSystemFontOfSize:18];
    next.titleLabel.font = base;

    CGFloat sideH = self.primaryDepthButton.totalHeight;
    if (sideH > 0) {
        next.layer.cornerRadius = sideH / 2.0;
    }
}

- (void)onNextNavButtonTapped {
    if (self.currentIndex >= 0 && self.currentIndex < self.units.count) {
        if (self.units[self.currentIndex].unitType == YTUnitTypeLevelCompletion) {
            [self showRestartLearningConfirmAlert];
            return;
        }
    }
    [self goNext];
}

- (UIView *)bottomToast {
    if (!_bottomToast) {
        _bottomToast = [[UIView alloc] init];
        _bottomToast.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
        _bottomToast.layer.cornerRadius = 16;
        _bottomToast.layer.masksToBounds = YES;
    }
    return _bottomToast;
}

- (UILabel *)bottomToastLabel {
    if (!_bottomToastLabel) {
        _bottomToastLabel = [[UILabel alloc] init];
        _bottomToastLabel.textColor = BLACK_COLOR_1F;
        _bottomToastLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _bottomToastLabel.numberOfLines = 2;
    }
    return _bottomToastLabel;
}

- (UIButton *)bottomToastButton {
    if (!_bottomToastButton) {
        _bottomToastButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _bottomToastButton.layer.cornerRadius = 18;
        _bottomToastButton.layer.masksToBounds = YES;
        _bottomToastButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:14];
        [_bottomToastButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_bottomToastButton setTitle:NSLocalizedString(@"Talk_Continue", @"") forState:UIControlStateNormal];
    }
    return _bottomToastButton;
}

@end
