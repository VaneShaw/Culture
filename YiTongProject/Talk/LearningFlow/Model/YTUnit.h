//
//  YTUnit.h
//  YiTongProject
//
//  Scene Dialogue - learning flow model
//
//  说明：
//  - `YTUnit` 是学习流的最小业务单元（词汇/对话/练习/语法/段落总览）
//  - 容器页只关心“当前是哪个 Unit、是否计入进度、主按钮如何驱动”
//  - 题型 UI 由 Presenter（`YTUnitViewProtocol`）基于 `unitType/exerciseType` 渲染
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTUnitType) {
    YTUnitTypeVocab = 0,
    YTUnitTypeDialogueLine = 1,
    YTUnitTypeDialogueParagraph = 2, // 困难级段落总览页：已下线（当前不渲染）
    YTUnitTypeExercise = 3,
    YTUnitTypeGrammar = 4,           // 语法/Usage：通常不计进度（引导页）
};

typedef NS_ENUM(NSInteger, YTExerciseType) {
    YTExerciseTypeListenChooseImage = 0,   // 听词选图
    YTExerciseTypeLookChooseWord = 1,      // 看图选词
    YTExerciseTypeChooseWordFillBlank = 2, // 选词填空
    YTExerciseTypeListenChooseResponse = 3,// 听音回应
    YTExerciseTypeBuildSentence = 4,       // 句子组装
    YTExerciseTypeCompleteDialogue = 5,    // 完成对话
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
/// - `correctOptionId` 在句子组装题里被 MVP 复用为“正确句子字符串”（后续可改为专用字段）
@interface YTUnit : NSObject

@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, assign) YTLevelId levelId;

@property (nonatomic, copy) NSString *unitId;
@property (nonatomic, assign) YTUnitType unitType;
@property (nonatomic, assign) NSInteger stepIndex; // 等级内序号：第N词/第N句/第N题（从0开始，便于数组索引/续学定位）

/// exercise 专用
@property (nonatomic, assign) YTExerciseType exerciseType;

/// 通用展示（按PRD：中/英、拼音、音频等）
@property (nonatomic, copy, nullable) NSString *titleCN;
@property (nonatomic, copy, nullable) NSString *titlePinyin;
@property (nonatomic, copy, nullable) NSString *titleEN;
@property (nonatomic, copy, nullable) NSString *imageName;      // 本地资源名（MVP）
@property (nonatomic, copy, nullable) NSString *audioURLString; // 题干/标准音（后续接口）

/// exercise 专用（MVP：选项用字符串/图片名表达）
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *options; // [{id,text,imageName,audioURL}]
@property (nonatomic, copy, nullable) NSString *correctOptionId;

/// vocab / dialogue_line 可选：需要在题干中高亮并可点击的“词汇点”
/// - 例：@"你是学生吗？" 里高亮 @"吗"
/// - 说明：目前用“子串数组”表达；若未来要支持多处同文案/精确 range，可升级为结构化 range
@property (nonatomic, strong, nullable) NSArray<NSString *> *highlightTexts;

/// Grammar 专用（MVP：纯文本）
@property (nonatomic, copy, nullable) NSString *grammarText;

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
/// - `highlightText`: 需要在 cn 上高亮的子串（string|null）
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

/// 是否计入进度（PRD：grammar 不计；段落总览建议不计）
- (BOOL)countsTowardProgress;

@end

NS_ASSUME_NONNULL_END

