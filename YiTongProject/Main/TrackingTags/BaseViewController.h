//
//  BaseViewController.h
//  YiTongProject
//
//  Created by ios01 on 2026/2/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseViewController : UIViewController
@property (nonatomic, copy) NSString *pageId;           // 当前页面唯一标识
@property (nonatomic, copy) NSString *fromPage;
@property (nonatomic, assign) long long pageEnterTimeMs;
//------------------------------------------------------
// 学习开始时间（毫秒）
@property (nonatomic, assign) long long studyStartTimeMs;
// 开始学习（需要的页面手动调用）
- (void)startStudy;
// 结束学习并上报
// @param completed 是否完成（1 完成 / 0 未完成）
// @param extraParams 额外参数（total / correct / score 等，可为空）

- (void)endStudyWithCompleted:(BOOL)completed
                  eventType:(NSString *)eventType
                   eventName:(NSString *)eventName
                  contentType:(NSString *)contentType
                   extraParams:(nullable NSDictionary *)extraParams;
@end

NS_ASSUME_NONNULL_END
