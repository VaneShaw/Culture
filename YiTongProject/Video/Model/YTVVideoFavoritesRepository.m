//
//  YTVVideoFavoritesRepository.m
//  YiTongProject
//

#import "YTVVideoFavoritesRepository.h"
#import "HttpTools.h"
#import "BaseDataModel.h"
#import "YTVFeedPageResult.h"

static NSString * const kYTVPathFavoriteToggle = @"/user/videoFavorites/toggle";
static NSString * const kYTVPathFavoriteList = @"/user/videoFavorites/list";

@implementation YTVVideoFavoritesRepository

- (void)toggleFavoriteWithVideoId:(NSString *)videoId
                       completion:(void (^)(BOOL success, BOOL isFavorite, NSInteger favoritesCount, NSString * _Nullable message))completion {
    if (videoId.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(NO, NO, -1, nil);
            }
        });
        return;
    }
    NSDictionary *params = @{ @"video_id": videoId };
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
                }
                id c = d[@"favorites_count"];
                if ([c isKindOfClass:[NSNumber class]]) {
                    fc = [c integerValue];
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
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"cursor"] = cursor ?: @"";
    params[@"pageSize"] = @(MAX(1, pageSize));
    if (lastVideoId.length > 0) {
        params[@"lastVideoId"] = lastVideoId;
    }
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
                page.nextCursor = @"";
                page.hasMore = NO;
            }
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
