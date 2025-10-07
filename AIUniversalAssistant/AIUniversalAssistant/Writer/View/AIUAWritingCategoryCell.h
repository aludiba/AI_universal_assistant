//
//  AIUAWritingCategoryCell.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 定义点击回调的block
typedef void (^AIUACategoryCellTapBlock)(NSString *fullText);

// 分类项Cell
@interface AIUAWritingCategoryCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, copy) AIUACategoryCellTapBlock tapBlock; // 点击回调

- (void)configureWithTitle:(NSString *)title content:(NSString *)content;
- (void)setTapBlock:(AIUACategoryCellTapBlock)tapBlock; // 设置点击回调

@end

NS_ASSUME_NONNULL_END
