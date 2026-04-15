//
//  AudioManager.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/21.
//

#import "AudioManager.h"
//字母录音管理-音频相关
@interface AudioManager ()
@property (nonatomic, copy) NSString *currentLetter;
@property (nonatomic, strong) NSURL *currentRecordingURLTemp;

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, copy) NSString *currentRecordingPath;
//上传管理
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionUploadTask *> *uploadTasks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *uploadProgress;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *uploadStatus;
@end

@implementation AudioManager

+ (instancetype)sharedManager {
    static AudioManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        //[sharedInstance setupAudioSession];
        sharedInstance.uploadTasks = [NSMutableDictionary dictionary];
        sharedInstance.uploadProgress = [NSMutableDictionary dictionary];
        sharedInstance.uploadStatus = [NSMutableDictionary dictionary];
    });
    return sharedInstance;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _audioSession = [AVAudioSession sharedInstance];
     
       
    }
    return self;
}
- (void)setupRecorder {
    // 设置录音会话
    NSError *sessionError = nil;
    //[_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    //[_audioSession setCategory:AVAudioSessionCategoryPlayback error:&sessionError];

    [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                   withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                         error:&sessionError];
    [_audioSession setActive:YES error:nil];

    if (sessionError) {
        NSLog(@"Audio Session error: %@", sessionError.localizedDescription);
        return;
    }
    
    [_audioSession setActive:YES error:&sessionError];
    if (sessionError) {
        NSLog(@"Audio Session activation error: %@", sessionError.localizedDescription);
        return;
    }
    
    // 设置录音文件路径
    //NSArray *pathComponents = @[
        //[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
        //[NSString stringWithFormat:@"%@_recording.m4a", self.currentLetter]
    //];
    //NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    //self.currentRecordingURLTemp = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_LetterRecording.m4a", self.currentLetter]];
    //path_str = @"LetterRecording.m4a";
  //-----------------------------------------新-----
    //NSString *path_str = [NSString stringWithFormat:@"%@_LetterRecording.m4a",self.currentLetter];
    //NSArray *pathComponents = @[
        //[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],path_str];
    //_currentRecordingPath = [NSURL fileURLWithPathComponents:pathComponents].path;
    //-----------------------------------------新-----
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    //NSURL *recordingURL = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_LetterRecording.m4a", self.currentLetter]];
    
    self.currentRecordingURLTemp = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_LetterRecording.m4a", self.currentLetter]];
    
    // 删除已存在的录音
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.currentRecordingURLTemp.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:self.currentRecordingURLTemp error:nil];
    }
    //----------------------------------------------新
//    // 如果文件已存在，则删除旧文件
//    if ([[NSFileManager defaultManager] fileExistsAtPath:_currentRecordingPath]) {
//        NSError *removeError = nil;
//        [[NSFileManager defaultManager] removeItemAtPath:_currentRecordingPath error:&removeError];
//        if (removeError) {
//            NSLog(@"Failed to remove existing file: %@", removeError.localizedDescription);
//            return;
//        }
//    }
    
    // 录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    
    // 设置录音格式为MPEG-4 AAC
    recordSettings[AVFormatIDKey] = @(kAudioFormatMPEG4AAC);
    recordSettings[AVSampleRateKey] = @(44100.0); // 采样率
    recordSettings[AVNumberOfChannelsKey] = @(1); // 单声道
    recordSettings[AVEncoderAudioQualityKey] = @(AVAudioQualityMedium); // 中等质量
    
    // 创建录音器
    NSError *recorderError = nil;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.currentRecordingURLTemp
                      
                                                settings:recordSettings
                                                   error:&recorderError];
    
    if (recorderError) {
        NSLog(@"Audio Recorder error: %@", recorderError.localizedDescription);
        return;
    }
    
    _audioRecorder.delegate = self;
    _audioRecorder.meteringEnabled = YES;
    
    if (![_audioRecorder prepareToRecord]) {
        NSLog(@"Failed to prepare recorder");
        return;
    }
}

#pragma mark - 上传管理

- (void)cancelUploadForLetter:(NSString *)letter {
    NSURLSessionUploadTask *task = self.uploadTasks[letter];
    if (task) {
        [task cancel];
        [self.uploadTasks removeObjectForKey:letter];
        self.uploadStatus[letter] = @(UploadStatusNotStarted);
        self.uploadProgress[letter] = @(0.0);
    }
}

- (UploadStatus)uploadStatusForLetter:(NSString *)letter {
    NSNumber *status = self.uploadStatus[letter];
    if (status) {
        return (UploadStatus)[status integerValue];
    }
    return UploadStatusNotStarted;
}
#pragma mark - 音频会话配置
- (void)setupAudioSession {
    /*NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    // 设置支持录音和播放
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
            withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth
                  error:&error];
    
    if (error) {
        NSLog(@"音频会话配置失败: %@", error.localizedDescription);
    } else {
        [session setActive:YES error:&error];
        if (error) {
            NSLog(@"激活音频会话失败: %@", error.localizedDescription);
        }
    }*/
}

#pragma mark - 录音管理


- (void)startRecordingForLetter:(NSString *)letter {
    // 停止当前录音或播放
    [self stopRecording];
    [self stopPlayback];
    
    // 设置当前字母
    self.currentLetter = letter;
    [self setupRecorder];
     [self.audioRecorder record];
    // 创建录音文件URL
    /*NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    self.currentRecordingURLTemp = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_recording.m4a", self.currentLetter]];
    
    // 删除已存在的录音
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.currentRecordingURLTemp.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:self.currentRecordingURLTemp error:nil];
    }
    
    // 录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    // 设置录音格式为MPEG-4 AAC
    recordSettings[AVFormatIDKey] = @(kAudioFormatMPEG4AAC);
    recordSettings[AVSampleRateKey] = @(44100.0); // 采样率
    recordSettings[AVNumberOfChannelsKey] = @(1); // 单声道
    recordSettings[AVEncoderAudioQualityKey] = @(AVAudioQualityMedium); // 中等质量
    
    
    
    // 创建录音器
    NSError *error = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.currentRecordingURLTemp
                                                    settings:recordSettings
                                                       error:&error];
    if (error) {
        NSLog(@"录音器初始化失败: %@", error.localizedDescription);
        return;
    }
    self.audioRecorder.delegate = self;
    self.audioRecorder.meteringEnabled = YES;
    [self.audioRecorder prepareToRecord];
    // 开始录音
    [self.audioRecorder record];*/
    NSLog(@"开始录音: [%@]-------", letter);
}
- (void)pauseRecording {
    if (self.audioRecorder && self.audioRecorder.isRecording) {
        [self.audioRecorder pause];
        NSLog(@"录音暂停: %@", self.currentLetter);
    }
}
- (void)resumeRecording {
    if (self.audioRecorder && !self.audioRecorder.isRecording) {
        [self.audioRecorder record];
        NSLog(@"录音恢复: %@", self.currentLetter);
    }
}
- (void)stopRecording {
    if (self.audioRecorder) {
        [self.audioRecorder stop];
        self.audioRecorder = nil;
        NSLog(@"录音停止: %@", self.currentLetter);
        
        
        
        NSError *deactivationError = nil;
        [_audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&deactivationError];
        if (deactivationError) {
            NSLog(@"Audio session deactivation error: %@", deactivationError.localizedDescription);
        }
        
        NSLog(@"Recording stopped");
        NSLog(@"Recording saved at path: --------[%@]--------path-------11-----", _currentRecordingPath);
    }
}
- (BOOL)isRecording {
    return self.audioRecorder && self.audioRecorder.isRecording;
}
#pragma mark - 播放管理
- (void)playRecordingForLetter:(NSString *)letter {
    // 停止当前播放或录音
    [self stopPlayback];
    [self stopRecording];
    // 设置当前字母
    self.currentLetter = letter;
    // 获取录音文件URL
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    self.currentRecordingURLTemp = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_LetterRecording.m4a", letter]];
    //NSLog(@"-------------[%@]-----url---",self.currentRecordingURL);
    // 检查文件是否存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.currentRecordingURLTemp.path]) {
        NSLog(@"录音文件不存在: [%@]---------", letter);
        return;
    }
    //创建播放器
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.currentRecordingURLTemp error:&error];
    if (error) {
        NSLog(@"播放器初始化失败: %@", error.localizedDescription);
        return;
    }
    self.audioPlayer.delegate = self;
    //self.audioPlayer.volume = 1.0;
    [self.audioPlayer prepareToPlay];
    //开始播放
    [self.audioPlayer play];
    NSLog(@"开始播放:[%@]", letter);
}
- (void)pausePlayback {
    if (self.audioPlayer && self.audioPlayer.isPlaying) {
        [self.audioPlayer pause];
        NSLog(@"播放暂停:[%@]", self.currentLetter);
    }
}
- (void)resumePlayback {
    if (self.audioPlayer && !self.audioPlayer.isPlaying) {
        [self.audioPlayer play];
        NSLog(@"播放恢复:[%@]", self.currentLetter);
    }
}
- (void)stopPlayback {
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
        NSLog(@"播放停止: %@", self.currentLetter);
        
        NSError *deactivationError = nil;
                [_audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&deactivationError];
                if (deactivationError) {
                    NSLog(@"Audio session deactivation error: %@", deactivationError.localizedDescription);
                }
                
                NSLog(@"Recording stopped");
                NSLog(@"Recording saved at path: [%@]--------------", _currentRecordingPath);
    }
}
- (BOOL)isPlaying {
    return self.audioPlayer && self.audioPlayer.isPlaying;
}
#pragma mark - 文件管理
- (void)deleteRecordingForLetter:(NSString *)letter {
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *fileURL = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_LetterRecording.m4a", letter]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
        
        if (error) {
            NSLog(@"删除录音失败: %@", error.localizedDescription);
        } else {
            NSLog(@"已删除录音: %@", letter);
        }
    }
}

- (void)deleteAllRecordings {
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtURL:documentsDirectory
                               includingPropertiesForKeys:nil
                                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                                    error:&error];
    
    if (error) {
        NSLog(@"获取文件列表失败: %@", error.localizedDescription);
        return;
    }
    
    for (NSURL *fileURL in files) {
        if ([fileURL.pathExtension isEqualToString:@"m4a"]) {
            [fileManager removeItemAtURL:fileURL error:&error];
            if (error) {
                NSLog(@"删除文件失败: %@", fileURL.lastPathComponent);
            }
        }
    }
    
    NSLog(@"已删除所有录音文件");
}

- (BOOL)recordingExistsForLetter:(NSString *)letter {
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *fileURL = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_LetterRecording.m4a", letter]];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path];
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"录音完成: 【%@】----a3--", self.currentLetter);
    } else {
        NSLog(@"录音失败: 【%@】----a2--", self.currentLetter);
    }
}
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"Recording encoding error: [%@]-----------a1", error.localizedDescription);
}
#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"播放完成: %@", self.currentLetter);
    }
    self.audioPlayer = nil;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"播放解码错误: %@", error.localizedDescription);
    self.audioPlayer = nil;
}




#pragma mark - 文件上传
//上传录音
- (void)uploadRecordingForLetter:(NSString *)letter
                          params:(NSDictionary *)params
                      completion:(void(^)(BOOL success,BaseDataModel *response, NSError * _Nullable error))completion {
    
    //==================================================================================

//    BaseDataModel *model1 = nil;
//    if (!wavURL || ![[NSFileManager defaultManager] fileExistsAtPath:wavURL.path]) {
//        NSLog(@"------错误---------111-------------11-------");
//        if (completion) completion(NO,model1, [NSError errorWithDomain:@"AudioManager"
//                                                        code:404
//                                                    userInfo:@{NSLocalizedDescriptionKey: @"录音文件不存在"}]);
//        return;
//    }
    //cafURL
    // 转换为WAV格式
    /*[self convertCAFToWAV:cafURL completion:^(NSURL * _Nullable wavURL, NSError * _Nullable error) {
        if (error || !wavURL) {
            NSLog(@"------错误--------222---------------22--------vs1--------");
            if (completion) completion(NO,model1, error ?: [NSError errorWithDomain:@"AudioManager"
                                                                     code:500
                                                                 userInfo:@{NSLocalizedDescriptionKey: @"格式转换失败"}]);
            return;
        }*/
        
        // 读取WAV文件数据
    NSURL *wavURL = [self recordingURLForLetter:letter];
       NSLog(@"wav0url--------[%@]---------11------vvv",wavURL);
        NSData *audioData = [NSData dataWithContentsOfURL:wavURL];
        BaseDataModel *model1 = nil;
        if (!audioData) {
            if (completion) completion(NO,model1, [NSError errorWithDomain:@"AudioManager"
                                                            code:500
                                                        userInfo:@{NSLocalizedDescriptionKey: @"无法读取音频数据"}]);
            return;
        }
        // 创建上传请求
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        //设置超时时间
        manager.requestSerializer.timeoutInterval = 30.0;
        //[manager setSessionDidReceiveAuthenticationChallengeBlock:]; // HTTPS证书问题
        //设置请求头
        [manager.requestSerializer setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
        NSString *authHeader = [KUSER_DEFAULT objectForKey:@"Authorization_key"];
        if(authHeader==nil){
            authHeader = @"";
        }
        if(authHeader.length > 0){
            [manager.requestSerializer setValue:authHeader forHTTPHeaderField:@"Authorization"];
        }
        // 设置可接受的响应类型
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                            @"application/json",
                                                            @"text/json",
                                                            @"text/javascript",
                                                            @"text/html",
                                                            @"text/plain",
                                                            nil];
        // 添加安全策略（特别是自签名证书）
        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        policy.allowInvalidCertificates = YES;  // 测试环境允许无效证书
        policy.validatesDomainName = NO;        // 不验证域名
        manager.securityPolicy = policy;
 
        //执行上传
        //NSLog(@"------[%@]------文件路径-------------22---------------",[NSString stringWithFormat:@"%@.m4a", letter]);
       
        //NSString *host = [AppConfig sharedConfig].main_host;
         NSString *host = HOST;
       //上传 跟读 评分 录音
        NSString *strUrl = [NSString stringWithFormat:@"%@%@",host,@[@"/speech/pinyinUpload",@"/speech/hanziScore"][IS_Formal_Hanzi]];
        [manager POST:[NSString stringWithFormat:@"%@",strUrl] // 替换为实际API地址
           parameters:params
              headers:nil
            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                [formData appendPartWithFileData:audioData
                                            name:@"read_audio"//@"audio"
                                        fileName:[NSString stringWithFormat:@"%@.m4a", letter]
                                        mimeType:@"audio/mp4"];
            }
            progress:^(NSProgress *uploadProgress) {
            //更新进度
          
            }
            success:^(NSURLSessionDataTask *task, id responseObject) {
            // 删除临时WAV文件
             //[[NSFileManager defaultManager] removeItemAtURL:wavURL error:nil];

            BaseDataModel *model = [BaseDataModel mj_objectWithKeyValues:responseObject];
                // 处理成功响应
                int code = [responseObject[@"code"] boolValue];
                
                if (code == 0) {
                    if (completion) completion(YES,model, nil);
                } else {
                    NSString *errorMsg = responseObject[@"message"] ?: @"上传失败";
                    NSError *error = [NSError errorWithDomain:@"AudioManager"
                                                      code:502
                                                  userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
                    if (completion) completion(NO,model, error);
                }
            }
            failure:^(NSURLSessionDataTask *task, NSError *error) {
                // 删除临时WAV文件
                //[[NSFileManager defaultManager] removeItemAtURL:wavURL error:nil];
                // 处理失败
                if (completion) completion(NO,nil, error);
            }];
    //}];
}

// 辅助方法：获取录音文件URL
- (NSURL *)recordingURLForLetter:(NSString *)letter {
    
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    return [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_LetterRecording.m4a", letter]];
}
@end


