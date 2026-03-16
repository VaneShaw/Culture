//
//  AnalyticsManager.h
//  YiTongProject
//
//  Created by ios01 on 2026/2/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnalyticsManager : NSObject
@property (nonatomic, strong) NSMutableArray *eventQueue;


+ (instancetype)shared;
- (void)flushEvents;                                         // 批量上报
- (void)trackEvent:(NSString *)eventType event_name:(NSString *)event_name params:(nullable NSDictionary *)event_params;                     // 单条事件收集
+ (long long)currentTimeMillis;                              //当前时间戳
+ (NSTimeInterval)currentTimeSeconds;
//extern NSString * const EventTypeAppHeartbeat;

- (void)startHeartbeat;
- (void)stopHeartbeat;
@end

NS_ASSUME_NONNULL_END
//xxxx==============================
//- (void)bulkTrack {
    
    /*NSMutableDictionary *event_params = [NSMutableDictionary dictionary];
    event_params[@"page"] = @""; //当前页面
    event_params[@"from"] = @""; //从哪里来的
    event_params[@"duration"] = @"";//停留时长
    event_params[@"cold_start"] = @"";// 1冷启动 0热启动
    event_params[@"content_id"] = @"";//内容id
    event_params[@"content_type"] = @"";//内容类型
    event_params[@"start_time_ms"] = @([AnalyticsManager currentTimeMillis]);//学习开始时间戳
    event_params[@"end_time_ms"] = @([AnalyticsManager currentTimeMillis]);  //学习结束时间戳
    event_params[@"completed"] = @"";   //1 完成。0 未完成
    event_params[@"total"] = @"";       //总题数
    event_params[@"correct"] = @"";     //正确题数
    event_params[@"score"] = @"";       //总得分
    event_params[@"session_id"] = [KeychainUUID getUUID];
    //event_params[@"source"] = @"";//暂无用
    //==============================================================
    [[AnalyticsManager shared] trackEvent:EventTypeAppLaunch event_name:@"" params:event_params];
    // 满足条件时批量上报
    //[[AnalyticsManager shared] flushEvents];
    */
    //==============================================================
    /*
    NSMutableDictionary *events = [NSMutableDictionary dictionary];
    events[@"event_id"] = [[NSUUID UUID] UUIDString]; //事件id   事件类型   事件名称
    events[@"event_type"] = @"";
    events[@"event_name"] = @"";
    events[@"event_time_ms"] = @([AnalyticsManager currentTimeMillis]);
    events[@"event_params"] = event_params;
    */
    /*NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"batch_id"] = [KeychainUUID getUUID];
    params[@"platform"] = @"ios";
    params[@"app_version"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    params[@"device_id"] = [UIDevice currentDevice].identifierForVendor.UUIDString;//x
    params[@"os_version"] = UIDevice.currentDevice.systemVersion;//x
    params[@"region"] = @[@"cn",@"overseas"][IS_OVERSEAS_VERSION];
    params[@"user_type"] = @[@"1",@"2"][[[UserModel sharedInstance] isLogin]];
    params[@"user_id"] = [[UserModel sharedInstance] userId];//x
    params[@"guest_id"] = [[UserModel sharedInstance] userId];//x
    params[@"timezone"] = [NSTimeZone localTimeZone].name;
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger offsetSeconds = tz.secondsFromGMT;
    NSInteger offsetMinutes = offsetSeconds / 60;
    params[@"tz_offset"] = [NSString stringWithFormat:@"%ld", (long)offsetMinutes];
    params[@"events"] = events;
    [HttpTools postRequestUsers:@"/eventTrack/bulkTrack" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        if (success) {
        }
    } failure:^(NSError * _Nonnull error) {
    }];*/
//}
