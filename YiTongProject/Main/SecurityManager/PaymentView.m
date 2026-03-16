//
//  PaymentView.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/27.
//

#import "PaymentView.h"
#import "HelpRulesViewController.h"
#import "YTIAPService.h"
#import "MemberRetentionView.h"
#import "AgreementTipView.h"
@interface PaymentView()
@property (nonatomic, strong) NSString *vip_status;
@property (nonatomic, strong) NSString *trial_time;
@property (nonatomic, strong) NSDictionary *dicOrder;
@property (strong, nonatomic) UIButton *btnPlay;
@property (nonatomic, strong) UILabel *lblTips;
@property (strong, nonatomic) AgreementTipView *tipView;

@end
@implementation PaymentView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        //[self setShowPopup:@""];
        self.dicOrder = nil;
        UILabel *lblTips = [[UILabel alloc]init];
        lblTips.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        lblTips.textColor = [self colorWithHexString:@"#9DABC2" alpha:1];
        lblTips.text = NSLocalizedString(@"*Manage Subscription on the App Store", @"");
        lblTips.textAlignment = NSTextAlignmentCenter;
        lblTips.hidden = YES;
        self.lblTips = lblTips;
        
        [self addSubview:self.btnPlay];
        [self addSubview:self.lblTips];
        
        self.btnPlay.frame = CGRectMake(20,  14, SCREEN_WIDTH - 40, 50);
        self.lblTips.frame = CGRectMake(10, 4 + self.btnPlay.frame.size.height +  self.btnPlay.frame.origin.y, SCREEN_WIDTH - 20, 17);
        //--------------------------------------------------------------------------
        
        AgreementTipView *tipView = [[AgreementTipView alloc] initWithFrame:CGRectMake(0, self.btnPlay.frame.origin.y + self.btnPlay.frame.size.height, SCREEN_WIDTH, 82 - 5)];
        self.tipView = tipView;
        tipView.tapHandler = ^(NSString * _Nonnull title) {
            if(IS_OVERSEAS_VERSION){
                //NSLog(@"会员服务协议被点击了！");
                // 可以在这里 push 一个 WebView 或者跳转到协议页面
                HelpRulesViewController *rulesVC = [HelpRulesViewController new];
                rulesVC.title = NSLocalizedString(@"Membership Service Terms",@"");
                rulesVC.rule_type = @"member";
                [self.uvc.navigationController pushViewController:rulesVC animated:YES];
                
            } else {
                
                HelpRulesViewController *rulesVC = [HelpRulesViewController new];
                if ([title isEqualToString:@"会员服务协议"]) {
                    //NSLog(@"点了用户协议");
                    //《会员服务协议》
                    rulesVC.title = NSLocalizedString(@"Membership Service Terms",@"");
                    rulesVC.rule_type = @"member";
                } else if ([title isEqualToString:@"隐私政策"]) {
                    //NSLog(@"点了隐私政策");
                    //《隐私政策》
                    rulesVC.title = NSLocalizedString(@"[Privacy Policy]",@"");
                    rulesVC.rule_type = @"privacy";
                }
                [self.uvc.navigationController pushViewController:rulesVC animated:YES];
            }
        };
        
        [self addSubview:tipView];

    }
    return self;
}

//button同时有背景图和文字
- (UIButton *)btnPlay {
    if(!_btnPlay){
        _btnPlay = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnPlay setBackgroundImage:[UIImage imageNamed:@"button_colorurs"] forState:UIControlStateNormal];
        //vip 状态 1=非会员，未试用，2=非会员，已过期，3=已订阅（含免费试用），4=已订阅（但取消）

        _btnPlay.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        [_btnPlay setTitleColor:[self colorWithHexString:@"#0D1346" alpha:1] forState:UIControlStateNormal];
        [_btnPlay addTarget:self action:@selector(btnPlayAction:) forControlEvents:UIControlEventTouchUpInside];
        //Base style for 圆角矩形 1 拷
    }
    return _btnPlay;
}
- (void)btnPlayAction:(UIButton *)sender {
    //iap313
    /*sender.enabled = NO;      // 禁用按钮
    if (![self hasNetwork]) {
        sender.enabled = YES;   // 恢复按钮点击
        [self showNoNetworkAlert]; // 弹窗提示
        return;
    }
    
//    if (![SKPaymentQueue canMakePayments]) {
//        NSString *message = @"Purchases not allowed on this device.";
//        [MBProgressHUD showLabel:NSLocalizedString(message, @"")];
//        return;
//    }
    __weak UIButton *weakSender = sender;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(9 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (weakSender && !weakSender.enabled) {
            weakSender.enabled = YES;
        }
    });

    switch (self.vip_status.intValue) {
        case 1:case 2:
        {
            //=======================================================
            if ([[YTIAPService shared] isPaymentInProgress]) {
                NSString *message = @"Payment processing. Membership will restore shortly.";
                [MBProgressHUD showLabel:NSLocalizedString(message, @"")];
                return;
            }
            if ([[YTIAPService shared] isParentalApprovalRequired]) {
                NSString *message = @"Parental approval required.";
                [MBProgressHUD showLabel:NSLocalizedString(message, @"")];
                return;
            }//case SKPaymentTransactionStatePurchasing: （购买中    ing）   “支付仍在处理中，如已扣款请稍后恢复会员权益”

            if(IS_OVERSEAS_VERSION){
                [self createOrderData];
            } else {
                if(self.tipView.agreeView.isChecked){   //点击同意 跳转 支付
                    [self createOrderData];
                } else {
                    NSString *message = @"Please accept the Membership Agreement and Privacy Policy";
                    [MBProgressHUD showLabel:NSLocalizedString(message, @"")];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.btnPlay.enabled = YES;
                    });
                }
            }
            
            //=======================================================
        }
            break;
        case 3:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.btnPlay.enabled = YES;
            });
            NSString *message = @"You’re already subscribed.";
            [MBProgressHUD showLabel:NSLocalizedString(message, @"")];
        }
            break;
        case 4:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.btnPlay.enabled = YES;
            });
            NSString *urlString = @"itms-apps://apps.apple.com/account/subscriptions";
            NSURL *url = [NSURL URLWithString:urlString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            }
        }
            break;
        default:
            break;
    }*/
}
- (BOOL)isDictionaryEmpty:(NSDictionary *)dict {
    // 先判断是否为 nil，再判断是否有元素
    return (dict == nil || [dict isKindOfClass:[NSNull class]] || dict.count == 0);
}

#pragma mark - 简单网络检测方法
- (BOOL)hasNetwork {
    // 这里用一个简单方法判断网络
    // 生产环境建议使用 Reachability 或 NWPathMonitor
    return [UIApplication sharedApplication].connectedScenes.count > 0;
}

#pragma mark - 无网络提示
- (void)showNoNetworkAlert {
    NSString *message = @"Network is unavailable. Please check your Wi-Fi or cellular data settings.";
    [MBProgressHUD showLabel:NSLocalizedString(message, @"")];
}
- (void)setVipStatus:(NSString *)status vipPrice:(NSString *)price trial_time:(NSString *)trial_time{


    
    self.trial_time = trial_time;
    self.vip_status = status;

    //vip 状态 1=非会员，未试用，2=非会员，已过期，3=已订阅（含免费试用），4=已订阅（但取消）"
    //状态2   状态3
    //"$6.99/month · Unlock Now" = "限时 8 元/月 · 立即解锁";
    NSString *staus2 = [NSString stringWithFormat:@"%@/month · Unlock Now",price];
    if(!IS_OVERSEAS_VERSION){//元/月
        staus2 = [NSString stringWithFormat:@"限时 %@ /月 · 立即解锁",price];
    }
    if(self.vip_status.intValue < 6){
        NSString *str1 = @[@"",@"Start Free Trial",staus2,staus2,@"Restore Subscription",@"",@""][self.vip_status.intValue];
        [self.btnPlay setTitle:NSLocalizedString(str1,@"") forState:UIControlStateNormal];
    }

    if(self.vip_status.intValue == 4){
        self.lblTips.hidden = NO;
        [self.tipView setAgreementY:12 + 14];
    } else {
        [self.tipView setAgreementY:3 + 14];
        self.lblTips.hidden = YES;
    }
    self.btnPlay.frame = CGRectMake(20,  14, SCREEN_WIDTH - 40, 50);
}

- (void)createOrderData {

    [self setproductId:@"" orderId:@""];
}
- (void)craterOrderId:(NSDictionary *)dic {
    //NSString *orderId = [NSString stringWithFormat:@"%@",dic[@"order_no"]];
    //NSString *productId = [NSString stringWithFormat:@"%@",dic[@"app_product_id"]];
    //[self setproductId:productId orderId:orderId];
    [self setproductId:@"" orderId:@""];
}
- (void)setproductId:(NSString *)productId orderId:(NSString *)orderId{
    NSLog(@"外层【创建订单】--------productId===[%@]----------orderId===[%@]",productId,orderId);
    // 2️⃣ 调用 YTIAPService 发起购买
    //iap313
    /*[[YTIAPService shared] startPurchaseWithProductId:productId
                                              orderId:orderId
                                                  uvc:self.uvc
                                           completion:^(BOOL success, NSString * _Nullable message,int type) {
        if(success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.btnPlay.enabled = YES;
                NSLog(@"-YTIAPService--支付成功验签返回--回调刷新-------type=[%d]刷新------vip_status[%@]",type,self.vip_status);
                BOOL shouldShowUI = (type != 1);
                //if(shouldShowUI && (self.vip_status.intValue == 1 || self.vip_status.intValue == 2)){
                if(shouldShowUI){
                        [UnlockedView showViewTitle:self.vip_status dataArray:@[self.trial_time] callBack:^(NSInteger index) {
                            [self.uvc.navigationController popViewControllerAnimated:YES];
                    }];
                }
                [UserStateManager shared].needRefreshVipUI = YES;
    
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:IAP_Membership_Notification
                    object:nil];
            });

        } else {
            
            NSString *str =  NSLocalizedString(@"User cancellation", @"");
            if([message isEqualToString:str]){
                [self setShowPopup:message];
            } else {
                if(message.length > 0){
                    [MBProgressHUD showLabel:message];
                }
            }
            NSLog(@"-------YTIAPService--返回失败-[%@]---------===-----",message);
        }
    }];*/
}
- (void)setShowPopup:(NSString *)messge {
    //一天之内只出现一次 不重复弹窗
    //===========================a1===================
    // 1. 获取存储的上次弹出时间
    static NSString *const kPopupDateKey = @"lastPopupDateKey_key";
    NSDate *lastDate = [KUSER_DEFAULT objectForKey:kPopupDateKey];
    NSDate *now = [NSDate date];  // 当前时间
    // 2. 判断是否应该显示
    BOOL shouldShow = YES;  // 默认显示
    if (lastDate) {  // 如果有上次记录
        NSCalendar *calendar = [NSCalendar currentCalendar];
        // 判断是否同一天
        if ([calendar isDate:lastDate inSameDayAsDate:now]) {
            shouldShow = NO;
        }
    }
    // 3. 只有满足条件时才显示弹窗
    //shouldShow = YES;
    if (shouldShow) {
        // 只在此处展示弹窗
        [MemberRetentionView showViewTitle:self.vip_status dataArray:@[self.trial_time] callBack:^(NSInteger index) {
            if(index == 2001){
                [self craterOrderId:self.dicOrder];
            }
        }];
        // 记录弹出时间
        [KUSER_DEFAULT setObject:now forKey:kPopupDateKey];
    } else {
        // 这里不会执行任何弹窗逻辑
        NSLog(@"今天已经弹过，不再显示");
        //[MBProgressHUD showLabel:messge];
    }
    //===========================a1===================
}

@end

