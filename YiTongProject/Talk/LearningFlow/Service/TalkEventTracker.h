//
//  TalkEventTracker.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// PRD 10章埋点：MVP 先本地队列暂存 + NSLog；后续可切到后端 bulkTrack
///
/// 使用约定：
/// - params 建议只放基础类型（NSString/NSNumber/NSDictionary/NSArray），便于持久化与上报
/// - 事件名建议稳定且可枚举（例如：unit_enter / unit_complete）
@interface TalkEventTracker : NSObject

+ (instancetype)shared;

- (void)track:(NSString *)eventName params:(nullable NSDictionary *)params;
- (void)flushIfNeeded;

@end

NS_ASSUME_NONNULL_END

