//
//  YTVFavoritesListViewModel.m
//  YiTongProject
//

#import "YTVFavoritesListViewModel.h"
#import "YTVVideoFavoritesRepository.h"
#import "YTVFeedPageResult.h"
#import "YTVVideoFeedItem.h"
#import "YTVFeedSnapshotCache.h"

static NSString * const kYTVFavoritesListCacheKey = @"__favorites_list__";
static const NSInteger kYTVFavoritesListPageSize = 20;

@interface YTVFavoritesListViewModel ()
@property (nonatomic, strong) NSMutableArray<YTVVideoFeedItem *> *mutableItems;
@property (nonatomic, copy, nullable) NSString *nextCursor;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, strong) YTVVideoFavoritesRepository *repository;
@end

@implementation YTVFavoritesListViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableItems = [NSMutableArray array];
        _hasMore = YES;
        _repository = [[YTVVideoFavoritesRepository alloc] init];
    }
    return self;
}

- (NSArray<YTVVideoFeedItem *> *)items {
    return [_mutableItems copy];
}

- (void)clearItemsForLogout {
    [self.mutableItems removeAllObjects];
}

- (void)loadDiskCacheOnly {
    NSDictionary *snap = [YTVFeedSnapshotCache loadSnapshotDictionaryForCategoryKey:kYTVFavoritesListCacheKey];
    [self ytv_applySnapshotDictionary:snap];
}

- (void)ytv_applySnapshotDictionary:(NSDictionary *)snap {
    if (!snap) {
        return;
    }
    id rawItems = snap[@"items"];
    if (![rawItems isKindOfClass:[NSArray class]]) {
        return;
    }
    [self.mutableItems removeAllObjects];
    for (id o in (NSArray *)rawItems) {
        if ([o isKindOfClass:[NSDictionary class]]) {
            YTVVideoFeedItem *it = [YTVVideoFeedItem itemWithDictionary:o];
            if (it) {
                it.isFavorite = YES;
                [self.mutableItems addObject:it];
            }
        }
    }
    id nc = snap[@"nextCursor"];
    self.nextCursor = [nc isKindOfClass:[NSString class]] ? (NSString *)nc : @"";
    id hm = snap[@"hasMore"];
    self.hasMore = [hm isKindOfClass:[NSNumber class]] ? [(NSNumber *)hm boolValue] : YES;
}

- (void)reloadFromCacheThenNetworkWithCompletion:(void (^)(NSError * _Nullable))completion {
    NSDictionary *snap = [YTVFeedSnapshotCache loadSnapshotDictionaryForCategoryKey:kYTVFavoritesListCacheKey];
    [self ytv_applySnapshotDictionary:snap];
    self.isLoading = YES;
    __weak typeof(self) weakSelf = self;
    [self.repository fetchListWithCursor:nil
                                pageSize:kYTVFavoritesListPageSize
                           lastVideoId:nil
                              completion:^(YTVFeedPageResult * _Nullable result, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                if (completion) {
                    completion(error);
                }
                return;
            }
            self.isLoading = NO;
            if (error) {
                if (completion) {
                    completion(error);
                }
                return;
            }
            [self.mutableItems removeAllObjects];
            if (result.items.count > 0) {
                for (YTVVideoFeedItem *it in result.items) {
                    it.isFavorite = YES;
                }
                [self.mutableItems addObjectsFromArray:result.items];
            }
            self.nextCursor = result.nextCursor ?: @"";
            self.hasMore = result.hasMore;
            [YTVFeedSnapshotCache saveCategoryKey:kYTVFavoritesListCacheKey
                                            items:self.mutableItems
                                       nextCursor:self.nextCursor ?: @""
                                          hasMore:self.hasMore];
            if (completion) {
                completion(nil);
            }
        });
    }];
}

@end
