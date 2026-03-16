//
//  LoginViewController.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <UIKit/UIKit.h>
#import "LoginFirstView.h"
NS_ASSUME_NONNULL_BEGIN

@interface LoginViewController : UIViewController
@property (nonatomic, copy) void (^loginCompletion)(void);
@property (assign, nonatomic) BOOL isCurrent;
@end

NS_ASSUME_NONNULL_END
