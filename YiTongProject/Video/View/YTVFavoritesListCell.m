//
//  YTVFavoritesListCell.m
//  YiTongProject
//

#import "YTVFavoritesListCell.h"
#import "YTVVideoFeedItem.h"
#import "HeaderConfig.h"

@interface YTVFavoritesListCell ()
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@end

@implementation YTVFavoritesListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor blackColor];
        self.contentView.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:self.coverView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.metaLabel];
        [self.coverView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView);
            make.height.equalTo(self.coverView.mas_width).multipliedBy(9.0 / 16.0);
        }];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.coverView);
            make.right.equalTo(self.coverView);
            make.top.equalTo(self.coverView.mas_bottom).offset(8);
        }];
        [self.metaLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.titleLabel);
            make.right.equalTo(self.titleLabel);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
            make.bottom.equalTo(self.contentView).offset(-20);
        }];
    }
    return self;
}

/// 绑定封面、标题与摘要（摘要单行尾部省略）。
- (void)ytv_configureWithItem:(YTVVideoFeedItem *)item {
    self.titleLabel.text = item.title.length ? item.title : @"—";
    self.metaLabel.text = item.summary.length ? item.summary : NSLocalizedString(@"YTV_favorites_list_meta_placeholder", @"");
    [self.coverView sd_setImageWithURL:[NSURL URLWithString:item.coverURL ?: @""]
                      placeholderImage:[UIImage imageNamed:@"file_blue"]];
}

- (UIImageView *)coverView {
    if (!_coverView) {
        _coverView = [[UIImageView alloc] init];
        _coverView.contentMode = UIViewContentModeScaleAspectFill;
        _coverView.clipsToBounds = YES;
        _coverView.layer.cornerRadius = 8;
        _coverView.layer.masksToBounds = YES;
        _coverView.backgroundColor = [self.contentView colorWithHexString:@"#1C1C1E" alpha:1];
    }
    return _coverView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:17];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _titleLabel;
}

- (UILabel *)metaLabel {
    if (!_metaLabel) {
        _metaLabel = [[UILabel alloc] init];
        _metaLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _metaLabel.textColor = [self.contentView colorWithHexString:@"#AEAEB2" alpha:1];
        _metaLabel.numberOfLines = 1;
        _metaLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _metaLabel;
}

@end
