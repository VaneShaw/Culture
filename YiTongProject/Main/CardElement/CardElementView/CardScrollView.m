//
//  CardScrollView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/29.
//

#import "CardScrollView.h"
#import "SpeakResultsView.h"
#import "HandwritingView.h"
#import "VideoFullScreenViewController.h"
@interface CardScrollView() <UIScrollViewDelegate,CardViewDelegate>
@property (nonatomic, strong) NSArray<UIView *> *cardViews;

@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, strong) NSString *strSymbol;

@end
@implementation CardScrollView
- (instancetype)initWithFrame:(CGRect)frame letters:(NSArray<NSString *> *)letters {
    self = [super initWithFrame:frame];
    if (self) {
        self.lastVisibleIndex = -1;
        self.footerIndex = 0;
        //_cardLetters = letters;
        //_pageCount = letters.count;
        self.currentPage = 0;
        self.clipsToBounds = YES;
        [self setupView];
    }
    return self;
}
- (void)setupView {
    // 1. 创建ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, Card_Height)];
    self.scrollView.contentSize = CGSizeMake(self.bounds.size.width * self.pageCount, Card_Height);
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.clipsToBounds = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    [self addSubview:self.scrollView];
    
    //self.scrollView.panGestureRecognizer.delegate = self;
    // 2. 创建卡片视图
    //[self setupCardViews];
    // 3. 设置初始布局
    //[self updateCardLayouts];
    int width = 40;
    for (int i = 0; i < 2; i++) {
        UIButton *leftView = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        leftView.frame = CGRectMake((SCREEN_WIDTH - width) * i, 0, width, Card_Height);
        leftView.backgroundColor = [UIColor clearColor];
        leftView.tag = 35 + i;
        [leftView addTarget:self action:@selector(btnLeftViewAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:leftView];
    }
}


- (void)reloadWithLetters:(NSArray *)letters strSymbol:(NSString *)strSymbol {
    
//- (void)reloadWithLetters:(NSArray *)letters {
    // 移除旧卡片
    for (UIView *card in self.cardViews) {
        [card removeFromSuperview];
    }
    // 更新数据
    self.cardLetters = letters;
    self.pageCount = letters.count;
    self.strSymbol = strSymbol;
    // 更新滚动视图大小
    self.scrollView.contentSize = CGSizeMake(self.bounds.size.width * self.pageCount, Card_Height);
    // 创建新卡片
    [self setupCardViews];
    [self updateCardLayouts];
    // 重置滚动位置
    [self.scrollView setContentOffset:CGPointZero];
  
}
//点击切换下标
- (void)reloadCardWithLettersFooterIndex:(int)footerIndex {//点击切换下标//关键位置
    //togglePlayPause

    self.footerIndex = footerIndex;
    int temp = (int)self.cardLetters.count-1;
    for (int i = 0; i < self.pageCount; i++) {
        CardView *card = (CardView *)self.cardViews[i];
        if(i>temp) return;
        NSDictionary *dic = self.cardLetters[i];
       [self setCardTypeCell:dic View:card];
        if(IS_Formal_Hanzi){
            [card setHanziCardCell:dic];
        } else {
            [card setCardCell:dic];//下标切换  //zuo 滑动
        }
        //[card configureWithType:@"Listen"];

//        NSString *card_type = [KUSER_DEFAULT objectForKey:Card_Type];
//        if([card_type isEqualToString:@"Video"]){
//            [card configureWithType:@"Video"];
//        } else {
//            [card configureWithType:@"Listen"];
//        }

    }
    if(footerIndex == 3){// 有问题需要处理
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          //[self.currentCardView quitTogglePlayPause];
            [self.currentCardView.playerViewVideo stopVideo];
          });
    } else {
        [self.currentCardView.playerViewVideo stopVideo];
    }
}

- (void)updateImageConstraints:(UIImageView *)imgView image:(UIImage *)image card:(CardView *)card {
    imgView.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat imgWidth = Card_WIDTH - 30;
    CGFloat y1 = Card_Height * 0.31;
    CGFloat aspectRatio = image.size.width / image.size.height;
    CGFloat maxHeight = Card_Height * 0.38 - 20;
    
    CGFloat calculatedHeight = (imgWidth * image.size.height) / image.size.width;
    CGFloat finalHeight = MIN(calculatedHeight, maxHeight);
    CGFloat finalWidth = finalHeight * aspectRatio;
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    
    [NSLayoutConstraint activateConstraints:@[
        [imgView.widthAnchor constraintEqualToConstant:finalWidth],
        [imgView.heightAnchor constraintEqualToConstant:finalHeight],
        [imgView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [imgView.topAnchor constraintEqualToAnchor:card.topAnchor constant:y1]
    ]];
}

- (void)setCardTypeCell:(NSDictionary *)dic View:(CardView *)card {

    if(dic){
        if([ColorManager isOrange]){
            if(IS_OVERSEAS_VERSION){
                card.listenViewTemp.lblTone.text = [NSString stringWithFormat:@"Tone%d",(int)card.tag + 1];
             } else {
                 int index = (int)card.tag;
                 card.listenViewTemp.lblTone.text = @[@"一声平调",@"二声扬调",@"三声拐弯",@"四声降调",@"",@"",@"",@""][index%4];
             }
             card.readTemp.lblTone.text = card.listenViewTemp.lblTone.text;
             card.symbolNumber = [NSString stringWithFormat:@"%@%d",self.strSymbol,(int)card.tag + 1];
        }
        if(IS_Formal_Hanzi){
            NSString *symbol =  [NSString stringWithFormat:@"%@",dic[@"hanzi"]];
            if([symbol isEqualToString:@"<null>"]){
                symbol = @"";
            }
       
            NSString *pinyin = [NSString stringWithFormat:@"%@",dic[@"pinyin"]];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:pinyin];
            [attr addAttribute:NSBaselineOffsetAttributeName value:@(5) range:NSMakeRange(0, attr.length)];
            card.listenViewTemp.lblPinyin.attributedText = attr;
            card.readTemp.lblPinyin.attributedText = attr;
            
            card.listenViewTemp.lblCardTitle.text = symbol;
            card.readTemp.lblCardTitle.text = symbol;
            card.writeView.lblCardTitle.text = symbol;
   
        } else {
            
            NSString *image_url = [NSString stringWithFormat:@"%@",dic[@"image_url"]];
            [card.imgWrite sd_setImageWithURL:[NSURL URLWithString:image_url]];
            NSString *audio_image_url = [NSString stringWithFormat:@"%@",dic[@"audio_image_url"]];
            [card.imgPicture sd_setImageWithURL:[NSURL URLWithString:audio_image_url]
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (image) {// 获取图片实际宽高比
                    [self updateImageConstraints:card.imgPicture image:image card:card];
                }
            }];
            NSString *sutitle = [NSString stringWithFormat:@"%@",dic[@"subtitle"]];
            if([sutitle isEqualToString:@"<null>"]){
                sutitle = @"";
            }
            card.listenViewTemp.lblCardSubtitle.text = sutitle;
            
            NSString *symbol =  [NSString stringWithFormat:@"%@",dic[@"symbol"]];
            if([symbol isEqualToString:@"<null>"]){
                symbol = @"";
            }   //等待处理32
          
            card.listenViewTemp.lblCardTitle.text = symbol;
            card.readTemp.lblCardTitle.text = symbol;
            
            BOOL isLength = symbol.length > 1? YES:NO;
            if([ColorManager isPurpleOrOrange]){
                isLength = NO;
            }
        }
        [self reloadCardViewTypeView:card];
     
    }
}
- (void)setupCardViews{//创建新卡片
    NSMutableArray *cards = [NSMutableArray array];
    CGFloat screenWidth = self.scrollView.bounds.size.width;
    
    int temp = (int)self.cardLetters.count-1;
    for (int i = 0; i < self.cardLetters.count; i++) {
        CardView *card = [[CardView alloc] initWithFrame:CGRectMake(i * screenWidth, 0, Card_WIDTH, Card_Height)];
        card.tag = i;
        card.uvc = self.uvc;
        //card.delegate = self;
        card.scrollViewTemp = self.scrollView;
        [self.scrollView addSubview:card];
        [cards addObject:card];
        
        if(i>temp) return;
            NSDictionary *dic = self.cardLetters[i];
            [self setCardTypeCell:dic View:card];
        if(IS_Formal_Hanzi){
            [card setHanziCardCell:dic];
        } else {
            [card setCardCell:dic];
        }
    }
    
    self.cardViews = cards.copy;
    int x = self.currentPage > 0 ? self.currentPage:0;
    if(x < self.cardLetters.count){
        [self cardDidAppearData:x];//汉字卡片初始化
    }
    
}
- (void)btnPlayLeftAction:(UIButton *)sender {
    if(self.currentCardView.isPlaying){//isplay2
        //再次点击取消动画
        [self.currentCardView stopPlayback];//停止播放
        //NSLog(@"-----------cc-----[点击---取消动画-----]");
    }else {
        [self.currentCardView playAudioUrl:@""];//播放url
        //NSLog(@"-----------cc-----[点击播放------------]");
    }
}
//点击录音
- (void)btnPlayRightAction:(UIButton *)sender {
    sender.enabled = NO;
    sender.alpha = 0.5;
    [self btnRecordingAction:sender];
}
//play_1_1 开始录音
/*- (void)startRecording;
//play_1_2 暂停录音 停止录音
- (void)stopRecording;
//play_4 播放录音
- (void)playRecording;
//停止播放
- (void)stopPlayback;
//play_5 删除录音
- (void)deleteRecording;*/
//=======================================================
- (void)btnRecordingAction:(UIButton *)sender{
    if(self.currentCardView.isRecording){//isvoice2
        //点击录音结束-----   上传ing
        [self.currentCardView stopRecording:YES];
   
      
        
    } else {
        //点击录音
        //[self.currentCardView startRecording];
        [self checkRecordPermission];
    
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.currentCardView.btnPlayRead.enabled = YES;
            self.currentCardView.btnPlayRead.alpha = 1.0;
            });
    }
}

- (void)checkRecordPermission {
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    
    switch (permissionStatus) {
        case AVAudioSessionRecordPermissionUndetermined:
            // 尚未请求权限
            [self requestRecordPermission];
            break;
        case AVAudioSessionRecordPermissionDenied:
            // 用户已拒绝
            [self showPermissionDeniedAlert];
            break;
        case AVAudioSessionRecordPermissionGranted:
            // 用户已授权
            [self.currentCardView startRecording];
            break;
    }
}
- (void)requestRecordPermission {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                // 用户已授权，可以开始录音
                [self.currentCardView startRecording];
            } else {
                // 用户拒绝授权，提示用户
                [self showPermissionDeniedAlert];
            }
        });
    }];
}
- (void)showPermissionDeniedAlert { //Microphone permission has been denied
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Microphone permission was denied",@"") message:NSLocalizedString(@"Enable microphone permissions in Settings to use the recording feature",@"")  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Go to Settings",@"")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",@"")  style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:settingsAction];
    [alert addAction:cancelAction];
    [self.uvc presentViewController:alert animated:YES completion:nil];
}

//===================================================
- (void)reloadCardViewTypeView:(CardView *)cardView {
    NSString *currentKey = [ColorManager currentColorKey];
    ColorItem *blue = [ColorManager itemForKey:currentKey];
    NSArray *colorArray = blue.colors;
    
    NSString *strColor;
    if(colorArray.count == 2){
        strColor = colorArray[0];
    }

    cardView.btnPlayListen.tag = cardView.tag + 300;
    [cardView.btnPlayListen addTarget:self action:@selector(btnPlayLeftAction:) forControlEvents:UIControlEventTouchUpInside];

    cardView.btnPlayRead.tag = cardView.tag + 600;
    [cardView.btnPlayRead addTarget:self action:@selector(btnPlayRightAction:) forControlEvents:UIControlEventTouchUpInside];
    
    SpeakResultsView *resultsView = (SpeakResultsView *)[self.currentCardView viewWithTag:955];
    if(resultsView){
        [resultsView removeFromSuperview];
    }
    if(self.currentCardView.isRecording){
        [self.currentCardView stopRecording:NO];
    }
    self.scrollView.scrollEnabled = YES;
    switch (self.footerIndex) {
        case 0:
        {
            //[self.currentCardView.listenTemp btnflipCardActionNo];
        }
            break;
        case 1:
        {
 
            //BOOL hasRecording = [[AudioManager sharedManager] recordingExistsForLetter:self.currentCardView.symbolTemp];
            //hasRecording = YES;
            NSLog(@"-----score--------[%@]------[%@]--",self.currentCardView.audio_score,self.currentCardView.audio_comment);
//            BOOL result = IS_Formal_Hanzi
//                          ? (self.currentCardView.audio_comment.length > 0)
//                          : (self.currentCardView.audio_score.intValue > 0);
            BOOL result = self.currentCardView.audio_score.intValue > 0;
            //if(result && hasRecording){
            if(result){
                [SpeakResultsView showSpeakResultsView:self.currentCardView.readTemp  data:@{@"comment":self.currentCardView.audio_comment}  resultsState:self.currentCardView.audio_score.intValue viewType:YES callBack:^(NSInteger index) {
                    if(index == 200){//播放url声音
                        [self.currentCardView playAudioUrl:@""];
                    }
                    if(index == 202){//播放录音
                        [self.currentCardView playRecording];
                    }
                    if(index == 101){//清空录音 重置
                        [self.currentCardView deleteRecording];
                    }
                }];
            }
        }
            break;
        case 2:
        {
            //self.scrollView.scrollEnabled = YES;
            //self.scrollView.scrollEnabled = NO;
        }
            break;
        case 3:
        {
            //self.scrollView.scrollEnabled = YES;
        }
            break;
        default:
            break;
    }
}

- (void)updateCardLayouts { //左右切换 左右滚动
    if (self.pageCount == 0) return;
    
    CGFloat screenWidth = self.scrollView.bounds.size.width;
    CGFloat contentOffsetX = self.scrollView.contentOffset.x;
    CGFloat page = contentOffsetX / screenWidth;
    NSInteger currentPage = (NSInteger)page;
    CGFloat progress = page - currentPage;
    
    CGFloat largeCardWidth = Card_WIDTH;
    CGFloat largeCardHeight = Card_Height;
    CGFloat smallCardHeight = Card_Height - 40;
    CGFloat smallCardVisibleWidth = 0;
    CGFloat spacing = 14;
    

   // CGFloat leftMargin = 39; // 左边距改为 39
    // 回调给外部处理
//    if (self.didSelectCardBlock) {
//        self.didSelectCardBlock(currentPage);
//    }
    //[self.currentCardView.playerVideo pause];//一有切换 播放器就暂停

    CGFloat sideMargin = 47 - 0; // 可灵活调整
    smallCardHeight = Card_Height - 70;
    sideMargin = 39;
    spacing = 12;
  
    for (int i = 0; i < self.pageCount; i++) {
        UIView *card = self.cardViews[i];
        //UILabel *label = [card viewWithTag:100];
        CGFloat cardWidth = largeCardWidth;
        CGFloat cardHeight = largeCardHeight;
        CGFloat y = (largeCardHeight - smallCardHeight) / 2;
        CGFloat x = i * screenWidth;
        
        if (i == currentPage) {//当前view
            cardHeight = largeCardHeight;
            y = 0;
            x = i * screenWidth + sideMargin;
            self.currentCardView = (CardView *)card;
        }
        
        else if (i == currentPage + 1 && i < self.pageCount) {//右侧view
            cardHeight = smallCardHeight;
            x = (currentPage * screenWidth) + sideMargin + largeCardWidth + spacing - smallCardVisibleWidth;
            
            if (progress > 0) {
                cardHeight = smallCardHeight + (largeCardHeight - smallCardHeight) * progress;
                y = (largeCardHeight - cardHeight) / 2;
            }
        } else if (i == currentPage - 1 && i >= 0) {//左侧view
            cardHeight = smallCardHeight;
            x = (currentPage * screenWidth)  - cardWidth + ( sideMargin - spacing);
            if (progress < 0) {
                cardHeight = smallCardHeight + (largeCardHeight - smallCardHeight) * (1 - progress);
                y = (largeCardHeight - cardHeight) / 2;
            }
        } else {
            cardHeight = smallCardHeight;
        }
        card.frame = CGRectMake(x, y, cardWidth, cardHeight);
    }
}
- (NSInteger)currentCardIndex {
    CGFloat pageWidth = self.scrollView.bounds.size.width;
    if (pageWidth <= 0) return 0;
    NSInteger index = (NSInteger)((self.scrollView.contentOffset.x + pageWidth * 0.5) / pageWidth);
    // 防止越界
    index = MAX(0, MIN(index, self.pageCount - 1));
    return index;
}
- (void)btnLeftViewAction:(UIButton *)sender {
    //[self snapToNearestPage];
    [KUSER_DEFAULT setBool:NO forKey:@"isFullScreen"];
    if(self.didSelectCardBlock33){
        self.didSelectCardBlock33(0);
    }
    //[self.currentCardView.playerVideo pause]; //一有切换 播放器就暂停

    AVPlayer *player = self.currentCardView.playerVideo;
    AVPlayerItem *item = player.currentItem;
    if (item && player.rate > 0 && item.status == AVPlayerItemStatusReadyToPlay) {
        [player pause];// 正在播放
    }
  
    if(sender.tag == 35){
        if (self.currentPage <= 0) return;
        self.currentPage--;
        CGFloat screenWidth = self.scrollView.bounds.size.width;
        [UIView animateWithDuration:0.2 animations:^{
            [self.scrollView setContentOffset:CGPointMake(self.currentPage * screenWidth, 0)];
        } completion:^(BOOL finished) {
            [self updateCardLayouts];
        }];
    } else {
        if (self.currentPage >= self.pageCount - 1) return;
        self.currentPage++;
        CGFloat screenWidth = self.scrollView.bounds.size.width;
        [UIView animateWithDuration:0.2 animations:^{
            [self.scrollView setContentOffset:CGPointMake(self.currentPage * screenWidth, 0)];
        } completion:^(BOOL finished) {
            [self updateCardLayouts];
        }];
    }
    // 回调给外部处理

//    [KUSER_DEFAULT setBool:NO forKey:@"isFullScreen"];
//    NSInteger index = [self currentCardIndex];
//    if(self.didSelectCardBlock33){//?
//        self.didSelectCardBlock33(index);
//    }
}
#pragma mark - UIScrollViewDelegate //左右滑动卡片
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    BOOL isDidScroll = NO;
    //scrollView.backgroundColor = [UIColor orangeColor];
    [self updateCardLayouts];
    if (scrollView.isDragging || scrollView.isTracking) {
        isDidScroll = YES;
        [KUSER_DEFAULT setBool:NO forKey:@"isFullScreen"];
    }
    //NSLog(@"isDidScroll-------[%d]----[%d]---------------------------------------------v--",isDidScroll,[KUSER_DEFAULT boolForKey:@"isFullScreen"]);
  
    if(isDidScroll || ![KUSER_DEFAULT boolForKey:@"isFullScreen"]){
        NSInteger index = [self currentCardIndex];
        //NSLog(@"---------------cc---------------[%ld]--[%ld]-------cc-------",index,self.lastVisibleIndex);
        if (index != self.lastVisibleIndex) {
            //NSLog(@"当前可见卡片index = --------[%ld]---------11--", (long)index);
            // 卡片变更 → 加载视频/GIF
            [self cardDidAppearData:index];//
            // 上一个卡片 → 停止释放资源
            if (self.lastVisibleIndex >= 0) {
                [self cardDidDisappear:self.lastVisibleIndex];
            }
            self.lastVisibleIndex = index;
        }
        //==============???
        if(self.didSelectCardBlock33){
            self.didSelectCardBlock33(index);
        }
        //[self.currentCardView.playerVideo pause]; //一有切换 播放器就暂停
        AVPlayer *player = self.currentCardView.playerVideo;
        AVPlayerItem *item = player.currentItem;
        if (item && player.rate > 0 && item.status == AVPlayerItemStatusReadyToPlay) {
            [player pause];// 正在播放
        }
       
    }
}
- (void)cardDidAppearData:(NSInteger)index {
    NSLog(@"当前可见卡片 index-----[%ld]------------------------------------v-", (long)index);
    //int temp = (int)self.cardLetters.count-1;
    //if(index>temp) return;
    CardView *card = (CardView *)self.cardViews[index];
    NSDictionary *dic = self.cardLetters[index];
    self.currentCardView = card;
    [self setCardTypeCell:dic View:card];
    [card cardDidAppearDic:dic];
    [card configureWithType:@"Listen"];
}
- (void)cardDidDisappear:(NSInteger)index {
    int temp = (int)self.cardLetters.count-1;
    if(index>temp) return;
    CardView *card = (CardView *)self.cardViews[index];
    NSDictionary *dic = self.cardLetters[index];
    [self setCardTypeCell:dic View:card];
    [card cardDidDisappear:dic];
    [card configureWithType:@"Listen"];
    //card.backgroundColor = [UIColor yellowColor];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
   [self snapToNearestPage];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self snapToNearestPage];
        //self.isUserScrolling = NO;
        //NSLog(@"用户拖动结束且没有减速");
    }
}
- (void)snapToNearestPage {
    CGFloat screenWidth = self.scrollView.bounds.size.width;
    CGFloat offsetX = self.scrollView.contentOffset.x;
    NSInteger page = lround(offsetX / screenWidth);
    page = MAX(0, MIN(page, self.pageCount - 1));
    self.currentPage = (int)page;
    [UIView animateWithDuration:0.2 animations:^{
        [self.scrollView setContentOffset:CGPointMake(page * screenWidth, 0)];
    } completion:^(BOOL finished) {
        [self updateCardLayouts];
    }];
}

//好像没用到
- (void)cardTapped:(UITapGestureRecognizer *)gesture {
    UIView *card = gesture.view;
    NSInteger index = card.tag;
    
    // 添加点击动画效果
    [UIView animateWithDuration:0.1 animations:^{
        card.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            card.transform = CGAffineTransformIdentity;
        }];
    }];
    
//    // 回调给外部处理
//    if (self.didSelectCardBlock22) {
//        self.didSelectCardBlock22(index);
//    }
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
#pragma mark - CardViewDelegate
- (void)cardViewDidTapButton:(CardView *)cardView {
    //NSLog(@"卡片 %ld 被点击", (long)cardView.cardIndex);
    // 这里可以写 push 页面 / 弹窗 / 播放逻辑 等
    VideoFullScreenViewController *vc = [[VideoFullScreenViewController alloc] init];
    vc.player = cardView.playerVideo; // 传递同一个 AVPlayer，继续播放
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [KUSER_DEFAULT setObject:@"Video" forKey:Card_Type];
    [self.uvc presentViewController:vc animated:YES completion:nil];
}
#pragma mark - 全屏
- (void)enterFullScreen {
    /*AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    playerVC.player = self.player;
    [self presentViewController:playerVC animated:YES completion:^{
        [self.player play];
    }];*/
 

}
@end

