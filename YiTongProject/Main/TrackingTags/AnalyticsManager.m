//
//  AnalyticsManager.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/3.
//
#import "AnalyticsManager.h"
#import <UIKit/UIKit.h>

@interface AnalyticsManager ()
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, assign) long long foregroundStartTimeMs;

@property (nonatomic, assign) BOOL isUploading;
@property (nonatomic, assign) NSTimeInterval lastSuccessUploadTime; // 👈 新增 记录“上一次成功上报的时间”
@end

@implementation AnalyticsManager

+ (instancetype)shared {
    static AnalyticsManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AnalyticsManager alloc] init];
        instance.eventQueue = [NSMutableArray array];
        instance.lastSuccessUploadTime = [[NSDate date] timeIntervalSince1970];
        [instance restoreCachedEvents];
    });
    return instance;
}
- (void)restoreCachedEvents {
    NSArray *cache = [KUSER_DEFAULT objectForKey:Analytics_Events_Key];
    if ([cache isKindOfClass:[NSArray class]] && cache.count > 0) {
        //[self.eventQueue addObjectsFromArray:cache];
    }
}
- (void)tryFlushIfNeeded {

    NSInteger count = self.eventQueue.count;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    BOOL reachCountThreshold = count >= 20;
    BOOL reachTimeThreshold = (now - self.lastSuccessUploadTime >= 30);
    
    // 规则：
    // 1️⃣ 条数达到 20
    // 2️⃣ 超过 30 秒 + 当前产生新事件（因为是 addEvent 里触发）

    if (reachCountThreshold || reachTimeThreshold) {
        //[self flushEvents];
    }
}
- (void)flushEvents {
    
    /*if (self.eventQueue.count == 0) return;
    if (self.isUploading) return;
    self.isUploading = YES;
    
    // TODO: 网络请求上报
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"batch_id"] = [KeychainUUID getUUID];
    params[@"platform"] = @"ios";
    params[@"app_version"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    params[@"device_id"] = [UIDevice currentDevice].identifierForVendor.UUIDString;//x
    params[@"os_version"] = UIDevice.currentDevice.systemVersion;//x
    params[@"region"] = @[@"cn",@"overseas"][IS_OVERSEAS_VERSION];
    params[@"user_type"] = @[@"1",@"2"][[[UserModel sharedInstance] isLogin]];
    params[@"user_id"] = [[UserModel sharedInstance] userId];//x
    params[@"guest_id"] = [KUSER_DEFAULT objectForKey:Guest_Uuid_Key];//x
    params[@"timezone"] = [NSTimeZone localTimeZone].name;
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger offsetSeconds = tz.secondsFromGMT;
    NSInteger offsetMinutes = offsetSeconds / 60;
    params[@"tz_offset"] = [NSString stringWithFormat:@"%ld", (long)offsetMinutes];
    params[@"events"] = [self.eventQueue copy];
     
    // TODO: 发送到后端接口
    [HttpTools postRequestUsers:@"/eventTrack/bulkTrack" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        self.isUploading = NO;
        if (success) {
            // 上报完成，清空队列
            [self.eventQueue removeAllObjects];
            //self.lastSuccessUploadTime =  [[NSDate date] timeIntervalSince1970];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:Analytics_Events_Key];
        }
    } failure:^(NSError * _Nonnull error) {
    }];*/
    
}
+ (long long)currentTimeMillis {//当前时间戳
    return (long long)([[NSDate date] timeIntervalSince1970] * 1000);
}
+ (NSTimeInterval)currentTimeSeconds {
    return [[NSDate date] timeIntervalSince1970];
}
//独立事件 页面访问事件 登录 注册 注销         统计事件合流后这走这里
- (void)trackEvent:(NSString *)eventType event_name:(NSString *)event_name params:(nullable NSDictionary *)event_params {
    /*if (eventType.length == 0) return;
    NSMutableDictionary *events = [NSMutableDictionary dictionary];
    events[@"event_id"] = [[NSUUID UUID] UUIDString];       //事件id  事件类型   事件名称
    events[@"event_type"] = eventType;
    events[@"event_name"] = event_name ?: @"";
    events[@"event_time_ms"] = @([AnalyticsManager currentTimeMillis]);
    if (event_params) {
        events[@"event_params"] = event_params;
    }
    [self.eventQueue addObject:events];
    [KUSER_DEFAULT setObject:self.eventQueue forKey:Analytics_Events_Key];
    [self tryFlushIfNeeded]; */
   
}

//[[AnalyticsManager shared] trackEvent:EventTypeCancel event_name:@"注销" params:nil];
// 进入前台。 开始计时并启动心跳
- (void)startHeartbeat {
    self.foregroundStartTimeMs = [AnalyticsManager currentTimeMillis];
    // 每 10 秒触发一次
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                           target:self
                                                         selector:@selector(heartbeatTick)
                                                         userInfo:nil
                                                          repeats:YES];
}
// 停止心跳（比如进入后台）
- (void)stopHeartbeat {
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
}
// 心跳触发方法
- (void)heartbeatTick {
    long long nowMs = [AnalyticsManager currentTimeMillis];
    long long durationSec = (nowMs - self.foregroundStartTimeMs) / 1000;
    if (durationSec <= 0) return;     // 上报事件
    NSMutableDictionary *event_params = [NSMutableDictionary dictionary];
    event_params[@"session_id"] = [KeychainUUID getUUID];
    event_params[@"duration"] = @(durationSec);//停留时长
    [[AnalyticsManager shared] trackEvent:EventTypeAppHeartbeat event_name:@"app使用时长累加" params:event_params];
    // 重置计时
    self.foregroundStartTimeMs = nowMs;
}
@end

