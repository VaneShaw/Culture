//
//  YTTalkLevelItem.m
//  YiTongProject
//

#import "YTTalkLevelItem.h"

@implementation YTTalkLevelItem

+ (NSArray<YTTalkLevelItem *> *)itemsByParsingAPIData:(id)data {
    if (![data isKindOfClass:[NSArray class]]) return @[];

    NSMutableArray<YTTalkLevelItem *> *out = [NSMutableArray array];
    for (id el in (NSArray *)data) {
        if (![el isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *d = (NSDictionary *)el;
        YTTalkLevelItem *one = [[YTTalkLevelItem alloc] init];

        id rid = d[@"id"];
        one.levelRecordId = [rid respondsToSelector:@selector(integerValue)] ? [rid integerValue] : 0;

        id lv = d[@"level"];
        one.level = [lv respondsToSelector:@selector(integerValue)] ? [lv integerValue] : 0;

        id t = d[@"title"];
        one.title = [t isKindOfClass:[NSString class]] ? (NSString *)t : @"";
        id st = d[@"subtitle"];
        one.subtitle = [st isKindOfClass:[NSString class]] ? (NSString *)st : @"";

        id ut = d[@"unlock_threshold"];
        one.unlockThreshold = [ut respondsToSelector:@selector(integerValue)] ? [ut integerValue] : 0;

        id iu = d[@"is_unlocked"];
        one.isUnlocked = [iu respondsToSelector:@selector(integerValue)] ? ([iu integerValue] != 0) : NO;

        id pp = d[@"progress_percent"];
        one.progressPercent = [pp respondsToSelector:@selector(integerValue)] ? [pp integerValue] : 0;

        id cu = d[@"completed_units"];
        one.completedUnits = [cu respondsToSelector:@selector(integerValue)] ? [cu integerValue] : 0;

        id tu = d[@"total_units"];
        one.totalUnits = [tu respondsToSelector:@selector(integerValue)] ? [tu integerValue] : 0;

        id ls = d[@"level_status"];
        one.levelStatus = [ls isKindOfClass:[NSString class]] ? (NSString *)ls : nil;

        [out addObject:one];
    }
    return [out copy];
}

@end
