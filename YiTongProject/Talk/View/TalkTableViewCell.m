//
//  TalkTableViewCell.m
//  YiTongProject
//
//  Created by ios01 on 2026/3/2.
//

#import "TalkTableViewCell.h"
@interface TalkTableViewCell()

@property (strong, nonatomic) UIImageView *cellView;
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;


@end


@implementation TalkTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;//不能选中
        self.contentView.userInteractionEnabled = YES;
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;

        [self.contentView addSubview:self.cellView];

        self.iconView = [[UIImageView alloc]initWithFrame:CGRectMake(self.cellView.frame.size.width - 21 - 123, 12, 123, 147)];
        self.iconView.image = [UIImage imageNamed:@"take_img1"];
        [self.cellView addSubview:self.iconView];
    }
    return self;
}
- (UIImageView *)imgView {
    if(!_imgView){
        _imgView = [[UIImageView alloc]init];
        _imgView.backgroundColor = [UIColor whiteColor];
        _imgView.layer.cornerRadius = 15;//圆角
        _imgView.userInteractionEnabled = YES;
        _imgView.frame = CGRectMake(0,0,SCREEN_WIDTH - 2 * Distance＿M, 180-2);
    }
    return _imgView;
}
- (UIImageView *)cellView {
    if(!_cellView){
        _cellView = [[UIImageView alloc]initWithFrame:CGRectMake(Distance＿M, 16, SCREEN_WIDTH - 2 * Distance＿M, 180 )];
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
 

        for (int i = 0; i < 2; i++) {
            UILabel *lblTitle = [[UILabel alloc]init];
            lblTitle.frame = CGRectMake(12, 27 +  28 * i , self.cellView.frame.size.width - 123 - 25, 21 + 19 * i);
            lblTitle.textColor = BLACK_COLOR_1F;
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:20];
            lblTitle.tag = 50 + i;
            lblTitle.layer.masksToBounds = YES;
            [_cellView addSubview:lblTitle];
            //lblTitle.text = @[@"5 key sections",@"Sound like a native"][i];
        }
        
        self.lblTitle = (UILabel *)[self.cellView viewWithTag:50];
        self.lblSubtitle = (UILabel *)[self.cellView viewWithTag:51];
        self.lblTitle.text = @"Campus Life";
        self.lblSubtitle.text = @"Master high-frequency \ncampus vocabulary";
        self.lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        self.lblSubtitle.numberOfLines = 2;
        
        UIImageView *imgDetails = [[UIImageView alloc]initWithFrame:CGRectMake(12, 107, 144, 38)];
        imgDetails.image = [UIImage imageNamed:@"union_blakc"];
        [_cellView addSubview:imgDetails];
        
        for (int i = 0; i < 2; i++) {
            UILabel *lblTitle = [[UILabel alloc]init];
            lblTitle.frame = CGRectMake(106 * i, 8 , 110 - 68 * i, 22);
            lblTitle.textColor = BLACK_COLOR_1F;
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16 - i*4];
            lblTitle.tag = 150 + i;
            [imgDetails addSubview:lblTitle];
            lblTitle.textAlignment = NSTextAlignmentCenter;
            lblTitle.text = @[@"View Details",@"33%"][i];
        }
    }
    return _cellView;
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
