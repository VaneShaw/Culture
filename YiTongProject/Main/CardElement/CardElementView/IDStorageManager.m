//
//  IDStorageManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/28.
//

#import "IDStorageManager.h"
static NSString * const kSavedIDKeys = @"SavedIDKeys";
//用于记录字母卡片的下标
@implementation IDStorageManager
+ (instancetype)sharedManager {
    static IDStorageManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[IDStorageManager alloc] init];
    });
    return manager;
}

- (void)saveValue:(id)value forId:(NSString *)anId {
    
    if (!value) return; // 防止存 nil 崩溃
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *strId = [[UserModel sharedInstance] userId];
    NSString *key = [NSString stringWithFormat:@"%@/%@",strId,anId];
    [defaults setObject:value forKey:key];
    
    // 维护已保存的 key 列表
    NSMutableArray *savedKeys = [[defaults objectForKey:kSavedIDKeys] mutableCopy];
    if (!savedKeys) {
        savedKeys = [NSMutableArray array];
    }
    if (![savedKeys containsObject:key]) {
        [savedKeys addObject:key];
    }
    [defaults setObject:savedKeys forKey:kSavedIDKeys];
    [defaults synchronize];
}
- (id)valueForId:(NSString *)anId {
    
    NSString *strId = [[UserModel sharedInstance] userId];
    NSString *key = [NSString stringWithFormat:@"%@/%@",strId,anId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}
//暂无用
- (void)removeValueForId:(NSString *)anId {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *strId = [[UserModel sharedInstance] userId];
    NSString *key = [NSString stringWithFormat:@"%@/%@",strId,anId];
    [defaults removeObjectForKey:key];
    // 更新 key 列表
    NSMutableArray *savedKeys = [[defaults objectForKey:kSavedIDKeys] mutableCopy];
    if (savedKeys && [savedKeys containsObject:key]) {
        [savedKeys removeObject:key];
        [defaults setObject:savedKeys forKey:kSavedIDKeys];
    }
    [defaults synchronize];
}
- (void)clearAllSavedValues {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedKeys = [defaults objectForKey:kSavedIDKeys];
    
    for (NSString *key in savedKeys) {
        [defaults removeObjectForKey:key];
    }
    [defaults removeObjectForKey:kSavedIDKeys];
    [defaults synchronize];
    
    //用户退出
    [[SilentReceiptSyncManager sharedManager] reset];
}

@end
