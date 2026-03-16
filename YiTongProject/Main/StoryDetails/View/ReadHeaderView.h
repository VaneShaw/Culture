//
//  ReadHeaderView.h
//  YiTongProject
//
//  Created by ios01 on 2025/11/4.
//

#import <UIKit/UIKit.h>
#import "VideoPlayerView.h"
NS_ASSUME_NONNULL_BEGIN

@interface ReadHeaderView : UIView
@property (strong, nonatomic) UIImageView *headerImageView;
@property (strong, nonatomic) UIViewController *uvc;


- (VideoPlayerView *)setupVideoIfVideoUrl:(NSString *)videoUrl;
- (void)loadTopImageWithURL:(NSString *)urlString hasVideo:(BOOL)hasVideo ;
@end

NS_ASSUME_NONNULL_END
