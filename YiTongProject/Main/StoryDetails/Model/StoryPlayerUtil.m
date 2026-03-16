//
//  StoryPlayerUtil.m
//  YiTongProject
//
//  Created by ios01 on 2026/1/6.
//

#import "StoryPlayerUtil.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation StoryPlayerUtil
+ (void)updateNowPlayingWithStoryInfo:(NSDictionary *)dicStory
                            isFairy:(BOOL)isFairy
                         languageKey:(NSString *)languageKey
                              player:(AVPlayer *)player
                          playerItem:(AVPlayerItem *)playerItem {

    if (!dicStory || !player) return;

    // ===== 1. 标题（中 / 英）=====
    NSString *titleCN = [NSString stringWithFormat:@"%@", dicStory[@"title_main"] ?: @""];
    NSString *titleEN = [NSString stringWithFormat:@"%@", dicStory[@"title_fallback"] ?: @""];
    NSString *title = [languageKey isEqualToString:@"En"] ? titleEN : titleCN;

    // ===== 2. 分类文案 =====
    NSString *category = isFairy ? @"神话故事" : @"成语故事";

    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];

    nowPlayingInfo[MPMediaItemPropertyTitle] = title;
    nowPlayingInfo[MPMediaItemPropertyArtist] = category; // ⚠️ 推荐放这里，稳定显示
    //nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = category; // 可留，但系统可能不显示

    // ===== 3. 先设置占位封面 =====
    UIImage *placeholderImage = [UIImage imageNamed:@"blue_1024"];
    if (placeholderImage) {
        MPMediaItemArtwork *artwork =
        [[MPMediaItemArtwork alloc] initWithBoundsSize:placeholderImage.size
                                         requestHandler:^UIImage * _Nonnull(CGSize size) {
            return placeholderImage;
        }];
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork;
    }

    // ===== 4. 播放时长 & 进度 =====
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {

        Float64 duration = CMTimeGetSeconds(playerItem.duration);
        if (isfinite(duration)) {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(duration);
        }

        Float64 currentTime = CMTimeGetSeconds(player.currentTime);
        if (isfinite(currentTime)) {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(currentTime);
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(player.rate);
    }

    // 先更新一次（保证立刻显示）
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;

    // ===== 5. 异步加载网络封面（失败自动 fallback）=====
    NSString *headImageURL = [NSString stringWithFormat:@"%@", dicStory[@"head_image"] ?: @""];
    if (headImageURL.length == 0) return;

    NSURL *url = [NSURL URLWithString:headImageURL];
    if (!url) return;

    [[[NSURLSession sharedSession] dataTaskWithURL:url
                                 completionHandler:^(NSData * _Nullable data,
                                                     NSURLResponse * _Nullable response,
                                                     NSError * _Nullable error) {

        UIImage *finalImage = nil;
        if (data && !error) {
            finalImage = [UIImage imageWithData:data];
        }
        if (!finalImage) {
            finalImage = placeholderImage; // fallback
        }
        if (!finalImage) return;

        MPMediaItemArtwork *networkArtwork =
        [[MPMediaItemArtwork alloc] initWithBoundsSize:finalImage.size
                                         requestHandler:^UIImage * _Nonnull(CGSize size) {
            return finalImage;
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *updatedInfo =
            [NSMutableDictionary dictionaryWithDictionary:
             [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo ?: @{}];

            updatedInfo[MPMediaItemPropertyArtwork] = networkArtwork;
            [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = updatedInfo;
        });

    }] resume];
}
@end
/*NSString *title_cn = [NSString stringWithFormat:@"%@",self.dicStory[@"title_main"]];
NSString *title_en = [NSString stringWithFormat:@"%@",self.dicStory[@"title_fallback"]];
NSString *title = [Language_key isEqualToString:@"En"] ? title_en:title_cn;
NSString *subtitle = self.isFairy ?@"神话故事":@"成语故事";
// 设置基本信息
NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
nowPlayingInfo[MPMediaItemPropertyTitle] = title;
nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = @"成语故事";
nowPlayingInfo[MPMediaItemPropertyArtist] = @"故事讲解";
//nowPlayingInfo[MPMediaItemPropertyArtist] = @"第三回 · 射九日";
// 设置封面图片
NSString *headImage = [NSString stringWithFormat:@"%@",self.dicStory[@"head_image"]];
UIImage *artworkImage = [UIImage imageNamed:@"blue_1024"];
MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:artworkImage.size  requestHandler:^UIImage * _Nonnull(CGSize size) {
    return artworkImage;
}];
[nowPlayingInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
// 设置播放时长和进度
if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
    Float64 duration = CMTimeGetSeconds(self.playerItem.duration);
    if (isfinite(duration)) {
        [nowPlayingInfo setObject:@(duration) forKey:MPMediaItemPropertyPlaybackDuration];
    }
    Float64 currentTime = CMTimeGetSeconds(self.playerAudio.currentItem.currentTime);
    [nowPlayingInfo setObject:@(currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [nowPlayingInfo setObject:@(self.playerAudio.rate) forKey:MPNowPlayingInfoPropertyPlaybackRate];
}
 
// 更新锁屏信息
[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;*/
