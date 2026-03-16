//
//  ReceiptSyncManager.m
//  YiTongProject
//
//  Created by Vincent on 2025/12/7.
//

#import "ReceiptSyncManager.h"
#import "RestoreVipView.h"

@interface ReceiptSyncManager ()
//@property (nonatomic, strong) NSMutableArray<SKPaymentTransaction *> *pendingTransactions;
//@property (nonatomic, assign, readwrite) BOOL isProcessingPendingQueue;
@end
@implementation ReceiptSyncManager
//每次登录后，判断如果当前用户非会员的情况下 请求接口判断 是否要弹窗询问用户是否愿意迁移
+ (instancetype)sharedManager {
    static ReceiptSyncManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ReceiptSyncManager alloc] init];
        //manager.pendingTransactions = [NSMutableArray array];
    });
    return manager;
}
#pragma mark - Public
//判断同一个月份 同一id 只能启动一次
- (BOOL)canSyncReceiptThisMonth {
    NSString *userId = [UserModel sharedInstance].userId;
    if (userId.length == 0) return NO;

    // 当前年月
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM";
    NSString *month = [formatter stringFromDate:[NSDate date]];
    NSString *key = [NSString stringWithFormat:@"receipt_sync_%@_%@", userId, month];
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    

    if ([ud boolForKey:key]) {
        return NO; // 本月已经走过 //测试用
    }

    // 标记已走
    [ud setBool:YES forKey:key];
    return YES;
}
- (void)syncReceiptIfNeeded {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData || receiptData.length == 0) {
        // 🔥 没有票 → 刷新
        SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];
        request.delegate = self;
        [request start];
        return;
    }
    //iap313
    //[self uploadReceipt:receiptData];
}
/*
#pragma mark - Private
- (void)printLongString:(NSString *)str {
    NSUInteger length = str.length;
    NSUInteger max = 1000; // 每段打印 1000 字符

    for (NSUInteger i = 0; i < length; i += max) {
        NSUInteger subLength = MIN(max, length - i);
        NSString *sub = [str substringWithRange:NSMakeRange(i, subLength)];
        NSLog(@"%@", sub);
    }
}
- (void)uploadReceipt:(NSData *)receiptData {
    NSString *receiptStr = [receiptData base64EncodedStringWithOptions:0];
    [self judgeTransfer:receiptStr];

}

#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request {
    // 🔥 收据刷新成功 → 重新读收据，并上传
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (receiptData && receiptData.length > 0) {
        [self uploadReceipt:receiptData];
    }
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"刷新 receipt 失败: %@", error);
}

// 2. 创建一个 __block 标志，防止重复隐藏
// 3. 设置超时隐藏（例如 4 秒）

- (void)judgeTransfer:(NSString *)receiptData {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"receipt_data"] = receiptData;  //region
    params[@"region"] = @[@"cn",@"overseas"][IS_OVERSEAS_VERSION];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@"/appleSubscription/judgeTransfer" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        if (success) {
            NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
            //NSLog(@"-----dic-----00judgeTransfer----------------------[%@]",dic);
            NSString *is_transfer = [NSString stringWithFormat:@"%@",dic[@"is_transfer"]];
            if(is_transfer.intValue == 1){
                NSString *str1 = @"You're signed in with a different account.Transfer your subscription to keep yourmembership active on this device:";
                NSString *str2 = @"·No extra charges\n·You may continue using the originalmember account\n·If it doesn't update right away, use\"Restore Subscription\" on theMembership page";
                [MembershipTransferView showViewTitle:@"" buttonArrayTitle:@[@"Membership Transfer",str1,str2,@"Not Now",@"Transfer"] callBack:^(NSInteger index) {
                    if(index == 1001 ){
                        [self transfer:receiptData];
                    }
                }];
            }
        } else {
            NSString *message = [NSString stringWithFormat:@"%@",response.msg];
            if(message.length > 0){
                [MBProgressHUD showLabel:message];
            }
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)transfer:(NSString *)receiptData {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"receipt_data"] = receiptData;  //region
    params[@"region"] = @[@"cn",@"overseas"][IS_OVERSEAS_VERSION];
    params = [LanguageHelper currentLanguageParams:params];
    [RestoreVipView showViewTitle:@"" buttonArrayTitle:@[@"Restoring your membership...",@"Please wait and do not leave this page."] callBack:^(NSInteger index) {
    }];
    
    [HttpTools postRequest:@"/appleSubscription/transfer" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        [RestoreVipView hiddenAll];
        
        //NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
        //NSLog(@"-----dic-----11transfer----------------------[%@]---------",dic);
        
        if (success) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:IAP_Membership_Notification
                    object:nil];
                });
            [MBProgressHUD showLabel:response.msg];
        } else {
            NSString *message = [NSString stringWithFormat:@"%@",response.msg];
            if(message.length > 0){
                [MBProgressHUD showLabel:message];
            }
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}

//===============================================================================
*/

@end
