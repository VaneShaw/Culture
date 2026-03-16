//
//  SilentReceiptSyncManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/25.
//

#import "SilentReceiptSyncManager.h"
@interface SilentReceiptSyncManager ()

@property (nonatomic, strong) NSMutableArray<SKPaymentTransaction *> *pendingTransactions;
@property (nonatomic, assign) BOOL isProcessingPendingQueue;
@property (nonatomic, strong) NSMutableSet<NSString *> *processingTransactionIds;

@property (nonatomic, assign) BOOL isVip;
@end
@implementation SilentReceiptSyncManager
//每次启动先判断 是否登录，然后静默补单---用户无感知
+ (instancetype)sharedManager {
    static SilentReceiptSyncManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SilentReceiptSyncManager alloc] init];
        instance.processingTransactionIds = [NSMutableSet set];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:instance];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pendingTransactions = [NSMutableArray array];
        _isProcessingPendingQueue = NO;
    }
    return self;
}
/// 登录后触发（可选）
- (void)startSilentSyncIfLoggedIn:(BOOL)isVip {
    // 你自己的登录判断逻辑
    self.isVip = isVip;
    if([[UserModel sharedInstance] isLogin] && IS_Member){
        [self startSilentSync];
    }
}
/// 启动静默补单（App 启动或登录后调用）
- (void)startSilentSync {
    //iap313
    /*if (self.isProcessingPendingQueue) return;
    self.isProcessingPendingQueue = YES;
    [self.pendingTransactions removeAllObjects];
    
  // 这里只是标记，真正交易处理通过 observer 回调
    NSArray<SKPaymentTransaction *> *transactions = [SKPaymentQueue defaultQueue].transactions;
    NSLog(@"补签---------补单的count--------[%ld]--------main-new---",transactions.count);

    for (SKPaymentTransaction *t in transactions) {
        if (!t.transactionIdentifier) continue;
        if (t.transactionState == SKPaymentTransactionStatePurchased ||
            t.transactionState == SKPaymentTransactionStateRestored) {
            [self.pendingTransactions addObject:t];
        } else if (t.transactionState == SKPaymentTransactionStateFailed) {
            [[SKPaymentQueue defaultQueue] finishTransaction:t];
        }
    }*/
    //NSLog(@"[SilentReceiptSync] Pending transactions count: [%lu]--------------", (unsigned long)self.pendingTransactions.count);
}



/// 用户注销清理
- (void)reset {
//    for (SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions) {
//        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//    }
    
    [self.pendingTransactions removeAllObjects];
    self.isProcessingPendingQueue = NO;
}
- (BOOL)isTransactionHandled:(SKPaymentTransaction *)t {
    NSString *transactionId = t.transactionIdentifier;
    if (transactionId.length == 0) return NO;
    return [[NSUserDefaults standardUserDefaults] boolForKey:transactionId];
}
/// observer 回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *t in transactions) {
        switch (t.transactionState) {
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored: {
                // 静默补单处理
                if ([self isTransactionHandled:t]) { // ✅ 已处理过，直接 finish
                      [[SKPaymentQueue defaultQueue] finishTransaction:t];
                      return;
                  }
                    [self handlePurchasedTransaction:t];
              
            }
                break;
            case SKPaymentTransactionStateFailed: {
                [[SKPaymentQueue defaultQueue] finishTransaction:t];
            }
                break;
            case SKPaymentTransactionStateDeferred:
            case SKPaymentTransactionStatePurchasing:
                // 不处理
                break;
        }
    }
}

/// 处理已购买交易（静默）
- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction {
    
    NSString *transactionId = transaction.transactionIdentifier;
    if (!transactionId || [self.processingTransactionIds containsObject:transactionId]) return;

    [self.processingTransactionIds addObject:transactionId];

    NSString *receipt = [self currentReceiptBase64];
    if (receipt.length == 0) return;

    [self verifyReceipt:receipt orderId:transactionId transaction:transaction sourceNewPayment:NO];
}

/// 获取 base64 receipt
- (NSString *)currentReceiptBase64 {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData) return nil;
    return [receiptData base64EncodedStringWithOptions:0];
}
#pragma mark - 验签方法
- (void)verifyReceipt:(NSString *)receipt
              orderId:(NSString *)orderId
          transaction:(SKPaymentTransaction *)transaction sourceNewPayment:(BOOL)isNewPayment {

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"user_id"] = [[UserModel sharedInstance] userId];//
    params[@"order_no"] = orderId;    //
    params[@"receipt_data"] = receipt;
    params[@"region"] = @[@"cn",@"overseas"][IS_OVERSEAS_VERSION];
    params = [LanguageHelper currentLanguageParams:params];
   
    //NSLog(@"------开始进入订阅----------ing---------------------------");
    [HttpTools postRequest:@"/appleSubscription/verify" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {

        if (success) {
            [[NSNotificationCenter defaultCenter]
                postNotificationName:IAP_Membership_Notification
                object:nil];
        }
        NSString *tid = transaction.transactionIdentifier;
       [[NSUserDefaults standardUserDefaults] setBool:YES forKey:tid];

        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        [self.processingTransactionIds removeObject:transaction.transactionIdentifier];
        
        [self processPendingTransactions];
        //NSLog(@"-验签-----------------end----------------------------");
    } failure:^(NSError * _Nonnull error) {
        //[[SKPaymentQueue defaultQueue] finishTransaction:transaction]; // 防止残留
        [self.processingTransactionIds removeObject:transaction.transactionIdentifier];
        [self processPendingTransactions];
    }];
}
- (void)processPendingTransactions {
    if (self.pendingTransactions.count == 0) {
        self.isProcessingPendingQueue = NO;
        return;
    }
    SKPaymentTransaction *t = self.pendingTransactions.firstObject;
    [self.pendingTransactions removeObjectAtIndex:0];
    [self handlePurchasedTransaction:t];
}
@end
