//
//  PronunciationFirstView.h
//  YiTongProject
//
//  Created by ios01 on 2025/8/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PronunciationFirstView : UIView
+ (void)showViewTitle:(NSString *)title buttonFrame:(CGRect)frame2 callBack:(void(^)(NSInteger index))callBack;

@end

NS_ASSUME_NONNULL_END
