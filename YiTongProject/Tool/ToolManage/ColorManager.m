//
//  ColorManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/2.
//

#import "ColorManager.h"
//拼音 学习 模块色值 管理
@implementation ColorItem
- (instancetype)initWithColors:(NSArray<NSString *> *)colors
                          type:(NSString *)type {
    if (self = [super init]) {
        _colors = colors;
        _type = type;
    }
    return self;
}
@end

@implementation ColorManager
+ (NSDictionary<NSString *, ColorItem *> *)allItems {
    static NSDictionary<NSString *, ColorItem *> *items;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        items = @{
            @"blue":   [[ColorItem alloc] initWithColors:@[@"#3D5CFF", @"#D6E6FF"] type:@"1"],
            @"green":  [[ColorItem alloc] initWithColors:@[@"#398A80", @"#D8F5F2"] type:@"2"],
            @"orange": [[ColorItem alloc] initWithColors:@[@"#F9A72E", @"#FFF3D9"] type:@"3"],
            @"purple": [[ColorItem alloc] initWithColors:@[@"#895BF2", @"#F1E9FF"] type:@"4"],
            @"green_00":  [[ColorItem alloc] initWithColors:@[@"#00C0A8", @"#D8F5F2"] type:@"5"],
        };
    });
    return items;
}
+ (ColorItem *)itemForKey:(NSString *)key {
    return [self.allItems objectForKey:key];
}
+ (void)saveColorKeyForRow:(NSInteger)row {
    NSArray *keys = @[@"blue", @"green", @"orange", @"purple"];
    if (keys.count == 0) return;
    NSString *key = keys[row % keys.count];
    [KUSER_DEFAULT setObject:key forKey:@"color_key"];
}
+ (NSString *)currentColorKey {
    return [KUSER_DEFAULT objectForKey:@"color_key"];
}
+ (BOOL)isBlue {
    NSString *currentKey = [self currentColorKey];
    return [currentKey isEqualToString:@"blue"];
}
+ (BOOL)isOrange {
    NSString *currentKey = [self currentColorKey];
    return [currentKey isEqualToString:@"orange"];
}
+ (BOOL)isPurple  {
    NSString *currentKey = [self currentColorKey];
    return [currentKey isEqualToString:@"purple"];
}
+ (BOOL)isPurpleOrOrange {
    NSString *currentKey = [self currentColorKey];
    return [currentKey isEqualToString:@"purple"] || [currentKey isEqualToString:@"orange"];
}
@end
