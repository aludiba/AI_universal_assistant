//
//  AIUATextViewController.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/11/24.
//

#import "AIUASuperViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AIUATextViewController : AIUASuperViewController

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *htmlFileName; // HTML文件名（如：用户协议.html）
@property (nonatomic, copy) NSString *urlString; // 远程URL（如：https://example.com/terms.html）

@end

NS_ASSUME_NONNULL_END
