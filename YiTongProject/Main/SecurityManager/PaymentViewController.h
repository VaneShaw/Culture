//
//  PaymentViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/11/25.
//

#import <UIKit/UIKit.h>
#import "PaymentView.h"
NS_ASSUME_NONNULL_BEGIN

@interface PaymentViewController : UIViewController
//@property (nonatomic, copy) void(^payVCResultCallback)(BOOL success);
@property (strong, nonatomic) PaymentView *paymentView;
@property (nonatomic, assign) int currentIndex;

@end

NS_ASSUME_NONNULL_END
/*
 - (void)loadCheckVipxxx {
     NSMutableDictionary *params = [NSMutableDictionary dictionary];
     params[@"app_region"] = @[@"domestic",@"overseas"][IS_OVERSEAS_VERSION];
     params = [LanguageHelper currentLanguageParams:params];
     [HttpTools postRequest:@"/vip/check" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
         if (success) {
             NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
      
             1是vip     0否
             NSString *is_vip = [NSString stringWithFormat:@"%@",dic[@"is_vip"]];
             //1 已开通试用   0否
             NSString *can_trial = [NSString stringWithFormat:@"%@",dic[@"can_trial"]];
             //1 已订阅。   2 取消订阅
             NSString *can_subscribe = [NSString stringWithFormat:@"%@",dic[@"can_subscribe"]];
             //到期时间戳
             NSString *expired_at = [NSString stringWithFormat:@"%@",dic[@"expired_at"]];
             NSString *remaining_days = [NSString stringWithFormat:@"%@",dic[@"remaining_days"]];
             
             self.vip_status = [NSString stringWithFormat:@"%@",dic[@"vip_status"]];
             //self.vip_status = @"1";
             NSLog(@"--------加载--payData-----[%@]",self.vip_status);
             //vip 状态 1=非会员，未试用，2=非会员，已过期，3=已订阅（含免费试用），4=已订阅（但取消）
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self reloadNewData];
             });
         }
     }
      failure:^(NSError * _Nonnull error) {
     }];
 }
 */
