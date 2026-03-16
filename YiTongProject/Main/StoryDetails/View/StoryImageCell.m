//
//  StoryImageCell.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/30.
//

#import "StoryImageCell.h"
@interface StoryImageCell()
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint; // 图片高度约束

@property (strong, nonatomic) FLAnimatedImageView *gifView;
@end
@implementation StoryImageCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
            self.selectionStyle = UITableViewCellSelectionStyleNone;

            _imgView = [[UIImageView alloc] init];
            _imgView.contentMode = UIViewContentModeScaleAspectFit;
            _imgView.clipsToBounds = YES;
            [self.contentView addSubview:_imgView];
            _imgView.translatesAutoresizingMaskIntoConstraints = NO;

            // Auto Layout 约束
            [NSLayoutConstraint activateConstraints:@[
                [_imgView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
                [_imgView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                [_imgView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            ]];
           self.heightConstraint = [_imgView.heightAnchor constraintEqualToConstant:150];
           self.heightConstraint.active = YES;
            // 底部约束保证 cell 自动撑开
            [_imgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            //[_imgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        }
        return self;
}
//- (void)layoutSubviews {
//    [super layoutSubviews];
//    //_imgView.frame = self.contentView.bounds;
//}
- (void)setModel:(StorySectionModel *)model {
        _model = model;
        // 高度约束，初始给个0
        self.gifView.hidden = YES;
        __weak typeof(self) weakSelf = self;
        [_imgView sd_setImageWithURL:[NSURL URLWithString:model.imageUrl]
                    placeholderImage:nil
                             options:0
                           completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (!image) return;
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            CGFloat ratio = image.size.height / image.size.width;
            strongSelf.heightConstraint.constant = SCREEN_WIDTH * ratio;
            //strongSelf.heightConstraint.constant = SCREEN_WIDTH * ratio;

            //CGFloat newHeight = SCREEN_WIDTH * ratio;
            //强制刷新 cell layout
            [strongSelf setNeedsLayout];
            [strongSelf layoutIfNeeded];
            
            // 告诉 tableView 更新高度
            UITableView *tableView = [strongSelf parentTableView];
            if(!weakSelf.model.imageLoaded){
                [tableView beginUpdates];
                [tableView endUpdates];
            }
      
            if (image) {
                weakSelf.model.imageLoaded = YES; // 加载成功后标记
            }
            strongSelf.imgView.image = image;
        }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.heightConstraint.constant = 0;
    //self.heightConstraint.constant = 150;
    self.imgView.image = nil;
}
- (UITableView *)parentTableView {
    UIView *view = self.superview;
    while (view && ![view isKindOfClass:[UITableView class]]) {
        view = view.superview;
    }
    return (UITableView *)view;
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
