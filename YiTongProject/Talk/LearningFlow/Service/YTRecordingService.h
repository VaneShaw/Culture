//
//  YTRecordingService.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTMicPermissionState) {
    YTMicPermissionStateUnknown = 0,
    YTMicPermissionStateGranted = 1,
    YTMicPermissionStateDenied = 2,
};

typedef void (^YTMicPermissionCallback)(YTMicPermissionState state);
typedef void (^YTRecordStartCallback)(BOOL success, NSError * _Nullable error);
typedef void (^YTRecordStopCallback)(NSURL * _Nullable fileURL, NSError * _Nullable error);

/// 录音服务：负责权限/录音文件落地，不做评分（评分走 `YTScoringService`）
///
/// 设计约定（MVP）：
/// - start 时若权限未知会触发系统弹窗，授权后自动重试开始录音
/// - 同一时刻仅允许一个录音；重复 start 会停止上一次 recorder
/// - stop 回调返回本地文件 URL（供评分/回放）
@interface YTRecordingService : NSObject

+ (instancetype)shared;

- (void)requestMicPermission:(YTMicPermissionCallback)callback;
- (YTMicPermissionState)currentPermissionState;

- (BOOL)isRecording;
- (void)startRecordingWithIdentifier:(NSString *)identifier completion:(YTRecordStartCallback)completion;
- (void)stopRecordingWithCompletion:(YTRecordStopCallback)completion;

/// 当前麦克风输入电平，约 0~1（仅在 `isRecording == YES` 时有意义；内部会调用 `updateMeters`）。
- (CGFloat)currentMeterNormalizedLevel;

@end

NS_ASSUME_NONNULL_END

