//
//  GuideManager.m
//  YiTongProject
//
//  Created by Vincent on 2025/8/15.
//

#import "GuideManager.h"
#define Guide_key @"quiz" //上架必备
@implementation GuideManager
+ (instancetype)shared {
    static GuideManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GuideManager alloc] init];
    });
    return instance;
}
- (BOOL)shouldShowGuideForPage:(NSString *)pageKey {
    NSString *guideKey = [NSString stringWithFormat:@"%@%@_guideShown",Guide_key,pageKey];
    return ![[NSUserDefaults standardUserDefaults] boolForKey:guideKey];
}
- (void)markGuideShownForPage:(NSString *)pageKey {
    NSString *guideKey = [NSString stringWithFormat:@"%@%@_guideShown",Guide_key,pageKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:guideKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (NSInteger)storedIndexForPage:(NSString *)pageKey {
    NSString *indexKey = [NSString stringWithFormat:@"%@%@_storedIndex",Guide_key,pageKey];
    return [[NSUserDefaults standardUserDefaults] integerForKey:indexKey];
}

- (void)storeIndex:(int)index forPage:(NSString *)pageKey {
    NSString *indexKey = [NSString stringWithFormat:@"%@%@_storedIndex",Guide_key,pageKey];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:indexKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)storeIndex:(NSInteger)index
             score:(NSInteger)score
           forPage:(NSString *)pageKey {
    NSString *infoKey = [NSString stringWithFormat:@"%@%@_info", Guide_key, pageKey];
    NSDictionary *info = @{
        @"index": @(index),
        @"score": @(score)
    };
    [[NSUserDefaults standardUserDefaults] setObject:info forKey:infoKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (NSInteger)storedQuizIndexForPage:(NSString *)pageKey {
    NSString *infoKey = [NSString stringWithFormat:@"%@%@_info", Guide_key, pageKey];
    NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:infoKey];
    return [info[@"index"] integerValue];
}
- (NSInteger)storedQuizScoreForPage:(NSString *)pageKey {
    NSString *infoKey = [NSString stringWithFormat:@"%@%@_info", Guide_key, pageKey];
    NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:infoKey];
    return [info[@"score"] integerValue];
}
@end
