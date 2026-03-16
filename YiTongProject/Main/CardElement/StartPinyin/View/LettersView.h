//
//  LettersView.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LettersView : UIView
@property (nonatomic, strong) UIColor *shadowColor;    // 阴影颜色（默认浅灰色）
@property (nonatomic, assign) CGFloat shadowRadius;   // 阴影模糊半径（默认 3pt）
@property (nonatomic, assign) CGFloat cornerRadius;  // 视图圆角（默认 12pt）
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;
@property (strong, nonatomic) UIButton *btnChart;
@property (strong, nonatomic) UIButton *btnView;
@end

NS_ASSUME_NONNULL_END
