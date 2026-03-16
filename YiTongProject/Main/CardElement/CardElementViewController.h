//
//  CardElementViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CardElementViewController : BaseViewController
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@property (strong, nonatomic) NSString *category_id;
@property (assign, nonatomic) BOOL isHanZi;
@end

NS_ASSUME_NONNULL_END
