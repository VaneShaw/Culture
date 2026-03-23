//
//  YTTalkLearningDataService.h
//  YiTongProject
//
//  学习流本地进度/续学存储服务
//  当前仅负责：续学位置、已完成列表、答对后的可恢复答案
//

#import <Foundation/Foundation.h>
#import "YTLearningProgressStoring.h"

@class YTLastPosition;

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkLearningDataService : NSObject <YTLearningProgressStoring>

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
