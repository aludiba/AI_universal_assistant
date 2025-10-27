#import "AIUASuperViewController.h"
#import "AIUADeepSeekWriter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AIUAWritingEditType) {
    AIUAWritingEditTypeContinue,  // 续写
    AIUAWritingEditTypeRewrite,   // 改写
    AIUAWritingEditTypeExpand,    // 扩写
    AIUAWritingEditTypeTranslate  // 翻译
};

@interface AIUADocDetailViewController : AIUASuperViewController

// DeepSeek写作器
@property (nonatomic, strong) AIUADeepSeekWriter *deepSeekWriter;

// 新建模式
- (instancetype)initWithNewDocument;

// 编辑模式
- (instancetype)initWithWritingItem:(NSDictionary *)writingItem;

@end

NS_ASSUME_NONNULL_END