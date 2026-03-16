//
//  TitleSubtitleView.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TitleSubtitleView : UIView
/// 设置内容
/// @param title 标题
/// @param subtitle 副标题
- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle;

/// 获取视图所需高度
+ (CGFloat)heightForWidth:(CGFloat)width
                    title:(NSString *)title
                 subtitle:(NSString *)subtitle;
@end

NS_ASSUME_NONNULL_END
