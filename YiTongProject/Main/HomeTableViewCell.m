//
//  HomeTableViewCell.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/3.
//

#import "HomeTableViewCell.h"

#import "GradientProgressView.h"
@interface HomeTableViewCell()

@property (strong, nonatomic) UIImageView *cellView;
@property (strong, nonatomic) UIImageView *imgArrow;
@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;
@property (strong, nonatomic) UILabel *lblRate;
@property (strong, nonatomic) GradientProgressView *progressView;

@end

@implementation HomeTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;//不能选中
        self.contentView.userInteractionEnabled = YES;
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        //[self.contentView addSubview:self.backView];
        [self.contentView addSubview:self.cellView];
        [self.contentView addSubview:self.lockView];
    }
    return self;
}
//- (UIImageView *)backView {
//    if(!_backView){
//        _backView = [[UIImageView alloc]initWithFrame:CGRectMake(Distance＿M, 8, SCREEN_WIDTH - 2 * Distance＿M, 220)];
//        _backView.clipsToBounds = YES;
//       
//    }
//    return _backView;
//}
- (UIImageView *)lockView {
    if(!_lockView){
        _lockView = [[UIImageView alloc]initWithFrame:CGRectMake(Distance＿M, 8, SCREEN_WIDTH - 2 * Distance＿M, 220)];
        _lockView.clipsToBounds = YES;
        _lockView.userInteractionEnabled = NO;
        _lockView.hidden = YES;
    
        /*UILabel *lbl = [[UILabel alloc]init];
        lbl.frame = CGRectMake(111, 92, self.cellView.frame.size.width - 183, 35);
        lbl.textColor = [self colorWithHexString:@"#63A8F5" alpha:1];
        lbl.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:30];
        lbl.text = @"Stay Tuned";
        [_lockView addSubview:lbl];

        UIImageView *imgV = [[UIImageView alloc]initWithFrame:CGRectMake(73, 92, 32, 32)];
        imgV.image = [UIImage imageNamed:@"lock_blue_1"];
        [_lockView addSubview:imgV];
        */

    }
    return _lockView;
}
- (UIImageView *)cellView {
    if(!_cellView){
        _cellView = [[UIImageView alloc]initWithFrame:CGRectMake(Distance＿M, 8, SCREEN_WIDTH - 2 * Distance＿M, 220 )];
        _cellView.userInteractionEnabled = YES;
        _cellView.layer.cornerRadius = 15;//圆角
        _cellView.layer.masksToBounds = NO; // 必须为 NO 才能显示阴影
        // 3. 设置浅灰色阴影
        _cellView.layer.shadowColor = [UIColor lightGrayColor].CGColor;
        _cellView.layer.shadowOffset = CGSizeMake(0, 1.5); // 阴影向下偏移1点
        _cellView.layer.shadowOpacity = 0.3; // 透明度（0~1）
        _cellView.layer.shadowRadius = 3.0;  // 阴影模糊半径
        // 4. 优化性能（阴影路径固定）
        _cellView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_cellView.bounds cornerRadius:_cellView.layer.cornerRadius].CGPath;

        [_cellView addSubview:self.imgView];
        [_cellView addSubview:self.imgArrow];
        [_cellView addSubview:self.lblTitle];
        [_cellView addSubview:self.lblSubtitle];
        [_cellView addSubview:self.progressView];
        
        for (int i = 0; i < 2; i++) {
            UILabel *lblTitle = [[UILabel alloc]init];
            lblTitle.frame = CGRectMake(10, self.cellView.frame.size.height - 67 + 31 * i - 0 , 114, 26);
            lblTitle.textColor = BLACK_COLOR_1F;
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
            lblTitle.layer.cornerRadius = 13;//圆角
            lblTitle.tag = 50 + i;
            lblTitle.layer.masksToBounds = YES;
            lblTitle.textAlignment = NSTextAlignmentCenter;
            lblTitle.layer.borderWidth = 1;//边框
            lblTitle.layer.borderColor = BLACK_COLOR_1F.CGColor;
            [_cellView addSubview:lblTitle];
            //lblTitle.text = @[@"5 key sections",@"Sound like a native"][i];
        }
        //BannerScrollView *bannerView = [[BannerScrollView alloc] initWithFrame:CGRectMake(10, 69, _cellView.frame.size.width - 20, 141 + heightView) bannerHeight:141 + heightView];
        float height1 = (SCREEN_WIDTH-60) * (282.0/630.0);
        BannerScrollView *bannerView = [[BannerScrollView alloc] initWithFrame:CGRectMake(10, 69, _cellView.frame.size.width - 20, height1) maxBannerHeight:height1];
        bannerView.layer.cornerRadius = 8;//圆角
        bannerView.layer.masksToBounds = YES;
        [_cellView addSubview:bannerView];
        self.bannerScrollView = bannerView;
        bannerView.didSelectItemAtIndex = ^(NSInteger index) {
            //NSLog(@"点击了第[%ld]张图片", (long)index);
            if(self.imagesArray.count > 0){
                self.selectedTypeIndex((int)index);
            }
        };
        bannerView.didUpdateBannerHeight = ^(CGFloat height) {
            //NSLog(@"Banner高度更新为: [%f]", height);
             //这里可以更新其他UI布局
        };
        // CGFloat currentHeight = bannerView.actualBannerHeight;
    }
    return _cellView;
}
- (void)setCell:(NSDictionary *)dic{
    
    self.imgView.frame = CGRectMake(self.cellView.frame.size.width - 152, 68, 142, 142);
    NSString *image_url = [NSString stringWithFormat:@"%@",dic[@"image"]];
    NSString *bg_color = [NSString stringWithFormat:@"%@",dic[@"bg_color"]];
    NSString *color_value = [NSString stringWithFormat:@"%@",dic[@"color_value"]];
    [self.imgView sd_setImageWithURL:[NSURL URLWithString:image_url]];
    self.lblTitle.text = [NSString stringWithFormat:@"%@",dic[@"title"]];
    self.lblSubtitle.text = [NSString stringWithFormat:@"%@",dic[@"subtitle"]];
    self.cellView.backgroundColor = [self colorWithHexString:bg_color alpha:1];

    NSArray *imagesArray = nil;
    if ([dic[@"images"] isKindOfClass:[NSArray class]]) {
        imagesArray = [NSArray arrayWithArray:dic[@"images"]];
    }
    self.imagesArray = imagesArray;
    BOOL isBanner = imagesArray.count > 0 ? YES:NO;
    self.lblTitle.frame = CGRectMake(10, 64 - 54 * isBanner , SCREEN_WIDTH - 2 * Distance＿X - 20, 23);
    self.lblSubtitle.frame = CGRectMake(self.lblTitle.frame.origin.x, self.lblTitle.frame.origin.y + self.lblTitle.frame.size.height + 8, self.cellView.frame.size.width - 170 + 150 * isBanner, 42 - 26 * isBanner);

    self.progressView.hidden = isBanner;
    self.imgView.hidden = isBanner;
    self.bannerScrollView.hidden = !isBanner;
    //self.bannerScrollView.tap.enabled = NO;

    if(isBanner){
        NSArray *imgArray = [imagesArray valueForKey:@"img"];
        NSUInteger count = MIN(imgArray.count, 6);
        NSArray *firstFive = [imgArray subarrayWithRange:NSMakeRange(0, count)];
        self.bannerScrollView.imageUrls = firstFive;
        //self.bannerScrollView.tap.enabled = YES;
    } else {
        NSString *learn_rate = [NSString stringWithFormat:@"%@",dic[@"learn_rate"]];
        self.lblRate.text = [NSString stringWithFormat:@"%.0lf%@",learn_rate.floatValue * 100,@"%"];
        [self.progressView setProgress:learn_rate.floatValue animated:YES color:@[bg_color,color_value]];
        BOOL isRate = learn_rate.doubleValue > 0 ? YES:NO;
        self.progressView.layer.borderWidth = isRate;//边框
        
        if(isRate){
            self.progressView.layer.cornerRadius = 19.0;//圆角
            self.progressView.layer.borderColor = BLACK_COLOR_1F.CGColor;
        } else {
            [self.progressView addDashedBorderWithColor:[self colorWithHexString:@"#BABACC" alpha:1]
                                   lineWidth:1.0
                                 dashPattern:@[@3, @3]  // 5像素实线 + 3像素空白
                                 cornerRadius:19.0];
        }
        for (int i = 0; i < 2; i++) {
            UILabel *lblTitle = (UILabel *)[self.progressView viewWithTag:60 + i];
            lblTitle.textColor = [theAppDelegate.window colorWithHexString:@[@"#BABACC",@"#1F1F39"][isRate] alpha:1];
        }
    }
    
    //self.backView.frame = CGRectMake(12, 2, SCREEN_WIDTH - 2 * 12, 220 + heightView * isBanner + 12);
    /*int heightView = 30;
    self.cellView.frame = CGRectMake(Distance＿M, 8, SCREEN_WIDTH - 2 * Distance＿M, 220 + heightView * isBanner);
    self.lockView.frame = CGRectMake(11, 8 - 6, SCREEN_WIDTH - 2 * 11, 220 + heightView * isBanner + 16 + 12);
    [self setFrame:CGRectMake(0,0,SCREEN_WIDTH, 236 + heightView * isBanner)];*/
    
    float height1 = (SCREEN_WIDTH-60) * (282.0/630.0);
    self.cellView.frame = CGRectMake(Distance＿M, 8, SCREEN_WIDTH - 2 * Distance＿M, (79 + height1 - 220) * isBanner + 220);
    self.lockView.frame = CGRectMake(11, 8 - 6, SCREEN_WIDTH - 2 * 11, self.cellView.frame.size.height + 16 + 12);
    [self setFrame:CGRectMake(0,0,SCREEN_WIDTH, self.cellView.frame.size.height + 16)];
    
    NSString *label1 = [NSString stringWithFormat:@"%@",dic[@"label1"]];
    NSString *label2 = [NSString stringWithFormat:@"%@",dic[@"label2"]];
    for (int i = 0; i < 2; i++) {
        UILabel *lblTitle = (UILabel *)[self.cellView viewWithTag:50 + i];
        lblTitle.hidden = isBanner;
        lblTitle.text = @[label1,label2][i];
        if(isBanner==NO){
            lblTitle.hidden = [lblTitle.text isEqualToString:@"<null>"]?YES:NO;
        }
        CGSize labelSize = [lblTitle sizeThatFits:CGSizeMake(MAXFLOAT,26)];
        lblTitle.frame = CGRectMake(10, self.cellView.frame.size.height - 67 + 31 * i , labelSize.width + 20, 26);
    }
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]init];
        //_lblTitle.frame = CGRectMake(10, 10 + 54 , SCREEN_WIDTH - 2 * Distance＿X - 113, 23);
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]init];
        //_lblSubtitle.frame = CGRectMake(self.lblTitle.frame.origin.x, self.lblTitle.frame.origin.y + self.lblTitle.frame.size.height + 8, self.cellView.frame.size.width - 170, 32+10);
        _lblSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:SCREEN_WIDTH < 390 ? 13 : 14];
        _lblSubtitle.numberOfLines = 2;
    }
    return _lblSubtitle;
}
- (GradientProgressView *)progressView {
    if(!_progressView){
        _progressView = [[GradientProgressView alloc]initWithFrame:CGRectMake(10, 8, _cellView.frame.size.width - 62, 38)];
        _progressView.layer.masksToBounds = YES;
        _progressView.clipsToBounds = YES;
        _progressView.backgroundColor = [UIColor clearColor];
        
        NSString *learning = NSLocalizedString(@"Learning Progress",@"");
        for (int i = 0; i < 2; i++) {
            UILabel *lblTitle = [[UILabel alloc]init];
            lblTitle.frame = CGRectMake(16 + (_progressView.frame.size.width - 32 - 200) * i, 8, 200, 22);
            lblTitle.tag =  60 + i;
            lblTitle.textColor = BLACK_COLOR_1F;
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14 + 6*i];
            [_progressView addSubview:lblTitle];
            lblTitle.text = @[learning,@"0%"][i];
            if(i==1){
                lblTitle.textAlignment = NSTextAlignmentRight;
                self.lblRate = lblTitle;
            }
        }
    }
    return _progressView;
}
- (UIImageView *)imgArrow {
    if(!_imgArrow){
        _imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(self.cellView.frame.size.width-48, 10, 38, 38)];
        _imgArrow.image = [UIImage imageNamed:@"button_arrow"];
    }
    return _imgArrow;
}

- (UIImageView *)imgView {
    if(!_imgView){
        _imgView = [[UIImageView alloc]init];
    }
    return _imgView;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}
@end

