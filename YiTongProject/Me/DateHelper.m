//
//  DateHelper.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/8.
//

#import "DateHelper.h"

@implementation DateHelper
/// 统一日期格式化
+ (NSString *)formattedDateString:(NSTimeInterval)timestamp {
    // 🔑 如果后端是毫秒，这里必须 /1000
    if (timestamp > 100000000000) { // 简单判断是否是 ms
        timestamp = timestamp / 1000.0;
    }

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [NSLocale currentLocale];
    fmt.timeZone = [NSTimeZone localTimeZone];//改变时间戳
    //====================================================
    /*NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [NSLocale currentLocale];*/

    // 英文：Dec 27
    // 中文：12月27日
    if (IS_OVERSEAS_VERSION) {
        fmt.dateFormat = @"MMM d";
        //fmt.dateFormat = @"MMM d, HH:mm";
    } else {
        fmt.dateFormat = @"M月d日";
        //fmt.dateFormat = @"M月d日 HH:mm";
    }
    return [fmt stringFromDate:date];
}

/// 自动续费文案
+ (NSString *)autoRenewsOnString:(NSTimeInterval)timestamp {
    NSString *dateStr = [self formattedDateString:timestamp];

    if (IS_OVERSEAS_VERSION) {

        return [NSString stringWithFormat:@"Auto-renews on %@", dateStr];
    } else {
        return [NSString stringWithFormat:@"已开通 · 将于%@自动续费", dateStr];
    }
}

/// 会员到期文案
+ (NSString *)subscriptionExpiresString:(NSTimeInterval)timestamp {
    NSString *dateStr = [self formattedDateString:timestamp];


    if (IS_OVERSEAS_VERSION) {
        return [NSString stringWithFormat:@"Subscription expires %@", dateStr];
    } else {
        return [NSString stringWithFormat:@"会员权益将于%@到期", dateStr];
    }
}
@end
