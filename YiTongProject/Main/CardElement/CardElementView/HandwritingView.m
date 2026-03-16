//
//  HandwritingView.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "HandwritingView.h"
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>

@implementation HandwritingView
//手写笔画
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
     [self setupView];
    }
    return self;
}
- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    self.strokesArray = [NSMutableArray array];
    self.currentStrokePoints = [NSMutableArray array];
    self.currentCharacter = @"";
    self.writingType = 0;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
   // 开始新笔画时重置时间基准
    if (self.strokesArray.count == 0 && self.currentStrokePoints.count == 0) {
        self.firstTimestamp = CACurrentMediaTime() * 1000; // 毫秒
    }
    [self.currentStrokePoints removeAllObjects];
    [self addTouchPoint:touches];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //[super touchesMoved:touches withEvent:event];//新增3
    [self addTouchPoint:touches];
    [self setNeedsDisplay];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    UIScrollView *scrollView = [self parentScrollView];
    if (scrollView) {
        scrollView.scrollEnabled = YES;
    }
    // 手写结束后，恢复滚动
    //[self setScrollEnabledForParent:YES];//新增3
    
    [self addTouchPoint:touches];
    
    if (self.currentStrokePoints.count > 0) {
        // 完成当前笔画，添加到笔画数组
        NSDictionary *stroke = @{
            @"order": @(self.strokesArray.count + 1),
            @"points": [self.currentStrokePoints copy]
        };
        [self.strokesArray addObject:stroke];
        [self.currentStrokePoints removeAllObjects];
    }
    if (self.selectedTypeIndex) {
        self.selectedTypeIndex(self.strokesArray.count);
    }
    [self setNeedsDisplay];
}

- (void)addTouchPoint:(NSSet<UITouch *> *)touches {
    if (touches.count == 0) return;
    UITouch *touch = [touches anyObject];
    if (!touch) return;
    CGPoint point = [touch locationInView:self];
    
    // 计算相对于第一个点的时间差（毫秒）
    CFTimeInterval currentTime = CACurrentMediaTime() * 1000;
    CFTimeInterval relativeTime = currentTime - self.firstTimestamp;
    
    NSDictionary *pointDict = @{
        @"x": @(point.x),
        @"y": @(point.y),
        @"t": @((NSInteger)relativeTime) // 相对时间戳
    };
    [self.currentStrokePoints addObject:pointDict];
}
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    [[UIColor blackColor] setStroke];
    //320/296
    CGFloat temp =  (CGFloat)(SCREEN_WIDTH-94)/(CGFloat)296;
    //NSLog(@"-------temp[%lf]---[%d]----------",temp,(SCREEN_WIDTH-94));
    temp = 1.0;//宽高等比例·1
    // 绘制所有已完成的笔画
    for (NSDictionary *stroke in self.strokesArray) {
        NSArray *points = stroke[@"points"];
        if (points.count < 2) continue;

        UIBezierPath *path = [UIBezierPath bezierPath];
        path.lineWidth = (2.0 + 3.0 + 6.0) * temp;//笔画粗细
        path.lineCapStyle = kCGLineCapRound;
        path.lineJoinStyle = kCGLineJoinRound;
        
        for (int i = 0; i < points.count; i++) {
            NSDictionary *pointDict = points[i];
            CGPoint point = CGPointMake([pointDict[@"x"] floatValue] *temp, [pointDict[@"y"] floatValue]*temp);
            if (i == 0) {
                [path moveToPoint:point];
            } else {
                [path addLineToPoint:point];
            }
        }
        [path stroke];
    }
    
    // 绘制当前未完成的笔画
    if (self.currentStrokePoints.count >= 2) {
        UIBezierPath *currentPath = [UIBezierPath bezierPath];
        currentPath.lineWidth = (2.0 + 3.0 + 6.0) * temp;//笔画粗细
        currentPath.lineCapStyle = kCGLineCapRound;
        currentPath.lineJoinStyle = kCGLineJoinRound;
        
        for (int i = 0; i < self.currentStrokePoints.count; i++) {
            NSDictionary *pointDict = self.currentStrokePoints[i];
            CGPoint point = CGPointMake([pointDict[@"x"] floatValue]*temp, [pointDict[@"y"] floatValue]*temp);
            if (i == 0) {
                [currentPath moveToPoint:point];
            } else {
                [currentPath addLineToPoint:point];
            }
        }
        [currentPath stroke];
    }
}
- (void)clearDrawing {
    [self.strokesArray removeAllObjects];
    [self.currentStrokePoints removeAllObjects];
    
    self.firstTimestamp = 0;
    [self setNeedsDisplay];
}
- (void)clearDrawing212 {
    //[self.strokesArray removeAllObjects];
    //[self.currentStrokePoints removeAllObjects];
    
    if (self.strokesArray.count > 0) {
        [self.strokesArray removeObjectAtIndex:(self.strokesArray.count-1)];
    }
    if (self.currentStrokePoints.count > 0) {
        [self.currentStrokePoints removeObjectAtIndex:(self.currentStrokePoints.count-1)];
    }
    self.firstTimestamp = 0;
    [self setNeedsDisplay];
}
- (NSDictionary *)getWritingData {
    // 如果有未完成的当前笔画，也添加到结果中
    if (self.currentStrokePoints.count > 0) {
        NSDictionary *currentStroke = @{
            @"order": @(self.strokesArray.count + 1),
            @"points": [self.currentStrokePoints copy]
        };
        [self.strokesArray addObject:currentStroke];
        [self.currentStrokePoints removeAllObjects];
    }
   /*
    return @{
        @"character": self.currentCharacter ?: @"",
        @"strokes": [self.strokesArray copy],
        @"type": [self typeStringForType:self.writingType]
    };*/
    return @{
        @"character": @"b",
        @"pinyin_id": @"7",
        @"is_rework": @"0",
        @"strokes": [self.strokesArray copy],
        @"type": @"1",
    };
    //return @{
        //@"strokes": [self.strokesArray copy]
     //};
}
- (void)setContinuousWritingEnabled:(BOOL)enabled {
    // 在这个实现中总是启用连续笔画
}
- (NSString *)typeStringForType:(NSInteger)type {
    //NSArray *types = @[@"letter", @"shengmu", @"yunmu", @"whole_syllable", @"intonation"];
    //return types[type];
    return @"";
}
/*
- (void)loadCharacterFromImage:(UIImage *)image completion:(void (^)(NSString *character, CGRect bounds))completion {
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    
    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        if (error) {
            NSLog(@"文字识别错误: %@", error.localizedDescription);
            completion(nil, CGRectZero);
            return;
        }
        
        NSArray<VNRecognizedTextObservation *> *observations = request.results;
        if (observations.count == 0) {
            completion(nil, CGRectZero);
            return;
        }
        VNRecognizedTextObservation *firstObservation = observations.firstObject;
        NSString *recognizedText = @"";
        
        // iOS 13+ 的现代API
        if (@available(iOS 13.0, *)) {
            //recognizedText = firstObservation.topCandidates.firstObject.string ?: @"";
        }
        // iOS 11-12 无法直接获取识别文本，只能获取位置
        else {
            NSLog(@"iOS 12及以下版本需要额外处理才能获取识别文本");
            // 只能获取文字区域但无法直接获取识别内容
            recognizedText = self.currentCharacter ?: @"";
        }
        NSString *character = recognizedText.length > 0 ? [recognizedText substringToIndex:1] : @"";
        // 坐标转换（所有版本通用）
        CGRect boundingBox = firstObservation.boundingBox;
        CGRect viewBounds = self.bounds;
        CGRect letterRect = CGRectMake(boundingBox.origin.x * viewBounds.size.width,
                                     (1 - boundingBox.origin.y - boundingBox.size.height) * viewBounds.size.height,
                                     boundingBox.size.width * viewBounds.size.width,
                                     boundingBox.size.height * viewBounds.size.height);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(character, letterRect);
        });
    }];
    
    // 设置识别参数（所有版本通用）
    if (@available(iOS 13.0, *)) {
        request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
        request.usesLanguageCorrection = NO;
    }
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:ciImage options:@{}];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error;
        [handler performRequests:@[request] error:&error];
        if (error) {
            NSLog(@"执行识别请求失败: %@", error.localizedDescription);
            completion(nil, CGRectZero);
        }
    });
}*/
#pragma mark - 保存和加载
//重写数据ing
- (void)loadWritingData:(NSArray *)strokesArray {
    [self clearDrawing];
    //NSArray *strokesArray = writingData[@"strokes"];
    if (![strokesArray isKindOfClass:[NSArray class]]) return;
    for (NSDictionary *stroke in strokesArray) {
        if ([stroke isKindOfClass:[NSDictionary class]]) {
            [self.strokesArray addObject:[stroke copy]];
        }
    }
    if (self.selectedTypeIndex) {
        self.selectedTypeIndex(self.strokesArray.count);
    }
    [self setNeedsDisplay];
}
- (void)saveToUserDefaults {
    NSDictionary *writingData = [self getWritingData];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:writingData];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"HandwritingData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
+ (NSDictionary *)loadFromUserDefaults {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"HandwritingData"];
    if (!data) return nil;
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (UIScrollView *)parentScrollView {
    UIView *v = self.superview;
    while (v) {
        if ([v isKindOfClass:[UIScrollView class]]) return (UIScrollView *)v;
        v = v.superview;
    }
    return nil;
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];

    // 如果触摸点在本视图内部，则禁用父 scrollView 滚动
    if (hitView == self) {
        UIScrollView *scrollView = [self parentScrollView];
        if (scrollView) {
            scrollView.scrollEnabled = NO;
        }
    }

    return hitView;
}
@end

