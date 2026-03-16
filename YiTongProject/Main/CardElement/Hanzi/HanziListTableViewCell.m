//
//  HanziListTableViewCell.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/19.
//

#import "HanziListTableViewCell.h"

@interface HanziListTableViewCell()
@property (strong, nonatomic) UIImageView *cellView1;
@property (strong, nonatomic) UIView *cellView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;

@property (assign, nonatomic) int cellDistance;
@property (assign, nonatomic) int labelWidth;//田子格 宽
@property (assign, nonatomic) int distanceWight;//田子格 宽
@property (assign, nonatomic) int distanceHeight;//田子格 宽
@property (strong, nonatomic) CellCoverView *cover;

@property (assign, nonatomic) int countAll;
@property (assign, nonatomic) NSInteger maxIsCount;
@end

@implementation HanziListTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //self.countAll = 5;
        self.countAll = (int)[KUSER_DEFAULT integerForKey:@"maxIsCount_key"];
//        if(self.maxIsCount > self.countAll){
//            self.countAll = (int)self.maxIsCount;
//        }
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;//不能选中
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        self.contentView.userInteractionEnabled = YES;
        self.cellDistance = 12;
        [self.contentView addSubview:self.cellView1];
        [self.contentView addSubview:self.cellView];
        
        CellCoverView *cover = [[CellCoverView alloc] initWithFrame:self.contentView.bounds title:NSLocalizedString(@"Unlock the complete Characters course",@"")];
        [self.cellView addSubview:cover];
    
     
        // AutoLayout 也可以
        cover.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [cover.topAnchor constraintEqualToAnchor:self.cellView.topAnchor constant:-3],
            [cover.leadingAnchor constraintEqualToAnchor:self.cellView.leadingAnchor],
            [cover.trailingAnchor constraintEqualToAnchor:self.cellView.trailingAnchor],
            [cover.bottomAnchor constraintEqualToAnchor:self.cellView.bottomAnchor constant:3]
        ]];
        self.cover = cover;
        self.cover.hidden = YES;
    }
    return self;
}
- (UIImageView *)cellView1 {
    if(!_cellView1){
        _cellView1 = [[UIImageView alloc]init];
        _cellView1.frame = CGRectMake(Distance＿M - self.cellDistance, 0, SCREEN_WIDTH - 2 * (Distance＿M - self.cellDistance), 133 + 2 * self.cellDistance);
        _cellView1.userInteractionEnabled = YES;
        UIImage *image = [UIImage imageNamed:@"background_white"];
        _cellView1.image = image;
    }
    return _cellView1;
}
- (UIView *)cellView {
    if(!_cellView){
        _cellView = [[UIView alloc]init];
        _cellView.frame = CGRectMake(Distance＿M, self.cellDistance, SCREEN_WIDTH - 2 * Distance＿M, 133);
        _cellView.userInteractionEnabled = YES;

        [_cellView addSubview:self.lblTitle];
        [_cellView addSubview:self.lblSubtitle];
        [_cellView addSubview:self.btnPracticeAll];
        self.labelWidth = 50;
        self.distanceWight = (self.cellView.frame.size.width - 34 - 5 * self.labelWidth)/4;
        self.distanceHeight = 16;

        int temp = 0;
        int count = self.countAll;
        for (int x = 0; x < count; x ++) {
            for (int i = 0; i < 5; i ++) {
                
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.frame = CGRectMake(17 + (self.distanceWight + self.labelWidth) * i , 67 + (self.labelWidth + self.distanceHeight) * x ,self.labelWidth, self.labelWidth);
                btn.tag = 1300 + temp;
                btn.hidden = YES;
                btn.clipsToBounds = YES;
                btn.backgroundColor = [UIColor clearColor];
                [btn setImage:[UIImage imageNamed:@"tian_white"] forState:UIControlStateNormal];
                [btn addTarget:self action:@selector(btnCellAction:) forControlEvents:UIControlEventTouchUpInside];
                [_cellView addSubview:btn];
                
                UILabel *lblInitials = [[UILabel alloc]init];
                lblInitials.font = [UIFont fontWithName:FONT_NAME_Kaiti size:36];
                lblInitials.frame = CGRectMake(0, 0, self.labelWidth, self.labelWidth);
                lblInitials.textAlignment = NSTextAlignmentCenter;
                lblInitials.layer.cornerRadius = 8;//圆角
                lblInitials.layer.masksToBounds = YES;
                lblInitials.tag = 160 + temp;
                lblInitials.userInteractionEnabled = NO; // 必须 NO
                [btn addSubview:lblInitials];

                temp++;
                lblInitials.textColor = BLACK_COLOR_1F;
            }
        }
    }
    return _cellView;
}

- (void)btnCellAction:(UIButton *)sender  {
    if(self.selectedTypeIndex){
        self.selectedTypeIndex(sender.tag);
    }
}
- (void)setCell:(NSDictionary *)dic {
    NSArray *array = [NSArray arrayWithArray:dic[@"elements"]];
    //NSInteger isCount = (array.count - 1) / 5 + 1;
    NSInteger isCount = (array.count + 4) / 5;
    // 记录最大值
    self.cellView1.frame = CGRectMake(Distance＿M - self.cellDistance, 0, SCREEN_WIDTH - 2 * (Distance＿M - self.cellDistance), 67 + (self.labelWidth  + self.distanceHeight)* isCount  + 2 * self.cellDistance);
    self.cellView.frame = CGRectMake(Distance＿M , self.cellDistance,SCREEN_WIDTH - 2 * Distance＿M, 67 + (self.labelWidth  + self.distanceHeight) * isCount);
    
    //特例//0字体颜色 1背景颜色
    ColorItem *blue = [ColorManager itemForKey:@"blue"];//#00C0A8
    NSArray *colorArray = blue.colors;
    UIColor *color = [UIColor clearColor];
    if (colorArray.count == 2){
        color = [self colorWithHexString:colorArray[0] alpha:1];
    }
    NSString *is_lock = [NSString stringWithFormat:@"%@",dic[@"is_lock"]];
    if(!IS_Member){
        is_lock = @"0";
    }
    self.cover.hidden = !is_lock.boolValue;
#ifdef DEBUG
        //self.cover.hidden = NO;// n
#endif
    [self.btnPracticeAll setTitleColor:color forState:UIControlStateNormal];
    //UIImage *arrowImage = [self imageWithImageName:@"next_pink" tintColor:color];
    UIImage *arrowImage = [UIImage imageNamed:@"arrows_blue"];
    [_btnPracticeAll setImage:arrowImage forState:UIControlStateNormal];
    
    self.lblTitle.text = [NSString stringWithFormat:@"%@",dic[@"title"]];
    self.lblSubtitle.text = [NSString stringWithFormat:@"%@",dic[@"subtitle"]];
    int count = self.countAll;
    for (int i = 0; i < (count * 5); i ++) {
        UIButton *btn = (UIButton *)[self.cellView viewWithTag:1300 + i];
        btn.hidden = YES;
    }
    
    for (int i = 0; i < array.count; i ++) {
        UIButton *btn = (UIButton *)[self.cellView viewWithTag:1300 + i];
        btn.hidden = NO;
        UILabel *lblInitials = (UILabel *)[btn viewWithTag:160 + i];
        NSDictionary *dicData = array[i];
        lblInitials.text = [NSString stringWithFormat:@"%@",dicData[@"hanzi"]];
        NSString *is_learning = [NSString stringWithFormat:@"%@",dicData[@"is_learning"]];
        if(colorArray.count == 2){
            NSString *strImage = @[@"tian_white",@"tian_select"][is_learning.boolValue];
            [btn setImage:[UIImage imageNamed:strImage] forState:UIControlStateNormal];
            //lblInitials.backgroundColor = [self colorWithHexString:@[@"#F4F6FA",colorArray[1]][is_learning.boolValue] alpha:1];
        }
    }
    
    //=======================

    //=======================
}
- (UIButton *)btnPracticeAll {
    if (!_btnPracticeAll) {
        _btnPracticeAll = [UIButton buttonWithType:UIButtonTypeCustom];
        int wight = self.cellDistance;
        //标题图片button
        _btnPracticeAll.frame = CGRectMake(self.cellView.frame.size.width - wight - 105 ,14, 105, 17);
        _btnPracticeAll.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14 - IS_OVERSEAS_VERSION * 2];
        [_btnPracticeAll setTitle:NSLocalizedString(@"Start Learning",@"") forState:UIControlStateNormal];
        _btnPracticeAll.userInteractionEnabled = NO;
        _btnPracticeAll.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _btnPracticeAll.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        int right = 30 - IS_OVERSEAS_VERSION * 30;
        _btnPracticeAll.titleEdgeInsets = UIEdgeInsetsMake(0,0,0,-right);
        _btnPracticeAll.imageEdgeInsets = UIEdgeInsetsMake(0,0,0,-(5 + right));

    }
    return _btnPracticeAll;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]init];
        _lblTitle.frame = CGRectMake(17, 12 , self.cellView.frame.size.width - 32 - 50, 20);
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]init];
        _lblSubtitle.frame = CGRectMake(self.lblTitle.frame.origin.x, 38, self.cellView.frame.size.width - 20, 15);
        //_lblSubtitle.textColor = [self colorWithHexString:@[@"#63637D",@"#B6BDC2"][IS_OVERSEAS_VERSION] alpha:1];
        _lblSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:SCREEN_WIDTH < 393 ? 12:14-2 * IS_OVERSEAS_VERSION];
        _lblSubtitle.numberOfLines = 2;
    }
    return _lblSubtitle;
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
