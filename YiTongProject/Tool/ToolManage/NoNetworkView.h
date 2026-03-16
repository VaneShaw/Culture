//
//  NoNetworkView.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NoNetworkView : UIView
@property (strong, nonatomic) UIButton *settingsBtn;
@property (nonatomic, copy) void (^refreshHandler)(void);

@end

NS_ASSUME_NONNULL_END
