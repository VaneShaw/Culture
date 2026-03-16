//
//  IDStorageManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/8/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IDStorageManager : NSObject
+ (instancetype)sharedManager;

// 保存一个值，指定 id (NSNumber/NSString/NSDictionary...都可以)
- (void)saveValue:(id)value forId:(NSString *)anId;

// 根据 id 获取值
- (id)valueForId:(NSString *)anId;

// 删除一个 id 对应的值
- (void)removeValueForId:(NSString *)anId;

// 清空所有保存过的 id
- (void)clearAllSavedValues;
@end

NS_ASSUME_NONNULL_END
