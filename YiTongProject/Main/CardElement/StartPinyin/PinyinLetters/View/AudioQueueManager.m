//
//  AudioQueueManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/5.
//

#import "AudioQueueManager.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioQueueManager ()

@property (nonatomic, strong) AVQueuePlayer *queuePlayer;
@property (nonatomic, strong) NSMutableArray<AVPlayerItem *> *playerItems;
@property (nonatomic, copy) AudioQueueCompletionHandler completionHandler;
@property (nonatomic, assign) BOOL isPlaying;
@end

@implementation AudioQueueManager
//音频播放，关于汉字翻转页里面的 中 + 英 音频队列拼接

+ (instancetype)sharedManager {
    static AudioQueueManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance setupAudioSession];
    });
    return instance;
}
#pragma mark - Audio Session（保证播放时 duck）
- (void)setupAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *err1 = nil;
    // 播放模式 + DuckOthers（降低其他音频音量）
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions:AVAudioSessionCategoryOptionDuckOthers
                   error:&err1];
    if (err1) NSLog(@"AudioSession category error: %@", err1);
    NSError *err2 = nil;
    [session setActive:YES error:&err2];
    if (err2) NSLog(@"AudioSession active error: %@", err2);
}
#pragma mark - Public API
- (void)stopAllAudio {
    self.isPlaying = NO;
    self.completionHandler = nil;
    if (self.queuePlayer) {
        [self.queuePlayer pause];
        [self.queuePlayer removeAllItems];
        self.queuePlayer = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioQueueStateNotification"
                                                        object:nil
                                                      userInfo:@{@"status": @(NO)}];
    NSLog(@"AudioQueueManager: 已停止播放队列");
}
- (void)playAudioQueueWithURLs:(NSArray<NSString *> *)urls
                    completion:(AudioQueueCompletionHandler)completion {
    // 清理上次播放的内容
    [self stopAllAudio];
    self.completionHandler = completion;
    self.isPlaying = YES;
    if (urls.count == 0) {
        [self finishWithError:@"URL数组为空" code:2001];
        return;
    }
    self.playerItems = [NSMutableArray array];
    // 创建 AVPlayerItem 列表
    for (NSString *urlString in urls) {
        if (urlString.length == 0) continue;
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) continue;

        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        // ⭐ 关键：防止慢速变声
        //item.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;
        [self.playerItems addObject:item];
    }

    if (self.playerItems.count == 0) {
        [self finishWithError:@"未能创建有效播放项" code:2002];
        return;
    }

    // 创建队列播放器
    self.queuePlayer = [AVQueuePlayer queuePlayerWithItems:self.playerItems];

    // 监听“最后一个 item 播放完成”
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFinish:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItems.lastObject];
    // 开始播放
    [self.queuePlayer play];
    //[self.queuePlayer playImmediatelyAtRate:0.5];
    //NSLog(@"AudioQueueManager: 开始播放队列音频");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioQueueStateNotification"
                                                        object:nil
                                                      userInfo:@{@"status": @(YES)}];
}

#pragma mark - Notification Callback

/// 最后一个音频播放完成
- (void)itemDidFinish:(NSNotification *)noti {

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItems.lastObject];

    if (!self.isPlaying) return; // 避免 stop 后重复回调

    NSLog(@"AudioQueueManager: 所有音频播放完成");

    if (self.completionHandler) {
        self.completionHandler(YES, nil);
    }

    self.completionHandler = nil;
    self.isPlaying = NO;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioQueueStateNotification"
                                                        object:nil
                                                      userInfo:@{@"status": @(NO)}];
}

#pragma mark - Helper

- (void)finishWithError:(NSString *)msg code:(NSInteger)code {

    NSError *err = [NSError errorWithDomain:@"AudioQueueError"
                                       code:code
                                   userInfo:@{NSLocalizedDescriptionKey: msg}];

    if (self.completionHandler) {
        self.completionHandler(NO, err);
    }

    self.completionHandler = nil;

    NSLog(@"AudioQueueManager Error: %@", msg);
}
@end
