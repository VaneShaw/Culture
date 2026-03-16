//
//  HanziListTableViewCell.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HanziListTableViewCell : UITableViewCell
@property (strong, nonatomic) UIButton *btnPracticeAll;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger selectedIndex);//代码块传值

- (void)setCell:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
