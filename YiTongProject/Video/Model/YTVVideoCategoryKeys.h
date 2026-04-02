//
//  YTVVideoCategoryKeys.h
//  YiTongProject
//
//  与接口 `category` 参数及技术设计 FeedContext 对齐（阶段 4）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSUInteger YTVVideoCategoryCount(void);

/// 0=推荐 1=成语 2=神话 3=封神；越界返回空串
FOUNDATION_EXPORT NSString *YTVVideoCategoryKeyAtIndex(NSUInteger index);

/// `recommend`/`idiom`/`myth`/`fengshen` 等；未知返回 `NSNotFound`
FOUNDATION_EXPORT NSInteger YTVVideoCategoryIndexForKey(NSString *categoryKey);

NS_ASSUME_NONNULL_END
