//
//  DateHelper.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DateHelper : NSObject
+ (NSString *)autoRenewsOnString:(NSTimeInterval)timestamp;
+ (NSString *)subscriptionExpiresString:(NSTimeInterval)timestamp;
@end

NS_ASSUME_NONNULL_END
