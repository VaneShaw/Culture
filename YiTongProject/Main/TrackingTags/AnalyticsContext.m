//
//  AnalyticsContext.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/5.
//

#import "AnalyticsContext.h"

@implementation AnalyticsContext
+ (instancetype)shared {
    static AnalyticsContext *ctx;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ctx = [[AnalyticsContext alloc] init];
    });
    return ctx;
}
@end
