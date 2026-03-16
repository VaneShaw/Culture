//
//  CellCoverView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CellCoverView : UIView
/// 文字内容
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, strong) UIImageView *bgImgView;

/// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title;
// 修改图标的方法
- (void)updateIconImageColor:(UIColor *)imgColor bgColor:(NSString *)bgColor;
@end

NS_ASSUME_NONNULL_END
