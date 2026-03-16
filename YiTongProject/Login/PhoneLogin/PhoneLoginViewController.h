//
//  PhoneLoginViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhoneLoginViewController : UIViewController
@property (assign, nonatomic) BOOL isCurrent;
@property (nonatomic, copy) void (^loginCompletion)(void);
//@property (nonatomic, copy) void (^loginCompletion)(void);
@end

NS_ASSUME_NONNULL_END
