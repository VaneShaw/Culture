//
//  QuizToneViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/6.
//

#import "QuizToneViewController.h"
#import "GradientProgressView.h"
#import "AudioPlayerManager.h"
#import "AnswerBackView.h"
#import "QuizViewController.h"
#import "QuizResultViewController.h"
#import "PronunciationFirstView.h"
#import "GuideManager.h"
#define Quiz_COLOR [UIColor clearColor]
#define Quiz_white_COLOR [UIColor whiteColor]

#define Tag_Question 20
#define Tag_Answer 100
static NSString *const kFirstPageKey = @"SecondPage";
@interface QuizToneViewController ()<UINavigationControllerDelegate,UIGestureRecognizerDelegate>
@property (strong, nonatomic) GradientProgressView *progressView;
@property (strong, nonatomic) UILabel *lblRate;

@property (nonatomic, strong) NSMutableArray *buttonsQuestion;
@property (nonatomic, strong) NSMutableArray *buttonsAnswer;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@property (nonatomic, strong) NSMutableArray<NSValue *> *targetPositions;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, strong) UIButton *selectedQuestionButton;
@property (nonatomic, strong) UIButton *selectedAnswerButton;
@property (nonatomic, assign) BOOL isFloatingPhase;
@property (nonatomic, assign) NSInteger errorCount;
@property (nonatomic, strong) NSMutableDictionary *correctPairs;
@property (nonatomic, assign) CGSize screenSize;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *footerView;

@property (nonatomic, assign) int diameterRound;
@property (nonatomic, assign) int selectIndex;
@property (nonatomic, assign) int questions; //做题数
@property (nonatomic, strong) NSArray *allArray;
@property (nonatomic, strong) NSArray *dataArray;
//@property (nonatomic, assign) BOOL isSingle;
@property (nonatomic, strong) UIImageView *imgAnswer;
@property (nonatomic, assign) int score;
@property (nonatomic, assign) BOOL isAnimating; // 动画进行中锁定
@property (nonatomic, assign) BOOL isProcessingPair; // 配对处理中锁定
@property (nonatomic, strong) NSString *audioUrl;
@property (nonatomic, assign) BOOL isCurrent;

@end

@implementation QuizToneViewController

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
                         contentType:@"tone"
                           extraParams:extra];
    }
    self.questions = 0;
}
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    // 获取记忆的下标
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
                [self proceedToNextQuestionAfterDelay:1.5];
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
        // 存储当前下标
        [self saveUserIndexAndScore:self.selectIndex];
    }
}
- (void)saveUserIndexAndScore:(int)index {
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
    //[self.navigationController popViewControllerAnimated:YES];
    //@"\n"
    NSArray *titleArray1 = @[@"Quit now?",@"Your progress won’t be saved.You’re almost done — don’t give up now!",@"Exit Anyway",@"Keep Going"];
    [ReadyLogOutView showViewTitle:@"" buttonArrayTitle:titleArray1 callBack:^(NSInteger index) {
    //[AnswerBackView showViewTitle:isQuit buttonArrayTitle:@[] callBack:^(NSInteger index) {
        if(index == 1000){//返回。  //1001继续当前
            self.selectIndex = 0;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"quiz_shengdiao";
    self.view.backgroundColor = [self.view colorWithHexString:@"#63A8F5" alpha:1];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    
    self.diameterRound = 88;
    self.selectIndex = 0;
    self.questions = 0;
    self.score = 0;
    
    int headerHeight = 550;
    self.headerView = [[UIView alloc]initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - headerHeight)/2, SCREEN_WIDTH, headerHeight)];
    self.headerView.clipsToBounds = YES;
    [self.view addSubview:self.headerView];
    self.headerView.backgroundColor = [UIColor clearColor];
    
    headerHeight = 550;
    self.footerView = [[UIView alloc]initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - headerHeight)/2, SCREEN_WIDTH, headerHeight )];
    self.footerView.clipsToBounds = YES;
    [self.view addSubview:self.footerView];
    self.footerView.backgroundColor = self.view.backgroundColor;
    self.footerView.hidden = YES;
    
    UIImageView *imgAnswer = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH-145)/2, (self.footerView.frame.size.height - 145)/2 - 20, 145, 145)];
    //imgAnswer.image = [UIImage imageNamed:@"answer_red"];//answer_greend
    [self.footerView addSubview:imgAnswer];
    self.imgAnswer = imgAnswer;
    
    //---------------------------------------------------------------------
    int width = 38;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    btn.frame = CGRectMake(20 , statusBarH + 30, width, width);
    btn.layer.cornerRadius = width/2;//圆角
    btn.layer.masksToBounds = YES;
    btn.backgroundColor = [self.view colorWithHexString:@"#DEDEDE" alpha:0.5];
    [btn setImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    // 进度条
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
    //-----------------------------------------------------------------
    
    //_screenSize = self.view.bounds.size;
    //_screenSize =  CGSizeMake(SCREEN_WIDTH, headerHeight-100);
    //_screenSize =  CGSizeMake(SCREEN_WIDTH, 500);
    _screenSize =  CGSizeMake(390, 450);
    // 初始浮动阶段
    _isFloatingPhase = YES;
    _startTime = CACurrentMediaTime();
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateButtonPositions)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // 5秒后停止浮动
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isFloatingPhase = NO;
        [self settleButtonsToTargetPositions];
    });
    [self getPracticeList];
    
    if ([[GuideManager shared] shouldShowGuideForPage:kFirstPageKey]) {
        //显示引导图
        // 创建半透明覆盖层
        UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
        overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.01]; // 几乎透明
        overlay.tag = 919; // 设置tag以便之后移除
        [self.view addSubview:overlay];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            overlay.hidden = YES;
            UIButton *button = (UIButton *)[self.headerView viewWithTag:Tag_Question + 0];
            if(self.isCurrent)return;
            //等待处理
            [PronunciationFirstView showViewTitle:@"1" buttonFrame:button.frame callBack:^(NSInteger index) {
                if(index == 101){
                    overlay.hidden = NO;
                    [self buttonTapped:button];
                    //---------------------------------------------------------
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[self.view viewWithTag:919] removeFromSuperview];
                        UIButton *button2 = (UIButton *)[self.headerView viewWithTag:Tag_Answer + 0];
                        NSString *title = button2.titleLabel.text;
                        if(self.isCurrent)return;
                        [[GuideManager shared] markGuideShownForPage:kFirstPageKey];
                        [PronunciationFirstView showViewTitle:title buttonFrame:button2.frame callBack:^(NSInteger index) {
                            if(index == 101){
                                [self buttonTapped:button2];
                            }
                        }];
                    });
                    //---------------------------------------------------------
                }
            }];
            
        });
    }
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}
// 生成一个指定范围内的随机数，例如0到99
//int randomNumber = rand() % 100;
- (void)updateButtonPositions {
    if (!self.isFloatingPhase) return;
    //int headerHeight = 550;
    //self.diameterRound = 88;
    CFTimeInterval elapsed = CACurrentMediaTime() - _startTime;
    for (int i = 0; i < self.buttons.count; i++) {
        UIButton *button = self.buttons[i];
        CGPoint target = [self.targetPositions[i] CGPointValue];
        // 添加基于时间的偏移量创建浮动效果
        CGFloat offsetX = sin(elapsed * 0.8 + i) * 8.0; // 减小浮动幅度
        CGFloat offsetY = cos(elapsed * 0.7 + i * 1.2) * 8.0;
        button.center = CGPointMake(target.x + offsetX, target.y + offsetY);
    }
}
- (void)calculateNonOverlappingPositions {
    // 清除旧位置
    [_targetPositions removeAllObjects];
    
    // 设置固定屏幕尺寸
    _screenSize = CGSizeMake(390, 450);
    CGFloat midX = _screenSize.width / 2;
    CGFloat marginY = 30;
    CGFloat marginX = 80; // 左边距至少80
    CGFloat diameter = self.diameterRound; // 假设直径为88
    CGFloat minDistance = diameter + 2; // 最小间距
    
    // 创建位置数组
    NSMutableArray *positions = [NSMutableArray array];
    // 最大尝试次数
    const int maxAttemptsPerButton = 150;
    const int maxTotalAttempts = maxAttemptsPerButton * _buttons.count;
    int totalAttempts = 0;
    
    for (int i = 0; i < _buttons.count; i++) {
        UIButton *button = _buttons[i];
        CGPoint newPosition;
        BOOL positionValid;
        int attempts = 0;
        
        // 定义安全区域
        CGRect safeArea;
        if (button.tag < 100) { // 问题圈放在左半区
            safeArea = CGRectMake(marginX, marginY + 30,
                                midX - marginX, _screenSize.height - 2 * marginY);
        } else { // 答案圈放在右半区
            safeArea = CGRectMake(midX, marginY + 30,
                                midX - marginX, _screenSize.height - 2 * marginY);
        }
        
        do {
            positionValid = YES;
            attempts++;
            totalAttempts++;
            
            // 安全退出机制
            if (totalAttempts > maxTotalAttempts) {
                NSLog(@"警告：无法为所有按钮找到合适位置，将强制放置可能有重叠");
                // 强制放置当前按钮
                newPosition = [self findBestAvailablePositionForButton:button
                                                      inArea:safeArea
                                                  withPositions:positions
                                                  minDistance:diameter];
                positionValid = YES; // 强制通过
                break;
            }
            
            // 在安全区域内随机生成位置
            newPosition = CGPointMake(
                safeArea.origin.x + arc4random_uniform(safeArea.size.width),
                safeArea.origin.y + arc4random_uniform(safeArea.size.height)
            );
            
            // 确保不超出边界
            newPosition.x = MAX(safeArea.origin.x + diameter/2,
                               MIN(safeArea.origin.x + safeArea.size.width - diameter/2, newPosition.x));
            newPosition.y = MAX(safeArea.origin.y + diameter/2,
                               MIN(safeArea.origin.y + safeArea.size.height - diameter/2, newPosition.y));
            
            // 检查是否与其他位置重叠
            for (NSValue *positionValue in positions) {
                CGPoint existingPosition = [positionValue CGPointValue];
                CGFloat distance = sqrt(pow(newPosition.x - existingPosition.x, 2) +
                                 pow(newPosition.y - existingPosition.y, 2));
                
                if (distance < minDistance) {
                    positionValid = NO;
                    break;
                }
            }
            
            // 每50次尝试后稍微扩大搜索区域
            if (attempts % 50 == 0) {
                safeArea = CGRectInset(safeArea, -5, -5);
            }
        } while (!positionValid);
        [positions addObject:[NSValue valueWithCGPoint:newPosition]];
        [_targetPositions addObject:[NSValue valueWithCGPoint:newPosition]];
        button.center = newPosition;
    }
}
// 辅助方法：当无法找到理想位置时，寻找最佳可用位置
- (CGPoint)findBestAvailablePositionForButton:(UIButton *)button
                                      inArea:(CGRect)area
                                withPositions:(NSArray *)existingPositions
                                 minDistance:(CGFloat)minDist {
    
    CGFloat bestDistance = 0;
    CGPoint bestPosition = CGPointMake(area.origin.x + area.size.width/2,
                                      area.origin.y + area.size.height/2);
    // 尝试网格点而非完全随机
    const int gridSteps = 5;
    CGFloat xStep = area.size.width / gridSteps;
    CGFloat yStep = area.size.height / gridSteps;
    
    for (int x = 0; x <= gridSteps; x++) {
        for (int y = 0; y <= gridSteps; y++) {
            CGPoint testPoint = CGPointMake(area.origin.x + x * xStep,
                                          area.origin.y + y * yStep);
            // 计算最小距离
            CGFloat currentMinDist = CGFLOAT_MAX;
            for (NSValue *posValue in existingPositions) {
                CGPoint existingPos = [posValue CGPointValue];
                CGFloat dist = sqrt(pow(testPoint.x - existingPos.x, 2) +
                                   pow(testPoint.y - existingPos.y, 2));
                currentMinDist = MIN(currentMinDist, dist);
            }
            
            // 更新最佳位置
            if (currentMinDist > bestDistance) {
                bestDistance = currentMinDist;
                bestPosition = testPoint;
            }
        }
    }
    
    return bestPosition;
}
//原始位置     //可能有问题的区域

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)createButtons {
    // 初始化
    _buttons = [NSMutableArray array];
    _targetPositions = [NSMutableArray array];
    _errorCount = 0;
    _correctPairs = [NSMutableDictionary dictionary];
    self.buttonsAnswer = [NSMutableArray new];
    self.buttonsQuestion = [NSMutableArray new];

    int count = (int)self.allArray.count;
    float rate = (float)self.selectIndex/count;
    [self.progressView setColorProgress:rate color:@"#FFFFFF" alpha:1 animated:YES];
    self.lblRate.text = [NSString stringWithFormat:@"%d/%d",self.selectIndex,count];
    //NSLog(@"页面开始启动---------cc--2");
    //创建4个问题圈（喇叭图标）
    int temp = 0;
    for (int i = 0; i < self.dataArray.count; i++) {
        UIButton *button = [self createButtonWithType:0 index:i];
        [self.buttonsQuestion addObject:[NSString stringWithFormat:@"%d",i+Tag_Question]];
        [self.headerView addSubview:button];
        [_buttons addObject:button];
        temp++;
    }

    //self.isSingle = temp == 1? YES:NO;
    //self.diameterRound = 88 + 12 * self.isSingle;
    
    // 创建4个答案圈（拼音）
    for (int i = 0; i < self.dataArray.count; i++) {
        UIButton *button = [self createButtonWithType:1 index:i];
        [button setTitle:self.dataArray[i][@"character"] forState:UIControlStateNormal];
        [self.headerView addSubview:button];
        [_buttons addObject:button];
        [self.buttonsAnswer addObject:[NSString stringWithFormat:@"%d",i+Tag_Answer]];
        // 存储正确配对关系（问题圈i对应答案圈i）
        [_correctPairs setObject:@(i + Tag_Question) forKey:@(i + Tag_Answer)];
    }
    [self calculateNonOverlappingPositions];
}
- (void)setupMultiPulseAnimationForView:(UIView *)view {
    // 确保视图是圆形
    view.layer.cornerRadius = 44;
    view.backgroundColor = [UIColor clearColor];
    UIColor *blueColor = [self.view colorWithHexString:@"#1181FF" alpha:1];

    // 创建3个扩散圈层
    for (int i = 0; i < 3; i++) {
        CALayer *pulseLayer = [CALayer layer];
        pulseLayer.bounds = CGRectMake(0, 0, 88, 88);
        pulseLayer.position = CGPointMake(view.bounds.size.width/2, view.bounds.size.height/2);
        pulseLayer.cornerRadius = 44;
        pulseLayer.borderWidth = 2;
        pulseLayer.borderColor = blueColor.CGColor;
        pulseLayer.opacity = 0;
        [view.layer addSublayer:pulseLayer];
        
        // 每个圈层的动画延迟
        CGFloat delay = i * 0.5;
        // 缩放动画
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = @1.0;
        scaleAnimation.toValue = @(140.0/88.0);
        // 透明度动画
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = @0.8;
        opacityAnimation.toValue = @0.0;
        // 组合动画
        CAAnimationGroup *groupAnimation = [CAAnimationGroup animation];
        groupAnimation.animations = @[scaleAnimation, opacityAnimation];
        groupAnimation.duration = 2.0;
        groupAnimation.beginTime = CACurrentMediaTime() + delay;
        groupAnimation.repeatCount = INFINITY;
        groupAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [pulseLayer addAnimation:groupAnimation forKey:@"pulseAnimation"];
    }
}
// 移除动画（如果需要）
- (void)removeBorderPulseAnimationFromButton:(UIButton *)button {
    [button.layer removeAnimationForKey:@"borderPulseAnimation"];
}
- (UIButton *)createButtonWithType:(int)type index:(int)index {
    UIButton *button;
  
    if(type == 0){
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"audio_white"] forState:UIControlStateNormal];
    } else {
        button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.tintColor = [UIColor whiteColor];
        button.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:36];
    }
    //...1 颜色
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.frame = CGRectMake(0, 0, self.diameterRound, self.diameterRound);
    button.layer.cornerRadius = self.diameterRound/2;
    button.layer.borderWidth = 2;
 
    button.backgroundColor = Quiz_COLOR;
    button.tag = type == 0 ? index + Tag_Question : index + Tag_Answer; // 问题圈: 0-3, 答案圈: 10-13
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}
//e a  o   u
- (void)settleButtonsToTargetPositions {
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        for (int i = 0; i < self.buttons.count; i++) {
            self.buttons[i].center = [self.targetPositions[i] CGPointValue];
        }
    } completion:nil];
}
- (void)buttonTapped:(UIButton *)sender {
    if (self.isAnimating || self.isProcessingPair) {
            return;
    }
    if (sender.tag < Tag_Answer) { // 问题圈（喇叭图标）
        [self handleQuestionButtonTap:sender];
    } else { // 答案圈（拼音）
        [self handleAnswerButtonTap:sender];
    }
    // 检查是否配对
    if (self.selectedQuestionButton && self.selectedAnswerButton) {
        [self checkPairMatch];
    }
}
- (void)setQuestionSelectButton:(UIButton *)button {
    button.backgroundColor = Quiz_white_COLOR;
    [button setImage:[UIImage imageNamed:@"audio_blue"] forState:UIControlStateNormal];
}
- (void)setQuestionNotButton:(UIButton *)button {
    button.backgroundColor = Quiz_COLOR;
    [button setImage:[UIImage imageNamed:@"audio_white"]forState:UIControlStateNormal];
}
- (void)handleQuestionButtonTap:(UIButton *)button {
    
    if (button == self.selectedQuestionButton) {
            // 取消选中 - 恢复大小
            [self restoreButtonSize:button];
            [self setQuestionNotButton:button];
            self.selectedQuestionButton = nil;
    } else {
            // 取消之前选中的问题按钮
        if (self.selectedQuestionButton) {
            [self restoreButtonSize:self.selectedQuestionButton];
            [self setQuestionNotButton:self.selectedQuestionButton];
        }
            // 选中当前按钮 - 轻微放大
            [self selectButton:button withColor:[UIColor whiteColor]];
            [self setQuestionSelectButton:button];
            int tag = (int)button.tag-Tag_Question;
            if(tag<self.dataArray.count){
                self.audioUrl = [NSString stringWithFormat:@"%@",self.dataArray[tag][@"audio"]];
                [self playAudio:self.audioUrl];
            }
        
        self.selectedQuestionButton = button;
        // 分离重叠按钮
        [self separateOverlappingButtonsFrom:button];
    }
}
- (void)setAnswerSelectButton:(UIButton *)button {
    button.backgroundColor = Quiz_white_COLOR;
    UIColor *selectColor = self.view.backgroundColor;
    [button setTintColor:selectColor];
    button.layer.borderWidth = 5;
}
- (void)setAnswerNotButton:(UIButton *)button {
    button.backgroundColor = Quiz_COLOR;
    button.tintColor = Quiz_white_COLOR;
    button.layer.borderWidth = 2;
}

//点击答案
- (void)handleAnswerButtonTap:(UIButton *)button {
    if (button == self.selectedAnswerButton) {
        //取消选中 - 恢复大小
        [self restoreButtonSize:button];
        [self setAnswerNotButton:button];
        self.selectedAnswerButton = nil;
    } else {
        // 取消之前选中的答案按钮
        if (self.selectedAnswerButton) {
            [self restoreButtonSize:self.selectedAnswerButton];
            [self setAnswerNotButton:self.selectedAnswerButton];
        }

        // 选中当前按钮 - 轻微放大
        [self setAnswerSelectButton:button];
        [self selectButton:button withColor:Quiz_white_COLOR];
        self.selectedAnswerButton = button;
        // 分离重叠按钮
        [self separateOverlappingButtonsFrom:button];
    }
}
- (void)selectButton:(UIButton *)button withColor:(UIColor *)color {
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
- (void)separateOverlappingButtonsFrom:(UIButton *)selectedButton {
    
    for (UIButton *button in self.buttons) {
        if (button == selectedButton || button.hidden) continue;
        // 计算两按钮中心距离
        CGFloat distance = sqrt(pow(button.center.x - selectedButton.center.x, 2) +
                               pow(button.center.y - selectedButton.center.y, 2));
        // 检查是否重叠（直径88，所以距离<88即重叠）
        if (distance < self.diameterRound) {
            // 计算分离方向向量
            CGPoint direction = CGPointMake(button.center.x - selectedButton.center.x,
                                           button.center.y - selectedButton.center.y);
            CGFloat length = MAX(distance, 0.1);
            
            // 标准化并放大
            direction.x /= length;
            direction.y /= length;
            
            // 计算需要移动的距离（刚好不重叠）
            CGFloat moveDistance = self.diameterRound - distance;
            CGPoint newCenter = CGPointMake(button.center.x + direction.x * moveDistance,
                                           button.center.y + direction.y * moveDistance);

            if(button.tag < 100){
                //确保新位置在屏幕内
                newCenter.x = MAX(self.diameterRound/2, MIN(_screenSize.width - self.diameterRound/2, newCenter.x));
                newCenter.y = MAX(self.diameterRound/2, MIN(_screenSize.height - self.diameterRound/2, newCenter.y));
            } else {
                //确保新位置在屏幕内
                newCenter.x = MAX(self.diameterRound/2, MIN(_screenSize.width - self.diameterRound/2, newCenter.x));
                newCenter.y = MAX(self.diameterRound/2, MIN(_screenSize.height - self.diameterRound/2, newCenter.y));
            }
            
            // 更新目标位置
            NSInteger index = [self.buttons indexOfObject:button];
            if (index != NSNotFound) {
                self.targetPositions[index] = [NSValue valueWithCGPoint:newCenter];
            }
            // 应用动画
            [UIView animateWithDuration:0.4
                                  delay:0
                 usingSpringWithDamping:0.6
                  initialSpringVelocity:0.7
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                button.center = newCenter;
            } completion:nil];
        }
    }
}

//点击答案
- (void)checkPairMatch {
    if (!self.selectedQuestionButton || !self.selectedAnswerButton) return;
    
    // 设置处理中锁定
     self.isProcessingPair = YES;
     self.isAnimating = YES;
    
    NSInteger questionTag = self.selectedQuestionButton.tag;
    NSInteger answerTag = self.selectedAnswerButton.tag;
    
    /* 检查是否匹配（考虑错误计数偏移）
    NSInteger expectedQuestionTag = [self.correctPairs[@(answerTag)] integerValue];
    BOOL isMatch = questionTag == expectedQuestionTag;
    
    // 错误计数逻辑：每次错误后偏移配对关系
    if (_errorCount > 0) {
        isMatch = questionTag == (expectedQuestionTag + _errorCount) % 4;
    }*/
    
    BOOL isMatch = (questionTag-Tag_Question == (answerTag-Tag_Answer))? YES:NO;
    if (isMatch) {
        // 匹配成功 - 移除配对
        [UIView animateWithDuration:0.35 animations:^{
            self.selectedQuestionButton.alpha = 0;
            self.selectedQuestionButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
            self.selectedAnswerButton.alpha = 0;
            self.selectedAnswerButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished) {
            //[self playAudio:self.audioUrl];
            
            // 从界面和数组中移除
            [self.selectedQuestionButton removeFromSuperview];
            [self.selectedAnswerButton removeFromSuperview];
            [self.buttons removeObject:self.selectedQuestionButton];
            [self.buttons removeObject:self.selectedAnswerButton];
            
            // 更新目标位置数组
            NSInteger questionIndex = [self.buttons indexOfObject:self.selectedQuestionButton];
            NSInteger answerIndex = [self.buttons indexOfObject:self.selectedAnswerButton];
            if (questionIndex != NSNotFound) [self.targetPositions removeObjectAtIndex:questionIndex];
            if (answerIndex != NSNotFound) [self.targetPositions removeObjectAtIndex:answerIndex];
            
            self.selectedQuestionButton = nil;
            self.selectedAnswerButton = nil;
            self.isProcessingPair = NO;
            self.isAnimating = NO;
            // 重置错误计数
            //self.errorCount = 0;
            if(self.buttons.count == 0){
                self.score++;
                //[MBProgressHUD showLabel:@"多题  答对了进入下一题"];
                self.selectIndex++;
                self.questions++;
                //[self reloadButtonsView];
                [self proceedToNextQuestionAfterDelay:1.2];
                [self addAnsweResult:YES];
            }
        }];
        
        //}
    } else {
        // 错误计数+1
        _errorCount++;
        NSLog(@"error-------count----[%d]--------",_errorCount);
        if(_errorCount == 1){
            //弹出 打叉
            //[MBProgressHUD showLabel:@"答错一次"];
        } else if(_errorCount == 2){
            self.selectIndex++;
            self.questions++;
            [self addAnsweResult:NO];
            //[MBProgressHUD showLabel:@"答错 两次 了"];
            //[self reloadButtonsView];
            [self proceedToNextQuestionAfterDelay:1.2];
        }
         //匹配失败 - 抖动效果
        [self shakeButton:self.selectedQuestionButton];
        [self shakeButton:self.selectedAnswerButton];
        
        // 重置选中状态
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self restoreButtonSize:self.selectedQuestionButton];
            [self restoreButtonSize:self.selectedAnswerButton];
     
            [self setQuestionNotButton:self.selectedQuestionButton];
            [self setAnswerNotButton:self.selectedAnswerButton];
            
            self.selectedQuestionButton = nil;
            self.selectedAnswerButton = nil;
        });
        self.isProcessingPair = NO;
        self.isAnimating = NO;
    }
}

- (void)addAnsweResult:(BOOL)isCorrect {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.footerView.hidden = NO;
        self.imgAnswer.image = [UIImage imageNamed:@[@"answer_red",@"answer_greend"][isCorrect]];//
        [self.imgAnswer addElasticAnimationWithDuration:0.5];
 
        int count = (int)self.allArray.count;
        float rate = (float)self.selectIndex/count;
        [self.progressView setColorProgress:rate color:@"#FFFFFF" alpha:1 animated:YES];
        self.lblRate.text = [NSString stringWithFormat:@"%d/%d",self.selectIndex,count];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.footerView.hidden = YES;
    });
}
- (void)proceedToNextQuestionAfterDelay:(NSTimeInterval)delay {
    [self clearAllButtons];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reloadButtonsView];
        });
}
- (void)reloadButtonsView{
    //
    if(self.selectIndex >= self.allArray.count){
        QuizResultViewController *vc = [QuizResultViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        vc.score = self.score;
        self.selectIndex = 0;
        __weak typeof(self) weakSelf = self;
        [vc setSelectedTypeIndex:^(NSInteger index) {
            if (index == 1) {
                //weakSelf.selectIndex = 0;
                //[weakSelf reloadButtonsView];
            }
        }];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        self.dataArray = [NSArray arrayWithArray:self.allArray[self.selectIndex][@"content"]];
        // 停止之前的动画
        if (_displayLink) {
            [_displayLink invalidate];
            _displayLink = nil;
        }

        [self createButtons];
        // 开始浮动动画
        _isFloatingPhase = YES;
        _startTime = CACurrentMediaTime();
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateButtonPositions)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        // 5秒后停止浮动
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.isFloatingPhase = NO;
            [self settleButtonsToTargetPositions];
        });
    }
}
- (void)clearAllButtons {
    // 创建消失动画
    [UIView animateWithDuration:0.8 animations:^{
        for (UIButton *button in self.buttons) {
            button.alpha = 0;
            button.transform = CGAffineTransformMakeScale(0.1, 0.1);
        }
    } completion:^(BOOL finished) {
        // 移除所有按钮
        for (UIButton *button in self.buttons) {
            [button removeFromSuperview];
        }
        // 重置所有状态
        [self.buttons removeAllObjects];
        [self.targetPositions removeAllObjects];
        self.selectedQuestionButton = nil;
        self.selectedAnswerButton = nil;
        //self.errorCount = 0;
        //self.consecutiveErrorCount = 0;
        // 停止浮动动画
        [self.displayLink invalidate];
        self.displayLink = nil;
    }];
}
- (void)shakeButton:(UIButton *)button {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.duration = 0.6;
    animation.values = @[
        [NSValue valueWithCGPoint:CGPointMake(button.center.x - 10, button.center.y)],
        [NSValue valueWithCGPoint:CGPointMake(button.center.x + 10, button.center.y)],
        [NSValue valueWithCGPoint:CGPointMake(button.center.x - 8, button.center.y)],
        [NSValue valueWithCGPoint:CGPointMake(button.center.x + 8, button.center.y)],
        [NSValue valueWithCGPoint:CGPointMake(button.center.x - 5, button.center.y)],
        [NSValue valueWithCGPoint:CGPointMake(button.center.x + 5, button.center.y)],
        [NSValue valueWithCGPoint:button.center]
    ];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [button.layer addAnimation:animation forKey:@"shake"];
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
        NSLog(@"更新ui显示播放成功。。。。。");
    });
}
- (void)handlePlaybackError:(NSError *)error {
    // 处理错误并更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.cell finishRecording];
        NSLog(@"音频初始化错误----------xxxx");
    });
}
- (void)getPracticeList {
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
            //self.allArray = [self.allArray subarrayWithRange:NSMakeRange(0,3)];
            self.dataArray = [NSArray arrayWithArray:self.allArray[self.selectIndex][@"content"]];
            [self createButtons];
            //self.isCurrent = [KUSER_DEFAULT boolForKey:[NSString stringWithFormat:@"%@_str",QUIZ_KEY]];
        } else {
            [MBProgressHUD showLabel:response.msg];
        }

    } failure:^(NSError * _Nonnull error) {
    }];
}
@end
