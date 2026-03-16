//
//  HanziCardView.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/20.
//

#import "HanziCardView.h"
#import "HanziMessageView.h"

@interface HanziCardView ()
@property (nonatomic, strong) UILabel *lblTitle0;
@property (nonatomic, strong) UILabel *lblTitle1;
@property (nonatomic, strong) UILabel *lblContent;
@property (nonatomic, strong) UIButton *btnMore;
@property (nonatomic, strong) UILabel *lblSubtitle0;
@property (nonatomic, strong) UILabel *lblSubtitle1;
@property (nonatomic, strong) NSString *strContent;

@property (nonatomic, strong) UIImageView *pinyinView;
@property (nonatomic, strong) UIView *meaningView;
@property (assign, nonatomic) BOOL isFlipped;      // 是否处于背面
@property (nonatomic, strong) UIView *flipContainer;

@property (nonatomic, strong) NSLayoutConstraint *btnHeightConstraint;
@property (nonatomic, strong) NSDictionary *lastFormWords;

@end
@implementation HanziCardView

@synthesize lblCardTitle = _lblCardTitle;
@synthesize lblCardSubtitle = _lblCardSubtitle;
@synthesize btnPlay = _btnPlay;
@synthesize lblPinyin = _lblPinyin;
@synthesize btnNext = _btnNext;
@synthesize hanziView = _hanziView;

- (instancetype)initWithTypeStyle:(TipsLayoutStyle)style {
    if (self = [super initWithTypeStyle:style]) {
        
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;
        self.clipsToBounds = YES;

        CGFloat giWidth = 50 + 10 * IS_Formal_Screen;
        self.gifViewTemp = [[SDAnimatedImageView alloc] initWithFrame:CGRectMake((Card_WIDTH-giWidth)/2 - 4, 8 + 4 * IS_Formal_Screen, giWidth + 8, giWidth)];
        self.gifViewTemp.contentMode = UIViewContentModeScaleAspectFit;
        self.gifViewTemp.hidden = YES;
        [self addSubview:self.gifViewTemp];
        [self addSubview:self.pinyinView];
        [self addSubview:self.lblPinyin];
        int hanziWidth = 210 + 54 * IS_Formal_Screen;
        self.flipContainer = [[UIView alloc] init];
        self.flipContainer.frame = CGRectMake((Card_WIDTH-hanziWidth)/2, 47 + 9 * IS_Formal_Screen, hanziWidth, hanziWidth);
        self.flipContainer.backgroundColor = [UIColor whiteColor];

        hanziWidth = (IS_Formal_Screen ? (Card_WIDTH - 60) : 210 );
        self.flipContainer.frame = CGRectMake((Card_WIDTH - hanziWidth)/2, 47 + 9 * IS_Formal_Screen, hanziWidth, hanziWidth);

        [self addSubview:self.flipContainer];
        [self.flipContainer addSubview:self.hanziView];
        [self.flipContainer addSubview:self.meaningView];
 
        [self addSubview:self.lblCardSubtitle];
        [self addSubview:self.btnPlay];
        [self addSubview:self.btnNext];
        for (int i = 0; i < 2; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake((Card_WIDTH - 20 - 74 * 2)/2 +  94 * i, Card_Height - 50 - 6*IS_Formal_Screen, 74, 50);
            btn.layer.masksToBounds = YES;
            btn.tag = 135 + i;
            btn.hidden = YES;
            [self addSubview:btn];
        }
    }
    return self;
}
- (UIImageView *)pinyinView {
    if(!_pinyinView){
        CGFloat newWidth = 84.0 * (30.0 / 35.0);
        _pinyinView = [[UIImageView alloc]initWithFrame:CGRectMake((Card_WIDTH-newWidth)/2, 8, newWidth, 30 + 5 * IS_Formal_Screen)];
        _pinyinView.clipsToBounds = YES;
        _pinyinView.image = [UIImage imageNamed:@"pinyin_cell"];
        self.lblPinyin.frame = CGRectMake((Card_WIDTH-newWidth)/2, 8, newWidth, 30 + 5 * IS_Formal_Screen);
    }
     return _pinyinView;
 }
- (UIImageView *)hanziView {
    if(!_hanziView){
        int hanziWidth = self.flipContainer.frame.size.width;//210 + 54 * IS_Formal_Screen;
        _hanziView = [[UIImageView alloc]initWithFrame:CGRectMake(0,0, hanziWidth, hanziWidth)];//264
        _hanziView.clipsToBounds = YES;
        _hanziView.image = [UIImage imageNamed:@"tian_blue"];
        _hanziView.backgroundColor = [UIColor whiteColor];
        self.lblCardTitle.frame = CGRectMake(0,6, hanziWidth, hanziWidth);
        [_hanziView addSubview:self.lblCardTitle];
    }
     return _hanziView;
 }
- (void)layoutSubviews {
    [super layoutSubviews];
    int hanziWidth = 210 + 54 * IS_Formal_Screen;
    hanziWidth = self.flipContainer.frame.size.width;
    int y = 47 + 9 * IS_Formal_Screen;
    self.btnPlay.hidden = NO;
    self.pinyinView.hidden = NO;
    self.hanziView.hidden = NO;
    CGFloat fontSize = [self fontSizeForCharWidth:self.lblCardTitle.bounds.size.width];
    self.lblCardTitle.font = [UIFont fontWithName:FONT_NAME_Kaiti size:fontSize];
    self.lblCardTitle.textColor = [self colorWithHexString:@"#1F1F39" alpha:1];
    
    switch (self.style) {
        case TipsLayoutStyleListen: {
            // 布局方案 A
            self.lblCardSubtitle.hidden = YES;
            self.btnNext.hidden = NO;
            self.gifViewTemp.hidden = YES;
            self.btnPlay.hidden = NO;
            break;
        }
        case TipsLayoutStyleRead: {
            self.lblCardSubtitle.hidden = NO;
            self.btnNext.hidden = YES;
            self.gifViewTemp.hidden = YES;
            self.btnPlay.hidden = NO;
            break;
        }
        case TipsLayoutStyleWrite: {
            y = 66 + 18 * IS_Formal_Screen;
            //hanziWidth = 230 + 30 * IS_Formal_Screen;
            self.lblCardSubtitle.hidden = YES;
            self.btnNext.hidden = YES;
            self.gifViewTemp.hidden = NO;
            self.btnPlay.hidden = YES;
            self.pinyinView.hidden = YES;
            self.btnPlay.hidden = YES;
            //self.lblCardTitle.font = [UIFont fontWithName:FONT_NAME_Kaiti size:150 + 60 * IS_Formal_Screen];//按比例提交文字_字体大小
            self.lblCardTitle.font = [UIFont fontWithName:FONT_NAME_Kaiti size:fontSize];//168 + 42 * IS_Formal_Screen
            self.lblCardTitle.textColor = [self colorWithHexString:@"#E3E8F1" alpha:1];
            break;
        }
    }
    self.flipContainer.frame = CGRectMake((Card_WIDTH-hanziWidth)/2, y, hanziWidth, hanziWidth);
}
- (CGFloat)fontSizeForCharWidth:(CGFloat)side {

    CGFloat baseSide = 264.0;     // 基准宽高
    CGFloat baseFont = 210.0;     // 基准字号（264→210）

    CGFloat minSide  = 210.0;     // 最小宽度
    CGFloat minFont  = baseFont * (minSide / baseSide);   // ≈168
    CGFloat maxSide  = 305.0;     // 字号过渡上限
    CGFloat maxFont  = 240.0;     // 305 对应字号（可根据视觉调整）
    // ① 小于 264 → 按比例缩小
    if (side <= baseSide) {
        return baseFont * (side / baseSide);
    }

    // ② 264~305 → 平滑渐变，0~1 过渡
    if (side <= maxSide) {
        CGFloat t = (side - baseSide) / (maxSide - baseSide);
        return baseFont + (maxFont - baseFont) * t;
    }

    // ③ 大于 305 → 保持比例继续放大（你也可以改成 return maxFont）
    return maxFont * (side / maxSide);
}
//- (void)cardDidDisappear:(NSDictionary *)dic {
    
- (void)loadGIFWithURLString:(NSString *)urlString {
    NSString *encodedUrlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  
    NSURL *url = [NSURL URLWithString:encodedUrlString];
    if (!encodedUrlString || encodedUrlString.length == 0) {
        //NSLog(@"❌ GIF 加载失败: URL 为空");
        return;
    }
    if (!url) {
        //NSLog(@"❌ GIF 加载失败: URL 无效 -> [%@]------------", encodedUrlString);
        return;
    }
    [self.gifViewTemp sd_cancelCurrentImageLoad];
    //SDWebImage 自动处理：下载 + 解析 GIF + 内存/磁盘缓存 + 播放
    [self.gifViewTemp sd_setImageWithURL:url
                        placeholderImage:nil
                                 options:SDWebImageRetryFailed | SDWebImageLowPriority
                               completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error) {
            //NSLog(@"❌ GIF 加载失败:  [%@]------------", error);
            self.gifViewTemp.hidden = YES; // 下载失败可隐藏
        } else {
            self.gifViewTemp.hidden = NO; 
            //NSLog(@"✅ GIF 加载成功，缓存类型: [%ld ]------------", (long)cacheType);
        }
    }];
}
- (UIView *)meaningView {
    if(!_meaningView){
        _meaningView = [[UIView alloc]init];
        int hanziWidth = self.flipContainer.frame.size.width; //210 + 54 * IS_Formal_Screen;
        _meaningView = [[UIView alloc]initWithFrame:CGRectMake(0,0, hanziWidth, hanziWidth)];//264
        _meaningView.layer.cornerRadius = 12;
        _meaningView.layer.masksToBounds = YES;
        _meaningView.clipsToBounds = YES;
        _meaningView.hidden = YES;
        _meaningView.backgroundColor = [UIColor whiteColor];
        _meaningView.layer.borderWidth = 1;//边框
        _meaningView.layer.borderColor = [self colorWithHexString:@"#C2CCFF" alpha:1].CGColor;
        
        // ======= 第一个小标题 =======
        for (int i = 0; i < 2; i++) {
            UILabel *lblTitle = [[UILabel alloc] init];
            //lblTitle.text = @[@"Interpretation",@"Form Words"][i]; // 示例
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Medium size:14];
            lblTitle.backgroundColor = [self colorWithHexString:@"#E6F0FF" alpha:1];
            lblTitle.textColor = [self colorWithHexString:@"#879AFF" alpha:1];
            lblTitle.layer.cornerRadius = 4;
            lblTitle.layer.masksToBounds = YES;
            lblTitle.tag = 100 + i;
           [_meaningView addSubview:lblTitle];
        }
        self.lblTitle0 = (UILabel *)[_meaningView viewWithTag:100];
        self.lblTitle1 = (UILabel *)[_meaningView viewWithTag:101];
        // ======= 第一个内容 =======
        UILabel *lblContent = [[UILabel alloc] init];
        lblContent.translatesAutoresizingMaskIntoConstraints = NO;
        lblContent.numberOfLines = 0;
        lblContent.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        lblContent.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        [_meaningView addSubview:lblContent];
        self.lblContent = lblContent;
        
        // “更多”按钮
        UIButton *btnMore = [UIButton buttonWithType:UIButtonTypeSystem];
        btnMore.translatesAutoresizingMaskIntoConstraints = NO;
        btnMore.clipsToBounds = YES;
        btnMore.hidden = YES; // 初始隐藏
        [btnMore addTarget:self action:@selector(btnMoreAction:) forControlEvents:UIControlEventTouchUpInside];
        [_meaningView addSubview:btnMore];
        self.btnMore = btnMore;
        UIImage *img = [UIImage imageNamed:@"down_more"];
        UIImageView *imgMore = [[UIImageView alloc]initWithFrame:CGRectMake(42-img.size.width-10, 6, img.size.width, img.size.height)];
        imgMore.image = img;
        [self.btnMore addSubview:imgMore];

        // ===== 内容2 =====
        int temp = 230;
        int fontsize1 = 12 + 2 * IS_Formal_Screen;//
        for (int i = 0; i < 2; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            btn.translatesAutoresizingMaskIntoConstraints = NO;
            btn.clipsToBounds = YES;
            btn.tag = temp + i;
            [_meaningView addSubview:btn];

            UILabel *lblSubtitle = [[UILabel alloc] init];
            lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:fontsize1];
            lblSubtitle.textColor = [self colorWithHexString:@"#1F1F39" alpha:1];
            lblSubtitle.tag = 300 + i;
            lblSubtitle.numberOfLines = 2;
            [btn addSubview:lblSubtitle];
        }
        
        self.lblSubtitle0 = (UILabel *)[self.meaningView viewWithTag:300];
        self.lblSubtitle1 = (UILabel *)[self.meaningView viewWithTag:301];
        // ===== 开启约束 =====
        self.lblTitle0.translatesAutoresizingMaskIntoConstraints = NO;
        self.lblContent.translatesAutoresizingMaskIntoConstraints = NO;
        self.lblTitle1.translatesAutoresizingMaskIntoConstraints = NO;
        self.lblSubtitle0.translatesAutoresizingMaskIntoConstraints = NO;
        self.lblSubtitle1.translatesAutoresizingMaskIntoConstraints = NO;

        self.lblTitle0.numberOfLines = 1; // 单行，宽度自适应
        [self.lblTitle0 setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.lblTitle0 setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        //CGFloat maxHeight = 75 + 40 * IS_Formal_Screen;//72 + 36 * IS_Formal_Screen;

   }
    return _meaningView;
}
- (void)setMeaningViewLayout:(CGFloat )maxHeight {
    //CGFloat maxHeight1 = 55 + 60 * IS_Formal_Screen;
    [NSLayoutConstraint activateConstraints:@[
        [self.lblTitle0.topAnchor constraintEqualToAnchor:self.meaningView.topAnchor constant:10 + 2 * IS_Formal_Screen],
        [self.lblTitle0.leadingAnchor constraintEqualToAnchor:self.meaningView.leadingAnchor constant:14],
//---------------------------
        // 内容1（多行自适应）
         [self.lblContent.topAnchor constraintEqualToAnchor:self.lblTitle0.bottomAnchor constant:6 + 2 * IS_Formal_Screen],
         [self.lblContent.leadingAnchor constraintEqualToAnchor:self.meaningView.leadingAnchor constant:14],
         [self.lblContent.trailingAnchor constraintEqualToAnchor:self.meaningView.trailingAnchor constant:-10],
         [self.lblContent.heightAnchor constraintLessThanOrEqualToConstant:maxHeight],
     
          // ✅ 不设固定高度
         // 限制最大高度
         // ===== “更多”按钮约束在右下角 =====
         [self.btnMore.trailingAnchor constraintEqualToAnchor:self.meaningView.trailingAnchor constant:-2],
         [self.btnMore.bottomAnchor constraintEqualToAnchor:self.lblContent.bottomAnchor constant:7],  //-10
         [self.btnMore.widthAnchor constraintEqualToConstant:42],
         [self.btnMore.heightAnchor constraintEqualToConstant:30],
//---------------------------
        // 标题2（紧接内容1下方）
        [self.lblTitle1.topAnchor constraintEqualToAnchor:self.lblContent.bottomAnchor constant:15-2 + 5 * IS_Formal_Screen],
        [self.lblTitle1.leadingAnchor constraintEqualToAnchor:self.lblTitle0.leadingAnchor],
//---------------------------
    ]];
}
- (void)btnMoreAction:(UIButton *)sender {
    [HanziMessageView showViewTitle:self.strContent buttonArrayTitle:@[] callBack:^(NSInteger index) {
    }];
}
- (void)updateMeaningViewWithText:(NSDictionary *)formWords {
    
    self.strContent = [NSString stringWithFormat:@"%@",formWords[@"interpret"]];
    NSArray *dataArray = [NSArray arrayWithArray:formWords[@"form_words"]];
    
    // 方法开头：
    if ([self.lastFormWords isEqualToDictionary:formWords]) {
        return; // 数据相同，不重复执行
    }
    self.lastFormWords = formWords;
   
    int temp = 0;
    for (int i = 0; i< dataArray.count; i++) {
        UILabel *lblTitle = (UILabel *)[self.meaningView viewWithTag:100 + i];
        NSString *title = @[@"Interpretation",@"Form Words"][i];
        lblTitle.text = [NSString stringWithFormat:@" %@ ",NSLocalizedString(title,@"")];

        NSString *hanzi = [NSString stringWithFormat:@"%@",dataArray[i][@"hanzi"]];
        NSString *pinyin = [NSString stringWithFormat:@"%@",dataArray[i][@"pinyin"]];
        NSString *english = [NSString stringWithFormat:@"%@",dataArray[i][@"phrase"]];
        
        UILabel *lblSubtitle = (UILabel *)[self.meaningView viewWithTag:300 + i];
        lblSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        NSString *str1 = hanzi;
        NSString *str2 = [NSString stringWithFormat:@"%@ %@",pinyin,english];
        NSString *content = [NSString stringWithFormat:@"%@ %@",str1,str2];
        int fontsize1 = 12 + 3 * IS_Formal_Screen;//x
        NSMutableAttributedString *noteStr = [[NSMutableAttributedString alloc] initWithString:content];
        [noteStr addAttribute:NSForegroundColorAttributeName value:BLACK_COLOR_1F range:NSMakeRange(0,str1.length)];
        [noteStr  addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontsize1]  range:NSMakeRange(0,str1.length)];
        lblSubtitle.attributedText = noteStr;
        
        // 1. 限制宽度（label 的宽度）
        CGFloat maxWidth = self.meaningView.frame.size.width - 44;
        CGSize labelSize = [lblSubtitle sizeThatFits:CGSizeMake(maxWidth,MAXFLOAT)];
        
        // 判断是否超过一行
        int needTwoLines = labelSize.height > 20 ? 1 : 0;
        temp = needTwoLines + temp;
        UIButton *btn = [self.meaningView viewWithTag:230 + i];
        lblSubtitle.numberOfLines = 0;
        if(needTwoLines == 1){
            NSString *str1 = hanzi;
            //NSString *str2 = [NSString stringWithFormat:@"%@\n%@",pinyin,english];
            //NSString *content = [NSString stringWithFormat:@"%@ %@",str1,str2];
            NSString *content = [NSString stringWithFormat:@"%@ %@\n          %@",str1,pinyin,english];
            int fontsize1 = 12 + 3 * IS_Formal_Screen;//x
            NSMutableAttributedString *noteStr = [[NSMutableAttributedString alloc] initWithString:content];
            [noteStr addAttribute:NSForegroundColorAttributeName value:BLACK_COLOR_1F range:NSMakeRange(0,str1.length)];
            [noteStr  addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontsize1]  range:NSMakeRange(0,str1.length)];
            lblSubtitle.attributedText = noteStr;
        }
        //汉字  英文
        //     德语
        //=====================================================================
        UIImage *img1 = [UIImage imageNamed:@"trumpet_black"];
        UIImageView *imgTrumpet = [[UIImageView alloc] init];
        imgTrumpet.translatesAutoresizingMaskIntoConstraints = NO;
        imgTrumpet.image = img1;
        [btn addSubview:imgTrumpet];

        //int needTwoLines = 1;
        UIButton *previousBtn = (UIButton *)[self.meaningView viewWithTag:230];
        NSLayoutYAxisAnchor *topAnchor = (i == 0)
            ? self.lblTitle1.bottomAnchor
            : previousBtn.bottomAnchor;
        
        CGFloat topConstant = (i == 0) ? 10 : 1;
        if(i==1 &&  needTwoLines==0){
            topConstant = 5;
        }
        
        [NSLayoutConstraint activateConstraints:@[
            [btn.leadingAnchor constraintEqualToAnchor:_meaningView.leadingAnchor constant:10],
            [btn.trailingAnchor constraintEqualToAnchor:_meaningView.trailingAnchor constant:-10],
            [btn.heightAnchor constraintEqualToConstant:(fontsize1 + 2 + 12 + needTwoLines * 20)],
            [btn.topAnchor constraintEqualToAnchor:topAnchor constant:topConstant],
        ]];
        
        // 子 label 填满按钮
        [NSLayoutConstraint activateConstraints:@[
            [lblSubtitle.leadingAnchor constraintEqualToAnchor:btn.leadingAnchor constant:4],
            [lblSubtitle.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor constant:-20],
            [lblSubtitle.topAnchor constraintEqualToAnchor:btn.topAnchor],
            [lblSubtitle.bottomAnchor constraintEqualToAnchor:btn.bottomAnchor],
        ]];
        
        [NSLayoutConstraint activateConstraints:@[
            [imgTrumpet.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor constant:(-2)],       // 右边距 2
            (needTwoLines == 0
                  ? [imgTrumpet.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor]
                  : [imgTrumpet.topAnchor constraintEqualToAnchor:btn.topAnchor constant:6]),                    // 垂直居中
            [imgTrumpet.widthAnchor constraintEqualToConstant:img1.size.width],                        // 固定宽
            [imgTrumpet.heightAnchor constraintEqualToConstant:img1.size.height]                       // 固定高
        ]];
        //=====================================================================
    }

    CGFloat maxHeight = 75-temp*10 + (40 + temp*10) * IS_Formal_Screen;
    [self setMeaningViewLayout:maxHeight];

    //maxHeight = 55 + 60 * IS_Formal_Screen;
    //CGFloat btnWidth = 40;
    // 计算文本完整高度
    CGFloat maxWidth = self.meaningView.frame.size.width - 14 - 10;
    CGSize fullSize = [self.strContent boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName: self.lblContent.font}
                                         context:nil].size;
    if (fullSize.height <= maxHeight) {
        // 文本较短：直接显示，无按钮
        self.lblContent.text = self.strContent;
        self.btnMore.hidden = YES;
      
    } else {
     
        //文本较长：截断 + 显示按钮
        NSInteger reservedTail = 10; // 末尾预留字符数
        NSString *finalText = [self truncateText:self.strContent
                                        forLabel:self.lblContent
                                       maxWidth:maxWidth
                                      maxHeight:maxHeight
                                   reservedTail:reservedTail];
        self.lblContent.text = finalText;
        self.btnMore.hidden = NO;
    }

    // ⚠️ 关键：强制更新布局（Auto Layout 环境）
    [self.meaningView layoutIfNeeded];
}

- (NSString *)truncateText:(NSString *)text
                  forLabel:(UILabel *)label
                 maxWidth:(CGFloat)maxWidth
                maxHeight:(CGFloat)maxHeight
              reservedTail:(NSInteger)reservedCount {

    // 1. 初始化文本系统
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:text
                                                            attributes:@{NSFontAttributeName: label.font}];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = 0;
    textContainer.lineBreakMode = NSLineBreakByWordWrapping;

    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];

    // 2. 强制布局
    [layoutManager glyphRangeForTextContainer:textContainer];
    NSMutableArray<NSDictionary *> *lines = [NSMutableArray array];
    // 3. 获取每一行的rect与范围
    [layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, layoutManager.numberOfGlyphs)
                                            usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer * _Nullable container, NSRange glyphRange, BOOL * _Nonnull stop) {
        [lines addObject:@{@"rect": [NSValue valueWithCGRect:usedRect],
                           @"range": [NSValue valueWithRange:glyphRange]}];
    }];

    if (lines.count == 0) return text;

    // 4. 找出在maxHeight内能放下的最后一行
    CGFloat totalHeight = 0;
    NSInteger visibleLineCount = 0;
    for (NSDictionary *lineInfo in lines) {
        CGRect usedRect = [lineInfo[@"rect"] CGRectValue];
        totalHeight += usedRect.size.height;
        if (totalHeight > maxHeight) break;
        visibleLineCount++;
    }

    // 如果所有行都能放下
    if (visibleLineCount >= lines.count) {
        return text;
    }

    // 5. 截取到最后能显示的那一行
    NSRange lastVisibleGlyphRange = [[lines[visibleLineCount - 1] objectForKey:@"range"] rangeValue];
    NSRange visibleGlyphRange = NSMakeRange(0, NSMaxRange(lastVisibleGlyphRange));
    NSRange visibleCharRange = [layoutManager characterRangeForGlyphRange:visibleGlyphRange actualGlyphRange:nil];

    // 6. 预留尾部字符空间 + “...”
    NSInteger truncateIndex = MAX((NSInteger)(visibleCharRange.length - reservedCount), 0);
    NSString *visibleText = [text substringToIndex:truncateIndex];
    return [visibleText stringByAppendingString:@"..."];
}
- (UILabel *)lblCardTitle {
    if(!_lblCardTitle){
        _lblCardTitle = [[UILabel alloc]init];
        _lblCardTitle.textAlignment = NSTextAlignmentCenter;
    }
    return _lblCardTitle;
}
- (UILabel *)lblCardSubtitle {
    if(!_lblCardSubtitle){
        _lblCardSubtitle = [[UILabel alloc]init];
        int y = Card_Height - 98 - 14 * IS_Formal_Screen;
        _lblCardSubtitle.frame = CGRectMake(15, y, Card_WIDTH-30, 20 + 25);
        _lblCardSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _lblCardSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        _lblCardSubtitle.numberOfLines = 0;
        _lblCardSubtitle.textAlignment = NSTextAlignmentCenter;
        _lblCardSubtitle.text = NSLocalizedString(@"Tap to start recording and say this sound out loud",@"");
    }
    return _lblCardSubtitle;
}
//=================================================================
- (UIPlayButton *)btnPlay {
    if(!_btnPlay){
        NSString *currentKey = [ColorManager currentColorKey];
        NSString *xbutton = [NSString stringWithFormat:@"button_bg_%@",currentKey];
        UIImage *bg = [UIImage imageNamed:xbutton];//@"button_white"
        UIImage *normal = [UIImage imageNamed:[NSString stringWithFormat:@"started_%@",currentKey]];
        UIImage *playing = [UIImage imageNamed:[NSString stringWithFormat:@"sound_wave_%@",currentKey]];
        _btnPlay = [[UIPlayButton alloc] initWithFrame:CGRectMake((Card_WIDTH - 74)/2, Card_Height - 50 - 6*IS_Formal_Screen, 74, 50)  backgroundImage:bg  normalImage:normal playingImage:playing];
        // 调整动画速度（越大越慢）
        _btnPlay.animationDuration = 0.4;
    }
    return _btnPlay;
}
- (UILabel *)lblPinyin {
    if(!_lblPinyin){
        _lblPinyin = [[UILabel alloc]init];
        _lblPinyin.frame = self.pinyinView.bounds;
        _lblPinyin.font = [UIFont fontWithName:FONT_NAME_Regular size:20 + 5 * IS_Formal_Screen];
        _lblPinyin.textColor = [self colorWithHexString:@"#1F1F39" alpha:1];
        _lblPinyin.textAlignment = NSTextAlignmentCenter;
    }
    return _lblPinyin;
}
- (UIButton *)btnNext {
    if(!_btnNext){
        _btnNext= [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnNext.frame = CGRectMake((Card_WIDTH-185)/2, self.flipContainer.frame.origin.y + self.flipContainer.frame.size.height + 12, 185, 20); //106
        _btnNext.titleEdgeInsets = UIEdgeInsetsMake(0,-20, 0, 0);
        _btnNext.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        [_btnNext setTintColor:[self colorWithHexString:@"#879AFF" alpha:1]];//标题图片button
        [_btnNext setTitle:NSLocalizedString(@"View Meaning & Usage",@"") forState:UIControlStateNormal];
      
        UIImage *arrowImage = [UIImage imageNamed:@"next_blue"];
        [_btnNext setImage:arrowImage forState:UIControlStateNormal];
        _btnNext.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _btnNext.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _btnNext.titleEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
        _btnNext.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -2);
        _btnNext.adjustsImageWhenHighlighted = NO;
        [_btnNext addTarget:self action:@selector(btnflipCardAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnNext;
}
#pragma mark - 翻转动画
- (void)btnflipCardActionNo {//如果是反面，切换的时候 转位正面
    if(self.isFlipped){
        [self btnflipCardAction];
    }
}
- (void)btnflipCardAction {
    self.userInteractionEnabled = NO;
    BOOL willBeFlipped = self.isFlipped;
    UIView *fromView = willBeFlipped ? self.meaningView : self.hanziView;
    UIView *toView = willBeFlipped ? self.hanziView : self.meaningView;
    
    NSString *str1 = NSLocalizedString(@"View Meaning & Usage",@"");
    NSString *str2 = NSLocalizedString(@"Back to Character",@"");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *title = @[str1, str2][!willBeFlipped];
        NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:title
                                                                        attributes:@{NSFontAttributeName:self.btnNext.titleLabel.font,
                                                                                     NSForegroundColorAttributeName:self.btnNext.titleLabel.textColor}];
        [UIView performWithoutAnimation:^{
            [self.btnNext setAttributedTitle:attrTitle forState:UIControlStateNormal];
            [self.btnNext layoutIfNeeded]; // 强制立即刷新布局
        }];
    });
    

 
    // 确保两个面背景不透明
    self.flipContainer.backgroundColor = [UIColor whiteColor];
    self.hanziView.backgroundColor = [UIColor whiteColor];
    self.meaningView.backgroundColor = [UIColor whiteColor];
    // 设置初始状态
    toView.hidden = NO;
    toView.layer.transform = CATransform3DMakeRotation(M_PI_2, 0, 1, 0); // 先转90度隐藏
    // 添加透视
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1.0 / 800.0;
    self.flipContainer.layer.sublayerTransform = perspective;

    [UIView animateKeyframesWithDuration:0.6 delay:0 options:0 animations:^{
        // 前半段：翻转 fromView 90°
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            fromView.layer.transform = CATransform3DMakeRotation(-M_PI_2, 0, 1, 0);
        }];
        // 后半段：翻转 toView 回到正面
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            toView.layer.transform = CATransform3DIdentity;
        }];
    } completion:^(BOOL finished) {
        // 动画结束，隐藏旧面
        fromView.hidden = YES;
        self.userInteractionEnabled = YES;
        fromView.layer.transform = CATransform3DIdentity;
        self.isFlipped = !self.isFlipped;
        

    }];
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
