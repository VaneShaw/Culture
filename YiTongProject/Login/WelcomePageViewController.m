//
//  WelcomePageViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "WelcomePageViewController.h"

@interface WelcomePageViewController ()
@property (strong, nonatomic) UIButton *btnLoging;
@property (strong, nonatomic) UIButton *btnReturn;
@end

@implementation WelcomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (UIButton *)btnLoging {
    if(!_btnLoging){
        _btnLoging = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnLoging.frame = CGRectMake(25, 450, SCREEN_WIDTH - 50, 45);
        _btnLoging.layer.cornerRadius = 6;//圆角
        _btnLoging.layer.masksToBounds = YES;
        //_btnLoging.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        _btnLoging.backgroundColor = Login_Btn_COLOR;
        [_btnLoging setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnLoging addTarget:self action:@selector(btnLoginAction:) forControlEvents:UIControlEventTouchUpInside];
        
        //Base style for 圆角矩形 1 拷
    }
    return _btnLoging;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
