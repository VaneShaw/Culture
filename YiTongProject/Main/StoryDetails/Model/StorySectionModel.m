//
//  StorySectionModel.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/30.
//

#import "StorySectionModel.h"

@implementation StorySectionModel

- (CGFloat)secondsFromFrameTimeString:(NSString *)timeString frameRate:(CGFloat)fps {
    NSArray<NSString *> *components = [timeString componentsSeparatedByString:@":"];
    if (components.count != 3) return 0;
    NSInteger minutes = [components[0] integerValue];
    NSInteger seconds = [components[1] integerValue];
    NSInteger frames = [components[2] integerValue];
    return minutes * 60 + seconds + (frames / fps);
}
//CGFloat totalSeconds = [self secondsFromFrameTimeString:@"01:06:11" frameRate:30];
//NSLog(@"%.2f", totalSeconds); // 66.37
/*- (NSInteger)timeStringToSeconds:(NSString *)timeString {
    NSArray *parts = [timeString componentsSeparatedByString:@":"];
    if (parts.count != 3) return 0;
    NSInteger hours = [parts[0] integerValue];
    NSInteger minutes = [parts[1] integerValue];
    NSInteger seconds = [parts[2] integerValue];
    return hours * 3600 + minutes * 60 + seconds;
}
// 实例方法
- (void)setStartTimeCNWithString:(NSDictionary *)dicTime {
    self.startTimeCN = [self secondsFromFrameTimeString:dicTime[@"main_start"] frameRate:30] - 0.3;
    self.endTimeCN = [self secondsFromFrameTimeString:dicTime[@"main_end"] frameRate:30] + 0.25;
}
- (void)setStartTimeENWithString:(NSDictionary *)dicTime {
    self.startTimeEN = [self secondsFromFrameTimeString:dicTime[@"fallback_start"] frameRate:30] - 0.3; //- 0.3
    self.endTimeEN = [self secondsFromFrameTimeString:dicTime[@"fallback_end"] frameRate:30] + 0.25;
}*/

// 实例方法
- (void)setStartTimeCNWithString:(NSDictionary *)dicTime iskeyTime:(BOOL)isTime {
    CGFloat leadTime = 0.35;      // 提前量（可调）
    CGFloat endTolerance = 0.20;  // 结束容差，避免高亮太快切走

    NSString *key_start = @[@"main_start",@"main_start_time"][isTime];
    NSString *key_end = @[@"main_end",@"main_end_time"][isTime];
    CGFloat start = [self secondsFromFrameTimeString:dicTime[key_start] frameRate:30];
    CGFloat end   = [self secondsFromFrameTimeString:dicTime[key_end]   frameRate:30];
    self.startTimeCN = start - leadTime;
    if (self.startTimeCN < 0) self.startTimeCN = 0; // 防止负数
    self.endTimeCN = end + endTolerance;
}
- (void)setStartTimeENWithString:(NSDictionary *)dicTime iskeyTime:(BOOL)isTime{
    CGFloat leadTime = 0.35;      // 提前量（可调）
    CGFloat endTolerance = 0.20;  // 结束容差，避免高亮太快切走
  
    NSString *key_start = @[@"fallback_start",@"fallback_start_time"][isTime];
    NSString *key_end = @[@"fallback_end",@"fallback_end_time"][isTime];
    CGFloat start = [self secondsFromFrameTimeString:dicTime[key_start] frameRate:30];
    CGFloat end = [self secondsFromFrameTimeString:dicTime[key_end] frameRate:30];
    self.startTimeEN = start - leadTime;
    if (self.startTimeEN < 0) self.startTimeEN = 0; // 防止负数
    self.endTimeEN = end + endTolerance;
}
@end
