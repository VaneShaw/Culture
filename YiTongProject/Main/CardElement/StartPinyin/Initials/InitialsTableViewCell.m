//
//  InitialsTableViewCell.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/8.
//

#import "InitialsTableViewCell.h"

@interface InitialsTableViewCell()
@property (strong, nonatomic) UIImageView *cellView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;
//@property (strong, nonatomic) UIImageView *imgArrow;
@property (assign, nonatomic) int cellWight;
@property (assign, nonatomic) int cellDistance;
@property (strong, nonatomic) CellCoverView *cover;
@end

@implementation InitialsTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.cellWight = SCREEN_WIDTH - 2 * Distance＿M;
        self.cellDistance = 12;
        self.selectionStyle = UITableViewCellSelectionStyleNone;//不能选中
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        self.contentView.userInteractionEnabled = YES;
        [self.contentView addSubview:self.cellView];
        //[self.contentView addSubview:self.cellSyllablesView];
        
        CellCoverView *cover = [[CellCoverView alloc] initWithFrame:self.contentView.bounds
                                                              title:NSLocalizedString(@"Unlock the complete Pinyin course",@"")];
        [self.cellView addSubview:cover];
        
        cover.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [cover.topAnchor constraintEqualToAnchor:self.cellView.topAnchor],
            [cover.leadingAnchor constraintEqualToAnchor:self.cellView.leadingAnchor],
            [cover.trailingAnchor constraintEqualToAnchor:self.cellView.trailingAnchor],
            [cover.bottomAnchor constraintEqualToAnchor:self.cellView.bottomAnchor]
        ]];
        self.cover = cover;
        self.cover.hidden = YES;
        

    }
    return self;
}
/*
- (UIImageView *)cellSyllablesView {
    if(!_cellSyllablesView){
        _cellSyllablesView = [[UIImageView alloc]init];
        _cellSyllablesView.frame = CGRectMake(Distance＿M - self.cellDistance, 0, self.cellWight + 2 * self.cellDistance, 240  + self.cellDistance);
        _cellSyllablesView.userInteractionEnabled = YES;
        UIImage *image = [UIImage imageNamed:@"background_white"];
        [_cellSyllablesView addSubview:self.btnPracticeAll];
        _cellSyllablesView.image = image;
    }
    return _cellSyllablesView;
}*/
- (UIImageView *)cellView {
    if(!_cellView){
        _cellView = [[UIImageView alloc]init];
        _cellView.userInteractionEnabled = YES;
        //_cellView.layer.cornerRadius = 12;//圆角
        //_cellView.layer.masksToBounds = YES;
        //_cellView.backgroundColor = [UIColor whiteColor];
        
        UIImage *image = [UIImage imageNamed:@"background_white"];
        [_cellView addSubview:self.lblTitle];
        [_cellView addSubview:self.lblSubtitle];
        [_cellView addSubview:self.btnPracticeAll];
        _cellView.image = image;
        //int distanceWight = 5;
        int distance = 5.5;
        int distanceWight = 8.5;

        int temp = 0;
        for (int x = 0; x < 3; x ++) {
            for (int i = 0; i < 6; i ++) {
                
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                //btn.frame = CGRectMake(0, 0, 35, 35);
                btn.frame = CGRectMake(16 + (18 + 35) * i + self.cellDistance - distanceWight, 61 + 47 * x + self.cellDistance/2 - distance,35 + 2 * distanceWight, 35 + 2 *distance);
                btn.tag = 1300 + temp;
                btn.hidden = YES;
                btn.clipsToBounds = YES;
                btn.backgroundColor = [UIColor clearColor];
                [btn addTarget:self action:@selector(btnCellAction:) forControlEvents:UIControlEventTouchUpInside];
                [_cellView addSubview:btn];
                
                UILabel *lblInitials = [[UILabel alloc]init];
                //lblInitials.frame = CGRectMake(16 + (18 + 35) * i + self.cellDistance, 61 + 47 * x + self.cellDistance/2,35, 35);
                lblInitials.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
                lblInitials.frame = CGRectMake(distanceWight, distance, 35, 35);
                lblInitials.textAlignment = NSTextAlignmentCenter;
                lblInitials.layer.cornerRadius = 8;//圆角
                lblInitials.layer.masksToBounds = YES;
                lblInitials.tag = 160 + temp;
                //lblInitials.userInteractionEnabled = YES;
                lblInitials.userInteractionEnabled = NO; // 必须 NO
                [btn addSubview:lblInitials];

                temp++;
                lblInitials.textColor = BLACK_COLOR_1F;
                //lblInitials.backgroundColor = [self colorWithHexString:@"#F4F6FA" alpha:1];
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

- (void)setCell:(NSDictionary *)dic imgColor:(NSString *)imgColor {
    
    NSArray *array = [NSArray arrayWithArray:dic[@"elements"]];
    BOOL isCount = (array.count > 6)? YES:NO;
    self.cellView.frame = CGRectMake(Distance＿M - self.cellDistance, 0, self.cellWight + 2 * self.cellDistance, 108 + 47 * isCount + self.cellDistance);
    //特例     //0字体颜色 1背景颜色
    NSString *currentKey = [ColorManager currentColorKey];
    if([currentKey isEqualToString:@"green"]){
        currentKey = [NSString stringWithFormat:@"%@_00",currentKey];
    }
    ColorItem *blue = [ColorManager itemForKey:currentKey];//#00C0A8
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
        //self.cover.hidden = NO;//测试用
#endif
    
    [self.btnPracticeAll setTitleColor:color forState:UIControlStateNormal];
    //self.imgArrow.image = [self imageWithImageName:@"next_pink" tintColor:color];
    UIImage *arrowImage = [self imageWithImageName:@"next_pink" tintColor:color];
    [_btnPracticeAll setImage:arrowImage forState:UIControlStateNormal];
    
    self.lblTitle.text = [NSString stringWithFormat:@"%@",dic[@"title"]];
    self.lblSubtitle.text = [NSString stringWithFormat:@"%@",dic[@"subtitle"]];
    for (int i = 0; i < 18; i ++) {
        UIButton *btn = (UIButton *)[self.cellView viewWithTag:1300 + i];
        btn.hidden = YES;
        //UILabel *lblInitials = (UILabel *)[btn viewWithTag:160 + i];
        //lblInitials.hidden = YES;
    }
    for (int i = 0; i < array.count; i ++) {
        UIButton *btn = (UIButton *)[self.cellView viewWithTag:1300 + i];
        btn.hidden = NO;
        UILabel *lblInitials = (UILabel *)[btn viewWithTag:160 + i];
        //lblInitials.hidden = NO;
     
        NSDictionary *dicData = array[i];
        lblInitials.text = [NSString stringWithFormat:@"%@",dicData[@"symbol"]];
        NSString *is_learning = [NSString stringWithFormat:@"%@",dicData[@"is_learning"]];
        //NSLog(@"is_learn---------[%@]---------------------",is_learning);
        if(colorArray.count == 2){
            lblInitials.backgroundColor = [self colorWithHexString:@[@"#F4F6FA",colorArray[1]][is_learning.boolValue] alpha:1];
        }
    }
    
    [self.cover updateIconImageColor:[self colorWithHexString:imgColor alpha:1] bgColor:colorArray[1]];
    //=======================
    int distance = 5.5;
    int distanceWight = 8.5;

    int temp1 = 0;
    for (int x = 0; x < 2; x ++) {
        for (int i = 0; i < 6; i ++) {
            UIButton *btn = (UIButton *)[self.cellView viewWithTag:1300 + temp1];
            //UILabel *lblInitials = (UILabel *)[btn viewWithTag:160 + temp1];
            temp1++;
            btn.frame =  CGRectMake(16 + (18 + 35) * i + self.cellDistance - distanceWight, 61 + 47 * x + self.cellDistance/2 - distance,35 + 2 * distanceWight, 35 + 2 * distance );
        }
    }
 
    if(array.count > 12){
        self.cellView.frame = CGRectMake(Distance＿M - self.cellDistance, 0, self.cellWight + 2 * self.cellDistance, 250 + self.cellDistance);
        int temp = 0;
        for (int x = 0; x < 4; x ++) {
            for (int i = 0; i < 4; i ++) {
                UIButton *btn = (UIButton *)[self.cellView viewWithTag:1300 + temp];
                UILabel *lblInitials = (UILabel *)[btn viewWithTag:160 + temp];
                temp++;
                btn.frame =  CGRectMake(16 + (18 + 62) * i + self.cellDistance - distanceWight, 48 + 47 * x + self.cellDistance/2 - distance,62 + 2 * distanceWight , 35  + 2 * distance );
                lblInitials.frame = CGRectMake(distanceWight, distance, 62 , 35);
            }
        }
    }
    //=======================
}
- (UIButton *)btnPracticeAll {
    if (!_btnPracticeAll) {
        _btnPracticeAll = [UIButton buttonWithType:UIButtonTypeCustom];
        int wight = SCREEN_WIDTH < 390 ? 5 : 15;
        //标题图片button
        _btnPracticeAll.frame = CGRectMake(self.cellWight - wight - 100 + self.cellDistance, 15 + self.cellDistance/2, 100, 15);
        _btnPracticeAll.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14 - IS_OVERSEAS_VERSION * 2];
        [_btnPracticeAll setTitle:NSLocalizedString(@"Start Learning",@"") forState:UIControlStateNormal];
        //_btnPracticeAll.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _btnPracticeAll.userInteractionEnabled = NO;
        _btnPracticeAll.titleEdgeInsets = UIEdgeInsetsMake(0,-20, 0, 0);

        //self.imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(100-15, 0, 15, 15)];
        //[_btnPracticeAll addSubview:self.imgArrow];
        _btnPracticeAll.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _btnPracticeAll.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _btnPracticeAll.titleEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 10);
        _btnPracticeAll.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -2);
    }
    return _btnPracticeAll;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]init];
        _lblTitle.frame = CGRectMake(16 + self.cellDistance, 12 + self.cellDistance/2, self.cellWight - 32 - 50, 20);
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]init];
        _lblSubtitle.frame = CGRectMake(self.lblTitle.frame.origin.x, 36 + self.cellDistance/2, self.cellWight - 20, 15);
        _lblSubtitle.textColor = [self colorWithHexString:@[@"#63637D",@"#B6BDC2"][IS_OVERSEAS_VERSION] alpha:1];
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
