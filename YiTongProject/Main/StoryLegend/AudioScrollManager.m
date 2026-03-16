//
//  AudioScrollManager.m
//  YiTongProject
//
//  Created by ios01 on 2026/1/28.
//

#import "AudioScrollManager.h"

@implementation AudioScrollManager
+ (instancetype)shared {
    static AudioScrollManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AudioScrollManager alloc] init];
        manager.onlyCoverPage = YES; // 默认只允许封面页
    });
    return manager;
}

#pragma mark - Core Logic

- (BOOL)canTriggerAudioWithVisibleRound:(NSInteger)visibleRound
                           isCoverPage:(BOOL)isCoverPage {
    
    // 1️⃣ 正在音频滚动中，直接拒绝
    if (self.isAudioScrolling_2) {
        return NO;
    }
    // 2️⃣ 只允许封面页
    if (self.onlyCoverPage && !isCoverPage) {
        return NO;
    }
    // 3️⃣ 当前可视回合必须等于音频所属回合
    if (visibleRound != self.currentAudioRoundIndex) {
        return NO;
    }
    return YES;
}
#pragma mark - State Control
- (void)beginAudioScrollWithRound:(NSInteger)round {
    self.isAudioScrolling_2 = YES;
    self.currentAudioRoundIndex = round;
}
- (void)endAudioScroll {
    self.isAudioScrolling_2 = NO;
}
- (void)reset {
    self.isAudio_Playing = NO;
    self.isAudioScrolling_2 = NO;
    self.currentAudioRoundIndex = NSNotFound;
}

@end

