//
//  YTAvatarPickerManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^YTAvatarPickCompletion)(UIImage * _Nullable avatar, BOOL success);

@interface YTAvatarPickerManager : NSObject

+ (instancetype)shared;

/// 从指定 VC 打开头像选择
- (void)pickAvatarFrom:(UIViewController *)vc
            completion:(YTAvatarPickCompletion)completion;
@end

NS_ASSUME_NONNULL_END
/*
 - (void)checkPhotoPermissionXXX {
     PHAuthorizationStatus status = PHPhotoLibrary.authorizationStatus;
     if (status == PHAuthorizationStatusAuthorized ||
         status == PHAuthorizationStatusLimited) {
         [self openPicker];
         return;
     }

     if (status == PHAuthorizationStatusDenied ||
         status == PHAuthorizationStatusRestricted) {
         [self showSettingAlert];
         return;
     }

     [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (status == PHAuthorizationStatusAuthorized ||
                 status == PHAuthorizationStatusLimited) {
                 [self openPicker];
             } else {
                 [self showSettingAlert];
             }
         });
     }];
 }
 */
