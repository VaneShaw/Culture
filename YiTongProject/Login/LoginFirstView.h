//
//  LoginFirstView.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoginFirstView : UIView
@property (strong, nonatomic) UILabel *lblHello;
@property (assign, nonatomic) BOOL isRegister;
@property (strong, nonatomic) UITextField *txtEmail;
@property (strong, nonatomic) UITextField *txtCode;
@property (strong, nonatomic) UITextField *txtPassword;
@property (strong, nonatomic) UITextField *txtRepassword;

@property (strong, nonatomic) UILabel *lblTipsEmail;
@property (strong, nonatomic) UILabel *lblTipsPassword;
@property (strong, nonatomic) UILabel *lblTipsConfirmPassword;
@property (strong, nonatomic) UILabel *lblTipsCode;

@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@property (nonatomic,copy) void (^selectedReadTypeIndex)(NSInteger index);//代码块传值
@end

NS_ASSUME_NONNULL_END
