//
//  YTInternalUnitViewSupport.m
//  YiTongProject
//

#import "YTInternalUnitViewSupport.h"
#import "YTAnswerEvaluating.h"
#import "YTUnit.h"

static NSArray<NSString *> *YTOrderedTokenTextsByGreedyMatch(NSString *sentence, NSArray<NSDictionary *> *options) {
    if (sentence.length == 0) return nil;
    NSMutableArray<NSString *> *candidates = [NSMutableArray array];
    for (NSDictionary *opt in options) {
        if (![opt isKindOfClass:[NSDictionary class]]) continue;
        NSString *t = opt[@"text"];
        if ([t isKindOfClass:[NSString class]] && t.length > 0) {
            [candidates addObject:t];
        }
    }
    if (candidates.count == 0) return nil;
    [candidates sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        if (a.length > b.length) return NSOrderedAscending;
        if (a.length < b.length) return NSOrderedDescending;
        return [a compare:b];
    }];
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    NSUInteger pos = 0;
    NSUInteger len = sentence.length;
    while (pos < len) {
        BOOL matched = NO;
        for (NSString *tok in candidates) {
            if (pos + tok.length > len) continue;
            if ([[sentence substringWithRange:NSMakeRange(pos, tok.length)] isEqualToString:tok]) {
                [out addObject:tok];
                pos += tok.length;
                matched = YES;
                break;
            }
        }
        if (!matched) return nil;
    }
    return [out copy];
}

static NSArray<NSString *> *YTCorrectFillOptionIdsForWordFillUnit(YTUnit *unit) {
    if (unit.unitType != YTUnitTypeExerciseChooseWordFillBlank || unit.correctFillTexts.count == 0) return nil;
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    for (NSString *want in unit.correctFillTexts) {
        if (![want isKindOfClass:[NSString class]]) return nil;
        NSString *trimWant = [want stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimWant.length == 0) return nil;
        NSString *foundId = nil;
        for (NSDictionary *opt in unit.options) {
            if (![opt isKindOfClass:[NSDictionary class]]) continue;
            NSString *txt = opt[@"text"];
            if (![txt isKindOfClass:[NSString class]]) continue;
            if ([[txt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:trimWant]) {
                id oid = opt[@"id"];
                foundId = [oid isKindOfClass:[NSString class]] ? (NSString *)oid : [NSString stringWithFormat:@"%@", oid];
                break;
            }
        }
        if (foundId.length == 0) return nil;
        [out addObject:foundId];
    }
    return [out copy];
}

NSDictionary *YTAnswerPayloadForSelectedOptionId(NSString *selectedOptionId) {
    if (selectedOptionId.length == 0) return nil;
    return @{YTAnswerPayloadKeySelectedOptionId: selectedOptionId};
}

NSDictionary *YTAnswerPayloadForOrderedTokenTexts(NSArray<NSString *> *orderedTokenTexts) {
    if (orderedTokenTexts.count == 0) return nil;
    return @{YTAnswerPayloadKeyOrderedTokenTexts: orderedTokenTexts};
}

NSDictionary *YTAnswerPayloadForSelectedFillOptionIds(NSArray<NSString *> *orderedOptionIds) {
    if (orderedOptionIds.count == 0) return nil;
    return @{YTAnswerPayloadKeySelectedFillOptionIds: orderedOptionIds};
}

UIImage *YTTalkImageAspectFitInBounds(UIImage *image, CGSize boundsSize, CGFloat cornerRadius, CGFloat contentFraction) {
    if (!image || boundsSize.width < 1.0 || boundsSize.height < 1.0) {
        return image;
    }
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize imgSize = image.size;
    if (imgSize.width < 1.0 || imgSize.height < 1.0) {
        return image;
    }
    CGFloat bw = boundsSize.width;
    CGFloat bh = boundsSize.height;
    CGFloat frac = (contentFraction > 1e-6) ? MIN(1.0, contentFraction) : 1.0;
    CGFloat boxW = bw * frac;
    CGFloat boxH = bh * frac;
    CGFloat boxX = (bw - boxW) / 2.0;
    CGFloat boxY = (bh - boxH) / 2.0;

    CGFloat sx = boxW / imgSize.width;
    CGFloat sy = boxH / imgSize.height;
    CGFloat s = MIN(sx, sy);
    CGFloat drawW = imgSize.width * s;
    CGFloat drawH = imgSize.height * s;
    CGFloat ox = boxX + (boxW - drawW) / 2.0;
    CGFloat oy = boxY + (boxH - drawH) / 2.0;
    CGRect drawRect = CGRectMake(ox, oy, drawW, drawH);
    CGFloat r = MIN(cornerRadius, MIN(CGRectGetWidth(drawRect), CGRectGetHeight(drawRect)) / 2.0);

    UIGraphicsBeginImageContextWithOptions(boundsSize, NO, scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        UIGraphicsEndImageContext();
        return image;
    }
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:drawRect cornerRadius:r];
    [path addClip];
    [image drawInRect:drawRect];
    UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return out ?: image;
}

NSDictionary *YTRestoreAnswerPayloadFromUnit(YTUnit *unit) {
    if (!unit) return nil;
    if (unit.unitType == YTUnitTypeExerciseChooseWordFillBlank && unit.correctFillTexts.count > 1) {
        NSArray<NSString *> *ids = YTCorrectFillOptionIdsForWordFillUnit(unit);
        if (ids.count == unit.correctFillTexts.count) {
            return YTAnswerPayloadForSelectedFillOptionIds(ids);
        }
    }
    if ([YTUnit yt_isSelectedOptionExerciseType:unit.unitType]) {
        return YTAnswerPayloadForSelectedOptionId(unit.correctOptionId);
    }
    if (unit.unitType == YTUnitTypeExerciseBuildSentence) {
        NSArray *ordered = YTOrderedTokenTextsByGreedyMatch(unit.correctSentenceText ?: @"", unit.options ?: @[]);
        return YTAnswerPayloadForOrderedTokenTexts(ordered);
    }
    return nil;
}

NSString *YTSelectedOptionIdFromPayload(NSDictionary *payload) {
    NSString *selectedOptionId = [payload[YTAnswerPayloadKeySelectedOptionId] isKindOfClass:[NSString class]] ? payload[YTAnswerPayloadKeySelectedOptionId] : nil;
    return selectedOptionId;
}

NSArray<NSString *> *YTOrderedTokenTextsFromPayload(NSDictionary *payload) {
    NSArray *texts = [payload[YTAnswerPayloadKeyOrderedTokenTexts] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeyOrderedTokenTexts] : nil;
    return texts;
}

NSArray<NSString *> *YTSelectedFillOptionIdsFromPayload(NSDictionary *payload) {
    NSArray *raw = [payload[YTAnswerPayloadKeySelectedFillOptionIds] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeySelectedFillOptionIds] : nil;
    if (raw.count == 0) return nil;
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    for (id o in raw) {
        if ([o isKindOfClass:[NSString class]]) {
            [out addObject:(NSString *)o];
        } else if ([o isKindOfClass:[NSNumber class]]) {
            [out addObject:[NSString stringWithFormat:@"%@", o]];
        }
    }
    return out.count > 0 ? [out copy] : nil;
}

@implementation YTBaseUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        _rootView = [[UIView alloc] init];
        _rootView.backgroundColor = [UIColor clearColor];
        _primaryState = [[YTUnitPrimaryState alloc] init];
        _primaryState.kind = YTUnitPrimaryKindContinue;
        _primaryState.title = @"Talk_Continue";
        _primaryState.enabled = YES;
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit
                    theme:(YTDifficultyTheme *)theme
                    audio:(YTAudioMuxService *)audio
                recording:(YTRecordingService *)recording
       pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator
          answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator
{
    self.unit = unit;
    self.theme = theme;
    self.audio = audio;
    self.recording = recording;
    self.pronounceEvaluator = pronounceEvaluator;
    self.answerEvaluator = answerEvaluator;
    self.completeSignalSatisfied = NO;
}

- (void)emitPrimaryState {
    if (self.onPrimaryStateChanged) {
        self.onPrimaryStateChanged(self.primaryState);
    }
}

- (BOOL)isUnitCompleteSignalSatisfied {
    return self.completeSignalSatisfied;
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    if (completion) completion(nil, nil);
}

- (void)applyRestoredAnswerSnapshot:(NSDictionary *)snapshot {
    (void)snapshot;
}

- (void)evaluateAnswerPayload:(NSDictionary *)answerPayload
                   completion:(void (^)(YTUnitSubmitResult * _Nullable result, NSError * _Nullable error))completion
{
    id<YTAnswerEvaluating> evaluator = self.answerEvaluator;
    if (!evaluator) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"YTBaseUnitView"
                                                code:5001
                                            userInfo:@{NSLocalizedDescriptionKey: @"Missing answer evaluator"}]);
        }
        return;
    }
    [evaluator evaluateUnit:self.unit answerPayload:answerPayload completion:completion];
}

@end
