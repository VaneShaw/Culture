//
//  StorySectionModel.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/30.
//

#import "StorySectionModel.h"
#import "PublicTool.h"

@implementation StorySectionModel

// 实例方法
- (void)setStartTimeCNWithString:(NSDictionary *)dicTime iskeyTime:(BOOL)isTime {
    // 时间码与安卓一致：分:秒:第三段，第三段×10 为毫秒；结束侧略延长便于高亮衔接
    CGFloat endTolerance = 0.20;

    NSString *key_start = @[@"main_start",@"main_start_time"][isTime];
    NSString *key_end = @[@"main_end",@"main_end_time"][isTime];
    CGFloat start = (CGFloat)[PublicTool secondsFromColonTimeStringLikeAndroid:dicTime[key_start]];
    CGFloat end = (CGFloat)[PublicTool secondsFromColonTimeStringLikeAndroid:dicTime[key_end]];
    self.startTimeCN = MAX(0, start);
    self.endTimeCN = end + endTolerance;
}
- (void)setStartTimeENWithString:(NSDictionary *)dicTime iskeyTime:(BOOL)isTime{
    CGFloat endTolerance = 0.20;

    NSString *key_start = @[@"fallback_start",@"fallback_start_time"][isTime];
    NSString *key_end = @[@"fallback_end",@"fallback_end_time"][isTime];
    CGFloat start = (CGFloat)[PublicTool secondsFromColonTimeStringLikeAndroid:dicTime[key_start]];
    CGFloat end = (CGFloat)[PublicTool secondsFromColonTimeStringLikeAndroid:dicTime[key_end]];
    self.startTimeEN = MAX(0, start);
    self.endTimeEN = end + endTolerance;
}
@end
