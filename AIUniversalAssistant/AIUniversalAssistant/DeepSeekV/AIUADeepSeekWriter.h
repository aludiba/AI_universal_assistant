#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AIUACompletionHandler)(NSString * _Nullable response, NSError * _Nullable error);
typedef void(^AIUAStreamHandler)(NSString *chunk, BOOL finished, NSError * _Nullable error);

@interface AIUADeepSeekWriter : NSObject

/// API密钥
@property (nonatomic, copy) NSString *apiKey;
/// API基础URL，默认为DeepSeek官方API
@property (nonatomic, copy) NSString *baseURL;
/// 请求超时时间，默认60秒
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
/// 模型名称，默认为最新版本
@property (nonatomic, copy) NSString *modelName;

/**
 * 初始化方法
 * @param apiKey DeepSeek API密钥
 */
- (instancetype)initWithAPIKey:(NSString *)apiKey;

#pragma mark - 基础写作方法

/**
 * 单次对话写作
 * @param prompt 写作提示
 * @param completion 完成回调
 */
- (void)generateWritingWithPrompt:(NSString *)prompt
                       completion:(AIUACompletionHandler)completion;

/**
 * 带参数的写作生成
 * @param prompt 写作提示
 * @param maxTokens 最大token数
 * @param temperature 温度参数 (0.0-1.0)
 * @param completion 完成回调
 */
- (void)generateWritingWithPrompt:(NSString *)prompt
                        maxTokens:(NSInteger)maxTokens
                      temperature:(CGFloat)temperature
                       completion:(AIUACompletionHandler)completion;

#pragma mark - 字数控制方法

/**
 * 生成指定字数的内容
 * @param prompt 写作提示（会自动添加字数要求）
 * @param wordCount 目标字数
 * @param completion 完成回调
 */
- (void)generateWritingWithPrompt:(NSString *)prompt
                        wordCount:(NSInteger)wordCount
                       completion:(AIUACompletionHandler)completion;

/**
 * 生成指定字数范围的内容
 * @param prompt 写作提示
 * @param minWords 最小字数
 * @param maxWords 最大字数
 * @param completion 完成回调
 */
- (void)generateWritingWithPrompt:(NSString *)prompt
                         minWords:(NSInteger)minWords
                         maxWords:(NSInteger)maxWords
                       completion:(AIUACompletionHandler)completion;

/**
 * 智能估算token数基于字数
 * @param wordCount 目标字数
 * @return 估算的token数
 */
- (NSInteger)estimatedTokensForWordCount:(NSInteger)wordCount;

#pragma mark - 流式处理方法

/**
 * 完整的流式写作（使用NSURLSessionStreamDelegate）
 * @param prompt 写作提示
 * @param wordCount 目标字数（可选，传0表示不限制）
 * @param streamHandler 流式回调
 */
- (void)generateFullStreamWritingWithPrompt:(NSString *)prompt
                                 wordCount:(NSInteger)wordCount
                            streamHandler:(AIUAStreamHandler)streamHandler;

#pragma mark - 多轮对话

/**
 * 多轮对话写作
 * @param messages 消息数组，每个元素为 @{@"role": @"user/system/assistant", @"content": @"消息内容"}
 * @param completion 完成回调
 */
- (void)generateWritingWithMessages:(NSArray<NSDictionary<NSString *, NSString *> *> *)messages
                         completion:(AIUACompletionHandler)completion;

/**
 * 中断当前请求
 */
- (void)cancelCurrentRequest;

@end

NS_ASSUME_NONNULL_END
