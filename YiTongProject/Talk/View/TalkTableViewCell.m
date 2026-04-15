//
//  TalkTableViewCell.m
//  YiTongProject
//
//  Created by ios01 on 2026/3/2.
//

#import "TalkTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>
@interface TalkTableViewCell()

@property (strong, nonatomic) UIImageView *cellView;
@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) UIView *bottomStatusView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;
@property (strong, nonatomic) UILabel *actionLabel;
@property (assign, nonatomic) YTTalkSceneCellStatus cellStatus;

// 进度百分比：0 表示未开始，100 表示完成，其他为进行中（用于直接展示与进度条比例）
@property (assign, nonatomic) CGFloat progressPercent;

// 右侧 30x30 角标：未开始=箭头；进行中=百分比；完成=✅
@property (strong, nonatomic) UIView *cornerProgressView;
@property (strong, nonatomic) UIImageView *cornerProgressIconView;
@property (strong, nonatomic) UILabel *cornerProgressLabel;

@property (strong, nonatomic) UIImageView *actionCapsuleImageView;
@property (strong, nonatomic) UIView *actionProgressClipView;
@property (strong, nonatomic) CAGradientLayer *actionGradientLayer;
@property (strong, nonatomic) CALayer *actionCapsuleMaskLayer;
@property (assign, nonatomic) CGRect actionCapsuleBaseFrame;


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
        // 纯色底图 bottomStatusView 相对图片向右偏移 6（offsetX）
        // 目标：纯色底图距离 cellView 右边 20
        // 因此图片 rightPadding 需要 = 20 + 6 = 26
        CGFloat rightPadding = 26.0;
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

        // learning 进度条（胶囊不规则底图）底边距容器底部 32
        // cellView 高度 190，进度条高度 38 -> y = 190 - 32 - 38 = 120
        CGRect capsuleFrame = CGRectMake(18, 120, 144, 38);
        self.actionCapsuleBaseFrame = capsuleFrame;

        // 用“胶囊底图 alpha”作为 mask，让渐变只在底图形状范围内显示（凹进去的位置也不会溢出）
        UIImage *capsuleImg = [UIImage imageNamed:@"union_blakc"];

        self.actionProgressClipView = [[UIView alloc] initWithFrame:capsuleFrame];
        self.actionProgressClipView.clipsToBounds = YES;
        self.actionProgressClipView.hidden = YES;
        [_cellView addSubview:self.actionProgressClipView];

        self.actionGradientLayer = [CAGradientLayer layer];
        self.actionGradientLayer.frame = CGRectMake(0, 0, capsuleFrame.size.width, capsuleFrame.size.height);
        self.actionGradientLayer.startPoint = CGPointMake(0, 0.5);
        self.actionGradientLayer.endPoint = CGPointMake(1, 0.5);

        // 覆盖遮挡方案：不使用 mask 裁剪渐变。
        // 渐变先铺满到当前进度宽度矩形，然后由 union_blakc 切图作为遮挡层叠在上面。
        [self.actionProgressClipView.layer addSublayer:self.actionGradientLayer];

        // 胶囊底图本体（用于显示不规则描边/细节）
        self.actionCapsuleImageView = [[UIImageView alloc] initWithFrame:capsuleFrame];
        self.actionCapsuleImageView.image = capsuleImg;
        self.actionCapsuleImageView.contentMode = UIViewContentModeScaleToFill;
        [_cellView addSubview:self.actionCapsuleImageView];

        // 右侧角标（30x30）放到胶囊图片内部：右侧距离胶囊右边 4
        CGFloat cornerSize = 30.0;
        CGRect capsuleRect = capsuleFrame;
        CGFloat cornerX = CGRectGetMaxX(capsuleRect) - cornerSize - 4.0;
        CGFloat cornerY = capsuleRect.origin.y + (capsuleRect.size.height - cornerSize) / 2.0;
        // 在胶囊内部显示，X/Y 不做额外越界裁剪

        self.cornerProgressView = [[UIView alloc] initWithFrame:CGRectMake(cornerX, cornerY, cornerSize, cornerSize)];
        self.cornerProgressView.backgroundColor = [UIColor clearColor];
        [_cellView addSubview:self.cornerProgressView];

        self.cornerProgressIconView = [[UIImageView alloc] initWithFrame:self.cornerProgressView.bounds];
        self.cornerProgressIconView.contentMode = UIViewContentModeScaleAspectFit;
        self.cornerProgressIconView.hidden = NO;
        self.cornerProgressIconView.image = [UIImage imageNamed:@"talk_corner_arrow"];
        [self.cornerProgressView addSubview:self.cornerProgressIconView];

        self.cornerProgressLabel = [[UILabel alloc] initWithFrame:self.cornerProgressView.bounds];
        self.cornerProgressLabel.textAlignment = NSTextAlignmentCenter;
        self.cornerProgressLabel.numberOfLines = 1;
        self.cornerProgressLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:13];
        self.cornerProgressLabel.textColor = [theAppDelegate.window colorWithHexString:@"#1F1F39" alpha:1];
        self.cornerProgressLabel.hidden = YES;
        [self.cornerProgressView addSubview:self.cornerProgressLabel];

        // “learning” 文案（覆盖在胶囊底图上）
        self.actionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 110, 38)];
        self.actionLabel.textAlignment = NSTextAlignmentCenter;
        self.actionLabel.textColor = BLACK_COLOR_1F;
        self.actionLabel.font = [UIFont fontWithName:FONT_NAME_Medium size:16];
        self.actionLabel.adjustsFontSizeToFitWidth = YES;
        self.actionLabel.minimumScaleFactor = 0.78;
        self.actionLabel.text = NSLocalizedString(@"Talk_SceneList_Action_Learning", @"");
        [self.actionCapsuleImageView addSubview:self.actionLabel];
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

- (YTTalkSceneCellStatus)yt_statusForProgressPercent:(CGFloat)progressPercent {
    if (progressPercent <= 0.0) return YTTalkSceneCellStatusNotStarted;
    if (progressPercent >= 100.0) return YTTalkSceneCellStatusCompleted;
    return YTTalkSceneCellStatusInProgress;
}

/// 胶囊主文案：与角标（箭头 / 百分比+%% / ✅）同一套 `scene_progress_percent` 规则——0 未开始、0～100 进行中、100 完成
- (NSString *)yt_localizedActionTitleForCellStatus:(YTTalkSceneCellStatus)status {
    switch (status) {
        case YTTalkSceneCellStatusNotStarted:
            return NSLocalizedString(@"Talk_SceneList_Action_Learning", @"");
        case YTTalkSceneCellStatusInProgress:
            return NSLocalizedString(@"Talk_Continue", @"");
        case YTTalkSceneCellStatusCompleted:
            return NSLocalizedString(@"Talk_SceneList_Action_ViewDetails", @"");
    }
}

- (CGFloat)yt_progressRatioForPercent:(CGFloat)progressPercent {
    CGFloat ratio = progressPercent / 100.0;
    ratio = MAX(0.0, MIN(1.0, ratio));
    return ratio;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.lblTitle.text = @"";
    self.lblSubtitle.text = @"";
    self.imgView.image = nil;
    self.actionLabel.text = NSLocalizedString(@"Talk_SceneList_Action_Learning", @"");
    self.cellStatus = YTTalkSceneCellStatusNotStarted;
    self.progressPercent = 0.0;
    self.bottomStatusView.backgroundColor = [self yt_colorForStatus:self.cellStatus];
    if (self.cornerProgressIconView) {
        self.cornerProgressIconView.image = [UIImage imageNamed:@"talk_corner_arrow"];
        self.cornerProgressIconView.hidden = NO;
    }
    if (self.cornerProgressLabel) {
        self.cornerProgressLabel.hidden = YES;
        self.cornerProgressLabel.text = @"";
    }
    // 重置胶囊渐变进度
    if (self.actionProgressClipView && !CGRectEqualToRect(self.actionProgressClipView.frame, self.actionCapsuleBaseFrame)) {
        self.actionProgressClipView.frame = self.actionCapsuleBaseFrame;
    }
    if (self.actionProgressClipView) {
        self.actionProgressClipView.hidden = YES;
    }
}

- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
                  imageUrl:(NSString *)imageUrl
           progressPercent:(NSInteger)progressPercent {
    self.lblTitle.text = title ?: @"";
    self.lblSubtitle.text = subtitle ?: @"";

    self.progressPercent = MAX(0, MIN(100, (CGFloat)progressPercent));
    self.cellStatus = [self yt_statusForProgressPercent:self.progressPercent];
    self.bottomStatusView.backgroundColor = [self yt_colorForStatus:self.cellStatus];

    UIImage *placeholder = [UIImage imageNamed:@"talk_default"];
    if (imageUrl.length > 0) {
        [self.imgView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:placeholder];
    } else {
        self.imgView.image = placeholder;
    }

    self.actionLabel.text = [self yt_localizedActionTitleForCellStatus:self.cellStatus];

    [self yt_updateCapsuleProgress];
    [self yt_updateCornerProgress];
}

- (void)yt_updateCornerProgress {
    if (!self.cornerProgressView) return;

    switch (self.cellStatus) {
        case YTTalkSceneCellStatusNotStarted: {
            self.cornerProgressIconView.image = [UIImage imageNamed:@"talk_corner_arrow"];
            self.cornerProgressIconView.hidden = NO;
            self.cornerProgressLabel.hidden = YES;
        } break;
        case YTTalkSceneCellStatusInProgress: {
            self.cornerProgressIconView.hidden = YES;
            self.cornerProgressLabel.hidden = NO;
            NSInteger percentInt = (NSInteger)llround(self.progressPercent);
            self.cornerProgressLabel.text = [NSString stringWithFormat:@"%ld%%", (long)percentInt];
            self.cornerProgressLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:12];
            self.cornerProgressLabel.textColor = [theAppDelegate.window colorWithHexString:@"#1F1F39" alpha:1];
        } break;
        case YTTalkSceneCellStatusCompleted: {
            self.cornerProgressIconView.image = [UIImage imageNamed:@"talk_corner_check"];
            self.cornerProgressIconView.hidden = NO;
            self.cornerProgressLabel.hidden = YES;
        } break;
    }
}

- (void)yt_updateCapsuleProgress {
    if (!self.actionProgressClipView || !self.actionGradientLayer || !self.actionCapsuleBaseFrame.size.width) return;

    CGFloat ratio = [self yt_progressRatioForPercent:self.progressPercent];
    BOOL shouldShow = ratio > 0.001;
    self.actionProgressClipView.hidden = !shouldShow;

    CGRect clipFrame = self.actionCapsuleBaseFrame;
    clipFrame.size.width = self.actionCapsuleBaseFrame.size.width * ratio;
    self.actionProgressClipView.frame = clipFrame;
    // 关键：让渐变按照“当前进度宽度”重新铺满
    self.actionGradientLayer.frame = self.actionProgressClipView.bounds;

    // 渐变：从 imageView 后面的“纯色背景色”（按状态取色）到白色
    UIColor *startColor = [self yt_colorForStatus:self.cellStatus];
    UIColor *endColor = [UIColor whiteColor];
    self.actionGradientLayer.colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
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
