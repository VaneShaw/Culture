//
//  TalkTableViewCell.m
//  YiTongProject
//
//  Created by ios01 on 2026/3/2.
//

#import "TalkTableViewCell.h"
@interface TalkTableViewCell()

@property (strong, nonatomic) UIImageView *cellView;
@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) UIView *bottomStatusView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;
@property (strong, nonatomic) UILabel *actionLabel;
@property (assign, nonatomic) YTTalkSceneCellStatus cellStatus;


@end


@implementation TalkTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;//不能选中
        self.contentView.userInteractionEnabled = YES;
        self.contentView.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;

        [self.contentView addSubview:self.cellView];
    }
    return self;
}
- (UIImageView *)imgView {
    if(!_imgView){
        _imgView = [[UIImageView alloc]init];
        _imgView.backgroundColor = [UIColor clearColor];
        _imgView.layer.cornerRadius = 16;//圆角
        _imgView.userInteractionEnabled = YES;
        // 右侧图片位置：用于与底部纯色背景发生重叠
        CGFloat cardW = SCREEN_WIDTH - 2 * Distance＿M;
        CGFloat imageW = 120.0;
        CGFloat imageH = 140.0;
        CGFloat rightPadding = 16.0;
        CGFloat x = cardW - rightPadding - imageW;
        CGFloat y = 20.0; // imageview 相对容器顶部 20
        _imgView.frame = CGRectMake(x, y, imageW, imageH);
        _imgView.clipsToBounds = YES;
        _imgView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imgView;
}
- (UIImageView *)cellView {
    if(!_cellView){
        CGFloat cardW = SCREEN_WIDTH - 2 * Distance＿M;
        // 顶部留白上调一点：让整体 cell 高度对齐 190
        _cellView = [[UIImageView alloc]initWithFrame:CGRectMake(Distance＿M, 10, cardW, 190)];
        _cellView.userInteractionEnabled = YES;
        _cellView.backgroundColor = [UIColor whiteColor];
        _cellView.layer.cornerRadius = 15.0; // 圆角
        _cellView.layer.masksToBounds = NO; // 阴影需要 masksToBounds = NO
        _cellView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        _cellView.layer.shadowOffset = CGSizeMake(0, 6);
        _cellView.layer.shadowOpacity = 1.0;
        _cellView.layer.shadowRadius = 12.0;
        _cellView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_cellView.bounds cornerRadius:_cellView.layer.cornerRadius].CGPath;

        // 纯色背景：大小跟 imageView 一模一样，并相对于 imageView 右移 6、下移 10
        CGRect imgFrame = self.imgView.frame; // 触发 imgView getter，确保 frame 已计算
        CGFloat offsetX = 6.0;
        CGFloat offsetY = 10.0;
        self.bottomStatusView = [[UIView alloc] initWithFrame:CGRectMake(imgFrame.origin.x + offsetX,
                                                                            imgFrame.origin.y + offsetY,
                                                                            imgFrame.size.width,
                                                                            imgFrame.size.height)];
        self.bottomStatusView.backgroundColor = [theAppDelegate.window colorWithHexString:@"#E3C89D" alpha:1];
        self.bottomStatusView.layer.cornerRadius = 16.0;
        self.bottomStatusView.clipsToBounds = YES;
        [_cellView addSubview:self.bottomStatusView]; // 放在 imageView 下面，确保“纯色上面覆盖图片”

        // 右侧重叠图片（覆盖纯色背景）
        [_cellView addSubview:self.imgView];

        // 标题（20 加粗）
        // 标题（20 加粗），相对容器顶部 32
        self.lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(18, 32, _cellView.bounds.size.width - 170, 24)];
        self.lblTitle.textColor = BLACK_COLOR_1F;
        self.lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
        self.lblTitle.numberOfLines = 1;
        [_cellView addSubview:self.lblTitle];

        // 副标题（多行）
        self.lblSubtitle = [[UILabel alloc] initWithFrame:CGRectMake(18, CGRectGetMaxY(self.lblTitle.frame) + 8, _cellView.bounds.size.width - 170, 44)];
        self.lblSubtitle.textColor = GARY_COLOR_63;
        self.lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        self.lblSubtitle.numberOfLines = 2;
        [_cellView addSubview:self.lblSubtitle];

        // 底部学习按钮底图
        // learning 进度条（胶囊底图）底边距容器底部 32
        // cellView 高度 190，进度条高度 38 -> y = 190 - 32 - 38 = 120
        UIImageView *imgDetails = [[UIImageView alloc] initWithFrame:CGRectMake(18, 120, 144, 38)];
        imgDetails.image = [UIImage imageNamed:@"union_blakc"];
        [_cellView addSubview:imgDetails];

        // “learning” 文案（覆盖在 union_blakc 上）
        self.actionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 110, 38)];
        self.actionLabel.textAlignment = NSTextAlignmentCenter;
        self.actionLabel.textColor = BLACK_COLOR_1F;
        self.actionLabel.font = [UIFont fontWithName:FONT_NAME_Medium size:16];
        self.actionLabel.text = @"learning";
        [imgDetails addSubview:self.actionLabel];
    }
    return _cellView;
}

- (UIColor *)yt_colorForStatus:(YTTalkSceneCellStatus)status {
    switch (status) {
        case YTTalkSceneCellStatusNotStarted:
            return [theAppDelegate.window colorWithHexString:@"#E3C89D" alpha:1];
        case YTTalkSceneCellStatusInProgress:
            return [theAppDelegate.window colorWithHexString:@"#C9DFA2" alpha:1];
        case YTTalkSceneCellStatusCompleted:
            return [theAppDelegate.window colorWithHexString:@"#DBE5F8" alpha:1];
    }
    return [theAppDelegate.window colorWithHexString:@"#E3C89D" alpha:1];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.lblTitle.text = @"";
    self.lblSubtitle.text = @"";
    self.imgView.image = nil;
    self.actionLabel.text = @"learning";
    self.cellStatus = YTTalkSceneCellStatusNotStarted;
    self.bottomStatusView.backgroundColor = [self yt_colorForStatus:self.cellStatus];
}

- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
                 imageName:(NSString *)imageName
                     status:(YTTalkSceneCellStatus)status {
    self.lblTitle.text = title ?: @"";
    self.lblSubtitle.text = subtitle ?: @"";
    self.cellStatus = status;
    self.bottomStatusView.backgroundColor = [self yt_colorForStatus:status];
    if (imageName.length > 0) {
        self.imgView.image = [UIImage imageNamed:imageName];
    } else {
        self.imgView.image = nil;
    }
    self.actionLabel.text = NSLocalizedString(@"learning", @"");
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
