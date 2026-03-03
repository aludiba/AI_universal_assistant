#import "AIUADeepSeekWriter.h"
#import "AIUAConfigID.h"
#import <CommonCrypto/CommonDigest.h>

@interface AIUADeepSeekWriter () <NSURLSessionDataDelegate, NSURLSessionStreamDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSession *streamSession;
@property (nonatomic, strong) NSURLSessionDataTask *currentTask;
@property (nonatomic, strong) NSMutableData *streamData;
@property (nonatomic, strong) NSMutableData *streamErrorData;
@property (nonatomic, copy) AIUAStreamHandler currentStreamHandler;
@property (nonatomic, strong) NSMutableString *accumulatedContent;
@property (nonatomic, assign) NSInteger currentStreamStatusCode;
@property (nonatomic, assign) BOOL streamDidReceiveDone;
@property (nonatomic, assign) NSUInteger streamChunkCount;
@property (nonatomic, strong) NSDate *streamStartAt;

@end

@implementation AIUADeepSeekWriter

#ifndef AIUA_STREAM_DEBUG_LOG
#define AIUA_STREAM_DEBUG_LOG 1
#endif

#if AIUA_STREAM_DEBUG_LOG
#define AIUAStreamLog(fmt, ...) NSLog((@"[DeepSeekStream] " fmt), ##__VA_ARGS__)
#else
#define AIUAStreamLog(fmt, ...)
#endif

#pragma mark - 签名辅助

- (NSString *)aiua_sha256Hex:(NSString *)input {
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hex appendFormat:@"%02x", digest[i]];
    }
    return hex;
}

- (void)appendSecurityHeadersToRequest:(NSMutableURLRequest *)request {
    if (AIUA_APP_CLIENT_TOKEN.length > 0) {
        [request setValue:AIUA_APP_CLIENT_TOKEN forHTTPHeaderField:@"x-aiua-app-token"];
    }
    
    // 版本 + 时间戳签名（可选）
    if (AIUA_APP_SIGNING_SECRET.length > 0) {
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        if (appVersion.length == 0) {
            appVersion = @"0.0.0";
        }
        long long ts = (long long)[[NSDate date] timeIntervalSince1970];
        NSString *timestamp = [NSString stringWithFormat:@"%lld", ts];
        NSString *path = request.URL.path.length > 0 ? request.URL.path : @"/ai";
        NSString *raw = [NSString stringWithFormat:@"%@.%@.%@.%@", appVersion, timestamp, path, AIUA_APP_SIGNING_SECRET];
        NSString *signature = [self aiua_sha256Hex:raw];
        
        [request setValue:appVersion forHTTPHeaderField:@"x-aiua-app-version"];
        [request setValue:timestamp forHTTPHeaderField:@"x-aiua-ts"];
        [request setValue:signature forHTTPHeaderField:@"x-aiua-sign"];
    }
}

#pragma mark - 初始化

- (instancetype)initWithAPIKey:(NSString *)apiKey {
    // 兼容旧调用：忽略本地传入的 apiKey，统一走后端代理
    return [self initWithServerURL:AIUA_AI_PROXY_URL];
}

- (instancetype)initWithServerURL:(NSString *)serverURL {
    self = [super init];
    if (self) {
        _baseURL = serverURL.length > 0 ? [serverURL copy] : AIUA_AI_PROXY_URL;
        _timeoutInterval = 120.0; // 流式/长文生成需更长时间，与服务端 UPSTREAM_TIMEOUT_MS 协调
        _modelName = @"deepseek-chat";
        
        // 配置普通请求的NSURLSession
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = _timeoutInterval;
        _session = [NSURLSession sessionWithConfiguration:config];
        
        // 配置流式请求的NSURLSession
        NSURLSessionConfiguration *streamConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        streamConfig.timeoutIntervalForRequest = _timeoutInterval;
        _streamSession = [NSURLSession sessionWithConfiguration:streamConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        _streamData = [NSMutableData data];
        _streamErrorData = [NSMutableData data];
        _accumulatedContent = [NSMutableString string];
        _currentStreamStatusCode = 200;
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
    
    NSURL *url = [NSURL URLWithString:self.baseURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = self.timeoutInterval;
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [self appendSecurityHeadersToRequest:request];
    
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
    
    NSURL *url = [NSURL URLWithString:self.baseURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = self.timeoutInterval;
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [self appendSecurityHeadersToRequest:request];
    
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
    self.streamStartAt = [NSDate date];
    AIUAStreamLog(@"start request. timeout=%.1fs, maxTokens=%ld, promptLen=%ld",
                  self.timeoutInterval, (long)maxTokens, (long)prompt.length);
    
    self.currentTask = [self.streamSession dataTaskWithRequest:request];
    [self.currentTask resume];
}

- (void)resetStreamState {
    [self.streamData setLength:0];
    [self.streamErrorData setLength:0];
    [self.accumulatedContent setString:@""];
    self.currentStreamStatusCode = 200;
    self.streamDidReceiveDone = NO;
    self.streamChunkCount = 0;
    self.streamStartAt = nil;
}

#pragma mark - NSURLSessionDataDelegate (流式处理)

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        self.currentStreamStatusCode = httpResponse.statusCode;
    } else {
        self.currentStreamStatusCode = 200;
    }
    AIUAStreamLog(@"didReceiveResponse status=%ld", (long)self.currentStreamStatusCode);
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session 
          dataTask:(NSURLSessionDataTask *)dataTask 
    didReceiveData:(NSData *)data {
    // 非 200 响应按普通文本缓存，待完成时统一转错误回调
    if (self.currentStreamStatusCode != 200) {
        [self.streamErrorData appendData:data];
        AIUAStreamLog(@"non-200 body chunk bytes=%lu", (unsigned long)data.length);
        return;
    }
    
    [self.streamData appendData:data];
    
    NSString *dataString = [[NSString alloc] initWithData:self.streamData encoding:NSUTF8StringEncoding];
    NSArray *lines = [dataString componentsSeparatedByString:@"\n"];
    
    // 处理完整的行，保留不完整的行在buffer中
    NSMutableString *remainingData = [NSMutableString string];
    BOOL hasIncompleteLine = NO;
    
    for (NSString *line in lines) {
        if ([line hasPrefix:@"data: "]) {
            if ([line isEqualToString:@"data: [DONE]"]) {
                // 标记收到 DONE，由 didCompleteWithError 统一收尾，避免重复回调和状态被提前清空
                self.streamDidReceiveDone = YES;
                AIUAStreamLog(@"received [DONE], accumulatedLen=%lu, chunkCount=%lu",
                              (unsigned long)self.accumulatedContent.length,
                              (unsigned long)self.streamChunkCount);
                continue;
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
            self.streamChunkCount += 1;
            [self.accumulatedContent appendString:chunkContent];
            AIUAStreamLog(@"chunk #%lu len=%lu totalLen=%lu",
                          (unsigned long)self.streamChunkCount,
                          (unsigned long)chunkContent.length,
                          (unsigned long)self.accumulatedContent.length);
            if (self.currentStreamHandler) {
                self.currentStreamHandler(chunkContent, NO, nil);
            }
        }
    } else {
        AIUAStreamLog(@"chunk json parse failed: %@", jsonError.localizedDescription);
    }
}

- (void)URLSession:(NSURLSession *)session 
              task:(NSURLSessionTask *)task 
didCompleteWithError:(NSError *)error {
    NSTimeInterval elapsed = self.streamStartAt ? [[NSDate date] timeIntervalSinceDate:self.streamStartAt] : 0;
    AIUAStreamLog(@"didComplete error=%@ status=%ld done=%d chunkCount=%lu totalLen=%lu elapsed=%.2fs",
                  error.localizedDescription ?: @"nil",
                  (long)self.currentStreamStatusCode,
                  self.streamDidReceiveDone,
                  (unsigned long)self.streamChunkCount,
                  (unsigned long)self.accumulatedContent.length,
                  elapsed);
    
    if (error) {
        if (self.currentStreamHandler) {
            self.currentStreamHandler(@"", YES, error);
        }
    } else if (self.currentStreamStatusCode != 200) {
        NSString *errorMessage = [NSString stringWithFormat:@"HTTP错误: %ld", (long)self.currentStreamStatusCode];
        if (self.streamErrorData.length > 0) {
            NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData:self.streamErrorData options:0 error:nil];
            if ([errorDict isKindOfClass:[NSDictionary class]]) {
                NSString *serverError = errorDict[@"error"];
                NSString *detail = errorDict[@"detail"];
                if (serverError.length > 0 && detail.length > 0) {
                    errorMessage = [NSString stringWithFormat:@"%@ (%@)", serverError, detail];
                } else if (serverError.length > 0) {
                    errorMessage = serverError;
                }
            } else {
                NSString *raw = [[NSString alloc] initWithData:self.streamErrorData encoding:NSUTF8StringEncoding];
                if (raw.length > 0) {
                    errorMessage = [NSString stringWithFormat:@"HTTP错误: %ld - %@", (long)self.currentStreamStatusCode, raw];
                }
            }
        }
        
        NSError *statusError = [NSError errorWithDomain:@"AIUADeepSeekWriter"
                                                   code:self.currentStreamStatusCode
                                               userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        if (self.currentStreamHandler) {
            self.currentStreamHandler(@"", YES, statusError);
        }
    } else {
        // 正常完成，发送最终内容
        if (self.currentStreamHandler) {
            if (self.accumulatedContent.length > 0) {
                self.currentStreamHandler(self.accumulatedContent, YES, nil);
            } else {
                NSString *debugDetail = [NSString stringWithFormat:@"(status=%ld, done=%@, chunks=%lu)",
                                         (long)self.currentStreamStatusCode,
                                         self.streamDidReceiveDone ? @"YES" : @"NO",
                                         (unsigned long)self.streamChunkCount];
                NSError *emptyError = [NSError errorWithDomain:@"AIUADeepSeekWriter"
                                                          code:-1
                                                      userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"流式响应为空，可能是响应超时或服务暂时无返回，请稍后重试 %@", debugDetail]}];
                self.currentStreamHandler(@"", YES, emptyError);
            }
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
