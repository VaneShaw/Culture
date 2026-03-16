//
//  PaymentTableViewCell.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/25.
//

#import "PaymentTableViewCell.h"


@interface PaymentTableViewCell()
@property (strong, nonatomic) UIImageView *cellView;
@property (strong, nonatomic) UIImageView *imgIcon;
@property (strong, nonatomic) UILabel *lblTitle;
@end

@implementation PaymentTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;//不能选中
        self.contentView.userInteractionEnabled = YES;
        self.clipsToBounds = YES;
        [self.contentView addSubview:self.imgIcon];
        [self.contentView addSubview:self.lblTitle];
    }
    return self;
}
- (void)setCell:(NSDictionary *)dic {
    self.imgIcon.image = [UIImage imageNamed:@"blue_tick"];
    NSArray *titleArray = dic[@"title"];
    if (![titleArray isKindOfClass:[NSArray class]] || titleArray.count != 2) return;

    //------------------------------------------
    self.lblTitle.textColor = [self colorWithHexString:@"#B0FFFC" alpha:1];
    NSString *strTitle = titleArray[0];
    NSString *strLength = titleArray[1];
    NSString *content = [NSString stringWithFormat:@"%@",strTitle];
    
    NSMutableAttributedString *noteStr = [[NSMutableAttributedString alloc] initWithString:content];
    [noteStr  addAttribute:NSForegroundColorAttributeName value:[self colorWithHexString:@"#B0B0E0" alpha:1] range:NSMakeRange(0,strLength.length)];
    //[noteStr  addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:30]  range:NSMakeRange(0,str1.length)];
    self.lblTitle.attributedText = noteStr;
    //------------------------------------------

    int space = 10;
    [NSLayoutConstraint activateConstraints:@[           // 图标
        [self.imgIcon.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:space],
        [self.imgIcon.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:30],
        [self.imgIcon.widthAnchor constraintEqualToConstant:20],
        [self.imgIcon.heightAnchor constraintEqualToConstant:20]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        // Title 上边距从 contentView 顶部开始（而不是 bottom）
        [self.lblTitle.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:space],
        [self.lblTitle.leadingAnchor constraintEqualToAnchor:self.imgIcon.trailingAnchor constant:10],
        [self.lblTitle.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-15],
        [self.lblTitle.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-space]
    ]];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}
- (UIImageView *)imgIcon {
    if(!_imgIcon){
        _imgIcon = [[UIImageView alloc]init];
        _imgIcon.translatesAutoresizingMaskIntoConstraints = NO;
        _imgIcon.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imgIcon;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]init];
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        _lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _lblTitle.textColor = [self colorWithHexString:@"#B0FFFC" alpha:1];
        _lblTitle.textColor = [self colorWithHexString:@"#B0B0B0" alpha:1];
        _lblTitle.numberOfLines = 0;
    }
    return _lblTitle;
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

