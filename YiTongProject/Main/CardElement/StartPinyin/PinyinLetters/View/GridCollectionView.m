//
//  GridCollectionView.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/4.
//

#import "GridCollectionView.h"
#import "AudioPlayerManager.h"
//#import "VoiceAnimationView.h"
@interface GridCollectionView () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) GridCollectionViewCell *cell;
@end
@implementation GridCollectionView
- (instancetype)initWithFrame:(CGRect)frame {
    // 创建布局
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.dataArrays = [NSMutableArray new];
    // 计算布局参数
    CGFloat leftMargin = 20.0;
    NSInteger itemsPerRow = 4;
    //CGFloat minAllowedSpacing = 5.0;
    //CGFloat minCellSize = 50.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handlePlayFinished:)
                                               name:@"AudioPlayStartPlayinghNotification"
                                             object:nil];


    //间距。 //cell宽
    CGFloat spacing = SCREEN_WIDTH > 395 ? 15 : 13;
    CGFloat cellWidth = (SCREEN_WIDTH - 40 - 3 * spacing)/4;

    // 5. 取整
    CGFloat cellSize = floor(cellSize);
    if(leftMargin * 2 + 3 * spacing + itemsPerRow * cellWidth > SCREEN_WIDTH){
        cellWidth = cellWidth - 1;
    }
    cellSize = cellWidth;
    // 配置布局
    layout.itemSize = CGSizeMake(cellSize, cellSize);
    layout.minimumLineSpacing = spacing;
    layout.minimumInteritemSpacing = spacing;
    layout.sectionInset = UIEdgeInsetsMake(spacing, leftMargin, spacing, leftMargin);
    
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.dataSource = self;
        self.delegate = self;
        
        // 注册单元格
        [self registerClass:[GridCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    }
    return self;
}
- (void)reloadWithData:(NSArray *)data {
    self.dataArrays = [NSMutableArray arrayWithArray:data];
    [self reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArrays.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GridCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    //cell.titleLabel.text = self.data[indexPath.item];
    // 设置不同背景色
    //CGFloat hue = (indexPath.item % 20) / 20.0;
    //cell.backgroundColor = [UIColor colorWithHue:hue saturation:0.7 brightness:0.9 alpha:1.0];
    if(self.tag == 300){
        [cell setCellPronunciation:self.dataArrays[indexPath.row]];
    } else {
        //cell.lblTitle.text = @"Aɑ";
        [cell setCellAlphabet:self.dataArrays[indexPath.row]];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //if ([self.gridDelegate respondsToSelector:@selector(didSelectItemAtIndex:)]) {
        //[self.gridDelegate didSelectItemAtIndex:indexPath.item];
    //}
    self.cell = (GridCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    NSString *audio_url = [NSString stringWithFormat:@"%@",self.dataArrays[indexPath.row][@"audio_url"]];
    if(audio_url){
        [self playAudio:audio_url];
    }
    if(self.selectedTypeIndex){
        self.selectedTypeIndex((int)indexPath.item);
    }
}
//AudioPlayStartPlayinghNotification
- (void)handlePlayFinished:(NSNotification *)notification {
    BOOL isFinished = [notification.userInfo[@"status"] boolValue];
    if (isFinished) {
        [self.cell startRecording];//开始动画
    } else {
        [self.cell finishRecording];
    }
}
- (void)playAudio:(NSString *)audio_url {
    [self.cell startRecording];//开始动画
    [[AudioPlayerManager sharedManager] playShortAudioWithURL:audio_url completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            // 播放成功完成
            [self updateUIForPlaybackSuccess];
        } else {
            // 处理播放错误
            [self handlePlaybackError:error];
        }
    }];
}

- (void)updateUIForPlaybackSuccess {
    // 更新UI显示播放成功
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cell finishRecording];
    });
}
- (void)handlePlaybackError:(NSError *)error {
    // 处理错误并更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cell finishRecording];
    });
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

