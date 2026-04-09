//
//  TalkCardView.m
//  YiTongProject
//
//  Created by ios01 on 2026/3/2.
//

#import "TalkCardView.h"
@interface TalkCardView()

@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;

@end
@implementation TalkCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat cardW = 260;
        self.imgView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, cardW - 20, 134)];
        self.imgView.image = [UIImage imageNamed:@"talk_default"];
        [self addSubview:self.imgView];
        
        [self addSubview:self.lblTitle];
        [self addSubview:self.lblSubtitle];
        
        self.lblTitle.text = @"Navigate Campus";
        self.lblSubtitle.text = @"New Words: 12";
  
    }
    return self;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]init];
        _lblTitle.frame = CGRectMake(10, 150, self.imgView.frame.size.width - 20, 25);
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:22];
        _lblTitle.numberOfLines = 0;
       
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]init];
        _lblSubtitle.frame = CGRectMake(self.lblTitle.frame.origin.x, 178, self.lblTitle.frame.size.width, 13);
        _lblSubtitle.textColor = BLACK_COLOR_1F;
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _lblSubtitle.numberOfLines = 0;
    }
    return _lblSubtitle;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
