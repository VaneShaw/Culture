//
//  YTVVideoFavoritesRepository.m
//  YiTongProject
//

#import "YTVVideoFavoritesRepository.h"
#import "HttpTools.h"
#import "BaseDataModel.h"
#import "YTVFeedPageResult.h"
#import "LanguageHelper.h"

static NSString * const kYTVPathFavoriteToggle = @"/video/favorite";
static NSString * const kYTVPathFavoriteList = @"/video/favoriteList";

@implementation YTVVideoFavoritesRepository

- (void)toggleFavoriteWithTaleType:(NSString *)taleType
                            taleId:(NSString *)taleId
                        isFavorite:(BOOL)isFavorite
                       completion:(void (^)(BOOL success, BOOL isFavorite, NSInteger favoritesCount, NSString * _Nullable message))completion {
    if (taleType.length == 0 || taleId.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(NO, NO, -1, nil);
            }
        });
        return;
    }
    NSDictionary *params = @{
        @"tale_type": taleType,
        @"tale_id": taleId,
        @"is_favorite": isFavorite ? @"1" : @"0"
    };
    [HttpTools postRequest:kYTVPathFavoriteToggle parames:params success:^(BOOL success, BaseDataModel *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success || response == nil) {
                NSString *msg = response.msg.length ? response.msg : NSLocalizedString(@"Request failed", @"");
                if (completion) {
                    completion(NO, NO, -1, msg);
                }
                return;
            }
            BOOL fav = NO;
            NSInteger fc = -1;
            if ([response.data isKindOfClass:[NSDictionary class]]) {
                NSDictionary *d = (NSDictionary *)response.data;
                id f = d[@"is_favorite"];
                if ([f isKindOfClass:[NSNumber class]]) {
                    fav = [f boolValue];
                } else if ([f isKindOfClass:[NSString class]]) {
                    fav = [(NSString *)f integerValue] != 0;
                }
                id c = d[@"favorite_count"] ?: d[@"favorites_count"];
                if ([c isKindOfClass:[NSNumber class]]) {
                    fc = [c integerValue];
                } else if ([c isKindOfClass:[NSString class]]) {
                    fc = [(NSString *)c integerValue];
                }
            }
            if (completion) {
                completion(YES, fav, fc, nil);
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(NO, NO, -1, error.localizedDescription);
            }
        });
    }];
}

- (void)fetchListWithCursor:(NSString *)cursor
                   pageSize:(NSInteger)pageSize
              lastVideoId:(NSString *)lastVideoId
                 completion:(void (^)(YTVFeedPageResult * _Nullable, NSError * _Nullable))completion {
    (void)cursor;
    (void)pageSize;
    (void)lastVideoId;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:kYTVPathFavoriteList parames:params success:^(BOOL success, BaseDataModel *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success || response == nil) {
                NSInteger code = response ? (NSInteger)response.code : -1;
                NSString *msg = response.msg.length ? response.msg : NSLocalizedString(@"Request failed", @"");
                NSError *err = [NSError errorWithDomain:@"YTVVideoFavoritesRepository"
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
            }
            // `/video/favoriteList` 当前返回全量收藏列表，无 cursor/has_more 语义。
            page.nextCursor = @"";
            page.hasMore = NO;
            if (completion) {
                completion(page, nil);
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, error);
            }
        });
    }];
}

@end
