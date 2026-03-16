//
//  QuizResultViewController.h
//  YiTongProject
//
//  Created by Vincent on 2025/8/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QuizResultViewController : BaseViewController
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值

@property (nonatomic,assign) int score;
@end

NS_ASSUME_NONNULL_END
