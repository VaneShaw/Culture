//
//  SingleAudioPlayer.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/5.
//

#import "SingleAudioPlayer.h"


@interface SingleAudioPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, copy) AudioPlayCompletionHandler completionHandler;

@end
@implementation SingleAudioPlayer
//单音频 赞无用可删
+ (instancetype)sharedManager {
    static SingleAudioPlayer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance setupAudioSession];
    });
    return instance;
}

#pragma mark - Audio Session

/// 统一设置音频会话（仅执行一次）
- (void)setupAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];

    NSError *error1 = nil;
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions:AVAudioSessionCategoryOptionDuckOthers //0  // 无混音选项
                   error:&error1];
    
    if (error1) {
        NSLog(@"AudioSession category error: %@", error1);
    }

    NSError *error2 = nil;
    [session setActive:YES error:&error2];
    if (error2) {
        NSLog(@"AudioSession active error: %@", error2);
    }
}

#pragma mark - Public Methods

/// 停止所有音频播放
- (void)stopAllAudio {

    // 防止回调重复触发
    self.completionHandler = nil;

    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer.delegate = nil;
        self.audioPlayer = nil;
    }

    // 发送播放状态通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayStateNotification"
                                                        object:nil
                                                      userInfo:@{@"status": @(NO)}];

    NSLog(@"AudioPlayerManager: 已停止所有音频");
}


/// 播放本地/网络短音频（自动异步加载）
- (void)playAudioWithURL:(NSString *)urlString
              completion:(AudioPlayCompletionHandler)completion {

    // 先停止之前的播放
    [self stopAllAudio];

    self.completionHandler = completion;

    if (urlString.length == 0) {
        [self handleCompletion:NO
                         error:[NSError errorWithDomain:@"AudioError"
                                                   code:1001
                                               userInfo:@{NSLocalizedDescriptionKey:@"URL为空"}]];
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self handleCompletion:NO
                         error:[NSError errorWithDomain:@"AudioError"
                                                   code:1002
                                               userInfo:@{NSLocalizedDescriptionKey:@"URL格式无效"}]];
        return;
    }

    /// 异步加载音频（不会阻塞 UI）
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSData *audioData = [NSData dataWithContentsOfURL:url];

        dispatch_async(dispatch_get_main_queue(), ^{

            if (!audioData) {
                [self handleCompletion:NO
                                 error:[NSError errorWithDomain:@"AudioError"
                                                           code:1003
                                                       userInfo:@{NSLocalizedDescriptionKey:@"音频加载失败"}]];
                return;
            }

            NSError *playerError = nil;
            self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:&playerError];

            if (playerError || !self.audioPlayer) {
                [self handleCompletion:NO error:playerError];
                return;
            }

            self.audioPlayer.delegate = self;
            [self.audioPlayer prepareToPlay];
            [self.audioPlayer play];

            NSLog(@"AudioPlayerManager: 开始播放音频");

            // 发送播放开始通知
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayStateNotification"
                                                                object:nil
                                                              userInfo:@{@"status": @(YES)}];
        });
    });
}

#pragma mark - Callbacks

/// 统一处理播放回调
- (void)handleCompletion:(BOOL)success error:(NSError *)error {

    if (self.completionHandler) {
        self.completionHandler(success, error);
    }

    self.completionHandler = nil;
}

#pragma mark - AVAudioPlayerDelegate

/// 播放完成
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {

    [self handleCompletion:flag error:nil];

    self.audioPlayer = nil;

    // 发送播放结束通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayStateNotification"
                                                        object:nil
                                                      userInfo:@{@"status": @(NO)}];

    NSLog(@"AudioPlayerManager: 音频播放完成");
}

/// 解码失败
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {

    [self handleCompletion:NO error:error];
    self.audioPlayer = nil;

    NSLog(@"AudioPlayerManager: 音频解码失败 %@", error);
}

@end
