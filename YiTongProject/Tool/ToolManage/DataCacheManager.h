//
//  DataCacheManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataCacheManager : NSObject
/// 保存数据（自动绑定类名作为 key）
+ (void)saveData:(NSArray *)data forClass:(Class)cls;

/// 读取数据（本地缓存）
+ (NSArray *)loadDataForClass:(Class)cls;

/// 判断是否有变化，如果变化返回 YES，并自动保存新数据
+ (BOOL)hasDataChanged:(NSArray *)newData forClass:(Class)cls;
@end

NS_ASSUME_NONNULL_END
