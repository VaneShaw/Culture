//
//  YTTalkHomeBannerData.m
//  YiTongProject
//

#import "YTTalkHomeBannerData.h"
#import "YTTalkHomeBannerImageItem.h"
#import "YTTalkHomeSceneTabItem.h"

@implementation YTTalkHomeBannerData

+ (NSArray<NSString *> *)yt_sortedStringValuesFromKeyedObject:(NSDictionary *)dict keyPrefix:(NSString *)prefix {
    if (![dict isKindOfClass:[NSDictionary class]] || prefix.length == 0) return @[];

    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    for (NSString *k in dict) {
        if (![k isKindOfClass:[NSString class]]) continue;
        if ([k hasPrefix:prefix]) [keys addObject:k];
    }
    [keys sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        NSString *sa = [a substringFromIndex:prefix.length];
        NSString *sb = [b substringFromIndex:prefix.length];
        NSInteger na = sa.integerValue;
        NSInteger nb = sb.integerValue;
        if (na != nb) {
            return na < nb ? NSOrderedAscending : NSOrderedDescending;
        }
        return [a compare:b];
    }];

    NSMutableArray<NSString *> *out = [NSMutableArray array];
    for (NSString *k in keys) {
        id v = dict[k];
        if (![v isKindOfClass:[NSString class]]) continue;
        NSString *s = [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) continue;
        [out addObject:s];
    }
    return [out copy];
}

+ (instancetype)dataByParsingAPIDictionary:(id)payload {
    YTTalkHomeBannerData *model = [[YTTalkHomeBannerData alloc] init];
    if (![payload isKindOfClass:[NSDictionary class]]) {
        model.sceneTabs = @[ [YTTalkHomeSceneTabItem defaultAllTabItem] ];
        model.bannerImages = @[];
        return model;
    }
    NSDictionary *root = (NSDictionary *)payload;

    id bannerRaw = root[@"banner_imgs"];
    id tabRaw = root[@"scene_tab_list"];

    NSArray<NSString *> *urls = [self yt_sortedStringValuesFromKeyedObject:[bannerRaw isKindOfClass:[NSDictionary class]] ? (NSDictionary *)bannerRaw : nil
                                                                 keyPrefix:@"img_"];

    NSMutableArray<YTTalkHomeBannerImageItem *> *images = [NSMutableArray array];
    for (NSString *url in urls) {
        YTTalkHomeBannerImageItem *one = [[YTTalkHomeBannerImageItem alloc] init];
        one.imageURLString = url;
        one.title = @"";
        one.subtitle = @"";
        one.tagText = @"";
        [images addObject:one];
    }
    model.bannerImages = [images copy];

    NSArray<NSString *> *tabTypes = [self yt_sortedStringValuesFromKeyedObject:[tabRaw isKindOfClass:[NSDictionary class]] ? tabRaw : nil
                                                                     keyPrefix:@"tab_"];
    if (tabTypes.count == 0) {
        model.sceneTabs = @[ [YTTalkHomeSceneTabItem defaultAllTabItem] ];
    } else {
        NSMutableArray<YTTalkHomeSceneTabItem *> *tabs = [NSMutableArray array];
        for (NSString *tp in tabTypes) {
            [tabs addObject:[YTTalkHomeSceneTabItem itemWithTypeIdentifier:tp]];
        }
        model.sceneTabs = [tabs copy];
    }

    return model;
}

+ (instancetype)emptyDefaultAllTabOnly {
    YTTalkHomeBannerData *model = [[YTTalkHomeBannerData alloc] init];
    model.sceneTabs = @[ [YTTalkHomeSceneTabItem defaultAllTabItem] ];
    model.bannerImages = @[];
    return model;
}

@end
