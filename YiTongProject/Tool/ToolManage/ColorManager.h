//
//  ColorManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ColorItem : NSObject

@property (nonatomic, strong, readonly) NSArray<NSString *> *colors; // 两个颜色值
@property (nonatomic, copy, readonly) NSString *type;                // 类型编号

- (instancetype)initWithColors:(NSArray<NSString *> *)colors
                          type:(NSString *)type;

@end


@interface ColorManager : NSObject

/// 获取所有颜色配置
+ (NSDictionary<NSString *, ColorItem *> *)allItems;

/// 根据 key 获取配置对象 (如 @"blue")
+ (ColorItem *)itemForKey:(NSString *)key;


/// 根据 row 保存颜色 key 到 UserDefaults
+ (void)saveColorKeyForRow:(NSInteger)row;

/// 从 UserDefaults 获取当前保存的颜色 key
+ (NSString *)currentColorKey;
+ (BOOL)isBlue;
/// 是否是 orange
+ (BOOL)isOrange;
+ (BOOL)isPurple;
/// 是否是 purple 或 orange
+ (BOOL)isPurpleOrOrange;
@end

NS_ASSUME_NONNULL_END
