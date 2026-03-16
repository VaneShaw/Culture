//
//  YTIAPService.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/15.
//

#import "YTIAPService.h"

/*
@interface YTIAPService ()
@property (nonatomic, strong) SKProductsRequest *productRequest; // 保持请求实例，防止被释放
@property (nonatomic, copy) NSString *currentOrderId;

// 👉 用于「进入页面时的状态同步」
@property (nonatomic, copy) YTIAPSyncCompletion syncCompletion;
@property (nonatomic, copy) YTIAPResultBlock completion;
@property (nonatomic, assign) BOOL isVerifying; // 避免重复验签
@property (nonatomic, weak) UIViewController *uvc; // 用于 HUD 显示

@property (nonatomic, strong) NSMutableSet<NSString *> *processingTransactionIds;
@property (nonatomic, assign) BOOL isPurchase; // YES 表示点击支付发起购买
@property (nonatomic, strong) NSString *productId;
@property (nonatomic, strong) NSMutableSet<NSString *> *verifyingOrderSet;


@property (nonatomic, assign) NSTimeInterval currentPurchaseTimestamp;
@end
@implementation YTIAPService
#pragma mark - 单例
+ (instancetype)shared {
    static YTIAPService *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[YTIAPService alloc] init];

        // ✅ 正在处理的 transactionId 集合
         service.processingTransactionIds = [NSMutableSet set];
         // ✅ 正在验签的订单号集合
         service.verifyingOrderSet = [NSMutableSet set];

        // 添加交易观察者，确保 App 启动就能处理未完成交易
        [[SKPaymentQueue defaultQueue] addTransactionObserver:service];
    });
    return service;
}

#pragma mark - 发起购买
- (void)startPurchaseWithProductId:(NSString *)productId
                           orderId:(NSString *)orderId
                              uvc:(UIViewController *)uvc
                        completion:(YTIAPResultBlock)completion {
    
    
    if ([self isPaymentInProgress]) {
        if (completion) {
            completion(NO, NSLocalizedString(@"Payment is in progress.", @""), 0);
        }
        return;
    }

    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(NO, NSLocalizedString(@"Payment unavailable.", @""), 0);
        }
        return;
    }
    
    
    self.currentPurchaseTimestamp = [[NSDate date] timeIntervalSince1970];
    if([KUSER_DEFAULT objectForKey:IAP_Product_id]){
        self.productId = [KUSER_DEFAULT objectForKey:IAP_Product_id];
    }

    productId = self.productId;
    //=========处理订单号相关逻辑1=============================================
    orderId = @"";//改动测试11

 
    self.completion = completion;
    self.currentOrderId = orderId;
    self.uvc = uvc;
    
    // 显示 HUD，防止用户乱点 //转圈圈
    [self showHUD];
    // 补单（处理之前未完成交易）
    //[self checkUnfinishedTransactionsWithUVC:uvc];
    // 1️⃣ 请求商品信息
    self.isPurchase = YES;
    self.productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
    self.productRequest.delegate = self;
    [self.productRequest start];
}
//self.productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
//self.productRequest.delegate = self;
//[self.productRequest start];

//为了查询商品信息
- (void)requestPriceForProduct:(NSString *)productId
                     completion:(YTIAPPriceCompletion)completion {
    self.priceCompletion = completion;
    self.isPurchase = NO;
    // 创建 SKProductsRequest
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
    request.delegate = self;
    [request start];
}

//离开时判断
- (void)finishUnprocessedTransactionsSafely {
    NSArray<SKPaymentTransaction *> *transactions = [SKPaymentQueue defaultQueue].transactions;
    
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *tid = transaction.transactionIdentifier;
        if (!tid) continue;

        switch (transaction.transactionState) {
            // ✅ 已支付或恢复
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored: {
                // 仅 finish 已经处理过的交易（验签成功或明确失败）
                if ([self.processingTransactionIds containsObject:tid]) {
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    [self.processingTransactionIds removeObject:tid];
                    NSLog(@"Finished processed transaction: [%@]-------0---", tid);
                }
                break;
            }
            // ✅ 支付失败
            case SKPaymentTransactionStateFailed: {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Finished failed transaction: [%@]-----------11", tid);
                break;
            }
            // ⏳ 不处理 Purchasing / Deferred
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateDeferred:
            default:
                break;
        }
    }
    
    NSArray *transactions1 = [SKPaymentQueue defaultQueue].transactions;
    NSLog(@"补签---------补单的count--------[%ld]--------end----",transactions1.count);
    
}
// 判断是否可以发起支付（没有正在进行的购买）  购买中
- (BOOL)isPaymentInProgress {
    for (SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                return YES; // 正在支付中，不允许再次发起
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                break;
        }
    }
    return NO;
}

// 判断是否存在待家长批准的支付      延迟
- (BOOL)isParentalApprovalRequired {
    for (SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateDeferred:
                // 需要家长批准
                return YES;
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                break;
        }
    }
    return NO;
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request
      didReceiveResponse:(SKProductsResponse *)response {
    
    if (response.products.count == 0) {
        [self hideHUD];
        NSString *message = @"Product unavailable.";
        message = NSLocalizedString(message,@"");
        if (self.completion) self.completion(NO, message,0);
        return;
    }
    SKProduct *product = response.products.firstObject;
    NSArray *transactions = [SKPaymentQueue defaultQueue].transactions;
    NSLog(@"补签---------补单的count--------[%ld]------------",transactions.count);
    
    // 2️⃣ 创建可变支付对象（可设置 applicationUsername）
    // ===== 购买逻辑 =====
    if (self.isPurchase) {
        NSLog(@"[点击购买才会触发----这里]--------");
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        //=========处理订单号相关逻辑1=============================================
 
        [[SKPaymentQueue defaultQueue] addPayment:payment]; // 3️⃣ 添加到支付队列
    }
    if (!product) {
        NSLog(@"【会员-service】-[商品不存在]--------");
        return;
    }
    // ✅ 在这里才能安全获取 product
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = product.priceLocale;
    NSString *priceString = [formatter stringFromNumber:product.price];
    
    NSString *productId = product.productIdentifier;
    self.productId = productId;
    [KUSER_DEFAULT setObject:productId forKey:IAP_Product_id];

    //NSInteger trialDays = [self trialDaysFromProduct:product];
    //NSString *trialText = [self trialDescriptionFromProduct:product];
    NSLog(@"【会员商品信息】--商品ID[%@]----商品价格:[%@] 数量:[%ld]---------",productId, priceString,response.products.count);
    //NSLog(@"------试用天数---------[%@]-----------",trialText);//7天免费试用
    
    NSString *price = [formatter stringFromNumber:product.price];
     if (self.priceCompletion) {
         self.priceCompletion(price);
     }
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
    for (SKPaymentTransaction *t in transactions) {
        NSString *tid = t.transactionIdentifier;

        switch (t.transactionState) {
            // ======================
            // ✅ 购买成功 / 恢复购买
            // ======================
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored: {

                if (tid.length > 0 && ![self.processingTransactionIds containsObject:tid]) {
                    [self.processingTransactionIds addObject:tid];
                }
                //=========处理订单号相关逻辑2=============================================
     
             
                BOOL isNewPayment = NO;
                if (self.isPurchase &&  t.transactionDate.timeIntervalSince1970 >= self.currentPurchaseTimestamp) {
                        isNewPayment = YES;
                }
                [self handlePurchasedTransaction:t
                                sourceNewPayment:isNewPayment];
            }
                break;

            // ======================
            // ❌ 支付失败
            // ======================
            case SKPaymentTransactionStateFailed: {

                NSLog(@"=========处理订单号相关逻辑2===========================================x1==");
                //BOOL isCurrentPay = (orderId.length > 0 && [orderId isEqualToString:self.currentOrderId]);
                BOOL isCurrentPay = self.isPurchase;
                [[SKPaymentQueue defaultQueue] finishTransaction:t];
                [self hideHUD];
                NSString *message1 = t.error.localizedDescription;
                NSLog(@"1--Failed--------[%d]---------message1=[%@]---",isCurrentPay,message1);
                
                if (isCurrentPay && self.completion) {
                    NSString *message = @"Payment failed";
                    if (t.error.code == SKErrorPaymentCancelled) {
                        message = @"User cancellation";
                        self.completion(NO, NSLocalizedString(message, @""), 0);
                    } else if (t.error.localizedDescription.length > 0) {
                        message = t.error.localizedDescription;
                        self.completion(NO, NSLocalizedString(message, @""), 0);
                    } else {
                        self.completion(NO, NSLocalizedString(message, @""), 0);
                    }
                    NSLog(@"2--Failed--------[%d]-----[%@]",isCurrentPay,message);
                    self.completion = nil;
                }
                
                NSLog(@"=========处理订单号相关逻辑2========================================c2=====");
            }
                break;

            // ======================
            // ⏳ 等待家长确认
            // ======================
            case SKPaymentTransactionStateDeferred: {
                //=========处理订单号相关逻辑2=============================================
                //BOOL isCurrentPay =  (orderId.length > 0 && [orderId isEqualToString:self.currentOrderId]);
                BOOL isCurrentPay = self.isPurchase;
                
                [self hideHUD];
                // ⚠️ Deferred 不能 finish
                if (isCurrentPay && self.completion) {
                    NSString *message =
                    NSLocalizedString(@"Waiting for parental approval.", @"");
                    self.completion(NO, message, 0);
                    self.completion = nil;
                }
            }
                break;

            // ======================
            // 🕐 正在购买
            // ======================
            case SKPaymentTransactionStatePurchasing:
                // 不处理
                break;
        }
    }
}
- (BOOL)isAlreadySubscribedError:(NSError *)error {
    NSString *desc = error.userInfo.description;
    return [desc containsString:@"3532"] ||
           [desc containsString:@"already subscribed"];
}

- (BOOL)shouldStartVerifyForTransaction:(NSString *)transactionId
                            forceAllow:(BOOL)forceAllow {

    if (transactionId.length == 0) {
        NSLog(@"❌ transactionId 为空，直接拦截");
        return NO;
    }

    @synchronized (self) {

        // 🔓 点击购买：强制放行一次
        if (forceAllow) {
            [self.verifyingOrderSet addObject:transactionId];
            NSLog(@"✅ 用户主动购买，强制放行验签：%@", transactionId);
            return YES;
        }

        // 🚫 非点击购买（补单 / restore）
        if ([self.verifyingOrderSet containsObject:transactionId]) {
            NSLog(@"🚫 已在验签中或已验签，忽略：%@", transactionId);
            return NO;
        }

        [self.verifyingOrderSet addObject:transactionId];
        NSLog(@"✅ 补单 / restore 进入验签：%@", transactionId);
        return YES;
    }
}
- (void)finishVerifyForOrder:(NSString *)orderId {
    if (orderId.length == 0) return;
    @synchronized (self) {
        [self.verifyingOrderSet removeObject:orderId];
    }
}

#pragma mark - 处理已购买交易 → 验签
- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction
                sourceNewPayment:(BOOL)isNewPayment {
    NSLog(@"---------------------验签判断前-------进入重复过滤-----");
    NSString *transactionId = transaction.transactionIdentifier;
    if (!transactionId || transactionId.length == 0) return;
    // 防止重复验签
    BOOL canVerify = [self shouldStartVerifyForTransaction:transactionId
                                               forceAllow:isNewPayment];
    if (!canVerify) {
        NSLog(@"🚫 重复验签被阻止 transactionId=%@", transactionId);
        return;
    }
    // 获取本地 receipt
      NSString *receipt = [self currentReceiptBase64];
      if (!receipt || receipt.length == 0) {
          NSLog(@"⚠️ receipt 为空，等待下次回调处理 transactionId=%@", transactionId);
          return; // 不 finish，留给下次 observer
      }

    // 3️⃣ 开始验签（异步）
    NSLog(@"-----------------------------正式进入验签-------------------------------[%@]----------",transactionId);
    [self verifyReceipt:receipt
               orderId:transactionId
           transaction:transaction
     sourceNewPayment:isNewPayment];
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
    if(isNewPayment){
        [self showOrUpdateMessage:@"Processing order..."];
    }
    //NSLog(@"------开始进入订阅----------ing---------------------------");
    [HttpTools postRequest:@"/appleSubscription/verify" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
   NSLog(@"进入----验证中------------isNewPayment=[%d]-----------------success=[%d]------msg=[%@]-----oredr=[%@]--状态=[%@]",isNewPayment,success,response.msg,orderId,response.data);
        
        self.isVerifying = NO;
        // 隐藏 HUD //转圈圈
        [self hideHUD];
        NSString *tid = transaction.transactionIdentifier;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:tid];
        NSString *msg = @"";
 
        if (success) {
            // ✅ 后端验签成功，唯一 finish 点
            [self.processingTransactionIds removeObject:tid];
            msg = @"Purchase successful.";
            msg = NSLocalizedString(msg,@"");
            if (!isNewPayment && self.syncCompletion) {
                self.syncCompletion(YTIAPSyncResultUpdated);
                self.syncCompletion = nil;
            }
        } else {
            msg = @"Verification failed. Try restoring later.";//@"支付验证失败，请稍后恢复会员";
            msg = @"Payment successful. Activating membership.";
            msg = NSLocalizedString(msg,@"");

            // ❌ 后端失败，不 finish
            //NSString *message = @"Payment successful. Activating membership.";
            //message = NSLocalizedString(message,@"");
            //[MBProgressHUD showLabel:message];
            [self.processingTransactionIds removeObject:tid];
            [self unmarkTransactionProcessing:transaction];
        }
        if(isNewPayment){
            self.isPurchase = NO;
            self.currentPurchaseTimestamp = 0;
            
            NSString *status = @"1";
            if ([response.data isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
                status = [NSString stringWithFormat:@"%@",dic[@"status"]];
            }
            BOOL isStatus = success;
            if (self.completion) self.completion(isStatus, msg,status.intValue);
            self.completion = nil;
        }
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        NSLog(@"-验签-----------------end----------------------------");
    } failure:^(NSError * _Nonnull error) {
        self.isVerifying = NO;
        NSString *tid = transaction.transactionIdentifier;
        [self.processingTransactionIds removeObject:tid];
        //NSLog(@"-验签-错误--------------error--[%@]----------------------------",error);
        [self hideHUD];
        // 网络失败，不 finish，等下次补单
        //[MBProgressHUD showLabel:error.localizedDescription];
        
        if(isNewPayment){
            self.isPurchase = NO;
            self.currentPurchaseTimestamp = 0;
            NSString *message = @"Network error. Try again later.";
            //message = NSLocalizedString(message,@"");
            message = error.localizedDescription;
            //NSLog(@"-验签错误--isnew------------error--[%@]------------------message=[%@]----------",error,message);
            if (self.completion) self.completion(NO, message,0);
            self.completion = nil;
        }
    }];
    
    
}
#pragma mark - 获取本地 receipt
- (NSString *)currentReceiptBase64 {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData) return nil;
    return [receiptData base64EncodedStringWithOptions:0];
}
- (BOOL)isTransactionBeingProcessed:(SKPaymentTransaction *)t {
    if (!t.transactionIdentifier) return NO;
    return [self.processingTransactionIds containsObject:t.transactionIdentifier];
}
- (void)markTransactionProcessing:(SKPaymentTransaction *)t {
    if (!t.transactionIdentifier) return;
    [self.processingTransactionIds addObject:t.transactionIdentifier];
}

- (void)unmarkTransactionProcessing:(SKPaymentTransaction *)t {
    if (!t.transactionIdentifier) return;
    [self.processingTransactionIds removeObject:t.transactionIdentifier];
}
- (void)showHUD {
    [[GlobalHUDManager shared] showOrUpdateMessage:@""];
    //[[GlobalHUDManager shared] show];
}

- (void)hideHUD {
    [[GlobalHUDManager shared] hide];
    //[[GlobalHUDManager shared] forceHideAll];
}

- (void)showOrUpdateMessage:(NSString *)message {
    [[GlobalHUDManager shared] showOrUpdateMessage:message];
}

@end
 */
