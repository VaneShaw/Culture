//
//  YTVFeedPageResult.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

@class YTVVideoFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface YTVFeedPageResult : NSObject

@property (nonatomic, copy) NSArray<YTVVideoFeedItem *> *items;
@property (nonatomic, copy, nullable) NSString *nextCursor;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) NSInteger ttlSec;

+ (nullable instancetype)resultWithDataObject:(nullable id)dataObject;

@end

NS_ASSUME_NONNULL_END
