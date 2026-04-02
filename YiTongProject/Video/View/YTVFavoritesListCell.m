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
        self.backgroundColor = [UIColor whiteColor];
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:self.coverView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.metaLabel];
        [self.coverView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.centerY.equalTo(self.contentView);
            make.width.height.mas_equalTo(88);
        }];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.coverView.mas_right).offset(12);
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.coverView.mas_top).offset(4);
        }];
        [self.metaLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.titleLabel);
            make.right.equalTo(self.titleLabel);
            make.bottom.equalTo(self.coverView.mas_bottom).offset(-4);
        }];
    }
    return self;
}

- (void)ytv_configureWithItem:(YTVVideoFeedItem *)item {
    self.titleLabel.text = item.title.length ? item.title : @"—";
    NSMutableString *meta = [NSMutableString string];
    if (item.category.length) {
        [meta appendString:item.category];
    }
    if (item.favoritedAtMs > 0) {
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:item.favoritedAtMs / 1000.0];
        static NSDateFormatter *fmt;
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            fmt = [[NSDateFormatter alloc] init];
            fmt.dateStyle = NSDateFormatterShortStyle;
            fmt.timeStyle = NSDateFormatterShortStyle;
        });
        if (meta.length) {
            [meta appendString:@" · "];
        }
        [meta appendString:[fmt stringFromDate:d]];
    }
    self.metaLabel.text = meta.length ? meta : NSLocalizedString(@"YTV_favorites_list_meta_placeholder", @"");
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
        _coverView.backgroundColor = [self.contentView colorWithHexString:@"#E8EEF5" alpha:1];
    }
    return _coverView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        _titleLabel.textColor = [self.contentView colorWithHexString:@"#1F1F39" alpha:1];
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

- (UILabel *)metaLabel {
    if (!_metaLabel) {
        _metaLabel = [[UILabel alloc] init];
        _metaLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
        _metaLabel.textColor = [self.contentView colorWithHexString:@"#8F8F8F" alpha:1];
        _metaLabel.numberOfLines = 2;
    }
    return _metaLabel;
}

@end
