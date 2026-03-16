//
//  AudioRemoteControlManager.h
//  YiTongProject
//
//  Created by ios01 on 2026/1/4.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface AudioRemoteControlManager : NSObject
@property (nonatomic, weak) AVPlayer *player;
/// UI 回调（VC 自己决定怎么换按钮）
@property (nonatomic, copy, nullable) void (^playStateChanged)(BOOL isPlaying);
- (instancetype)initWithPlayer:(AVPlayer *)player;
/// 开启 / 关闭远程控制
- (void)setupRemoteControls;
- (void)removeRemoteControls;
/// 手动刷新锁屏进度
- (void)refreshNowPlayingAfterSeek;
@end
NS_ASSUME_NONNULL_END
