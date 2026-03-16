//
//  CardBaseView.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/21.
//

#import "CardBaseView.h"

@implementation CardBaseView

- (instancetype)initWithTypeStyle:(TipsLayoutStyle)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _style = style;
        //[self setupViews];
    }
    return self;
}
//- (instancetype)initWithLayoutStyle:(TipsLayoutStyle)style {
//    self = [super initWithFrame:CGRectZero];
//    if (self) {
//        _layoutStyle = style;
//    }
//    return self;
//}
//- (instancetype)init {
    //return [self initWithStyle:TipsLayoutStyleListen];
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)btnflipCardActionNo {//如果是反面，切换的时候 转位正面
    
}
@end
