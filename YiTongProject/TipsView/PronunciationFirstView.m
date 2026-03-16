//
//  PronunciationFirstView.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/7.
//

#import "PronunciationFirstView.h"
#import <FLAnimatedImage/FLAnimatedImage.h>
@interface PronunciationFirstView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *imgCode;
@property (nonatomic, strong) UIView *contentView;
//@property (nonatomic, assign) BOOL isQuitNow;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation PronunciationFirstView
//游戏动画教程
- (instancetype)initWithFrame:(CGRect)frame showViewTitle:(NSString *)title buttonFrame:(CGRect)frame2  callBack:(void(^)(NSInteger index))callBack {
    frame = [UIScreen mainScreen].bounds;
    if (self = [super initWithFrame:frame]) {
        __weak typeof(self) weakSelf = self;
        [self setSelectedTypeIndex:^(NSInteger index) {
            if (callBack) {
                callBack(index);
            }
            [weakSelf hidden];
        }];
        //self.isQuitNow = title.boolValue;
        _bkView = [[UIView alloc] initWithFrame:frame];
        //_bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        [self addSubview:_bkView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [_bkView addGestureRecognizer:tap];
        [tap addTarget:self action:@selector(tapAction)];
        [self addContentView:title buttonFrame:frame2];
    }
    return self;  
}
- (void)tapAction {
    [self hidden];
}
+ (void)showViewTitle:(NSString *)title buttonFrame:(CGRect)frame2 callBack:(void(^)(NSInteger index))callBack {
    PronunciationFirstView *pleasefoView = [[PronunciationFirstView alloc] initWithFrame:CGRectZero showViewTitle:title buttonFrame:frame2 callBack:callBack];
    pleasefoView.tag = 855 + title.boolValue;
     UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [window addSubview:pleasefoView];
    
    [UIView animateWithDuration:0.25 animations:^{
        pleasefoView.bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        //pleasefoView.bkView.backgroundColor = [UIColor clearColor];
        pleasefoView.contentView.alpha = 1;
    }];
}
- (void)addContentView:(NSString *)title buttonFrame:(CGRect)frame2 {
    int width = SCREEN_WIDTH;
    int headerHeight = 550;
    _contentView = [[UIView alloc]initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - headerHeight)/2, SCREEN_WIDTH, headerHeight)];
    _contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:_contentView];
    
    UIColor *blueColor = [self colorWithHexString:@"#63A8F5" alpha:1];
    int diameterRound = 88;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    button.frame = frame2;
    button.layer.cornerRadius = frame2.size.width/2;
    button.layer.borderWidth = 2;
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    if(title.intValue == 1){
        [button setImage:[UIImage imageNamed:@"audio_white"] forState:UIControlStateNormal];
    } else {
        button.tintColor = [UIColor whiteColor];
        button.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:36];
        [button setTitle:title forState:UIControlStateNormal];
    }
    button.backgroundColor = blueColor;
    button.layer.masksToBounds = YES;
    [button addTarget:self action:@selector(btn123Action:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:button];
    //button.frame = CGRectMake(SCREEN_WIDTH/2-diameterRound/2, headerHeight/2-diameterRound/2, diameterRound, diameterRound);

    NSString *gifPath = [[NSBundle mainBundle] pathForResource:@"chick_white" ofType:@"gif"];
    if (!gifPath) {
        NSLog(@"文件未找到或 Bundle 路径无效--"); // 检查文件是否存在
    }
    NSData *gifData = [NSData dataWithContentsOfFile:gifPath];
    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:gifData];
    FLAnimatedImageView *animatedImageView = [[FLAnimatedImageView alloc] init];
    animatedImageView.animatedImage = animatedImage;
    animatedImageView.frame  = CGRectMake(button.frame.origin.x + 2, button.frame.origin.y + 6, 148, 148);
    [_contentView addSubview:animatedImageView];
    int tempX = button.frame.origin.x;
    if(tempX >= SCREEN_WIDTH/2) {
        tempX = SCREEN_WIDTH/2 - 50;
    }
    
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(tempX, button.frame.origin.y + 50 + diameterRound, width - tempX, 60)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
    lblTitle.textColor = [UIColor whiteColor];
    lblTitle.numberOfLines = 2;
    //lblTitle.text = NSLocalizedString(@"Tap any audio button\n to hear a pronunciation", @"");

    NSString *first_key = [KUSER_DEFAULT objectForKey:@"first_key"];
    if([first_key isEqualToString:@"is_pinyin"]){
        
        if([title isEqualToString:@"1"]){
            lblTitle.text = NSLocalizedString(@"Tap the audio button to hear the pronunciation first", @"");
        } else {
            lblTitle.text = NSLocalizedString(@"Now choose the answer that matches the sound", @"");
        }
        
    } else {
        
        if([title isEqualToString:@"1"]){
            lblTitle.text = NSLocalizedString(@"Tap any audio button to hear a pronunciation", @"");
        } else {
            lblTitle.text = NSLocalizedString(@"After listening, tap the answer that matches the sound", @"");
        }
        
    }
    [_contentView addSubview:lblTitle];
}
- (void)btn123Action:(UIButton *)sender {
    self.selectedTypeIndex(101);
}
- (void)hidden{
    __weak typeof(self) weakSelf=self;
    [UIView animateWithDuration:0.25 animations:^{
        //weakSelf.bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0];
        weakSelf.contentView.alpha = 0;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}
@end
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

