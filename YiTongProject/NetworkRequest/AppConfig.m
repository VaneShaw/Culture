//
//  AppConfig.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/16.
//

#import "AppConfig.h"
@interface AppConfig ()
@property (nonatomic, strong, readwrite) NSString *main_host;
@end
@implementation AppConfig
+ (instancetype)sharedConfig {
    static AppConfig *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[AppConfig alloc] init];
        
    });
    return config;
}

- (instancetype)init {
    if (self = [super init]) {
        // 根据构建配置和版本自动选择host
        [self updateHost];
        [self setLanguage:@[@"cn",@"en"][IS_OVERSEAS_VERSION]];
        //NSLog(@"--------[%@]------first",[NSLocale preferredLanguages].firstObject);
    }
    return self;
}

- (void)setLanguage:(NSString *)language {
    // 语言变化时，重新更新host（Release模式下会根据版本选择）
    [self updateHost];
    
    NSLog(@"self.host-------------[%@]",self.main_host);
}

// 根据构建配置和版本自动更新host
- (void)updateHost {
#ifdef DEBUG
    // Debug模式：使用测试环境
    self.main_host = HOST_TEST;
#else
    // Release模式：根据国内版/国外版选择对应的正式环境host
    if (IS_OVERSEAS_VERSION) {
        // 海外版
        self.main_host = HOST_PRODUCTION_OVERSEAS;
    } else {
        // 国内版
        self.main_host = HOST_PRODUCTION_DOMESTIC;
    }
#endif
}

@end
