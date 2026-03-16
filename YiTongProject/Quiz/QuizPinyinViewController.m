//
//  QuizPinyinViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/30.
//

#import "QuizPinyinViewController.h"
#import "QuizResultViewController.h"
#import "GradientProgressView.h"
#import "AudioPlayerManager.h"
#import "AnswerBackView.h"
#import "QuizResultViewController.h"
#import "QuizViewController.h"
#import "PronunciationFirstView.h"
#import "GuideManager.h"
#define Quiz_COLOR [UIColor clearColor]
#define Quiz_white_COLOR [UIColor whiteColor]

static NSString *const kFirstPageKey = @"FirstPage";

@interface QuizPinyinViewController ()<UINavigationControllerDelegate,UIGestureRecognizerDelegate>
@property (strong, nonatomic) GradientProgressView *progressView;
@property (strong, nonatomic) UILabel *lblRate;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) NSMutableArray<UIButton *> *answerButtons;

@property (nonatomic, assign) NSInteger wrongAttempts;
@property (nonatomic, assign) BOOL isAnswering; // 防止动画期间重复点击
@property (nonatomic, assign) int selectIndex;
@property (nonatomic, assign) int questions;     //做题数
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) NSArray *allArray;
@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, strong) UIImageView *imgAnswer;
@property (nonatomic, assign) int score;
@property (nonatomic, assign) BOOL hasPlayed;

@property (nonatomic, strong) UIButton *selectedQuestionButton;
@property (nonatomic, strong) UIButton *selectedAnswerButton;
@property (nonatomic, strong) NSString *audioUrl;
@property (nonatomic, assign) BOOL isCurrent;

@property (nonatomic, assign) BOOL hasHandledWrongUI; //「错误处理只允许执行一次」的锁
@property (nonatomic, assign) BOOL ishasPlayedAudio;//判断当按钮是选中 or 需求
@property (nonatomic, assign) BOOL hasAnswered;
@property (nonatomic, strong) NSArray<UIButton *> *answerBtnArray; // 四个按钮
@property (nonatomic, strong) NSMutableSet<NSNumber *> *selectedTags; // 用户选择的按钮 tag
@property (nonatomic, assign) BOOL hasScoredCurrentQuestion; // 本题是否已计分
@property (nonatomic, assign) BOOL hasScoredThisRound;

@end

@implementation QuizPinyinViewController
- (void)viewDidAppear:(BOOL)animated {//视图---出现
    [super viewDidAppear:animated];
    [self startStudy];
}
- (void)viewWillDisappear:(BOOL)animated {//视图即将消失v
    [super viewWillDisappear:animated];
    self.isCurrent = YES;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[AudioPlayerManager sharedManager] stopAllAudio];
    [self saveUserIndexAndScore:0];
    
    if (self.studyStartTimeMs > 0) {
        NSDictionary *extra = @{
               @"total": @(self.allArray.count),
               @"correct": @(self.score),
               @"score": @(self.score * 10)
        };
        BOOL isCompleted = self.questions >= 9;
        [self endStudyWithCompleted:isCompleted
                          eventType:EventTypeQuiz
                           eventName:@"测试事件"
                         contentType:@"pinyin"
                           extraParams:extra];
    }
    self.questions = 0;
    NSLog(@"self.selectIndex-------cvc---------[%d]-------cvc-----",self.selectIndex);
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    // 获取记忆的下标 有就跳转到该页面
    //int selectIndex = (int)[[GuideManager shared] storedIndexForPage:kFirstPageKey];
    int selectIndex = (int)[[GuideManager shared] storedQuizIndexForPage:kFirstPageKey];
    int score = (int)[[GuideManager shared] storedQuizScoreForPage:kFirstPageKey];
    
    if(selectIndex > 0){
        NSArray *titleArray0 = @[@"Welcome back!",@"Continue from where you stopped?",@"No, start over",@"Yes, resume"];
        //[AnswerBackView showViewTitle:@"0" buttonArrayTitle:@[] callBack:^(NSInteger index) {
        [ReadyLogOutView showViewTitle:@"" buttonArrayTitle:titleArray0 callBack:^(NSInteger index) {
            if(index == 1000){//No, start over 从第一题开始     1001 Yes, resume继续
                self.selectIndex = 0;
                self.questions = 0;
            } else {
                self.score = score;
                self.selectIndex = selectIndex;
                self.questions = selectIndex;
                if(self.dataArray.count > 0 ){
                    [self loadNewQuestion];
                } else {
                    [self getPracticeList];
                }
            }
        }];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    // 如果当前页面即将消失，且是侧滑返回
    if ([viewController isKindOfClass:[QuizViewController class]]) {
        NSLog(@"用户正在侧滑返回上一页");
        // 在这里执行你的逻辑
        [self saveUserIndexAndScore:self.selectIndex];
    }
}
- (void)saveUserIndexAndScore:(int)index {
    //[[GuideManager shared] storeIndex:self.selectIndex forPage:kFirstPageKey];
    //[[GuideManager shared] storeIndex:self.selectIndex forPage:kFirstPageKey];
    if(index > 0){
        [[GuideManager shared] storeIndex:self.selectIndex score:self.score forPage:kFirstPageKey];
    } else {
        [[GuideManager shared] storeIndex:0 score:0 forPage:kFirstPageKey];
    }
}

#pragma mark - 应用生命周期通知

- (void)appWillResignActive:(NSNotification *)notification {
    NSLog(@"应用即将失去活跃状态，保存游戏进度");
    [self saveUserIndexAndScore:self.selectIndex];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
    NSLog(@"应用已进入后台，保存游戏进度");
    [self saveUserIndexAndScore:self.selectIndex];
}
- (void)backAction {
    
    //@"\n"
    NSArray *titleArray1 = @[@"Quit now?",@"Your progress won’t be saved.You’re almost done — don’t give up now!",@"Exit Anyway",@"Keep Going"];
    [ReadyLogOutView showViewTitle:@"" buttonArrayTitle:titleArray1 callBack:^(NSInteger index) {
        if(index == 1000){//返回。  //1001继续当前
            self.selectIndex = 0;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}
- (void)playAudio:(NSString *)audio_url {
    [[AudioPlayerManager sharedManager] playShortAudioWithURL:audio_url completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            // 播放成功完成
            [self updateUIForPlaybackSuccess];
        } else {
            // 处理播放错误
            [self handlePlaybackError:error];
        }
    }];
}
- (void)updateUIForPlaybackSuccess {
    // 更新UI显示播放成功
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.cell finishRecording];
    });
}
- (void)handlePlaybackError:(NSError *)error {
    // 处理错误并更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.cell finishRecording];
    });
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"quiz_pinyin";
    self.view.backgroundColor = [self.view colorWithHexString:@"#63A8F5" alpha:1];
    self.navigationController.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    // 初始化选择集合
    self.selectedTags = [NSMutableSet set];
    self.selectIndex = 0;
    self.questions = 0;
    self.score = 0;
    //------------------------------------------------------------
    int headerHeight = 550;
    self.headerView = [[UIView alloc]initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - headerHeight)/2-0, SCREEN_WIDTH, headerHeight)];
    self.headerView.clipsToBounds = YES;
    [self.view addSubview:self.headerView];
    self.headerView.backgroundColor = [UIColor clearColor];
    
    self.footerView = [[UIView alloc]initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - headerHeight)/2 - 25 -0, SCREEN_WIDTH, headerHeight + 50)];
    [self.view addSubview:self.footerView];
    self.footerView.clipsToBounds = YES;
    self.footerView.backgroundColor = self.view.backgroundColor;
    self.footerView.hidden = YES;
    
    UIImageView *imgAnswer = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH-145)/2, (self.footerView.frame.size.height - 145)/2 - 20, 145, 145)];
    [self.footerView addSubview:imgAnswer];
    self.imgAnswer = imgAnswer;
    //------------------------------------------------------------
    
    int width = 38;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    btn.frame = CGRectMake(20 ,statusBarH + 30, width, width);
    btn.layer.cornerRadius = width/2;//圆角
    btn.layer.masksToBounds = YES;
    btn.backgroundColor = [self.view colorWithHexString:@"#DEDEDE" alpha:0.5];
    [btn setImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    //进度条
    self.progressView = [[GradientProgressView alloc]initWithFrame:CGRectMake(68, btn.frame.origin.y + (width-8)/2, SCREEN_WIDTH - 68 - 57, 8)];
    self.progressView.layer.cornerRadius = 4;//圆角
    self.progressView.layer.masksToBounds = YES;
    self.progressView.backgroundColor = [self.view colorWithHexString:@"#FFFFFF" alpha:0.2];
    [self.view addSubview:self.progressView];
    
    self.lblRate = [UILabel new];
    self.lblRate.textColor = [UIColor whiteColor];
    self.lblRate.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:14];
    
    [self.view addSubview:self.lblRate];
    [self.lblRate mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.progressView.mas_right).offset(7);
        make.right.equalTo(self.view.mas_right).offset(5);
        make.centerY.equalTo(self.progressView);
        make.height.equalTo(@18);
    }];
    self.answerButtons = [NSMutableArray array];
    self.wrongAttempts = 0;
    self.isAnswering = NO;
    self.hasAnswered = NO;
    [self setupPlayButton];
    [self getPracticeList];
    
    if ([[GuideManager shared] shouldShowGuideForPage:kFirstPageKey]) {
        //创建半透明覆盖层
        UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
        overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.01]; // 几乎透明
        overlay.tag = 919; // 设置tag以便之后移除
        [self.view addSubview:overlay];
        
        //显示引导图
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            overlay.hidden = YES;
            if(self.isCurrent)return;
            [KUSER_DEFAULT setObject:@"is_pinyin" forKey:@"first_key"];
            [PronunciationFirstView showViewTitle:@"1" buttonFrame:self.playButton.frame callBack:^(NSInteger index) {
                if(index == 101){
                    overlay.hidden = NO;
                    [self playButtonTapped:self.playButton];
                    //---------------------------------------------------------
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[self.view viewWithTag:919] removeFromSuperview];
                        UIButton *button = (UIButton *)[self.headerView viewWithTag:100];
                        NSString *title = button.titleLabel.text;
                        
                        if(self.isCurrent)return;
                        [[GuideManager shared] markGuideShownForPage:kFirstPageKey];
                        [PronunciationFirstView showViewTitle:title buttonFrame:button.frame callBack:^(NSInteger index) {
                            if(index == 101){
                                [self answerButtonTapped:button];
                            }
                        }];
                    });
                    //---------------------------------------------------------
                }
            }];
        });
    }
    
    // 注册应用生命周期通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)dealloc {
    // 移除通知观察者
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
- (void)setupPlayButton {
    int height = self.headerView.frame.size.height;
    int diameter = 140;
    UIView *roundView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2-diameter/2, height/2-diameter/2, diameter, diameter)];
    roundView.layer.cornerRadius = diameter/2;//圆角
    [self.headerView addSubview:roundView];
    //roundView.center = self.headerView.center;
    [self.view setupMultiPulseAnimationForView:roundView];
    
    diameter = 88;
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.frame = CGRectMake(SCREEN_WIDTH/2-diameter/2, height/2-diameter/2, diameter, diameter);
    self.playButton.layer.cornerRadius = diameter/2;
    self.playButton.backgroundColor = [self.view colorWithHexString:@"#1181FF" alpha:1];
    self.playButton.tag = 10;
    [self.playButton setImage:[UIImage imageNamed:@"audio_white"] forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.playButton];
}
- (void)loadNewQuestion {
    // 清空之前的按钮
    for (UIButton *button in self.answerButtons) {
        [button removeFromSuperview];
    }
    [self.answerButtons removeAllObjects];
    self.wrongAttempts = 0;
    self.isAnswering = NO;
    self.selectedQuestionButton = nil;
    self.selectedAnswerButton = nil;
    self.hasPlayed = NO;
    // 重置播放按钮样式
    self.playButton.backgroundColor = [self.view colorWithHexString:@"#1181FF" alpha:1];
    int count = (int)self.allArray.count;
    float rate = (float)self.selectIndex/count;
    [self.progressView setColorProgress:rate color:@"#FFFFFF" alpha:1 animated:YES];
    self.lblRate.text = [NSString stringWithFormat:@"%d/%d",self.selectIndex,count];
    
    //audio character
    int diameter = 100;
    // 创建四个答案按钮
    for (int i = 0; i < self.dataArray.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, diameter, diameter);
        button.layer.cornerRadius = diameter/2;
        button.backgroundColor = [UIColor clearColor];
        [button setTitle:self.dataArray[i][@"character"] forState:UIControlStateNormal];
        NSString *audio = [NSString stringWithFormat:@"%@",self.dataArray[i][@"audio"]];
        button.tag = 1000 + i;
        if(audio.length > 6){
            self.audioUrl = audio;
            button.tag = 100;
        }
        
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:36];
        button.layer.borderWidth = 2;  //边框
        button.layer.borderColor = [UIColor whiteColor].CGColor;
        //button.tag = i;
        
        // 设置初始位置在屏幕外
        CGFloat startX = 0, startY = 0;
        int side = arc4random_uniform(4);
        switch (side) {
            case 0: // 上
                startX = arc4random_uniform((uint32_t)self.headerView.bounds.size.width);
                startY = -100;
                break;
            case 1: // 右
                startX = self.headerView.bounds.size.width + 100;
                startY = arc4random_uniform((uint32_t)self.headerView.bounds.size.height);
                break;
            case 2: // 下
                startX = arc4random_uniform((uint32_t)self.headerView.bounds.size.width);
                startY = self.view.bounds.size.height + 100;
                break;
            case 3: // 左
                startX = -100;
                startY = arc4random_uniform((uint32_t)self.headerView.bounds.size.height);
                break;
        }
        button.center = CGPointMake(startX, startY);
        [button addTarget:self action:@selector(answerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.headerView addSubview:button];
        [self.answerButtons addObject:button];
        self.answerBtnArray = [NSArray arrayWithArray:self.answerButtons];
    }
    // 动画效果
    [self animateButtonsToValidPositions];
}
- (void)animateButtonsToValidPositions {
    NSMutableArray *finalPositions = [NSMutableArray array];
    //计算有效位置，确保不重叠
    for (int i = 0; i < 4; i++) {
        CGPoint position;
        BOOL positionValid;
        int attempts = 0;
        do {
            positionValid = YES;
            attempts++;
            //随机生成位置，但不要太靠近播放按钮
            CGFloat minDistanceFromPlayButton = 120;
            CGFloat minDistanceBetweenButtons = 120;
            
            CGFloat x, y;
            do {
                x = 100 + arc4random_uniform((uint32_t)(self.headerView.bounds.size.width - 176));
                y = 100 + arc4random_uniform((uint32_t)(self.headerView.bounds.size.height - 176));
            } while (sqrt(pow(x - self.playButton.center.x, 2) + pow(y - self.playButton.center.y, 2)) < minDistanceFromPlayButton);
            position = CGPointMake(x, y);
            
            // 检查是否与其他按钮重叠
            for (NSValue *posValue in finalPositions) {
                CGPoint existingPos = [posValue CGPointValue];
                if (sqrt(pow(position.x - existingPos.x, 2) + pow(position.y - existingPos.y, 2)) < minDistanceBetweenButtons) {
                    positionValid = NO;
                    break;
                }
            }
            
            if (attempts > 100) {
                // 防止无限循环，如果尝试次数太多，放宽条件
                minDistanceBetweenButtons -= 10;
                attempts = 0;
            }
        } while (!positionValid && attempts < 200);
        [finalPositions addObject:[NSValue valueWithCGPoint:position]];
    }
    
    // 执行动画
    for (int i = 0; i < 4; i++) {
        UIButton *button = self.answerButtons[i];
        CGPoint finalPosition = [finalPositions[i] CGPointValue];
        [UIView animateWithDuration:0.5 + (i * 0.1)
                              delay:0.1 * i
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            button.center = finalPosition;
        } completion:nil];
    }

    //[self loadNextQuestion11];
}
//进入下一题
- (void)loadNextQuestion11 {
    self.hasScoredCurrentQuestion = NO;
    self.hasScoredThisRound = NO;
    self.hasPlayed = NO;
    //self.wrongAttempts = 0;
}
//点击字母1
//问题按钮     播放声音
- (void)answeriQuestionsCorrectly:(UIButton *)sender {
    if (self.hasScoredThisRound) {
           return;
       }
       // ✅ 第一次进入，立刻上锁
    self.hasScoredThisRound = YES;
    [self handleCorrectAnswer:sender];
    [self addAnsweResult:YES];
    self.selectIndex++;
    self.questions++;
    self.score++;

}
- (void)playButtonTapped:(UIButton *)sender {
    NSLog(@"播放音标");
    // 这里实现播放音标的逻辑
    [self playAudio:self.audioUrl];
    // 标记已播放
    self.hasPlayed = YES;
    self.ishasPlayedAudio = YES;
    self.selectedQuestionButton = sender;
    // 可选：改变播放按钮样式表示已播放
    if (self.hasScoredCurrentQuestion) {
        return;
    }
    if(self.selectedAnswerButton.tag == 100){
        NSLog(@"回答正确!------------------------11-------------------------------------11----");
        self.hasScoredCurrentQuestion = YES; // 🔒 锁住，不再重复计分
        [self answeriQuestionsCorrectly:sender];
        self.hasHandledWrongUI = NO;
    } else {
        if(self.selectedAnswerButton.tag > 100){
            //回答错误xxx
            self.wrongAttempts++;
        }
    }
    if(self.selectedAnswerButton.tag > 1000){
        if (self.selectedAnswerButton) {
            if(!self.hasHandledWrongUI){
                [self handleWrongAnswer:self.selectedAnswerButton];  //改动313
                [self restoreButtonSize:self.selectedAnswerButton];
                [self setAnswerNotButton:self.selectedAnswerButton];
                self.hasHandledWrongUI = YES;
            }
            //self.selectedAnswerButton = nil;
        }
    }
}
//=================================================================
- (void)selectButton:(UIButton *)button {
    // 轻微放大效果 (1.1倍)
    [UIView animateWithDuration:0.3 animations:^{
        button.transform = CGAffineTransformMakeScale(1.10, 1.10);
        //button.backgroundColor = color;
    }];
}
- (void)restoreButtonSize:(UIButton *)button {
    [UIView animateWithDuration:0.3 animations:^{
        button.transform = CGAffineTransformIdentity;
    }];
}
- (void)setAnswerSelectButton:(UIButton *)button {
    button.backgroundColor = Quiz_white_COLOR;
    UIColor *selectColor = self.view.backgroundColor;
    
    [button setTitleColor:selectColor forState:UIControlStateNormal];
    button.layer.borderWidth = 5;
    button.layer.borderColor = [self.view colorWithHexString:@"#f4f4f4" alpha:0.8].CGColor;
    [self.selectedAnswerButton setTintColor:[UIColor redColor]];
}
- (void)setAnswerNotButton:(UIButton *)button {
    button.backgroundColor = Quiz_COLOR;//改动313 再次点击 会触发失败 但不能透明
    button.layer.borderWidth = 2;
    button.layer.borderColor = Quiz_white_COLOR.CGColor;
    [button setTitleColor:Quiz_white_COLOR forState:UIControlStateNormal];
    if(self.ishasPlayedAudio){
        button.backgroundColor = Quiz_white_COLOR;
        UIColor *selectColor = self.view.backgroundColor;
        [button setTitleColor:selectColor forState:UIControlStateNormal];
    }
}

//=================================================================
- (void)handleAnswerButtonTap:(UIButton *)button {
    
    if (button == self.selectedAnswerButton) {
        //取消选中 - 恢复大小。   再次点击取消
        [self restoreButtonSize:button];
        [self setAnswerNotButton:button];
        self.selectedAnswerButton = nil;
    } else {
        // 取消之前选中的答案按钮
        if (self.selectedAnswerButton) {
            [self restoreButtonSize:self.selectedAnswerButton];
            
            self.ishasPlayedAudio = NO;
            [self setAnswerNotButton:self.selectedAnswerButton];
            [self setAnswerSelectButton:button];
            [self selectButton:button];
            self.selectedAnswerButton = button;
            
        } else {
            //单击选中
            [self setAnswerSelectButton:button];
            [self selectButton:button];
            self.selectedAnswerButton = button;
        }
    }
}

//点击字母1//点击答案    答案按钮
- (void)answerButtonTapped:(UIButton *)sender {
    
    NSLog(@"------self.hasAnswered=[%d]--------------ccc-----------",self.hasAnswered);
    
    if(!self.hasAnswered){
        self.hasAnswered = YES;
        [self handleAnswerButtonTap:sender];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.hasAnswered = NO;
        });
        
        // 检查是否已播放
        if (!self.hasPlayed) {
            //[self handleAnswerButtonTap:sender];
            //[self showPlayFirstAlert];
            return;
        }
        
        if (self.isAnswering) return;
        self.isAnswering = YES;
        self.hasHandledWrongUI  = NO;
        //NSLog(@"选择了答案: ------[%d]",sender.tag);
        // 假设第一个按钮是正确答案（实际应用中应该有更复杂的逻辑）
        self.selectedAnswerButton = sender;
        
        if (sender.tag == 100) {
            NSLog(@"----------回答正确!-------22-------------------22----------");
           
            [self answeriQuestionsCorrectly:sender];
            //[self playAudio:self.audioUrl];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.hasAnswered = NO;
            });
        } else {
            //回答错误xxx
            self.wrongAttempts++;
            [self handleWrongAnswer:sender];
            if (self.wrongAttempts >= 2) {
                self.selectIndex++;
                self.questions++;
                [self proceedToNextQuestionAfterDelay:1.2];
                [self addAnsweResult:NO];
            } else {
                self.isAnswering = NO;
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.hasAnswered = NO;
            });
        }
    }
}
- (void)addAnsweResult:(BOOL)isCorrect {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.footerView.hidden = NO;
        self.imgAnswer.image = [UIImage imageNamed:@[@"answer_red",@"answer_greend"][isCorrect]];//
        [self.imgAnswer addElasticAnimationWithDuration:0.5];
        
        int count = (int)self.allArray.count ;
        float rate = (float)self.selectIndex/count;
        [self.progressView setColorProgress:rate color:@"#FFFFFF" alpha:1 animated:YES];
        self.lblRate.text = [NSString stringWithFormat:@"%d/%d",self.selectIndex,count];
    });
    
    if(isCorrect){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.footerView.hidden = YES;
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.footerView.hidden = YES;
        });
    }
    
}
//回答正确
- (void)handleCorrectAnswer:(UIButton *)correctButton {
    // 正确答案按钮放大并变绿色
    [UIView animateWithDuration:0.4 animations:^{
        //correctButton.backgroundColor = [UIColor greenColor];
        correctButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        // 所有按钮向播放按钮移动并消失
        [UIView animateWithDuration:1.0 animations:^{
            for (UIButton *button in self.answerButtons) {
                if(button.tag == 100 && self.hasPlayed){
                    button.center = self.playButton.center;
                    button.alpha = 0;
                    button.transform = CGAffineTransformMakeScale(0.1, 0.1);
                } else {
                    button.alpha = 0;
                }
            }
        } completion:^(BOOL finished) {
            //self.selectIndex++;
            //self.score++;
            [self proceedToNextQuestionAfterDelay:1.2];
        }];
    }];
}
//回答错误
- (void)handleWrongAnswer:(UIButton *)wrongButton {
    // 错误按钮抖动效果
    CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    shake.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    shake.duration = 0.6;
    shake.values = @[@(-20), @(20), @(-15), @(15), @(-10), @(10), @(-5), @(5), @(0)];
    [wrongButton.layer addAnimation:shake forKey:@"shake"];
    
    // 错误按钮变红色
    [UIView animateWithDuration:0.3 animations:^{
        //wrongButton.backgroundColor = [UIColor redColor];
    }];
    
    // 显示正确答案（第一个按钮）
    UIButton *correctButton = self.answerButtons[0];
    [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //correctButton.backgroundColor = [UIColor greenColor];
        //correctButton.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:nil];
}
- (void)proceedToNextQuestionAfterDelay:(NSTimeInterval)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reloadButtonsView];
    });
}
//点击字母1/ 进入下一题
- (void)reloadButtonsView {
    if(self.selectIndex >= self.allArray.count){
        QuizResultViewController *vc = [QuizResultViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        vc.score = self.score;
        self.selectIndex = 0;
        __weak typeof(self) weakSelf = self;
        [vc setSelectedTypeIndex:^(NSInteger index) {
            if (index == 1) {
                //weakSelf.selectIndex = 0;
                //weakSelf.dataArray = [NSArray arrayWithArray:self.allArray[self.selectIndex][@"content"]];
                //[weakSelf loadNewQuestion];
            }
        }];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        self.dataArray = [NSArray arrayWithArray:self.allArray[self.selectIndex][@"content"]];
        [self loadNewQuestion];
        [self loadNextQuestion11];
    }
}
- (UIColor *)randomColor {
    CGFloat hue = (arc4random() % 256 / 256.0);
    CGFloat saturation = (arc4random() % 128 / 256.0) + 0.5;
    CGFloat brightness = (arc4random() % 128 / 256.0) + 0.5;
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

- (void)getPracticeList{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"practice_id"] = self.practice_id;
    
    [MBProgressHUD showMessage:@""];
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(Countdown_Seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
           [MBProgressHUD hideHUD];
    });
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@"/home/getPracticeList" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        [MBProgressHUD hideHUD];
        if (success) {
            self.allArray = [NSArray arrayWithArray:response.data];
            //self.allArray = [self.allArray subarrayWithRange:NSMakeRange(0,1)];//上架必备
            self.dataArray = [NSArray arrayWithArray:self.allArray[self.selectIndex][@"content"]];
            [self loadNewQuestion];
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
    
}
@end
