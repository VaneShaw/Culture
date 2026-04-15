//
//  CardElementViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/29.
//

#import "CardElementViewController.h"
#import "CardScrollView.h"
#import "VideoFullScreenViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BottomSwitchBar.h"
@interface CardElementViewController ()
@property (nonatomic, strong) CardScrollView *scrollView;
@property (strong, nonatomic) NSArray *dataArray;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIView *footerView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;
@property (assign, nonatomic) int selectIndexTemp;
@property (strong, nonatomic) UIButton *btnCurrent;
@property (strong, nonatomic) BottomSwitchBar *barSwitch;
@property (nonatomic, assign) BOOL isCategoryListLoaded;
@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *cardButtonMap;

@end

//元素-卡片页面
@implementation CardElementViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    if(self.isCategoryListLoaded){
        //[self.scrollView.currentCardView configureWithType:@"Write"];
    }
   
    //@"Listen", @"Speak", @"Write", @"Video"
}

- (void)viewWillDisappear:(BOOL)animated { //视图即将消失v
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    [MBProgressHUD hideHUD];
    
    // 停止所有音频操作
    [[AudioManager sharedManager] stopRecording];
    [[AudioManager sharedManager] stopPlayback];
    [self.scrollView.currentCardView stopProgressTimer];
    
    UIViewController *toVC = self.navigationController.topViewController;
    if ([toVC isKindOfClass:[VideoFullScreenViewController class]]) {
        //self.isVideo = YES;
        //NSLog(@"👉 即将进入全屏页面");
        //[self btnSelectExerciseTag:3];//等待处理3
    } else if (self.isMovingFromParentViewController) {
        if (self.isMovingFromParentViewController || self.isBeingDismissed) {
            // 返回上级页面时，停止播放
            [self.scrollView.currentCardView.playerViewVideo turnOffVideoPlayback];
            [[MediaPlayManager sharedManager] turnOffVideoPlayback1];
        }
    }

    [self.scrollView.currentCardView destroyPlayer];
    if(self.selectedTypeIndex){
        self.selectedTypeIndex(1);
    }
    
    if (self.studyStartTimeMs > 0) {
        [self endStudyWithCompleted:[self hasAnyCardTwoDifferentButtonsClicked]
                          eventType:EventTypeLearn
                           eventName:@"学习事件"
                         contentType:@[@"pinyin",@"hanzi"][self.isHanZi]
                           extraParams:nil];
 
    }
    [self.cardButtonMap removeAllObjects];
}
- (void)viewDidAppear:(BOOL)animated {//视图---出现
    [super viewDidAppear:animated];
    //[self reloadDataIndex];
    NSInteger tempIndex = self.scrollView.lastVisibleIndex + 0;
    if(tempIndex==0){
        //tempIndex = 1;
    }
    if(tempIndex >= 0 && tempIndex < self.scrollView.cardLetters.count){
        //[self.scrollView cardDidAppearData:tempIndex];
    }
    [self startStudy];
}
//---------------------------------------------------
- (void)onCardButtonClickedWithCardId:(NSString *)cardId
                             buttonId:(NSString *)buttonId {
    if (!cardId || !buttonId) return;

    NSMutableSet *set = self.cardButtonMap[cardId];
    if (!set) {
        set = [NSMutableSet set];
        self.cardButtonMap[cardId] = set;
    }

    [set addObject:buttonId];   // 同一个按钮点 10 次，也只算 1 个
}
- (BOOL)hasAnyCardTwoDifferentButtonsClicked {
    for (NSString *cardId in self.cardButtonMap) {
        if (self.cardButtonMap[cardId].count >= 2) {
            return YES;
        }
    }
    return NO;
}

//---------------------------------------------------
- (void)viewDidDisappear:(BOOL)animated {
    //page 当前卡片的第几个，   index 下标//听 读 写
    //NSDictionary *dic = @{@"page":[NSString stringWithFormat:@"%d",self.scrollView.currentPage],@"index":[NSString stringWithFormat:@"%d",self.scrollView.footerIndex]};
    //[[IDStorageManager sharedManager] saveValue:dic forId:self.category_id];
}


- (void)reloadDataIndex {
    //声母 声调 韵母 里  每一行 cell 的id        5-23
    NSDictionary *dic = [[IDStorageManager sharedManager] valueForId:self.category_id];
    //NSDictionary *dic = [NSDictionary dictionaryWithDictionary:[KUSER_DEFAULT objectForKey:self.category_id]];
    
        int page = [dic[@"page"] intValue];
        if(page > 0 && page < self.dataArray.count){
            self.scrollView.currentPage = page;
            self.scrollView.footerIndex = [dic[@"index"] intValue];
            //[self.exerciseView updateCardLayouts];
            CGFloat screenWidth = self.scrollView.scrollView.bounds.size.width;
            [self.scrollView.scrollView setContentOffset:CGPointMake(self.scrollView.currentPage * screenWidth, 0)];
            UIButton *btnExercise = (UIButton *)[self.footerView viewWithTag:55 + self.scrollView.footerIndex];
            [self btnExerciseActionDeX:btnExercise];
            [self btnSelectExerciseTag:self.scrollView.footerIndex];
        }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cardButtonMap = [NSMutableDictionary dictionary];
    self.pageId = @[@"learn_pinyin_detail",@"learn_hanzi_detail"][self.isHanZi];
    
    [KUSER_DEFAULT setBool:NO forKey:@"isFullScreen"];
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self addGlobalBackButtonColor:[UIColor whiteColor] headerTitleDic:@{}];
    self.view.backgroundColor = [self.view colorWithHexString:@"#F5F9FF" alpha:1];
    NSError *sessionError = nil;
    // 设置音频会话类别为播放
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.footerView];
    self.selectIndexTemp = 0;
    CGRect frame = CGRectMake(0, self.lblSubtitle.frame.origin.y + self.lblSubtitle.frame.size.height + 40, SCREEN_WIDTH, Card_Height);
    // 1. 创建数据

    NSArray *letters = @[
        @{
            @"id": @"7",
            @"symbol": @"",
            @"subtitle": @"",
            @"audio_url": @"",
            @"audio_image_url": @"",
            @"image_url": @"",
            @"learn_image_url": @"",
            @"learn_audio_url": @""
        }];
    // 2. 创建并添加自定义视图
    self.scrollView = [[CardScrollView alloc] initWithFrame:frame letters:letters];
    [self.headerView addSubview:self.scrollView];
    self.scrollView.uvc = self;
    //self.exerciseView.backgroundColor = [UIColor orangeColor];
    __weak typeof(self) weakSelf = self;
    
    self.scrollView.didSelectCardBlock33 = ^(NSInteger index) {
        //if(self.selectIndexTemp != index){
            [self.barSwitch switchToIndex:0];
            [weakSelf btnSelectExerciseTag:55-55];
            [self.scrollView.currentCardView configureWithType:@"Listen"];
       // }
        weakSelf.selectIndexTemp = (int)index;
    };
    [self getCategoryList];

    self.scrollView.currentCardView.buttonClickBlock = ^(NSString *cardId, NSString *buttonId) {
        [weakSelf onCardButtonClickedWithCardId:cardId
                                     buttonId:buttonId];
    };
}
#pragma mark - 回收
- (void)dealloc {
    [self.cardButtonMap removeAllObjects];
    if (self.scrollView.currentCardView.timeObserver) {
        [self.scrollView.currentCardView.playerVideo removeTimeObserver:self.scrollView.currentCardView.timeObserver];
        self.scrollView.currentCardView.timeObserver = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)cancelAnimations {
    // 停止所有正在进行的动画
    //[self.exerciseView.layer removeAllAnimations];
    //for (UIView *view in self.exerciseView.subviews) {
        //[view.layer removeAllAnimations];
    //}
}
- (UIView *)headerView {
    if (!_headerView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGRect rectNav = self.navigationController.navigationBar.frame;
        CGRect frame = CGRectMake(0, statusBarH + rectNav.size.height, SCREEN_WIDTH, Card_Height + 130 + 30);
        _headerView = [[UIView alloc]initWithFrame:frame];
        _headerView.backgroundColor = [UIColor clearColor];
        [_headerView addSubview:self.lblTitle];
        [_headerView addSubview:self.lblSubtitle];
    }
    return _headerView;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿M, 35 + 0, SCREEN_WIDTH - 2 * Distance＿M, 25)];
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(self.lblTitle.frame.origin.x, 12 + self.lblTitle.frame.origin.y + self.lblTitle.frame.size.height, self.lblTitle.frame.size.width, 20 + 25)];
        _lblSubtitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        _lblSubtitle.numberOfLines = 2;
    }
    return _lblSubtitle;
}
- (UIView *)footerView {
    if (!_footerView) {
        //橙色为 声调板块,以此判断是否需要隐藏功能模块
       
        _footerView = [[UIView alloc]init];
        _footerView.frame = CGRectMake(0, self.headerView.frame.origin.y + self.headerView.frame.size.height + 30 - 5, SCREEN_WIDTH , 54);
        _footerView.layer.cornerRadius = 12;//圆角
        _footerView.backgroundColor = [UIColor clearColor];
        _footerView.userInteractionEnabled = YES;
        _footerView.clipsToBounds = YES;
        
        BottomSwitchBar *bar = [[BottomSwitchBar alloc] init];
        [_footerView addSubview:bar];
        self.barSwitch = bar;
 
    }
    return _footerView;
}
- (void)updateImage {
    //[self.imageView startAnimating]; // 开始动画
}
- (void)setCurrentButtonExercise:(UIButton *)btnExercise {
    self.btnCurrent = btnExercise;
    NSString *currentKey = [ColorManager currentColorKey];
    ColorItem *blue = [ColorManager itemForKey:currentKey];
    NSArray *colorArray = blue.colors;
    if (colorArray.count == 2){
        [btnExercise setTintColor:[self.view colorWithHexString:colorArray[0] alpha:1]];
        btnExercise.backgroundColor = [self.view colorWithHexString:colorArray[1] alpha:1];
    }
}
- (void)btnExerciseActionDeX:(UIButton *)sender {

}
- (void)btnSelectExerciseTag:(int)tag {
    //int tag = (int)sender.tag - 55;
    [self.scrollView reloadCardWithLettersFooterIndex:tag];
}

- (void)getCategoryList{
    __weak typeof(self) weakSelf = self;
    __block BOOL hudHidden = NO;// 2. 创建一个 __block 标志，防止重复隐藏
    if (!self.isCategoryListLoaded) {
        // 1. 显示加载动画
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        // 2. 创建一个 __block 标志，防止重复隐藏
        // 3. 设置超时隐藏（例如 4 秒）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!hudHidden) {
                hudHidden = YES;
                __strong typeof(weakSelf) self = weakSelf;
                if (self) {
                    [MBProgressHUD hideHUDForView:self.view animated:YES]; //转圈圈隐藏
                }
            }
        });
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"category_id"] = self.category_id;
    if(self.isHanZi){
        params[@"app_region"] = @[@"domestic",@"overseas"][IS_OVERSEAS_VERSION];
    }
    params = [LanguageHelper currentLanguageParams:params];
    NSString *url = @[@"/pinyin/getElementList",@"/hanzi/getElementList"][self.isHanZi];
    [HttpTools postRequest:url parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!hudHidden) {
               hudHidden = YES;
               [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
        self.isCategoryListLoaded = YES;
        if (success) {
             NSDictionary *dicData = [NSDictionary dictionaryWithDictionary:response.data];
             NSDictionary *dicCategory = [NSDictionary dictionaryWithDictionary:dicData[@"category"]];
             NSString *title = [NSString stringWithFormat:@"%@",dicCategory[@"title"]];
             if([title isEqualToString:@"<null>"]){
                 title = @"";
             }
             CGFloat statusBarH = [PublicTool getStatusBarHeight];
             CGRect rectNav = self.navigationController.navigationBar.frame;
             self.lblTitle.text = title;
             NSString *subtitle = [NSString stringWithFormat:@"%@",dicCategory[@"subtitle"]];
             if([subtitle isEqualToString:@"<null>"]){
                 subtitle = @"";
             }
             self.lblSubtitle.text = subtitle;
             [self.lblSubtitle sizeToFit];
             
             CGSize labelSize = [self.lblSubtitle sizeThatFits:CGSizeMake(SCREEN_WIDTH - 2 * Distance＿M,MAXFLOAT)];
             self.scrollView.frame = CGRectMake(0, self.lblSubtitle.frame.origin.y + labelSize.height + 40, SCREEN_WIDTH, Card_Height);
             self.headerView.frame = CGRectMake(0,statusBarH + rectNav.size.height,  SCREEN_WIDTH,self.scrollView.frame.origin.y + Card_Height + 5);
             [self.lblSubtitle sizeToFit];
             
             CGRect newFrame = self.footerView.frame;
             newFrame.origin.y = self.headerView.frame.origin.y + self.headerView.frame.size.height + 25;
             self.footerView.frame = newFrame;
             
             if([dicData[@"elements"] isKindOfClass:[NSArray class]]) {
                 self.dataArray = [NSArray arrayWithArray:dicData[@"elements"]];
                 //NSLog(@"--------------data------[%@]--------------cccxa",self.dataArray[0]);
                 NSString *video_url;
                 if(self.dataArray.count > 0){
                     video_url = [NSString stringWithFormat:@"%@",self.dataArray[0][@"video_url"]];
                 }
                 
                 NSString *key = nil;
                 if ([ColorManager isOrange]) {
                     key = video_url.length > 6 ? @"orange_video" : @"orange";
                 } else {
                     key = video_url.length > 6 ? @"blue_video" : @"blue";
                 }
                 NSDictionary *map = @{
                     @"orange" : @[@"Listen", @"Speak"],
                     @"orange_video": @[@"Listen", @"Speak", @"Video"],
                     @"blue"   : @[@"Listen", @"Speak", @"Write"],
                     @"blue_video": @[@"Listen", @"Speak", @"Write", @"Video"]
                 };
                 //NSString *key = [ColorManager isOrange] ? @"orange" :
                                 //(video_url.length > 6 ? @"blue" : @"default");
                 NSArray *titleArray = map[key];
                 
                 __weak typeof(self) weakBar = self;
                 [self.barSwitch configureWithY:0
                               titles:titleArray
                               action:^(NSInteger index) {
                     __strong typeof(weakBar) self = weakBar;
                     if (!self) return;
                     NSLog(@"点击了第 %ld 个按钮", (long)index);
                     
                     [self btnSelectExerciseTag:(int)index];
                     [self.scrollView.currentCardView configureWithType:titleArray[index]];
                     //[KUSER_DEFAULT setObject:titleArray[index] forKey:Card_Type];
                     [self.scrollView.currentCardView.playerVideo pause];
                 }];
                 
                 NSString *strSymbol = [NSString stringWithFormat:@"%@",dicCategory[@"character"]];
                 if([strSymbol isEqualToString:@"(null)"]){
                     strSymbol = @"";
                 }
                 [self.scrollView reloadWithLetters:self.dataArray strSymbol:strSymbol];
                 [self reloadDataIndex];
             
             }
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}

@end
