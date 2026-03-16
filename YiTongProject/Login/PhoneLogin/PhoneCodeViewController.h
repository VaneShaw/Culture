//
//  PhoneCodeViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhoneCodeViewController : UIViewController
@property (nonatomic, copy) void (^loginCompletion)(void);

@property (strong, nonatomic) NSString *phone;
@property (assign, nonatomic) BOOL isCurrent;
@end

NS_ASSUME_NONNULL_END
