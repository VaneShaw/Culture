//
//  CardTipsView.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/28.
//

#import "CardTipsView.h"
@interface CardTipsView ()

@end

@implementation CardTipsView
@synthesize lblCardTitle = _lblCardTitle;
@synthesize lblCardSubtitle = _lblCardSubtitle;
@synthesize toneView = _toneView;
@synthesize lblTone = _lblTone;
@synthesize btnPlay = _btnPlay;
//@synthesize lblPinyin = _lblPinyin;
//@synthesize btnNext = _btnNext;

- (instancetype)initWithTypeStyle:(TipsLayoutStyle)style {
    if (self = [super initWithTypeStyle:style]) {
        // ✅ 在这里可以添加子类独有的 UI
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;
        self.clipsToBounds = YES;
       [self setupViews];
    }
    return self;
}
- (void)setupViews {
    // Title
    [self addSubview:self.lblCardTitle];
    [self addSubview:self.lblCardSubtitle];
    [self addSubview:self.btnPlay];
    [self addSubview:self.toneView];
    self.toneView.hidden = ![ColorManager isOrange];
    
    for (int i = 0; i < 2; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake((Card_WIDTH - 20 - 74 * 2)/2 +  94 * i, Card_Height - 50 - 6*IS_Formal_Screen, 74, 50);
        btn.layer.masksToBounds = YES;
        btn.tag = 135 + i;
        btn.hidden = YES;
        [self addSubview:btn];
    }
    
}
- (UILabel *)lblCardTitle {
    if(!_lblCardTitle){
        _lblCardTitle = [[UILabel alloc]init];
        _lblCardTitle.textAlignment = NSTextAlignmentCenter;
    }
    return _lblCardTitle;
}
- (UILabel *)lblCardSubtitle {
    if(!_lblCardSubtitle){
        _lblCardSubtitle = [[UILabel alloc]init];
        
        int margin = Distance＿X;
        int y = Card_Height * 0.63;
        _lblCardSubtitle.frame = CGRectMake(margin, y, Card_WIDTH - 2 * margin, Card_Height - y - 60);
        _lblCardSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _lblCardSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        _lblCardSubtitle.numberOfLines = 0;
        _lblCardSubtitle.textAlignment = NSTextAlignmentCenter;
    }
    return _lblCardSubtitle;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
//    for (int i = 0; i < 2; i++) {
//        UIButton *btn = (UIButton *)[self viewWithTag:135+i];
//        btn.hidden = YES;
//    }
    
    switch (self.style) {
        case TipsLayoutStyleListen: {
            // 布局方案 A
            BOOL isPurple = [ColorManager isPurple];
            self.lblCardTitle.textColor = BLACK_COLOR_1F;
            if([ColorManager isPurpleOrOrange]){
                self.lblCardTitle.frame = CGRectMake(0, 69, Card_WIDTH, 164);
                self.lblCardTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:130 - isPurple * 10];
            } else {
                int height = SCREEN_WIDTH > 395 ? Card_Height * 0.26 : 70;
                height = Card_Height * 0.29;
                if(height>135){
                    height = 132;
                }
                //方案一3 frame
                self.lblCardTitle.frame = CGRectMake(0, 0,Card_WIDTH,height);
                self.lblCardTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:60 + 30];
            }
            break;
        }
        case TipsLayoutStyleRead: {
            
            NSString *currentKey = [ColorManager currentColorKey];
            ColorItem *blue = [ColorManager itemForKey:currentKey];
            NSArray *colorArray = blue.colors;
            NSString *strColor;
            if(colorArray.count == 2){
                strColor = colorArray[0];
            }
            self.lblCardTitle.textColor = [self colorWithHexString:strColor alpha:1];
            //布局方案B
            BOOL isPurple = [ColorManager isPurple];
            self.lblCardTitle.frame = CGRectMake(0, 60, Card_WIDTH, 164 + 18);
            self.lblCardTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:130 - isPurple * 10];
            self.lblCardSubtitle.text = NSLocalizedString(@"Tap to start recording and say this sound out loud",@"");
            
            break;
        }
        case TipsLayoutStyleWrite: {
            self.btnNext.hidden = YES;
            self.lblCardSubtitle.hidden = YES;
            self.btnPlay.hidden = YES;
            break;
        }
    }
}
- (UIView *)toneView {
    if(!_toneView){
        _toneView = [UIView new];
        _toneView.frame = CGRectMake(-12, -12, 72 - 10 * IS_OVERSEAS_VERSION + 12, 28+12);
        _toneView.backgroundColor =  [self colorWithHexString:@"#FFF3D9" alpha:1];
        _toneView.layer.cornerRadius = 12;
        _toneView.layer.masksToBounds = YES;
        _toneView.clipsToBounds = YES;
        [_toneView addSubview:self.lblTone];
    }
    return _toneView;
}
- (UILabel *)lblTone {
    if(!_lblTone){
        _lblTone = [[UILabel alloc]initWithFrame:CGRectMake(12, 12, 72 - 10 * IS_OVERSEAS_VERSION , 28)];
        _lblTone.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _lblTone.textColor = [self colorWithHexString:@"#F89F1E" alpha:1];
        _lblTone.textAlignment = NSTextAlignmentCenter;
    }
    return _lblTone;
}

//=================================================================
- (UIPlayButton *)btnPlay {
    if(!_btnPlay){
        
        NSString *currentKey = [ColorManager currentColorKey];
        NSString *xbutton = [NSString stringWithFormat:@"button_bg_%@",currentKey];
        UIImage *bg = [UIImage imageNamed:xbutton];//@"button_white"
        UIImage *normal = [UIImage imageNamed:[NSString stringWithFormat:@"started_%@",currentKey]];
        UIImage *playing = [UIImage imageNamed:[NSString stringWithFormat:@"sound_wave_%@",currentKey]];
        _btnPlay = [[UIPlayButton alloc] initWithFrame:CGRectMake((Card_WIDTH - 74)/2, Card_Height - 50 - 6*IS_Formal_Screen, 74, 50) backgroundImage:bg normalImage:normal playingImage:playing];
        
        // 调整动画速度（越大越慢）
        _btnPlay.animationDuration = 0.4;
    }
    return _btnPlay;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

