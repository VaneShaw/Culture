//
//  InitialsTableViewCell.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InitialsTableViewCell : UITableViewCell
@property (strong, nonatomic) UIButton *btnPracticeAll;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger selectedIndex);//代码块传值

- (void)setCell:(NSDictionary *)dic imgColor:(NSString *)imgColor;

@end

NS_ASSUME_NONNULL_END
//self.cellView.layer.masksToBounds = NO; // 必须为 NO 才能显示阴影
//3. 设置浅灰色阴影
/*self.cellView.layer.shadowColor = [UIColor lightGrayColor].CGColor;
self.cellView.layer.shadowOffset = CGSizeMake(0, 1.5); // 阴影向下偏移1点
self.cellView.layer.shadowOpacity = 0.3; // 透明度（0~1）
self.cellView.layer.shadowRadius = 3.0;  // 阴影模糊半径
// 4. 优化性能（阴影路径固定）
self.cellView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.cellView.bounds cornerRadius:self.cellView.layer.cornerRadius].CGPath;*/
