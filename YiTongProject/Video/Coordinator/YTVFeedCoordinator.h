//
//  YTVFeedCoordinator.h
//  YiTongProject
//
//  视频模块路由：Tab、导航栈、分类 Feed（技术设计阶段 10；全文/外链等可后续扩展）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVFeedCoordinator : NSObject

+ (instancetype)sharedCoordinator;

/// 解析并跳转视频 Tab、切分类、定位/补拉单条
- (void)routeVideoDeepLinkFromURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
