//
//  AgreementTipView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/17.
//

#import <UIKit/UIKit.h>
#import "MembershipAgreementView.h"
NS_ASSUME_NONNULL_BEGIN

@interface AgreementTipView : UIView
/// 点击回调（跳协议）
@property (nonatomic, copy) void (^tapHandler)(NSString *title);
@property (nonatomic, strong) UILabel *agreementLabel;
@property (strong, nonatomic) MembershipAgreementView *agreeView;
-(void)setAgreementY:(int)y;

@end

NS_ASSUME_NONNULL_END
