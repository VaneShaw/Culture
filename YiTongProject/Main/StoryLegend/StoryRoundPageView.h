//
//  StoryRoundPageView.h
//  YiTongProject
//
//  Created by ios01 on 2026/1/5.
//

#import <UIKit/UIKit.h>
#import "StoryMenuView.h"
#import "VideoPlayerView.h"
#import "ReadHeaderView.h"
#import "ReadFooterView.h"
#import "StoryLockCoverView.h"

@class StorySectionModel;
@class StoryRoundPageView;
@protocol StoryRoundPageViewDelegate <NSObject>

- (BOOL)storyPageViewSwitchAudio:(StoryRoundPageView *)pageView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface StoryRoundPageView : UIView

@property (nonatomic, weak) id<StoryRoundPageViewDelegate> delegate;
@property (nonatomic, assign) NSInteger roundIndex;       //当前是第几个回合index
@property (nonatomic, assign) NSInteger currentIndex_1;   //v    当前在第几行

//yes : 音频读到哪里。对应的cell高亮就跟随，并且居中
//@property (nonatomic, assign) BOOL isAudioScrolling;     // 是否跟随音频滚动（默认YES）
//@property (nonatomic, assign) BOOL isPlayAudio_current;   //是否选中播放 后 才能执行
//yes 播放中 no 没有在播放       
                                          
@property (nonatomic, assign) BOOL gestureBound; // 是否已绑定外层 scrollView
@property (nonatomic, assign) StoryMenuView *menuView_1;
@property (nonatomic, strong) VideoPlayerView *playerViewVideo;   //v

@property (strong, nonatomic) StoryLockCoverView *cover;
@property (strong, nonatomic) UIColor *bg_ui_color;//
@property (strong, nonatomic) UIColor *title_Color;
@property (strong, nonatomic) UIColor *select_Color;//
@property (strong, nonatomic) UIColor *bg_bright_color; 
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataArray;
@property (strong, nonatomic) ReadFooterView *footerView;
@property (strong, nonatomic) ReadHeaderView *headerView;
- (void)startRecording;
- (void)cancelRecording;
@property (nonatomic, copy) void (^didSelectRowBlock)(int index);

- (instancetype)initWithFrame:(CGRect)frame
                         model:(StorySectionModel *)model;
- (void)scrollTableViewToBottomIfNeeded;
- (void)playAudioAtIndexPath:(NSIndexPath *)indexPath1 isStart:(BOOL)isStart;

- (void)scrollToCellAudioAtIndexCurrent:(NSInteger)index;
- (void)scrollToCellAtIndex:(NSInteger)index;
- (void)smoothScrollToIndex11:(NSInteger)index;
- (void)storyMenuViewAutoSync:(BOOL)autoSync;


- (NSTimeInterval)coverTitleAudioStartTime;//返回封面时间
@end

