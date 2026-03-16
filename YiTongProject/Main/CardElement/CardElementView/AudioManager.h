//
//  AudioManager.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/21.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "BaseDataModel.h"
// 上传状态枚举
typedef NS_ENUM(NSInteger, UploadStatus) {
    UploadStatusNotStarted,  // 未开始
    UploadStatusInProgress,  // 上传中
    UploadStatusCompleted,   // 上传完成
    UploadStatusFailed       // 上传失败
};

NS_ASSUME_NONNULL_BEGIN
@interface AudioManager : NSObject<AVAudioRecorderDelegate, AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

+ (instancetype)sharedManager;

// 录音管理
- (void)startRecordingForLetter:(NSString *)letter;//字母录音
- (void)pauseRecording; //暂停播放
- (void)resumeRecording;//恢复播放
- (void)stopRecording;  //停止播放
- (BOOL)isRecording;    //正在录音

// 播放管理
- (void)playRecordingForLetter:(NSString *)letter;//播放字母录音
- (void)pausePlayback;//暂停播放
- (void)resumePlayback;//恢复播放
- (void)stopPlayback;  //停止播放
- (BOOL)isPlaying;     //正在播放

// 文件管理  //删除字母的记录-删除所有-记录存在的字母
- (void)deleteRecordingForLetter:(NSString *)letter;
- (void)deleteAllRecordings;
- (BOOL)recordingExistsForLetter:(NSString *)letter;
- (NSURL *)recordingURLForLetter:(NSString *)letter;
// 上传管理
/*
 - (void)uploadRecordingForLetter:(NSString *)letter
                      serverURL:(NSString *)serverURL
                       progress:(void(^)(float progress))progressBlock
                     completion:(void(^)(BOOL success, NSError *error))completionBlock;
*/
- (void)cancelUploadForLetter:(NSString *)letter;
- (UploadStatus)uploadStatusForLetter:(NSString *)letter;
//上传录音
- (void)uploadRecordingForLetter:(NSString *)letter
                          params:(NSDictionary *)params
                      completion:(void(^)(BOOL success,BaseDataModel *response, NSError * _Nullable error))completion;


@end

NS_ASSUME_NONNULL_END
