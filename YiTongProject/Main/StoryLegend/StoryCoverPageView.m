//
//  StoryCoverPageView.m
//  YiTongProject
//
//  Created by ios01 on 2026/1/5.
//

#import "StoryCoverPageView.h"

@implementation StoryCoverPageView

- (instancetype)initWithFrame:(CGRect)frame
                         title:(NSString *)title
                     imageName:(NSString *)imageName {
    if (self = [super initWithFrame:frame]) {
        
        UIImageView *imageView =
        [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [self addSubview:imageView];
        [imageView sd_setImageWithURL:[NSURL URLWithString:imageName]];
        
        UILabel *label =  [[UILabel alloc] initWithFrame:CGRectMake(25, frame.size.height - 250,frame.size.width - 50, 80)];
        label.text = title;
        label.textColor = UIColor.greenColor;
        label.font = [UIFont boldSystemFontOfSize:35];
        [self addSubview:label];
    }
    return self;
}

@end
