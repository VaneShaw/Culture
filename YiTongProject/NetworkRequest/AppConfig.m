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
        // 默认语言
        //[self setLanguage:[NSLocale preferredLanguages].firstObject];
        self.main_host = HOST;
        [self setLanguage:@[@"cn",@"en"][IS_OVERSEAS_VERSION]];
        //NSLog(@"--------[%@]------first",[NSLocale preferredLanguages].firstObject);
    }
    return self;
}

- (void)setLanguage:(NSString *)language {
    self.main_host = HOST;
    
    NSLog(@"self.host-------------[%@]",self.main_host);
//    if ([language hasPrefix:@"cn"]) {
//        self.host = HOST_CN;
//    } else {
//        self.host = HOST_EN;
//    }
}

@end
