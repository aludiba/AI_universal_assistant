#import "AIUASuperViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AIUAWritingInputViewController : AIUASuperViewController

@property (nonatomic, strong) NSDictionary *templateItem;
@property (nonatomic, copy) NSString *categoryId;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *type;

- (instancetype)initWithTemplateItem:(NSDictionary *)templateItem
                            categoryId:(NSString *)categoryId apiKey:(NSString *)apiKey;

@end

NS_ASSUME_NONNULL_END
