//
//  NicknameViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NicknameViewController : UIViewController
@property (nonatomic, copy) void (^selectedUserNickname)(NSString *nickname);
@end

NS_ASSUME_NONNULL_END
