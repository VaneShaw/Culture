//
//  StoryTextCell.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/30.
//

#import <UIKit/UIKit.h>
#import "StorySectionModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface StoryTextCell : UITableViewCell
//@property (strong, nonatomic) UIPlayButton *btnPlayAudio;
@property (nonatomic, strong) UIView *selectedBgView;
@property (nonatomic, strong) UILabel *lblChinese;
@property (nonatomic, strong) UILabel *lblEnglish;
- (void)setModel:(StorySectionModel *)model selected:(BOOL)isSelected;

@end

NS_ASSUME_NONNULL_END
