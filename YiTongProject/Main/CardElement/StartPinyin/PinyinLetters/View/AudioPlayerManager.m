//
//  AudioPlayerManager.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/11.
//

#import "AudioPlayerManager.h"
// 最大并发播放数（防止音频过载）
#define MAX_CONCURRENT_PLAYERS 5
@interface AudioPlayerManager ()<AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVQueuePlayer *queuePlayer;
@property (nonatomic, strong) NSArray<AVPlayerItem *> *queueItems;

@property (nonatomic, copy) AudioPlayCompletionHandler completionHandler;
@end
@implementation AudioPlayerManager
//所有音频相关 - 公共音频类
+ (instancetype)sharedManager {
    static AudioPlayerManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        // 设置音频会话
        //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                       withOptions:0  // 无混音选项
                                             error:nil];
        //[[AVAudioSession sharedInstance] setActive:YES error:nil];
        NSError *error;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (error) {
            NSLog(@"AudioSession error: 【%@】--", error); // 可能触发工厂类错误
        }

    });
    return sharedInstance;
}

- (void)stopAllAudio {

    if (self.audioPlayer) {
          [self.audioPlayer stop];
          self.audioPlayer.delegate = nil;
          self.audioPlayer = nil;
      }

      if (self.queuePlayer) {
          [self.queuePlayer removeAllItems];
          [self.queuePlayer pause];
          self.queuePlayer = nil;
      }
 
    NSLog(@"已停止当前音频");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayStartPlayinghNotification"
                                                      object:nil
                                                    userInfo:@{@"status": @(NO)}];
}
- (void)playMergedAudioWithURLs:(NSArray<NSString *> *)urlStrings
                     completion:(AudioPlayCompletionHandler)completion {
    //[[AVAudioSession sharedInstance] setActive:YES error:nil];
    // 停止当前播放
    [self stopAllAudio];
    // 保存回调
    self.completionHandler = completion;

    // 检查 URL 数组有效性
    if (urlStrings.count == 0) {
        NSError *err = [NSError errorWithDomain:@"AudioErrorDomain"
                                           code:1001
                                       userInfo:@{NSLocalizedDescriptionKey: @"无效的音频URL数组"}];
        [self handleCompletion:NO error:err];
        return;
    }

    // 构建 AVPlayerItem 队列
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *urlString in urlStrings) {
        if (urlString.length == 0) continue;
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) continue;
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        [items addObject:item];
    }

    if (items.count == 0) {
        NSError *err = [NSError errorWithDomain:@"AudioErrorDomain"
                                           code:1002
                                       userInfo:@{NSLocalizedDescriptionKey: @"未能创建任何有效的播放项"}];
        [self handleCompletion:NO error:err];
        return;
    }
    self.queueItems = items;
    self.queuePlayer = [AVQueuePlayer queuePlayerWithItems:self.queueItems];
    // 创建队列播放器
    //self.queuePlayer222 = [AVQueuePlayer queuePlayerWithItems:items];
    // 监听播放结束
    //[[NSNotificationCenter defaultCenter] addObserver:self
                                             //selector:@selector(queueItemDidFinish:)
                                                 //name:AVPlayerItemDidPlayToEndTimeNotification
                                               //object:[items lastObject]]; // 只监听最后一个
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(queueItemDidFinish:)
        name:AVPlayerItemDidPlayToEndTimeNotification
        object:nil];
    // 开始播放
    [self.queuePlayer play];
    NSLog(@"开始连续播放两个音频");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayStartPlayinghNotification"
                                                        object:nil
                                                      userInfo:@{@"status": @(YES)}];
}
- (void)queueItemDidFinish:(NSNotification *)notification {
    NSLog(@"所有音频播放完成");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:notification.object];
    AVPlayerItem *finishedItem = notification.object;
     if (finishedItem != self.queuePlayer.items.lastObject) {
         return;  // 不是最后一个，不回调
     }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    if (self.completionHandler) {
        self.completionHandler(YES, nil);
        self.completionHandler = nil;
    }
    self.queuePlayer = nil;
}
- (void)playShortAudioWithURL:(NSString *)urlString
                   completion:(AudioPlayCompletionHandler)completion {
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    // 停止当前所有音频
     [self stopAllAudio];
    // 保存回调block
    self.completionHandler = completion;
    // 清理之前的播放器
    if (self.audioPlayer) {
        self.audioPlayer.delegate = nil;
        self.audioPlayer = nil;
    }
    
    // 检查URL有效性
    if (!urlString || urlString.length == 0) {
        NSLog(@"无效的音频URL");
        [self handleCompletion:NO error:[NSError errorWithDomain:@"AudioErrorDomain" code:1001
                                                     userInfo:@{NSLocalizedDescriptionKey: @"无效的音频URL"}]];
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSLog(@"无法创建URL对象: %@", urlString);
        [self handleCompletion:NO error:[NSError errorWithDomain:@"AudioErrorDomain" code:1002
                                                     userInfo:@{NSLocalizedDescriptionKey: @"无效的URL格式"}]];
        return;
    }
    // 异步加载音频
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *audioData = [NSData dataWithContentsOfURL:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (audioData) {
                NSError *error;
                self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:&error];
                
                if (!error) {
                    self.audioPlayer.delegate = self;
                    //self.audioPlayer.volume = 1.0;
                    [self.audioPlayer prepareToPlay];
                    [self.audioPlayer play];
                    NSLog(@"1开始播放短音频1");
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioPlayStartPlayinghNotification"
                                                                      object:nil
                                                                    userInfo:@{@"status": @(YES)}];
                } else {
                    NSLog(@"音频播放器初始化失败: %@", error.localizedDescription);
                    [self handleCompletion:NO error:error];
                }
            } else {
                NSLog(@"无法加载音频数据");
                [self handleCompletion:NO error:[NSError errorWithDomain:@"AudioErrorDomain"  code:1003
                                                             userInfo:@{NSLocalizedDescriptionKey: @"音频数据加载失败"}]];
            }
        });
    });
}

#pragma mark - 回调处理方法
- (void)handleCompletion:(BOOL)success error:(NSError *)error {
    if (self.completionHandler) {
        self.completionHandler(success, error);
    }
    // 清空block避免循环引用
    self.completionHandler = nil;
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self handleCompletion:flag error:nil];
    self.audioPlayer = nil;

}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self handleCompletion:NO error:error];
    self.audioPlayer = nil;

}

@end
