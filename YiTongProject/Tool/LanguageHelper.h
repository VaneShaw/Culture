//
//  LanguageHelper.h
//  YiTongProject
//
//  Created by ios01 on 2025/8/29.
//

#import <Foundation/Foundation.h>

extern NSString * const LanguageDidChangeNotification;

@interface LanguageHelper : NSObject

+ (void)setLanguage:(NSString *)language;   // @"en", @"zh-Hans", @"ja"
+ (NSString *)currentLanguage;
+ (NSMutableDictionary *)currentLanguageParams:(NSMutableDictionary *)params;
@end

// 定义一个宏，代替系统的 NSLocalizedString
//#define MyLocalizedString(key, comment) [LanguageHelper localizedStringForKey:(key)]
//[LanguageHelper setLanguage:@[@"en",@"zh-Hans",@"ja"][1]];
//NSString *hello = NSLocalizedString(@"hello_text", @"问候语");


//系统地区
//NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
//如果系统地区选的是「中国大陆」 → CN    如果地区是「美国」 → US        如果地区是「韩国」 → KR
//系统语言
//NSString *language = [[NSLocale preferredLanguages] firstObject];
//简体中文 → zh-Hans-CN      英语（美国） → en-US           韩语 → ko-KR
