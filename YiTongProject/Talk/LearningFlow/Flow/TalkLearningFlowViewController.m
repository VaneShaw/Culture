//
//  TalkLearningFlowViewController.m
//  YiTongProject
//

#import "TalkLearningFlowViewController.h"
#import "HeaderConfig.h"
#import "UserModel.h"
#import "LoginViewController.h"
#import "UIViewController+BackButton.h"

#import "YTLastPosition.h"
#import "YTLearningFlowBootstrap.h"
#import "YTLearningFlowBootstrapService.h"
#import "YTDifficultyTheme.h"
#import "YTMockUnitFactory.h"
#import "YTMockLearningFlowBootstrapService.h"
#import "YTLocalAnswerEvaluator.h"
#import "YTLocalPronounceEvaluator.h"
#import "YTLearningProgressStoring.h"
#import "YTUnitViewFactory.h"
#import "TalkEventTracker.h"
#import "YTAnswerResultBottomSheet.h"
#import "YTResumeLearningAlertView.h"
#import "YTTalkLearningDataService.h"
#import "YTDepthPrimaryButton.h"
#import "YTRecordingService.h"

/**
 场景对话 - 学习流容器（核心页）
 
 设计意图：
 - 入口直接进入学习流（用户选难度后直接开始做题）
 - 容器只负责：导航/进度/续学/埋点/底部主按钮驱动
 - 具体题型 UI/交互由 Presenter（`YTUnitViewProtocol`）承载，通过协议回调把“主按钮状态”回传给容器
 
 PRD MVP 约束（当前版本）：
 - 练习题：须答对才计入进度；未答对时底部右箭头置灰，答对后才可进入下一题
 - 部分 unit 不计进度（见 `-[YTUnit countsTowardProgress]`）
 - 续学位置与已完成集合落地本地（无接口先跑通闭环）
 */
static NSString *const kYTUnlockToastShownKeyPrefix = @"talk_unlock_toast_shown";

@interface TalkLearningFlowViewController ()

@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, assign) YTLevelId levelId;
@property (nonatomic, strong) YTDifficultyTheme *theme;

@property (nonatomic, strong) NSArray<YTUnit *> *units;
@property (nonatomic, strong, nullable) YTLearningFlowBootstrap *preloadedBootstrap;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableSet<NSString *> *completedUnitIds;
/// 续学弹窗选「继续上次学习」时为 YES，才从本地/后台恢复已答对题目的答案；选「从头开始」为 NO
@property (nonatomic, assign) BOOL resumePrefillCorrectAnswers;
/// YES：不请求 YTTalkLearningDataService，用 init 传入的 units 经插入过渡/完成页后从第 0 步开始
@property (nonatomic, assign) BOOL skipFetchUsePreloaded;

@property (nonatomic, strong) UIView *progressBackgroundView;
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

@end

@implementation TalkLearningFlowViewController

/// 是否为「练习题」题型（不含过渡页/完成页/发音）
static BOOL YTUnitTypeIsExerciseQuestion(YTUnitType t) {
    switch (t) {
        case YTUnitTypeExerciseListenChooseImage:
        case YTUnitTypeExerciseLookChooseWord:
        case YTUnitTypeExerciseChooseWordFillBlank:
        case YTUnitTypeExerciseListenChooseResponse:
        case YTUnitTypeExerciseBuildSentence:
        case YTUnitTypeExerciseCompleteDialogue:
            return YES;
        default:
            return NO;
    }
}

- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    return [self initWithSceneId:sceneId levelId:levelId preloadedUnits:nil skipFetchUsePreloaded:NO];
}

- (instancetype)initWithSceneId:(NSString *)sceneId
                        levelId:(YTLevelId)levelId
             preloadedBootstrap:(YTLearningFlowBootstrap *)preloadedBootstrap {
    self = [self initWithSceneId:sceneId levelId:levelId preloadedUnits:preloadedBootstrap.units skipFetchUsePreloaded:NO];
    if (self) {
        _preloadedBootstrap = preloadedBootstrap;
    }
    return self;
}

- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId preloadedUnits:(NSArray<YTUnit *> *)preloadedUnits {
    return [self initWithSceneId:sceneId levelId:levelId preloadedUnits:preloadedUnits skipFetchUsePreloaded:NO];
}

- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId preloadedUnits:(NSArray<YTUnit *> *)preloadedUnits skipFetchUsePreloaded:(BOOL)skip {
    self = [super init];
    if (self) {
        _sceneId = [sceneId copy];
        _levelId = levelId;
        _currentIndex = 0;
        _completedUnitIds = [NSMutableSet set];
        _units = preloadedUnits ?: @[];
        _skipFetchUsePreloaded = skip;
        _bootstrapService = [YTMockLearningFlowBootstrapService shared];
        _pronounceEvaluator = [YTLocalPronounceEvaluator shared];
        _answerEvaluator = [YTLocalAnswerEvaluator shared];
        _progressStore = [YTTalkLearningDataService shared];
    }
    return self;
}

#pragma mark - 生命周期

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
    if (self.skipFetchUsePreloaded && self.units.count > 0) {
        [self applyPreloadedUnitsAndStartFresh];
        return;
    }
    // 模拟接口：点击难度获取内容，返回 units + 上次学习位置 + 已完成列表
    __weak typeof(self) weakSelf = self;
    [self.bootstrapService fetchBootstrapForSceneId:self.sceneId levelId:self.levelId completion:^(YTLearningFlowBootstrap * _Nullable bootstrap, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!bootstrap) return;
        [self applyBootstrapAndStart:bootstrap];
    }];
}

/// 下一难度无缝切换：与 `startFlow` 中插入过渡/完成页、恢复已完成集合逻辑一致，但不走接口与续学
- (void)applyPreloadedUnitsAndStartFresh {
    self.units = [YTMockUnitFactory learningFlowUnitsFromRawUnits:self.units sceneId:self.sceneId levelId:self.levelId];
    [self restoreCompletedUnits];
    [self startFreshFromBeginning];
}

- (void)applyBootstrapAndStart:(YTLearningFlowBootstrap *)bootstrap {
    [self applyBootstrap:bootstrap];
    [self routeEntryFromBootstrap:bootstrap];
}

- (void)applyBootstrap:(YTLearningFlowBootstrap *)bootstrap {
    self.units = [YTMockUnitFactory learningFlowUnitsFromRawUnits:bootstrap.units sceneId:self.sceneId levelId:self.levelId];
    [self.completedUnitIds removeAllObjects];
    if (bootstrap.completedUnitIds.count > 0) {
        [self.completedUnitIds addObjectsFromArray:bootstrap.completedUnitIds];
    }

    // 拉取到已完成列表后立刻刷新顶部进度（含续学弹窗未点「继续」时也要与本地一致）
    [self updateProgressUI];
}

- (void)routeEntryFromBootstrap:(YTLearningFlowBootstrap *)bootstrap {
    YTLastPosition *lastPosition = bootstrap.lastPosition;
    if (!lastPosition) {
        [self startFreshFromBeginning];
        return;
    }

    NSInteger idx = [self indexForLastPosition:lastPosition];
    // 上次停留在第一题（index 0）不再弹续学窗，直接进入
    if (idx <= 0) {
        [self startFreshFromBeginning];
        return;
    }

    [self showResumePromptWithLastPosition:lastPosition];
}

- (void)startFreshFromBeginning {
    self.resumePrefillCorrectAnswers = NO;
    [self updateProgressUI];
    [self showUnitAtIndex:0];
}

#pragma mark - UI

- (void)setupUI {
    // UI 结构（自上而下）：
    // 1) 进度胶囊：底层背景 progressBackgroundView + 渐变层承载 progressPillLabel
    // 2) 内容容器 contentContainer：所有题型共用同一容器；各题 Presenter 的 rootView 铺满此区域（edges = contentContainer）
    // 3) 底部导航：左/主/右（三按钮），主按钮由 Presenter 驱动文案/可用态
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
}

#pragma mark - Flow

/// 清除各题上的续学/后台预填标记，避免「从头开始」后仍视为已答对、右箭头仍解锁
- (void)resetLearnStateFlagsOnAllUnits {
    for (YTUnit *u in self.units) {
        u.answeredCorrectFromServer = NO;
        u.serverAnswerPayload = nil;
    }
}

- (void)showResumePromptWithLastPosition:(YTLastPosition *)pos {
    // 续学弹窗：与 YTTipAlertView 同风格的卡片 + 圆环进度 + 继续/重新开始（无关闭按钮时仅能通过两按钮选择）
    CGFloat progressRatio = [self currentProgress];
    __weak typeof(self) weakSelf = self;
    [YTResumeLearningAlertView showInView:self.view
                            progressRatio:progressRatio
                                    title:nil
                               onContinue:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.resumePrefillCorrectAnswers = YES;
        NSInteger idx = [self indexForLastPosition:pos];
        [self showUnitAtIndex:MAX(0, idx)];
    }
                                onRestart:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.resumePrefillCorrectAnswers = NO;
        [self.progressStore clearAnswerSnapshotsForSceneId:self.sceneId levelId:self.levelId];
        [self.progressStore clearLastPositionForSceneId:self.sceneId levelId:self.levelId];
        [self.completedUnitIds removeAllObjects];
        [self persistCompletedUnits];
        [self resetLearnStateFlagsOnAllUnits];
        [self showUnitAtIndex:0];
    }];
}

- (NSInteger)indexForLastPosition:(YTLastPosition *)pos {
    if (!pos) return 0;
    // 优先按 unitId 精确定位（更抗数据结构调整）
    for (NSInteger i = 0; i < self.units.count; i++) {
        YTUnit *u = self.units[i];
        if ([u.unitId isEqualToString:pos.unitId]) return i;
    }
    // fallback：用 stepIndex 兜底，并做边界保护
    NSInteger idx = pos.stepIndex;
    if (idx < 0) idx = 0;
    if (idx >= self.units.count) idx = self.units.count - 1;
    return idx;
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

    // 模拟接口：进入新步骤时调用，更新当前用户所在页面
    [self.progressStore saveCurrentPositionForSceneId:self.sceneId levelId:self.levelId unitId:u.unitId stepIndex:u.stepIndex unitType:u.unitType completion:nil];

    [self markUnitEnter:u];
}

- (BOOL)isCurrentStepUnlockedForNext {
    if (self.units.count == 0) return NO;
    if (self.currentIndex < 0 || self.currentIndex >= self.units.count) return NO;
    YTUnit *u = self.units[self.currentIndex];
    if (u.answeredCorrectFromServer) return YES;
    if (u.unitId.length > 0 && [self.completedUnitIds containsObject:u.unitId]) return YES;
    if (self.unitView && [self.unitView isUnitCompleteSignalSatisfied]) return YES;
    return NO;
}

/// 第一道「过渡页」或「练习题」的下标：从该步起不可再回到前面的词汇/句子（发音）；均无则为 NSNotFound
- (NSInteger)indexOfFirstUnitBlockingReturnToPronounce {
    for (NSInteger i = 0; i < self.units.count; i++) {
        YTUnitType t = self.units[i].unitType;
        if (t == YTUnitTypePracticeTransition || YTUnitTypeIsExerciseQuestion(t)) {
            return i;
        }
    }
    return NSNotFound;
}

/// 第一道练习题下标；无练习题时为 NSNotFound
- (NSInteger)indexOfFirstExerciseQuestion {
    for (NSInteger i = 0; i < self.units.count; i++) {
        if (YTUnitTypeIsExerciseQuestion(self.units[i].unitType)) {
            return i;
        }
    }
    return NSNotFound;
}

/// 过渡页 / 完成页：隐藏左右箭头，主按钮与内容区等宽（左右 inset 20）；其它题型恢复三按钮布局
- (void)updateBottomBarLayoutForCurrentUnit {
    BOOL isTrans = NO;
    if (self.currentIndex >= 0 && self.currentIndex < self.units.count) {
        YTUnitType t = self.units[self.currentIndex].unitType;
        isTrans = (t == YTUnitTypePracticeTransition || t == YTUnitTypeLevelCompletion);
    }
    self.prevButton.hidden = isTrans;
    self.nextButton.hidden = isTrans;
    if (isTrans) {
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
    // 过渡页 / 完成页不展示左右箭头（由 updateBottomBarLayoutForCurrentUnit 控制 hidden）
    if (self.currentIndex >= 0 && self.currentIndex < self.units.count) {
        YTUnitType t = self.units[self.currentIndex].unitType;
        if (t == YTUnitTypePracticeTransition || t == YTUnitTypeLevelCompletion) {
            return;
        }
    }
    // 左箭头：过渡页起不可回发音；进入第一道练习题后也不可再回到过渡页（只能在本段练习题间后退）
    BOOL hasPrev = (self.currentIndex > 0);
    NSInteger firstExIdx = [self indexOfFirstExerciseQuestion];
    NSInteger lockIdx = [self indexOfFirstUnitBlockingReturnToPronounce];
    if (firstExIdx != NSNotFound && self.currentIndex >= firstExIdx) {
        hasPrev = (self.currentIndex > firstExIdx);
    } else if (lockIdx != NSNotFound && self.currentIndex >= lockIdx) {
        hasPrev = (self.currentIndex > lockIdx);
    }
    // 右箭头：须本题已达成完成条件（练习题为答对等）才解锁下一题
    BOOL hasNext = (self.currentIndex + 1 < self.units.count);
    BOOL nextUnlocked = [self isCurrentStepUnlockedForNext];
    self.prevButton.enabled = hasPrev;
    self.nextButton.enabled = (hasNext && nextUnlocked);
}

- (void)mountUnitViewForUnit:(YTUnit *)u {
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
            UIImage *recordingImage = [UIImage imageNamed:@"talk_vectoring"];
            if (recordingImage) {
                [self.primaryButton setTitle:@"" forState:UIControlStateNormal];
                [self.primaryButton setImage:recordingImage forState:UIControlStateNormal];
                self.primaryButton.imageView.contentMode = UIViewContentModeCenter;
            } else {
                // 资源缺失时回退文字，避免按钮空白
                [self.primaryButton setImage:nil forState:UIControlStateNormal];
                [self.primaryButton setTitle:NSLocalizedString(rawTitle, @"") forState:UIControlStateNormal];
            }
        } else {
            [self.primaryButton setImage:nil forState:UIControlStateNormal];
            [self.primaryButton setTitle:NSLocalizedString(rawTitle, @"") forState:UIControlStateNormal];
        }
        self.primaryButton.enabled = state.enabled;
        self.primaryButton.tag = state.kind;
        // 过渡页 / 完成页：深色主按钮；其余题型保留难度主题色（录音态见上）
        YTUnit *cu = (self.currentIndex >= 0 && self.currentIndex < self.units.count) ? self.units[self.currentIndex] : nil;
        UIColor *faceColor;
        if (cu && (cu.unitType == YTUnitTypePracticeTransition || cu.unitType == YTUnitTypeLevelCompletion)) {
            faceColor = [theAppDelegate.window colorWithHexString:@"#1F2540" alpha:1];
        } else {
            faceColor = self.theme.primaryColor;
        }
        self.primaryDepthButton.depthColor = nil;
        self.primaryDepthButton.faceColor = faceColor;
        [self.primaryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self updateNavButtons];
    };

    [self.unitView configureWithUnit:u
                               theme:self.theme
                               audio:[YTAudioMuxService shared]
                           recording:[YTRecordingService shared]
                  pronounceEvaluator:self.pronounceEvaluator
                     answerEvaluator:self.answerEvaluator];

    // 续学「继续」或后台：恢复已答对题目的选项/句子（从头开始不会带 payload）
    NSDictionary *restorePayload = nil;
    if (u.answeredCorrectFromServer && u.serverAnswerPayload.count > 0) {
        restorePayload = u.serverAnswerPayload;
    } else if (self.resumePrefillCorrectAnswers) {
        restorePayload = [self.progressStore answerSnapshotPayloadForUnitId:u.unitId sceneId:self.sceneId levelId:self.levelId];
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
            // 提交：展示对错反馈（错误时给出正确答案）；仅答对时计入进度
            BOOL correct = submitResult ? submitResult.isCorrect : YES;
            NSDictionary *answerPayload = submitResult.answerPayload ?: submitResult.restorableAnswerPayload;
            if (correct && answerPayload.count > 0) {
                [self.progressStore saveCorrectAnswerSnapshotForUnitId:u.unitId sceneId:self.sceneId levelId:self.levelId payload:answerPayload];
            }
            // 先计入完成并刷新顶部进度，再弹出结果页（避免弹层盖住时误以为进度未变）
            if (correct) [self markUnitCompletedIfNeeded:u];
            [self showAnswerResultSheetCorrect:correct submitResult:submitResult];
            [self updateNavButtons];
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
    if (u) {
        BOOL isListening = (u.unitType == YTUnitTypeExerciseListenChooseImage ||
                            u.unitType == YTUnitTypeExerciseListenChooseResponse);
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
    NSInteger firstExIdx = [self indexOfFirstExerciseQuestion];
    if (firstExIdx != NSNotFound && self.currentIndex >= firstExIdx && prev < firstExIdx) {
        return;
    }
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
        if (theAppDelegate.tabBarController_startApp) {
            theAppDelegate.tabBarController_startApp.selectedIndex = 1;
        }
        [self.navigationController popToRootViewControllerAnimated:YES];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

/// 栈仍为 [话题首页, 学习流]，仅替换顶层学习流为下一难度，动画上像从当前页直接进入下一难度
- (void)transitionToNextDifficultyLevelSeamlessly {
    YTLevelId next = (YTLevelId)(self.levelId + 1);
    if (next > YTLevelIdAdvanced) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    NSArray<YTUnit *> *nextUnits = [YTMockUnitFactory learningFlowUnitsForSceneId:self.sceneId levelId:next];
    if (nextUnits.count == 0) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    TalkLearningFlowViewController *nextVC = [[TalkLearningFlowViewController alloc] initWithSceneId:self.sceneId
                                                                                             levelId:next
                                                                                      preloadedUnits:nextUnits
                                                                              skipFetchUsePreloaded:YES];
    nextVC.hidesBottomBarWhenPushed = YES;
    UINavigationController *nav = self.navigationController;
    if (!nav) return;
    NSMutableArray<UIViewController *> *stack = [nav.viewControllers mutableCopy];
    if (stack.count == 0) return;
    [stack removeLastObject];
    [stack addObject:nextVC];
    [nav setViewControllers:stack animated:YES];
}

#pragma mark - 进度/解锁

- (void)restoreCompletedUnits {
    // 已完成集合（本地持久化）：用于进度计算与“重复进入不丢进度”
    // Key 维度：sceneId + levelId（不同场景/难度互不干扰）
    NSString *key = [self completedUnitsStorageKey];
    NSArray *arr = [KUSER_DEFAULT objectForKey:key];
    if ([arr isKindOfClass:[NSArray class]]) {
        for (id v in arr) {
            if ([v isKindOfClass:[NSString class]]) {
                [self.completedUnitIds addObject:v];
            }
        }
    }
}

- (void)persistCompletedUnits {
    // NSUserDefaults：存字符串数组即可（避免复杂结构）
    NSString *key = [self completedUnitsStorageKey];
    [KUSER_DEFAULT setObject:self.completedUnitIds.allObjects forKey:key];
}

- (NSString *)completedUnitsStorageKey {
    return [NSString stringWithFormat:@"talk_completed_units_%@_%ld", self.sceneId, (long)self.levelId];
}

- (CGFloat)currentProgress {
    // 进度 = 已写入 completed 的单元数 / 本关计入进度的单元总数。
    // 「何时写入」由 markUnitCompletedIfNeeded 各分支保证（练习答对、发音/跟读完成等），与顶部条展示一致。
    return [YTMockUnitFactory progressRatioForUnits:self.units completedUnitIdentifiers:self.completedUnitIds];
}

- (void)updateProgressUI {
    CGFloat p = [self currentProgress];
    NSInteger percent = (NSInteger)round(p * 100.0);
    NSString *progressPrefix = NSLocalizedString(@"Progress", @"");
    // 进度胶囊文案：所有难度统一展示“Progress”，避免 Intermediate/Advanced 被误显示为“Vocabulary”
    NSString *prefix = progressPrefix;
    self.progressPillLabel.text = [NSString stringWithFormat:@"%@  %ld%%", prefix, (long)percent];

    // 渐变进度条：仅在有进度时展示（渐变放在背景层，避免盖住文字）
    [self.progressBackgroundView layoutIfNeeded];
    if (self.progressGradientLayer) {
        [self.progressGradientLayer removeFromSuperlayer];
        self.progressGradientLayer = nil;
    }
    if (p > 0) {
        CGRect bounds = self.progressBackgroundView.bounds;
        if (!CGRectIsEmpty(bounds)) {
            // 起始颜色：按难度使用指定色，50% 透明度
            UIColor *startColor = nil;
            if (self.levelId == YTLevelIdBeginner) {
                startColor = [theAppDelegate.window colorWithHexString:@"#079669" alpha:0.5];
            } else if (self.levelId == YTLevelIdIntermediate) {
                startColor = [theAppDelegate.window colorWithHexString:@"#117FEC" alpha:0.5];
            } else {
                startColor = [theAppDelegate.window colorWithHexString:@"#2711EC" alpha:0.5];
            }
            UIColor *endColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];

            // 渐变范围 = 从左边到当前进度对应的宽度；渐变层只占这段宽度，这样整段都是左→右渐变
            CGFloat fillWidth = bounds.size.width * MIN(MAX(p, 0.0), 1.0);
            CAGradientLayer *grad = [CAGradientLayer layer];
            grad.frame = CGRectMake(0, 0, fillWidth, bounds.size.height);
            grad.colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
            grad.startPoint = CGPointMake(0, 0.5);
            grad.endPoint = CGPointMake(1, 0.5);

            // 背景 view 已 masksToBounds，渐变会被圆角裁剪；文字 label 始终在上层
            [self.progressBackgroundView.layer insertSublayer:grad atIndex:0];
            self.progressGradientLayer = grad;
        }
    }

    [self maybeShowUnlockToastIfNeededWithProgress:p];
}

- (void)maybeShowUnlockToastIfNeededWithProgress:(CGFloat)p {
    // 解锁提示（MVP）：
    // - 入门/进阶：进度 ≥60% 时提示一次（每个 scene+level 仅一次）；困难无下一难度，不提示
    // - 目前用 Alert 轻量实现；后续可替换为自定义 toast
    if (self.levelId == YTLevelIdAdvanced) return;
    if (p < 0.6) return;

    NSString *key = [NSString stringWithFormat:@"%@_%@_%ld", kYTUnlockToastShownKeyPrefix, self.sceneId, (long)self.levelId];
    if ([KUSER_DEFAULT boolForKey:key]) return;
    [KUSER_DEFAULT setBool:YES forKey:key];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Congratulations, you've unlocked the next level!", @"") preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

#pragma mark - LastPosition

- (void)saveLastPositionIfPossible {
    // 存档时机：viewWillDisappear 调用（见上方）
    // 说明：MVP 不做“完成后清理 lastPosition”，后续可按产品策略调整
    if (self.units.count == 0) return;
    if (self.currentIndex < 0 || self.currentIndex >= self.units.count) return;
    YTUnit *u = self.units[self.currentIndex];
    [self.progressStore saveCurrentPositionForSceneId:self.sceneId levelId:self.levelId unitId:u.unitId stepIndex:u.stepIndex unitType:u.unitType completion:nil];
}

#pragma mark - 埋点（MVP：先走 AnalyticsManager 的壳，后续完善）

- (void)markUnitEnter:(YTUnit *)u {
    // 进入 unit 埋点：用于漏斗与停留分析（MVP 只记录基础字段）
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"sceneId"] = u.sceneId ?: @"";
    params[@"levelId"] = @(u.levelId);
    params[@"unitType"] = @(u.unitType);
    params[@"unitId"] = u.unitId ?: @"";
    params[@"stepIndex"] = @(u.stepIndex);
    [[TalkEventTracker shared] track:@"unit_enter" params:params];
}

- (void)markUnitCompletedIfNeeded:(YTUnit *)u {
    // 完成埋点：
    // - 仅对 countsTowardProgress == YES 的 unit 生效
    // - unitId 去重，避免重复计入进度/重复上报
    if (!u.unitId.length) return;
    if (![u countsTowardProgress]) return;
    NSString *uid = [u.unitId copy];
    if ([self.completedUnitIds containsObject:uid]) return;

    [self.completedUnitIds addObject:uid];
    [self persistCompletedUnits];
    [self updateProgressUI];
    [self updateNavButtons];
    // 下一帧再刷一次，避免与弹窗/布局同帧竞态导致胶囊文案未刷新
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self updateProgressUI];
    });

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"sceneId"] = u.sceneId ?: @"";
    params[@"levelId"] = @(u.levelId);
    params[@"unitType"] = @(u.unitType);
    params[@"unitId"] = u.unitId ?: @"";
    params[@"durationMs"] = @(0);
    params[@"result"] = @"completed";
    [[TalkEventTracker shared] track:@"unit_complete" params:params];
}

#pragma mark - Helpers

- (NSString *)levelName {
    if (self.levelId == YTLevelIdBeginner) return NSLocalizedString(@"Beginner", @"");
    if (self.levelId == YTLevelIdIntermediate) return NSLocalizedString(@"Intermediate", @"");
    return NSLocalizedString(@"Advanced", @"");
}

- (NSString *)unitDisplayNameForStepIndex:(NSInteger)stepIndex {
    NSString *tpl = NSLocalizedString(@"Step %ld", @"");
    return [NSString stringWithFormat:tpl, (long)(stepIndex + 1)];
}

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
        // 使用原来的进度条背景色：白色 60% 透明度
        _progressBackgroundView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        _progressBackgroundView.layer.cornerRadius = 20;
        _progressBackgroundView.layer.masksToBounds = YES;
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

- (YTDepthPrimaryButton *)primaryDepthButton {
    if (!_primaryDepthButton) {
        _primaryDepthButton = [YTDepthPrimaryButton learningFlowPrimaryButton];
        UIColor *initialFace = self.theme.primaryColor ?: [UIColor clearColor];
        _primaryDepthButton.faceColor = initialFace;
        UIButton *b = _primaryDepthButton.actionButton;
        b.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
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
        // 左箭头：回看上一题；右箭头是否可点由「本题是否已达成完成条件」决定（见 updateNavButtons）
        _prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _prevButton.backgroundColor = [UIColor whiteColor];
        _prevButton.layer.masksToBounds = YES;
        _prevButton.layer.borderWidth = 1;
        _prevButton.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;

        UIImage *selImg = [UIImage imageNamed:@"talk_arrow_left_sel"];
        UIImage *unSelImg = [UIImage imageNamed:@"talk_arrow_left_unSel"];
        if (selImg) {
            [_prevButton setImage:[selImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        }
        if (unSelImg) {
            [_prevButton setImage:[unSelImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateDisabled];
        }

        // 资源兜底：确保按钮至少可见
        if (!selImg || !unSelImg) {
            if (@available(iOS 13.0, *)) {
                [_prevButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
            } else {
                [_prevButton setTitle:@"<" forState:UIControlStateNormal];
                [_prevButton setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
            }
            _prevButton.tintColor = BLACK_COLOR_1F;
        }

        [_prevButton addTarget:self action:@selector(goPrev) forControlEvents:UIControlEventTouchUpInside];
    }
    return _prevButton;
}

- (UIButton *)nextButton {
    if (!_nextButton) {
        // 右切题：最后一题或本题未过关时禁用（alpha 降低）
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _nextButton.backgroundColor = [UIColor whiteColor];
        _nextButton.layer.masksToBounds = YES;
        _nextButton.layer.borderWidth = 1;
        _nextButton.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;

        UIImage *selImg = [UIImage imageNamed:@"talk_arrow_right_sel"];
        UIImage *unSelImg = [UIImage imageNamed:@"talk_arrow_right_unSel"];
        if (selImg) {
            [_nextButton setImage:[selImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        }
        if (unSelImg) {
            [_nextButton setImage:[unSelImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateDisabled];
        }

        // 资源兜底：确保按钮至少可见
        if (!selImg || !unSelImg) {
            if (@available(iOS 13.0, *)) {
                [_nextButton setImage:[UIImage systemImageNamed:@"chevron.right"] forState:UIControlStateNormal];
            } else {
                [_nextButton setTitle:@">" forState:UIControlStateNormal];
                [_nextButton setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
            }
            _nextButton.tintColor = BLACK_COLOR_1F;
        }

        [_nextButton addTarget:self action:@selector(goNext) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextButton;
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
