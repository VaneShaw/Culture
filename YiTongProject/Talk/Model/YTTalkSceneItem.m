//
//  YTTalkSceneItem.m
//  YiTongProject
//

#import "YTTalkSceneItem.h"

@implementation YTTalkSceneItem

+ (NSArray<YTTalkSceneItem *> *)itemsByParsingAPIData:(id)data {
    if (![data isKindOfClass:[NSArray class]]) return @[];

    NSMutableArray<YTTalkSceneItem *> *out = [NSMutableArray array];
    for (id el in (NSArray *)data) {
        if (![el isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *d = (NSDictionary *)el;
        YTTalkSceneItem *one = [[YTTalkSceneItem alloc] init];
        id idVal = d[@"id"];
        if ([idVal isKindOfClass:[NSNumber class]]) {
            one.sceneId = [(NSNumber *)idVal integerValue];
        } else if ([idVal isKindOfClass:[NSString class]]) {
            one.sceneId = [(NSString *)idVal integerValue];
        } else {
            one.sceneId = 0;
        }
        id codeVal = d[@"code"];
        one.sceneCode = [codeVal isKindOfClass:[NSString class]] ? (NSString *)codeVal : @"";

        id sortVal = d[@"sort"];
        one.sort = [sortVal respondsToSelector:@selector(integerValue)] ? [sortVal integerValue] : 0;
        id hotVal = d[@"hot"];
        one.hot = [hotVal respondsToSelector:@selector(integerValue)] ? [hotVal integerValue] : 0;

        id ct = d[@"create_time"];
        one.createTime = [ct isKindOfClass:[NSString class]] ? (NSString *)ct : nil;

        id t = d[@"title"];
        one.title = [t isKindOfClass:[NSString class]] ? (NSString *)t : @"";
        id st = d[@"subtitle"];
        one.subtitle = [st isKindOfClass:[NSString class]] ? (NSString *)st : @"";

        id cov = d[@"cover_image"];
        one.coverImagePath = [cov isKindOfClass:[NSString class]] ? (NSString *)cov : nil;

        id pct = d[@"scene_progress_percent"];
        one.sceneProgressPercent = [pct respondsToSelector:@selector(integerValue)] ? [pct integerValue] : 0;

        [out addObject:one];
    }
    return [out copy];
}

@end
