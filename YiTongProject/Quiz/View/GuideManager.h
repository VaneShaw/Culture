//
//  GuideManager.h
//  YiTongProject
//
//  Created by Vincent on 2025/8/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GuideManager : NSObject

+ (instancetype)shared;

// 检查是否需要显示页面引导图
- (BOOL)shouldShowGuideForPage:(NSString *)pageKey;

// 标记页面引导图已显示
- (void)markGuideShownForPage:(NSString *)pageKey;

// 获取/设置页面记忆下标  这两个后期 作废
- (NSInteger)storedIndexForPage:(NSString *)pageKey;
- (void)storeIndex:(int)index forPage:(NSString *)pageKey;

//quiz模块 存入第几题  当前得分
- (void)storeIndex:(NSInteger)index
             score:(NSInteger)score
           forPage:(NSString *)pageKey;
//获取当前在第几题
- (NSInteger)storedQuizIndexForPage:(NSString *)pageKey;
//获取当前得分
- (NSInteger)storedQuizScoreForPage:(NSString *)pageKey;

@end

NS_ASSUME_NONNULL_END
