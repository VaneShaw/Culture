//
//  YTVVideoDeepLinkRouter.h
//  YiTongProject
//
//  Universal Link / 自定义 scheme 视频深链解析（技术设计阶段 10）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoDeepLinkRouter : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *videoId;
@property (nonatomic, copy, readonly, nullable) NSString *categoryKey;
@property (nonatomic, copy, readonly, nullable) NSString *fromSource;

+ (BOOL)ytv_isVideoDeepLinkURL:(NSURL *)url;
+ (nullable instancetype)ytv_routerParsingURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
