//
//  PaymentView.h
//  YiTongProject
//
//  Created by ios01 on 2025/11/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PaymentView : UIView
//@property (nonatomic, copy) void(^payResultCallback)(BOOL success);
//@property (nonatomic, copy) void(^payCurrentVCResultCallback)(BOOL success);
@property (strong, nonatomic) UIViewController *uvc;
- (void)setVipStatus:(NSString *)vip_status vipPrice:(NSString *)price trial_time:(NSString *)trial_time;


@end

NS_ASSUME_NONNULL_END
//===================================
//============================================================
//===================================
/*- (void)createCnAprotocolLink {
    NSURL *url = [NSURL URLWithString:@""];
    MembershipAgreementView *agree = [[MembershipAgreementView alloc] initWithAgreementURL:url privacyURL:url];
    agree.translatesAutoresizingMaskIntoConstraints = NO;
    // 初始是否勾选
    agree.checked = NO;
    agree.hidden = YES;
    self.agreeView = agree;
    // 回调：勾选/取消
    __weak typeof(self) weakSelf = self;
    agree.onToggle = ^(BOOL checked) {
        NSLog(@"checked? -----[%d]---", checked);
        //checked 1 选中。  0 未打勾
        // 例如：设置注册按钮 enable
        //weakSelf.btnCode.enabled = checked;
    };
    //BOOL isChecked = agree.isChecked;
    agree.onTapLinkName = ^(NSString *name) {
        HelpRulesViewController *rulesVC = [HelpRulesViewController new];
        if ([name isEqualToString:@"会员服务协议"]) {
            //NSLog(@"点了用户协议");
            rulesVC.title = NSLocalizedString(@"《会员服务协议》",@"");
            rulesVC.title = NSLocalizedString(@"Membership Service Terms",@"");
            rulesVC.rule_type = @"member";
        } else if ([name isEqualToString:@"隐私政策"]) {
            //NSLog(@"点了隐私政策");
            rulesVC.title = NSLocalizedString(@"《隐私政策》",@"");
            rulesVC.title = NSLocalizedString(@"[Privacy Policy]",@"");
            rulesVC.rule_type = @"privacy";
        }
        [self.uvc.navigationController pushViewController:rulesVC animated:YES];
    };

    [self addSubview:agree];
    [NSLayoutConstraint activateConstraints:@[
        [agree.topAnchor constraintEqualToAnchor:self.btnPlay.bottomAnchor constant:13], //原来是18 但有了上边距5
        [agree.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [agree.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
    ]];
}
- (void)createEnAprotocolLink {
    CGFloat labelX = 20;
    CGFloat labelY = self.btnPlay.frame.size.height + self.btnPlay.frame.origin.y + 18;
    
    // 1. 创建 UILabel
    UILabel *agreementLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY, SCREEN_WIDTH - 2 * labelX, 0)];
    agreementLabel.numberOfLines = 0;
    agreementLabel.textAlignment = NSTextAlignmentCenter;
    agreementLabel.userInteractionEnabled = YES; // 一定要打开用户交互
    agreementLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    agreementLabel.textColor = [self colorWithHexString:@"#9DABC2" alpha:1];
    agreementLabel.hidden = YES;
    self.agreementLabel = agreementLabel;
    
    // 2. 创建富文本
    NSString *text = NSLocalizedString(@"Read and agree to the Membership Service Terms",@"");
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:text];
    // 3. 设置《会员服务协议》下划线和颜色
    NSRange linkRange = [text rangeOfString:NSLocalizedString(@"Membership Service Terms",@"")];
    [attrStr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:linkRange];
    [attrStr addAttribute:NSForegroundColorAttributeName value:[self colorWithHexString:@"#9DABC2" alpha:1] range:linkRange];
    agreementLabel.attributedText = attrStr;
    
    // 3️⃣ 关键：根据内容计算高度
    CGSize fitSize = [agreementLabel sizeThatFits:CGSizeMake(SCREEN_WIDTH - 2 * labelX, CGFLOAT_MAX)];
    CGRect frame = agreementLabel.frame;
    frame.size.height = fitSize.height;
    agreementLabel.frame = frame;
    
    // 4. 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(agreementTapped:)];
    [agreementLabel addGestureRecognizer:tap];
    [self addSubview:agreementLabel];
    
}*/

// 5. 点击事件
/*- (void)agreementTapped:(UITapGestureRecognizer *)tap {
    UILabel *label = (UILabel *)tap.view;
    NSString *text = label.text;
    NSRange linkRange = [text rangeOfString:NSLocalizedString(@"Membership Service Terms",@"")];
    
    // 获取点击位置
    CGPoint location = [tap locationInView:label];
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:label.attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:label.bounds.size];
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = label.numberOfLines;
    textContainer.lineBreakMode = label.lineBreakMode;
    [layoutManager addTextContainer:textContainer];
    
    NSUInteger index = [layoutManager characterIndexForPoint:location inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:nil];
    if (NSLocationInRange(index, linkRange)) {
        //NSLog(@"会员服务协议被点击了！");
        // 可以在这里 push 一个 WebView 或者跳转到协议页面
        HelpRulesViewController *rulesVC = [HelpRulesViewController new];
        rulesVC.title = NSLocalizedString(@"Membership Service Terms",@"");
        rulesVC.rule_type = @"member";
        [self.uvc.navigationController pushViewController:rulesVC animated:YES];
    }
}*/

//===================================
//============================================================
//===================================
/*
 /*[[YTIAPService shared] checkUnfinishedTransactionsWithUVC:self.uvc  completion:^(YTIAPSyncResult result) {
      if (result == YTIAPSyncResultUpdated) {
          // 🔄 刷新会员状态
          dispatch_async(dispatch_get_main_queue(), ^{
              BOOL success = YES;
              if (self.payCurrentVCResultCallback) {
                  self.payCurrentVCResultCallback(success);
              }
              if (self.payResultCallback) {
                  self.payResultCallback(success);
              }
          });
      }
  }];
 
//        [MemberRetentionView showViewTitle:@"" dataArray:@[] callBack:^(NSInteger index) {
//            if(index == 2001){
//                //[self craterOrderId:self.dicOrder];
//            }
//        }];
//
//        [UnlockedView showViewTitle:@"2" dataArray:@[] callBack:^(NSInteger index) {
//            [self.uvc.navigationController popViewControllerAnimated:YES];
//        }];
 
 */
