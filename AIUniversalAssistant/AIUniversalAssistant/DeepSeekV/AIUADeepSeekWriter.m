#import "AIUADeepSeekWriter.h"

@interface AIUADeepSeekWriter () <NSURLSessionDataDelegate, NSURLSessionStreamDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSession *streamSession;
@property (nonatomic, strong) NSURLSessionDataTask *currentTask;
@property (nonatomic, strong) NSMutableData *streamData;
@property (nonatomic, copy) AIUAStreamHandler currentStreamHandler;
@property (nonatomic, strong) NSMutableString *accumulatedContent;

@end

@implementation AIUADeepSeekWriter

#pragma mark - 初始化

- (instancetype)initWithAPIKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        _apiKey = [apiKey copy];
        _baseURL = @"https://api.deepseek.com/v1";
        _timeoutInterval = 60.0;
        _modelName = @"deepseek-chat";
        
        // 配置普通请求的NSURLSession
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = _timeoutInterval;
        config.HTTPAdditionalHeaders = @{
            @"Authorization": [NSString stringWithFormat:@"Bearer %@", _apiKey],
            @"Content-Type": @"application/json"
        };
        _session = [NSURLSession sessionWithConfiguration:config];
        
        // 配置流式请求的NSURLSession
        NSURLSessionConfiguration *streamConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        streamConfig.timeoutIntervalForRequest = _timeoutInterval;
        streamConfig.HTTPAdditionalHeaders = @{
            @"Authorization": [NSString stringWithFormat:@"Bearer %@", _apiKey],
            @"Content-Type": @"application/json"
        };
        _streamSession = [NSURLSession sessionWithConfiguration:streamConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        _streamData = [NSMutableData data];
        _accumulatedContent = [NSMutableString string];
    }
    return self;
}

#pragma mark - 公开方法 - 基础写作

- (void)generateWritingWithPrompt:(NSString *)prompt
                       completion:(AIUACompletionHandler)completion {
    [self generateWritingWithPrompt:prompt
                          maxTokens:1000
                        temperature:1.5
                         completion:completion];
}

- (void)generateWritingWithPrompt:(NSString *)prompt
                        maxTokens:(NSInteger)maxTokens
                      temperature:(CGFloat)temperature
                       completion:(AIUACompletionHandler)completion {
    
    NSArray *messages = @[
        @{@"role": @"user", @"content": prompt}
    ];
    
    [self generateWritingWithMessages:messages
                            maxTokens:maxTokens
                          temperature:temperature
                           completion:completion];
}

#pragma mark - 公开方法 - 字数控制

- (void)generateWritingWithPrompt:(NSString *)prompt
                        wordCount:(NSInteger)wordCount
                       completion:(AIUACompletionHandler)completion {
    
    NSString *enhancedPrompt = [self addWordCountRequirementToPrompt:prompt wordCount:wordCount];
    NSInteger estimatedTokens = [self estimatedTokensForWordCount:wordCount];
    
    [self generateWritingWithPrompt:enhancedPrompt
                          maxTokens:estimatedTokens
                        temperature:1.5
                         completion:completion];
}

- (void)generateWritingWithPrompt:(NSString *)prompt
                         minWords:(NSInteger)minWords
                         maxWords:(NSInteger)maxWords
                       completion:(AIUACompletionHandler)completion {
    
    NSString *enhancedPrompt = [self addWordRangeRequirementToPrompt:prompt minWords:minWords maxWords:maxWords];
    NSInteger estimatedTokens = [self estimatedTokensForWordCount:maxWords];
    
    [self generateWritingWithPrompt:enhancedPrompt
                          maxTokens:estimatedTokens
                        temperature:1.5
                         completion:completion];
}

- (NSInteger)estimatedTokensForWordCount:(NSInteger)wordCount {
    // 中英文混合情况下，大致估算：1个token ≈ 0.75个英文单词 ≈ 1-2个中文字符
    // 这里采用保守估计：1个中文字符 ≈ 1.5个token
    return (NSInteger)(wordCount * 1.5) + 50; // 增加50个token作为缓冲
}

#pragma mark - 公开方法 - 流式处理

- (void)generateFullStreamWritingWithPrompt:(NSString *)prompt
                                 wordCount:(NSInteger)wordCount
                            streamHandler:(AIUAStreamHandler)streamHandler {
    
    NSString *finalPrompt = prompt;
    if (wordCount > 0) {
        finalPrompt = [self addWordCountRequirementToPrompt:prompt wordCount:wordCount];
    }
    
    NSInteger maxTokens = wordCount > 0 ? [self estimatedTokensForWordCount:wordCount] : 1000;
    
    [self performFullStreamRequestWithPrompt:finalPrompt
                                   maxTokens:maxTokens
                                 temperature:1.5
                              streamHandler:streamHandler];
}

#pragma mark - 多轮对话

- (void)generateWritingWithMessages:(NSArray<NSDictionary<NSString *, NSString *> *> *)messages
                         completion:(AIUACompletionHandler)completion {
    
    [self generateWritingWithMessages:messages
                            maxTokens:1000
                          temperature:1.5
                           completion:completion];
}

- (void)cancelCurrentRequest {
    [self.currentTask cancel];
    self.currentTask = nil;
    [self resetStreamState];
}

#pragma mark - 私有方法 - 字数处理

- (NSString *)addWordCountRequirementToPrompt:(NSString *)prompt wordCount:(NSInteger)wordCount {
    if (wordCount && wordCount > 0) {
        return [NSString stringWithFormat:@"%@\n\n请确保内容字数在%@字左右。", prompt, @(wordCount)];
    }
    return prompt;
}

- (NSString *)addWordRangeRequirementToPrompt:(NSString *)prompt minWords:(NSInteger)minWords maxWords:(NSInteger)maxWords {
    return [NSString stringWithFormat:@"%@\n\n请确保内容字数在%@到%@字之间。", prompt, @(minWords), @(maxWords)];
}

#pragma mark - 私有方法 - 请求处理

- (void)generateWritingWithMessages:(NSArray<NSDictionary<NSString *, NSString *> *> *)messages
                          maxTokens:(NSInteger)maxTokens
                        temperature:(CGFloat)temperature
                         completion:(AIUACompletionHandler)completion {
    
    NSDictionary *requestBody = @{
        @"model": self.modelName,
        @"messages": messages,
        @"max_tokens": @(MAX(1, MIN(maxTokens, 4000))),
        @"temperature": @(MAX(0.0, MIN(temperature, 1.5))),
        @"stream": @NO
    };
    
    [self performRequestWithBody:requestBody stream:NO completion:completion streamHandler:nil];
}

- (void)generateStreamWritingWithMessages:(NSArray<NSDictionary<NSString *, NSString *> *> *)messages
                                maxTokens:(NSInteger)maxTokens
                              temperature:(CGFloat)temperature
                           streamHandler:(AIUAStreamHandler)streamHandler {
    
    NSDictionary *requestBody = @{
        @"model": self.modelName,
        @"messages": messages,
        @"max_tokens": @(MAX(1, MIN(maxTokens, 4000))),
        @"temperature": @(MAX(0.0, MIN(temperature, 1.5))),
        @"stream": @YES
    };
    
    [self performRequestWithBody:requestBody stream:YES completion:nil streamHandler:streamHandler];
}

- (void)performRequestWithBody:(NSDictionary *)body
                        stream:(BOOL)stream
                    completion:(AIUACompletionHandler _Nullable)completion
                streamHandler:(AIUAStreamHandler _Nullable)streamHandler {
    
    NSString *endpoint = [self.baseURL stringByAppendingString:@"/chat/completions"];
    NSURL *url = [NSURL URLWithString:endpoint];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = self.timeoutInterval;
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.apiKey] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (jsonError) {
        if (completion) completion(nil, jsonError);
        if (streamHandler) streamHandler(@"", YES, jsonError);
        return;
    }
    request.HTTPBody = jsonData;
    
    [self cancelCurrentRequest];
    
    if (stream) {
        self.currentStreamHandler = streamHandler;
        [self resetStreamState];
        
        self.currentTask = [self.streamSession dataTaskWithRequest:request];
        [self.currentTask resume];
    } else {
        [self performStandardRequest:request completion:completion];
    }
}

#pragma mark - 完整的流式请求实现

- (void)performFullStreamRequestWithPrompt:(NSString *)prompt
                                 maxTokens:(NSInteger)maxTokens
                               temperature:(CGFloat)temperature
                            streamHandler:(AIUAStreamHandler)streamHandler {
    
    NSDictionary *requestBody = @{
        @"model": self.modelName,
        @"messages": @[@{@"role": @"user", @"content": prompt}],
        @"max_tokens": @(MAX(1, MIN(maxTokens, 4000))),
        @"temperature": @(MAX(0.0, MIN(temperature, 1.5))),
        @"stream": @YES
    };
    
    NSString *endpoint = [self.baseURL stringByAppendingString:@"/chat/completions"];
    NSURL *url = [NSURL URLWithString:endpoint];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = self.timeoutInterval;
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.apiKey] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&jsonError];
    if (jsonError) {
        streamHandler(@"", YES, jsonError);
        return;
    }
    request.HTTPBody = jsonData;
    
    [self cancelCurrentRequest];
    
    self.currentStreamHandler = streamHandler;
    [self resetStreamState];
    
    self.currentTask = [self.streamSession dataTaskWithRequest:request];
    [self.currentTask resume];
}

- (void)resetStreamState {
    [self.streamData setLength:0];
    [self.accumulatedContent setString:@""];
}

#pragma mark - NSURLSessionDataDelegate (流式处理)

- (void)URLSession:(NSURLSession *)session 
          dataTask:(NSURLSessionDataTask *)dataTask 
    didReceiveData:(NSData *)data {
    
    [self.streamData appendData:data];
    
    NSString *dataString = [[NSString alloc] initWithData:self.streamData encoding:NSUTF8StringEncoding];
    NSArray *lines = [dataString componentsSeparatedByString:@"\n"];
    
    // 处理完整的行，保留不完整的行在buffer中
    NSMutableString *remainingData = [NSMutableString string];
    BOOL hasIncompleteLine = NO;
    
    for (NSString *line in lines) {
        if ([line hasPrefix:@"data: "]) {
            if ([line isEqualToString:@"data: [DONE]"]) {
                // 流式传输完成
                if (self.currentStreamHandler) {
                    self.currentStreamHandler(@"", YES, nil);
                }
                [self resetStreamState];
                return;
            } else {
                NSString *jsonStr = [line substringFromIndex:6];
                if (jsonStr.length > 0) {
                    [self processStreamJSON:jsonStr];
                }
            }
        } else if (line.length > 0) {
            // 不完整的行，保留到下一次处理
            if (remainingData.length > 0) [remainingData appendString:@"\n"];
            [remainingData appendString:line];
            hasIncompleteLine = YES;
        }
    }
    
    if (hasIncompleteLine) {
        self.streamData = [remainingData dataUsingEncoding:NSUTF8StringEncoding].mutableCopy;
    } else {
        [self.streamData setLength:0];
    }
}

- (void)processStreamJSON:(NSString *)jsonStr {
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError;
    NSDictionary *chunkDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
    
    if (!jsonError) {
        NSString *chunkContent = [self extractContentFromResponse:chunkDict];
        if (chunkContent && chunkContent.length > 0) {
            [self.accumulatedContent appendString:chunkContent];
            if (self.currentStreamHandler) {
                self.currentStreamHandler(chunkContent, NO, nil);
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session 
              task:(NSURLSessionTask *)task 
didCompleteWithError:(NSError *)error {
    
    if (error) {
        if (self.currentStreamHandler) {
            self.currentStreamHandler(@"", YES, error);
        }
    } else {
        // 正常完成，发送最终内容
        if (self.currentStreamHandler && self.accumulatedContent.length > 0) {
            self.currentStreamHandler(self.accumulatedContent, YES, nil);
        }
    }
    [self resetStreamState];
}

#pragma mark - 标准请求处理

- (void)performStandardRequest:(NSURLRequest *)request
                    completion:(AIUACompletionHandler)completion {
    
    self.currentTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSError *statusError = [NSError errorWithDomain:@"AIUADeepSeekWriter"
                                                       code:httpResponse.statusCode
                                                   userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP错误: %ld", (long)httpResponse.statusCode]}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, statusError);
            });
            return;
        }
        
        NSError *parseError;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, parseError);
            });
            return;
        }
        
        NSString *content = [self extractContentFromResponse:responseDict];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(content, nil);
        });
    }];
    
    [self.currentTask resume];
}

- (NSString *)extractContentFromResponse:(NSDictionary *)response {
    NSArray *choices = response[@"choices"];
    if (choices && [choices isKindOfClass:[NSArray class]] && choices.count > 0) {
        NSDictionary *firstChoice = choices[0];
        NSDictionary *message = firstChoice[@"message"];
        if (message && [message isKindOfClass:[NSDictionary class]]) {
            return message[@"content"];
        }
        
        NSDictionary *delta = firstChoice[@"delta"];
        if (delta && [delta isKindOfClass:[NSDictionary class]]) {
            return delta[@"content"];
        }
    }
    return nil;
}

#pragma mark - 析构

- (void)dealloc {
    [self cancelCurrentRequest];
}

@end
