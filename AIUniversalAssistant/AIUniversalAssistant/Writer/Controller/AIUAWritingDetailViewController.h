#import <UIKit/UIKit.h>
#import "AIUASuperViewController.h"
NS_ASSUME_NONNULL_BEGIN

@interface AIUAWritingDetailViewController : AIUASuperViewController

/// 初始化方法
/// @param prompt 用户输入的提示词
/// @param apiKey DeepSeek API密钥
- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey;

@end

NS_ASSUME_NONNULL_END
