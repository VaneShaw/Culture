//
//  StoryMenuView.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/23.
//

#import <UIKit/UIKit.h>
#import "StorySectionModel.h"
@class StoryMenuView;
NS_ASSUME_NONNULL_BEGIN

@protocol StoryMenuViewDelegate <NSObject>

/// 选中了第几个故事
- (void)storyMenuView:(StoryMenuView *)menuView didSelectStoryAtIndex:(NSInteger)index;

/// 点击播放 / 暂停
- (void)storyMenuViewDidTogglePlay:(StoryMenuView *)menuView;

/// 拖动音频进度
- (void)storyMenuViewDidSeekToProgress:(CGFloat)progress;

/// 切换语言
- (void)storyMenuViewDidChangeLanguage:(NSString *)language;
//返回uiviewcontroller     菜单栏目 是否是显示还是隐藏

- (void)scrollToCellAtIndex:(NSInteger)index;                //点击跳转到对应的cell
- (void)scrollToCellAudioAtIndexCurrent:(NSInteger)index;   //是否跟音频滚动
- (void)storyMenuViewAutoSync:(BOOL)autoSync;               //更新播放进度
- (void)setAudioPlayerEnd:(BOOL)isEnd;                      //是否播放结束
- (void)audioPlayerDidUpdateTime:(NSTimeInterval)currentTime //跟新最新播放的秒数
                         duration:(NSTimeInterval)duration;


@end

@interface StoryMenuView : UIView<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) AVPlayer *playerAudio;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) UIButton *btnLanguage;     // 语言切换
@property (nonatomic, strong) UIButton *btnMenu;         // 菜单按钮
@property (nonatomic, strong) UIView *menuContainer;     // 菜单栏容器
@property (nonatomic, strong) UITableView *tableView;    // 故事书列表
@property (nonatomic, strong) UIView *audioControlView;  // 音频控制器    音频控制器
@property (nonatomic, strong) UIButton *playPauseButton; // 播放/暂停
@property (nonatomic, strong) UISlider *progressSlider;  // 进度条
@property (nonatomic, strong) UILabel *durationLabel;    // 时长显示
@property (nonatomic, strong) UIButton *unfoldButton;                 //用来展开更多按钮
@property (nonatomic, strong) UIButton *btnLocation;
@property (nonatomic, assign) BOOL isLanguageCn;      // 当前语言
@property (nonatomic, assign) NSInteger storyIndex;    // 当前选中索引
@property (nonatomic, weak) id<StoryMenuViewDelegate> delegate;
@property (nonatomic, strong) NSString *story_id;
@property (nonatomic, strong) NSDictionary *dicStory;
@property (nonatomic, strong) NSArray *textArray;
@property (nonatomic, strong) NSString *audio_en;
@property (nonatomic, strong) NSString *audio_cn;
@property (nonatomic, assign) NSInteger lastIndex;

//@property (nonatomic, assign) float main_end;     //  标题播放结束时间 中文
//@property (nonatomic, assign) float fallback_end;//   外文 播放结束时间
@property (nonatomic, strong) NSArray <NSDictionary *>*storyListArray; // 数据源 { @"cn":@"中文", @"en":@"英文" }

- (void)togglePlayPause:(UIButton *)sender;//点击播放 暂停
- (void)setResetAudioPlayer;

- (void)setMainLanguage;      // 切换语言
- (void)setupAudioControls;  // 设置音频控件
- (void)reloadStories;
- (void)pauseAndCloseAudioControls;

- (void)getMythStory:(int)isFairy;//yes 神话 no成语
/// 从该秒数 seek（内部用毫秒精度 CMTime，与安卓时间戳对齐）
- (void)clickCellToTime:(NSTimeInterval)start;
- (void)setMainAudioPlayer;//音频初始化

//是否弹出 定位 到音频读的那一行 //yes 显示文字，no 空回收
- (void)setLocationState:(BOOL)isShow;
- (void)setLocationInitialization;
- (void)updateNowPlayingInfo;
//- (void)setupRemoteControls;

- (BOOL)menuViewIsPlaying;//是否播放中
- (void)menuViewPlay;     //播放中
- (void)menuViewPause;    //暂停中
- (void)menuViewResume;   //恢复
- (void)menuForceStopAudio;//退出页面完全停止
- (void)setMenuViewIndex:(NSString *)strId;  //传入id 对应回合高亮
@end

NS_ASSUME_NONNULL_END
/*- (void)updateNowPlayingInfoXXX {

    NSString *title_cn = [NSString stringWithFormat:@"%@",self.dicStory[@"title_main"]];
    NSString *title_en = [NSString stringWithFormat:@"%@",self.dicStory[@"title_fallback"]];
    NSString *title = [Language_key isEqualToString:@"En"] ? title_en:title_cn;
    if(!title){
        title = @"";
    }
    // 1女娲    2后裔   //3 盘古
    //NSString *subtitle = [Language_key isEqualToString:@"En"] ?@"神话故事":@"神话故事";
    // 设置基本信息
    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
    [nowPlayingInfo setObject:title forKey:MPMediaItemPropertyTitle];

    NSString *head_image = [NSString stringWithFormat:@"%@",self.dicStory[@"head_image"]];
    //head_image
    // 设置封面图片
    UIImage *artworkImage = [UIImage imageNamed:@"blue_1024"];
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:artworkImage.size  requestHandler:^UIImage * _Nonnull(CGSize size) {
        return artworkImage;
    }];
    [nowPlayingInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
    
    //[nowPlayingInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
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
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
}*/
