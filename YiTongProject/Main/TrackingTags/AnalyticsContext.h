//
//  AnalyticsContext.h
//  YiTongProject
//
//  Created by ios01 on 2026/2/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnalyticsContext : NSObject
@property (nonatomic, copy) NSString *currentPage;
@property (nonatomic, copy) NSString *lastPage;

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
