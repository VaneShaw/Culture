//
//  YTTalkCompleteSubmit.m
//

#import "YTTalkCompleteSubmit.h"
#import "YTUnit.h"
#import "YTUnitViewProtocol.h"
#import "HttpTools.h"
#import "BaseDataModel.h"
#import "NSDictionary+YTSafe.h"
#import "HeaderConfig.h"

static NSString *YTTalkWordTextForOptionId(YTUnit *unit, NSString *optionId) {
    if (unit.options.count == 0 || optionId.length == 0) return @"";
    for (NSDictionary *opt in unit.options) {
        if (![opt isKindOfClass:[NSDictionary class]]) continue;
        id oid = opt[@"id"];
        NSString *os = [oid isKindOfClass:[NSString class]] ? (NSString *)oid : [NSString stringWithFormat:@"%@", oid];
        if (![os isEqualToString:optionId]) continue;
        id t = opt[@"text"];
        if ([t isKindOfClass:[NSString class]]) {
            return (NSString *)t;
        }
    }
    return @"";
}

static NSString *YTTalkJoinedOrderedTokenTexts(NSDictionary *payload) {
    NSArray *ord = [payload[YTAnswerPayloadKeyOrderedTokenTexts] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeyOrderedTokenTexts] : nil;
    if (ord.count == 0) return @"";
    NSMutableString *s = [NSMutableString string];
    for (id o in ord) {
        if ([o isKindOfClass:[NSString class]]) {
            [s appendString:(NSString *)o];
        }
    }
    return [s copy];
}

static NSArray *YTTalkArrayFromOrderedTokenTexts(NSDictionary *payload) {
    NSArray *ord = [payload[YTAnswerPayloadKeyOrderedTokenTexts] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeyOrderedTokenTexts] : nil;
    if (ord.count == 0) return @[];
    NSMutableArray *out = [NSMutableArray array];
    for (id o in ord) {
        if ([o isKindOfClass:[NSString class]]) {
            [out addObject:o];
        } else if (o) {
            [out addObject:[NSString stringWithFormat:@"%@", o]];
        }
    }
    return [out copy];
}

/// 按当前 unit 接口下发的 `content.correct_answer` 键顺序与类型封装用户答案（与标答同构）
static NSDictionary *YTTalkBuildAnswerFromCorrectAnswerTemplate(NSDictionary *payload, YTUnit *unit) {
    NSDictionary *template = unit.serverCorrectAnswerTemplate;
    if (template.count == 0 || !unit) return nil;
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    NSMutableOrderedSet<NSString *> *orderedKeys = [NSMutableOrderedSet orderedSet];
    NSArray<NSString *> *preferred = @[ @"choice_id", @"fills", @"sentence_text", @"text", @"order" ];
    for (NSString *k in preferred) {
        if (template[k] != nil) {
            [orderedKeys addObject:k];
        }
    }
    for (NSString *k in template) {
        if (![orderedKeys containsObject:k]) {
            [orderedKeys addObject:k];
        }
    }
    for (NSString *key in orderedKeys) {
        id templateVal = template[key];
        if ([key isEqualToString:@"choice_id"]) {
            NSString *sid = [payload[YTAnswerPayloadKeySelectedOptionId] isKindOfClass:[NSString class]] ? payload[YTAnswerPayloadKeySelectedOptionId] : nil;
            if (sid.length == 0) {
                continue;
            }
            if ([templateVal isKindOfClass:[NSNumber class]]) {
                out[key] = @([sid integerValue]);
            } else {
                out[key] = sid;
            }
        } else if ([key isEqualToString:@"fills"]) {
            NSArray *fillIds = [payload[YTAnswerPayloadKeySelectedFillOptionIds] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeySelectedFillOptionIds] : nil;
            NSString *selOpt = [payload[YTAnswerPayloadKeySelectedOptionId] isKindOfClass:[NSString class]] ? payload[YTAnswerPayloadKeySelectedOptionId] : nil;
            NSMutableArray<NSString *> *fillTexts = [NSMutableArray array];
            if (fillIds.count > 0) {
                for (id oidObj in fillIds) {
                    NSString *oid = [oidObj isKindOfClass:[NSString class]] ? (NSString *)oidObj : [NSString stringWithFormat:@"%@", oidObj];
                    [fillTexts addObject:YTTalkWordTextForOptionId(unit, oid) ?: @""];
                }
            } else if (selOpt.length > 0) {
                [fillTexts addObject:YTTalkWordTextForOptionId(unit, selOpt) ?: @""];
            }
            if (fillTexts.count > 0) {
                out[key] = [fillTexts copy];
            }
        } else if ([key isEqualToString:@"sentence_text"] || [key isEqualToString:@"text"]) {
            NSString *joined = YTTalkJoinedOrderedTokenTexts(payload);
            if (joined.length > 0) {
                out[key] = joined;
            }
        } else if ([key isEqualToString:@"order"]) {
            NSArray *arr = YTTalkArrayFromOrderedTokenTexts(payload);
            if (arr.count > 0) {
                out[key] = arr;
            }
        }
    }
    return [out copy];
}

/// Mock / 无 `correct_answer` 模板时的兜底（尽量与常见接口字段一致）
static NSString *YTTalkAnswerJSONStringFromPayloadLegacy(NSDictionary *payload, YTUnit * _Nullable unit) {
    if (payload.count == 0) {
        return @"{}";
    }
    NSMutableDictionary *out = [NSMutableDictionary dictionary];

    if (unit && unit.unitType == YTUnitTypeExerciseChooseWordFillBlank) {
        NSArray *fillIds = [payload[YTAnswerPayloadKeySelectedFillOptionIds] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeySelectedFillOptionIds] : nil;
        NSString *selOpt = [payload[YTAnswerPayloadKeySelectedOptionId] isKindOfClass:[NSString class]] ? payload[YTAnswerPayloadKeySelectedOptionId] : nil;
        NSMutableArray<NSString *> *fillTexts = [NSMutableArray array];
        if (fillIds.count > 0) {
            for (id oidObj in fillIds) {
                NSString *oid = [oidObj isKindOfClass:[NSString class]] ? (NSString *)oidObj : [NSString stringWithFormat:@"%@", oidObj];
                NSString *t = YTTalkWordTextForOptionId(unit, oid);
                [fillTexts addObject:t ?: @""];
            }
        } else if (selOpt.length > 0) {
            [fillTexts addObject:YTTalkWordTextForOptionId(unit, selOpt) ?: @""];
        }
        if (fillTexts.count > 0) {
            out[@"fills"] = [fillTexts copy];
        }
        NSError *err = nil;
        NSData *d = [NSJSONSerialization dataWithJSONObject:out options:0 error:&err];
        if (!d) {
            return @"{}";
        }
        return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    }

    NSString *sid = [payload[YTAnswerPayloadKeySelectedOptionId] isKindOfClass:[NSString class]] ? payload[YTAnswerPayloadKeySelectedOptionId] : nil;
    if (sid.length > 0) {
        out[@"choice_id"] = sid;
    }
    NSArray *ord = [payload[YTAnswerPayloadKeyOrderedTokenTexts] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeyOrderedTokenTexts] : nil;
    if (ord.count > 0) {
        out[@"ordered_token_texts"] = ord;
    }
    NSArray *fills = [payload[YTAnswerPayloadKeySelectedFillOptionIds] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeySelectedFillOptionIds] : nil;
    if (fills.count > 0) {
        out[@"fill_choice_ids"] = fills;
    }
    NSError *err = nil;
    NSData *d = [NSJSONSerialization dataWithJSONObject:out options:0 error:&err];
    if (!d) {
        return @"{}";
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

static NSString *YTTalkAnswerJSONStringFromPayload(NSDictionary *payload, YTUnit * _Nullable unit) {
    if (unit && unit.serverCorrectAnswerTemplate.count > 0) {
        NSDictionary *built = YTTalkBuildAnswerFromCorrectAnswerTemplate(payload ?: @{}, unit);
        NSDictionary *toEncode = built ?: @{};
        NSError *err = nil;
        NSData *d = [NSJSONSerialization dataWithJSONObject:toEncode options:0 error:&err];
        if (!d) {
            return @"{}";
        }
        return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    }
    return YTTalkAnswerJSONStringFromPayloadLegacy(payload ?: @{}, unit);
}

@implementation YTTalkCompleteSubmit

+ (NSString *)answerJSONStringFromAnswerPayload:(NSDictionary *)payload {
    return YTTalkAnswerJSONStringFromPayload(payload ?: @{}, nil);
}

+ (NSString *)answerJSONStringFromAnswerPayload:(NSDictionary *)payload unit:(YTUnit *)unit {
    return YTTalkAnswerJSONStringFromPayload(payload ?: @{}, unit);
}

+ (void)submitWithSceneId:(NSString *)sceneId
                  levelId:(NSInteger)levelId
                     unit:(YTUnit *)unit
         answerJSONString:(NSString *)answerJSON
         readAudioFileURL:(NSURL *)fileURL
               completion:(void (^)(BOOL, BOOL, NSInteger, NSInteger, NSError * _Nullable))completion {
    if (!completion) return;
    /// 接口约定：`scene_id` / `level_id` 以 `unit.content` 内为准；无则回退入口 sceneId、`levelId`（API 等级 1/2/3）
    NSString *effectiveSceneId = unit.contentSceneId.length ? unit.contentSceneId : sceneId;
    NSString *effectiveLevelStr = unit.contentLevelIdString.length
        ? unit.contentLevelIdString
        : [NSString stringWithFormat:@"%ld", (long)levelId];

    NSMutableDictionary<NSString *, NSString *> *fields = [NSMutableDictionary dictionary];
    if (effectiveSceneId.length) {
        fields[@"scene_id"] = effectiveSceneId;
    }
    fields[@"level_id"] = effectiveLevelStr;
    if (unit.unitId.length) {
        fields[@"unit_id"] = unit.unitId;
    }
    if (unit.refTable.length) {
        fields[@"ref_table"] = unit.refTable;
    }
    if (unit.contentId.length) {
        fields[@"content_id"] = unit.contentId;
    }
    NSString *ans = answerJSON.length ? answerJSON : @"{}";
    fields[@"answer"] = ans;

#if DEBUG
    {
        // 与接口文档一致：scene_id / level_id 来自 content（见 effective*）；unit_id、ref_table 为 unit 外层
        NSString *fullURL = [NSString stringWithFormat:@"%@%@", HOST, @"/talk/complete"];
        NSString *contentLine = unit.contentId.length
            ? [NSString stringWithFormat:@"content_id (string) = \"%@\"", unit.contentId]
            : @"content_id = (未传，接口可选)";
        NSString *fileLog = @"read_audio = (未传，接口可选)";
        if (fileURL) {
            BOOL ex = fileURL.path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path];
            unsigned long long b = 0;
            if (ex) {
                NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
                b = [attr[NSFileSize] unsignedLongLongValue];
            }
            fileLog = [NSString stringWithFormat:@"read_audio (file) → path=%@ exists=%@ size_bytes=%llu",
                       fileURL.path, ex ? @"YES" : @"NO", b];
        }
        NSLog(@"\n========== [YTTalkComplete] /talk/complete 请求参数（文档字段）==========\n"
              @"URL: %@\n"
              @"--- multipart 文本部分（全部为 NSString）---\n"
              @"scene_id (string) = \"%@\"  ← content.scene_id，缺省用入口 scene\n"
              @"level_id (string) = \"%@\"  ← content.level_id，缺省用入口 level\n"
              @"unit_id (string) = \"%@\"\n"
              @"ref_table (string) = \"%@\"\n"
              @"%@\n"
              @"answer (string) = %@\n"
              @"--- 文件部分（字段名 read_audio）---\n"
              @"%@\n"
              @"==================================================\n",
              fullURL,
              effectiveSceneId.length ? effectiveSceneId : @"",
              effectiveLevelStr,
              unit.unitId.length ? unit.unitId : @"",
              unit.refTable.length ? unit.refTable : @"",
              contentLine,
              ans,
              fileLog);
    }
#endif

    [HttpTools postMultipartRequest:@"/talk/complete"
                             fields:[fields copy]
                            fileURL:fileURL
                        fileFieldName:@"read_audio"
                            success:^(BOOL success, BaseDataModel *response) {
        if (!success || !response) {
            NSString *msg = response.msg.length ? response.msg : NSLocalizedString(@"Request failed", @"");
            completion(NO, NO, -1, -1, [NSError errorWithDomain:@"YTTalkCompleteSubmit" code:-1 userInfo:@{NSLocalizedDescriptionKey: msg}]);
            return;
        }
        id dataObj = response.data;
        NSDictionary *d = [dataObj isKindOfClass:[NSDictionary class]] ? dataObj : nil;
        BOOL serverOK = NO;
        if (d) {
            id s = d[@"success"];
            if ([s isKindOfClass:[NSNumber class]]) {
                serverOK = [(NSNumber *)s boolValue];
            } else if ([s isKindOfClass:[NSString class]]) {
                NSString *low = [(NSString *)s lowercaseString];
                serverOK = [low isEqualToString:@"true"] || [low isEqualToString:@"1"] || [low isEqualToString:@"yes"];
            }
        }
        NSInteger pct = -1;
        NSDictionary *prog = [d yt_dictionaryForKey:@"progress"];
        if (prog.count) {
            pct = [prog yt_integerForKey:@"progress_percent" defaultValue:-1];
        }
        NSInteger rawScore = -1;
        if (d) {
            id rs = d[@"raw_score"];
            if ([rs isKindOfClass:[NSNumber class]]) {
                rawScore = [(NSNumber *)rs integerValue];
            } else if ([rs isKindOfClass:[NSString class]]) {
                rawScore = [(NSString *)rs integerValue];
            }
        }
        completion(YES, serverOK, pct, rawScore, nil);
    } failure:^(NSError *error) {
        completion(NO, NO, -1, -1, error);
    }];
}

@end
