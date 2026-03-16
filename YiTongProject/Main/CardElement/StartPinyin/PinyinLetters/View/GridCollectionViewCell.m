//
//  GridCollectionViewCell.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/4.
//

#import "GridCollectionViewCell.h"
@interface GridCollectionViewCell()
@end
//拼音字母表
@implementation GridCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 12;
        self.contentView.clipsToBounds = YES;
        //self.imgIcon = [[UIImageView alloc]initWithFrame:CGRectMake(self.frame.size.width - 20, 8, 12, 12)];
        //self.imgIcon.image = [UIImage imageNamed:@"audio_black"];
        [self.contentView addSubview:self.imgIcon];
        [self.contentView addSubview:self.lblTitle];
        [self.contentView addSubview:self.lblSubtitle];
        [self.contentView addSubview:self.lblAlphabet];

        AnimatedImageView *animatedImage = [[AnimatedImageView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
        animatedImage.center = CGPointMake(self.frame.size.width - 20+3, 8 + 6);
        animatedImage.image = [UIImage imageNamed:@"audio_black"];
        [self.contentView addSubview:animatedImage];
        self.animatedImage = animatedImage;
    
     
    }
    return self;
}
- (void)setCellPronunciation:(NSDictionary *)dic {
    self.backgroundColor = [self colorWithHexString:@"#FFDFE9" alpha:1];
    self.layer.borderWidth = 0;//边框
    self.lblAlphabet.text = [NSString stringWithFormat:@"%@",dic[@"label"]];
    self.lblSubtitle.text = @"";
    //NSLog(@"aaa------[%@]--------[%@]--------aaa",dic[@"label"],dic[@"symbol"]);
   
    NSString *symbol = [NSString stringWithFormat:@"%@",dic[@"symbol"]];
    NSString *soundmark = [NSString stringWithFormat:@"%@",dic[@"soundmark"]];
    if([soundmark isEqualToString:@"<null>"]){
        soundmark = @"";
    }
    NSString *content = [NSString stringWithFormat:@"%@%@",symbol,soundmark];
    NSMutableAttributedString *noteStr = [[NSMutableAttributedString alloc] initWithString:content];
    
    UIFont *symbolFont = [UIFont fontWithName:FONT_NAME_Regular size:35];
    [noteStr addAttribute:NSFontAttributeName value:symbolFont range:NSMakeRange(0,symbol.length)];
    self.lblTitle.attributedText = noteStr;
}
- (void)setCellAlphabet:(NSDictionary *)dic {
    self.layer.borderColor = [self colorWithHexString:@"#FFDFE9" alpha:1].CGColor;
    self.backgroundColor =[UIColor whiteColor];
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1;//边框

    self.lblTitle.text = @"";
    self.lblAlphabet.text = @"";
    self.lblSubtitle.text = [NSString stringWithFormat:@"%@",dic[@"symbol"]];
    //NSLog(@"ccc------[%@]--------ccc",dic[@"symbol"]);
    //-[ɑ]-    [Aɑ]
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]init];
        _lblTitle.frame = CGRectMake(5, 11, self.frame.size.width - 10, self.frame.size.height - 33);
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _lblTitle.textAlignment = NSTextAlignmentCenter;
  
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]init];
        _lblSubtitle.frame = CGRectMake(5, 18, self.frame.size.width - 10, self.frame.size.height - 36);
        _lblSubtitle.textColor = [self colorWithHexString:@"#EB658D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:32];
        _lblSubtitle.textAlignment = NSTextAlignmentCenter;
    }
    return _lblSubtitle;
}
- (UILabel *)lblAlphabet {
    if(!_lblAlphabet){
        _lblAlphabet = [[UILabel alloc]initWithFrame:CGRectMake(3, self.frame.size.height - 20,self.frame.size.width - 6, 13 - IS_OVERSEAS_VERSION * 2)];
        _lblAlphabet.textColor = [self colorWithHexString:@"#9D7C85" alpha:1];
        _lblAlphabet.font = [UIFont fontWithName:FONT_NAME_Regular size:12 - IS_OVERSEAS_VERSION * 2];
        _lblAlphabet.textAlignment = NSTextAlignmentCenter;
    }
    return _lblAlphabet;
}

- (void)btnRecordButtonAction {
    //[self startRecording];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //[self finishRecording];
        });
}
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    //CGPoint touchPoint = [gesture locationInView:self.contentView];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            // 开始动画
            [self startRecording];
            break;
            
        case UIGestureRecognizerStateChanged:
            // 检测是否滑动到取消区域
            //if (touchPoint.y < self.animationView.center.y - 50) {
                //[self.animationView showCanceling];
            //} else {
                //[self.animationView showRecording];
            //}
            break;
            
        case UIGestureRecognizerStateEnded:
            // 结束录音
            //if (touchPoint.y < self.animationView.center.y - 50) {
                //[self cancelRecording];
            //} else {
                //[self finishRecording];
            //}
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            // 取消录音
            [self cancelRecording];
            break;
            
        default:
            break;
    }
}
- (void)startRecording {
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishRecording];
        });
}
-(void)finishRecording {
    [self cancelRecording];
    NSLog(@"1播放声音已结束1");
}
- (void)cancelRecording {
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

/*/ 开始动画
- (void)startRecording {
    // 开始动画
    [self.animationView startAnimation];
    [self.animationView showRecording];

}
//录音已完成
- (void)finishRecording {
    // 显示发送状态
    [self.animationView showSending];
    //NSLog(@"录音完成，发送语音消息");
}*/
//取消录音
//- (void)cancelRecording {
//    // 停止动画
//    //[self.animationView stopAnimation];
//
//}
@end
