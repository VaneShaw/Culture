//
//  ProfileViewController.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileViewController : BaseViewController

@end

NS_ASSUME_NONNULL_END
/*
 - (void)getUserHomeInfo11{
     NSMutableDictionary *params = [NSMutableDictionary dictionary];
     params = [LanguageHelper currentLanguageParams:params];
     [HttpTools postRequest:@"/user/getUserHomeInfo" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
         //[self getBanner];
          if (success) {
              NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
              NSString *avatar = [NSString stringWithFormat:@"%@",dic[@"avatar"]];
              [self.btnAvatar sd_setImageWithURL:[NSURL URLWithString:avatar]
                                        forState:UIControlStateNormal];
              
              [KUSER_DEFAULT setObject:dic forKey:@"user_info_key"];
              
              self.lblUserName.text = [NSString stringWithFormat:@"%@",dic[@"username"]];
              self.strEmail = @[[NSString stringWithFormat:@"%@",dic[@"mobile"]],[NSString stringWithFormat:@"%@",dic[@"email"]]][IS_OVERSEAS_VERSION];
              self.lblEmail.text = [self maskEmail:self.strEmail];

         } else {
             [MBProgressHUD showLabel:response.msg];
         }
  
     } failure:^(NSError * _Nonnull error) {
     }];
 }
 */
