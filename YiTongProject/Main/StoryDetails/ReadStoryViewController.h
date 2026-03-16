//
//  ReadStoryViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReadStoryViewController : BaseViewController
@property (strong, nonatomic) NSString *storyId;
@property (nonatomic, assign) BOOL isFairy;//1 神话。0 成语


//- (void)loadStoryData:(NSString *)storyId;   // 切换故事时调用
@end

NS_ASSUME_NONNULL_END

/*
 "audio_cn" = "https://testoss.shiyi-yitong.com/story/myth/videos/nvwa_cn.MP3";
 "audio_en" = "https://testoss.shiyi-yitong.com/story/myth/videos/nvwa_en.MP3";
 "bg_color" = "#EAE0CC";
 "bright_color" = "#7F3400";
 "font_color" = "#000000";
 id = 1;
 "images_url" = "https://testoss.shiyi-yitong.com/story/myth/images/nvwa_head.png";
 status = 1;
 "title_cn" = "\U5973\U5a32\U8865\U5929";
 "title_en" = "N\U00fcw\U0251 Mends the Sky";
 "video_url" = "<null>";
 
 self.videoUrl = @"https://testoss.shiyi-yitong.com/pinyin/initials/videos/m.mp4";
 */
