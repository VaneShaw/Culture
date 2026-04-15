//
//  YTVFeedPageResult.m
//  YiTongProject
//

#import "YTVFeedPageResult.h"
#import "YTVVideoFeedItem.h"

@implementation YTVFeedPageResult

+ (instancetype)resultWithDataObject:(id)dataObject {
    if (![dataObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dict = (NSDictionary *)dataObject;
    NSMutableArray<YTVVideoFeedItem *> *items = [NSMutableArray array];
    id rawItems = dict[@"items"];
    if (rawItems == nil) {
        rawItems = dict[@"list"];
    }
    if ([rawItems isKindOfClass:[NSArray class]]) {
        for (id obj in (NSArray *)rawItems) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                YTVVideoFeedItem *it = [YTVVideoFeedItem itemWithDictionary:obj];
                if (it) {
                    [items addObject:it];
                }
            }
        }
    }
    YTVFeedPageResult *r = [[YTVFeedPageResult alloc] init];
    r.items = [items copy];
    BOOL hasMoreResolved = NO;
    id nc = dict[@"next_cursor"] ?: dict[@"nextCursor"];
    if ([nc isKindOfClass:[NSString class]]) {
        r.nextCursor = (NSString *)nc;
    } else {
        // /video/list: {page,page_size,total}
        NSInteger page = 0;
        NSInteger pageSize = 0;
        NSInteger total = 0;
        id p = dict[@"page"];
        id ps = dict[@"page_size"] ?: dict[@"pageSize"];
        id t = dict[@"total"];
        if ([p isKindOfClass:[NSNumber class]]) {
            page = [p integerValue];
        } else if ([p isKindOfClass:[NSString class]]) {
            page = [(NSString *)p integerValue];
        }
        if ([ps isKindOfClass:[NSNumber class]]) {
            pageSize = [ps integerValue];
        } else if ([ps isKindOfClass:[NSString class]]) {
            pageSize = [(NSString *)ps integerValue];
        }
        if ([t isKindOfClass:[NSNumber class]]) {
            total = [t integerValue];
        } else if ([t isKindOfClass:[NSString class]]) {
            total = [(NSString *)t integerValue];
        }
        NSInteger nextPage = MAX(1, page + 1);
        r.nextCursor = [NSString stringWithFormat:@"%ld", (long)nextPage];
        if (page > 0 && pageSize > 0 && total >= 0) {
            r.hasMore = (page * pageSize) < total;
            hasMoreResolved = YES;
        }
    }
    id hm = dict[@"has_more"] ?: dict[@"hasMore"];
    if ([hm isKindOfClass:[NSNumber class]]) {
        r.hasMore = [hm boolValue];
    } else if (!hasMoreResolved) {
        r.hasMore = YES;
    }
    id ttl = dict[@"ttl_sec"] ?: dict[@"ttlSec"];
    if ([ttl isKindOfClass:[NSNumber class]]) {
        r.ttlSec = [ttl integerValue];
    } else {
        r.ttlSec = 0;
    }
    return r;
}

@end
