//
//  YTVFeedResumeCache.m
//  YiTongProject
//

#import "YTVFeedResumeCache.h"

static const NSTimeInterval kYTVFeedResumeCacheTTL = 24 * 60 * 60;

static NSString *YTVFeedResumeSafeFileComponent(NSString *categoryKey) {
    NSString *base = categoryKey.length > 0 ? categoryKey : @"default";
    NSCharacterSet *bad = [NSCharacterSet characterSetWithCharactersInString:@"/\\:?%*|\"<>\n\r"];
    return [[base componentsSeparatedByCharactersInSet:bad] componentsJoinedByString:@"_"];
}

@implementation YTVFeedResumeCache

+ (NSURL *)ytv_resumeDirectoryURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *base = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *dir = [base URLByAppendingPathComponent:@"YTVFeedResume" isDirectory:YES];
    [fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

+ (NSURL *)ytv_fileURLForCategoryKey:(NSString *)categoryKey {
    NSString *name = [NSString stringWithFormat:@"%@.json", YTVFeedResumeSafeFileComponent(categoryKey ?: @"")];
    return [[self ytv_resumeDirectoryURL] URLByAppendingPathComponent:name];
}

+ (void)saveCategoryKey:(NSString *)categoryKey
        lastViewedVideoId:(NSString *)lastViewedVideoId
         lastViewedPlayURL:(NSString *)lastViewedPlayURL
       lastViewedIndexHint:(NSInteger)lastViewedIndexHint {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"category"] = categoryKey ?: @"";
    payload[@"savedAt"] = @([[NSDate date] timeIntervalSince1970]);
    if (lastViewedVideoId.length > 0) {
        payload[@"lastViewedVideoId"] = lastViewedVideoId;
    }
    if (lastViewedPlayURL.length > 0) {
        payload[@"lastViewedPlayURL"] = lastViewedPlayURL;
    }
    payload[@"lastViewedIndexHint"] = @(MAX(lastViewedIndexHint, 0));
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    if (!data.length) {
        return;
    }
    [data writeToURL:[self ytv_fileURLForCategoryKey:categoryKey] atomically:YES];
}

+ (NSDictionary *)loadResumeDictionaryForCategoryKey:(NSString *)categoryKey {
    NSURL *url = [self ytv_fileURLForCategoryKey:categoryKey];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data.length == 0) {
        return nil;
    }
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dict = (NSDictionary *)obj;
    NSNumber *savedAt = [dict[@"savedAt"] isKindOfClass:[NSNumber class]] ? dict[@"savedAt"] : nil;
    if (savedAt && ([[NSDate date] timeIntervalSince1970] - savedAt.doubleValue > kYTVFeedResumeCacheTTL)) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        return nil;
    }
    return dict;
}

@end
