//
//  HanziCardViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HanziCardViewController : UIViewController
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@property (strong, nonatomic) NSString *category_id;
@end

NS_ASSUME_NONNULL_END
