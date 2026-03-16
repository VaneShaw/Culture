//
//  SpeakResultsView.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/18.
//

#import "SpeakResultsView.h"
#import "AnimatedImageView.h"
//#import "VoiceAnimationView.h"

@interface SpeakResultsView()
@property (nonatomic, strong) UIView *viewSpeakResults;
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) AnimatedImageView *animatedImage;
@property (nonatomic, strong) NSTimer *audioSimulationTimer;
@property (nonatomic, strong) UILabel *lblStandard;
@property (nonatomic, strong) UILabel *lblVoice;
@property (nonatomic, strong) AnimatedImageView *animatedImageLeft;
@property (nonatomic, strong) AnimatedImageView *animatedImageRight;

@property (nonatomic, strong) NSString *themeColor;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation SpeakResultsView

- (instancetype)initWithFrame:(CGRect)frame showSpeakResultsView:(UIView *)resultsView data:(NSDictionary *)dicData  resultsState:(int)state viewType:(BOOL)isSpeak callBack:(void(^)(NSInteger index))callBack {
    frame = [UIScreen mainScreen].bounds;
    if (self = [super initWithFrame:frame]) {

        [self setSelectedTypeIndex:^(NSInteger index) {
            if (callBack) {
                callBack(index);
            }
        }];
        [self addSpeakResultsView:resultsView  data:dicData resultsState:state viewType:isSpeak];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(handlePlayFinished:)
                                                   name:@"AudioPlayDidFinishNotification"
                                                 object:nil];
    }
    return self;
}
- (void)tapAction {
    [self hidden];
}
+ (void)showSpeakResultsView:(UIView *)resultsView data:(NSDictionary *)dicData resultsState:(int)state viewType:(BOOL)isSpeak callBack:(void(^)(NSInteger index))callBack {
    int width = Card_WIDTH;
    int height = Card_Height;
    SpeakResultsView *pleasefoView = [[SpeakResultsView alloc] initWithFrame:CGRectMake(0,0, width, height) showSpeakResultsView:resultsView data:dicData resultsState:state viewType:isSpeak callBack:callBack];
    pleasefoView.tag = 955;
    pleasefoView.backgroundColor = [UIColor clearColor];
    [resultsView addSubview:pleasefoView];
    pleasefoView.viewSpeakResults.backgroundColor = [UIColor whiteColor];
}
- (void)addSpeakResultsView:(UIView *)resultsView data:(NSDictionary *)dicData resultsState:(int)state viewType:(BOOL)isSpeak {

    int width = Card_WIDTH;
    int height = Card_Height;

    _viewSpeakResults = [[UIView alloc]initWithFrame:self.bounds];
    _viewSpeakResults.backgroundColor = [UIColor whiteColor];
    _viewSpeakResults.clipsToBounds = YES;
    [self addSubview:_viewSpeakResults];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [_viewSpeakResults addGestureRecognizer:tap];
    [tap addTarget:self action:@selector(tapAction)];
    
    UIImageView *imgPerfect = [[UIImageView alloc]init];
    [_viewSpeakResults addSubview:imgPerfect];

    NSString *string = [NSString stringWithFormat:@"speak_results_%d_%@",state,Language_Type];
    UIImage *image = [UIImage imageNamed:string];
    imgPerfect.frame = CGRectMake((width - image.size.width)/2, 75 + 26 * IS_Formal_Screen, image.size.width, image.size.height);
    imgPerfect.image = image;
    int type = SCREEN_HEIGHT < Small_Screen ? 0 : 1;
    //int yTemp = 60 * type;
    int yTemp = 80 + 40 * IS_Formal_Screen;
    if(IS_Formal_Hanzi){
        NSString *comment = [NSString stringWithFormat:@"%@",dicData[@"comment"]];
        if(!comment || [comment isEqualToString:@"(null)"]){
            comment = @"";
        }
        
        UILabel *lblComment = [[UILabel alloc]initWithFrame:CGRectMake(22, imgPerfect.frame.origin.y + imgPerfect.frame.size.height + 10 * IS_Formal_Screen, width-44, 65 + type * 20)];
        lblComment.text = comment;
        lblComment.numberOfLines = 0;
        lblComment.textAlignment = NSTextAlignmentCenter;
        lblComment.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        lblComment.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        [_viewSpeakResults addSubview:lblComment];
        CGSize labelSize = [lblComment sizeThatFits:CGSizeMake(width - 44,MAXFLOAT)];
        CGRect frame = lblComment.frame;
        frame.size.height = MIN(labelSize.height+2, 65 + type * 20); // 限制最大高度
        lblComment.frame = frame;
    }

    if(!isSpeak){//书写模块
        UIButton *btnReset = [UIButton buttonWithType:UIButtonTypeCustom];
        //btnReset.frame = CGRectMake((width - 74)/2,height - 55 - 5 - yTemp, 74, 50);
        btnReset.frame = CGRectMake((width - 74)/2,imgPerfect.frame.origin.y + imgPerfect.frame.size.height + 46, 74, 50);
        [_viewSpeakResults addSubview:btnReset];
        //self.btnReset = btnReset;
        [btnReset addTarget:self action:@selector(btnResetAction:) forControlEvents:UIControlEventTouchUpInside];
        
        NSString *currentKey = [ColorManager currentColorKey];
        NSString *rewrite = [NSString stringWithFormat:@"rewrite_%@",currentKey];
        UIImage *backgroundImage = [UIImage imageNamed:rewrite];
        [btnReset setBackgroundImage:backgroundImage forState:UIControlStateNormal];
      
    } else {
        for (int i = 0; i < 3; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            if(i==1){
                btn.frame = CGRectMake((width - 3 * 89)/2 + 89* i + 45/2, height - 0 - 8 - yTemp, 48, 60);
                btn.tag = 201;
                [btn addTarget:self action:@selector(btnResetAction:) forControlEvents:UIControlEventTouchUpInside];
                [_viewSpeakResults addSubview:btn];
                
            } else {
                
                btn.tag = 200 + i;
                btn.frame = CGRectMake((width - 3 * 89)/2 + 89* i, height - 0 - yTemp, 89, 44);
                UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(22, 0, 89-22, 32)];
                lblTitle.tag = 230 + i;
                NSString *title = @[@"Standard",@"",@"My Voice"][i];
                title = NSLocalizedString(title,@"");
                lblTitle.text = title;
                lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
                lblTitle.textAlignment = NSTextAlignmentCenter;
                lblTitle.textColor = GARY_COLOR_63;
                [btn addSubview:lblTitle];
                [btn addTarget:self action:@selector(btnStandardAction:) forControlEvents:UIControlEventTouchUpInside];
                
                //UIImageView *imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 12, 12)];
                //imgArrow.tag = 300 + i;
                //[btn addSubview:imgArrow];
                [_viewSpeakResults addSubview:btn];
                
                AnimatedImageView *animatedImage = [[AnimatedImageView alloc] initWithFrame:CGRectMake(8, 9, 14, 14)];
                animatedImage.image = [self imageWithImageName:@"sound_wave_blue" tintColor:GARY_COLOR_63];
                animatedImage.tag = 300 + i;
                [btn addSubview:animatedImage];
            }
    
            self.lblStandard= (UILabel *)[_viewSpeakResults viewWithTag:230];
            self.lblVoice = (UILabel *)[_viewSpeakResults viewWithTag:232];
            self.animatedImageLeft = (AnimatedImageView *)[_viewSpeakResults viewWithTag:300];
            self.animatedImageRight = (AnimatedImageView *)[_viewSpeakResults viewWithTag:302];
            
            NSString *currentKey = [ColorManager currentColorKey];
            if([currentKey isEqualToString:@"green"]){
                currentKey = [NSString stringWithFormat:@"%@_00",currentKey];
            }
            ColorItem *blue = [ColorManager itemForKey:currentKey];//#00C0A8
            NSArray *colorArray = blue.colors;
            if(colorArray.count == 2){
                self.themeColor = colorArray[0];
            }
            NSString *xbutton = [NSString stringWithFormat:@"button_%@",currentKey];
            NSString *replay = [NSString stringWithFormat:@"replay_%@",currentKey];

            UIImage *backgroundImage = [UIImage imageNamed:@[xbutton,replay,xbutton][i]];
            [btn setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        }
    }
    //self.selectedTypeIndex(1);
}
//================================================
- (void)startAnimation {
    [self.animatedImage startAnimation];
    // 开始模拟音频变化
    if (self.audioSimulationTimer) {
        [self.audioSimulationTimer invalidate];
    }
    self.audioSimulationTimer = [NSTimer scheduledTimerWithTimeInterval:0.15
                                                           target:self
                                                         selector:@selector(updateAudioSimulation)
                                                         userInfo:nil
                                                          repeats:YES];
}
- (void)stopAnimation {
    [self.animatedImage stopAnimation];
    // 停止模拟音频变化
    [self.audioSimulationTimer invalidate];
    self.audioSimulationTimer = nil;
    

}
- (void)updateAudioSimulation {
    // 随机生成音频级别变化
    CGFloat randomValue = (arc4random_uniform(60) + 20) / 100.0;
    [self.animatedImage setAudioLevel:randomValue];
}
//================================================

- (void)btnStandardAction:(UIButton *)sender {
    int tag = (int)sender.tag - 200;
    for (int i = 0; i < 2; i++) {
        UIButton *btn = (UIButton *)[self.viewSpeakResults viewWithTag:200 + i*2];
        UILabel *lblTitle = (UILabel *)[btn viewWithTag:230 + i*2];
        AnimatedImageView *animatedImage = (AnimatedImageView *)[btn viewWithTag:300 + i*2];
        if(i*2 == tag){
            lblTitle.textColor = [self colorWithHexString:self.themeColor alpha:1];
            NSString *currentKey = [ColorManager currentColorKey];
            animatedImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"sound_wave_%@",currentKey]];
        } else {
            lblTitle.textColor = [self colorWithHexString:@"#C2C3C3" alpha:1];
            animatedImage.image = [self imageWithImageName:@"sound_wave_blue" tintColor:[self colorWithHexString:@"#C2C3C3" alpha:1]];
        }
    }
    
    self.selectedTypeIndex(sender.tag);
    [self stopAnimation];
    self.animatedImage = (AnimatedImageView *)[sender viewWithTag:sender.tag + 100];
    [self startAnimation];
}
- (void)handlePlayFinished:(NSNotification *)notification {
    BOOL isFinished = [notification.userInfo[@"status"] boolValue];
    if (isFinished) {
        [self stopAnimation]; // 停止动画

            self.animatedImageLeft.image = [self imageWithImageName:@"sound_wave_blue" tintColor:GARY_COLOR_63];
            self.animatedImageRight.image = [self imageWithImageName:@"sound_wave_blue" tintColor:GARY_COLOR_63];
            self.lblStandard.textColor = GARY_COLOR_63;
            self.lblVoice.textColor = GARY_COLOR_63;
        
    }
}
- (void)btnResetAction:(UIButton *)sender {
    self.selectedTypeIndex(101);
    [self hidden];
}
- (void)hidden{
    [self stopAnimation];
    __weak typeof(self) weakSelf=self;
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.viewSpeakResults.alpha = 1;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}

@end

