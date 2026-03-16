//
//  ProgressContainerView.h
//  YiTongProject
//
//  Created by ios01 on 2026/2/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgressContainerView : UIView

@property (nonatomic, strong) UILabel *leftLabel;   // 左侧标题
@property (nonatomic, strong) UILabel *rightLabel;  // 右侧百分比
@property (nonatomic, assign) CGFloat progress;     // 0~1
@property (nonatomic, strong) NSArray<UIColor *> *gradientColors;

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
