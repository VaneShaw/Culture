//
//  UITableView+Empty.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/1.
//

#import "UITableView+Empty.h"
#import <objc/runtime.h>

static char kEmptyViewKey;
@implementation UITableView (Empty)
/*- (void)showEmptyViewWithMessage:(NSString *)message image:(UIImage *)image {
    UIView *emptyView = objc_getAssociatedObject(self, &kEmptyViewKey);
    if (!emptyView) {
        emptyView = [[UIView alloc] initWithFrame:self.bounds];
        emptyView.backgroundColor = [UIColor whiteColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"file_blue"]];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.frame = CGRectMake((SCREEN_WIDTH - 140)/2, SCREEN_HEIGHT/4, 140, 140);
        [emptyView addSubview:imageView];

        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(imageView.frame)+20, SCREEN_WIDTH-40, 30)];
        messageLabel.text = NSLocalizedString(@"暂无数据",@"");
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        messageLabel.textColor = [self colorWithHexString:@"#8F8F8F" alpha:1];
        [emptyView addSubview:messageLabel];
        
        objc_setAssociatedObject(self, &kEmptyViewKey, emptyView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self addSubview:emptyView];
}

- (void)hideEmptyView {
    UIView *emptyView = objc_getAssociatedObject(self, &kEmptyViewKey);
    if (emptyView) {
        [emptyView removeFromSuperview];
    }
}*/
- (void)checkEmptyWithDataCount:(NSInteger)count {
    if (count == 0) {
            [self showEmptyView];
        } else {
            [self hideEmptyView];
        }
}
- (void)showEmptyView {
    UIView *emptyView = objc_getAssociatedObject(self, &kEmptyViewKey);
    if (!emptyView) {
        emptyView = [[UIView alloc] initWithFrame:self.bounds];
        emptyView.backgroundColor = [UIColor whiteColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"file_blue"]];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.frame = CGRectMake((self.bounds.size.width - 140)/2,
                                     self.bounds.size.height/4,
                                     140,
                                     140);
        [emptyView addSubview:imageView];
        
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,
                                                                   CGRectGetMaxY(imageView.frame)+20,
                                                                   self.bounds.size.width-40,
                                                                   30)];
        messageLabel.text = NSLocalizedString(@"暂无数据",@"");
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        messageLabel.textColor = [self colorWithHexString:@"#8F8F8F" alpha:1];
        [emptyView addSubview:messageLabel];
        
        objc_setAssociatedObject(self, &kEmptyViewKey, emptyView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self addSubview:emptyView];
}

- (void)hideEmptyView {
    UIView *emptyView = objc_getAssociatedObject(self, &kEmptyViewKey);
    if (emptyView) {
        [emptyView removeFromSuperview];
    }
}

@end
