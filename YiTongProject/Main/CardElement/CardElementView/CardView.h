//
//  CardView.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/10.
//

#import <UIKit/UIKit.h>
#import "HandwritingView.h"
#import "CardTipsView.h"
#import "VideoPlayerView.h"
#import "HanziCardView.h"
NS_ASSUME_NONNULL_BEGIN
@class CardView;

@protocol CardViewDelegate <NSObject>
- (void)cardViewDidTapButton:(CardView *)cardView;
@end

@interface CardView : UIView
@property (nonatomic, weak) id<CardViewDelegate> delegate;
@property (nonatomic, strong) id timeObserver;       // 播放进度监听
@property  (nonatomic, strong, nullable) AVPlayer *playerVideo; // 视频播放器

@property (strong, nonatomic) UIImageView *imgWrite;
@property (strong, nonatomic) UIImageView *imgPicture;//主图
@property (strong, nonatomic) UIPlayButton *btnPlayListen;
@property (strong, nonatomic) UIPlayButton *btnPlayRead;

@property (nonatomic, strong) UIView *listenView;
@property (nonatomic, strong) UIView *readView;
@property (strong, nonatomic) CardBaseView *writeView;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) CardBaseView *listenViewTemp;//公共容器
@property (nonatomic, strong) CardBaseView *readTemp;

@property (nonatomic, strong) HandwritingView *handwritingView;
@property (nonatomic, strong) UISegmentedControl *typeSegment;
@property (strong, nonatomic) NSDictionary *dicStrokes;
@property (strong, nonatomic) NSDictionary *dicStrokesTemp;
@property (strong, nonatomic) NSString *learn_audio_url;
@property (strong, nonatomic) NSString *audio_score;
@property (strong, nonatomic) NSString *audio_comment;

@property (strong, nonatomic) NSString *symbolTemp;
@property (strong, nonatomic) NSString *symbolTempStr;
@property (strong, nonatomic) NSString *symbolNumber;
@property (strong, nonatomic) UIScrollView *scrollViewTemp;
@property (nonatomic, strong) UIViewController *uvc;

@property (nonatomic, assign) BOOL isPlaying;  //1播放中   0没播放
@property (nonatomic, assign) BOOL isRecording;//1录音中   0没录音
@property (nonatomic, strong) VideoPlayerView *playerViewVideo;

- (void)loadWritingData:(NSArray *)strokesArray;
- (void)setCardCell:(NSDictionary *)dic;
- (void)setHanziCardCell:(NSDictionary *)dic;

- (void)destroyPlayer;
//play_1_1 开始录音
- (void)startRecording;
//play_1_2 暂停录音 停止录音
//- (void)stopRecording;
- (void)stopRecording:(BOOL)isUpload;
//play_4 播放录音
- (void)playRecording;
//停止播放
- (void)stopPlayback;
//play_5 删除录音
- (void)deleteRecording;
//上传录音
- (void)uploadRecording;
- (void)playAudioUrl:(NSString *)audioUrl;
- (void)configureWithType:(NSString *)type;
- (void)stopProgressTimer;

- (void)cardDidAppearDic:(NSDictionary *)dic;
- (void)cardDidDisappear:(NSDictionary *)dic;

@property (nonatomic, copy) void (^buttonClickBlock)(NSString *cardId, NSString *buttonId);
//- (void)quitTogglePlayPause;
@end

NS_ASSUME_NONNULL_END

/*
 - (void)startRecording {
     // 开始动画
     [self.animationView startAnimation];
     [self.animationView showRecording];
 }
 //录音已完成
 - (void)finishRecording {
     // 显示发送状态
     [self.animationView showSending];
 }
 //取消录音
 - (void)cancelRecording {
 // 开始
    [self.animationView startAnimation];
 // 停止动画
     [self.animationView stopAnimation];

 }
 */
/*/play_1 开始录音
- (void)toggleRecording {
    if (self.isRecording) {
        [self stopRecording];//停止录音
    } else {
        [self startRecording];
    }
}*/
//play_2 暂停录音
/*
 #pragma mark - UI状态更新 (增加上传部分)
 - (void)updateUIState {  //暂无用
     // ... 已有状态更新代码 ...
     //BOOL hasRecording = [[AudioManager sharedManager] recordingExistsForLetter:self.symbolTemp];//是否有数据
     //BOOL isRecording = [[AudioManager sharedManager] isRecording];//1录音中。0没录音
     //BOOL isPlaying = [[AudioManager sharedManager] isPlaying];    //1播放中。0没播放
     
     // 更新上传按钮状态
     UploadStatus uploadStatus = [[AudioManager sharedManager] uploadStatusForLetter:self.symbolTemp];
     //self.uploadButton.enabled = hasRecording && uploadStatus != UploadStatusCompleted;
     if (uploadStatus == UploadStatusInProgress) {
         //[self.uploadButton setTitle:@"取消上传" forState:UIControlStateNormal];
     } else if (uploadStatus == UploadStatusCompleted) {
         //[self.uploadButton setTitle:@"已上传" forState:UIControlStateNormal];
         //self.uploadButton.enabled = NO;
     } else {
         //[self.uploadButton setTitle:@"上传录音" forState:UIControlStateNormal];
     }
 }
 */

