//
//  CountDownButton.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^CountDownBlock)(void); // 定义 Block 类型
@interface CountDownButton : UIButton

@property (nonatomic, strong) UILabel *countdownLabel;
// 开始倒计时（默认60秒）
- (void)startCountDown;

// 停止倒计时（手动恢复按钮状态）
- (void)stopCountDown;

// 自定义倒计时时间（单位：秒）
@property (nonatomic, assign) NSInteger countDownTime;

// 点击按钮时触发的 Block（用于外部业务逻辑，如发送验证码）
@property (nonatomic, copy) CountDownBlock countDownBlock;
@end

NS_ASSUME_NONNULL_END
