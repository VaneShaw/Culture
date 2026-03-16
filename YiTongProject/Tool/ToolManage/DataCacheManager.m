//
//  DataCacheManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/12.
//

#import "DataCacheManager.h"
//先拿本地保存到数据， 然后再判断是否刷新
@implementation DataCacheManager
+ (NSString *)keyForClass:(Class)cls {
    return [NSString stringWithFormat:@"%@_DataArray", NSStringFromClass(cls)];
}
+ (void)saveData:(NSArray *)data forClass:(Class)cls {
    if (!data) return;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    if (!error && jsonData) {
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [[NSUserDefaults standardUserDefaults] setObject:jsonStr forKey:[self keyForClass:cls]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
+ (NSArray *)loadDataForClass:(Class)cls {
    NSString *jsonStr = [[NSUserDefaults standardUserDefaults] objectForKey:[self keyForClass:cls]];
    if (!jsonStr) return nil;
    NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}
+ (BOOL)hasDataChanged:(NSArray *)newData forClass:(Class)cls {
    if (!newData) return YES;
    // ====== 每次启动 App 的首次调用强制刷新 ======
    static NSMutableSet *firstLaunchClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        firstLaunchClasses = [NSMutableSet set];
    });

    NSString *className = NSStringFromClass(cls);
    if (![firstLaunchClasses containsObject:className]) {
        [firstLaunchClasses addObject:className];
        NSLog(@"✅ App 启动后 %@ 首次调用，强制刷新", className);
        [self saveData:newData forClass:cls];
        return YES;
    }

    NSString *key = [NSString stringWithFormat:@"DataChanged_KEY"];
    BOOL forceRefresh = [KUSER_DEFAULT boolForKey:key];
    if (forceRefresh) {
        NSLog(@"⚡ %@ 被强制刷新（UserDefaults）", className);
        [self saveData:newData forClass:cls];
        //[KUSER_DEFAULT setBool:NO forKey:key]; // 刷新后重置开关
        [KUSER_DEFAULT synchronize];
        return YES;
    }

    
    // 取本地旧数据
    NSArray *oldData = [self loadDataForClass:cls];
    BOOL changed = NO;
    
    // 1. 旧数据为 nil → 一定刷新
    if (!oldData) {
        changed = YES;
    }
    // 2. 数量不同 → 一定刷新
    
    else if (oldData.count != newData.count) {
        changed = YES;
    }
    else {
        // 转成 JSON 字符串比较
        NSData *oldJson = [NSJSONSerialization dataWithJSONObject:oldData ?: @[] options:0 error:nil];
        NSData *newJson = [NSJSONSerialization dataWithJSONObject:newData options:0 error:nil];
        
        NSString *oldStr = [[NSString alloc] initWithData:oldJson encoding:NSUTF8StringEncoding];
        NSString *newStr = [[NSString alloc] initWithData:newJson encoding:NSUTF8StringEncoding];
        
        changed = ![oldStr isEqualToString:newStr];
    }
    
    if (changed) {
        [self saveData:newData forClass:cls]; // 更新本地缓存
    }
    
    return changed;
}
@end
