//
//  GridCollectionViewCell.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/4.
//

#import <UIKit/UIKit.h>
//#import "VoiceAnimationView.h"
#import "AnimatedImageView.h"
NS_ASSUME_NONNULL_BEGIN

@interface GridCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imgIcon;
@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UILabel *lblSubtitle;
@property (nonatomic, strong) UILabel *lblAlphabet;
//@property (nonatomic, strong) VoiceAnimationView *animationView;
@property (nonatomic, strong) AnimatedImageView *animatedImage;
@property (nonatomic, strong) NSTimer *audioSimulationTimer;

- (void)setCellPronunciation:(NSDictionary *)dic;
- (void)setCellAlphabet:(NSDictionary *)dic;

- (void)startRecording;
//录音已完成
- (void)finishRecording;
@end

NS_ASSUME_NONNULL_END
