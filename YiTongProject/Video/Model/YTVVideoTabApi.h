//
//  YTVVideoTabApi.h
//  YiTongProject
//
//  POST /video/tab，body JSON（含 lang）返回分类 segment 的 key 与展示文案（与 feed category 参数一致）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoTabApi : NSObject

/// 请求视频 Tab 配置；成功时 `keys` 与 `titles` 一一对应，顺序与接口约定一致（先走 canonical 顺序，其余 key 按字母序）
+ (void)ytv_fetchVideoTabsWithCompletion:(void (^)(NSArray<NSString *> * _Nullable keys, NSArray<NSString *> * _Nullable titles, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
