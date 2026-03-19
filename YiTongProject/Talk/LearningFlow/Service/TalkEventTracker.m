//
//  TalkEventTracker.m
//  YiTongProject
//

#import "TalkEventTracker.h"
#import "HeaderConfig.h"

static NSString *const kTalkEventQueueKey = @"talk_event_queue";

@interface TalkEventTracker ()
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *queue;
@end

@implementation TalkEventTracker

/**
 学习流埋点（MVP）
 
 设计目标：
 - 不依赖后端也能完整记录关键事件（进入/提交/完成/解锁等），便于联调与验收
 - 事件先落本地队列，后续接接口可在 `flushIfNeeded` 里批量上报并清空
 
 说明：
 - 这里用 `AnalyticsManager currentTimeMillis` 统一时间戳口径（与工程现有埋点保持一致）
 - 队列设置简单上限（50），避免用户长时间使用导致无限增长
 */
+ (instancetype)shared {
    static TalkEventTracker *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[TalkEventTracker alloc] init];
        s.queue = [NSMutableArray array];
        // 启动时恢复上次未上报的事件队列（MVP：仅恢复，不真正上报）
        id cached = [KUSER_DEFAULT objectForKey:kTalkEventQueueKey];
        if ([cached isKindOfClass:[NSArray class]]) {
            [s.queue addObjectsFromArray:(NSArray *)cached];
        }
    });
    return s;
}

- (void)track:(NSString *)eventName params:(NSDictionary *)params {
    if (eventName.length == 0) return;
    NSMutableDictionary *e = [NSMutableDictionary dictionary];
    e[@"event_name"] = eventName;
    e[@"event_time_ms"] = @([AnalyticsManager currentTimeMillis]);
    if (params) e[@"event_params"] = params;
    [self.queue addObject:e];
    // 先持久化，保证闪退/杀进程后仍可追溯
    [KUSER_DEFAULT setObject:self.queue forKey:kTalkEventQueueKey];
    NSLog(@"[TalkEvent] %@ %@", eventName, params ?: @{});
    [self flushIfNeeded];
}

- (void)flushIfNeeded {
    // MVP：仅做队列持久化；后续接接口后在这里批量上报并清空
    // 约束：
    // - 当前不会真的“flush”，只做长度控制；避免用户离线长期使用导致存储膨胀
    // - 接后端后建议：按批次上报成功后再清空，失败则保留重试
    if (self.queue.count > 50) {
        // 简单裁剪，避免无限增长
        NSRange r = NSMakeRange(0, self.queue.count - 50);
        [self.queue removeObjectsInRange:r];
        [KUSER_DEFAULT setObject:self.queue forKey:kTalkEventQueueKey];
    }
}

@end

