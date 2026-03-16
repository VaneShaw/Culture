//
//  StoryTextCell.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/30.
//

#import "StoryTextCell.h"
#import "AnimatedImageView.h"
@interface StoryTextCell()

@end
@implementation StoryTextCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    // 背景视图（用于选中效果）
    self.selectedBgView = [[UIView alloc] init];
    self.selectedBgView.backgroundColor = [self colorWithHexString:@"#D2BAA9" alpha:0.1]; // 示例蓝色
    self.selectedBgView.layer.cornerRadius = 10;
    self.selectedBgView.layer.masksToBounds = YES;
    self.clipsToBounds = YES;
    [self.contentView addSubview:self.selectedBgView];
    self.selectedBgView.translatesAutoresizingMaskIntoConstraints = NO;

    // 中文
    self.lblChinese = [[UILabel alloc] init];
    self.lblChinese.numberOfLines = 0;
    self.lblChinese.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    self.lblChinese.textColor = [self colorWithHexString:@"#BE6221" alpha:1];
    self.lblChinese.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.lblChinese];
    
    // 英文
    self.lblEnglish = [[UILabel alloc] init];
    self.lblEnglish.numberOfLines = 0;
    self.lblEnglish.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    self.lblEnglish.textColor = [self colorWithHexString:@"#BE6221" alpha:1];
    self.lblEnglish.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.lblEnglish];
    
    int space = 10;
    // selectedBgView 约束：撑开内容 + 底部间距
    [NSLayoutConstraint activateConstraints:@[
        [self.selectedBgView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:space/2],
        [self.selectedBgView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:space],
        [self.selectedBgView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-space],
        [self.selectedBgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-space/2],
    ]];

    // 中文 Label 约束
    [NSLayoutConstraint activateConstraints:@[
        [self.lblChinese.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15],//上边距
        [self.lblChinese.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.lblChinese.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-35],
    ]];

    // 英文 Label 约束
    [NSLayoutConstraint activateConstraints:@[
        [self.lblEnglish.topAnchor constraintEqualToAnchor:self.lblChinese.bottomAnchor constant:(space-2)], //上边距
        [self.lblEnglish.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.lblEnglish.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-15],
        [self.lblEnglish.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-15]//下边距
    ]];
    
}
- (void)prepareForReuse {
    [super prepareForReuse];
    self.lblChinese.attributedText = nil;
    self.lblEnglish.attributedText = nil;
    self.selectedBgView.hidden = YES;
}

- (void)setModel:(StorySectionModel *)model selected:(BOOL)isSelected {
    NSString *chineseText = model.textCN;
    NSString *englishText = model.textEN;

    NSString *strFont = @[FONT_NAME_Regular,FONT_NAME_Medium][model.isTitle];
    self.lblChinese.font = [UIFont fontWithName:strFont size:16 + 4 * model.isTitle];
    //NSString *strFont2 = @[FONT_NAME_Kaiti,FONT_NAME_Medium][model.isTitle];
    self.lblEnglish.font = [UIFont fontWithName:strFont size:16 + 4 * model.isTitle];
  
    // 中文行间距可调（可选）
       NSMutableParagraphStyle *paraChinese = [[NSMutableParagraphStyle alloc] init];
       paraChinese.lineSpacing = 0; // 如果需要可以设置
       NSAttributedString *attrChinese = [[NSAttributedString alloc] initWithString:chineseText attributes:@{
           NSFontAttributeName:self.lblChinese.font,
           NSParagraphStyleAttributeName:paraChinese,
           NSLigatureAttributeName:@0
       }];
       self.lblChinese.attributedText = attrChinese;

       // 英文行间距可调（可选）
       NSMutableParagraphStyle *paraEnglish = [[NSMutableParagraphStyle alloc] init];
       paraEnglish.lineSpacing = 0;
       NSAttributedString *attrEnglish = [[NSAttributedString alloc] initWithString:englishText attributes:@{
           NSFontAttributeName:self.lblEnglish.font,
           NSParagraphStyleAttributeName: paraEnglish,
           NSLigatureAttributeName:@0
       }];
       self.lblEnglish.attributedText = attrEnglish;

       //是否显示选中背景
    if (isSelected) {
        self.selectedBgView.hidden = NO;
    } else {
        self.selectedBgView.hidden = YES;
    }
       //强制刷新布局（同步文本内容，不用异步）
       [self setNeedsLayout];
       [self layoutIfNeeded];
      //通知 tableView 更新 cell 高度
    
//    UITableView *tableView = [self parentTableView];
//    if (tableView) {
//        [tableView beginUpdates];
//        [tableView endUpdates];
//    }
    
}
//- (UITableView *)parentTableView {
//    UIView *view = self.superview;
//    while (view && ![view isKindOfClass:[UITableView class]]) {
//        view = view.superview;
//    }
//    return (UITableView *)view;
//}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
