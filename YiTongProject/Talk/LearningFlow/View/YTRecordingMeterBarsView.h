//
//  YTRecordingMeterBarsView.h
//  YiTongProject
//
//  学习流主按钮录音态：多根细白条随输入电平起伏跳动（替代静态 talk_vectoring 切图）。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTRecordingMeterBarsView : UIView

/// 电平 0~1，由 `YTRecordingService -currentMeterNormalizedLevel` 驱动；设置后会做轻量平滑。
@property (nonatomic, assign) CGFloat meterLevel;

/// 波形水平滚动相位（弧度），由外部每帧更新（如 `CACurrentMediaTime() * 速度`），产生左右流动感。
@property (nonatomic, assign) CGFloat wavePhase;

/// 白条颜色，默认白色。
@property (nonatomic, strong) UIColor *barColor;

@end

NS_ASSUME_NONNULL_END
