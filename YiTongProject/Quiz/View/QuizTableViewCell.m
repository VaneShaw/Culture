//
//  QuizTableViewCell.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/30.
//

#import "QuizTableViewCell.h"
@interface QuizTableViewCell()

@property (strong, nonatomic) UIView *cellView;
@property (strong, nonatomic) UIImageView *imgButton;
@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) UIImageView *imgTap;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;
@property (strong, nonatomic) UILabel *lblRate;


@end
@implementation QuizTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;//不能选中
        self.contentView.userInteractionEnabled = YES;
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        [self.contentView addSubview:self.cellView];
    }
    return self;
}
- (UIView *)cellView {
    if(!_cellView){
        _cellView = [[UIView alloc]initWithFrame:CGRectMake(Distance＿M, 8, SCREEN_WIDTH - 2 * Distance＿M, 230 + 30 * IS_OVERSEAS_VERSION )];//上架必备
        _cellView.userInteractionEnabled = YES;
        _cellView.layer.cornerRadius = 12;//圆角
        _cellView.layer.masksToBounds = NO; // 必须为 NO 才能显示阴影
        // 3. 设置浅灰色阴影
        _cellView.layer.shadowColor = [UIColor lightGrayColor].CGColor;
        _cellView.layer.shadowOffset = CGSizeMake(0, 1.5); // 阴影向下偏移1点
        _cellView.layer.shadowOpacity = 0.3; // 透明度（0~1）
        _cellView.layer.shadowRadius = 3.0;  // 阴影模糊半径
        // 4. 优化性能（阴影路径固定）
        _cellView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_cellView.bounds cornerRadius:_cellView.layer.cornerRadius].CGPath;

        [_cellView addSubview:self.imgTap];
        [_cellView addSubview:self.imgView];
        [_cellView addSubview:self.imgButton];
        [_cellView addSubview:self.lblTitle];
        [_cellView addSubview:self.lblSubtitle];
   
        //_cellView.backgroundColor = [self colorWithHexString:@"#FFF3D9" alpha:1];
        //self.lblTitle.text = @"Pinyin Practice";
        //self.lblSubtitle.text = @"Let’s see how well you’ve learned!";
    }
    return _cellView;
}
- (void)setCell:(NSDictionary *)dic index:(int)index {
    
    NSString *bg_color = [NSString stringWithFormat:@"%@",dic[@"bg_color"]];
    self.cellView.backgroundColor = [self colorWithHexString:bg_color alpha:1];
    self.imgButton.image = [UIImage imageNamed:[NSString stringWithFormat:@"quiz_button_0_%@",Language_Type]];
    
    NSString *label_image = [NSString stringWithFormat:@"%@",dic[@"label_image"]];
    __weak typeof(self) weakSelf = self;
    [self.imgTap sd_setImageWithURL:[NSURL URLWithString:label_image]
                   placeholderImage:nil
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (image) {
            // 获取图片实际宽高比
            int imgWidth = image.size.width/2;
            int imgHeight = image.size.height/2;
            //CGFloat aspectRatio = image.size.width / image.size.height;
            weakSelf.imgTap.frame = CGRectMake(48 - 37*(index%2), 16 , imgWidth, imgHeight);
            
            self.lblTitle.text = [NSString stringWithFormat:@"%@",dic[@"title"]];
            self.lblSubtitle.text = [NSString stringWithFormat:@"%@",dic[@"subtitle"]];
            CGSize labelSize0 = [self.lblTitle sizeThatFits:CGSizeMake(self.cellView.frame.size.width - 158,MAXFLOAT)];
            CGSize labelSize1 = [self.lblSubtitle sizeThatFits:CGSizeMake(self.cellView.frame.size.width - 158,MAXFLOAT)];
            int y = self.imgTap.frame.origin.y + self.imgTap.frame.size.height - 5;//55
            self.lblTitle.frame = CGRectMake(12, y, self.cellView.frame.size.width - 158, labelSize0.height + 2);
            self.lblSubtitle.frame = CGRectMake(self.lblTitle.frame.origin.x, self.lblTitle.frame.origin.y + self.lblTitle.frame.size.height + 8 + 0, self.lblTitle.frame.size.width, labelSize1.height + 2);
            self.imgButton.frame = CGRectMake(14, self.lblSubtitle.frame.origin.y + self.lblSubtitle.frame.size.height + 20, 144, 38);
            
            int height = self.imgButton.frame.origin.y + self.imgButton.frame.size.height + 18;
            //NSLog(@"height------[%d]",height);
            //int height2 = imgHeight + 20;
        }
    }];
    
    NSString *image_url = [NSString stringWithFormat:@"%@",dic[@"image"]];
    [self.imgView sd_setImageWithURL:[NSURL URLWithString:image_url]
                   placeholderImage:nil
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (image) {
            // 获取图片实际宽高比
            //CGFloat aspectRatio = image.size.width/image.size.height;
            int imgWidth = image.size.width/2;
            int imgHeight = image.size.height/2;
            weakSelf.imgView.frame = CGRectMake(weakSelf.cellView.frame.size.width - 12 - imgWidth, (weakSelf.cellView.frame.size.height - imgHeight)/2, imgWidth, imgHeight);
        }
    }];
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]init];
        _lblTitle.frame = CGRectMake(11, 55, self.cellView.frame.size.width - 158 , 100);
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:26 + 8 * IS_OVERSEAS_VERSION];
        _lblTitle.numberOfLines = 0;
        //_lblTitle.backgroundColor = [UIColor orangeColor];
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]init];
        _lblSubtitle.frame = CGRectMake(self.lblTitle.frame.origin.x, self.lblTitle.frame.origin.y + self.lblTitle.frame.size.height + 8, self.lblTitle.frame.size.width, 32+10);
        _lblSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _lblSubtitle.numberOfLines = 0;
    }
    return _lblSubtitle;
}
- (UIImageView *)imgButton {
    if(!_imgButton){
        _imgButton = [[UIImageView alloc]initWithFrame:CGRectMake(14, self.cellView.frame.size.height - 38 - 22, 144, 38)];
    }
    return _imgButton;
}
- (UIImageView *)imgTap {
    if(!_imgTap){
        _imgTap = [[UIImageView alloc]init];
    }
    return _imgTap;
}
- (UIImageView *)imgView {
    if(!_imgView){
        _imgView = [[UIImageView alloc]init];
        //_imgView.frame = CGRectMake(11, 22, self.cellView.frame.size.width - 22, 193);
        //_imgView.frame = CGRectMake(self.cellView.frame.size.width - 323 -14, 22, 323, 213);
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
