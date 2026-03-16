//
//  AudioScrollManager.h
//  YiTongProject
//
//  Created by ios01 on 2026/1/28.
//

//@property (nonatomic, assign) BOOL hasPrependedData;
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioScrollManager : NSObject


// 是否发生过「前插数据更新」
@property (nonatomic, assign) BOOL hasPrependedData;
// 是否正在音频驱动滚动（全局唯一）
@property (nonatomic, assign) BOOL isAudioScrolling_2;

//=============上面是====有用的参数=========================

/// 音频是否正在播放（全局唯一）
@property (nonatomic, assign) BOOL isAudio_Playing;
/// 当前音频所属回合 index
@property (nonatomic, assign) NSInteger currentAudioRoundIndex;

/// 当前音频是否只允许在封面页触发
@property (nonatomic, assign) BOOL onlyCoverPage;

/// 单例
+ (instancetype)shared;

/// 是否允许在当前页面触发音频逻辑
- (BOOL)canTriggerAudioWithVisibleRound:(NSInteger)visibleRound
                           isCoverPage:(BOOL)isCoverPage;

/// 音频开始（统一入口）
- (void)beginAudioScrollWithRound:(NSInteger)round;

/// 音频结束 / 中断（统一出口）
- (void)endAudioScroll;

/// 重置（页面切换 / VC 销毁时）
- (void)reset;
@end

NS_ASSUME_NONNULL_END
