//
//  InitialsViewController.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^InitialsControllerCompletionBlock)(NSString *data);

@interface InitialsViewController : BaseViewController
@property (strong, nonatomic) NSString *colorButton;
@property (strong, nonatomic) NSString *category_id;

@property (nonatomic, copy) InitialsControllerCompletionBlock completionBlock;
@end

NS_ASSUME_NONNULL_END
