//
//  TitleSubtitleView.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/22.
//

#import "TitleSubtitleView.h"


@implementation TitleSubtitleView {
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        // 标题
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.numberOfLines = 0; // 自动换行
        _titleLabel.textColor = BLACK_COLOR_1F; // BLACK_COLOR_1F
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
        [self addSubview:_titleLabel];
        
        // 副标题
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.numberOfLines = 0; // 自动换行
        _subtitleLabel.textColor = GARY_COLOR_63;
        _subtitleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        [self addSubview:_subtitleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = 20;
    CGFloat maxWidth = self.bounds.size.width - padding * 2;
    
    CGSize titleSize = [_titleLabel sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    _titleLabel.frame = CGRectMake(padding, 0, maxWidth, titleSize.height);
    
    CGSize subtitleSize = [_subtitleLabel sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    _subtitleLabel.frame = CGRectMake(padding, CGRectGetMaxY(_titleLabel.frame) + 8, maxWidth, subtitleSize.height);
}

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle {
    _titleLabel.text = title;
    _subtitleLabel.text = subtitle;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

+ (CGFloat)heightForWidth:(CGFloat)width
                    title:(NSString *)title
                 subtitle:(NSString *)subtitle {
    CGFloat padding = 20;
    CGFloat maxWidth = width - padding * 2;
    
    UILabel *tmpTitle = [[UILabel alloc] init];
    tmpTitle.numberOfLines = 0;
    tmpTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
    tmpTitle.text = title;
    CGSize titleSize = [tmpTitle sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    
    UILabel *tmpSubtitle = [[UILabel alloc] init];
    tmpSubtitle.numberOfLines = 0;
    tmpSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    tmpSubtitle.text = subtitle;
    CGSize subtitleSize = [tmpSubtitle sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    
    return titleSize.height + 8 + subtitleSize.height; // 8 是标题和副标题间距
}



@end
