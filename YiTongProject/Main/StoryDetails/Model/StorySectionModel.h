//
//  StorySectionModel.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, StorySectionType) {
    StorySectionTypeText,
    StorySectionTypeImage
};
@interface StorySectionModel : NSObject
@property (nonatomic, assign) StorySectionType type;
@property (nonatomic, copy) NSString *model_id;
@property (nonatomic, copy) NSString *chapter_no; //第几回合

@property (nonatomic, copy) NSString *fallback_end_time; //外语结束时间
@property (nonatomic, copy) NSString *main_end_time;     //中文结束时间

@property (nonatomic, copy) NSString *textCN;
@property (nonatomic, copy) NSString *textEN;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, copy) NSString *video_url;
@property (nonatomic, assign) BOOL isTitle;
@property (nonatomic, assign) CGFloat startTimeCN;
@property (nonatomic, assign) CGFloat endTimeCN;

@property (nonatomic, strong) NSArray *contents;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *coverImageName;
@property (nonatomic, copy) NSString *bg_color;
@property (nonatomic, copy) NSString *main_audio_url;
@property (nonatomic, copy) NSString *fallback_audio_url;
@property (nonatomic, copy) NSString *head_image;
@property (nonatomic, copy) NSString *font_color;
@property (nonatomic, copy) NSString *bright_color;
@property (nonatomic, copy) NSString *bright_bg_color;
@property (nonatomic, copy) NSString *is_lock;


@property (nonatomic, assign) CGFloat startTimeEN;
@property (nonatomic, assign) CGFloat endTimeEN;
//@property (nonatomic, assign) CGFloat imageHeight; // 可缓存比例高度
@property (nonatomic, assign) BOOL imageLoaded; // 新增标记 图片加载相关


- (void)setStartTimeCNWithString:(NSDictionary *)dicTime iskeyTime:(BOOL)isTime;
- (void)setStartTimeENWithString:(NSDictionary *)dicTime iskeyTime:(BOOL)isTime;
@end

NS_ASSUME_NONNULL_END
