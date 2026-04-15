//
//  YTVFeedRepository.m
//  YiTongProject
//

#import "YTVFeedRepository.h"
#import "YTVFeedPageResult.h"
#import "YTVVideoFeedItem.h"
#import "HttpTools.h"
#import "BaseDataModel.h"
#import "YTVVideoDebugSampleFeed.h"
#import "LanguageHelper.h"

static NSString * const kYTVPathList = @"/video/list";
static NSString * const kYTVPathItemById = @"/video/feed/item";

@implementation YTVFeedRepository

static NSString *YTVVideoListTabFromCategoryKey(NSString *categoryKey) {
    if (categoryKey.length == 0) {
        return @"";
    }
    return categoryKey;
}

- (void)fetchBootstrapWithCategoryKey:(NSString *)categoryKey
                               cursor:(NSString *)cursor
                             pageSize:(NSInteger)pageSize
                      lastVideoId:(NSString *)lastVideoId
                           completion:(void (^)(YTVFeedPageResult * _Nullable, NSError * _Nullable))completion {
    if ([YTVVideoDebugSampleFeed isSampleFeedEnabled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            YTVFeedPageResult *page = [YTVVideoDebugSampleFeed bootstrapPageForCategoryKey:categoryKey ?: @"" pageSize:pageSize];
            if (completion) {
                completion(page, nil);
            }
        });
        return;
    }
    [self ytv_fetchListWithCategoryKey:categoryKey cursor:nil completion:completion];
}

- (void)fetchNextWithCategoryKey:(NSString *)categoryKey
                          cursor:(NSString *)cursor
                        pageSize:(NSInteger)pageSize
                   lastVideoId:(NSString *)lastVideoId
                      completion:(void (^)(YTVFeedPageResult * _Nullable, NSError * _Nullable))completion {
    if ([YTVVideoDebugSampleFeed isSampleFeedEnabled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            YTVFeedPageResult *page = [YTVVideoDebugSampleFeed nextPageForCategoryKey:categoryKey ?: @""
                                                                       lastVideoId:lastVideoId
                                                                          pageSize:pageSize];
            if (completion) {
                completion(page, nil);
            }
        });
        return;
    }
    [self ytv_fetchListWithCategoryKey:categoryKey cursor:cursor completion:completion];
}

- (void)ytv_fetchListWithCategoryKey:(NSString *)categoryKey
                              cursor:(NSString *)cursor
                          completion:(void (^)(YTVFeedPageResult * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    NSString *tab = YTVVideoListTabFromCategoryKey(categoryKey ?: @"");
    if (tab.length > 0) {
        params[@"tab"] = tab;
    }
    NSInteger page = 1;
    if (cursor.length > 0) {
        NSInteger p = [cursor integerValue];
        if (p > 0) {
            page = p;
        }
    }
    params[@"page"] = @(MAX(1, page));

    [HttpTools postRequest:kYTVPathList parames:params success:^(BOOL success, BaseDataModel *response) {
        if (!success || response == nil) {
            NSInteger code = response ? (NSInteger)response.code : -1;
            NSString *msg = response.msg.length ? response.msg : NSLocalizedString(@"Request failed", @"");
            NSError *err = [NSError errorWithDomain:@"YTVFeedRepository"
                                               code:code
                                           userInfo:@{NSLocalizedDescriptionKey: msg}];
            if (completion) {
                completion(nil, err);
            }
            return;
        }
        YTVFeedPageResult *page = [YTVFeedPageResult resultWithDataObject:response.data];
        if (!page) {
            page = [[YTVFeedPageResult alloc] init];
            page.items = @[];
            page.nextCursor = @"";
            page.hasMore = NO;
        }
        if (completion) {
            completion(page, nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)fetchVideoItemById:(NSString *)videoId
                completion:(void (^)(YTVVideoFeedItem * _Nullable, NSError * _Nullable))completion {
    if (videoId.length == 0) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"YTVFeedRepository" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"empty videoId"}]);
        }
        return;
    }
    NSDictionary *params = @{ @"video_id": videoId };
    [HttpTools postRequest:kYTVPathItemById parames:params success:^(BOOL success, BaseDataModel *response) {
        if (!success || response == nil) {
            NSString *msg = response.msg.length ? response.msg : NSLocalizedString(@"Request failed", @"");
            NSError *err = [NSError errorWithDomain:@"YTVFeedRepository"
                                               code:(NSInteger)(response ? response.code : -1)
                                           userInfo:@{NSLocalizedDescriptionKey: msg}];
            if (completion) {
                completion(nil, err);
            }
            return;
        }
        id data = response.data;
        NSDictionary *dict = nil;
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *d = (NSDictionary *)data;
            id inner = d[@"item"] ?: d[@"video"] ?: d[@"data"];
            if ([inner isKindOfClass:[NSDictionary class]]) {
                dict = inner;
            } else {
                dict = d;
            }
        }
        YTVVideoFeedItem *item = dict ? [YTVVideoFeedItem itemWithDictionary:dict] : nil;
        if (completion) {
            completion(item, item ? nil : [NSError errorWithDomain:@"YTVFeedRepository" code:-2 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"YTV_deep_link_parse_item_failed", @"")}]);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

@end
