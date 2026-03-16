//
//  CardView.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/10.
//

#import "CardView.h"
#import "AudioQueueManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SpeakResultsView.h"
#import "AudioPlayerManager.h"
#import "VideoFullScreenViewController.h"

@interface CardView ()
@property (strong, nonatomic) NSString *pinyin_id;
@property (strong, nonatomic) NSString *hanzi_id;
@property (strong, nonatomic) NSString *audio_url;

@property (strong, nonatomic) UIButton *btnClear;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, strong) UIProgressView *uploadProgressView;

@property (nonatomic, strong) NSString *gif_url;
// 1️⃣ 在类里加一个标志位，防止重复全屏
@property (nonatomic, assign) BOOL isFullScreen;
@end

@implementation CardView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.audio_comment = @"";
        [self addSubview:self.listenView];
        [self addSubview:self.readView];
        [self addSubview:self.writeView];
        [self addSubview:self.videoView];

        //1. 根据条件确定要创建的类
        Class viewClass = IS_Formal_Hanzi ? [HanziCardView class] : [CardTipsView class];
        //2. 动态创建对象（多态）
        CardBaseView *listenTips = [[viewClass alloc] initWithTypeStyle:TipsLayoutStyleListen];
        listenTips.frame = CGRectMake(0, 0, Card_WIDTH, Card_Height);
        [self.listenView addSubview:listenTips];
        self.listenViewTemp = listenTips;
        self.btnPlayListen = self.listenViewTemp.btnPlay;
        int temp = 230;
        for (int i = 0; i < 2; i++) {
            UIButton *btn = (UIButton *)[self.listenViewTemp viewWithTag:temp + i];
            btn.layer.cornerRadius = 5;//圆角
            btn.layer.masksToBounds = YES;
            [btn addTarget:self action:@selector(btnPlaySoundAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        //在readView 上
        CardBaseView *readTips = [[viewClass alloc] initWithTypeStyle:TipsLayoutStyleRead];
        readTips.frame = CGRectMake(0, 0, Card_WIDTH, Card_Height);
        [self.readView addSubview:readTips];
        self.readTemp = readTips;
        
        self.btnPlayRead = self.readTemp.btnPlay;
        NSString *currentKey = [ColorManager currentColorKey];
        self.readTemp.btnPlay.normalImage = [UIImage imageNamed:[NSString stringWithFormat:@"record_icon_%@",currentKey]];
        //[self updateUIState];


    }
    return self;
}
//点击两个音频合并
 - (void)btnPlaySoundAction:(UIButton *)sener {
     int temp = 230;
     int tag = (int)sener.tag - temp;
     
     NSArray *dataArray = [NSArray arrayWithArray:self.dicStrokes[@"form_words"]];
     for (int i = 0; i < dataArray.count; i++) {
         UIButton *btn = (UIButton *)[self.listenViewTemp viewWithTag:temp + i];
         
         if(tag == i){
             btn.backgroundColor = [self colorWithHexString:@"#F6F6F6" alpha:1];
             NSString *audio_url = [NSString stringWithFormat:@"%@",dataArray[i][@"main_audio_url"]];
             NSString *fallback_audio_url = [NSString stringWithFormat:@"%@",dataArray[i][@"fallback_audio_url"]];
             
             NSLog(@"-----audio_url----ccc------[%@]-----[%@]",audio_url,fallback_audio_url);
             self.isPlaying = YES;
             //[self.btnPlayListen startPlaying];
             
             [[AudioQueueManager sharedManager] playAudioQueueWithURLs:@[audio_url,fallback_audio_url] completion:^(BOOL success, NSError * _Nonnull error) {
                 //=====================================
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayDidFinishNotification"
                                                                     object:nil
                                                                   userInfo:@{@"status": @(YES)}];
                 if (success) {
                     //播放成功完成
                     //[self updateUIForPlaybackSuccess];
                 } else {
                     //处理播放错误
                     [self handlePlaybackError:error];
                 }
                 btn.backgroundColor = [UIColor clearColor];
                 //==========================================
             }];
             /*[[AudioQueueManager sharedManager] playMergedAudioWithURLs:@[audio_url,fallback_audio_url] completion:^(BOOL success, NSError * _Nullable error) {
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayDidFinishNotification"
                                                                     object:nil
                                                                   userInfo:@{@"status": @(YES)}];
                 if (success) {
                     //播放成功完成
                     //[self updateUIForPlaybackSuccess];
                 } else {
                     //处理播放错误
                     [self handlePlaybackError:error];
                 }
                 btn.backgroundColor = [UIColor clearColor];
             }];*/
         } else {
             btn.backgroundColor = [UIColor clearColor];
         }
     }
 }
 
- (void)configureWithType:(NSString *)type {
    self.listenView.hidden = ![type isEqualToString:@"Listen"];
    self.readView.hidden   = ![type isEqualToString:@"Speak"];
    self.writeView.hidden  = ![type isEqualToString:@"Write"];
    self.videoView.hidden  = ![type isEqualToString:@"Video"];
    
    if(!self.writeView.hidden){
        if(self.gif_url.length > 6){
            [self.writeView loadGIFWithURLString:self.gif_url];
        }
    }
}

- (UIView *)listenView {
    if(!_listenView){
        _listenView = [[UIView alloc]initWithFrame:self.bounds];
        _listenView.clipsToBounds = YES;
        _listenView.frame = CGRectMake(0,0,Card_WIDTH,Card_Height);
        _listenView.backgroundColor =  [self colorWithHexString:@"#FFFFFF" alpha:1];
        
        self.imgPicture = [[UIImageView alloc]init];
        self.imgPicture.frame = CGRectMake(Card_WIDTH - 268, 0, 268, 136);
        [_listenView addSubview:self.imgPicture];
        self.imgPicture.hidden = [ColorManager isPurpleOrOrange];
    }
    return _listenView;
}

- (UIView *)readView {
    if(!_readView){
        _readView = [[UIView alloc]initWithFrame:self.bounds];
        _readView.hidden = YES;
        _readView.clipsToBounds = YES;
        _readView.frame = CGRectMake(0,0,Card_WIDTH,Card_Height);
        _readView.backgroundColor =  [self colorWithHexString:@"#FFFFFF" alpha:1];
    }
    return _readView;
}
- (CardBaseView *)writeView {
    if(!_writeView){
        Class viewClass = IS_Formal_Hanzi ? [HanziCardView class] : [CardTipsView class];
        //_writeView = [[viewClass alloc] initWithStyle:TipsLayoutStyleWrite];
        _writeView = [[viewClass alloc] initWithTypeStyle:TipsLayoutStyleWrite];
        _writeView.frame = CGRectMake(0, 0, Card_WIDTH, Card_Height);
        _writeView.hidden = YES;
        _writeView.clipsToBounds = YES;
        _writeView.backgroundColor = [UIColor whiteColor];
        for (int i = 0; i < 2; i++) {
            UIButton *btn = (UIButton *)[_writeView viewWithTag:135+i];
            btn.hidden = NO;
        }
        
        [self setClearAndSubmitButton:NO];
        self.btnClear = (UIButton *)[_writeView viewWithTag:135];
        [self.btnClear addTarget:self action:@selector(clearDrawing:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *btnSubmit = (UIButton *)[_writeView viewWithTag:136];
        [btnSubmit addTarget:self action:@selector(submitWriting:) forControlEvents:UIControlEventTouchUpInside];
        
        if(!IS_Formal_Hanzi){
            CGFloat width = 216;//正常版    //temp = 1.0;//宽高等比例·1
            CGFloat height = 163;           //width = 240; //height = 180;
            
            if([ColorManager isPurple]) {
                    width = 282;
                    height = 163;
            }
            CGFloat newWidth = Card_WIDTH - 20;
            CGFloat newHeight = newWidth * (height / width);
            UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake((Card_WIDTH-newWidth)/2, (Card_Height - 58 - newHeight)/2, newWidth,newHeight)];
            [_writeView addSubview:imgView];
            self.imgWrite = imgView;
        }

        self.handwritingView = [[HandwritingView alloc] init];
        int y = 66 + 18 * IS_Formal_Screen;
        int hanziWidth = 230 + 30 * IS_Formal_Screen;
        if(IS_Formal_Hanzi){
            hanziWidth = (IS_Formal_Screen ? (Card_WIDTH - 60) : 210 );
            self.handwritingView.frame = CGRectMake((Card_WIDTH - hanziWidth)/2,y, hanziWidth, hanziWidth);;
        } else {
            self.handwritingView.frame = self.imgWrite.frame;
        }
        
        [_writeView addSubview:self.handwritingView];
        __weak typeof(self) weakSelf = self;
        [self.handwritingView setSelectedTypeIndex:^(NSInteger index) {
            if(index > 0){
                [weakSelf setClearAndSubmitButton:YES];
            }
        }];
    }
    return _writeView;
}
//- (void)playVideo:(NSString *)url {
//    if([ColorManager isBlue]){
//        
//    }
//}
- (void)destroyPlayer {
    [self.playerVideo pause];
    //[self.playerLayer removeFromSuperlayer];
    //self.playerLayer = nil;
    [self.playerVideo replaceCurrentItemWithPlayerItem:nil];
    self.playerVideo = nil;
}
- (UIView *)videoView {
    if(!_videoView){
        _videoView = [[UIView alloc]initWithFrame:self.bounds];
        _videoView.hidden = YES;
        _videoView.clipsToBounds = YES;
        UIImageView *imgV = [[UIImageView alloc]initWithFrame:self.bounds];
        int type = SCREEN_HEIGHT < Small_Screen ? 0 : 1;
        imgV.image = [UIImage imageNamed:@[@"mask_group_small",@"mask_group"][type]];
        if(IS_Formal_Hanzi){
            imgV.image = [UIImage imageNamed:@[@"mask_group_small_1",@"mask_group_1"][type]];
        }
        [_videoView addSubview:imgV];
        
        CGFloat height = self.frame.size.width * (168.0 / 298.0);//宽高等比例
        //if([ColorManager isBlue]){
            [self setupAudioSession];
   
                VideoPlayerView *playerView = [[VideoPlayerView alloc] init];
                [_videoView addSubview:playerView];
                self.playerViewVideo = playerView;
                
                [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.centerY.equalTo(_videoView);   // 垂直居中
                    make.left.right.equalTo(_videoView); // 左右贴齐
                    make.height.mas_equalTo(height);     // 固定高度
                }];
                
                // 点击播放视频
                //[playerView playVideoAndStopAudio];
                // 全屏回调
        
                __weak typeof(self) weakSelf = self;
                playerView.enterFullScreenBlock = ^(AVPlayer *player) {
//                    __strong typeof(weakSelf) self = weakSelf;
//                    if (!self) return;                        // 防止 self 已释放
//                    if (!self.uvc) return;                    // 防止 uvc 为 nil
//                    if (!player) return;                      // 防止 player 为 nil
//                    if (self.isFullScreen) return;            // 防止重复点击
//                    self.isFullScreen = YES;
                    
                    
                    VideoFullScreenViewController *vc = [[VideoFullScreenViewController alloc] init];
                    vc.player = player;
                    vc.modalPresentationStyle = UIModalPresentationFullScreen;
                    //[self.uvc presentViewController:vc animated:YES completion:nil];
                    [self.uvc presentViewController:vc animated:YES completion:^{
                        self.isFullScreen = NO;               // 全屏弹出完成后，解除标记
                    }];
                    [KUSER_DEFAULT setBool:YES forKey:@"isFullScreen"];
                    [KUSER_DEFAULT setObject:@"Video" forKey:Card_Type];
                };
                // 监听关闭音频的通知
        //}
    }
    return _videoView;
}
- (void)setupAudioSession {
    NSError *error = nil;
    
    // 设置为媒体播放模式（非静音、非混音，声音和全屏一致）
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    if (error) {
        NSLog(@"设置 AVAudioSessionCategoryPlayback 出错: %@", error);
    }
    
    // 激活会话
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        NSLog(@"激活 AVAudioSession 出错: %@", error);
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */
//================================提交笔画start=====================================
- (void)clearDrawing:(UIButton *)sender {
    [self.handwritingView clearDrawing];
    [self setClearAndSubmitButton:NO];
}
- (void)setClearAndSubmitButton:(BOOL)isEnabled {
    
    NSString *currentKey = [ColorManager currentColorKey];
    NSString *key = @[@"gray",currentKey][isEnabled];
    NSString *clear = [NSString stringWithFormat:@"clear_%@",key];
    NSString *submit = [NSString stringWithFormat:@"submit_%@",key];
    for (int i = 0; i < 2; i++) {
        UIButton *btn = (UIButton *)[self.writeView viewWithTag:135 + i];
        [btn setImage:[UIImage imageNamed:@[clear,submit][i]] forState:UIControlStateNormal];
        btn.userInteractionEnabled = isEnabled;
    }
}
- (void)submitWriting:(UIButton *)sender {
    if (self.handwritingView.strokesArray.count == 0) {
        //[MBProgressHUD showLabel:@"请先书写内容"];
        return;
    }
    NSDictionary *writingData = [self.handwritingView getWritingData];//保存数据
    [self.handwritingView saveToUserDefaults];
    //[self logJson:writingData];
    [self submitStrokesScore:writingData];//按比例提交文字_1_提交书写评分
}
//===============================
//提交笔画 评分
#pragma mark - 笔画上传功能。
//上传模版数据用，暂无用
/*- (void)pinyinScoreTest:(NSDictionary *)dic{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *currentKey = [ColorManager currentColorKey];
    ColorItem *blue = [ColorManager itemForKey:currentKey];
    params[@"type"] = blue.type;
    params[@"character"] = self.symbolTemp;
    params[@"strokes"] = dic[@"strokes"];
    params = [LanguageHelper currentLanguageParams:params];
    [MBProgressHUD showMessage:NSLocalizedString(@"Scoring...","")];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
    });
    
    [HttpTools postRequest:@"/user/createTemplates" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        [MBProgressHUD hideHUD];
        if (success) {
            [MBProgressHUD showLabel:@"提交成功"];
        } else {
            [MBProgressHUD showLabel:@"失败"];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}*/
//_2_提交
- (NSArray *)strokesToStandard264:(NSArray<NSDictionary *> *)strokes
                 currentGridWidth:(CGFloat)currentWidth
                         margin:(CGFloat)margin
{
    if (!strokes || strokes.count == 0) return @[];

    CGFloat standardWidth = 264.0; // 标准田字格宽高
    CGFloat effectiveWidth = currentWidth - 2*margin;

    NSMutableArray *scaledStrokes = [NSMutableArray array];

    for (NSDictionary *stroke in strokes) {
        NSArray *points = stroke[@"points"];
        if (![points isKindOfClass:[NSArray class]]) continue;

        NSMutableArray *scaledPoints = [NSMutableArray array];
        for (NSDictionary *p in points) {
            CGFloat x = [p[@"x"] floatValue];
            CGFloat y = [p[@"y"] floatValue];
            NSNumber *t = p[@"t"];

            // 归一化到 0~1
            CGFloat normX = (x - margin) / effectiveWidth;
            CGFloat normY = (y - margin) / effectiveWidth;

            // 映射到 264 标准
            CGFloat uploadX = normX * standardWidth;
            CGFloat uploadY = normY * standardWidth;
            NSDictionary *scaledPoint = @{@"x": @(uploadX),
                                          @"y": @(uploadY),
                                          @"t": t ?: @(0)};
            [scaledPoints addObject:scaledPoint];
        }
        NSDictionary *scaledStroke = @{
            @"order": stroke[@"order"] ?: @(0),
            @"points": scaledPoints
        };
        [scaledStrokes addObject:scaledStroke];
    }
    return scaledStrokes;
}

- (void)submitStrokesScore:(NSDictionary *)dic{
    //上架必备
    //[self pinyinScoreTest:dic];
    //return;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *currentKey = [ColorManager currentColorKey];
    ColorItem *blue = [ColorManager itemForKey:currentKey];
    

    if(IS_Formal_Hanzi){
        int hanziWidth = (IS_Formal_Screen ? (Card_WIDTH - 60) : 210 );
        //NSArray *standardStrokes = [self strokesToStandard264:dic[@"strokes"]
                                                       //currentGridWidth:hanziWidth];
        NSArray *standardStrokes = [self strokesToStandard264:dic[@"strokes"] currentGridWidth:hanziWidth margin:0];
        params[@"strokes"] = standardStrokes;
        //params[@"strokes"] = dic[@"strokes"];//按比例提交文字_1_vvv 提交
        params[@"character"] = self.symbolTempStr;
        params[@"hanzi_id"] = self.hanzi_id;
        params[@"app_region"] = @[@"domestic",@"overseas"][IS_OVERSEAS_VERSION];
    } else {
        params[@"strokes"] = dic[@"strokes"];
        params[@"character"] = self.symbolTemp;
        params[@"type"] = blue.type;
        params[@"is_rework"] = [self.dicStrokes[@"learn_strokes"] isKindOfClass:[NSArray class]]? @"1":@"0";
        params[@"pinyin_id"] = self.pinyin_id;
    }
    
    params = [LanguageHelper currentLanguageParams:params];
    [MBProgressHUD showMessage:NSLocalizedString(@"Scoring...","")];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
    });
    params = [LanguageHelper currentLanguageParams:params];
    //书写评分
    NSString *strUrl = @[@"/writing/pinyinScore",@"/writing/hanziScore"][IS_Formal_Hanzi];
    [HttpTools postRequest:strUrl parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        [MBProgressHUD hideHUD];
        if (success) {
            if (self.buttonClickBlock) {
                  NSString *carId = IS_Formal_Hanzi ? self.hanzi_id : self.pinyin_id;
                  self.buttonClickBlock(carId, @"btnWriting");
              }
            
            NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
            self.dicStrokes = dic;
            self.dicStrokesTemp = dic;
            [self loadWritingData:self.dicStrokes[@"strokes"]];
            NSString *score =  [NSString stringWithFormat:@"%@",dic[@"score"]];
            [SpeakResultsView showSpeakResultsView:self data:@{@"comment":@""} resultsState:score.intValue viewType:NO callBack:^(NSInteger index) {
                if(index == 101){
                    [self clearDrawing:self.btnClear];
                }
            }];
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (NSData *)convertArrayToJSONData:(NSArray *)array {
    if (![NSJSONSerialization isValidJSONObject:array]) {
        NSLog(@"数组包含无法转换为 JSON 的元素");
        return nil;
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array
                                                       options:0
                                                         error:&error];
    if (error) {
        //NSLog(@"JSON 转换错误: %@", error.localizedDescription);
        return nil;
    }
    return jsonData;
}
- (void)logJson:(id)jsonObject {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!error) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        printf("==[%s]\n=------------1---=", [jsonString UTF8String]);  // 使用printf避免NSLog添加的时间戳
    } else {
        //NSLog(@"JSON打印错误: [%@]", error.localizedDescription);
    }
    
}
//画出笔画
- (void)loadWritingData:(NSArray *)strokesArray { //按比例提交文字_1_接口返回展示

    if (strokesArray>0) {
        //NSDictionary *writingData = [HandwritingView loadFromUserDefaults];

        if(IS_Formal_Hanzi){
            int hanziWidth = (IS_Formal_Screen ? (Card_WIDTH - 60) : 210 );
            NSArray *array = [self strokesFromStandard264:strokesArray currentGridWidth:hanziWidth ];
            [self.handwritingView loadWritingData:array];    //按比例提交文字_1_vvv 画
        } else {
            [self.handwritingView loadWritingData:strokesArray];
        }
    }
}
//_2_返回
- (NSArray *)strokesFromStandard264:(id)strokesInput
                   currentGridWidth:(CGFloat)currentWidth
{
    if (!strokesInput) return @[];

    NSArray *strokesArray = nil;
    if ([strokesInput isKindOfClass:[NSArray class]]) {
        strokesArray = strokesInput;
    } else if ([strokesInput isKindOfClass:[NSString class]] && [strokesInput length] > 0) {
        NSData *data = [strokesInput dataUsingEncoding:NSUTF8StringEncoding];
        if (data.length == 0) return @[];
        NSError *error = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [jsonObj isKindOfClass:[NSArray class]]) {
            strokesArray = jsonObj;
        } else {
            NSLog(@"❌ JSON parse error: %@", error);
            return @[];
        }
    } else {
        return @[];
    }

    if (strokesArray.count == 0) return @[];

    CGFloat standardWidth = 264.0;
    CGFloat scale = currentWidth / standardWidth; // 核心比例
    NSMutableArray *scaledStrokes = [NSMutableArray arrayWithCapacity:strokesArray.count];
    for (NSDictionary *stroke in strokesArray) {
        NSArray *points = stroke[@"points"];
        if (![points isKindOfClass:[NSArray class]]) continue;

        NSMutableArray *scaledPoints = [NSMutableArray arrayWithCapacity:points.count];
        for (NSDictionary *p in points) {
            CGFloat x = [p[@"x"] floatValue];
            CGFloat y = [p[@"y"] floatValue];
            NSNumber *t = p[@"t"] ?: @(0);

            // 核心缩放公式
            CGFloat drawX = x * scale;
            CGFloat drawY = y * scale;
            NSDictionary *scaledPoint = @{@"x": @(drawX),
                                          @"y": @(drawY),
                                          @"t": t};
            [scaledPoints addObject:scaledPoint];
        }

        NSDictionary *scaledStroke = @{
            @"order": stroke[@"order"] ?: @(0),
            @"points": scaledPoints
        };
        [scaledStrokes addObject:scaledStroke];
    }

    return [scaledStrokes copy];
}
//================================提交笔画end=================================
//===============================声音ing=====提交开始================================
#pragma mark - 录音控制
//play_1_1 开始录音
- (void)startRecording {
    [[AudioManager sharedManager] startRecordingForLetter:self.symbolTemp];
    self.isRecording = YES;
    // 更新UI
    //[self updateUIState];
    // 开始进度计时器
    //footerindex=1  录音 开
    [self startProgressTimer];
    [self.btnPlayRead startPlaying];
    self.readTemp.lblCardSubtitle.text = NSLocalizedString(@"Recording...Tap to stop",@"");
}
//play_1_2 暂停录音 停止录音
- (void)stopRecording:(BOOL)isUpload {
    [[AudioManager sharedManager] stopRecording];
    self.isRecording = NO;
    // 更新UI
    //[self updateUIState];
    // 停止进度计时器
    [self stopProgressTimer];
    self.readTemp.lblCardSubtitle.text = NSLocalizedString(@"Tap to start recording and say this sound out loud",@"");
    //footerindex=1   录音 关
    [self.btnPlayRead stopPlaying];
    if(isUpload){
        [self uploadRecording];//上传数据
    } else {
            self.btnPlayRead.enabled = YES;
            [UIView animateWithDuration:0.2 animations:^{
                self.btnPlayRead.alpha = 1.0;
            }];
        
    }
}
#pragma mark - 播放控制
//play_4 播放录音
- (void)playRecording {
    if(self.audio_score.intValue > 0){//如果有评分,优先拿接口音频
        self.isPlaying = YES;
        [self playAudioUrl:self.learn_audio_url];
        return;
    }
    if (self.isPlaying) {
        [self stopPlayback];
    } else {
        [[AudioManager sharedManager] playRecordingForLetter:self.symbolTemp];//本地
        self.isPlaying = YES;
        // 更新UI
        //[self updateUIState];
        // 开始进度计时器
        [self startProgressTimer];
    }
}
//停止播放
- (void)stopPlayback {
    [[AudioManager sharedManager] stopPlayback];
    self.isPlaying = NO;
    //更新UI
    //[self updateUIState];
    //停止进度计时器
    [self stopProgressTimer];
    //footerindex=0  播放 关
    [self.btnPlayListen stopPlaying];
}
#pragma mark - 文件管理
//play_5 删除录音
- (void)deleteRecording {
    self.audio_score = @"";
    [[AudioManager sharedManager] deleteRecordingForLetter:self.symbolTemp];
    //更新UI
    //[self updateUIState];
}
#pragma mark - 进度更新
- (void)startProgressTimer {
    [self stopProgressTimer];
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                          target:self
                                                        selector:@selector(updateProgress)
                                                        userInfo:nil
                                                         repeats:YES];
}
- (void)stopProgressTimer {
    if (self.progressTimer) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
}
- (void)updateProgress {
    if (self.isRecording) {
        AVAudioRecorder *recorder = [AudioManager sharedManager].audioRecorder;
        if (recorder) {
            NSTimeInterval duration = recorder.currentTime;
            self.progressView.progress = duration / 60.0; // 最大录音60秒
        }
    } else if (self.isPlaying) {
        AVAudioPlayer *player = [AudioManager sharedManager].audioPlayer;
        if (player) {
            self.progressView.progress = player.currentTime / player.duration;
        }
    }
}
- (void)dealloc {
    [self.btnPlayListen stopPlaying];
    [self.btnPlayRead stopPlaying];
    
    [self stopProgressTimer];
    [[AudioManager sharedManager] stopRecording];
    [[AudioManager sharedManager] stopPlayback];
}
//播放url音频声音
- (void)playAudioUrl:(NSString *)audioUrl{
    //footerindex=0  播放 开
    self.isPlaying = YES;
    [self.btnPlayListen startPlaying];
    // 添加视觉反馈
    if([audioUrl isEqualToString:@""]){
        audioUrl = self.audio_url;
    }
    [[AudioPlayerManager sharedManager] playShortAudioWithURL:audioUrl completion:^(BOOL success, NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayDidFinishNotification"
                                                            object:nil
                                                          userInfo:@{@"status": @(YES)}];
        if (success) {
            //播放成功完成
            [self updateUIForPlaybackSuccess];
        } else {
            //处理播放错误
            [self handlePlaybackError:error];
        }
    }];
}
- (void)updateUIForPlaybackSuccess {
    // 更新UI显示播放成功
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPlayback];
    });
}
- (void)handlePlaybackError:(NSError *)error {
    // 处理错误并更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPlayback];
    });
}
//===============================声音ing=========end============================
#pragma mark - UI设置 (增加上传部分)
- (void)setupProgressUI {
    // ... 已有UI设置代码 ...

}
// 在UI设置中添加上传按钮
- (void)setUploadRecording {
    // ... 原有按钮代码保持不变 ...
    // 注册上传进度通知
    //[[NSNotificationCenter defaultCenter] addObserver:self
    //selector:@selector(handleUploadProgress:)
    //name:@"AudioUploadProgress"
    //object:nil];
}
// 处理上传进度通知。暂无用
- (void)handleUploadProgress111:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *letter = userInfo[@"letter"];
    //NSNumber *progress = userInfo[@"progress"];
    
    //if ([letter isEqualToString:self.symbolTemp]) {
      //  dispatch_async(dispatch_get_main_queue(), ^{
            //CGFloat progressValue = [progress floatValue];
            //self.uploadProgressLabel.text = [NSString stringWithFormat:@"上传进度: %.0f%%", progressValue * 100];
        //});
    //}
}
// 在dealloc中移除通知
//- (void)dealloc {
//[[NSNotificationCenter defaultCenter] removeObserver:self];
//}
// 添加上传方法

// ... 其他方法保持不变 ...
//====================================================================以上 暂无用===
//=================================================================================
#pragma mark - 声音上传功能
//上传录音数据_data
- (void)uploadRecording {
    // 检查上传状态
    UploadStatus status = [[AudioManager sharedManager] uploadStatusForLetter:self.symbolTemp];
    if (status == UploadStatusInProgress) {
        [self cancelUpload];
        
        self.btnPlayRead.enabled = YES;
        self.btnPlayRead.alpha = 1.0;

        return;
    }
    
    // 显示上传UI
    self.uploadProgressView.hidden = NO;
    self.uploadProgressView.progress = 0.0;
    // 开始上传
    // 检查是否有录音
    if (![[AudioManager sharedManager] recordingExistsForLetter:self.symbolTemp]) {
        [MBProgressHUD showLabel:@"Unable to upload"];
        self.btnPlayRead.enabled = YES;
        self.btnPlayRead.alpha = 1.0;
        
        return;
    }
    
    // 更新UI状态 提交录音     //录音评分
    //[self.uploadButton setTitle:@"上传中..." forState:UIControlStateNormal];;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *currentKey = [ColorManager currentColorKey];
    ColorItem *blue = [ColorManager itemForKey:currentKey];
    params[@"type"] = blue.type;
    if(IS_Formal_Hanzi){
        params[@"hanzi_id"] = self.hanzi_id;
        params[@"app_region"] = @[@"domestic",@"overseas"][IS_OVERSEAS_VERSION];
    } else {
        params[@"pinyin_id"] = self.pinyin_id;
        params[@"character"] = self.symbolTemp;
    }
  
    //params[@"is_rework"] = self.audio_score.intValue > 1 ? @"1":@"0";
    params = [LanguageHelper currentLanguageParams:params];
    [MBProgressHUD showMessage:NSLocalizedString(@"Scoring...","")];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
    });
    // 执行上传

    self.btnPlayRead.enabled = YES;
    self.btnPlayRead.alpha = 1.0;
    
    [[AudioManager sharedManager] uploadRecordingForLetter:self.symbolTemp
                                                    params:params
                                                completion:^(BOOL success,BaseDataModel *response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUD];
            if (success) {
                //self.uploadProgressLabel.text = @"✅ 上传成功!";
                if (self.buttonClickBlock) {
                    NSString *carId = IS_Formal_Hanzi ? self.hanzi_id : self.pinyin_id;
                    self.buttonClickBlock(carId, @"btnRecord");
                }
                //====================================================================
                //上传录音数据返回结果
                NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
                self.learn_audio_url = [NSString stringWithFormat:@"%@",dic[@"read_audio"]];
                self.audio_score = [NSString stringWithFormat:@"%@",dic[@"score"]];
                self.audio_comment  = [NSString stringWithFormat:@"%@",dic[@"comment"]];
                
                [SpeakResultsView showSpeakResultsView:self data:@{@"comment":self.audio_comment} resultsState:self.audio_score.intValue viewType:YES callBack:^(NSInteger index) {
                    //[MBProgressHUD hideHUD];
                    if(index == 200){//播放url声音
                        [self playAudioUrl:@""];
                    }
                    if(index == 202){//播放录音
                        [self playRecording];
                    }
                    if(index == 101){//清空录音 重置
                        [self deleteRecording];
                    }
                }];
                //====================================================================
            } else {
                //NSLog(@"---------------录音上传失败======[%@]=======",[NSString stringWithFormat:@"❌ 上传失败: %@", error.localizedDescription]);
            }
        });
    }];
    //====================================================================================
}
//取消上传,暂无用
- (void)cancelUpload {
    [[AudioManager sharedManager] cancelUploadForLetter:self.symbolTemp];
    // 隐藏上传UI
    self.uploadProgressView.hidden = YES;
}
//视频播放器的进度条滑动的时候冲突处理。  //----------------视频播放区域禁止UIScrollerView 左右滚动
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 如果是 UISlider 里的手势，就不要和 scrollView 同时识别
//    if ([otherGestureRecognizer.view isKindOfClass:[UISlider class]]) {
//        return NO;
//    }
//    return YES;
    
       UIView *view = otherGestureRecognizer.view;
      // 如果手势发生在 UISlider 或它的子视图上，就不要同时识别
      while (view) {
          if ([view isKindOfClass:[UISlider class]]) {
              return NO; // 不让 scrollView 同时响应
          }
          view = view.superview;
      } // 其他情况允许同时识别（更平滑，比如点击视频、调音量等）
      return YES;
}

//=================================================

- (void)setCardCell:(NSDictionary *)dic {
    self.dicStrokes = dic;
    self.pinyin_id = [NSString stringWithFormat:@"%@",dic[@"id"]];
    self.symbolTemp = [NSString stringWithFormat:@"%@",dic[@"symbol"]];
    if([ColorManager isOrange]){
        self.symbolTemp = self.symbolNumber;//a1 a2
    }
    self.audio_url = [NSString stringWithFormat:@"%@",dic[@"audio_url"]];
    if(self.dicStrokesTemp[@"strokes"]) {
        [self loadWritingData:self.dicStrokesTemp[@"strokes"]];
    } else {
        if(self.dicStrokes[@"learn_strokes"]){
            [self loadWritingData:self.dicStrokes[@"learn_strokes"]];
        }
    }
    self.learn_audio_url = [NSString stringWithFormat:@"%@",dic[@"learn_audio_url"]];
    self.audio_score = [NSString stringWithFormat:@"%@",dic[@"audio_score"]];
    
    NSString *sutitle = [NSString stringWithFormat:@"%@",dic[@"subtitle"]];
    if([sutitle isEqualToString:@"<null>"]){
        sutitle = @"";
    }
    self.listenViewTemp.lblPinyin.text = sutitle;
    NSString *symbol =  [NSString stringWithFormat:@"%@",dic[@"symbol"]];
    if([symbol isEqualToString:@"<null>"]){
        symbol = @"";
    }
    self.listenViewTemp.lblCardTitle.text = symbol;
    self.readTemp.lblCardTitle.text = symbol;
    

}
- (void)cardDidAppearDic:(NSDictionary *)dic {
   
    NSString *video_url = [NSString stringWithFormat:@"%@",dic[@"video_url"]];
    if (video_url.length == 0) {
        NSLog(@"❌ video_url is empty");
        return;
    }
    if(IS_Formal_Hanzi){
        [self setHanziCardCell:dic];
        NSString *gif_url = [NSString stringWithFormat:@"%@",dic[@"gif_url"]];
        self.gif_url = gif_url;
        
        [self.writeView loadGIFWithURLString:gif_url];
        [self.listenViewTemp updateMeaningViewWithText:dic];
        [self.playerViewVideo setVideoURL:[NSURL URLWithString:video_url]];
        //NSLog(@"video_url---------[%@]------------------------00------id=[%@]----------",video_url,dic[@"id"]);
    } else {
        [self setCardCell:dic];
        [self.playerViewVideo setVideoURL:[NSURL URLWithString:video_url]];
        //NSLog(@"video_url---------[%@]------------------------11--------",video_url);
    }

}
- (void)cardDidDisappear:(NSDictionary *)dic  {
    // 1. 停止 GIF 播放
    [self.listenViewTemp btnflipCardActionNo];
    if(IS_Formal_Hanzi){
        [self.writeView.gifViewTemp stopAnimating]; // SDAnimatedImageView
        //self.writeView.gifViewTemp.image = nil;     // 清掉图片
    }
       // 2. 停止视频播放
       //[self.playerViewVideo.player pause];
    AVPlayer *player = self.playerViewVideo.player;
    AVPlayerItem *item = player.currentItem;
    if (item && player.rate > 0 && item.status == AVPlayerItemStatusReadyToPlay) {
        [player pause];// 正在播放 就暂停
    }
    
       // 3. 移除 AVPlayerLayer
       if (self.playerViewVideo.playerLayer) {
           [self.playerViewVideo.playerLayer removeFromSuperlayer];
           self.playerViewVideo.playerLayer.player = nil;
           self.playerViewVideo.playerLayer = nil;
       }
    // 4. 释放播放器引用
    self.playerViewVideo.player = nil;
}
    
- (void)setHanziCardCell:(NSDictionary *)dic {
    //NSLog(@"id---------[%@]------------id----",dic[@"id"]);
    
    self.dicStrokes = dic;
    self.hanzi_id = [NSString stringWithFormat:@"%@",dic[@"id"]];
    self.audio_url = [NSString stringWithFormat:@"%@",dic[@"audio_url"]];
    self.symbolTemp = [NSString stringWithFormat:@"hanzi_%@",dic[@"id"]];//本地路径 无汉字
    self.symbolTempStr = [NSString stringWithFormat:@"%@",dic[@"hanzi"]];//
    NSString *gif_url = [NSString stringWithFormat:@"%@", dic[@"gif_url"]];
    if (gif_url.length > 6) {
        self.gif_url = gif_url;
        [self.writeView loadGIFWithURLString:gif_url];
    }
    [self.listenViewTemp updateMeaningViewWithText:dic];
    if(self.dicStrokesTemp[@"strokes"]) {
        [self loadWritingData:self.dicStrokesTemp[@"strokes"]];
    } else {
        if(self.dicStrokes[@"learn_strokes"]){
            [self loadWritingData:self.dicStrokes[@"learn_strokes"]];
        }
    }
    self.learn_audio_url = [NSString stringWithFormat:@"%@",dic[@"learn_audio_url"]];
    //NSLog(@"----------[%@]----------------------------[%@]",self.learn_audio_url,dic);
    self.audio_score = [NSString stringWithFormat:@"%@",dic[@"audio_score"]];
    self.audio_comment  = [NSString stringWithFormat:@"%@",dic[@"comment"]];
    NSString *symbol =  [NSString stringWithFormat:@"%@",dic[@"hanzi"]];
    if([symbol isEqualToString:@"<null>"]){
        symbol = @"";
    }
    self.writeView.lblCardTitle.text = symbol;
    self.listenViewTemp.lblCardTitle.text = symbol;
    self.readTemp.lblCardTitle.text = symbol;
    
    NSString *pinyin = [NSString stringWithFormat:@"%@",dic[@"pinyin"]];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:pinyin];
    [attr addAttribute:NSBaselineOffsetAttributeName value:@(5) range:NSMakeRange(0, attr.length)];
    self.listenViewTemp.lblPinyin.attributedText = attr;
    self.readTemp.lblPinyin.attributedText = attr;
    
    if(IS_Formal_Hanzi){
        //NSString *video_url = [NSString stringWithFormat:@"%@",dic[@"video_url"]];
        //[self.playerViewVideo setVideoURL:[NSURL URLWithString:video_url]];
        //NSLog(@"video_url--------333-[%@]------------------------333--------",video_url);
    }
    
}
@end
//评分 audio_score
/*
 "audio_score" = ""; //跟读声音分数
 "audio_url" = "https://testoss.shiyi-yitong.com/hanzi/audios/\U53e3.mp3";     //音频地址
 "gif_url" = "https://testoss.shiyi-yitong.com/hanzi/videos/\U53e3.gif";       //gif
 hanzi = "\U53e3";   //汉字
 id = 6;
 "learn_audio_url" = "";   已学的音频url
 "learn_strokes" = "";      书写的轨迹
 pinyin = "k\U01d2u";        //拼音
 "video_url" = "";            //视频地址
 
 "form_words" =     (
             {
         "audio_url" = "https://testoss.shiyi-yitong.com/hanzi/audios/\U4eba\U53e3.mp3"; //音频地址
         english = Population;                         对应的英文
         hanzi = "\U4eba\U53e3";                       汉字
         pinyin = "\Uff08r\U00e9n k\U01d2u\Uff09";    //拼音
     },
             {
         "audio_url" = "https://testoss.shiyi-yitong.com/hanzi/audios/\U53e3\U7f69.mp3";
         english = "Face mask";
         hanzi = "\U53e3\U7f69";
         pinyin = "\Uff08k\U01d2u zh\U00e0o\Uff09";
     }
 );

 */

