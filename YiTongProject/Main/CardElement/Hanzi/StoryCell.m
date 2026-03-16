//
//  StoryCell.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/23.
//

#import "StoryCell.h"
#import <Masonry/Masonry.h>

@implementation StoryCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _cnLabel = [[UILabel alloc] init];
        _cnLabel.numberOfLines = 0;
        _cnLabel.font = [UIFont boldSystemFontOfSize:16];
        [self.contentView addSubview:_cnLabel];
        _enLabel = [[UILabel alloc] init];
        _enLabel.font = [UIFont systemFontOfSize:13];
        _enLabel.numberOfLines = 0; // 允许换行
        [self.contentView addSubview:_enLabel];
        
        [_cnLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(14);
            make.left.equalTo(self.contentView).offset(20);
            make.right.equalTo(self.contentView).offset(-10);
        }];
        [_enLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cnLabel.mas_bottom).offset(6);
            make.left.right.equalTo(self.cnLabel);
            make.bottom.equalTo(self.contentView).inset(16);
        }];
        
    }
    return self;
}

- (void)configureWithCN:(NSString *)cn en:(NSString *)en selected:(BOOL)isSelected {
    cn = [NSString stringWithFormat:@"%@",cn];
    en = [NSString stringWithFormat:@"%@",en];
    self.cnLabel.text = cn;
    self.enLabel.text = en;
    
    if (isSelected) {
        self.cnLabel.textColor = BLACK_COLOR_1F;
        self.enLabel.textColor = [self colorWithHexString:@"#515181" alpha:1];
    } else {
        self.cnLabel.textColor = [self colorWithHexString:@"#A8A8BC" alpha:1];
        self.enLabel.textColor = [self colorWithHexString:@"#A8A8BC" alpha:1];
    }
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
