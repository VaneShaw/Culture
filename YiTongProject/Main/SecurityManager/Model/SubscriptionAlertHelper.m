//
//  SubscriptionAlertHelper.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/4.
//

#import "SubscriptionAlertHelper.h"

@implementation SubscriptionAlertHelper
+ (NSString *)todayString {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    return [fmt stringFromDate:[NSDate date]];
}

+ (NSString *)stringFromTimestamp:(NSTimeInterval)timestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    return [fmt stringFromDate:date];
}

+ (BOOL)shouldShowAlertForDaysLeft:(NSInteger)daysLeft expireTimestamp:(NSTimeInterval)expireTimestamp {
    if (daysLeft < 0) return NO; // 已过期
    
    NSString *expireKey = [self stringFromTimestamp:expireTimestamp];
    NSString *daysKey = [NSString stringWithFormat:@"%ld", (long)daysLeft];
    NSMutableDictionary *allShown = [[KUSER_DEFAULT objectForKey:@"SubscriptionAlertShown"] mutableCopy];
    if (!allShown) allShown = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *shownForThisExpire = [[allShown objectForKey:expireKey] mutableCopy];
    if (!shownForThisExpire) shownForThisExpire = [NSMutableDictionary dictionary];
    if (shownForThisExpire[daysKey] != nil) {
        //已弹过
        return NO;
    }
    // 还没弹，记录并返回 YES
    shownForThisExpire[daysKey] = [self todayString];
    allShown[expireKey] = shownForThisExpire;
    
    [KUSER_DEFAULT setObject:allShown forKey:@"SubscriptionAlertShown"];
    [KUSER_DEFAULT synchronize];
    return YES;
}

@end
