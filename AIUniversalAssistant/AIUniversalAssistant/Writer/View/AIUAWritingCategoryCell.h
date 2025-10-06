//
//  AIUAWritingCategoryCell.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 分类项Cell
@interface AIUAWritingCategoryCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;

- (void)configureWithTitle:(NSString *)title content:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
