//
//  YTUnitViewFactory.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTUnitViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTUnitViewFactory : NSObject

/**
 根据 `YTUnit` 构建对应题型 Presenter（实现 `YTUnitViewProtocol`）。
 
 设计意图：
 - 让学习流容器不需要 `switch(unitType)`/`switch(exerciseType)` 写死分发逻辑
 - 题型扩展时只新增 Presenter，并在此处接入映射
 */
+ (id<YTUnitViewProtocol>)buildViewForUnit:(YTUnit *)unit;

@end

NS_ASSUME_NONNULL_END

