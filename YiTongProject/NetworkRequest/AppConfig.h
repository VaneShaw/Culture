//
//  AppConfig.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppConfig : NSObject
@property (nonatomic, strong, readonly) NSString *main_host;

// 单例
+ (instancetype)sharedConfig;

// 设置语言/环境
- (void)setLanguage:(NSString *)language;
@end

NS_ASSUME_NONNULL_END
