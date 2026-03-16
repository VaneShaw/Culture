//
//  ReceiptSyncManager.h
//  YiTongProject
//
//  Created by Vincent on 2025/12/7.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "YTIAPService.h"
NS_ASSUME_NONNULL_BEGIN

@interface ReceiptSyncManager : NSObject<SKRequestDelegate>

// 是否正在处理补单队列
@property (nonatomic, assign, readonly) BOOL isProcessingPendingQueue;
+ (instancetype)sharedManager;
// 登录成功后调用
- (void)syncReceiptIfNeeded;

//判断是否重复
- (BOOL)canSyncReceiptThisMonth;
// 启动补单
//- (void)startPendingTransactionSync;
@end

NS_ASSUME_NONNULL_END
