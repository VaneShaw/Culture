//
//  YTRecordingService.m
//  YiTongProject
//

#import "YTRecordingService.h"
#import <AVFoundation/AVFoundation.h>

/**
 录音服务（MVP）
 
 职责边界：
 - 负责：麦克风权限申请、AVAudioSession 配置、录音文件写入本地
 - 不负责：播放（走 `YTAudioMuxService`）、评分（走 `YTScoringService`）
 
 设计要点：
 - iOS17+ 使用 `AVAudioApplication` 的权限 API；低版本 fallback 到 `AVAudioSession`
 - 录音文件直接落到 Documents，便于调试与后续上传（后续可改到 tmp 并上传后删除）
 - 同一时刻只允许一个 recorder（重复 start 会停止上一次）
 */
@interface YTRecordingService () <AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, copy) YTRecordStopCallback pendingStop;
@end

@implementation YTRecordingService

+ (instancetype)shared {
    static YTRecordingService *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[YTRecordingService alloc] init];
        s.session = [AVAudioSession sharedInstance];
    });
    return s;
}

- (YTMicPermissionState)currentPermissionState {
    // 权限口径统一走 AVAudioSession：
    // - 在旧/新系统上都稳定可用
    // - 避免在“新系统 + 旧 SDK / 不同头文件版本”下对 AVAudioApplication 枚举值误判
    AVAudioSessionRecordPermission p = self.session.recordPermission;
    if (p == AVAudioSessionRecordPermissionGranted) return YTMicPermissionStateGranted;
    if (p == AVAudioSessionRecordPermissionDenied) return YTMicPermissionStateDenied;
    return YTMicPermissionStateUnknown;
}

- (void)requestMicPermission:(YTMicPermissionCallback)callback {
    if (!callback) return;
    // 始终走 AVAudioSession，行为稳定；授权结果回到主线程
    [self.session requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(granted ? YTMicPermissionStateGranted : YTMicPermissionStateDenied);
        });
    }];
}

- (BOOL)isRecording {
    return self.recorder.isRecording;
}

- (void)startRecordingWithIdentifier:(NSString *)identifier completion:(YTRecordStartCallback)completion {
    if (identifier.length == 0) {
        if (completion) completion(NO, [NSError errorWithDomain:@"YTRecordingService" code:2001 userInfo:@{NSLocalizedDescriptionKey: @"identifier 为空"}]);
        return;
    }
    if ([self isRecording]) {
        // 保证互斥：新一次录音开始前先停止旧 recorder
        [self.recorder stop];
        self.recorder = nil;
    }

    YTMicPermissionState state = [self currentPermissionState];
    if (state == YTMicPermissionStateDenied) {
        if (completion) completion(NO, [NSError errorWithDomain:@"YTRecordingService" code:2002 userInfo:@{NSLocalizedDescriptionKey: @"麦克风权限被拒绝"}]);
        return;
    }
    if (state == YTMicPermissionStateUnknown) {
        // 首次弹权限：拿到授权后递归重试（调用方不需要关心权限细节）
        __weak typeof(self) weakSelf = self;
        [self requestMicPermission:^(YTMicPermissionState newState) {
            __strong typeof(weakSelf) self = weakSelf;
            if (newState != YTMicPermissionStateGranted) {
                if (completion) completion(NO, [NSError errorWithDomain:@"YTRecordingService" code:2002 userInfo:@{NSLocalizedDescriptionKey: @"麦克风权限被拒绝"}]);
                return;
            }
            [self startRecordingWithIdentifier:identifier completion:completion];
        }];
        return;
    }

    NSError *err = nil;
    // PlayAndRecord + 默认外放：符合“跟读”场景（不走听筒）
    [self.session setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                        error:&err];
    if (err) {
        if (completion) completion(NO, err);
        return;
    }
    [self.session setActive:YES error:&err];
    if (err) {
        if (completion) completion(NO, err);
        return;
    }

    NSURL *dir = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    // 文件名带 unitId + 时间戳：便于排查与避免覆盖
    NSString *filename = [NSString stringWithFormat:@"talk_%@_%lld.m4a", identifier, (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
    NSURL *url = [dir URLByAppendingPathComponent:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }

    // AAC 单声道：体积小、兼容性好（后续可按需求提高采样率/码率）
    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(44100.0),
        AVNumberOfChannelsKey: @(1),
        AVEncoderAudioQualityKey: @(AVAudioQualityMedium),
    };

    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&err];
    if (err || !self.recorder) {
        if (completion) completion(NO, err ?: [NSError errorWithDomain:@"YTRecordingService" code:2003 userInfo:@{NSLocalizedDescriptionKey: @"录音器初始化失败"}]);
        return;
    }
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];

    BOOL ok = [self.recorder record];
    if (completion) completion(ok, ok ? nil : [NSError errorWithDomain:@"YTRecordingService" code:2004 userInfo:@{NSLocalizedDescriptionKey: @"开始录音失败"}]);
}

- (void)stopRecordingWithCompletion:(YTRecordStopCallback)completion {
    if (![self isRecording] || !self.recorder) {
        if (completion) completion(nil, [NSError errorWithDomain:@"YTRecordingService" code:2005 userInfo:@{NSLocalizedDescriptionKey: @"当前未在录音"}]);
        return;
    }
    self.pendingStop = completion;
    [self.recorder stop];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSURL *url = recorder.url;
    self.recorder = nil;

    NSError *deactErr = nil;
    [self.session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&deactErr];

    if (self.pendingStop) {
        YTRecordStopCallback cb = self.pendingStop;
        self.pendingStop = nil;
        if (!flag) {
            cb(nil, [NSError errorWithDomain:@"YTRecordingService" code:2006 userInfo:@{NSLocalizedDescriptionKey: @"录音失败"}]);
            return;
        }
        cb(url, nil);
    }
}

@end

