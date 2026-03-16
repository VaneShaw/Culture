//
//  BaseViewController.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/5.
//

#import "BaseViewController.h"
#import "AnalyticsContext.h"
#import "AnalyticsManager.h"
@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // ⚠️ 在“页面成为 currentPage 之前”截胡
    self.fromPage =  [KUSER_DEFAULT objectForKey:@"analytics_last_page"];
    AnalyticsContext *ctx = [AnalyticsContext shared];              // 1️⃣ 记录页面流转关系
    ctx.lastPage  = self.fromPage;   //ctx.currentPage;             //
    ctx.currentPage = self.pageId;
    self.pageEnterTimeMs = [AnalyticsManager currentTimeMillis];    // 2️⃣ 记录进入时间
}
- (void)viewWillDisappear:(BOOL)animated {
    [KUSER_DEFAULT setObject:self.pageId forKey:@"analytics_last_page"];
    [super viewWillDisappear:animated];
    if (self.pageEnterTimeMs <= 0 || !self.pageId) return;
    if (self.pageEnterTimeMs <= 0) return;
    long long durationMs = [AnalyticsManager currentTimeMillis] - self.pageEnterTimeMs;
    
    if (durationMs <= 0) return;
    AnalyticsContext *ctx = [AnalyticsContext shared];
    NSMutableDictionary *event_params = [NSMutableDictionary dictionary];
    event_params[@"page"] = self.pageId;
    event_params[@"from"] = ctx.lastPage ?: @"unknown";
    event_params[@"duration"] = @(durationMs);//停留时长
    [[AnalyticsManager shared] trackEvent:EventTypePageView event_name:@"页面访问" params:event_params];
}
//--------------------------------------------------------------------
- (void)startStudy {
    self.studyStartTimeMs = [AnalyticsManager currentTimeMillis];
}
//学习 故事 练习统计事件
- (void)endStudyWithCompleted:(BOOL)completed
                  eventType:(NSString *)eventType
                   eventName:(NSString *)eventName
                  contentType:(NSString *)contentType
                   extraParams:(nullable NSDictionary *)extraParams {
    
    if (self.studyStartTimeMs <= 0) return;
    long long endTimeMs = [AnalyticsManager currentTimeMillis];
    long long durationMs = endTimeMs - self.studyStartTimeMs;
    //if (durationMs <= 0) return;
    if (durationMs < 3000) {
        self.studyStartTimeMs = 0; // 防止后续重复触发
        return;
    }
    NSMutableDictionary *event_params = [NSMutableDictionary dictionary];
    //event_params[@"content_id"] = self.storyId;       // 必填参数
    event_params[@"content_type"] = contentType;       //@"myth";
    event_params[@"duration"]      = @(durationMs / 1000.0); // 秒
    event_params[@"start_time_ms"] = @(self.studyStartTimeMs);
    event_params[@"end_time_ms"]   = @(endTimeMs);
    event_params[@"completed"]     = @(completed ? 1 : 0);
    // 额外参数（题数 / 正确数 / 分数）
    if (extraParams.count > 0) {
        [event_params addEntriesFromDictionary:extraParams];
    }
    //EventTypeStory @"故事阅读"
    [[AnalyticsManager shared] trackEvent:eventType
                               event_name:eventName
                                   params:event_params];
    //防止重复上报
    self.studyStartTimeMs = 0;
}

@end
/*
#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


