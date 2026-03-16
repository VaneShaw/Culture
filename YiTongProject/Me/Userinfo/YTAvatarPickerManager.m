//
//  YTAvatarPickerManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/18.
//

#import "YTAvatarPickerManager.h"
#import <Photos/Photos.h>

@interface YTAvatarPickerManager ()
<
UIImagePickerControllerDelegate,
UINavigationControllerDelegate
>

@property (nonatomic, weak) UIViewController *presentVC;
@property (nonatomic, copy) YTAvatarPickCompletion completion;

@end

@implementation YTAvatarPickerManager

+ (instancetype)shared {
    static YTAvatarPickerManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YTAvatarPickerManager alloc] init];
    });
    return manager;
}

#pragma mark - Public

- (void)pickAvatarFrom:(UIViewController *)vc
            completion:(YTAvatarPickCompletion)completion {

    self.presentVC = vc;
    self.completion = completion;
    [self checkPhotoPermission];
}

#pragma mark - Permission
- (void)checkPhotoPermission {

    PHAuthorizationStatus status = PHPhotoLibrary.authorizationStatus;
    BOOL authorized = (status == PHAuthorizationStatusAuthorized);
    if (@available(iOS 14, *)) {
        authorized = authorized || (status == PHAuthorizationStatusLimited);
    }

    if (authorized) {
        [self openPicker];
        return;
    }

    if (status == PHAuthorizationStatusDenied ||
        status == PHAuthorizationStatusRestricted) {
        [self showSettingAlert];
        return;
    }

    // 未决定（NotDetermined）
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{

            BOOL granted = (status == PHAuthorizationStatusAuthorized);
            if (@available(iOS 14, *)) {
                granted = granted || (status == PHAuthorizationStatusLimited);
            }

            if (granted) {
                [self openPicker];
            } else {
                [self showSettingAlert];
            }
        });
    }];
}


#pragma mark - Picker

- (void)openPicker {

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES; // 系统裁剪
    picker.delegate = self;

    [self.presentVC presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePicker Delegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {

    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }

    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            self.completion(image, image != nil);
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            self.completion(nil, NO);
        }
    }];
}

#pragma mark - Alert

- (void)showSettingAlert {

    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"相册权限未开启"
                                        message:@"请在系统设置中允许访问相册"
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
        if (self.completion) self.completion(nil, NO);
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"去设置"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }]];

    [self.presentVC presentViewController:alert animated:YES completion:nil];
}

@end
