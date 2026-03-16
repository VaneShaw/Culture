//
//  YTIAPService.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/15.
//

#import <Foundation/Foundation.h>
/*#import <StoreKit/StoreKit.h>


typedef NS_ENUM(NSInteger, YTIAPSyncResult) {
    YTIAPSyncResultNone,        // 没有需要处理的
    YTIAPSyncResultUpdated,    // 有补单 / 恢复 / 状态变化
    YTIAPSyncResultFailed      // 同步失败（网络等）
};
typedef void (^ _Nullable YTIAPPriceCompletion)(NSString * _Nullable price);

typedef void (^YTIAPSyncCompletion)(YTIAPSyncResult result);
typedef void(^YTIAPResultBlock)(BOOL success, NSString * _Nullable message,int type);
@interface YTIAPService : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, copy, nullable) YTIAPPriceCompletion priceCompletion;
// 单例
+ (instancetype _Nonnull)shared;

// 发起购买，外部只需 productId 和 orderId
- (void)startPurchaseWithProductId:(NSString * _Nonnull)productId
                           orderId:(NSString * _Nonnull)orderId
                             uvc:(UIViewController * _Nonnull)uvc
                        completion:(YTIAPResultBlock _Nonnull)completion;

// 请求价格
- (void)requestPriceForProduct:(NSString *_Nonnull)productId
                     completion:(YTIAPPriceCompletion)completion;


- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction
                  sourceNewPayment:(BOOL)isNewPayment;
// App 启动 / 页面进入时补单

//- (BOOL)preparePayment;
// 判断是否可以发起支付（没有正在进行的购买）
- (BOOL)isPaymentInProgress;

// 判断是否存在待家长批准的支付
- (BOOL)isParentalApprovalRequired;

- (void)finishUnprocessedTransactionsSafely;

@end*/


//#pragma mark - 处理已购买交易 → 验签
/*- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction       sourceNewPayment:(BOOL)isNewPayment{
    //no历史补签   yes 新的
    // 1️⃣ transaction 级防重（最关键）
    // 防止同一笔交易被重复处理：
    // - paymentQueue 会多次回调同一笔 transaction
    // - App 重启 / 进入支付页时 Apple 会重放未 finish 的交易
    // - 补单扫描和实时监听可能同时触发
    // 如果这笔 transaction 已经在处理（验签中），直接 return
      if ([self isTransactionBeingProcessed:transaction]) {
          NSLog(@"------重复--已过滤-------11---------------");
          return;
      }
   
      [self markTransactionProcessing:transaction];
      // 2️⃣ 获取 receipt（App 级）
      NSString *receipt = [self currentReceiptBase64];
      if (receipt.length == 0) {
          // 不 finish，留给下次补单
          [self unmarkTransactionProcessing:transaction];
          return;
      }
      // 3️⃣ 订单号策略
      NSString *orderId = transaction.payment.applicationUsername;
      if (orderId.length == 0 && isNewPayment) {
          orderId = self.currentOrderId;
      }
    NSLog(@"--- 开始进入验签---非重复--len=[%ld]--isnew=[%d]---order.len=[%ld]---------执行到里面了",receipt.length,isNewPayment,orderId.length);
      // ⚠️ 新支付却没有订单号 → 严重异常
      if (isNewPayment && orderId.length == 0) {
          [self unmarkTransactionProcessing:transaction];
          return;
      }
    [self verifyReceipt:receipt orderId:orderId transaction:transaction sourceNewPayment:isNewPayment];

}*/
