//
//  SubscriptionAlertHelper.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SubscriptionAlertHelper : NSObject
+ (BOOL)shouldShowAlertForDaysLeft:(NSInteger)daysLeft expireTimestamp:(NSTimeInterval)expireTimestamp;

@end

NS_ASSUME_NONNULL_END
