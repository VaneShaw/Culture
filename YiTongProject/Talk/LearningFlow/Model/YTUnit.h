//
//  YTUnit.h
//  YiTongProject
//
//  Scene Dialogue - learning flow model
//
//  说明：
//  - `YTUnit` 是学习流的最小业务单元（发音学习/练习/语法）
//  - 容器页只关心“当前是哪个 Unit、是否计入进度、主按钮如何驱动”
//  - 题型 UI 由 Presenter（`YTUnitViewProtocol`）基于 `unitType` 渲染
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTUnitType) {
    YTUnitTypePronounce = 0,                    // 发音练习
    YTUnitTypeExerciseListenChooseImage = 1,    // 听词选图
    YTUnitTypeExerciseLookChooseWord = 2,       // 看图选词
    YTUnitTypeExerciseChooseWordFillBlank = 3,  // 选词填空
    YTUnitTypeExerciseListenChooseResponse = 4, // 听音回应
    YTUnitTypeExerciseBuildSentence = 5,        // 句子组装
    YTUnitTypeExerciseCompleteDialogue = 6,     // 完成对话
    YTUnitTypePracticeTransition = 7,           // 词汇/句子学完后 → 练习题前的过渡页（不计入进度）
    YTUnitTypeLevelCompletion = 8,              // 本难度全部练习结束后的完成页（不计入进度）
};

/// PRD: 入门/简单/困难
typedef NS_ENUM(NSInteger, YTLevelId) {
    YTLevelIdBeginner = 0,
    YTLevelIdIntermediate = 1,
    YTLevelIdAdvanced = 2,
};

/// Unit 内容字段（最小可运行集合；后续接接口可扩展）
///
/// 字段约定（MVP）：
/// - 资源以本地 `imageName` 表达；音频以 `audioURLString` 表达（多数 mock 为空）
/// - 选择题 `options` 使用字典数组表达：常用 key 为 id/text/imageName/audioURL
@interface YTUnit : NSObject

/// 学习流入口（续学 key、Mock 等）；`/talk/complete` 的 `scene_id` 优先用 `contentSceneId`
@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, assign) YTLevelId levelId;

/// 接口 `content.scene_id` / `content.level_id`（字符串）；提交 `/talk/complete` 时优先于入口 scene/level
@property (nonatomic, copy, nullable) NSString *contentSceneId;
@property (nonatomic, copy, nullable) NSString *contentLevelIdString;

/// 学习流单元标识：接口路径优先用外层 `unit_id`（字符串或数字）；无则回退 `ref_table`+`ref_id` 等拼接
@property (nonatomic, copy) NSString *unitId;
@property (nonatomic, assign) YTUnitType unitType;
@property (nonatomic, assign) NSInteger stepIndex; // 等级内序号：第N词/第N句/第N题（从0开始，便于数组索引/续学定位）

/// `/talk/unit` 与提交 `/talk/complete`：`ref_table` 为 vocab / dialogue / exercise / cross
@property (nonatomic, copy, nullable) NSString *refTable;
/// 内容主键：优先 `content.id`，其次 `content.content_id`（提交 `/talk/complete`）
@property (nonatomic, copy, nullable) NSString *contentId;

/// 通用展示（按PRD：中/英、拼音、音频等）
/// - 练习题：`stem_text` / `stem_pinyin` 在 `content` 下（或扁平 payload，见 `YTUnitMapper`）
/// - `listen_respond`：`stem_text`→左上角说明；`stem_pinyin`→听音题题目气泡；`stem_audio_url`→喇叭音频
/// - 各 Unit 卡片左上角说明文案统一用 `stemText`（接口 `stem_text`）；`titleCN` 仍表示题干主文案（如选词填空的 `sentence_template`）
@property (nonatomic, copy, nullable) NSString *stemText;
@property (nonatomic, copy, nullable) NSString *titleCN;
@property (nonatomic, copy, nullable) NSString *titlePinyin;
@property (nonatomic, copy, nullable) NSString *titleEN;
@property (nonatomic, copy, nullable) NSString *imageName;      // 本地资源名（MVP）
@property (nonatomic, copy, nullable) NSString *imageURLString; // 远程图片 URL（接口优先；失败回退 imageName）
@property (nonatomic, copy, nullable) NSString *audioURLString; // 题干/标准音（后续接口）

/// pronounce 可选：中间媒体组件（图片/视频），用于左右滑动展示
/// - 形状（建议）：[{type:"image", name:"xxx"/url:"..."}, {type:"video", url:"..."}]
/// - 接口也可在 `content` 下发 `video_url`（及 `image_url`），由 `YTUnitMapper` 组装为本数组
/// - 若为空，UI 继续使用 imageURLString/imageName 兜底
@property (nonatomic, copy, nullable) NSArray<NSDictionary *> *mediaItems;

/// exercise_* 专用（MVP：选项用字符串/图片名表达）
/// - `word_fill` 接口可在 `content.options` 里给 `word_bank`（字符串数组）；Mapper 会转为 `{ id, text }` 供选词填空 UI 使用
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *options; // [{id,text,imageName,audioURL}]
@property (nonatomic, copy, nullable) NSString *correctOptionId;
/// `word_fill` 专用：接口 `correct_answer.fills`（按空顺序填入的词，与 `word_bank` 文案比对）
@property (nonatomic, copy, nullable) NSArray<NSString *> *correctFillTexts;
/// 句子组装题专用：正确句子全文（接口可为 `correct_answer.sentence_text` / `text`，或 `correct_answer.order` 数组合并）
@property (nonatomic, copy, nullable) NSString *correctSentenceText;

/// 接口 `content.correct_answer` 原样副本（键即提交 `/talk/complete` 时 `answer` 应与之一致）
@property (nonatomic, copy, nullable) NSDictionary *serverCorrectAnswerTemplate;

/// pronounce 可选：需要在题干中高亮并可点击的“词汇点”
/// - 例：@"你是学生吗？" 里高亮 @"吗"
/// - `grammar_keyword` 可为「模板」：用 ASCII 三个点 `...` 表示中间可变，如 `去...吗` → 句子里「去学校吗」高亮「去」「吗」；若句中字面出现 `去...吗` 则整段高亮
/// - 说明：目前用“子串数组”表达；UI 侧对含 `...` 的项做展开
@property (nonatomic, strong, nullable) NSArray<NSString *> *highlightTexts;

/// Grammar Page（点词高亮翻转后的语法页：标题/说明/公式/示例/拼音与高亮）
/// - 注意：当前语法页 UI 由 `YTPronounceUnitView` 负责（不是 `unitType=grammar` 那个纯文本页）
@property (nonatomic, copy, nullable) NSString *grammarPageNavTitle;
@property (nonatomic, copy, nullable) NSString *grammarPageDescription;
@property (nonatomic, copy, nullable) NSString *grammarPagePromptToken;
@property (nonatomic, copy, nullable) NSString *grammarPagePromptPinyin;
@property (nonatomic, copy, nullable) NSString *grammarPagePromptText;
@property (nonatomic, copy, nullable) NSString *grammarPageFormulaText;
@property (nonatomic, copy, nullable) NSString *grammarPageFormulaHighlightText;
@property (nonatomic, copy, nullable) NSString *grammarPageExampleLabel;
@property (nonatomic, copy, nullable) NSString *grammarPageArrowText;

/// 语法页例句数组（可扩展 N 句）
/// 每条 example 字典建议包含：
/// - `cn`: 中文句子（string）
/// - `en`: 英文句子（string）
/// - `highlightText`: 需要在 cn 上高亮的子串（string|null）；与 `grammar_keyword` 相同规则，支持 `...` 通配
@property (nonatomic, copy, nullable) NSArray<NSDictionary *> *grammarPageExamples;

/// 兼容旧字段（示例仅 2 条时使用，若 `grammarPageExamples` 非空则 UI 会优先使用数组）
@property (nonatomic, copy, nullable) NSString *grammarPageExample1CN;
@property (nonatomic, copy, nullable) NSString *grammarPageExample1EN;
@property (nonatomic, copy, nullable) NSString *grammarPageExample2CN;
@property (nonatomic, copy, nullable) NSString *grammarPageExample2EN;
@property (nonatomic, copy, nullable) NSString *grammarPageExample2HighlightText;

/// Complete Dialogue 专用（MVP）：回答模板（用 "__" 表示空缺）
/// - 例：@"__，我是学生。"
@property (nonatomic, copy, nullable) NSString *answerTemplateCN;
/// `complete_dialogue`：接口 `content.options.context_lines`（对话上文，题干气泡展示）
@property (nonatomic, copy, nullable) NSArray<NSDictionary *> *completeDialogueContextLines;

/// 后台下发：`/talk/unit` 中 `is_unit_completed` / `is_line_completed` 任一为完成，或 `progress.answeredCorrect` 为 YES；为 YES 时可用 `serverAnswerPayload` 预填（来自 `progress.answerPayload` 或题干内标答推导）
@property (nonatomic, assign) BOOL answeredCorrectFromServer;
/// 后台下发的可恢复答案（如 @{@"selectedOptionId":@"a"} 或句子组装的 orderedTokenTexts）
@property (nonatomic, copy, nullable) NSDictionary *serverAnswerPayload;

/// `practice_transition`（7）：`display.subtitle`（string）与 `display.sections`
@property (nonatomic, copy, nullable) NSString *transitionSubtitle;
/// 每项建议 `@{ @"caption": @"", @"body": @"" }`（困难模式两段说明）
@property (nonatomic, copy, nullable) NSArray<NSDictionary *> *transitionSections;
/// `level_complete`（8）：`display.scoreText` / `display.subtitle` 等
@property (nonatomic, copy, nullable) NSString *completionScoreText;
@property (nonatomic, copy, nullable) NSString *completionSubtitle;

/// 是否计入进度（过渡页 / 完成页不计入）
- (BOOL)countsTowardProgress;

/// `unitType` 7 / 8：主标题来自接口 `display.title`（string）；其它题型仍可能用 `titleCN` / `titleEN` / `titlePinyin`。
- (NSString *)yt_resolvedTitleDisplayText;

/// 左上角说明：`stem_text` 去空白；为空则返回 nil（UI 可用本地化兜底）
- (nullable NSString *)yt_resolvedStemInstructionText;

#pragma mark - 题型分类（学习流内统一入口，避免多处 switch 重复）

/// 练习题：unitType 1～6（听词选图 / … / 完成对话）
+ (BOOL)yt_isExerciseQuestionType:(YTUnitType)t;
/// 用 `selectedOptionId` 判题的选择/填空类（不含句子组装）
+ (BOOL)yt_isSelectedOptionExerciseType:(YTUnitType)t;

/// 听词选图 / 听音回应（错题提示带拼音等）
- (BOOL)yt_isListeningExercise;

/// 接口/本地标答的可读摘要，用于错题或接口错误弹窗（无则返回空串）
- (NSString *)yt_displayCorrectAnswerText;

@end

NS_ASSUME_NONNULL_END
