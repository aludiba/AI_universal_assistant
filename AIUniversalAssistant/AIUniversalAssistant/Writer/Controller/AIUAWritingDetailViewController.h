#import <UIKit/UIKit.h>
#import "AIUASuperViewController.h"
NS_ASSUME_NONNULL_BEGIN

@interface AIUAWritingDetailViewController : AIUASuperViewController

/// 初始化方法
/// prompt 用户输入的提示词
/// apiKey DeepSeek API密钥
/// wordCount 字数限制
/// type 写作模版的类型
- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey;

- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey wordCount:(NSInteger)wordCount;

- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey type:(NSString *)type;

- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey type:(NSString *)type wordCount:(NSInteger)wordCount;

@end

NS_ASSUME_NONNULL_END
