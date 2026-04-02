//
//  NSDictionary+YTSafe.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (YTSafe)

/// 取子字典；缺失、NSNull、类型不符时返回 @{}；receiver 非字典或 nil 时返回 @{}。
- (NSDictionary *)yt_dictionaryForKey:(id<NSCopying>)key;

/// 取数组；缺失、NSNull、类型不符时返回 @[]。
- (NSArray *)yt_arrayForKey:(id<NSCopying>)key;

/// 取字符串：NSString 原样，NSNumber 用 stringWithFormat，其余为 @""。
- (NSString *)yt_stringForKey:(id<NSCopying>)key;

/// 取 NSNumber：已为 NSNumber 则返回；NSString 可 `doubleValue` 时包装为 @(double)；否则 nil。
- (nullable NSNumber *)yt_numberForKey:(id<NSCopying>)key;

/// 取整型：NSNumber / 数字字符串可解析时用 integerValue，否则 defaultValue。
- (NSInteger)yt_integerForKey:(id<NSCopying>)key defaultValue:(NSInteger)defaultValue;

/// 期望为某类型时返回该对象，否则 nil（含 NSNull、类型不符）。
- (nullable id)yt_objectForKey:(id<NSCopying>)key class:(Class)cls;

@end

NS_ASSUME_NONNULL_END
