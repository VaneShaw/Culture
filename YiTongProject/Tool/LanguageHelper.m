//
//  LanguageHelper.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/29.
//

#import "LanguageHelper.h"
#import <objc/runtime.h>

NSString * const LanguageDidChangeNotification = @"LanguageDidChangeNotification";
static const char _bundle = 0;
//多语言管理 
@interface PrivateBundle : NSBundle @end
@implementation PrivateBundle
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    NSBundle *bundle = objc_getAssociatedObject(self, &_bundle);
    return bundle ? [bundle localizedStringForKey:key value:value table:tableName]
                  : [super localizedStringForKey:key value:value table:tableName];
}
@end

@implementation LanguageHelper

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object_setClass([NSBundle mainBundle], [PrivateBundle class]);
    });
}
+ (void)setLanguage:(NSString *)language {
    NSString *path = [[NSBundle mainBundle] pathForResource:language ofType:@"lproj"];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    
    if (bundle) {
         objc_setAssociatedObject([NSBundle mainBundle], &_bundle, bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
         [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"appLanguage"];
         [[NSUserDefaults standardUserDefaults] synchronize];
     } else {
         NSLog(@"⚠️ 没找到 lproj 文件：%@", language);
     }
    // 通知所有页面更新
    [[NSNotificationCenter defaultCenter] postNotificationName:LanguageDidChangeNotification object:nil];
}
+ (NSMutableDictionary *)currentLanguageParams:(NSMutableDictionary *)params {
    params[@"lang"] = @[@"cn",@"en"][IS_OVERSEAS_VERSION];
    return params;
}

+ (NSString *)currentLanguage {

    // 1. 先看用户是否手动选过
    NSString *lang = [[NSUserDefaults standardUserDefaults] objectForKey:@"appLanguage"];
    if (lang) {
        return lang;
    }
    //韩
    // 2. 如果没有，就取系统语言
    NSString *systemLang = [[NSLocale preferredLanguages] firstObject];
    // systemLang 可能是 "zh-Hans-CN" / "ja-JP" / "ko-KR" 之类
    // 3. 只取前面部分（标准化）
    NSArray *parts = [systemLang componentsSeparatedByString:@"-"];
    NSString *langCode = parts.firstObject;  // 比如 "zh"
    
    // 特殊处理中文（因为 iOS 有 zh-Hans, zh-Hant）
    if ([systemLang hasPrefix:@"zh-Hans"]) {
        langCode = @"zh-Hans";
    } else if ([systemLang hasPrefix:@"zh-Hant"]) {
        //langCode = @"zh-Hant";// 繁体 也能返回简体
        langCode = @"zh-Hans";
    }
    
    // 4. 检查项目里是否有对应的 lproj
    NSString *path = [[NSBundle mainBundle] pathForResource:langCode ofType:@"lproj"];
    if (!path) {
        langCode = @"en"; // 没有就默认英文
    }
    // 5. 保存下来，避免下次重复判断
    [[NSUserDefaults standardUserDefaults] setObject:langCode forKey:@"appLanguage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return langCode;
}

@end
