//
//  StoryCell.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StoryCell : UITableViewCell
@property (nonatomic, strong) UILabel *cnLabel; // 中文
@property (nonatomic, strong) UILabel *enLabel; // 英文

- (void)configureWithCN:(NSString *)cn en:(NSString *)en selected:(BOOL)isSelected;
@end

NS_ASSUME_NONNULL_END
