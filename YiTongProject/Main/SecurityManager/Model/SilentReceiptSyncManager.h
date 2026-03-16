//
//  SilentReceiptSyncManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/25.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void(^SilentSyncCompletion)(BOOL hasPendingTransactions);
@interface SilentReceiptSyncManager : NSObject <SKPaymentTransactionObserver>

@property (nonatomic, strong, readonly) NSMutableArray<SKPaymentTransaction *> *pendingTransactions;
@property (nonatomic, assign, readonly) BOOL isProcessingPendingQueue;

+ (instancetype)sharedManager;

/// 启动静默补单
- (void)startSilentSync;

/// 用于用户登录后触发静默补单
- (void)startSilentSyncIfLoggedIn:(BOOL)isVip;

/// 清理状态（用户注销时可调用）
- (void)reset;

@end
