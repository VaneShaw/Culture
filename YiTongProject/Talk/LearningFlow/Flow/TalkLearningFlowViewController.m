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
#import "YTDifficultyTheme.h"
#import "YTMockUnitFactory.h"
#import "YTUnitViewFactory.h"
#import "TalkEventTracker.h"
#import "YTAnswerResultBottomSheet.h"

/**
 场景对话 - 学习流容器（核心页）
 
 设计意图：
 - 入口直接进入学习流（用户选难度后直接开始做题）
 - 容器只负责：导航/进度/续学/埋点/底部主按钮驱动
 - 具体题型 UI/交互由 Presenter（`YTUnitViewProtocol`）承载，通过协议回调把“主按钮状态”回传给容器
 
 PRD MVP 约束（当前版本）：
 - 练习题：提交一次即算完成（对错不阻断流程）
 - 部分 unit 不计进度（见 `-[YTUnit countsTowardProgress]`）
 - 续学位置与已完成集合落地本地（无接口先跑通闭环）
 */
static NSString *const kYTLastPositionStorageKeyPrefix = @"talk_last_position";
static NSString *const kYTUnlockToastShownKeyPrefix = @"talk_unlock_toast_shown";

@interface TalkLearningFlowViewController ()

@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, assign) YTLevelId levelId;
@property (nonatomic, strong) YTDifficultyTheme *theme;

@property (nonatomic, strong) NSArray<YTUnit *> *units;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableSet<NSString *> *completedUnitIds;

@property (nonatomic, strong) UIView *progressBackgroundView;
@property (nonatomic, strong) UILabel *progressPillLabel;
@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, strong) id<YTUnitViewProtocol> unitView;
@property (nonatomic, strong) UIButton *primaryButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic, strong) CAGradientLayer *progressGradientLayer;

@property (nonatomic, strong) UIView *bottomToast;
@property (nonatomic, strong) UILabel *bottomToastLabel;
@property (nonatomic, strong) UIButton *bottomToastButton;

@property (nonatomic, strong) YTAnswerResultBottomSheet *answerResultSheet;

@end

@implementation TalkLearningFlowViewController

- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    return [self initWithSceneId:sceneId levelId:levelId preloadedUnits:nil];
}

- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId preloadedUnits:(NSArray<YTUnit *> *)preloadedUnits {
    self = [super init];
    if (self) {
        _sceneId = [sceneId copy];
        _levelId = levelId;
        _currentIndex = 0;
        _completedUnitIds = [NSMutableSet set];
        _units = preloadedUnits ?: @[];
    }
    return self;
}

#pragma mark - 生命周期

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 使用工程统一返回按钮：强制隐藏系统导航栏，避免系统返回按钮露出/重叠
    [self.navigationController setNavigationBarHidden:YES animated:animated];
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
    // Mock 数据先跑通 UI/交互/埋点链路；接接口时替换数据源即可
    if (self.units.count == 0) {
        self.units = [YTMockUnitFactory buildUnitsForSceneId:self.sceneId levelId:self.levelId];
    }
    [self restoreCompletedUnits];

    // 有续学位置则提示（避免误跳到中间）
    YTLastPosition *pos = [self loadLastPosition];
    if (pos) {
        [self showResumePromptWithLastPosition:pos];
    } else {
        [self showUnitAtIndex:0];
    }
}

#pragma mark - UI

- (void)setupUI {
    // UI 结构（自上而下）：
    // 1) 进度胶囊：底层背景 progressBackgroundView + 渐变层承载 progressPillLabel
    // 2) 内容容器 contentContainer（承载题型 rootView）
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
    [self.view addSubview:self.primaryButton];

    [self.prevButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-18);
        make.width.height.mas_equalTo(54);
    }];
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-18);
        make.width.height.mas_equalTo(54);
    }];
    [self.primaryButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.prevButton.mas_right).offset(12);
        make.right.equalTo(self.nextButton.mas_left).offset(-12);
        make.centerY.equalTo(self.prevButton);
        make.height.mas_equalTo(54);
    }];

    [self.view addSubview:self.bottomToast];
    [self.bottomToast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(16);
        make.bottom.equalTo(self.primaryButton.mas_top).offset(-12);
        make.height.mas_equalTo(56);
    }];
    self.bottomToast.hidden = YES;

    // 内容容器：位于进度条和底部按钮区域之间，底部与主按钮顶部相距 16，保持 335:546 宽高比
    [self.view addSubview:self.contentContainer];
    [self.contentContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(16);
        // 内容区域顶部距离进度条 16
        make.top.equalTo(self.progressPillLabel.mas_bottom).offset(16);
        make.bottom.equalTo(self.primaryButton.mas_top).offset(-16);
        make.height.equalTo(self.contentContainer.mas_width).multipliedBy(546.0/335.0);
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

- (void)showResumePromptWithLastPosition:(YTLastPosition *)pos {
    // 续学弹窗：
    // - 让用户确认是否从上次位置继续（避免默认跳转导致迷惑）
    // - “取消”直接返回上一页（避免留在空学习流页）
    NSString *unitName = [NSString stringWithFormat:@"%@-%@", [self levelName], [self unitDisplayNameForStepIndex:pos.stepIndex]];
    NSString *tpl = NSLocalizedString(@"Detected last learning at %@, continue?", @"");
    NSString *message = [NSString stringWithFormat:tpl, unitName];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue last learning", @"") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        NSInteger idx = [self indexForLastPosition:pos];
        [self showUnitAtIndex:MAX(0, idx)];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Start from beginning", @"") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        [self showUnitAtIndex:0];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        [self.navigationController popViewControllerAnimated:YES];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
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
    [self updateProgressUI];
    [self mountUnitViewForUnit:u];
    [self updateNavButtons];

    // 进入事件埋点
    [self markUnitEnter:u];
}

- (void)updateNavButtons {
    // 底部左右箭头仅负责切题；不影响“完成/进度”判定
    BOOL hasPrev = (self.currentIndex > 0);
    BOOL hasNext = (self.currentIndex + 1 < self.units.count);
    self.prevButton.enabled = hasPrev;
    self.nextButton.enabled = hasNext;
    self.prevButton.alpha = hasPrev ? 1.0 : 0.35;
    self.nextButton.alpha = hasNext ? 1.0 : 0.35;
}

- (void)mountUnitViewForUnit:(YTUnit *)u {
    // 清理旧内容
    for (UIView *v in self.contentContainer.subviews) {
        [v removeFromSuperview];
    }

    // 工厂根据 unitType/exerciseType 返回对应 Presenter（题型扩展点）
    self.unitView = [YTUnitViewFactory buildViewForUnit:u];
    __weak typeof(self) weakSelf = self;
    self.unitView.onPrimaryStateChanged = ^(YTUnitPrimaryState *state) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        // 容器只消费“主按钮状态”：文案/可用/类型（Submit/Continue/GotIt/Record）
        [self.primaryButton setTitle:NSLocalizedString(state.title ?: @"", @"") forState:UIControlStateNormal];
        self.primaryButton.enabled = state.enabled;
        self.primaryButton.tag = state.kind;
        self.primaryButton.backgroundColor = self.theme.primaryColor;
    };

    // 注入服务
    [self.unitView configureWithUnit:u
                               theme:self.theme
                               audio:[YTAudioMuxService shared]
                           recording:[YTRecordingService shared]
                             scoring:[YTScoringService shared]];

    UIView *rv = self.unitView.rootView;
    [self.contentContainer addSubview:rv];
    [rv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentContainer);
    }];
}

- (void)onPrimaryButton {
    if (self.units.count == 0) return;
    YTUnit *u = self.units[self.currentIndex];
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
            // 提交：展示对错反馈（错误时给出正确答案），并将该 unit 计为完成（PRD MVP）
            BOOL correct = submitResult ? submitResult.isCorrect : YES;
            [self showAnswerResultSheetCorrect:correct submitResult:submitResult];
            [self markUnitCompletedIfNeeded:u];
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
    if (u && u.unitType == YTUnitTypeExercise) {
        BOOL isListening = (u.exerciseType == YTExerciseTypeListenChooseImage || u.exerciseType == YTExerciseTypeListenChooseResponse);
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
    }];
}

- (void)goPrev {
    NSInteger prev = self.currentIndex - 1;
    if (prev < 0) return;
    self.bottomToast.hidden = YES;
    [self showUnitAtIndex:prev];
}

- (void)goNext {
    NSInteger next = self.currentIndex + 1;
    if (next >= self.units.count) {
        [self showLevelCompletion];
        return;
    }
    [self showUnitAtIndex:next];
}

- (void)showLevelCompletion {
    // 关卡完成（MVP 占位）：
    // - 当前用 Alert 提示并返回上一页
    // - 后续可替换为“完成页/奖励页/分享页”，并清理 lastPosition 或写入“已完成状态”
    NSString *title = NSLocalizedString(@"Level completed", @"");
    NSString *message = NSLocalizedString(@"You have completed this level (MVP placeholder)", @"");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
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
    // 进度计算口径：
    // - 仅统计 countsTowardProgress == YES 的 unit
    // - done 以 unitId 是否在 completed 集合为准
    NSInteger total = 0;
    NSInteger done = 0;
    for (YTUnit *u in self.units) {
        if (![u countsTowardProgress]) continue;
        total += 1;
        if ([self.completedUnitIds containsObject:u.unitId]) {
            done += 1;
        }
    }
    if (total <= 0) return 0;
    return (CGFloat)done / (CGFloat)total;
}

- (void)updateProgressUI {
    CGFloat p = [self currentProgress];
    NSInteger percent = (NSInteger)round(p * 100.0);
    NSString *progressPrefix = NSLocalizedString(@"Progress", @"");
    NSString *vocabPrefix = NSLocalizedString(@"Vocabulary", @"");
    NSString *prefix = (self.levelId == YTLevelIdBeginner) ? progressPrefix : vocabPrefix;
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
    // - 达到 60% 进度弹一次（每个 scene+level 仅一次）
    // - 目前用 Alert 轻量实现；后续可替换为自定义 toast
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

- (NSString *)lastPositionStorageKey {
    // 续学存档 Key：sceneId + levelId（不同场景/难度互不干扰）
    return [NSString stringWithFormat:@"%@_%@_%ld", kYTLastPositionStorageKeyPrefix, self.sceneId, (long)self.levelId];
}

- (nullable YTLastPosition *)loadLastPosition {
    // fromDictionary 内部有容错：坏数据会返回 nil
    id raw = [KUSER_DEFAULT objectForKey:[self lastPositionStorageKey]];
    return [YTLastPosition fromDictionary:raw];
}

- (void)saveLastPositionIfPossible {
    // 存档时机：viewWillDisappear 调用（见上方）
    // 说明：MVP 不做“完成后清理 lastPosition”，后续可按产品策略调整
    if (self.units.count == 0) return;
    if (self.currentIndex < 0 || self.currentIndex >= self.units.count) return;
    YTUnit *u = self.units[self.currentIndex];

    YTLastPosition *pos = [[YTLastPosition alloc] init];
    pos.sceneId = self.sceneId;
    pos.levelId = self.levelId;
    pos.unitType = u.unitType;
    pos.unitId = u.unitId;
    pos.stepIndex = u.stepIndex;
    pos.timestamp = [NSDate date].timeIntervalSince1970;
    [KUSER_DEFAULT setObject:[pos toDictionary] forKey:[self lastPositionStorageKey]];
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
    if ([self.completedUnitIds containsObject:u.unitId]) return;

    [self.completedUnitIds addObject:u.unitId];
    [self persistCompletedUnits];
    [self updateProgressUI];

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

- (UIButton *)primaryButton {
    if (!_primaryButton) {
        // 主按钮由 Presenter 驱动状态：title/enabled/kind（tag 存 kind）
        _primaryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _primaryButton.layer.cornerRadius = 27;
        _primaryButton.layer.masksToBounds = YES;
        [_primaryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _primaryButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        [_primaryButton addTarget:self action:@selector(onPrimaryButton) forControlEvents:UIControlEventTouchUpInside];
        [_primaryButton setTitle:NSLocalizedString(@"Talk_Continue", @"") forState:UIControlStateNormal];
    }
    return _primaryButton;
}

- (UIButton *)prevButton {
    if (!_prevButton) {
        // 左右切题按钮：只负责导航，不做“是否完成”判定（避免误改进度口径）
        _prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _prevButton.backgroundColor = [UIColor whiteColor];
        _prevButton.layer.cornerRadius = 27;
        _prevButton.layer.masksToBounds = YES;
        _prevButton.layer.borderWidth = 1;
        _prevButton.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;
        if (@available(iOS 13.0, *)) {
            [_prevButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
        } else {
            [_prevButton setTitle:@"<" forState:UIControlStateNormal];
            [_prevButton setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        }
        _prevButton.tintColor = BLACK_COLOR_1F;
        [_prevButton addTarget:self action:@selector(goPrev) forControlEvents:UIControlEventTouchUpInside];
    }
    return _prevButton;
}

- (UIButton *)nextButton {
    if (!_nextButton) {
        // 右切题：到最后一题后会被禁用（alpha 降低）
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _nextButton.backgroundColor = [UIColor whiteColor];
        _nextButton.layer.cornerRadius = 27;
        _nextButton.layer.masksToBounds = YES;
        _nextButton.layer.borderWidth = 1;
        _nextButton.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;
        if (@available(iOS 13.0, *)) {
            [_nextButton setImage:[UIImage systemImageNamed:@"chevron.right"] forState:UIControlStateNormal];
        } else {
            [_nextButton setTitle:@">" forState:UIControlStateNormal];
            [_nextButton setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        }
        _nextButton.tintColor = BLACK_COLOR_1F;
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

